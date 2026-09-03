#!/usr/bin/env bash
# banner-gen.sh — LinkedIn profile banner generation helper (each::sense AI).
#
# Wraps the each::sense chat/completions endpoint used by the vendored
# `poster-design-generation` skill (vendor/eachlabs-skills) into a small,
# non-destructive CLI:
#
#   banner-gen.sh --check
#   banner-gen.sh --spec <spec.json> --content <content.json> --out <dir>
#   banner-gen.sh --help
#
# `--check`        verifies that EACHLABS_API_KEY is present and well-formed
#                  (never prints the key value).
# `--spec/--out`   builds the each::sense request from a banner spec JSON
#                  (visual direction) + a content JSON (the EXACT text to
#                  render), streams the response (SSE), saves the generated
#                  image and a diagnostic log.
#
# Contract:
#   * EACHLABS_API_KEY is required (env or local secret — never committed).
#     Missing/invalid key -> exit 1 with a clear message and NO files created.
#   * The key is NEVER printed, echoed, or written into any output artifact
#     (request body, logs, report). Only the HTTP header carries it.
#   * No partial/fake image: the download lands in a temp file and is moved to
#     <out>/banner.png only after it passes a PNG/JPEG magic-byte check.
#   * Invoked without a subcommand -> usage on stderr, exit 2 (never runs).
#   * Argument/input errors (missing flags, unreadable or invalid JSON) -> 2.
#   * Runtime failures (network, generation error, bad download) -> 1.
#
# Stdlib-friendly: bash + curl + python3 (stdlib json only). curl is allowed
# here because this script is invoked by the user/agent at runtime (never by
# pipeline scripts). No network is used for --check.
set -euo pipefail

ENDPOINT="https://eachsense-agent.core.eachlabs.run/v1/chat/completions"

usage() { # prints to the given fd (default stdout): usage 2 -> stderr
  local fd="${1:-1}"
  if [[ "$fd" == "2" ]]; then
    cat >&2 <<'EOF'
Usage:
  banner-gen.sh --check
  banner-gen.sh --spec <spec.json> --content <content.json> --out <dir>
  banner-gen.sh --help

  --check      Verify EACHLABS_API_KEY is set and well-formed (never prints it).
  --spec FILE  Banner spec JSON: canvas, safe zones, visual direction
               (concept/palette/style/composition) and optional prompt.
  --content F  Content JSON: the exact text to render on the banner
               (phrase + phone/email/social items) — sourced from hub.json.
  --out DIR    Output directory. On success it receives:
                 banner.png           final 4:1 image
                 banner.request.json  request body sent to each::sense (key-free)
                 banner.sse.log       raw SSE stream from the API

Requires EACHLABS_API_KEY (env/secret, never committed). Without it the
script exits 1 without creating anything.
EOF
  else
    cat <<'EOF'
Usage:
  banner-gen.sh --check
  banner-gen.sh --spec <spec.json> --content <content.json> --out <dir>
  banner-gen.sh --help

  --check      Verify EACHLABS_API_KEY is set and well-formed (never prints it).
  --spec FILE  Banner spec JSON: canvas, safe zones, visual direction
               (concept/palette/style/composition) and optional prompt.
  --content F  Content JSON: the exact text to render on the banner
               (phrase + phone/email/social items) — sourced from hub.json.
  --out DIR    Output directory. On success it receives:
                 banner.png           final 4:1 image
                 banner.request.json  request body sent to each::sense (key-free)
                 banner.sse.log       raw SSE stream from the API

Requires EACHLABS_API_KEY (env/secret, never committed). Without it the
script exits 1 without creating anything.
EOF
  fi
}

# ---------------------------------------------------------------------------
# Key presence/format check. Never prints the value — only presence/status.
# Returns 0 when the key is present and well-formed.
# ---------------------------------------------------------------------------
key_check() {
  local k="${EACHLABS_API_KEY:-}"
  if [[ -z "$k" ]]; then
    echo "error: EACHLABS_API_KEY is not set — LinkedIn banner generation uses the each::sense API (skill poster-design-generation). Set it in the environment or a local secret before running (never commit it)." >&2
    return 1
  fi
  if [[ "$k" =~ [[:space:]] ]] || [[ "${#k}" -lt 8 ]]; then
    echo "error: EACHLABS_API_KEY has an invalid format — expected a single non-empty token without spaces/newlines (an each::sense API key). Refusing to run." >&2
    return 1
  fi
  return 0
}

cmd_check() {
  if key_check; then
    echo "ok: EACHLABS_API_KEY is set and looks valid — each::sense banner generation is ready."
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# Generation: --spec <file> --content <file> --out <dir>
# ---------------------------------------------------------------------------
SPEC=""
CONTENT=""
OUT=""

parse_args() {
  local i=0
  local -a args=("$@")
  local n=$#
  while (( i < n )); do
    case "${args[$i]}" in
      --spec)    SPEC="${args[$((i+1))]:-}";    i=$((i+2)) ;;
      --content) CONTENT="${args[$((i+1))]:-}"; i=$((i+2)) ;;
      --out)     OUT="${args[$((i+1))]:-}";     i=$((i+2)) ;;
      --help|-h) usage; exit 0 ;;
      *) usage 2; exit 2 ;;
    esac
  done
}

json_tool_ok() { # <file> — 0 when the file parses as JSON
  python3 -m json.tool "$1" >/dev/null 2>&1
}

cmd_generate() {
  # Argument/input validation first (exit 2 — same contract as pdf.sh):
  # usage mistakes are reported even when the key is missing.
  if [[ -z "$SPEC" || -z "$CONTENT" || -z "$OUT" ]]; then
    usage 2
    exit 2
  fi
  [[ -f "$SPEC" ]]    || { echo "error: spec file not found: $SPEC" >&2; exit 2; }
  [[ -f "$CONTENT" ]] || { echo "error: content file not found: $CONTENT" >&2; exit 2; }

  # Runtime dependencies.
  if ! command -v curl >/dev/null 2>&1; then
    echo "error: curl not found — required to call the each::sense endpoint" >&2
    exit 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "error: python3 not found — required to build/parse the each::sense request" >&2
    exit 1
  fi

  # Input JSON validation (exit 2).
  json_tool_ok "$SPEC"    || { echo "error: spec file is not valid JSON: $SPEC" >&2; exit 2; }
  json_tool_ok "$CONTENT" || { echo "error: content file is not valid JSON: $CONTENT" >&2; exit 2; }

  # Semantic validation of the spec (canvas + a renderable direction/prompt).
  python3 - "$SPEC" <<'PY' || { echo "error: spec file is missing required fields (canvas.width/height, direction.concept or prompt)" >&2; exit 2; }
import json, sys
spec = json.load(open(sys.argv[1]))
canvas = spec.get("canvas") or {}
assert isinstance(canvas.get("width"), int) and canvas["width"] > 0, "canvas.width"
assert isinstance(canvas.get("height"), int) and canvas["height"] > 0, "canvas.height"
direction = spec.get("direction") or {}
assert isinstance(direction.get("concept"), str) or isinstance(spec.get("prompt"), str), "direction.concept|prompt"
PY
  python3 - "$CONTENT" <<'PY' || { echo "error: content file is missing required fields (items array)" >&2; exit 2; }
import json, sys
content = json.load(open(sys.argv[1]))
assert isinstance(content.get("items", None), list), "items"
for it in content["items"]:
    assert isinstance(it, dict) and isinstance(it.get("value", ""), str) and it["value"] != "", "item.value"
PY

  # Environment gate last (exit 1, clear message) — nothing is created when
  # the key is missing: no output dir, no partial file.
  if ! key_check; then
    exit 1
  fi
  mkdir -p "$OUT" || { echo "error: cannot create output directory: $OUT" >&2; exit 1; }

  local req_json="$OUT/banner.request.json"
  local sse_log="$OUT/banner.sse.log"
  local dl_tmp="$OUT/.banner.png.tmp"

  # --- Build the request body (key-free by construction) ---------------------
  python3 - "$SPEC" "$CONTENT" "$req_json" <<'PY'
import json, sys

spec, content, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
spec = json.load(open(spec))
content = json.load(open(content))
canvas = spec.get("canvas", {"width": 1584, "height": 396})
direction = spec.get("direction", {})
sz = spec.get("safe_zones", {})
photo = sz.get("profile_photo", {}) or {}
mobile = sz.get("mobile_crop", {}) or {}
left_px = int(photo.get("left_px", 500))
bottom_px = int(photo.get("bottom_px", 260))
mw = int(mobile.get("width", 640))
mh = int(mobile.get("height", 160))
gen = spec.get("generation", {}) or {}

items = content.get("items", []) or []
phrase = (content.get("phrase") or "").strip()

def visual_prompt():
    if isinstance(spec.get("prompt"), str) and spec["prompt"].strip():
        return spec["prompt"].strip()
    palette = direction.get("palette", {}) or {}
    pal_txt = ", ".join(f"{k}: {v}" for k, v in palette.items()) if palette else "not constrained"
    parts = [
        "Design a professional LinkedIn profile banner image — a wide 4:1 horizontal banner, exact canvas "
        f"{canvas['width']}x{canvas['height']} pixels (the official LinkedIn size). The banner must look "
        "premium and personal; it exists to attract recruiters and clients.",
        f"- Concept: {direction.get('concept', '')}",
        f"- Style: {direction.get('style', 'clean, modern, high-end')}",
        f"- Background composition: {direction.get('composition', 'abstract premium background, calm and uncluttered, no people, no photos, no logos')}",
        f"- Color palette (prefer these exact hex values): {pal_txt}",
        f"- Typography hint: {direction.get('typography_hint', 'clean sans-serif, high contrast, crisp edges')}",
    ]
    sig = direction.get("signature_element")
    if isinstance(sig, str) and sig.strip():
        parts.append(f"- Signature element: {sig.strip()}")
    parts += [
        "",
        "Hard layout rules (critical):",
        f"1. LinkedIn overlays the member's profile photo on the BOTTOM-LEFT corner of the banner (desktop). "
        f"Keep the region spanning the left {left_px}px and the bottom {bottom_px}px of the image COMPLETELY "
        "free of text, buttons and fine detail.",
        f"2. On mobile, LinkedIn center-crops the banner to roughly {mw}x{mh}px. All text must therefore sit "
        "inside the central band of the image (middle ~75% of the height), preferably right of center, and must "
        "remain legible at small size.",
        "3. Keep the bottom-left area as a calm background region (no busy detail behind the future profile photo).",
    ]
    return "\n".join(parts)

prompt = visual_prompt()
text_lines = []
if phrase:
    text_lines.append(f'— Phrase (impact line, the LARGEST text): "{phrase}"')
if items:
    lines = []
    for it in items:
        label = it.get("label") or it.get("kind") or ""
        value = it.get("value", "")
        lines.append(f"   - {label + ': ' if label else ''}{value}")
    text_lines.append("— Contact footer row (smaller, crisp, high-contrast text), placed right of center inside the central band:")
    text_lines.append("\n".join(lines))
if text_lines:
    prompt += (
        "\n\nRender EXACTLY the following text. Spelling must be exact — do not paraphrase, reorder, translate "
        "or invent anything:\n" + "\n".join(text_lines)
    )
prompt += (
    "\n\nOutput: a single high-quality 4:1 PNG image covering the full canvas. No letterboxing, no watermark, "
    "no external logos."
)

body = {
    "messages": [{"role": "user", "content": prompt}],
    "model": gen.get("model", "eachsense/beta"),
    "stream": True,
    "mode": gen.get("mode", "max"),
}
sid = spec.get("session_id")
if isinstance(sid, str) and sid.strip():
    body["session_id"] = sid.strip()

with open(out_path, "w", encoding="utf-8") as fh:
    json.dump(body, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

  # --- Stream the each::sense response (SSE) to the log ---------------------
  local curl_rc=0
  curl -sS -N --max-time 900 -o "$sse_log" -X POST "$ENDPOINT" \
       -H "Content-Type: application/json" \
       -H "X-API-Key: $EACHLABS_API_KEY" \
       -H "Accept: text/event-stream" \
       --data-binary @"$req_json" || curl_rc=$?
  if [[ "$curl_rc" -ne 0 ]]; then
    echo "error: each::sense request failed (curl exit $curl_rc) — no image generated. Request saved at $req_json, stream log at $sse_log" >&2
    exit 1
  fi

  # --- Extract the generated image URL from the SSE stream -------------------
  local img_url=""
  if ! img_url="$(python3 - "$sse_log" <<'PY'
import json, sys
path = sys.argv[1]
found_url = ""
last_status = ""
error_msg = ""
with open(path, encoding="utf-8", errors="replace") as fh:
    for raw in fh:
        line = raw.strip()
        if not line.startswith("data:"):
            continue
        payload = line[5:].strip()
        if not payload or payload == "[DONE]":
            continue
        try:
            ev = json.loads(payload)
        except json.JSONDecodeError:
            continue
        each = ev.get("eachlabs") or {}
        etype = each.get("type") or ev.get("type") or ""
        if etype == "generation_response":
            found_url = each.get("url") or ""
            if not found_url and each.get("generations"):
                found_url = each["generations"][0]
        elif etype == "complete":
            last_status = each.get("status", "")
            if not found_url and each.get("generations"):
                found_url = each["generations"][0]
        elif etype == "error":
            error_msg = each.get("message") or each.get("error_code") or "each::sense generation error"
if last_status == "error" or (error_msg and not found_url):
    print(error_msg or "each::sense reported an error", file=sys.stderr)
    sys.exit(1)
if not found_url:
    print("no image URL found in the each::sense stream — see the stream log", file=sys.stderr)
    sys.exit(1)
print(found_url)
PY
    )"; then
    echo "error: generation failed — no image produced. Request saved at $req_json, stream log at $sse_log" >&2
    exit 1
  fi

  # --- Download the image (temp file; only published when valid) -------------
  if ! curl -sS -fL --max-time 300 -o "$dl_tmp" "$img_url"; then
    echo "error: failed to download the generated image ($img_url) — no banner written." >&2
    rm -f "$dl_tmp"
    exit 1
  fi

  # Reject anything that is not a PNG/JPEG so a corrupt/half download or an
  # HTML error page can never ship as the banner.
  local magic
  magic="$(head -c 8 "$dl_tmp" | od -An -tx1 | tr -d ' \n' || true)"
  case "$magic" in
    89504e470d0a1a0a|ffd8ff*) ;;
    *)
      echo "error: downloaded file is not a valid PNG/JPEG image (magic mismatch) — no banner written." >&2
      rm -f "$dl_tmp"
      exit 1
      ;;
  esac

  mv -f "$dl_tmp" "$OUT/banner.png"
  echo "Banner generated: $OUT/banner.png"
  echo "Saved: $OUT/banner.request.json, $OUT/banner.sse.log"
}

# ---------------------------------------------------------------------------
MODE="${1:-}"
case "$MODE" in
  "")
    usage 2
    exit 2
    ;;
  --check)
    cmd_check
    ;;
  --spec)
    # --spec is both the subcommand and the first flag: keep it in the list so
    # parse_args consumes "--spec <file> --content <file> --out <dir>".
    parse_args "$@"
    cmd_generate
    ;;
  --help|-h)
    usage
    exit 0
    ;;
  *)
    usage 2
    exit 2
    ;;
esac
