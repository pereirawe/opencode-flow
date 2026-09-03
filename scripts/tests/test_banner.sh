#!/usr/bin/env bash
# Tests for scripts/cv/banner-gen.sh (issue #224 — LinkedIn profile banner
# helper for the each::sense image model).
#
# Mechanically testable parts ONLY — no network. The each::sense API call and
# the image download are mocked via a fake `curl` on PATH. Real generation
# requires the user's EACHLABS_API_KEY at runtime (verified manually).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

t_begin "test_banner"

BANNER="$SCRIPT_DIR/../cv/banner-gen.sh"
SKILL="$SCRIPT_DIR/../../skills/career/cv-linkedin-banner/SKILL.md"
CMD_DOC="$SCRIPT_DIR/../../commands/ocf:cv-banner.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A fake key that passes the format gate (>= 8 chars, no whitespace). It must
# NEVER appear in the script's stdout/stderr or in any artifact it writes.
FAKE_KEY="el_test_0000111122223333"

# run_banner: invokes the helper capturing combined output and exit code.
# EACHLABS_API_KEY is delivered through the environment via env_set/env_unset
# (a prefix assignment before a function call would NOT be exported to the
# child bash that runs the script).
BANNER_OUT=""
BANNER_RC=""
run_banner() {
  set +e
  BANNER_OUT="$(bash "$BANNER" "$@" 2>&1)"
  BANNER_RC=$?
  set -e
}
env_set()   { EACHLABS_API_KEY="$1"; export EACHLABS_API_KEY; }
env_unset() { unset EACHLABS_API_KEY; }
env_unset

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------
mkdir -p "$TMP/specs" "$TMP/bin"

cat > "$TMP/specs/spec-ok.json" <<'JSON'
{
  "version": "banner-spec-v1",
  "canvas": {"width": 1584, "height": 396},
  "safe_zones": {
    "profile_photo": {"left_px": 500, "bottom_px": 260},
    "mobile_crop": {"width": 640, "height": 160}
  },
  "direction": {
    "concept": "Engenheiro de dados senior — dados como alavanca de decisao",
    "palette": {
      "background": "#0F172A",
      "surface": "#1E293B",
      "text_primary": "#F8FAFC",
      "accent_primary": "#38BDF8"
    },
    "style": "modern, clean, premium tech",
    "composition": "abstract gradient background, subtle grid, no people",
    "typography_hint": "sans-serif, high contrast"
  },
  "generation": {"mode": "max"}
}
JSON

cat > "$TMP/specs/spec-invalid.json" <<'JSON'
{"canvas": {"width": "not-a-number", "height": 396}, "direction": {}}
JSON

cat > "$TMP/specs/spec-no-canvas.json" <<'JSON'
{"direction": {"style": "x"}}
JSON

cat > "$TMP/content-ok.json" <<'JSON'
{
  "phrase": "Engenheiro de dados | transformo dados em decisoes",
  "items": [
    {"kind": "phone", "label": "Telefone", "value": "+55 (11) 98765-4321"},
    {"kind": "email", "value": "candidato@example.com"},
    {"kind": "social", "network": "linkedin", "handle": "/in/candidato-teste", "value": "/in/candidato-teste"}
  ]
}
JSON

cat > "$TMP/content-no-items.json" <<'JSON'
{"phrase": "somente frase"}
JSON

cat > "$TMP/content-bad-item.json" <<'JSON'
{"items": [{"kind": "email"}]}
JSON

# Mock curl: routes by URL.
#   * each::sense endpoint (URL contains chat/completions) -> writes the
#     canned SSE stream to the -o file; verifies the X-API-Key header equals
#     $EACHLABS_API_KEY (exit 3 when missing/mismatched).
#   * any other URL (image download) -> writes a fake PNG (or fails per
#     MOCK_DL_MODE) to the -o file.
# Scenario selection: MOCK_MODE=ok|error|empty (SSE), MOCK_DL_MODE=png|fail|text.
cat > "$TMP/bin/curl" <<'MOCKEOF'
#!/usr/bin/env bash
out=""; url=""; want=""; headers=()
for tok in "$@"; do
  case "$tok" in
    -o|-H|--data-binary) want="$tok" ;;
    -*) : ;;
    *)
      case "$want" in
        -o) out="$tok"; want="" ;;
        -H) headers+=("$tok"); want="" ;;
        --data-binary) want="" ;;
        *) url="$tok" ;;
      esac
      ;;
  esac
done

if [[ "$url" == *"chat/completions"* ]]; then
  key_ok=0
  for h in "${headers[@]}"; do
    [[ "$h" == "X-API-Key: ${EACHLABS_API_KEY:-}" ]] && key_ok=1
  done
  [[ "$key_ok" == "1" ]] || { echo "mock curl: X-API-Key header missing/mismatched" >&2; exit 3; }
  case "${MOCK_MODE:-ok}" in
    error)
      cat > "$out" <<'SSE'
data: {"id":"x","object":"chat.completion.chunk","choices":[],"eachlabs":{"type":"error","message":"mock generation error"}}
data: {"id":"x","eachlabs":{"type":"complete","status":"error"}}
data: [DONE]
SSE
      ;;
    empty)
      printf 'data: [DONE]\n' > "$out"
      ;;
    ok)
      cat > "$out" <<'SSE'
data: {"id":"chatcmpl-mock","object":"chat.completion.chunk","choices":[],"eachlabs":{"type":"thinking_delta","content":"mock"}}
data: {"id":"chatcmpl-mock","object":"chat.completion.chunk","choices":[],"eachlabs":{"type":"generation_response","url":"https://mock.invalid/generated/banner.png","generations":["https://mock.invalid/generated/banner.png"],"model":"eachsense/beta","execution_time_ms":1}}
data: {"id":"chatcmpl-mock","object":"chat.completion.chunk","choices":[],"eachlabs":{"type":"complete","status":"ok","generations":["https://mock.invalid/generated/banner.png"],"model":"eachsense/beta"}}
data: [DONE]
SSE
      ;;
  esac
  exit 0
fi

case "${MOCK_DL_MODE:-png}" in
  fail) echo "mock curl: download failed" >&2; exit 22 ;;
  text) printf 'not-an-image at all' > "$out"; exit 0 ;;
  png)  printf '\x89PNG\r\n\x1a\nmock-png-bytes-0123456789' > "$out"; exit 0 ;;
esac
MOCKEOF
chmod +x "$TMP/bin/curl" 2>/dev/null || true

assert_no_key_leak() { # $1 = label — asserts FAKE_KEY never appeared in output
  if [[ "$BANNER_OUT" == *"$FAKE_KEY"* ]]; then
    t_fail "$1 (the key value leaked into the script output)"
  else
    t_ok "$1"
  fi
}

# --- syntax ---------------------------------------------------------------
set +e
bash -n "$BANNER"
rc_syntax=$?
set -e
assert_eq "0" "$rc_syntax" "banner-gen.sh passes bash -n"

# --- usage / argument validation (no key needed) ---------------------------
run_banner
assert_eq "2" "$BANNER_RC" "no subcommand -> exit 2 (usage)"
if [[ "$BANNER_OUT" == *"Usage:"* ]]; then
  t_ok "no subcommand prints the usage text"
else
  t_fail "no subcommand does not print usage"
fi

run_banner --frobnicate
assert_eq "2" "$BANNER_RC" "unknown subcommand -> exit 2"

run_banner --spec "$TMP/specs/spec-ok.json" --content "$TMP/content-ok.json"
assert_eq "2" "$BANNER_RC" "--spec without --out -> exit 2"

run_banner --spec "$TMP/nope.json" --content "$TMP/content-ok.json" --out "$TMP/out-arg"
assert_eq "2" "$BANNER_RC" "missing spec file -> exit 2"
assert_eq "0" "$(test -d "$TMP/out-arg" && echo 1 || echo 0)" "missing spec file creates no output dir"

# --- --check ----------------------------------------------------------------
env_unset
run_banner --check
assert_eq "1" "$BANNER_RC" "--check without EACHLABS_API_KEY -> exit 1"
if [[ "$BANNER_OUT" == *"EACHLABS_API_KEY is not set"* ]]; then
  t_ok "--check missing key prints a clear message"
else
  t_fail "--check missing key message not clear: $BANNER_OUT"
fi

env_set ""
run_banner --check
assert_eq "1" "$BANNER_RC" "--check with an EMPTY EACHLABS_API_KEY is treated as absent (exit 1)"

env_set "   "
run_banner --check
assert_eq "1" "$BANNER_RC" "--check with a whitespace-only key -> exit 1 (invalid format)"

env_set "abc 123 def"
run_banner --check
assert_eq "1" "$BANNER_RC" "--check with a whitespace-containing key -> exit 1 (invalid format)"
assert_no_key_leak "--check invalid-format scenarios never leak a key value"

env_set "$FAKE_KEY"
run_banner --check
assert_eq "0" "$BANNER_RC" "--check with a valid-looking key -> exit 0"
if [[ "$BANNER_OUT" == *"looks valid"* ]]; then
  t_ok "--check valid key prints a ready message"
else
  t_fail "--check valid key message not printed: $BANNER_OUT"
fi
assert_no_key_leak "--check NEVER prints the key value (valid key scenario)"

# --- generation: key missing -> clear failure, no partial output ------------
env_unset
run_banner --spec "$TMP/specs/spec-ok.json" --content "$TMP/content-ok.json" --out "$TMP/out-nokey"
assert_eq "1" "$BANNER_RC" "--spec without key -> exit 1 (clear failure)"
if [[ "$BANNER_OUT" == *"EACHLABS_API_KEY is not set"* ]]; then
  t_ok "--spec without key prints a clear message"
else
  t_fail "--spec without key message not clear: $BANNER_OUT"
fi
assert_eq "0" "$(test -d "$TMP/out-nokey" && echo 1 || echo 0)" "missing key creates NO output dir (no partial file)"

# --- generation: input validation (key present, fails before network) ------
env_set "$FAKE_KEY"
run_banner --spec "$TMP/specs/spec-invalid.json" --content "$TMP/content-ok.json" --out "$TMP/out-invspec"
assert_eq "2" "$BANNER_RC" "invalid spec JSON -> exit 2"
assert_eq "0" "$(test -d "$TMP/out-invspec" && echo 1 || echo 0)" "invalid spec JSON creates no output dir"

run_banner --spec "$TMP/specs/spec-no-canvas.json" --content "$TMP/content-ok.json" --out "$TMP/out-nocanvas"
assert_eq "2" "$BANNER_RC" "spec without canvas/direction/prompt -> exit 2"
if [[ "$BANNER_OUT" == *"missing required fields"* ]]; then
  t_ok "invalid spec semantic error message is clear"
else
  t_fail "invalid spec semantic message not clear: $BANNER_OUT"
fi

run_banner --spec "$TMP/specs/spec-ok.json" --content "$TMP/content-no-items.json" --out "$TMP/out-noitems"
assert_eq "2" "$BANNER_RC" "content without items array -> exit 2"

run_banner --spec "$TMP/specs/spec-ok.json" --content "$TMP/content-bad-item.json" --out "$TMP/out-baditem"
assert_eq "2" "$BANNER_RC" "content item without value -> exit 2"

# --- generation: mocked success path ----------------------------------------
OUT_OK="$TMP/out-ok"
env_set "$FAKE_KEY"
PATH="$TMP/bin:$PATH" run_banner \
  --spec "$TMP/specs/spec-ok.json" --content "$TMP/content-ok.json" --out "$OUT_OK"
assert_eq "0" "$BANNER_RC" "generation succeeds with a mocked each::sense stream"
if [[ "$BANNER_OUT" == *"Banner generated"* ]]; then
  t_ok "success prints the banner path"
else
  t_fail "success does not print the banner path: $BANNER_OUT"
fi
assert_no_key_leak "success path output never leaks the key"

if [[ -s "$OUT_OK/banner.png" ]]; then
  t_ok "banner.png written and non-empty"
else
  t_fail "banner.png missing or empty"
fi
PNG_MAGIC="$(head -c 8 "$OUT_OK/banner.png" | od -An -tx1 | tr -d ' \n' || true)"
assert_eq "89504e470d0a1a0a" "$PNG_MAGIC" "banner.png has PNG magic bytes (valid image)"

REQ="$OUT_OK/banner.request.json"
assert_contains "$REQ" "eachsense/beta" "request body uses the eachsense/beta model"
assert_contains "$REQ" '"mode": "max"' "request body uses mode max"
assert_contains "$REQ" '"stream": true' "request body streams (stream: true)"
assert_contains "$REQ" "1584" "request prompt embeds the 1584 canvas width"
assert_contains "$REQ" "396" "request prompt embeds the 396 canvas height"
assert_contains "$REQ" "Engenheiro de dados | transformo dados em decisoes" "request prompt embeds the exact phrase from content"
assert_contains "$REQ" "+55 (11) 98765-4321" "request prompt embeds the exact phone from content"
assert_contains "$REQ" "candidato@example.com" "request prompt embeds the exact email from content"
assert_contains "$REQ" "/in/candidato-teste" "request prompt embeds the exact social handle from content"
assert_contains "$REQ" "left 500px" "request prompt encodes the profile-photo guard (left 500px)"
assert_contains "$REQ" "bottom 260px" "request prompt encodes the profile-photo guard (bottom 260px)"
assert_contains "$REQ" "center-crops" "request prompt encodes the mobile center-crop rule"
assert_not_contains "$REQ" "$FAKE_KEY" "request body NEVER contains the API key"

assert_contains "$OUT_OK/banner.sse.log" "generation_response" "SSE stream log saved"
assert_not_contains "$OUT_OK/banner.sse.log" "$FAKE_KEY" "SSE stream log NEVER contains the API key"

# --- generation: each::sense error event ------------------------------------
OUT_ERR="$TMP/out-err"
env_set "$FAKE_KEY"
PATH="$TMP/bin:$PATH" MOCK_MODE=error run_banner \
  --spec "$TMP/specs/spec-ok.json" --content "$TMP/content-ok.json" --out "$OUT_ERR"
assert_eq "1" "$BANNER_RC" "each::sense error event -> exit 1"
if [[ "$BANNER_OUT" == *"generation failed"* ]]; then
  t_ok "each::sense error prints a clear failure message"
else
  t_fail "each::sense error message not clear: $BANNER_OUT"
fi
assert_eq "0" "$(test -f "$OUT_ERR/banner.png" && echo 1 || echo 0)" "failed generation leaves NO banner.png (no partial image)"

# --- generation: stream without any image URL --------------------------------
OUT_EMPTY="$TMP/out-empty"
env_set "$FAKE_KEY"
PATH="$TMP/bin:$PATH" MOCK_MODE=empty run_banner \
  --spec "$TMP/specs/spec-ok.json" --content "$TMP/content-ok.json" --out "$OUT_EMPTY"
assert_eq "1" "$BANNER_RC" "stream without an image URL -> exit 1"
assert_eq "0" "$(test -f "$OUT_EMPTY/banner.png" && echo 1 || echo 0)" "URL-less stream leaves NO banner.png"

# --- generation: download failure --------------------------------------------
OUT_DLFAIL="$TMP/out-dlfail"
env_set "$FAKE_KEY"
PATH="$TMP/bin:$PATH" MOCK_DL_MODE=fail run_banner \
  --spec "$TMP/specs/spec-ok.json" --content "$TMP/content-ok.json" --out "$OUT_DLFAIL"
assert_eq "1" "$BANNER_RC" "image download failure -> exit 1"
if [[ "$BANNER_OUT" == *"failed to download"* ]]; then
  t_ok "download failure prints a clear message"
else
  t_fail "download failure message not clear: $BANNER_OUT"
fi
assert_eq "0" "$(test -f "$OUT_DLFAIL/banner.png" && echo 1 || echo 0)" "download failure leaves NO banner.png"
assert_eq "0" "$(test -f "$OUT_DLFAIL/.banner.png.tmp" && echo 1 || echo 0)" "download failure cleans the temp file"

# --- generation: non-image body (e.g. an HTML error page) ---------------------
OUT_BADIMG="$TMP/out-badimg"
env_set "$FAKE_KEY"
PATH="$TMP/bin:$PATH" MOCK_DL_MODE=text run_banner \
  --spec "$TMP/specs/spec-ok.json" --content "$TMP/content-ok.json" --out "$OUT_BADIMG"
assert_eq "1" "$BANNER_RC" "non-image download body -> exit 1"
if [[ "$BANNER_OUT" == *"not a valid PNG/JPEG"* ]]; then
  t_ok "non-image body prints a clear rejection message"
else
  t_fail "non-image body message not clear: $BANNER_OUT"
fi
assert_eq "0" "$(test -f "$OUT_BADIMG/banner.png" && echo 1 || echo 0)" "non-image body leaves NO banner.png"

# --- cross-file contract (issue #224 deliverables exist and reference each other)
if [[ -f "$SKILL" ]]; then
  assert_contains "$SKILL" "cv-linkedin-banner" "banner skill names itself"
  assert_contains "$SKILL" "1584" "skill pins the 1584px canvas width"
  assert_contains "$SKILL" "396" "skill pins the 396px canvas height"
  assert_contains "$SKILL" "500" "skill pins the 500px profile-photo guard (left)"
  assert_contains "$SKILL" "260" "skill pins the 260px profile-photo guard (bottom)"
  assert_contains "$SKILL" "EACHLABS_API_KEY" "skill documents the API key requirement"
  assert_contains "$SKILL" "banner-gen.sh" "skill references the banner-gen.sh helper"
  assert_contains "$SKILL" "poster-design-generation" "skill references the vendored each::sense skill"
  assert_contains "$SKILL" "art-director" "skill reuses the art-director visual direction"
  assert_contains "$SKILL" "linkedin/banner" "skill defines the linkedin/banner output dir"
  assert_contains "$SKILL" "NUNCA inventar" "skill forbids fabricating contact data"
else
  t_fail "cv-linkedin-banner skill missing at $SKILL"
fi

if [[ -f "$CMD_DOC" ]]; then
  assert_contains "$CMD_DOC" "/ocf:cv-banner" "command doc names /ocf:cv-banner"
  assert_contains "$CMD_DOC" "banner-gen.sh" "command doc references the helper"
  assert_contains "$CMD_DOC" "EACHLABS_API_KEY" "command doc documents the key requirement"
  assert_contains "$CMD_DOC" "validate.py" "command doc validates the hub"
  assert_contains "$CMD_DOC" "linkedin/banner" "command doc documents the output dir"
  assert_contains "$CMD_DOC" "upload" "command doc states nothing is published (manual upload)"
else
  t_fail "ocf:cv-banner command doc missing at $CMD_DOC"
fi

t_finish
