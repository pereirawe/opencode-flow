---
name: cv-linkedin-sync
description: Offline LinkedIn ↔ hub.json sync diff — parses the OFFICIAL LinkedIn "Download My Data" export (a local directory of CSVs; never scraped, never a URL) and diffs it against hub.json (headline, positions/experience, skills, education, languages, certifications), producing linkedin-sync.md (report in the user's language) + linkedin-sync.json (machine-readable, consumed by cv-linkedin and cv-optimize). Use when the user wants to compare the real LinkedIn profile with the hub, refresh an outdated hub from the official export, or decide which skills to add/promote/remove on LinkedIn ("sync do LinkedIn", "comparar LinkedIn com hub", "diff linkedin", "export oficial do LinkedIn", "Download My Data", "atualizar hub pelo linkedin" also trigger this skill). Career sector. Powered by scripts/cv/linkedin-sync.py.
---

# CV LinkedIn Sync — offline LinkedIn ↔ hub.json diff

Compares the candidate's REAL LinkedIn profile against `hub.json` using the
official LinkedIn **Download My Data** export. The diff covers headline/About,
positions (Work/Experience), education, skills, languages and certifications
(when present in the export) and classifies every entry into four categories:
`consistent`, `divergent`, `linkedin_only`, `hub_only` — plus actionable
per-skill recommendations (add/promote/remove/keep) prioritizing the profile
objective and the hub's dominant skill categories.

This skill is the **single source of truth** for the parse rules, the diff
semantics, the OAuth limitation and the consumption contract. The behaviour
is implemented by `scripts/cv/linkedin-sync.py` (stdlib only); never change
the parser without updating this document (and vice-versa).

## 1. Input — the official export (never scraping, never a URL)

1. **Input is a local directory** with the official LinkedIn export: the
   directory extracted from the `Download My Data` ZIP. Default location:
   `~/career/<candidate-name>/entradas/linkedin/` (same convention as the
   cv-hub inputs). An explicit `--export DIR` overrides it.
2. **NEVER scrape linkedin.com** and **NEVER accept a URL** — a URL input is
   refused (exit 1) with a clear message. The sync is fully offline.
3. **Export absent** → the script exits non-zero with a message pointing to
   LinkedIn → Settings & Privacy → Data privacy → "Get a copy of your data"
   and generates NO empty report.
4. The script reads only the columns it needs from the export CSVs
   (tolerant, case/whitespace-insensitive header matching). **Sensitive
   columns of Profile.csv** (Address, Birth Date, Zip Code, phone, e-mail)
   are never read nor copied into the outputs.

### Which files are used

| hub side | export file(s) | notes |
| --- | --- | --- |
| `summary`, `personal_info.professional_title` | `Profile.csv` (columns `Headline`, `Summary`) — fallback `Profile Summary.csv` (free-form cell) | headline may be absent from the export → reported `not_available_in_export`, never guessed |
| `experience` | `Positions.csv` (`Company Name, Title, Description, Location, Started On, Finished On`) | |
| `skills` | `Skills.csv` (`Name`) | |
| `education` | `Education.csv` (`School Name, Start Date, End Date, Notes, Degree Name, Activities`) | |
| `languages` | `Languages.csv` (`Name, Proficiency`) | |
| `certifications` | `Certifications.csv` (older exports; name/authority/date columns) | file may be absent or empty → section reports "not comparable", hub certifications are NOT classified as `hub_only` |

Missing **optional** files (e.g. Certifications.csv) produce a specific
warning and are NOT a total failure. A directory with none of the core files
(Profile/Profile Summary, Positions, Skills, Education, Languages) is
rejected as "not a Download My Data export directory".

## 2. Parse rules (tolerant by design)

1. **CSV reading** uses the Python 3 stdlib `csv` module (quoted multi-line
   cells intact), UTF-8 with BOM tolerance, latin-1 fallback; blank rows are
   skipped.
2. **File discovery** matches CSV stems case-insensitively at the export root
   first, then one subdirectory level (`Certifications_1.csv` and similar
   suffixed variants are accepted) — the general Download My Data layout is a
   directory of CSVs at the top level with some nested folders.
3. **Header matching** is case-insensitive, whitespace-normalized and
   accent-insensitive with per-column aliases (e.g. `started on`, `start
   date`, `data de início` → start; `finished on`, `end date`, `fim` → end;
   `company name`, `empresa` → company; ...). Unmatched columns yield an
   empty value, never a crash.
4. **Name normalization** (`norm`): lowercase, accents stripped (NFKD),
   non-alphanumeric collapsed to spaces, digit↔letter boundaries split
   ("93.9FM" → "93 9 fm").
5. **Date normalization** accepts `YYYY`, `YYYY-MM[-DD]`, `MM/YYYY` and month
   names in English/Portuguese/Spanish (`Mar 2021`, `março de 2021`,
   `Jan/2021`, ...); `present`/`atual`/blank → open-ended. Comparison is
   coarse-tolerant: a `YYYY` does not contradict a `YYYY-MM` with the same
   year; open-ended equals open-ended.
6. **Organization/school matching** (`org_match`): normalized token sets
   equal OR the smaller set (≥ 3 tokens) fully contained in the larger one —
   absorbs qualifiers such as "URBE - Universidad Rafael Belloso Chacín" vs
   "Universidad Rafael Belloso Chacín".
7. **Skill matching** (`skill_match`): normalized token sets equal OR one
   contained in the other when the larger side has ≥ 2 tokens ("MySQL & SQL"
   covers a LinkedIn-only "SQL"; "Git" never aliases "GitHub").
8. **Spoken languages** are canonicalized across spellings/locales
   ("Espanhol"/"Español"/"Spanish" → `spanish`; "Inglês"/"English" →
   `english`; ...). LinkedIn proficiency labels (EN/PT/ES official labels)
   are mapped to the hub `languages.level` enum (`Native or bilingual
   proficiency` → `native`, `Full professional proficiency` → `fluent`,
   `Professional working proficiency` → `advanced`, `Limited working
   proficiency` → `conversational`, `Elementary proficiency` → `basic`);
   unrecognized labels are reported raw (`level: null`), never guessed.
9. **Headline**: read from the `Headline` column of Profile.csv when present.
   Best-effort fallback for exports without Profile.csv: the first line
   (≤ 220 chars) of the Profile Summary.csv cell. When the export has no
   headline at all the state is `not_available_in_export` — the report tells
   the user to check it manually instead of fabricating a comparison.
10. **Empty Positions.csv / Certifications.csv** are treated as "no data to
    compare" (a LinkedIn profile virtually always lists positions, and an
    empty Certifications.csv carries no per-certification data — both signal
    partial/empty sources): the hub positions/certifications are NOT
    classified as `hub_only` and a clear note is emitted. Empty
    Skills/Education/Languages files are real signals (the member lists none
    in those sections) and diff normally.

## 3. Diff semantics (the four categories)

Every compared section classifies each entry as exactly one of:

- `consistent` — present and equal on both sides (after normalization);
- `divergent` — matched on both sides (same company/school/language/skill)
  but the fields differ (`title`, `start_date`, `end_date`, `course`, `level`,
  `year`, `issuer`, or `order` when ≥ 2 matched positions of the same company
  appear in a different relative order on each side). The stale side should be
  aligned — the export is the most recent source at its export date;
- `linkedin_only` — on LinkedIn, missing from the hub → action: **add to the
  hub**;
- `hub_only` — in the hub, missing from LinkedIn → action: **add to
  LinkedIn**.

Sections compared: `experience` (paired by company → title → identical date
range), `education` (by institution), `languages` (by canonical language
name), `certifications` (by name), `skills`, and the `headline`/About
(professional_title vs the export headline).

### Skills recommendations (add/promote/remove/keep)

For every skill in the union the JSON emits a structured recommendation:

- `hub_only` → `add_to_linkedin` (all hub skills are worth proposing).
- `linkedin_only` → scored against the hub context:
  - token overlap with `profile_objective` (issue #222: `type` + `target_role`
    + `note`) → `add_to_hub` (high);
  - token overlap with a hub `primary` skill name (variant/close name) →
    `add_to_hub` (high); with a skill of the hub's dominant categories →
    `add_to_hub` (medium);
  - declared objective present but no overlap → `remove_from_linkedin` (low);
  - no objective and no hub reference → `keep` (low) with reason
    `no_hub_reference` — never recommend removal without a declared
    objective;
  - a spoken-language skill already recorded in `hub.languages` →
    `keep` with reason `language_in_hub` (handled by the languages diff —
    never proposed as a tech-skill add).
- `consistent` → `promote_on_linkedin` when relevant to the objective/primary/
  dominant areas (keep it near the top of the LinkedIn ranking), else `keep`.

Dominant categories = the top-2 hub skill `category` values by count (tie →
alphabetical). Relevance labels are deterministic rules over real data —
never fabricated.

**Count semantics (skills).** The skills diff counts exclude LinkedIn skills
that are spoken languages already recorded in `hub.languages` — those are
routed to the languages diff (Skills.csv lists them as endorsable skills, but
they are not tech-skill candidates). Therefore, per the count line,
`LinkedIn skills = consistent + linkedin_only` (a multilingual Skills.csv does
not inflate the totals).

**Hub-skill pairing (no drops, no duplicates).** Hub skills are matched
ONE-TO-ONE with LinkedIn skills (a hub entry is consumed when a LinkedIn skill
pairs with it — the same used-set pattern as positions). A hub entry left
unconsumed but still covered by a LinkedIn tech skill under the subset
semantics (hub `{React, React Native}` × LinkedIn `{React}`) is emitted ONCE
as `consistent`; only genuinely uncovered leftovers become `hub_only`. Hub
skills are therefore never dropped from the JSON and never duplicated.

## 4. OAuth limitation (documented decision)

"Sign in with LinkedIn" (OAuth/OpenID Connect) only returns **name, e-mail
and photo** — it cannot read the headline, positions, skills, education or
languages of the profile. A full sync therefore REQUIRES the official
Download My Data export. The report states this so the user understands why a
manual export step is part of the flow. OAuth is never used as a data source.

## 5. Outputs (never edits hub.json)

Outputs are written next to the hub (default `~/career/<candidate-name>/`):

- `linkedin-sync.json` — machine-readable payload (schema
  `cv/linkedin-sync@1`): `export_dir`, `export_date` (max mtime of the parsed
  CSVs), `export_stale`/`export_stale_days`, `language`, `headline`,
  per-section `sections.*` with the four category arrays + `counts`, and
  `skills.recommendations` (name, side, action, priority, reason — English
  protocol tokens, language-neutral).
- `linkedin-sync.md` — the human report in the user's language, following
  `standards/cv-analysis.md`: exactly one H1, H2 sections in a fixed order,
  no metadata header line, bullets/simple lists only, no sensitive data,
  nothing invented. It declares the detected export date and the staleness
  caveat ("export older than N days (default 180) → request a fresh one").

Report language resolution: `--lang pt|en|es` wins; otherwise the hub summary
language (the `summary_i18n` key whose value equals the top-level `summary`;
fall back to the first available pt/en/es key); final fallback English.
Protocol tokens (`consistent`, `linkedin_only`, `add_to_linkedin`, ...) stay
English in any language.

`hub.json` is NEVER modified by the sync — the outputs only propose actions
(categories + recommendations). Everything in the outputs comes from the
export or the hub.

## 6. Consumption contract (cv-linkedin #223, cv-optimize #226)

The JSON is the interface for the later consumer issues (do NOT wire them
here):

- `sections.skills.recommendations[]` feeds cv-linkedin's skills ranking
  (top-50 relevance): `add_to_linkedin`/`promote_on_linkedin` items are
  candidates to feature near the top; `remove_from_linkedin` items are
  deprioritization candidates; `keep`/`no_hub_reference` items need human
  review.
- `headline.category` (`divergent`/`not_available_in_export`), the
  `divergent` position/education entries and `sections.languages` feed the
  LinkedIn action plan of cv-optimize (banner/headline/About/experience/
  skills consistency with `linkedin-optimization.md`).
- Consumers must read `hub.json` for the full entries (the diff only carries
  identifying fields) and must never treat the report as a substitute for
  the hub.

## 7. Usage

```
python3 $SCRIPTS_DIR/cv/linkedin-sync.py ~/career/<candidate-name> [--export DIR] [--lang pt|en|es]
```

Run with the candidate dir; exit codes: 0 = success, 1 = operational failure
(no export / URL / no export files / invalid hub), 2 = usage error. Validate
the hub first with `python3 $SCRIPTS_DIR/cv/validate.py hub.json` (exit 0).

## 8. Report

Tell the user: the output paths (`linkedin-sync.md` + `linkedin-sync.json`),
the detected export date and staleness verdict, and the per-section counts
(consistent/divergent/linkedin_only/hub_only) plus the number of skill
recommendations — nothing invented, hub.json untouched.
