#!/usr/bin/env bash
# Tests for scripts/marketing/person-validate.py (issue #225 — LinkedIn
# carousel publisher identity validation against person.schema.json).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

t_begin "test_carousel_person"

VALIDATE="$SCRIPT_DIR/../marketing/person-validate.py"
SCHEMA="$SCRIPT_DIR/../../skills/marketing/linkedin-carousel/person.schema.json"
SKILL="$SCRIPT_DIR/../../skills/marketing/linkedin-carousel/SKILL.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# run_pv: invoke the validator capturing output + exit code (python3, NOT bash)
PV_OUT=""; PV_RC=""
run_pv() {
  set +e
  PV_OUT="$(python3 "$VALIDATE" "$@" 2>&1)"
  PV_RC=$?
  set -e
}

# --- fixtures ----------------------------------------------------------------
mkdir -p "$TMP/persons"
cat > "$TMP/persons/valid-full.json" <<'JSON'
{
  "schema": "linkedin-carousel-person-v1",
  "name": "Maria Silva",
  "headline": "Engenheira de dados | transformo dados em decisoes",
  "handle": "in/maria-silva",
  "cta_text": "Salve este post",
  "logo_path": "logo.png"
}
JSON

cat > "$TMP/persons/valid-minimal.json" <<'JSON'
{
  "schema": "linkedin-carousel-person-v1",
  "name": "Maria Silva"
}
JSON

cat > "$TMP/persons/no-schema.json" <<'JSON'
{"name": "Maria Silva"}
JSON

cat > "$TMP/persons/no-name.json" <<'JSON'
{"schema": "linkedin-carousel-person-v1"}
JSON

cat > "$TMP/persons/bad-handle-slash.json" <<'JSON'
{"schema": "linkedin-carousel-person-v1", "name": "Maria", "handle": "/in/maria-silva"}
JSON

cat > "$TMP/persons/bad-handle-space.json" <<'JSON'
{"schema": "linkedin-carousel-person-v1", "name": "Maria", "handle": "in/maria silva"}
JSON

cat > "$TMP/persons/bad-handle-empty.json" <<'JSON'
{"schema": "linkedin-carousel-person-v1", "name": "Maria", "handle": "in/"}
JSON

cat > "$TMP/persons/handle-upper.json" <<'JSON'
{"schema": "linkedin-carousel-person-v1", "name": "Maria", "handle": "in/Maria-Silva"}
JSON

cat > "$TMP/persons/unknown-key.json" <<'JSON'
{"schema": "linkedin-carousel-person-v1", "name": "Maria", "invented_field": "x"}
JSON

cat > "$TMP/persons/bad-type.json" <<'JSON'
{"schema": "linkedin-carousel-person-v1", "name": 42}
JSON

cat > "$TMP/persons/not-json.json" <<'JSON'
{"schema": "linkedin-carousel-person-v1", "name": "quebrado
JSON

printf 'not valid json at all' > "$TMP/persons/garbage.txt"

# --- syntax ------------------------------------------------------------------
set +e
python3 -m py_compile "$VALIDATE"
rc_syntax=$?
set -e
assert_eq "0" "$rc_syntax" "person-validate.py compiles (py_compile)"

# --- usage / IO errors --------------------------------------------------------
run_pv
assert_eq "2" "$PV_RC" "no arguments -> exit 2 (usage)"

run_pv "$TMP/persons/valid-full.json" "$TMP/persons/valid-full.json" "$TMP/persons/valid-full.json"
assert_eq "2" "$PV_RC" "too many arguments -> exit 2 (usage)"

run_pv "$TMP/persons/nope.json"
assert_eq "2" "$PV_RC" "missing person file -> exit 2"

run_pv "$TMP/persons/garbage.txt"
assert_eq "1" "$PV_RC" "malformed JSON file -> exit 1"

# --- valid persons ------------------------------------------------------------
run_pv "$TMP/persons/valid-full.json"
assert_eq "0" "$PV_RC" "full valid person -> exit 0"
if [[ "$PV_OUT" == *"VALID"* ]]; then
  t_ok "valid person prints a VALID verdict"
else
  t_fail "valid person verdict not printed: $PV_OUT"
fi

run_pv "$TMP/persons/valid-minimal.json"
assert_eq "0" "$PV_RC" "minimal valid person (schema+name only) -> exit 0"

# Optional fields omitted are valid (BR 1 — omission rules, never invented).
if [[ "$PV_OUT" == *"VALID"* ]]; then
  t_ok "optional fields omitted still VALID"
else
  t_fail "minimal person not VALID: $PV_OUT"
fi

# --- invalid persons (jsonschema path) ----------------------------------------
run_pv "$TMP/persons/no-schema.json"
assert_eq "1" "$PV_RC" "missing schema -> exit 1"

run_pv "$TMP/persons/no-name.json"
assert_eq "1" "$PV_RC" "missing name -> exit 1"

run_pv "$TMP/persons/bad-handle-slash.json"
assert_eq "1" "$PV_RC" "handle with leading slash -> exit 1 (pattern ^in/...)"
if [[ "$PV_OUT" == *"pattern"* || "$PV_OUT" == *"handle"* ]]; then
  t_ok "bad handle error message mentions the handle/pattern"
else
  t_fail "bad handle message not clear: $PV_OUT"
fi

run_pv "$TMP/persons/bad-handle-space.json"
assert_eq "1" "$PV_RC" "handle with space -> exit 1"

run_pv "$TMP/persons/bad-handle-empty.json"
assert_eq "1" "$PV_RC" "empty handle (in/) -> exit 1"

run_pv "$TMP/persons/handle-upper.json"
assert_eq "0" "$PV_RC" "uppercase handle (in/Maria-Silva) -> exit 0 (class allows A-Z)"

run_pv "$TMP/persons/unknown-key.json"
assert_eq "1" "$PV_RC" "unknown field -> exit 1 (additionalProperties: false)"

run_pv "$TMP/persons/bad-type.json"
assert_eq "1" "$PV_RC" "name with wrong type -> exit 1"

# --- invalid persons (hand-rolled fallback path) ------------------------------
run_pv "$TMP/persons/bad-handle-space.json" "$TMP/../.."
if [[ "$PV_RC" == "2" ]]; then
  t_ok "invalid schema path -> exit 2 (usage)"
else
  t_fail "invalid schema path should exit 2, got $PV_RC"
fi

PERSON_VALIDATE_FALLBACK=1 run_pv "$TMP/persons/valid-full.json"
assert_eq "0" "$PV_RC" "fallback path: full valid person -> exit 0"

PERSON_VALIDATE_FALLBACK=1 run_pv "$TMP/persons/unknown-key.json"
assert_eq "1" "$PV_RC" "fallback path: unknown field -> exit 1"

PERSON_VALIDATE_FALLBACK=1 run_pv "$TMP/persons/bad-handle-slash.json"
assert_eq "1" "$PV_RC" "fallback path: bad handle -> exit 1"

PERSON_VALIDATE_FALLBACK=1 run_pv "$TMP/persons/bad-type.json"
assert_eq "1" "$PV_RC" "fallback path: wrong type -> exit 1"

# --- cross-file contract -------------------------------------------------------
if [[ -f "$SCHEMA" ]]; then
  assert_contains "$SCHEMA" "linkedin-carousel-person-v1" "schema declares the canonical schema id"
  assert_contains "$SCHEMA" '"required"' "schema has a required list"
  assert_contains "$SCHEMA" '"name"' "schema requires name"
  assert_contains "$SCHEMA" "in/[A-Za-z0-9._-]+" "schema pins the handle pattern"
  assert_contains "$SCHEMA" "headline" "schema documents headline"
  assert_contains "$SCHEMA" "cta_text" "schema documents cta_text"
  assert_contains "$SCHEMA" "logo_path" "schema documents logo_path"
  assert_contains "$SCHEMA" "additionalProperties" "schema rejects unknown keys"
else
  t_fail "person.schema.json missing at $SCHEMA"
fi

if [[ -f "$SKILL" ]]; then
  assert_contains "$SKILL" "person-validate.py" "skill references the person validator"
  assert_contains "$SKILL" "in/[A-Za-z0-9._-]+" "skill pins the handle pattern"
  assert_contains "$SKILL" "docs/assets/person.json" "skill documents the person.json location"
else
  t_fail "linkedin-carousel skill missing at $SKILL"
fi

t_finish
