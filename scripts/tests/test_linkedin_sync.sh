#!/usr/bin/env bash
# Tests for scripts/cv/linkedin-sync.py (issue #225) — offline LinkedIn
# "Download My Data" export <-> hub.json sync diff.
# Self-contained: generates its own fixtures under a temp dir, no network, no
# TTY, no changes outside the temp dir. Covers the issue's Tests lines:
#   fixture diff -> four categories correct; hub-only skill -> add to LinkedIn;
#   LinkedIn-only position -> add to hub; missing export -> exit != 0 + message;
#   linkedin-sync.json parseable with the four categories present.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

t_begin "test_linkedin_sync"

SYNC="$SCRIPT_DIR/../cv/linkedin-sync.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/candidate" "$TMP/export" "$TMP/out"

# --- fixtures ---------------------------------------------------------------
# hub.json (main fixture) + a realistic Download My Data export layout.
python3 - "$TMP" <<'PYEOF'
import json, os, sys
tmp = sys.argv[1]

hub = {
    "personal_info": {"name": "John Test", "professional_title": "Tech Lead & Senior Developer"},
    "summary": "Resumo em ingles para testes.",
    "summary_i18n": {"en": "Resumo em ingles para testes."},
    "experience": [
        {"company": "Acme", "title": "Developer", "start_date": "2019-01", "end_date": "2021-12"},
        {"company": "Beta Corp", "title": "Manager", "start_date": "2018-06", "end_date": "2020-05"},
        {"company": "Delta Ltd", "title": "Director", "start_date": "2015-01", "end_date": "2018-12"},
        {"company": "Codetomika", "title": "CEO", "start_date": "2022-03", "end_date": "atual", "current": True},
    ],
    "education": [
        {"institution": "URBE - Universidad Rafael Belloso Chacin",
         "course": "Engenharia Eletronica", "start_date": "2008", "end_date": "2012"},
        {"institution": "UNIR", "course": "Tecnologo em Informatica",
         "start_date": "2012", "end_date": "2017"},
    ],
    "skills": [
        {"name": "Python", "category": "language", "importance": "primary"},
        {"name": "Docker", "category": "tool", "importance": "primary"},
        {"name": "Node.js", "category": "language", "importance": "primary"},
        {"name": "PostgreSQL", "category": "data", "importance": "primary"},
        {"name": "Git", "category": "tool", "importance": "secondary"},
    ],
    "certifications": [
        {"name": "AWS Certified Developer", "issuer": "AWS", "year": "2023"},
        {"name": "PMP", "issuer": "PMI", "year": "2020"},
    ],
    "projects": [],
    "languages": [
        {"language": "Espanhol", "level": "native"},
        {"language": "Ingles", "level": "fluent"},
        {"language": "Portugues", "level": "native"},
    ],
    "links": [],
}
json.dump(hub, open(os.path.join(tmp, "candidate", "hub.json"), "w"), ensure_ascii=False)

export_dir = os.path.join(tmp, "export")

def wcsv(name, header, rows):
    with open(os.path.join(export_dir, name), "w", encoding="utf-8") as f:
        f.write(",".join(header) + "\n")
        for r in rows:
            f.write(",".join(str(c) for c in r) + "\n")

wcsv("Profile Summary.csv", ["Profile Summary"], [])
wcsv("Profile.csv",
     ["First Name", "Last Name", "Address", "Birth Date", "Headline", "Summary",
      "Industry", "Zip Code"],
     [["John", "Test", "Secret Street 99", "Jun 15, 1987",
       "Head of Engineering | AI",
       "Experienced engineer leading teams.",
       "IT Services", "81230-000"]])
wcsv("Positions.csv",
     ["Company Name", "Title", "Description", "Location", "Started On", "Finished On"],
     [["Acme", "Developer", "Built things", "Remote", "2019-01", "2021-12"],
      ["Beta Corp", "Manager", "", "NYC", "2018-03", "2020-05"],
      ["Gamma Inc", "Analyst", "", "Chicago", "2022-01", ""],
      ["Codetomika", "CEO", "", "Remote", "2022-03", ""]])
wcsv("Skills.csv", ["Name"],
     [["Python"], ["Docker"], ["Laravel"], ["Microsoft Excel"], ["Ingles"]])
wcsv("Education.csv",
     ["School Name", "Start Date", "End Date", "Notes", "Degree Name", "Activities"],
     [["Universidad Rafael Belloso Chacin", "1999", "2004", "", "", ""],
      ["MLK", "1998", "2004", "", "", ""]])
wcsv("Languages.csv", ["Name", "Proficiency"],
     [["Espanhol", "Native or bilingual proficiency"],
      ["Ingles", "Professional working proficiency"],
      ["Frances", "Elementary proficiency"]])
wcsv("Certifications.csv",
     ["Name", "Start Date", "End Date", "License Number", "Authority"],
     [["AWS Certified Developer", "2023", "", "", "AWS"],
      ["Scrum Master", "2022", "", "", "Scrum Alliance"]])
PYEOF

cp "$TMP/candidate/hub.json" "$TMP/hub.before.json"

# --- 1. main run (English forced for stable greps) --------------------------
set +e
SYNC_OUT="$(python3 "$SYNC" "$TMP/candidate" --export "$TMP/export" \
  --out-dir "$TMP/out" --lang en 2>&1)"
RC=$?
set -e
assert_eq "0" "$RC" "linkedin-sync.py exits 0 on a valid export + hub"
assert_eq "1" "$(test -s "$TMP/out/linkedin-sync.md" && echo 1 || echo 0)" "linkedin-sync.md written"
assert_eq "1" "$(test -s "$TMP/out/linkedin-sync.json" && echo 1 || echo 0)" "linkedin-sync.json written"

# hub.json must be untouched (BR 6: the sync never edits the hub)
if cmp -s "$TMP/hub.before.json" "$TMP/candidate/hub.json"; then
  t_ok "hub.json byte-identical after the sync"
else
  t_fail "hub.json was modified by the sync"
fi

# --- 2. report greps (Tests 2 & 3 + honest-output checks) -------------------
assert_contains "$TMP/out/linkedin-sync.md" "hub_only — Delta Ltd" \
  "hub-only position listed in the report"
assert_contains "$TMP/out/linkedin-sync.md" "consider adding to LinkedIn" \
  "hub-only position recommends adding to LinkedIn (Tests: 2 pattern)"
assert_contains "$TMP/out/linkedin-sync.md" "linkedin_only — Gamma Inc" \
  "LinkedIn-only position listed in the report"
assert_contains "$TMP/out/linkedin-sync.md" "consider adding to the hub" \
  "LinkedIn-only position recommends adding to the hub (Tests: 3 pattern)"
assert_contains "$TMP/out/linkedin-sync.md" "PostgreSQL — action: add to LinkedIn" \
  "hub-only skill PostgreSQL recommends add to LinkedIn (Tests: 2 grep)"
assert_eq "3" "$(count_occurrences "$TMP/out/linkedin-sync.md" "action: add to LinkedIn")" \
  "three hub-only skills recommend add to LinkedIn (Node.js, PostgreSQL, Git)"
assert_contains "$TMP/out/linkedin-sync.md" "hub professional_title and the LinkedIn headline differ" \
  "divergent headline reported honestly"
assert_not_contains "$TMP/out/linkedin-sync.md" "Secret Street" \
  "no sensitive Profile.csv columns (address) leak into the report"
assert_not_contains "$TMP/out/linkedin-sync.json" "Secret Street" \
  "no sensitive Profile.csv columns (address) leak into the JSON"
assert_contains "$TMP/out/linkedin-sync.md" "Download My Data" \
  "report states the official-export requirement (OAuth limitation)"

# --- 3. JSON structural + classification checks (Tests 1 & 5) ---------------
if python3 - "$TMP/out/linkedin-sync.json" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))

# Tests: 5 — parseable and the 4 categories are present
assert d["categories"] == ["linkedin_only", "hub_only", "divergent", "consistent"], d["categories"]
exp = d["sections"]["experience"]
for key in ("consistent", "divergent", "hub_only", "linkedin_only"):
    assert key in exp and isinstance(exp[key], list), key
assert exp["counts"] == {"consistent": 2, "divergent": 1, "linkedin_only": 1, "hub_only": 1}, exp["counts"]

# Tests: 1 — positions classify correctly
con = [(e["company"], e["title"]) for e in exp["consistent"]]
assert ("Acme", "Developer") in con, con
assert ("Codetomika", "CEO") in con, con
assert len(exp["divergent"]) == 1 and exp["divergent"][0]["company"] == "Beta Corp", exp["divergent"]
assert "start_date" in exp["divergent"][0]["differences"], exp["divergent"][0]["differences"]
assert exp["divergent"][0]["hub"]["start_date"] == "2018-06"
assert exp["divergent"][0]["linkedin"]["start_date"] == "2018-03"
assert [e["company"] for e in exp["linkedin_only"]] == ["Gamma Inc"], exp["linkedin_only"]
assert [e["company"] for e in exp["hub_only"]] == ["Delta Ltd"], exp["hub_only"]

# skills classification + recommendations
sk = d["sections"]["skills"]
assert sk["counts"] == {"consistent": 2, "divergent": 0, "linkedin_only": 2, "hub_only": 3}, sk["counts"]
recs = {r["name"]: r for r in sk["recommendations"]}
assert recs["PostgreSQL"]["action"] == "add_to_linkedin" and recs["PostgreSQL"]["side"] == "hub_only", recs["PostgreSQL"]
assert recs["Python"]["action"] == "promote_on_linkedin", recs["Python"]
assert recs["Ingles"]["action"] == "keep" and recs["Ingles"]["reason"] == "language_in_hub", recs["Ingles"]
assert "Laravel" in sk["linkedin_only"] and "Microsoft Excel" in sk["linkedin_only"]

# education / languages / certifications / headline
edu = d["sections"]["education"]
assert edu["counts"]["divergent"] == 1 and edu["divergent"][0]["institution"].startswith("URBE"), edu["counts"]
assert edu["counts"]["hub_only"] == 1 and edu["hub_only"][0]["institution"] == "UNIR"
assert edu["counts"]["linkedin_only"] == 1 and edu["linkedin_only"][0]["school"] == "MLK"
langs = d["sections"]["languages"]
assert langs["counts"] == {"consistent": 1, "divergent": 1, "linkedin_only": 1, "hub_only": 1}, langs["counts"]
div_lang = langs["divergent"][0]
assert div_lang["hub"]["level"] == "fluent" and div_lang["linkedin"]["level"] == "advanced", div_lang
certs = d["sections"]["certifications"]
assert certs["counts"]["consistent"] == 1 and certs["consistent"][0]["name"] == "AWS Certified Developer"
assert certs["counts"]["hub_only"] == 1 and certs["hub_only"][0]["name"] == "PMP"
assert certs["counts"]["linkedin_only"] == 1 and certs["linkedin_only"][0]["name"] == "Scrum Master"
assert d["headline"]["category"] == "divergent", d["headline"]
assert d["language"] == "en"
assert d["export_date"], "export date detected from file mtimes"
PYEOF
then
  t_ok "linkedin-sync.json parses and classifies every section correctly (Tests 1 & 5)"
else
  t_fail "JSON classification incorrect (Tests 1 & 5)"
fi

# --- 4. export missing -> exit != 0 + Download My Data message (Tests: 4) ---
mkdir -p "$TMP/nocandidate"
cp "$TMP/candidate/hub.json" "$TMP/nocandidate/hub.json"
set +e
NOEXP_OUT="$(python3 "$SYNC" "$TMP/nocandidate" 2>&1)"
RC_NOEXP=$?
set -e
assert_eq "1" "$RC_NOEXP" "missing export dir -> exit != 0 (Tests: 4)"
if [[ "$NOEXP_OUT" == *"Download My Data"* ]]; then
  t_ok "missing export message points to LinkedIn Download My Data"
else
  t_fail "missing export message lacks 'Download My Data': $NOEXP_OUT"
fi
assert_eq "0" "$(test -f "$TMP/nocandidate/linkedin-sync.md" && echo 1 || echo 0)" \
  "no empty linkedin-sync.md report on a missing export"
assert_eq "0" "$(test -f "$TMP/nocandidate/linkedin-sync.json" && echo 1 || echo 0)" \
  "no empty linkedin-sync.json on a missing export"

# --- 5. URL refused (AC 3) ---------------------------------------------------
set +e
URL_OUT="$(python3 "$SYNC" "$TMP/candidate" --export "https://linkedin.com/in/x" \
  --out-dir "$TMP/out-url" 2>&1)"
RC_URL=$?
set -e
assert_eq "1" "$RC_URL" "a URL as the export dir is refused"
if [[ "$URL_OUT" == *"never scraped"* ]]; then
  t_ok "URL refusal message states linkedin.com is never scraped"
else
  t_fail "URL refusal message missing: $URL_OUT"
fi
assert_eq "0" "$(test -f "$TMP/out-url/linkedin-sync.md" && echo 1 || echo 0)" \
  "no report generated for a refused URL"

# --- 6. default report language follows the hub summary language (BR 5) -----
mkdir -p "$TMP/ptcand"
python3 - "$TMP" <<'PYEOF'
import json, os, sys
tmp = sys.argv[1]
hub = {
    "personal_info": {"name": "Joao Test"},
    "summary": "Resumo em portugues.",
    "summary_i18n": {"pt": "Resumo em portugues."},
    "experience": [], "education": [], "skills": [], "certifications": [],
    "projects": [], "languages": [], "links": [],
}
json.dump(hub, open(os.path.join(tmp, "ptcand", "hub.json"), "w"), ensure_ascii=False)
export_dir = os.path.join(tmp, "ptcand", "entradas", "linkedin")
os.makedirs(export_dir, exist_ok=True)
open(os.path.join(export_dir, "Positions.csv"), "w").write(
    "Company Name,Title,Description,Location,Started On,Finished On\n"
    "Acme,Developer,,Remote,2019-01,\n")
PYEOF
set +e
python3 "$SYNC" "$TMP/ptcand" >/dev/null 2>&1
RC_PT=$?
set -e
assert_eq "0" "$RC_PT" "pt-language run exits 0 (default export resolution)"
assert_contains "$TMP/ptcand/linkedin-sync.md" "# Sincronização LinkedIn ↔ Hub" \
  "report defaults to the hub summary language (pt)"

# --- 7. objective-driven remove recommendation (BR 4) -----------------------
mkdir -p "$TMP/objcand" "$TMP/objexp"
python3 - "$TMP" <<'PYEOF'
import json, os, sys
tmp = sys.argv[1]
hub = {
    "personal_info": {"name": "Obj Test", "professional_title": "Data Engineer"},
    "summary": "s",
    "summary_i18n": {"en": "s"},
    "profile_objective": {"type": "job_search", "target_role": "Senior SQL Developer"},
    "experience": [], "education": [],
    "skills": [{"name": "Python", "category": "language", "importance": "primary"}],
    "certifications": [], "projects": [], "languages": [], "links": [],
}
json.dump(hub, open(os.path.join(tmp, "objcand", "hub.json"), "w"), ensure_ascii=False)
with open(os.path.join(tmp, "objexp", "Skills.csv"), "w", encoding="utf-8") as f:
    f.write("Name\nSQL\nMicrosoft Excel\n")
with open(os.path.join(tmp, "objexp", "Profile.csv"), "w", encoding="utf-8") as f:
    f.write("First Name,Last Name,Headline,Summary\nObj,Test,Data Engineer,About text.\n")
with open(os.path.join(tmp, "objexp", "Positions.csv"), "w", encoding="utf-8") as f:
    f.write("Company Name,Title,Description,Location,Started On,Finished On\n")
PYEOF
set +e
python3 "$SYNC" "$TMP/objcand" --export "$TMP/objexp" --out-dir "$TMP/objout" --lang en >/dev/null 2>&1
RC_OBJ=$?
set -e
assert_eq "0" "$RC_OBJ" "objective run exits 0"
if python3 - "$TMP/objout/linkedin-sync.json" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
recs = {r["name"]: r for r in d["sections"]["skills"]["recommendations"]}
# SQL overlaps the declared objective (target_role) -> add to hub
assert recs["SQL"]["action"] == "add_to_hub" and recs["SQL"]["priority"] == "high", recs["SQL"]
# Microsoft Excel does not align with the declared objective -> remove/deprioritize
assert recs["Microsoft Excel"]["action"] == "remove_from_linkedin", recs["Microsoft Excel"]
assert recs["Python"]["action"] == "add_to_linkedin", recs["Python"]
PYEOF
then
  t_ok "objective-driven skill recommendations (add_to_hub / remove_from_linkedin)"
else
  t_fail "objective-driven skill recommendations incorrect (BR 4)"
fi
assert_contains "$TMP/objout/linkedin-sync.md" "remove/deprioritize on LinkedIn" \
  "remove recommendation rendered in the report"

# --- 8. empty Positions.csv is not treated as 'absent from LinkedIn' --------
mkdir -p "$TMP/emptycand" "$TMP/emptyexp"
python3 - "$TMP" <<'PYEOF'
import json, os, sys
tmp = sys.argv[1]
hub = {
    "personal_info": {"name": "Empty Test"},
    "summary": "s",
    "experience": [{"company": "Acme", "title": "Dev", "start_date": "2020-01"}],
    "education": [], "skills": [], "certifications": [], "projects": [],
    "languages": [], "links": [],
}
json.dump(hub, open(os.path.join(tmp, "emptycand", "hub.json"), "w"), ensure_ascii=False)
with open(os.path.join(tmp, "emptyexp", "Positions.csv"), "w", encoding="utf-8") as f:
    f.write("Company Name,Title,Description,Location,Started On,Finished On\n")
PYEOF
set +e
python3 "$SYNC" "$TMP/emptycand" --export "$TMP/emptyexp" --out-dir "$TMP/emptyout" --lang en >/dev/null 2>&1
RC_EMPTY=$?
set -e
assert_eq "0" "$RC_EMPTY" "empty-Positions.csv run exits 0"
if python3 - "$TMP/emptyout/linkedin-sync.json" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
exp = d["sections"]["experience"]
# An empty Positions.csv makes the section unavailable: nothing is
# classified (no hub_only/linkedin_only/... arrays, no counts).
assert exp["available"] is False and exp.get("empty_source") is True, exp
for key in ("consistent", "divergent", "hub_only", "linkedin_only", "counts"):
    assert key not in exp, "unavailable section must not classify entries: " + key
PYEOF
then
  t_ok "empty Positions.csv -> no hub_only classification (honest, no false positives)"
else
  t_fail "empty Positions.csv handling incorrect"
fi

t_finish
