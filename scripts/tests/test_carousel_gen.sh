#!/usr/bin/env bash
# Tests for scripts/marketing/carousel-gen.sh (issue #225 — LinkedIn carousel
# orchestrator): preflight, prompts-only fallback (E2E), mocked image mode,
# retry/fail-clean, and key-leak scanning.
#
# The each::sense API call and image download are mocked via a fake `curl` on
# PATH (same technique as test_banner.sh). The real image path requires the
# user's EACHLABS_API_KEY at runtime — guarded here by --check semantics and
# the mock.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

t_begin "test_carousel_gen"

GEN="$SCRIPT_DIR/../marketing/carousel-gen.sh"
SKILL="$SCRIPT_DIR/../../skills/marketing/linkedin-carousel/SKILL.md"
AGENT="$SCRIPT_DIR/../../agents/marketing/linkedin-carousel.md"
CMD_DOC="$SCRIPT_DIR/../../commands/ocf:linkedin-carousel.md"
OPENCODE_JSON="$SCRIPT_DIR/../../opencode.json"
COMMANDS_README="$SCRIPT_DIR/../../commands/README.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAKE_KEY="el_test_0000111122223333"

GEN_OUT=""; GEN_RC=""
run_gen() {
  set +e
  GEN_OUT="$(bash "$GEN" "$@" 2>&1)"
  GEN_RC=$?
  set -e
}
env_set()   { EACHLABS_API_KEY="$1"; export EACHLABS_API_KEY; }
env_unset() { unset EACHLABS_API_KEY; }
env_unset

img_dims() { python3 - "$1" <<'PY'
from PIL import Image
import sys
try:
    im = Image.open(sys.argv[1]); print(f"{im.width}x{im.height}")
except Exception: pass
PY
}
png_magic() { head -c 8 "$1" | od -An -tx1 | tr -d ' \n' || true; }

# ---------------------------------------------------------------------------
# Fixtures: a target project with docs/assets (person + logo) and the
# agent-authored docs/carousel/<slug>/deck.json + research/.
# ---------------------------------------------------------------------------
PROJ="$TMP/proj"
mkdir -p "$PROJ/docs/assets" "$TMP/bin" "$TMP/fixtures"

python3 - "$PROJ/docs/assets/logo.png" "$TMP/fixtures/art-ok.png" "$TMP/fixtures/art-small.png" <<'PY'
from PIL import Image
import sys
logo, ok, small = sys.argv[1:4]
Image.new("RGB", (200, 80), (0, 119, 182)).save(logo, "PNG")
Image.new("RGB", (1080, 1080), (230, 57, 70)).save(ok, "PNG")
Image.new("RGB", (64, 64), (0, 0, 0)).save(small, "PNG")
PY

cat > "$PROJ/docs/assets/person.json" <<'JSON'
{
  "schema": "linkedin-carousel-person-v1",
  "name": "Maria Silva",
  "headline": "Engenheira de dados | transformo dados em decisoes",
  "handle": "in/maria-silva",
  "cta_text": "Salve este post",
  "logo_path": "logo.png"
}
JSON

DECK="$PROJ/docs/carousel/meudeck/deck.json"
mkdir -p "$(dirname "$DECK")" "$(dirname "$DECK")/research"
cat > "$DECK" <<'JSON'
{
  "schema": "linkedin-carousel-deck-v1",
  "slug": "meudeck",
  "topic": "Arquitetura limpa na pratica",
  "locale": "pt",
  "n_slides": 3,
  "created": "2026-09-09T13:27:00Z",
  "open_questions": [],
  "slides": [
    {
      "index": 1,
      "type": "cover",
      "design_prompt": "Design a bold editorial background, dark and minimal, square 1080x1080, no text, no letters.",
      "text": {"TITULO": "Arquitetura limpa", "SUBTITULO": "7 pontos para codigo sustentavel", "RODAPE": "Maria Silva · in/maria-silva"},
      "sources": []
    },
    {
      "index": 2,
      "type": "content",
      "design_prompt": "Design a calm abstract background, dark blue tones, square 1080x1080, no text, no letters.",
      "text": {"TAG": "Principio 1", "HEADLINE": "Dependencias explicitas", "BULLETS": ["Injete as dependencias", "Nada de globais"], "DETALHE": "Fonte: blog.cleancoder.com"},
      "sources": [{"url": "https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html", "accessed": "2026-09-09", "note": "principio de dependencias"}]
    },
    {
      "index": 3,
      "type": "cta",
      "design_prompt": "Design a minimal final background, red accent, square 1080x1080, no text, no letters.",
      "text": {"HEADLINE": "Gostou?", "SUBHEADLINE": "Siga para mais conteudo", "CTA": "Salve este post", "RODAPE": "Maria Silva · in/maria-silva"},
      "sources": []
    }
  ]
}
JSON
printf '# Fonte 1\nURL: https://blog.cleancoder.com/…\nAcesso: 2026-09-09\n' > "$(dirname "$DECK")/research/01-meudeck.md"

# --- broken fixtures --------------------------------------------------------
PROJ_NODOCS="$TMP/proj-nodocs"; mkdir -p "$PROJ_NODOCS"
PROJ_NOPERSON="$TMP/proj-noperson"; mkdir -p "$PROJ_NOPERSON/docs"
PROJ_BADHANDLE="$TMP/proj-badhandle"; mkdir -p "$PROJ_BADHANDLE/docs/assets"
cat > "$PROJ_BADHANDLE/docs/assets/person.json" <<'JSON'
{"schema": "linkedin-carousel-person-v1", "name": "Maria", "handle": "/in/errado"}
JSON
PROJ_BADLOGO="$TMP/proj-badlogo"; mkdir -p "$PROJ_BADLOGO/docs/assets"
cat > "$PROJ_BADLOGO/docs/assets/person.json" <<'JSON'
{"schema": "linkedin-carousel-person-v1", "name": "Maria", "logo_path": "logo.txt"}
JSON
printf 'not an image' > "$PROJ_BADLOGO/docs/assets/logo.txt"

# Deck without sources on the content slide (BR 10).
DECK_NOSRC="$TMP/deck-nosrc.json"
python3 - "$DECK" "$DECK_NOSRC" <<'PY'
import json, sys
deck = json.load(open(sys.argv[1], encoding="utf-8"))
deck["slug"] = "nosrc"
deck["slides"][1]["sources"] = []
with open(sys.argv[2], "w", encoding="utf-8") as fh:
    json.dump(deck, fh, ensure_ascii=False, indent=2)
PY

# Deck with only 2 slides (BR 4 violation).
DECK_SHORT="$TMP/deck-short.json"
python3 - "$DECK" "$DECK_SHORT" <<'PY'
import json, sys
deck = json.load(open(sys.argv[1], encoding="utf-8"))
deck["n_slides"] = 2
deck["slides"] = deck["slides"][:2]
with open(sys.argv[2], "w", encoding="utf-8") as fh:
    json.dump(deck, fh, ensure_ascii=False, indent=2)
PY

# --- mock curl (routes by URL; verifies the key header on the API call) -------
cat > "$TMP/bin/curl" <<'MOCKEOF'
#!/usr/bin/env bash
out=""; url=""; want=""; headers=()
for tok in "$@"; do
  case "$tok" in
    -o|-H|--data-binary|-X) want="$tok" ;;
    -*) : ;;
    *)
      case "$want" in
        -o) out="$tok"; want="" ;;
        -H) headers+=("$tok"); want="" ;;
        --data-binary) want="" ;;
        -X) want="" ;;
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
data: {"id":"chatcmpl-mock","object":"chat.completion.chunk","choices":[],"eachlabs":{"type":"generation_response","url":"https://mock.invalid/gen/art.png","generations":["https://mock.invalid/gen/art.png"],"model":"eachsense/beta","execution_time_ms":1}}
data: {"id":"chatcmpl-mock","object":"chat.completion.chunk","choices":[],"eachlabs":{"type":"complete","status":"ok","generations":["https://mock.invalid/gen/art.png"],"model":"eachsense/beta"}}
data: [DONE]
SSE
      ;;
  esac
  exit 0
fi

case "${MOCK_DL_MODE:-png}" in
  fail) echo "mock curl: download failed" >&2; exit 22 ;;
  text) printf 'not-an-image at all' > "$out"; exit 0 ;;
  small) cp "${MOCK_SMALL:-}" "$out" 2>/dev/null || printf 'small' > "$out"; exit 0 ;;
  png)  cp "${MOCK_OK:-}" "$out" 2>/dev/null || printf 'png' > "$out"; exit 0 ;;
esac
MOCKEOF
chmod +x "$TMP/bin/curl" 2>/dev/null || true

assert_no_key_leak() { # $1 = label — FAKE_KEY must never appear in the run output
  if [[ "$GEN_OUT" == *"$FAKE_KEY"* ]]; then
    t_fail "$1 (the key value leaked into the script output)"
  else
    t_ok "$1"
  fi
}

# ---------------------------------------------------------------------------
# Syntax / usage
# ---------------------------------------------------------------------------
set +e
bash -n "$GEN"
rc_syntax=$?
set -e
assert_eq "0" "$rc_syntax" "carousel-gen.sh passes bash -n"

run_gen
assert_eq "2" "$GEN_RC" "no subcommand -> exit 2 (usage)"
run_gen --frobnicate
assert_eq "2" "$GEN_RC" "unknown subcommand -> exit 2"
run_gen --project "$PROJ"
assert_eq "2" "$GEN_RC" "--project without --slug -> exit 2"

# ---------------------------------------------------------------------------
# --check (creates NOTHING; exit 0 with deps; reports the mode by key state)
# ---------------------------------------------------------------------------
env_unset
run_gen --check
assert_eq "0" "$GEN_RC" "--check without key -> exit 0 (deps ok)"
if [[ "$GEN_OUT" == *"prompts-only"* ]]; then
  t_ok "--check reports prompts-only mode when the key is absent"
else
  t_fail "--check should mention prompts-only without the key: $GEN_OUT"
fi
assert_no_key_leak "--check never prints a key value"

env_set "$FAKE_KEY"
run_gen --check
assert_eq "0" "$GEN_RC" "--check with a valid-looking key -> exit 0"
if [[ "$GEN_OUT" == *"image mode"* ]]; then
  t_ok "--check reports image mode when the key is set"
else
  t_fail "--check should mention image mode with the key: $GEN_OUT"
fi
assert_no_key_leak "--check with key set never prints the key value"

# ---------------------------------------------------------------------------
# Preflight failures (exit 2, zero NEW artifacts in the output dir)
# ---------------------------------------------------------------------------
env_unset
OUTDIR="$PROJ/docs/carousel/meudeck"
assert_nothing_new() { # $1 label — no derived artifacts may exist
  local label="$1"
  local bad=0
  for f in prompts-textos.md instrucoes.md deck.pdf slide-01.png art-01.request.json; do
    if [[ -e "$OUTDIR/$f" ]]; then bad=1; fi
  done
  if compgen -G "$OUTDIR/.carousel-tmp.*" >/dev/null 2>&1; then bad=1; fi
  if [[ "$bad" == "0" ]]; then t_ok "$label"; else t_fail "$label (derived artifact found)"; fi
}

run_gen --project "$TMP/proj-nodocs" --slug x
assert_eq "2" "$GEN_RC" "project without docs/ -> exit 2 (preflight)"
if [[ "$GEN_OUT" == *"docs"* ]]; then t_ok "no-docs error message is clear"; else t_fail "no-docs message: $GEN_OUT"; fi

run_gen --project "$PROJ_NOPERSON" --slug x
assert_eq "2" "$GEN_RC" "project without person.json -> exit 2 (preflight)"

run_gen --project "$PROJ_BADHANDLE" --slug x
assert_eq "2" "$GEN_RC" "invalid person.json (handle sem in/) -> exit 2"

run_gen --project "$PROJ_BADLOGO" --slug x
assert_eq "2" "$GEN_RC" "invalid logo (magic-byte) -> exit 2"
if [[ "$GEN_OUT" == *"logo"* ]]; then t_ok "bad-logo error message mentions the logo"; else t_fail "bad-logo message: $GEN_OUT"; fi

run_gen --project "$PROJ" --slug outro-slug
assert_eq "2" "$GEN_RC" "CLI slug != deck.json slug -> exit 2"
assert_nothing_new "slug mismatch leaves no new artifacts"

run_gen --project "$PROJ" --slug meudeck --out "$TMP/out-nosrc"
assert_eq "0" "$GEN_RC" "sanity: valid project with key absent -> exit 0 (prompts-only)"
rm -rf "$TMP/out-nosrc"

# Invalid decks in dedicated projects (copy the deck fixture, break it).
PROJ_NOSRC="$TMP/proj-nosrc"; mkdir -p "$PROJ_NOSRC/docs/assets"
cp "$PROJ/docs/assets/person.json" "$PROJ_NOSRC/docs/assets/"
cp "$PROJ/docs/assets/logo.png" "$PROJ_NOSRC/docs/assets/"
mkdir -p "$PROJ_NOSRC/docs/carousel/nosrc"
cp "$DECK_NOSRC" "$PROJ_NOSRC/docs/carousel/nosrc/deck.json"
run_gen --project "$PROJ_NOSRC" --slug nosrc
assert_eq "2" "$GEN_RC" "content slide without sources -> exit 2 (BR 10)"
if [[ "$GEN_OUT" == *"source"* ]]; then t_ok "no-sources error mentions sources"; else t_fail "no-sources message: $GEN_OUT"; fi

PROJ_SHORT="$TMP/proj-short"; mkdir -p "$PROJ_SHORT/docs/assets"
cp "$PROJ/docs/assets/person.json" "$PROJ_SHORT/docs/assets/"
cp "$PROJ/docs/assets/logo.png" "$PROJ_SHORT/docs/assets/"
mkdir -p "$PROJ_SHORT/docs/carousel/short"
cp "$DECK_SHORT" "$PROJ_SHORT/docs/carousel/short/deck.json"
run_gen --project "$PROJ_SHORT" --slug short
assert_eq "2" "$GEN_RC" "deck with 2 slides -> exit 2 (BR 4: 3..20)"

# ---------------------------------------------------------------------------
# Prompts-only fallback — E2E (Tests 1)
# ---------------------------------------------------------------------------
env_unset
run_gen --project "$PROJ" --slug meudeck --out "$TMP/out-prompts"
assert_eq "0" "$GEN_RC" "prompts-only run -> exit 0"
if [[ "$GEN_OUT" == *"prompts-only"* ]]; then
  t_ok "prompts-only run reports the mode clearly"
else
  t_fail "prompts-only mode message missing: $GEN_OUT"
fi
if [[ -f "$TMP/out-prompts/prompts-textos.md" ]]; then
  t_ok "prompts-textos.md generated"
  assert_contains "$TMP/out-prompts/prompts-textos.md" "Prompt de design (EN)" "prompts-textos has the EN design prompt block"
  assert_contains "$TMP/out-prompts/prompts-textos.md" "Arquitetura limpa" "prompts-textos carries the user-language slide text"
else
  t_fail "prompts-textos.md missing"
fi
if [[ -f "$TMP/out-prompts/instrucoes.md" ]]; then
  t_ok "instrucoes.md generated"
  if grep -qi "upload" "$TMP/out-prompts/instrucoes.md"; then
    t_ok "instrucoes mentions the manual upload"
  else
    t_fail "instrucoes does not mention upload: $(head -c 300 "$TMP/out-prompts/instrucoes.md")"
  fi
else
  t_fail "instrucoes.md missing"
fi
assert_eq "0" "$(test -f "$TMP/out-prompts/deck.pdf" && echo 1 || echo 0)" "prompts-only creates NO deck.pdf"
assert_eq "0" "$(ls "$TMP/out-prompts"/slide-*.png 2>/dev/null | wc -l)" "prompts-only creates NO slide PNGs"
assert_eq "0" "$(ls "$TMP/out-prompts"/art-*.request.json 2>/dev/null | wc -l)" "prompts-only creates NO API request files"
if [[ -f "$TMP/out-prompts/deck.json" || -f "$PROJ/docs/carousel/meudeck/deck.json" ]]; then
  t_ok "deck.json (source artifact) is always present"
else
  t_fail "deck.json missing"
fi

# ---------------------------------------------------------------------------
# Image mode — mocked each::sense (Tests 2/6)
# ---------------------------------------------------------------------------
env_set "$FAKE_KEY"
MOCK_OK="$TMP/fixtures/art-ok.png"
MOCK_SMALL="$TMP/fixtures/art-small.png"
export MOCK_OK MOCK_SMALL
OUT_IMG="$TMP/out-img"
PATH="$TMP/bin:$PATH" run_gen --project "$PROJ" --slug meudeck --out "$OUT_IMG"
assert_eq "0" "$GEN_RC" "image mode with mocked API succeeds"
assert_no_key_leak "image mode output never leaks the key"

if [[ -f "$OUT_IMG/slide-01.png" && -f "$OUT_IMG/slide-02.png" && -f "$OUT_IMG/slide-03.png" ]]; then
  t_ok "all 3 slide PNGs generated"
  assert_eq "89504e470d0a1a0a" "$(png_magic "$OUT_IMG/slide-01.png")" "slide-01 PNG magic bytes"
  assert_eq "1080x1080" "$(img_dims "$OUT_IMG/slide-01.png")" "slide-01 is exactly 1080x1080"
  assert_eq "1080x1080" "$(img_dims "$OUT_IMG/slide-02.png")" "slide-02 is exactly 1080x1080"
  assert_eq "1080x1080" "$(img_dims "$OUT_IMG/slide-03.png")" "slide-03 is exactly 1080x1080"
else
  t_fail "slide PNGs missing in $OUT_IMG"
fi
if [[ -s "$OUT_IMG/deck.pdf" ]]; then
  t_ok "deck.pdf generated"
  assert_eq "%PDF" "$(head -c 4 "$OUT_IMG/deck.pdf")" "deck.pdf has PDF magic"
else
  t_fail "deck.pdf missing or empty"
fi
if [[ -f "$OUT_IMG/prompts-textos.md" && -f "$OUT_IMG/instrucoes.md" ]]; then
  t_ok "prompts-textos.md + instrucoes.md generated in image mode"
else
  t_fail "derived markdown missing in image mode"
fi

REQ="$OUT_IMG/art-01.request.json"
if [[ -f "$REQ" ]]; then
  assert_contains "$REQ" "eachsense/beta" "request uses the eachsense/beta model"
  assert_contains "$REQ" '"stream": true' "request streams (stream: true)"
  assert_contains "$REQ" "bold editorial background" "request embeds the slide design prompt"
  assert_not_contains "$REQ" "$FAKE_KEY" "request body NEVER contains the API key"
else
  t_fail "art-01.request.json missing"
fi
if [[ -f "$OUT_IMG/art-01.sse.log" ]]; then
  assert_contains "$OUT_IMG/art-01.sse.log" "generation_response" "SSE stream log saved"
  assert_not_contains "$OUT_IMG/art-01.sse.log" "$FAKE_KEY" "SSE log NEVER contains the API key"
else
  t_fail "art-01.sse.log missing"
fi

# Full artifact key scan (Tests 6): no output artifact may contain the key
# value nor the EACHLABS_API_KEY variable name as content.
KEYSCAN="$(grep -rl "$FAKE_KEY" "$OUT_IMG" 2>/dev/null || true)"
if [[ -z "$KEYSCAN" ]]; then
  t_ok "no output artifact contains the key value (full scan)"
else
  t_fail "key value found in: $KEYSCAN"
fi
KEYSCAN2="$(grep -rl "EACHLABS_API_KEY" "$OUT_IMG" 2>/dev/null || true)"
if [[ -z "$KEYSCAN2" ]]; then
  t_ok "no output artifact mentions EACHLABS_API_KEY"
else
  t_fail "EACHLABS_API_KEY found in: $KEYSCAN2"
fi

# ---------------------------------------------------------------------------
# Image mode failures: bad download body (magic) and wrong dimension -> retry
# (<=2) then clean failure; zero partial artifacts (Tests 3)
# ---------------------------------------------------------------------------
OUT_BADIMG="$TMP/out-badimg"
env_set "$FAKE_KEY"
PATH="$TMP/bin:$PATH" MOCK_DL_MODE=text run_gen --project "$PROJ" --slug meudeck --out "$OUT_BADIMG"
assert_eq "1" "$GEN_RC" "non-image download body -> exit 1 after retries"
if [[ "$GEN_OUT" == *"magic"* || "$GEN_OUT" == *"aborting"* ]]; then
  t_ok "bad-image failure message is clear"
else
  t_fail "bad-image message not clear: $GEN_OUT"
fi
assert_eq "0" "$(test -f "$OUT_BADIMG/deck.pdf" && echo 1 || echo 0)" "bad download leaves NO deck.pdf"
assert_eq "0" "$(ls "$OUT_BADIMG"/slide-*.png 2>/dev/null | wc -l)" "bad download leaves NO slide PNGs"
assert_eq "0" "$(test -d "$OUT_BADIMG/.carousel-tmp."* 2>/dev/null && echo 1 || echo 0)" "bad download cleans the temp dir"
assert_no_key_leak "failure path never leaks the key"

OUT_BADDIM="$TMP/out-baddim"
env_set "$FAKE_KEY"
PATH="$TMP/bin:$PATH" MOCK_DL_MODE=small run_gen --project "$PROJ" --slug meudeck --out "$OUT_BADDIM"
assert_eq "1" "$GEN_RC" "wrong-dimension download -> exit 1 after retries"
if [[ "$GEN_OUT" == *"1080x1080"* ]]; then
  t_ok "dimension rejection message mentions 1080x1080"
else
  t_fail "dimension rejection message not clear: $GEN_OUT"
fi
assert_eq "0" "$(test -f "$OUT_BADDIM/deck.pdf" && echo 1 || echo 0)" "wrong dimension leaves NO deck.pdf"
assert_eq "0" "$(ls "$OUT_BADDIM"/slide-*.png 2>/dev/null | wc -l)" "wrong dimension leaves NO slide PNGs"

OUT_ERR="$TMP/out-err"
env_set "$FAKE_KEY"
PATH="$TMP/bin:$PATH" MOCK_MODE=error run_gen --project "$PROJ" --slug meudeck --out "$OUT_ERR"
assert_eq "1" "$GEN_RC" "each::sense error event -> exit 1"
assert_eq "0" "$(test -f "$OUT_ERR/deck.pdf" && echo 1 || echo 0)" "API error leaves NO deck.pdf"

# deck.json + research are ALWAYS preserved on runtime failure (BR 8).
if [[ -f "$PROJ/docs/carousel/meudeck/deck.json" && -f "$PROJ/docs/carousel/meudeck/research/01-meudeck.md" ]]; then
  t_ok "deck.json + research preserved after runtime failures"
else
  t_fail "source artifacts lost after failure"
fi

# ---------------------------------------------------------------------------
# Cross-file contract (deliverables exist and reference each other)
# ---------------------------------------------------------------------------
if [[ -f "$SKILL" ]]; then
  assert_contains "$SKILL" "linkedin-carousel" "skill names itself"
  assert_contains "$SKILL" "1080" "skill pins the 1080px canvas"
  assert_contains "$SKILL" "#E63946" "skill pins the canonical red"
  assert_contains "$SKILL" "#0077B6" "skill pins the canonical blue"
  assert_contains "$SKILL" "deck.json" "skill defines deck.json as the source artifact"
  assert_contains "$SKILL" "carousel-gen.sh" "skill references the orchestrator"
  assert_contains "$SKILL" "EACHLABS_API_KEY" "skill documents the key requirement"
  assert_contains "$SKILL" "prompts-only" "skill documents the prompts-only fallback"
  assert_contains "$SKILL" "NUNCA inventar" "skill forbids fabricating identity/content"
else
  t_fail "linkedin-carousel skill missing at $SKILL"
fi

if [[ -f "$AGENT" ]]; then
  assert_contains "$AGENT" "linkedin-carousel" "agent names the skill"
  assert_contains "$AGENT" "carousel-gen.sh" "agent references the orchestrator"
  assert_contains "$AGENT" "person-validate.py" "agent validates person.json"
  assert_contains "$AGENT" "docs/carousel" "agent writes under docs/carousel"
else
  t_fail "linkedin-carousel agent missing at $AGENT"
fi

if [[ -f "$CMD_DOC" ]]; then
  assert_contains "$CMD_DOC" "/ocf:linkedin-carousel" "command doc names /ocf:linkedin-carousel"
  assert_contains "$CMD_DOC" "carousel-gen.sh" "command doc references the orchestrator"
  assert_contains "$CMD_DOC" "EACHLABS_API_KEY" "command doc documents the key requirement"
  assert_contains "$CMD_DOC" "docs/carousel" "command doc documents the output dir"
  assert_contains "$CMD_DOC" "upload" "command doc states nothing is published (manual upload)"
else
  t_fail "ocf:linkedin-carousel command doc missing at $CMD_DOC"
fi

if [[ -f "$OPENCODE_JSON" ]]; then
  assert_contains "$OPENCODE_JSON" "ocf:linkedin-carousel" "opencode.json registers the command"
  assert_contains "$OPENCODE_JSON" '"linkedin-carousel": "allow"' "opencode.json allows the skill"
else
  t_fail "opencode.json missing"
fi
if [[ -f "$COMMANDS_README" ]]; then
  assert_contains "$COMMANDS_README" "ocf:linkedin-carousel" "commands/README.md indexes the command"
else
  t_fail "commands/README.md missing"
fi

t_finish
