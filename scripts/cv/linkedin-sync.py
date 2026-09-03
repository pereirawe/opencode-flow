#!/usr/bin/env python3
"""linkedin-sync.py — offline LinkedIn <-> hub.json sync diff (issue #225).

Compares a candidate's REAL LinkedIn profile — from the official LinkedIn
"Download My Data" export (a local directory of CSVs, never scraped, never a
URL) — against the candidate's hub.json, and reports per-section diffs with
the four categories (consistent / divergent / linkedin_only / hub_only) plus
actionable per-skill recommendations (add/promote/remove/keep).

Usage:
    linkedin-sync.py <candidate-dir> [options]

Positional:
    candidate-dir        candidate directory (e.g. ~/career/<candidate-name>);
                         hub.json and the outputs live inside it by default.

Options:
    --export DIR   LinkedIn Download My Data export directory
                   (default: <candidate-dir>/entradas/linkedin)
    --hub FILE     hub.json path (default: <candidate-dir>/hub.json)
    --out-dir DIR  directory for linkedin-sync.md / linkedin-sync.json
                   (default: <candidate-dir>)
    --lang LANG    report language: pt | en | es
                   (default: detected from the hub summary language)
    --stale-days N staleness threshold for the export age in days (default 180)

Exit codes:
    0 - success (reports written)
    1 - operational failure (missing export/hub, URL refused, no export files)
    2 - usage error

Guarantees (issue #225 business rules):
    * NEVER scrapes linkedin.com and NEVER accepts a URL as input — only a
      local Download My Data directory is read.
    * NEVER writes to hub.json — this script only reads the hub and reports.
    * Every value in the outputs comes from the export or the hub. Nothing is
      invented; unknown proficiency labels / unmatched names are reported
      honestly instead of guessed.
    * No sensitive data (address, birth date, phone, e-mail from Profile.csv)
      is ever copied into the reports — only the Headline/Summary columns of
      Profile.csv are read.

The parse rules, the diff semantics, the proficiency mapping and the OAuth
limitation are documented in skills/career/cv-linkedin-sync/SKILL.md — the
single source of truth for this script's behaviour.
"""
import argparse
import csv
import datetime
import io
import json
import os
import re
import sys
import unicodedata

# ---------------------------------------------------------------------------
# Text normalization (case / whitespace / accents / punctuation folding)
# ---------------------------------------------------------------------------

def fold_text(value):
    """Lowercase + strip accents (NFKD). Punctuation is kept here and removed
    later by norm_name."""
    if value is None:
        return ""
    s = unicodedata.normalize("NFKD", str(value))
    s = "".join(ch for ch in s if not unicodedata.combining(ch))
    return s.lower()


def norm_name(value):
    """Identity key for names (companies, titles, skills, schools...):
    lowercase, accent-free, letters/digits only; digit<->letter boundaries are
    split ("93.9FM" -> "93 9 fm") and whitespace is collapsed."""
    s = fold_text(value)
    s = re.sub(r"(?<=[a-z])(?=\d)|(?<=\d)(?=[a-z])", " ", s)
    s = re.sub(r"[^a-z0-9]+", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def tokens_of(value):
    return norm_name(value).split(" ")


def org_key(value):
    return tuple(tokens_of(value))


def org_match(a, b):
    """Organization/school names match when their normalized token sets are
    equal OR the smaller token set (>= 3 tokens) is fully contained in the
    larger one. The containment rule absorbs qualifiers/prefixes such as
    "URBE - Universidad Rafael Belloso Chacín" vs "Universidad Rafael Belloso
    Chacín". Short names (>= 3 tokens required) never alias unrelated
    organizations."""
    ta = set(org_key(a))
    tb = set(org_key(b))
    if ta == tb:
        return True
    small, large = (ta, tb) if len(ta) <= len(tb) else (tb, ta)
    return len(small) >= 3 and small < large


def skill_key(value):
    """A skill is identified by its normalized token set."""
    return tuple(sorted(tokens_of(value)))


def skill_match(a, b):
    """Skill names match when their token sets are equal or one is contained
    in the other with >= 2 tokens on the larger side ("MySQL & SQL" covers a
    LinkedIn-only "SQL"; "Git" never aliases "GitHub")."""
    ka = set(skill_key(a))
    kb = set(skill_key(b))
    if ka == kb:
        return True
    small, large = (ka, kb) if len(ka) <= len(kb) else (kb, ka)
    return len(large) >= 2 and small < large


# ---------------------------------------------------------------------------
# Date parsing / normalization ("2021-03", "Mar 2021", "março de 2021", ...)
# ---------------------------------------------------------------------------

# month number by 3-letter prefix, covering en/pt/es month names
MONTH_PREFIX = {
    "jan": 1, "ene": 1,
    "feb": 2, "fev": 2,
    "mar": 3,
    "apr": 4, "abr": 4,
    "may": 5, "mai": 5,
    "jun": 6,
    "jul": 7,
    "aug": 8, "ago": 8,
    "sep": 9, "set": 9,
    "oct": 10, "out": 10,
    "nov": 11,
    "dec": 12, "dic": 12, "dez": 12,
}

OPEN_ENDED = {
    "present", "now", "current", "actual", "today",
    "atual", "presente", "hoje",
    "o momento", "ate o momento",
}


def parse_date(value):
    """Parse a date cell into (year, month, day) with optional None parts, or
    None for empty / open-ended ("present", "atual", ...).

    Accepts "YYYY", "YYYY-MM[-DD]", "MM/YYYY", "Mar 2021", "março de 2021",
    "Jan/2021", "03/2021" (English/Portuguese/Spanish month names).
    """
    if value is None:
        return None
    s = str(value).strip()
    if not s:
        return None
    low = re.sub(r"\s+", " ", fold_text(s)).strip()
    if low in OPEN_ENDED:
        return None

    m = re.fullmatch(r"(\d{4})", low)
    if m:
        return (int(m.group(1)), None, None)
    m = re.fullmatch(r"(\d{4})[-/.](\d{1,2})(?:[-/.](\d{1,2}))?", low)
    if m:
        return (int(m.group(1)), int(m.group(2)),
                int(m.group(3)) if m.group(3) else None)
    m = re.fullmatch(r"(\d{1,2})[-/.](\d{4})", low)
    if m:
        return (int(m.group(2)), int(m.group(1)), None)
    m = re.fullmatch(r"([a-z]+)(?:\s+de)?[\s,./\-]*(\d{4})", low)
    if m:
        word, year = m.group(1), int(m.group(2))
        month = MONTH_PREFIX.get(word[:3])
        if month and 1 <= month <= 12 and 1900 <= year <= 2099:
            return (year, month, None)
    m = re.search(r"\b(19|20)\d{2}\b", low)
    if m:
        return (int(m.group(0)), None, None)
    return None


def canon_date(value):
    """Render a raw date cell as 'YYYY-MM' or 'YYYY'; None when open/empty."""
    t = parse_date(value)
    if t is None:
        return None
    year, month, _day = t
    if month is None:
        return "%04d" % year
    return "%04d-%02d" % (year, month)


def dates_equal(a, b):
    """Two raw date cells are equal when both are open/empty or their
    canonical tuples agree on every known part (a coarse '2021' does not
    contradict a precise '2021-03')."""
    ta = parse_date(a)
    tb = parse_date(b)
    if ta is None or tb is None:
        return ta is None and tb is None
    if ta[0] != tb[0]:
        return False
    if ta[1] is not None and tb[1] is not None and ta[1] != tb[1]:
        return False
    return True


# ---------------------------------------------------------------------------
# CSV discovery + tolerant reading (python3 csv module)
# ---------------------------------------------------------------------------

KNOWN_FILES = {
    "profile": {"profile"},
    "profile_summary": {"profile summary", "profilesummary"},
    "positions": {"positions", "position", "experience", "work experience"},
    "skills": {"skills", "skill"},
    "education": {"education", "educations"},
    "languages": {"languages", "language"},
    "certifications": {"certifications", "certification"},
}


def discover_csv_files(export_dir):
    """Find the target CSVs inside the export directory (root preferred, one
    subdirectory level tolerated). Returns {semantic_key: path}."""
    found = {}
    export_dir = os.path.abspath(export_dir)
    depth0 = export_dir.count(os.sep)
    for base, dirs, files in os.walk(export_dir):
        depth = base.count(os.sep) - depth0
        if depth > 1:
            dirs[:] = []
            continue
        dirs.sort()
        for fn in sorted(files):
            if not fn.lower().endswith(".csv"):
                continue
            stem = fn[:-4]
            key = " ".join(fold_text(stem).split())
            key_no_suffix = re.sub(r"\s+\d+$", "", key)  # Certifications_1.csv
            for semantic, names in KNOWN_FILES.items():
                if semantic in found:
                    continue
                if key in names or key_no_suffix in names:
                    found[semantic] = os.path.join(base, fn)
    return found


def read_csv(path):
    """Read a CSV file into a list of dicts (header -> value) with the stdlib
    csv module (StringIO keeps quoted multi-line cells intact). Handles UTF-8
    BOM and falls back to latin-1."""
    with open(path, "rb") as fh:
        raw = fh.read()
    try:
        text = raw.decode("utf-8-sig")
    except UnicodeDecodeError:
        text = raw.decode("latin-1")
    reader = csv.reader(io.StringIO(text))
    rows = list(reader)
    if not rows:
        return []
    header = [" ".join(fold_text(h).split()) for h in rows[0]]
    out = []
    for r in rows[1:]:
        if not any(str(cell).strip() for cell in r):
            continue  # skip fully blank rows
        out.append(dict(zip(header, r)))
    return out


def row_value(row, col_key):
    """Read a semantic column value from a row dict (folded headers)."""
    aliases = COLUMNS[col_key]
    for alias in aliases:
        if alias in row:
            return str(row[alias])
    return ""


# column aliases per semantic (folded, whitespace collapsed)
COLUMNS = {
    "company": ["company name", "company", "employer", "organization name",
                "organization", "empresa"],
    "title": ["title", "position", "job title", "role", "cargo"],
    "description": ["description", "descricao", "descripcion", "notes", "note"],
    "location": ["location", "local", "localizacao", "ubicacion", "city"],
    "start": ["started on", "start date", "started date", "begin date",
              "start", "data inicio", "data de inicio", "inicio",
              "fecha de inicio"],
    "end": ["finished on", "end date", "ended on", "finish date", "end",
            "data fim", "data de fim", "data termino", "data de termino",
            "fim", "fin", "fecha de fin"],
    "school": ["school name", "school", "institution", "instituicao",
               "universidad", "university"],
    "degree": ["degree name", "degree", "course", "curso", "titulo",
               "formacao", "formacion"],
    "name": ["name", "language", "idioma", "skill", "certification name"],
    "proficiency": ["proficiency", "level", "nivel", "proficiencia"],
    "authority": ["authority", "issuer", "emissor", "organization"],
    "headline": ["headline", "professional headline", "titulo profissional"],
    "summary": ["summary", "about", "resumo", "sobre", "acerca de",
                "profile summary"],
}


# ---------------------------------------------------------------------------
# Spoken-language canonicalization (hub.languages vs Languages.csv)
# ---------------------------------------------------------------------------

LANG_ALIASES = {
    "english": ["english", "ingles", "inglese", "anglais", "ingilizce"],
    "spanish": ["spanish", "espanol", "espanola", "castellano", "espanhol"],
    "portuguese": ["portuguese", "portugues"],
    "french": ["french", "frances", "francais", "francaise"],
    "german": ["german", "aleman", "alemao", "deutsch", "allemand"],
    "italian": ["italian", "italiano", "italien"],
    "dutch": ["dutch", "holandes", "holandais", "nederlands", "neerlandes"],
    "japanese": ["japanese", "japones", "japonais", "mandarin"],
    "chinese": ["chinese", "chines", "chino"],
    "korean": ["korean", "coreano", "coreain"],
    "russian": ["russian", "russo", "ruso", "russe"],
    "arabic": ["arabic", "arabe", "arabo"],
    "hindi": ["hindi"],
    "turkish": ["turkish", "turco", "turc"],
    "vietnamese": ["vietnamese", "vietnamita", "vietnamien"],
    "thai": ["thai", "tailandes", "tailandais"],
    "polish": ["polish", "polones", "polonais"],
    "ukrainian": ["ukrainian", "ucraniano", "ukrainien"],
    "swedish": ["swedish", "sueco", "suedois"],
    "norwegian": ["norwegian", "noruego", "noruegues", "norvegien"],
    "danish": ["danish", "danes", "dinamarques", "danois"],
    "finnish": ["finnish", "finlandes", "finlandais"],
    "czech": ["czech", "tcheco", "tcheque", "checo"],
    "greek": ["greek", "grego", "grec"],
    "hebrew": ["hebrew", "hebraico", "hebreu", "hebreo"],
    "indonesian": ["indonesian", "indonesio", "indonesien"],
    "malay": ["malay", "malayo", "malais"],
    "romanian": ["romanian", "romeno", "roumain"],
    "hungarian": ["hungarian", "hungaro", "hongrois"],
    "latin": ["latin", "latim", "latino"],
}

_LANG_LOOKUP = {}
for _canon, _aliases in LANG_ALIASES.items():
    for _a in _aliases:
        _LANG_LOOKUP[norm_name(_a)] = _canon


def language_canon(name):
    """Canonical English name for a spoken language when recognized (matched
    accent/case-insensitively across en/pt/es/native spellings); None when
    unknown."""
    return _LANG_LOOKUP.get(norm_name(name))


def linkedin_proficiency_to_hub(raw):
    """Map a LinkedIn proficiency label to the hub languages.level enum.
    Accepts the official English/Portuguese/Spanish labels and the hub enum
    values themselves. None when unrecognized (reported honestly)."""
    if raw is None:
        return None
    s = " ".join(fold_text(raw).split())
    if not s:
        return None
    words = set(norm_name(raw).split(" "))
    if words & {"native", "nativo", "nativa", "bilingue", "bilingual"}:
        return "native"
    if words & {"full", "completa", "completo", "fluent", "fluente", "fluido"}:
        return "fluent"
    if words & {"professional", "profissional", "profesional", "advanced",
                "avancado", "avanzado"}:
        return "advanced"
    if words & {"limited", "limitada", "limitado", "conversational",
                "conversacional"}:
        return "conversational"
    if words & {"elementary", "elementar", "elemental", "basic", "basico"}:
        return "basic"
    return None


# ---------------------------------------------------------------------------
# Hub loading (read-only)
# ---------------------------------------------------------------------------

def load_hub(path):
    """Load hub.json. Only the minimal structural checks needed by the diff
    are performed here (full validation is validate.py's job — the sync never
    writes the hub)."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            hub = json.load(f)
    except FileNotFoundError:
        return None, "hub file not found: {0}".format(path)
    except json.JSONDecodeError as e:
        return None, "invalid JSON in {0}: {1}".format(path, e)
    if not isinstance(hub, dict):
        return None, "hub root must be an object"
    if not isinstance(hub.get("personal_info"), dict):
        return None, "hub personal_info must be an object"
    for k in ("summary", "experience", "education", "skills",
              "certifications", "languages"):
        if not isinstance(hub.get(k), (str, list)):
            return None, "hub section '{0}' must be an array (summary: string)".format(k)
    return hub, None


# ---------------------------------------------------------------------------
# Parsers per export file (values only; nothing invented)
# ---------------------------------------------------------------------------

def parse_profile_row(found):
    """Headline + About from Profile.csv (structured Headline/Summary columns)
    with fallback to the free-form 'Profile Summary.csv' cell."""
    headline = None
    about = None
    profile_path = found.get("profile")
    if profile_path:
        for row in read_csv(profile_path):
            h = row_value(row, "headline").strip()
            s = row_value(row, "summary").strip()
            if h and headline is None:
                headline = h
            if s and about is None:
                about = s
    if about is None:
        # Fallback: Profile Summary.csv (one free-form cell per row). The
        # first short line (<= 220 chars) is a best-effort headline candidate.
        ps_path = found.get("profile_summary")
        if ps_path:
            lines = []
            for row in read_csv(ps_path):
                for key, value in row.items():
                    if str(value).strip():
                        lines.append(str(value).strip())
            if lines:
                about = "\n".join(lines)
                first = lines[0].split("\n")[0].strip()
                if len(first) <= 220:
                    headline = headline or first
    return {"headline": headline, "about": about}


def parse_positions(found):
    out = []
    path = found.get("positions")
    if not path:
        return out, "Positions.csv"
    for row in read_csv(path):
        company = row_value(row, "company").strip()
        title = row_value(row, "title").strip()
        if not company and not title:
            continue
        start_raw = row_value(row, "start").strip()
        end_raw = row_value(row, "end").strip()
        out.append({
            "company": company,
            "title": title,
            "description": row_value(row, "description").strip(),
            "location": row_value(row, "location").strip(),
            "start_date": canon_date(start_raw),
            "end_date": canon_date(end_raw),
            "current": parse_date(end_raw) is None,
        })
    return out, None


def parse_skills(found):
    out = []
    path = found.get("skills")
    if not path:
        return out, "Skills.csv"
    for row in read_csv(path):
        name = row_value(row, "name").strip()
        if name:
            out.append({"name": name})
    return out, None


def parse_education(found):
    out = []
    path = found.get("education")
    if not path:
        return out, "Education.csv"
    for row in read_csv(path):
        school = row_value(row, "school").strip()
        if not school:
            continue
        out.append({
            "school": school,
            "degree": row_value(row, "degree").strip(),
            "notes": row_value(row, "description").strip(),
            "start_date": canon_date(row_value(row, "start").strip()),
            "end_date": canon_date(row_value(row, "end").strip()),
        })
    return out, None


def parse_languages(found):
    out = []
    path = found.get("languages")
    if not path:
        return out, "Languages.csv"
    for row in read_csv(path):
        name = row_value(row, "name").strip()
        if not name:
            continue
        prof_raw = row_value(row, "proficiency").strip()
        out.append({
            "name": name,
            "proficiency_raw": prof_raw,
            "level": linkedin_proficiency_to_hub(prof_raw),
        })
    return out, None


def parse_certifications(found):
    out = []
    path = found.get("certifications")
    if not path:
        return out, "Certifications.csv"
    for row in read_csv(path):
        name = row_value(row, "name").strip()
        if not name:
            continue
        year = None
        for col in ("start", "end"):
            y = canon_date(row_value(row, col).strip())
            if y:
                year = y[:4]
                break
        out.append({
            "name": name,
            "authority": row_value(row, "authority").strip(),
            "year": year,
        })
    return out, None


# ---------------------------------------------------------------------------
# Diff semantics (consistent / divergent / linkedin_only / hub_only)
# ---------------------------------------------------------------------------

def _hub_position_short(e):
    """Identify a hub experience entry in the diff (hub.json stays the source
    of truth for the full entry; dates are kept as stored)."""
    return {
        "company": str(e.get("company", "")).strip(),
        "title": str(e.get("title", "")).strip(),
        "start_date": e.get("start_date"),
        "end_date": e.get("end_date"),
        "current": bool(e.get("current")),
        "location": str(e.get("location", "")).strip(),
    }


def _li_position_short(e):
    return {
        "company": str(e.get("company", "")).strip(),
        "title": str(e.get("title", "")).strip(),
        "start_date": e.get("start_date"),
        "end_date": e.get("end_date"),
        "current": bool(e.get("current")),
        "location": str(e.get("location", "")).strip(),
        "description": e.get("description", ""),
    }


def pair_positions(hub_entry, li_entry):
    """Compare one matched position pair (same company). Returns the
    differences list (empty == consistent)."""
    diffs = []
    if norm_name(str(hub_entry.get("title", ""))) != norm_name(str(li_entry.get("title", ""))):
        diffs.append("title")
    if not dates_equal(hub_entry.get("start_date"), li_entry.get("start_date")):
        diffs.append("start_date")
    if not dates_equal(hub_entry.get("end_date"), li_entry.get("end_date")):
        diffs.append("end_date")
    return diffs


def _pair_within_company(hub_list, li_list):
    """One-to-one pairing inside a matched company: exact normalized title
    first, then identical date range. Returns (pairs, hub_leftovers,
    li_leftovers); each pair is (hub_entry, li_entry, differences)."""
    hub_list = list(hub_list)
    li_list = list(li_list)
    pairs = []
    used_h = set()
    used_l = set()

    for i, h in enumerate(hub_list):
        for j, l in enumerate(li_list):
            if i in used_h or j in used_l:
                continue
            if norm_name(str(h.get("title", ""))) == norm_name(str(l.get("title", ""))):
                used_h.add(i)
                used_l.add(j)
                pairs.append((i, j, pair_positions(h, l)))
                break

    for i, h in enumerate(hub_list):
        if i in used_h:
            continue
        for j, l in enumerate(li_list):
            if j in used_l:
                continue
            if dates_equal(h.get("start_date"), l.get("start_date")) and \
                    dates_equal(h.get("end_date"), l.get("end_date")):
                used_h.add(i)
                used_l.add(j)
                pairs.append((i, j, pair_positions(h, l)))
                break

    hub_left = [hub_list[i] for i in range(len(hub_list)) if i not in used_h]
    li_left = [li_list[j] for j in range(len(li_list)) if j not in used_l]
    return pairs, hub_left, li_left


def diff_positions(hub_exp, li_positions):
    """Classify every hub/LinkedIn position into the four categories.

    Pairing granularity: organization first (org_match absorbs company-name
    variants), then title, then identical date range. 'order' is added to the
    differences when a company holds >= 2 matched positions listed in a
    different relative order on each side.
    """
    hub_groups = {}
    hub_order = []
    for e in hub_exp:
        if not isinstance(e, dict):
            continue
        name = str(e.get("company", "")).strip()
        if not name:
            continue
        key = " ".join(org_key(name))
        if key not in hub_groups:
            hub_groups[key] = {"name": name, "positions": []}
            hub_order.append(key)
        hub_groups[key]["positions"].append(e)

    li_groups = {}
    for e in li_positions:
        name = str(e.get("company", "")).strip()
        if not name:
            continue
        key = " ".join(org_key(name))
        li_groups.setdefault(key, {"name": name, "positions": []})
        li_groups[key]["positions"].append(e)

    # Map each LinkedIn company to its best hub group (longest matching name).
    li_by_hub = {}
    for li_key, li_group in li_groups.items():
        best = None
        for hub_key in hub_order:
            if org_match(hub_groups[hub_key]["name"], li_group["name"]):
                if best is None or len(hub_groups[hub_key]["name"]) > len(hub_groups[best]["name"]):
                    best = hub_key
        li_by_hub.setdefault(best, []).append(li_group)

    consistent = []
    divergent = []
    hub_only = []
    linkedin_only = []
    consumed_hub = set()

    for hub_key, groups in li_by_hub.items():
        if hub_key is None:
            for g in groups:
                linkedin_only.extend(g["positions"])
            continue
        consumed_hub.add(hub_key)
        l_list = []
        for g in groups:
            l_list.extend(g["positions"])
        h_list = hub_groups[hub_key]["positions"]
        pairs, h_left, l_left = _pair_within_company(h_list, l_list)

        order_flags = set()
        if len(pairs) >= 2:
            idx_h = [p[0] for p in pairs]
            idx_l = [p[1] for p in pairs]
            for a in range(len(pairs)):
                for b in range(a + 1, len(pairs)):
                    if (idx_h[a] < idx_h[b]) != (idx_l[a] < idx_l[b]):
                        order_flags.add(a)
                        order_flags.add(b)

        for n, (i_h, i_l, diffs) in enumerate(pairs):
            h = h_list[i_h]
            l = l_list[i_l]
            diffs = list(diffs)
            if n in order_flags and "order" not in diffs:
                diffs.append("order")
            if diffs:
                divergent.append({
                    "company": hub_groups[hub_key]["name"],
                    "hub": _hub_position_short(h),
                    "linkedin": _li_position_short(l),
                    "differences": sorted(diffs),
                })
            else:
                consistent.append(_hub_position_short(h))
        for h in h_left:
            hub_only.append(_hub_position_short(h))
        for l in l_left:
            linkedin_only.append(l)

    for hub_key in hub_order:
        if hub_key not in consumed_hub:
            for h in hub_groups[hub_key]["positions"]:
                hub_only.append(_hub_position_short(h))

    return {
        "consistent": consistent,
        "divergent": divergent,
        "hub_only": hub_only,
        "linkedin_only": linkedin_only,
    }


def _hub_skill_short(e):
    return {
        "name": str(e.get("name", "")).strip(),
        "category": str(e.get("category", "")).strip(),
        "level": str(e.get("level", "")).strip(),
        "importance": str(e.get("importance", "")).strip(),
        "since": str(e.get("since", "")).strip(),
    }


def diff_skills(hub_skills, li_skills, hub_languages, hub):
    """Skill diff + per-skill recommendations (add/promote/remove/keep),
    prioritizing relevance to the hub profile_objective (issue #222) and to
    the hub's dominant skill categories. Spoken-language skills found in the
    LinkedIn Skills.csv are handled by the languages diff instead of being
    proposed as hub skills (action 'keep', reason language_in_hub)."""
    hub_entries = [_hub_skill_short(e) for e in hub_skills
                   if isinstance(e, dict) and str(e.get("name", "")).strip()]
    li_names = [str(e.get("name", "")).strip() for e in li_skills
                if str(e.get("name", "")).strip()]

    objective = hub.get("profile_objective")
    if not isinstance(objective, dict):
        objective = {}
    objective_text = " ".join(str(v) for v in objective.values() if isinstance(v, str))
    objective_tokens = set(tokens_of(objective_text))

    cat_count = {}
    for e in hub_entries:
        cat = e.get("category") or "other"
        cat_count[cat] = cat_count.get(cat, 0) + 1
    dominant_cats = [c for c, _ in sorted(cat_count.items(), key=lambda kv: (-kv[1], kv[0]))][:2]

    hub_by_key = {}
    for e in hub_entries:
        hub_by_key.setdefault(skill_key(e["name"]), e)

    hub_lang_canons = set()
    for e in hub_languages:
        if isinstance(e, dict) and str(e.get("language", "")).strip():
            c = language_canon(str(e["language"]))
            if c:
                hub_lang_canons.add(c)

    def li_is_hub_language(name):
        canon = language_canon(name)
        return canon and canon in hub_lang_canons

    def relevance_for_li_skill(name):
        """(action, reason, priority) for a LinkedIn skill absent from the hub."""
        toks = set(tokens_of(name))
        if objective_tokens and (toks & objective_tokens):
            return "add_to_hub", "matches_objective", "high"
        for key, e in hub_by_key.items():
            hub_toks = set(tokens_of(e["name"]))
            if hub_toks & toks and e.get("importance") == "primary":
                return "add_to_hub", "related_primary", "high"
        for key, e in hub_by_key.items():
            hub_toks = set(tokens_of(e["name"]))
            if hub_toks & toks and e.get("category") in dominant_cats:
                return "add_to_hub", "related_dominant", "medium"
        if objective_tokens:
            return "remove_from_linkedin", "not_aligned_objective", "low"
        return "keep", "no_hub_reference", "low"

    def action_for_hub_skill(e):
        toks = set(tokens_of(e["name"]))
        if e.get("importance") == "primary":
            return "add_to_linkedin", "primary_hub_skill", "high"
        if objective_tokens and (toks & objective_tokens):
            return "add_to_linkedin", "matches_objective", "high"
        if e.get("category") in dominant_cats:
            return "add_to_linkedin", "dominant_category", "medium"
        return "add_to_linkedin", "hub_skill", "medium"

    def action_for_shared(name, hub_entry):
        toks = set(tokens_of(name))
        if hub_entry.get("importance") == "primary" or \
                (objective_tokens and (toks & objective_tokens)) or \
                hub_entry.get("category") in dominant_cats:
            return "promote_on_linkedin", "relevant_shared", "medium"
        return "keep", "shared_not_relevant", "low"

    consistent = []
    divergent = []
    hub_only = []
    linkedin_only = []
    recommendations = []

    for name in li_names:
        if li_is_hub_language(name):
            recommendations.append({
                "name": name,
                "side": "linkedin_only",
                "action": "keep",
                "priority": "low",
                "reason": "language_in_hub",
            })
            continue
        found = None
        for e in hub_by_key.values():
            if skill_match(name, e["name"]):
                found = e
                break
        if found is None:
            linkedin_only.append(name)
            action, reason, priority = relevance_for_li_skill(name)
            recommendations.append({
                "name": name,
                "side": "linkedin_only",
                "action": action,
                "priority": priority,
                "reason": reason,
            })
        else:
            consistent.append({"name": found["name"], "category": found.get("category")})
            action, reason, priority = action_for_shared(name, found)
            recommendations.append({
                "name": found["name"],
                "side": "consistent",
                "action": action,
                "priority": priority,
                "reason": reason,
                "hub_category": found.get("category"),
            })

    for e in hub_by_key.values():
        if any(skill_match(li, e["name"]) for li in li_names):
            continue
        hub_only.append(e)
        action, reason, priority = action_for_hub_skill(e)
        recommendations.append({
            "name": e["name"],
            "side": "hub_only",
            "action": action,
            "priority": priority,
            "reason": reason,
            "hub_category": e.get("category"),
        })

    return {
        "consistent": consistent,
        "divergent": divergent,
        "hub_only": hub_only,
        "linkedin_only": linkedin_only,
        "recommendations": recommendations,
    }


def diff_education(hub_edu, li_edu):
    """Education diff keyed by institution (org_match absorbs name variants)."""
    hub_entries = []
    for e in hub_edu:
        if isinstance(e, dict) and str(e.get("institution", "")).strip():
            hub_entries.append({
                "institution": str(e["institution"]).strip(),
                "course": str(e.get("course", "")).strip(),
                "start_date": e.get("start_date"),
                "end_date": e.get("end_date"),
            })
    li_entries = [e for e in li_edu]

    consistent = []
    divergent = []
    hub_only = []
    linkedin_only = []
    used_li = set()

    for h in hub_entries:
        cand = [j for j, l in enumerate(li_entries) if j not in used_li
                and org_match(h["institution"], l["school"])]
        if not cand:
            hub_only.append(h)
            continue
        j = cand[0]
        l = li_entries[j]
        diffs = []
        if h.get("course") and l.get("degree") and \
                norm_name(h["course"]) != norm_name(l["degree"]):
            diffs.append("course")
        if not dates_equal(h.get("start_date"), l.get("start_date")):
            diffs.append("start_date")
        if not dates_equal(h.get("end_date"), l.get("end_date")):
            diffs.append("end_date")
        if diffs:
            divergent.append({
                "institution": h["institution"],
                "hub": h,
                "linkedin": l,
                "differences": sorted(diffs),
            })
        else:
            consistent.append(h)
        used_li.add(j)

    for j, l in enumerate(li_entries):
        if j not in used_li:
            linkedin_only.append(l)

    return {
        "consistent": consistent,
        "divergent": divergent,
        "hub_only": hub_only,
        "linkedin_only": linkedin_only,
    }


def diff_languages(hub_langs, li_langs):
    """Languages diff keyed by canonical language name; proficiency levels are
    compared via the hub enum after mapping the LinkedIn label."""
    hub_entries = []
    for e in hub_langs:
        if isinstance(e, dict) and str(e.get("language", "")).strip():
            hub_entries.append({
                "language": str(e["language"]).strip(),
                "canon": language_canon(str(e["language"])) or norm_name(str(e["language"])),
                "level": str(e.get("level", "")).strip(),
                "scale_note": str(e.get("scale_note", "")).strip(),
            })
    li_entries = []
    for e in li_langs:
        li_entries.append({
            "language": str(e.get("name", "")).strip(),
            "canon": language_canon(str(e.get("name", ""))) or norm_name(str(e.get("name", ""))),
            "level": e.get("level"),
            "proficiency_raw": e.get("proficiency_raw", ""),
        })

    consistent = []
    divergent = []
    hub_only = []
    linkedin_only = []
    used_li = set()

    for h in hub_entries:
        cand = [j for j, l in enumerate(li_entries) if j not in used_li
                and l["canon"] == h["canon"]]
        if not cand:
            hub_only.append({"language": h["language"], "level": h["level"],
                             "scale_note": h["scale_note"]})
            continue
        j = cand[0]
        l = li_entries[j]
        if h["level"] and l["level"] and h["level"] != l["level"]:
            divergent.append({
                "language": h["language"],
                "hub": {"language": h["language"], "level": h["level"],
                        "scale_note": h["scale_note"]},
                "linkedin": {"language": l["language"], "level": l["level"],
                             "proficiency_raw": l["proficiency_raw"]},
                "differences": ["level"],
            })
        else:
            consistent.append({"language": h["language"],
                               "level": h["level"] or l["level"]})
        used_li.add(j)

    for j, l in enumerate(li_entries):
        if j not in used_li:
            linkedin_only.append({"language": l["language"], "level": l["level"],
                                  "proficiency_raw": l["proficiency_raw"]})

    return {
        "consistent": consistent,
        "divergent": divergent,
        "hub_only": hub_only,
        "linkedin_only": linkedin_only,
    }


def diff_certifications(hub_certs, li_certs):
    hub_entries = []
    for e in hub_certs:
        if isinstance(e, dict) and str(e.get("name", "")).strip():
            hub_entries.append({
                "name": str(e["name"]).strip(),
                "issuer": str(e.get("issuer", "")).strip(),
                "year": str(e.get("year", "")).strip(),
            })
    consistent = []
    divergent = []
    hub_only = []
    linkedin_only = []
    used_li = set()

    for h in hub_entries:
        cand = [j for j, l in enumerate(li_certs) if j not in used_li
                and skill_match(h["name"], l["name"])]
        if not cand:
            hub_only.append(h)
            continue
        j = cand[0]
        l = li_certs[j]
        diffs = []
        if h.get("issuer") and l.get("authority") and \
                norm_name(h["issuer"]) != norm_name(l["authority"]):
            diffs.append("issuer")
        if h.get("year") and l.get("year") and h["year"] != l["year"]:
            diffs.append("year")
        if diffs:
            divergent.append({
                "name": h["name"],
                "hub": h,
                "linkedin": l,
                "differences": sorted(diffs),
            })
        else:
            consistent.append(h)
        used_li.add(j)

    for j, l in enumerate(li_certs):
        if j not in used_li:
            linkedin_only.append(l)

    return {
        "consistent": consistent,
        "divergent": divergent,
        "hub_only": hub_only,
        "linkedin_only": linkedin_only,
    }


def diff_headline(hub, profile):
    """Headline comparison. The LinkedIn headline is NOT included in every
    Download My Data export — when no Headline column exists (neither in
    Profile.csv nor a short first line in Profile Summary.csv) the state is
    'not_available_in_export' instead of a guessed category."""
    hub_title = (hub.get("personal_info") or {}).get("professional_title") or None
    li_headline = (profile or {}).get("headline") or None
    if hub_title and li_headline:
        category = "consistent" if norm_name(hub_title) == norm_name(li_headline) \
            else "divergent"
    elif li_headline and not hub_title:
        category = "linkedin_only"
    else:
        category = "not_available_in_export"
    return {
        "hub_professional_title": hub_title,
        "linkedin_headline": li_headline,
        "category": category,
        "hub_summary_present": bool((hub.get("summary") or "").strip()),
        "linkedin_about": (profile or {}).get("about") or None,
    }


# ---------------------------------------------------------------------------
# Report language
# ---------------------------------------------------------------------------

def detect_language(hub, cli_lang):
    """Report language: --lang wins; otherwise the hub summary language (the
    summary_i18n key whose value equals the top-level summary; fall back to
    the first available pt/en/es key); final fallback English."""
    if cli_lang:
        return cli_lang
    i18n = hub.get("summary_i18n")
    if isinstance(i18n, dict):
        summary = hub.get("summary")
        for key in ("pt", "en", "es"):
            if isinstance(i18n.get(key), str) and summary == i18n[key]:
                return key
        for key in ("pt", "en", "es"):
            if isinstance(i18n.get(key), str) and i18n[key]:
                return key
    return "en"


# message catalog (pt/es/en) — report body only; protocol tokens stay English
MSGS = {
    "pt": {
        "title": "Sincronização LinkedIn ↔ Hub",
        "h_summary": "Resumo da sincronização",
        "h_experience": "Experiência (Positions)",
        "h_skills": "Skills (Habilidades)",
        "h_education": "Educação",
        "h_languages": "Idiomas",
        "h_certifications": "Certificações",
        "h_headline": "Headline e Sobre",
        "h_export": "Dados do export",
        "open": "atual",
        "missing": "ausente",
        "present": "presente",
        "action_add_to_hub": "adicionar ao hub",
        "action_add_to_linkedin": "adicionar ao LinkedIn",
        "action_promote": "promover no LinkedIn (fixar no topo do ranking)",
        "action_remove": "remover/despriorizar no LinkedIn",
        "action_keep": "manter (sem ação)",
        "li_only_action": "está no LinkedIn e não está no hub — considere adicionar ao hub",
        "hub_only_action": "está no hub e não está no LinkedIn — considere adicionar ao LinkedIn",
        "divergent_action": "campos divergentes — alinhe o lado desatualizado (o export é a fonte mais recente)",
        "file_missing": "arquivo não encontrado no export: {file} — esta seção não pôde ser comparada (as entradas do hub NÃO foram classificadas como hub_only)",
        "no_positions": "Positions.csv não tem registros — nenhuma posição do LinkedIn para comparar",
        "no_skills": "Skills.csv não tem registros — nenhuma skill do LinkedIn para comparar",
        "no_recommendations": "nenhuma recomendação de skill com ação (as demais estão consistentes/sem ação no JSON)",
        "skill_rec": "Recomendações de skills (por prioridade)",
        "export_dir": "Diretório do export",
        "hub_path": "Hub",
        "export_date": "Data do export (detectada dos arquivos)",
        "export_unknown": "não foi possível detectar a data dos arquivos do export",
        "stale": "O export tem {days} dias — o LinkedIn pode ter mudado desde então. Solicite um export novo (LinkedIn → Configurações → Privacidade de dados → Obter uma cópia dos seus dados) antes de agir com base nestas recomendações.",
        "fresh": "O export é recente ({days} dias).",
        "oauth": "Por que o export oficial? O \"Entrar com LinkedIn\" (OpenID) só devolve nome/e-mail/foto — a sincronização completa exige o export Download My Data (skill cv-linkedin-sync).",
        "head_divergent": "o professional_title do hub e a headline do LinkedIn divergem — decida qual lado alinhar",
        "head_consistent": "o professional_title do hub e a headline do LinkedIn estão alinhados",
        "head_na": "a headline do LinkedIn não está incluída neste export (sem coluna Headline em Profile.csv) — confira manualmente no perfil",
        "head_li_only": "há headline no LinkedIn mas o hub não tem professional_title — considere adicioná-lo ao hub",
        "about_li": "Sobre (About) do LinkedIn presente ({n} caracteres)",
        "about_missing": "Sobre (About) do LinkedIn vazio/ausente — considere publicar um resumo a partir do hub",
        "counts_line": "LinkedIn {li} · hub {hub} — consistent {c} · divergent {d} · linkedin_only {lo} · hub_only {ho}",
        "reason_primary_hub_skill": "skill primária do hub ausente no perfil do LinkedIn",
        "reason_matches_objective": "relacionada ao objetivo do perfil (profile_objective)",
        "reason_related_primary": "relacionada a uma skill primária do hub (variante/nome próximo)",
        "reason_related_dominant": "relacionada às categorias dominantes de skills do hub",
        "reason_dominant_category": "faz parte das categorias dominantes de skills do hub",
        "reason_hub_skill": "skill do hub — vale adicionar ao LinkedIn",
        "reason_language_in_hub": "idioma já registrado em hub.languages (tratado pelo diff de idiomas)",
        "reason_no_hub_reference": "sem referência no hub para pontuar relevância — revise manualmente",
        "reason_not_aligned_objective": "não alinhada ao objetivo declarado do perfil — remover/despriorizar mantém o ranking do LinkedIn focado",
        "reason_relevant_shared": "presente nos dois lados e relevante — mantenha perto do topo do ranking do LinkedIn",
        "reason_shared_not_relevant": "presente nos dois lados — sem ação necessária",
        "written": "Relatórios gerados:",
        "diff_note_lang": "nível mapeado do rótulo do LinkedIn ({raw}) → {mapped}",
    },
    "en": {
        "title": "LinkedIn ↔ Hub Sync",
        "h_summary": "Sync summary",
        "h_experience": "Experience (Positions)",
        "h_skills": "Skills",
        "h_education": "Education",
        "h_languages": "Languages",
        "h_certifications": "Certifications",
        "h_headline": "Headline & About",
        "h_export": "Export data",
        "open": "present",
        "missing": "absent",
        "present": "present",
        "action_add_to_hub": "add to the hub",
        "action_add_to_linkedin": "add to LinkedIn",
        "action_promote": "promote on LinkedIn (pin near the top of the ranking)",
        "action_remove": "remove/deprioritize on LinkedIn",
        "action_keep": "keep (no action)",
        "li_only_action": "on LinkedIn but missing from the hub — consider adding to the hub",
        "hub_only_action": "in the hub but missing from LinkedIn — consider adding to LinkedIn",
        "divergent_action": "divergent fields — align the stale side (the export is the most recent source)",
        "file_missing": "file not found in the export: {file} — this section could not be compared (hub entries were NOT classified as hub_only)",
        "no_positions": "Positions.csv has no records — no LinkedIn positions to compare",
        "no_skills": "Skills.csv has no records — no LinkedIn skills to compare",
        "no_recommendations": "no skill recommendation with an action (the remaining skills are consistent / no-action — see the JSON)",
        "skill_rec": "Skill recommendations (by priority)",
        "export_dir": "Export directory",
        "hub_path": "Hub",
        "export_date": "Export date (detected from the files)",
        "export_unknown": "could not detect the export date from the files",
        "stale": "The export is {days} days old — LinkedIn may have changed since. Request a fresh export (LinkedIn → Settings → Data privacy → Get a copy of your data) before acting on these recommendations.",
        "fresh": "The export is recent ({days} days old).",
        "oauth": "Why the official export? \"Sign in with LinkedIn\" (OpenID) only returns name/e-mail/photo — a full profile sync requires the Download My Data export (see the cv-linkedin-sync skill).",
        "head_divergent": "hub professional_title and the LinkedIn headline differ — decide which side to align",
        "head_consistent": "hub professional_title and the LinkedIn headline are aligned",
        "head_na": "the LinkedIn headline is not included in this export (no Headline column in Profile.csv) — check it manually on the profile",
        "head_li_only": "LinkedIn has a headline but the hub has no professional_title — consider adding it to the hub",
        "about_li": "LinkedIn About is present ({n} characters)",
        "about_missing": "LinkedIn About is empty/missing — consider publishing a hub summary",
        "counts_line": "LinkedIn {li} · hub {hub} — consistent {c} · divergent {d} · linkedin_only {lo} · hub_only {ho}",
        "reason_primary_hub_skill": "primary hub skill missing from the LinkedIn profile",
        "reason_matches_objective": "related to the profile objective (profile_objective)",
        "reason_related_primary": "related to a primary hub skill (variant/close name)",
        "reason_related_dominant": "related to the hub's dominant skill categories",
        "reason_dominant_category": "part of the hub's dominant skill categories",
        "reason_hub_skill": "hub skill — worth adding to LinkedIn",
        "reason_language_in_hub": "spoken language already recorded in hub.languages (handled by the languages diff)",
        "reason_no_hub_reference": "no hub reference to score relevance — review manually",
        "reason_not_aligned_objective": "not aligned with the declared profile objective — removing/deprioritizing keeps the LinkedIn ranking focused",
        "reason_relevant_shared": "present on both sides and relevant — keep near the top of the LinkedIn ranking",
        "reason_shared_not_relevant": "present on both sides — no action needed",
        "written": "Reports written:",
        "diff_note_lang": "level mapped from the LinkedIn label ({raw}) → {mapped}",
    },
    "es": {
        "title": "Sincronización LinkedIn ↔ Hub",
        "h_summary": "Resumen de la sincronización",
        "h_experience": "Experiencia (Positions)",
        "h_skills": "Skills (Habilidades)",
        "h_education": "Educación",
        "h_languages": "Idiomas",
        "h_certifications": "Certificaciones",
        "h_headline": "Headline y Acerca de",
        "h_export": "Datos del export",
        "open": "actual",
        "missing": "ausente",
        "present": "presente",
        "action_add_to_hub": "añadir al hub",
        "action_add_to_linkedin": "añadir a LinkedIn",
        "action_promote": "promover en LinkedIn (fijar cerca del top del ranking)",
        "action_remove": "eliminar/despriorizar en LinkedIn",
        "action_keep": "mantener (sin acción)",
        "li_only_action": "está en LinkedIn y no está en el hub — considera añadirlo al hub",
        "hub_only_action": "está en el hub y no está en LinkedIn — considera añadirlo a LinkedIn",
        "divergent_action": "campos divergentes — alinea el lado desactualizado (el export es la fuente más reciente)",
        "file_missing": "archivo no encontrado en el export: {file} — esta sección no pudo compararse (las entradas del hub NO se clasificaron como hub_only)",
        "no_positions": "Positions.csv sin registros — no hay posiciones de LinkedIn para comparar",
        "no_skills": "Skills.csv sin registros — no hay skills de LinkedIn para comparar",
        "no_recommendations": "ninguna recomendación de skill con acción (el resto están consistentes / sin acción — ver el JSON)",
        "skill_rec": "Recomendaciones de skills (por prioridad)",
        "export_dir": "Directorio del export",
        "hub_path": "Hub",
        "export_date": "Fecha del export (detectada de los archivos)",
        "export_unknown": "no se pudo detectar la fecha del export desde los archivos",
        "stale": "El export tiene {days} días — LinkedIn puede haber cambiado desde entonces. Solicita un export nuevo (LinkedIn → Configuración → Privacidad de datos → Obtener una copia de tus datos) antes de actuar según estas recomendaciones.",
        "fresh": "El export es reciente ({days} días).",
        "oauth": "¿Por qué el export oficial? \"Iniciar sesión con LinkedIn\" (OpenID) solo devuelve nombre/correo/foto — la sincronización completa requiere el export Download My Data (skill cv-linkedin-sync).",
        "head_divergent": "el professional_title del hub y la headline de LinkedIn difieren — decide qué lado alinear",
        "head_consistent": "el professional_title del hub y la headline de LinkedIn están alineados",
        "head_na": "la headline de LinkedIn no está incluida en este export (sin columna Headline en Profile.csv) — verifícala manualmente en el perfil",
        "head_li_only": "hay headline en LinkedIn pero el hub no tiene professional_title — considera añadirlo al hub",
        "about_li": "Acerca de (About) de LinkedIn presente ({n} caracteres)",
        "about_missing": "Acerca de (About) de LinkedIn vacío/ausente — considera publicar un resumen desde el hub",
        "counts_line": "LinkedIn {li} · hub {hub} — consistent {c} · divergent {d} · linkedin_only {lo} · hub_only {ho}",
        "reason_primary_hub_skill": "skill primaria del hub ausente en el perfil de LinkedIn",
        "reason_matches_objective": "relacionada con el objetivo del perfil (profile_objective)",
        "reason_related_primary": "relacionada con una skill primaria del hub (variante/nombre cercano)",
        "reason_related_dominant": "relacionada con las categorías dominantes de skills del hub",
        "reason_dominant_category": "parte de las categorías dominantes de skills del hub",
        "reason_hub_skill": "skill del hub — vale añadir a LinkedIn",
        "reason_language_in_hub": "idioma ya registrado en hub.languages (lo trata el diff de idiomas)",
        "reason_no_hub_reference": "sin referencia en el hub para puntuar relevancia — revisa manualmente",
        "reason_not_aligned_objective": "no alineada con el objetivo declarado del perfil — eliminar/despriorizar mantiene el ranking de LinkedIn enfocado",
        "reason_relevant_shared": "presente en ambos lados y relevante — mantenla cerca del top del ranking de LinkedIn",
        "reason_shared_not_relevant": "presente en ambos lados — sin acción necesaria",
        "written": "Informes generados:",
        "diff_note_lang": "nivel mapeado desde la etiqueta de LinkedIn ({raw}) → {mapped}",
    },
}


# ---------------------------------------------------------------------------
# Report rendering
# ---------------------------------------------------------------------------

def count_cat(diff_result):
    return {
        "consistent": len(diff_result.get("consistent", [])),
        "divergent": len(diff_result.get("divergent", [])),
        "linkedin_only": len(diff_result.get("linkedin_only", [])),
        "hub_only": len(diff_result.get("hub_only", [])),
    }


def is_open_end(raw):
    """True when a raw hub date means open-ended (None, 'present', 'atual'...)
    — hub entries without an end_date are open-ended per the hub schema."""
    if raw is None or str(raw).strip() == "":
        return True
    return parse_date(raw) is None


def display_range(entry, lang):
    """Render '<start> → <end>' for a diff entry (dates canonical on the
    LinkedIn side, stored on the hub side; open ends localized)."""
    start = entry.get("start_date")
    end = entry.get("end_date")
    start_s = start if start else "?"
    if is_open_end(end):
        return "{0} → {1}".format(start_s, MSGS[lang]["open"])
    return "{0} → {1}".format(start_s, str(end).strip())


def truncate(text, limit=160):
    t = " ".join(str(text).split())
    if len(t) <= limit:
        return t
    return t[: limit - 1].rstrip() + "…"


ACTION_PHRASE_KEY = {
    "add_to_hub": "action_add_to_hub",
    "add_to_linkedin": "action_add_to_linkedin",
    "promote_on_linkedin": "action_promote",
    "remove_from_linkedin": "action_remove",
    "keep": "action_keep",
}


def unavailable_message(section_data, lang):
    """Human message for a section that could not be compared."""
    if section_data.get("empty_source"):
        return MSGS[lang]["no_positions"]
    return MSGS[lang]["file_missing"].format(
        file=section_data.get("missing_file", "?"))


def render_report(data, lang):
    L = MSGS[lang]
    lines = []
    lines.append("# {0}".format(L["title"]))
    lines.append("")
    lines.append("## {0}".format(L["h_summary"]))
    lines.append("")
    s = data["sections"]
    for section, label_key in (
        ("experience", "h_experience"), ("skills", "h_skills"),
        ("education", "h_education"), ("languages", "h_languages"),
        ("certifications", "h_certifications"),
    ):
        label = L[label_key]
        section_data = s[section]
        if section_data.get("available") is False:
            lines.append("- {0}: {1}".format(label, unavailable_message(section_data, lang)))
            continue
        counts = section_data.get("counts", {})
        hub_total = counts.get("consistent", 0) + counts.get("divergent", 0) \
            + counts.get("hub_only", 0)
        li_total = counts.get("consistent", 0) + counts.get("divergent", 0) \
            + counts.get("linkedin_only", 0)
        lines.append("- {0}: {1}".format(
            label, L["counts_line"].format(
                li=li_total, hub=hub_total,
                c=counts.get("consistent", 0), d=counts.get("divergent", 0),
                lo=counts.get("linkedin_only", 0), ho=counts.get("hub_only", 0))))
    head = data["headline"]
    lines.append("- {0}: hub {1} · LinkedIn {2}".format(
        L["h_headline"],
        L["present"] if head.get("hub_professional_title") else L["missing"],
        L["present"] if head.get("linkedin_headline") else L["missing"]))
    lines.append("")

    lines.append("## {0}".format(L["h_experience"]))
    lines.append("")
    exp = s["experience"]
    if exp.get("available") is False:
        lines.append("- {0}".format(unavailable_message(exp, lang)))
    else:
        if exp.get("no_linkedin_positions"):
            lines.append("- {0}".format(L["no_positions"]))
        for e in exp["consistent"]:
            lines.append("- consistent — {company} · {title} ({dates})".format(
                company=e["company"], title=e["title"], dates=display_range(e, lang)))
        for d in exp["divergent"]:
            lines.append("- divergent — {company} · {title} — hub: {hd} · LinkedIn: {ld} — differences: {diff} — {action}".format(
                company=d["company"], title=d["hub"]["title"],
                hd=display_range(d["hub"], lang), ld=display_range(d["linkedin"], lang),
                diff=", ".join(d["differences"]), action=L["divergent_action"]))
        for e in exp["linkedin_only"]:
            desc = ""
            if e.get("description"):
                desc = " — \"{0}\"".format(truncate(e["description"], 120))
            lines.append("- linkedin_only — {company} · {title} ({dates}){desc} — {action}".format(
                company=e["company"], title=e["title"], dates=display_range(e, lang),
                desc=desc, action=L["li_only_action"]))
        for e in exp["hub_only"]:
            lines.append("- hub_only — {company} · {title} ({dates}) — {action}".format(
                company=e["company"], title=e["title"], dates=display_range(e, lang),
                action=L["hub_only_action"]))
    lines.append("")

    lines.append("## {0}".format(L["h_skills"]))
    lines.append("")
    skills = s["skills"]
    if skills.get("available") is False:
        lines.append("- {0}".format(unavailable_message(skills, lang)))
    else:
        lines.append("- {0}".format(L["skill_rec"]))
        actionable = [r for r in skills["recommendations"] if r["action"] != "keep"]
        if not actionable:
            lines.append("- {0}".format(L["no_recommendations"]))
        for r in actionable:
            reason = L.get("reason_" + r["reason"], MSGS["en"].get("reason_" + r["reason"], r["reason"]))
            lines.append("- {side} → {name} — action: {action} — priority {priority} — {reason}".format(
                side=r["side"], name=r["name"], action=L[ACTION_PHRASE_KEY[r["action"]]],
                priority=r["priority"], reason=reason))
    lines.append("")

    lines.append("## {0}".format(L["h_education"]))
    lines.append("")
    edu = s["education"]
    if edu.get("available") is False:
        lines.append("- {0}".format(unavailable_message(edu, lang)))
    else:
        for e in edu["consistent"]:
            lines.append("- consistent — {inst} · {course} ({dates})".format(
                inst=e["institution"], course=e.get("course") or "-",
                dates=display_range(e, lang)))
        for d in edu["divergent"]:
            lines.append("- divergent — {inst} — hub: \"{hc}\" ({hd}) · LinkedIn: \"{lc}\" ({ld}) — differences: {diff} — {action}".format(
                inst=d["institution"], hc=d["hub"].get("course") or "-",
                hd=display_range(d["hub"], lang), lc=d["linkedin"].get("degree") or "-",
                ld=display_range(d["linkedin"], lang), diff=", ".join(d["differences"]),
                action=L["divergent_action"]))
        for e in edu["linkedin_only"]:
            lines.append("- linkedin_only — {school} · \"{degree}\" ({dates}) — {action}".format(
                school=e["school"], degree=e.get("degree") or "-",
                dates=display_range(e, lang), action=L["li_only_action"]))
        for e in edu["hub_only"]:
            lines.append("- hub_only — {inst} · {course} ({dates}) — {action}".format(
                inst=e["institution"], course=e.get("course") or "-",
                dates=display_range(e, lang), action=L["hub_only_action"]))
    lines.append("")

    lines.append("## {0}".format(L["h_languages"]))
    lines.append("")
    langs = s["languages"]
    if langs.get("available") is False:
        lines.append("- {0}".format(unavailable_message(langs, lang)))
    else:
        for e in langs["consistent"]:
            lines.append("- consistent — {language}: {level}".format(language=e["language"], level=e["level"] or "-"))
        for d in langs["divergent"]:
            mapped = ""
            if d["linkedin"].get("proficiency_raw") and d["linkedin"].get("level"):
                mapped = " ({0})".format(L["diff_note_lang"].format(
                    raw=d["linkedin"]["proficiency_raw"], mapped=d["linkedin"]["level"]))
            lines.append("- divergent — {language} — hub: {hl} · LinkedIn: {ll}{mapped} — {action}".format(
                language=d["language"], hl=d["hub"]["level"] or "-",
                ll=d["linkedin"]["level"] or d["linkedin"]["proficiency_raw"] or "-",
                mapped=mapped, action=L["divergent_action"]))
        for e in langs["linkedin_only"]:
            lines.append("- linkedin_only — {language}: {level} — {action}".format(
                language=e["language"], level=e["level"] or e.get("proficiency_raw") or "-",
                action=L["li_only_action"]))
        for e in langs["hub_only"]:
            lines.append("- hub_only — {language}: {level} — {action}".format(
                language=e["language"], level=e["level"] or "-",
                action=L["hub_only_action"]))
    lines.append("")

    lines.append("## {0}".format(L["h_certifications"]))
    lines.append("")
    certs = s["certifications"]
    if certs.get("available") is False:
        lines.append("- {0}".format(unavailable_message(certs, lang)))
    else:
        for e in certs["consistent"]:
            lines.append("- consistent — {name} · {issuer} ({year})".format(
                name=e["name"], issuer=e.get("issuer") or "-", year=e.get("year") or "-"))
        for d in certs["divergent"]:
            lines.append("- divergent — {name} — hub: {hi} ({hy}) · LinkedIn: {li} ({ly}) — differences: {diff}".format(
                name=d["name"], hi=d["hub"].get("issuer") or "-", hy=d["hub"].get("year") or "-",
                li=d["linkedin"].get("authority") or "-", ly=d["linkedin"].get("year") or "-",
                diff=", ".join(d["differences"])))
        for e in certs["linkedin_only"]:
            lines.append("- linkedin_only — {name} · {authority} ({year}) — {action}".format(
                name=e["name"], authority=e.get("authority") or "-", year=e.get("year") or "-",
                action=L["li_only_action"]))
        for e in certs["hub_only"]:
            lines.append("- hub_only — {name} · {issuer} ({year}) — {action}".format(
                name=e["name"], issuer=e.get("issuer") or "-", year=e.get("year") or "-",
                action=L["hub_only_action"]))
    lines.append("")

    lines.append("## {0}".format(L["h_headline"]))
    lines.append("")
    head = data["headline"]
    if head["category"] == "divergent":
        lines.append("- hub professional_title: {0}".format(head["hub_professional_title"]))
        lines.append("- LinkedIn headline: {0}".format(head["linkedin_headline"]))
        lines.append("- {0}".format(L["head_divergent"]))
    elif head["category"] == "consistent":
        lines.append("- {0}".format(L["head_consistent"]))
    elif head["category"] == "linkedin_only":
        lines.append("- LinkedIn headline: {0} — {1}".format(
            head["linkedin_headline"], L["head_li_only"]))
    else:
        lines.append("- {0}".format(L["head_na"]))
        if head.get("hub_professional_title"):
            lines.append("- hub professional_title: {0}".format(head["hub_professional_title"]))
    if head.get("linkedin_about"):
        lines.append("- {0}".format(L["about_li"].format(n=len(head["linkedin_about"]))))
    elif head.get("hub_summary_present"):
        lines.append("- {0}".format(L["about_missing"]))
    lines.append("")

    lines.append("## {0}".format(L["h_export"]))
    lines.append("")
    lines.append("- {0}: {1}".format(L["export_dir"], data["export_dir"]))
    lines.append("- {0}: {1}".format(L["hub_path"], data["hub"]))
    if data.get("export_date"):
        lines.append("- {0}: {1}".format(L["export_date"], data["export_date"]))
    else:
        lines.append("- {0}: {1}".format(L["export_date"], L["export_unknown"]))
    if data.get("export_date"):
        if data.get("export_stale"):
            lines.append("- {0}".format(L["stale"].format(days=data["export_stale_days"])))
        else:
            lines.append("- {0}".format(L["fresh"].format(days=data["export_stale_days"])))
    lines.append("- {0}".format(L["oauth"]))
    text = "\n".join(lines)
    return text + "\n"


# ---------------------------------------------------------------------------
# Payload assembly
# ---------------------------------------------------------------------------

def build_payload(args, hub, export_dir, found):
    profile = parse_profile_row(found)

    li_positions, missing_pos = parse_positions(found)
    li_skills, missing_skills = parse_skills(found)
    li_edu, missing_edu = parse_education(found)
    li_langs, missing_langs = parse_languages(found)
    li_certs, missing_certs = parse_certifications(found)

    def section_box(missing_file):
        box = {"available": missing_file is None}
        if missing_file:
            box["missing_file"] = missing_file
        return box

    sections = {}

    exp = section_box(missing_pos)
    sections["experience"] = exp
    # An empty Positions.csv is treated as "no data to compare" (a LinkedIn
    # profile virtually always lists positions, so an empty file signals a
    # partial export): hub entries are NOT classified as hub_only then.
    if exp["available"] and not li_positions and hub.get("experience"):
        exp["available"] = False
        exp["empty_source"] = True
    if exp["available"]:
        exp.update(diff_positions(hub.get("experience", []), li_positions))
        exp["counts"] = count_cat(exp)
        exp["no_linkedin_positions"] = not li_positions

    skills = section_box(missing_skills)
    sections["skills"] = skills
    if skills["available"]:
        skills.update(diff_skills(hub.get("skills", []), li_skills,
                                  hub.get("languages", []), hub))
        skills["counts"] = count_cat(skills)

    edu = section_box(missing_edu)
    sections["education"] = edu
    if edu["available"]:
        edu.update(diff_education(hub.get("education", []), li_edu))
        edu["counts"] = count_cat(edu)

    langs = section_box(missing_langs)
    sections["languages"] = langs
    if langs["available"]:
        langs.update(diff_languages(hub.get("languages", []), li_langs))
        langs["counts"] = count_cat(langs)

    certs = section_box(missing_certs)
    sections["certifications"] = certs
    if certs["available"]:
        certs.update(diff_certifications(hub.get("certifications", []), li_certs))
        certs["counts"] = count_cat(certs)

    headline = diff_headline(hub, profile)

    export_date = None
    mtimes = []
    for path in found.values():
        try:
            mtimes.append(os.path.getmtime(path))
        except OSError:
            continue
    if mtimes:
        export_date = datetime.datetime.fromtimestamp(max(mtimes)).date()

    stale_days = None
    stale = False
    if export_date is not None:
        stale_days = (datetime.date.today() - export_date).days
        stale = stale_days > args.stale_days

    return {
        "schema": "cv/linkedin-sync@1",
        "hub": args.hub,
        "export_dir": export_dir,
        "export_date": export_date.isoformat() if export_date else None,
        "export_stale": stale,
        "export_stale_days": stale_days,
        "language": args.lang,
        "headline": headline,
        "sections": sections,
        "notes": [],
        "categories": ["linkedin_only", "hub_only", "divergent", "consistent"],
    }


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="linkedin-sync.py",
        description="Diff the official LinkedIn Download My Data export against "
                    "hub.json (offline; never scrapes, never accepts a URL).")
    parser.add_argument("candidate_dir",
                        help="candidate directory (~/career/<candidate-name>)")
    parser.add_argument("--export", dest="export_dir", default=None,
                        help="LinkedIn export directory (default: "
                             "<candidate-dir>/entradas/linkedin)")
    parser.add_argument("--hub", dest="hub", default=None,
                        help="hub.json path (default: <candidate-dir>/hub.json)")
    parser.add_argument("--out-dir", dest="out_dir", default=None,
                        help="output directory for linkedin-sync.md/.json "
                             "(default: <candidate-dir>)")
    parser.add_argument("--lang", dest="lang", default=None,
                        choices=["pt", "en", "es"],
                        help="report language (default: detected from the hub)")
    parser.add_argument("--stale-days", dest="stale_days", type=int, default=180,
                        help="staleness threshold in days (default: 180)")
    args = parser.parse_args(argv)

    def url_refused(value):
        return bool(value) and re.match(r"^[a-z][a-z0-9+.-]*://",
                                        str(value).strip(), re.IGNORECASE)

    candidate = os.path.abspath(args.candidate_dir)
    export_dir = os.path.abspath(args.export_dir) if args.export_dir \
        else os.path.join(candidate, "entradas", "linkedin")
    hub_path = os.path.abspath(args.hub) if args.hub \
        else os.path.join(candidate, "hub.json")
    out_dir = os.path.abspath(args.out_dir) if args.out_dir else candidate

    if url_refused(args.export_dir):
        print("error: a URL was given as the export directory ({0}) — the sync "
              "only reads a local LinkedIn Download My Data export directory; "
              "linkedin.com is never scraped.".format(args.export_dir), file=sys.stderr)
        return 1
    if url_refused(args.hub):
        print("error: a URL was given as the hub path — hub.json must be a "
              "local file.", file=sys.stderr)
        return 1
    if not os.path.isdir(export_dir):
        print("error: LinkedIn export directory not found: {0}".format(export_dir), file=sys.stderr)
        print("This tool compares the hub against the OFFICIAL LinkedIn export "
              "('Download My Data').", file=sys.stderr)
        print("Get one at: LinkedIn -> Settings & Privacy -> Data privacy -> "
              "'Get a copy of your data' (the profile sections are enough), "
              "unzip it and point --export at the extracted directory.",
              file=sys.stderr)
        print("No report was generated.", file=sys.stderr)
        return 1

    hub, hub_error = load_hub(hub_path)
    if hub_error:
        print("error: {0}".format(hub_error), file=sys.stderr)
        print("No report was generated.", file=sys.stderr)
        return 1

    found = discover_csv_files(export_dir)
    core = [k for k in ("profile", "profile_summary", "positions", "skills",
                        "education", "languages") if k in found]
    if not core:
        print("error: no recognizable LinkedIn Download My Data CSV files were "
              "found under {0} (looked for Profile/Profile Summary, Positions, "
              "Skills, Education, Languages, Certifications).".format(export_dir), file=sys.stderr)
        print("No report was generated.", file=sys.stderr)
        return 1

    args.hub = hub_path
    args.lang = detect_language(hub, args.lang)

    data = build_payload(args, hub, export_dir, found)

    md = render_report(data, args.lang)

    json_path = os.path.join(out_dir, "linkedin-sync.json")
    md_path = os.path.join(out_dir, "linkedin-sync.md")
    os.makedirs(out_dir, exist_ok=True)
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    with open(md_path, "w", encoding="utf-8") as f:
        f.write(md)

    print(MSGS[args.lang]["written"])
    print("- {0}".format(md_path))
    print("- {0}".format(json_path))
    print("language: {0}".format(args.lang))
    return 0


if __name__ == "__main__":
    sys.exit(main())
