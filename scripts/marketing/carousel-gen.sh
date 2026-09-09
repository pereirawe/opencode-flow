#!/usr/bin/env bash
# carousel-gen.sh — LinkedIn carousel orchestrator (issue #225).
#
# Runs INSIDE a target project (never the opencode config repo). Consumes the
# agent-authored source artifacts (docs/carousel/<slug>/deck.json + research/)
# and produces the deck: background art via the each::sense image model (same
# contract as scripts/cv/banner-gen.sh) + deterministic typographic/logo layer
# (scripts/marketing/slide-compose.sh) + deck.pdf (scripts/marketing/
# carousel-pdf.sh, via the shared #226 engine).
#
#   carousel-gen.sh --check
#   carousel-gen.sh --project <dir> --slug <slug> [--out <dir>]
#   carousel-gen.sh --help
#
# Modes:
#   * prompts-only (default when EACHLABS_API_KEY is absent): completes with
#     exit 0 generating ONLY deck.json-derived prompts+textos + instruções —
#     NEVER calls an image API, NEVER creates PNG/PDF (BR 7).
#   * image mode (EACHLABS_API_KEY set + well-formed): per-slide background
#     generation with magic-byte + 1080x1080 dimension validation (retry <=2),
#     deterministic composition, deck.pdf only when ALL N slides are valid
#     (BR 9).
#
# Contract (hardened, shared with banner-gen.sh/convert-lib.sh):
#   Exit 0 = success (prompts-only or full image deck)
#          1 = runtime failure (Chrome/Pillow/curl missing, each::sense or
#              download failure, persistent image validation failure) — zero
#              partial artifacts at the destination; deck.json + research/
#              (agent inputs) are always preserved
#          2 = usage error or invalid input (bad flags, preflight failure:
#              missing docs/, invalid person.json, invalid logo, invalid
#              deck.json)
#   Key safety (BR 11): EACHLABS_API_KEY lives only in the environment/HTTP
#   header — never printed, logged or written into any output artifact.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../shared/convert-lib.sh
source "$SCRIPT_DIR/../shared/convert-lib.sh"

ENDPOINT="https://eachsense-agent.core.eachlabs.run/v1/chat/completions"
CANVAS_W=1080
CANVAS_H=1080

usage() { # fd 1=stdout, 2=stderr
  local fd="${1:-1}"
  cat >&"$fd" <<'EOF'
Usage:
  carousel-gen.sh --check
  carousel-gen.sh --project <dir> --slug <slug> [--out <dir>]
  carousel-gen.sh --help

  --check    Verify dependencies (Chrome, python3+Pillow) and the image-model
             key state WITHOUT creating any file. Image mode = ready when
             EACHLABS_API_KEY is set; otherwise prompts-only mode is reported
             (a valid, supported run).
  --project  DIR   target project root (must contain docs/ and
                   docs/assets/person.json). Never the opencode config repo.
  --slug     NAME  deck slug; must match deck.json.slug. Input deck lives at
                   docs/carousel/<slug>/deck.json (authored by the agent).
  --out      DIR   optional output override (default docs/carousel/<slug>/).

Modes: prompts-only (no EACHLABS_API_KEY -> deck.json + prompts+textos +
instruções, NO PNG/PDF) or image mode (each::sense art + deterministic
composition -> slide-*.png + deck.pdf). Nothing is published — manual upload.
EOF
}

PROJECT=""; SLUG=""; OUT=""; TMP=""
parse_args() {
  local i=0
  local -a args=("$@")
  local n=$#
  while (( i < n )); do
    case "${args[$i]}" in
      --project) PROJECT="${args[$((i+1))]:-}"; i=$((i+2)) ;;
      --slug)    SLUG="${args[$((i+1))]:-}";    i=$((i+2)) ;;
      --out)     OUT="${args[$((i+1))]:-}";     i=$((i+2)) ;;
      --help|-h) usage; exit 0 ;;
      *) usage 2; exit 2 ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Environment helpers
# ---------------------------------------------------------------------------
img_magic() { head -c 8 "$1" | od -An -tx1 | tr -d ' \n' || true; }

img_dims() {
  python3 - "$1" <<'PY'
from PIL import Image
import sys
try:
    im = Image.open(sys.argv[1])
    print(f"{im.width}x{im.height}")
except Exception:
    pass
PY
}

magic_is_image() { # PNG/JPEG/WebP accepted for backgrounds (BR 9)
  case "$1" in
    89504e470d0a1a0a|ffd8ff*|52494646*) return 0 ;;
    *) return 1 ;;
  esac
}

magic_is_logo() { # PNG/JPEG/WebP/GIF, plus SVG by content sniffing
  case "$1" in
    89504e470d0a1a0a|ffd8ff*|52494646*|47494638*) return 0 ;;
  esac
  local head
  head="$(head -c 200 "$2" 2>/dev/null || true)"
  case "$head" in
    \<svg*|\<\?xml*) return 0 ;;
  esac
  return 1
}

key_present() { # SILENT probe: 0 when EACHLABS_API_KEY is set + well-formed
  local k="${EACHLABS_API_KEY:-}"
  [[ -n "$k" ]] || return 1
  [[ "$k" =~ [[:space:]] ]] && return 1
  [[ "${#k}" -lt 8 ]] && return 1
  return 0
}

key_check() { # banner-gen.sh contract: set + well-formed, never printed
  local k="${EACHLABS_API_KEY:-}"
  if [[ -z "$k" ]]; then
    echo "error: EACHLABS_API_KEY is not set — carousel image generation uses the each::sense API. Set it in the environment or a local secret before running (never commit it)." >&2
    return 1
  fi
  if [[ "$k" =~ [[:space:]] ]] || [[ "${#k}" -lt 8 ]]; then
    echo "error: EACHLABS_API_KEY has an invalid format — expected a single non-empty token without spaces/newlines. Refusing to run." >&2
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# cmd_check — dependency + key-state probe, creates NOTHING (BR 8).
# ---------------------------------------------------------------------------
cmd_check() {
  local rc=0
  if [[ -z "$(convert_find_chrome)" ]]; then
    echo "error: Google Chrome not found (needed for the deterministic 1080x1080 composition)" >&2
    rc=1
  fi
  if ! python3 -c 'import PIL' >/dev/null 2>&1; then
    echo "error: python3 Pillow not found (needed for the 1080x1080 dimension validation)" >&2
    rc=1
  fi
  if [[ "$rc" -ne 0 ]]; then
    return 1
  fi
  if key_present; then
    echo "ok: dependencies ready — image mode available (EACHLABS_API_KEY set)."
  else
    echo "ok: dependencies ready — prompts-only mode (EACHLABS_API_KEY not set): deck.json + prompts/textos + instruções only, no PNG/PDF."
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Each::sense background generation (banner-gen.sh contract, square canvas).
# Writes into <dir>/<prefix>.request.json + <prefix>.sse.log (key-free).
# ---------------------------------------------------------------------------
gen_background() { # <design_prompt> <dir> <prefix> -> 0 + <dir>/<prefix>.png
  local prompt="$1" dir="$2" prefix="$3"
  local req="$dir/$prefix.request.json" sse="$dir/$prefix.sse.log"
  local dl="$dir/.$prefix.png.tmp"

  # Canonical hard-rule suffix (BR 6): the model contributes ONLY background
  # art — no text/letters ever; deterministic enforcement on top of the
  # agent-authored design prompt.
  prompt+="

Output: a single high-quality background image, exact square canvas 1080x1080 pixels (1:1). ABSOLUTELY NO text, NO letters, NO numbers, NO logos, NO watermark, NO signature — pure background art only. Keep the central area calm and uncluttered; typography will be overlaid on top."

  python3 - "$req" "$prompt" <<'PY'
import json, sys
req_path, prompt = sys.argv[1], sys.argv[2]
body = {
    "messages": [{"role": "user", "content": prompt}],
    "model": "eachsense/beta",
    "stream": True,
    "mode": "max",
}
with open(req_path, "w", encoding="utf-8") as fh:
    json.dump(body, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

  local curl_rc=0
  curl -sS -N --max-time 900 -o "$sse" -X POST "$ENDPOINT" \
       -H "Content-Type: application/json" \
       -H "X-API-Key: $EACHLABS_API_KEY" \
       -H "Accept: text/event-stream" \
       --data-binary @"$req" || curl_rc=$?
  if [[ "$curl_rc" -ne 0 ]]; then
    echo "error: each::sense request failed (curl exit $curl_rc) — no background generated (prefix $prefix)" >&2
    return 1
  fi

  local img_url=""
  if ! img_url="$(python3 - "$sse" <<'PY'
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
    echo "error: generation failed — no image produced (prefix $prefix). Request saved at $req, stream log at $sse" >&2
    return 1
  fi

  rm -f "$dl"
  if ! curl -sS -fL --max-time 300 -o "$dl" "$img_url"; then
    echo "error: failed to download the generated background ($img_url) — no background written (prefix $prefix)." >&2
    rm -f "$dl"
    return 1
  fi

  if ! magic_is_image "$(img_magic "$dl")"; then
    echo "error: downloaded background is not a valid PNG/JPEG/WebP image (magic mismatch) — no background written (prefix $prefix)." >&2
    rm -f "$dl"
    return 1
  fi
  local dims
  dims="$(img_dims "$dl")"
  if [[ "$dims" != "${CANVAS_W}x${CANVAS_H}" ]]; then
    echo "error: downloaded background has dimension $dims, expected ${CANVAS_W}x${CANVAS_H} — rejected (prefix $prefix)." >&2
    rm -f "$dl"
    return 1
  fi

  mv -f "$dl" "$dir/$prefix.png"
  return 0
}

# ---------------------------------------------------------------------------
# Derived artifacts (both modes): prompts+textos (deck locale) + instruções.
# ---------------------------------------------------------------------------
write_prompts_textos() { # <deck.json> <out.md>
  python3 - "$1" "$2" <<'PY'
import json, sys
deck, out_path = sys.argv[1], sys.argv[2]
deck = json.load(open(deck, encoding="utf-8"))
TYPE_LABEL = {"cover": "capa", "content": "conteúdo", "cta": "cta"}
lines = [
    f"# Carrossel LinkedIn: {deck.get('topic', deck.get('slug', ''))}",
    "",
    f"- Slug: `{deck.get('slug')}` · Idioma: {deck.get('locale')} · Slides: {deck.get('n_slides')}",
    "- Estrutura: 1 capa + (N-2) conteúdo + 1 CTA",
    "",
]
for slide in deck.get("slides", []):
    lines.append(f"## Slide {slide.get('index')} — {TYPE_LABEL.get(slide.get('type'), slide.get('type'))}")
    lines.append("")
    lines.append("### Prompt de design (EN)")
    lines.append("")
    lines.append(slide.get("design_prompt", ""))
    lines.append("")
    lines.append("### Texto do slide")
    lines.append("")
    text = slide.get("text", {})
    for key, value in text.items():
        if isinstance(value, list):
            for i, item in enumerate(value, 1):
                lines.append(f"**{key} {i}:** {item}")
        elif isinstance(value, str):
            lines.append(f"**{key}:** {value}")
    lines.append("")
with open(out_path, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines))
PY
}

write_instrucoes() { # <deck.json> <out.md> <mode: image|prompts-only>
  python3 - "$1" "$2" "$3" <<'PY'
import json, sys

deck_path, out_path, mode = sys.argv[1], sys.argv[2], sys.argv[3]
deck = json.load(open(deck_path, encoding="utf-8"))
locale = deck.get("locale", "pt")
slug = deck.get("slug", "")
n = deck.get("n_slides", 0)

T = {
    "pt": {
        "title": "Instruções — carrossel LinkedIn",
        "deck": "deck.json é o artefato fonte (spec por slide: prompt de design EN + texto estruturado).",
        "mode_image": "Modo imagem: as artes foram geradas (each::sense) e a tipografia/logo compostos deterministicamente.",
        "mode_prompts": "Modo prompts-only: as artes NÃO foram geradas. Para cada slide, use o 'Prompt de design (EN)' em uma ferramenta de imagem externa — SEM texto/letras/logo no prompt, canvas quadrado 1080x1080. Depois rode este comando novamente com EACHLABS_API_KEY definida, ou componha manualmente.",
        "files": "Arquivos: research/ (fontes), deck.json, prompts-textos.md, instrucoes.md, slide-01.png … slide-{n}.png, deck.pdf.",
        "upload": "Upload MANUAL no LinkedIn (carrossel): poste as imagens slide-01.png … slide-{n}.png em ordem (1 capa + conteúdo + CTA final). Nada é publicado automaticamente.",
        "verify": "Confira a rastreabilidade: cada afirmação factual dos slides mapeada a ≥1 fonte em research/ (URL + data).",
    },
    "en": {
        "title": "Instructions — LinkedIn carousel",
        "deck": "deck.json is the source artifact (per-slide spec: EN design prompt + structured text).",
        "mode_image": "Image mode: the art was generated (each::sense) and the typography/logo composed deterministically.",
        "mode_prompts": "Prompts-only mode: the art was NOT generated. For each slide, use the 'Design prompt (EN)' in an external image tool — NO text/letters/logo in the prompt, square 1080x1080 canvas. Then re-run this command with EACHLABS_API_KEY set, or compose manually.",
        "files": "Files: research/ (sources), deck.json, prompts-textos.md, instrucoes.md, slide-01.png … slide-{n}.png, deck.pdf.",
        "upload": "Manual upload on LinkedIn (carousel): post slide-01.png … slide-{n}.png in order (1 cover + content + final CTA). Nothing is published automatically.",
        "verify": "Check traceability: every factual claim maps to ≥1 source in research/ (URL + date).",
    },
    "es": {
        "title": "Instrucciones — carrusel LinkedIn",
        "deck": "deck.json es el artefacto fuente (spec por slide: prompt de diseño EN + texto estructurado).",
        "mode_image": "Modo imagen: las artes se generaron (each::sense) y la tipografía/logo se compusieron determinísticamente.",
        "mode_prompts": "Modo solo-prompts: las artes NO se generaron. Para cada slide, use el 'Prompt de diseño (EN)' en una herramienta de imagen externa — SIN texto/letras/logo en el prompt, lienzo cuadrado 1080x1080. Luego vuelva a ejecutar este comando con EACHLABS_API_KEY definida, o componga manualmente.",
        "files": "Archivos: research/ (fuentes), deck.json, prompts-textos.md, instrucciones.md, slide-01.png … slide-{n}.png, deck.pdf.",
        "upload": "Subida MANUAL en LinkedIn (carrusel): publique slide-01.png … slide-{n}.png en orden (1 portada + contenido + CTA final). Nada se publica automáticamente.",
        "verify": "Verifique la trazabilidad: cada afirmación factual mapeada a ≥1 fuente en research/ (URL + fecha).",
    },
}

t = T.get(locale, T["pt"])
lines = [
    f"# {t['title']} — {deck.get('topic', slug)}",
    "",
    t["deck"],
    "",
    t["mode_image"] if mode == "image" else t["mode_prompts"],
    "",
    t["files"].format(n=n),
    "",
    t["upload"].format(n=n),
    "",
    t["verify"],
    "",
    "— Gerado por scripts/marketing/carousel-gen.sh (issue #225), sem publicação automática.",
]
with open(out_path, "w", encoding="utf-8") as fh:
    fh.write("\n".join(lines) + "\n")
PY
}

# ---------------------------------------------------------------------------
# cmd_generate — the full run.
# ---------------------------------------------------------------------------
cmd_generate() {
  if [[ -z "$PROJECT" || -z "$SLUG" ]]; then
    usage 2
    exit 2
  fi
  [[ -d "$PROJECT" ]] || { echo "error: project directory not found: $PROJECT" >&2; exit 2; }
  PROJECT="$(realpath "$PROJECT")"
  local DECK_DIR="$PROJECT/docs/carousel/$SLUG"
  local DECK="$DECK_DIR/deck.json"
  local PERSON="$PROJECT/docs/assets/person.json"

  # --- Preflight (BR 1): zero artifacts created on any failure --------------
  if [[ ! -d "$PROJECT/docs" ]]; then
    echo "error: preflight — $PROJECT/docs does not exist (the command must run in a target project with docs/)." >&2
    exit 2
  fi
  if [[ ! -f "$PERSON" ]]; then
    echo "error: preflight — docs/assets/person.json not found in $PROJECT (BR 1)." >&2
    exit 2
  fi
  local pv_out=""
  if ! pv_out="$(python3 "$SCRIPT_DIR/person-validate.py" "$PERSON" 2>&1)"; then
    echo "error: preflight — docs/assets/person.json is invalid:" >&2
    echo "$pv_out" >&2
    exit 2
  fi
  echo "$pv_out"
  if [[ ! -f "$DECK" ]]; then
    echo "error: preflight — deck.json not found at $DECK (the agent must author docs/carousel/<slug>/deck.json first)." >&2
    exit 2
  fi

  # Person logo gate (BR 1): when present, the logo must be a valid image.
  local logo_path=""
  logo_path="$(python3 - "$PERSON" <<'PY'
import json, sys
p = json.load(open(sys.argv[1], encoding="utf-8"))
print((p.get("logo_path") or "").strip())
PY
)"
  local LOGO_FILE=""
  if [[ -n "$logo_path" ]]; then
    if [[ "$logo_path" == /* ]]; then
      LOGO_FILE="$logo_path"
    else
      LOGO_FILE="$PROJECT/docs/assets/$logo_path"
    fi
    if [[ ! -f "$LOGO_FILE" ]]; then
      echo "error: preflight — logo not found at $LOGO_FILE (from person.json logo_path '$logo_path')." >&2
      exit 2
    fi
    if ! magic_is_logo "$(img_magic "$LOGO_FILE")" "$LOGO_FILE"; then
      echo "error: preflight — logo is not a valid image (magic-byte check failed): $LOGO_FILE" >&2
      exit 2
    fi
  fi

  # Deck structural gate (BR 3/4/10): schema, N, order, per-type text blocks,
  # design prompts, source mapping on content slides.
  local deck_err=""
  if ! deck_err="$(python3 - "$DECK" "$SLUG" "$LOGO_FILE" <<'PY'
import json, re, sys

deck_path, slug, logo_file = sys.argv[1], sys.argv[2], sys.argv[3] or ""
deck = json.load(open(deck_path, encoding="utf-8"))
errs = []

if deck.get("schema") != "linkedin-carousel-deck-v1":
    errs.append("schema must be 'linkedin-carousel-deck-v1'")
if not isinstance(deck.get("slug"), str) or deck["slug"] != slug:
    errs.append(f"slug mismatch: CLI slug '{slug}' != deck.json slug {deck.get('slug')!r}")
if not isinstance(deck.get("topic"), str) or not deck["topic"].strip():
    errs.append("topic is required (non-empty string)")
if deck.get("locale") not in ("pt", "en", "es"):
    errs.append("locale must be one of pt/en/es (user language resolution is the agent's job)")

slides = deck.get("slides")
if not isinstance(slides, list):
    errs.append("slides must be a list (3..20 entries, BR 4)")
    slides = []
else:
    if not (3 <= len(slides) <= 20):
        errs.append(f"slides must be a list of 3..20 entries (BR 4), got {len(slides)}")
    if not isinstance(deck.get("n_slides"), int) or deck["n_slides"] != len(slides):
        errs.append("n_slides must equal len(slides)")

# Per-slide checks run for every slide so ALL errors are reported at once
# (never gated by earlier errors).
if slides:
    if slides[0].get("type") != "cover":
        errs.append("slide 1 must be type 'cover'")
    if slides[-1].get("type") != "cta":
        errs.append(f"last slide (index {len(slides)}) must be type 'cta'")
    expected_idx = 1
    for i, s in enumerate(slides):
        if not isinstance(s, dict):
            errs.append(f"slide[{i}] must be an object"); continue
        if s.get("index") != expected_idx:
            errs.append(f"slide index must be sequential (expected {expected_idx}, got {s.get('index')!r})")
        expected_idx += 1
        stype = s.get("type")
        if i == 0 or i == len(slides) - 1:
            if stype not in ("cover", "cta"):
                errs.append(f"slide {s.get('index')}: type must be cover/cta on the ends, got {stype!r}")
        else:
            if stype != "content":
                errs.append(f"slide {s.get('index')}: middle slides must be type 'content', got {stype!r}")
        if not isinstance(s.get("design_prompt"), str) or not s["design_prompt"].strip():
            errs.append(f"slide {s.get('index')}: design_prompt (EN) is required")
        text = s.get("text")
        if not isinstance(text, dict):
            errs.append(f"slide {s.get('index')}: text block is required"); continue
        if stype == "cover":
            for k in ("TITULO",):
                if not isinstance(text.get(k), str) or not text[k].strip():
                    errs.append(f"slide {s.get('index')}: text.{k} is required")
            for k in ("SUBTITULO", "RODAPE"):
                if k in text and not isinstance(text[k], str):
                    errs.append(f"slide {s.get('index')}: text.{k} must be a string")
        elif stype == "content":
            for k in ("HEADLINE",):
                if not isinstance(text.get(k), str) or not text[k].strip():
                    errs.append(f"slide {s.get('index')}: text.{k} is required")
            if not isinstance(text.get("BULLETS"), list) or not any(
                isinstance(b, str) and b.strip() for b in text["BULLETS"]
            ):
                errs.append(f"slide {s.get('index')}: text.BULLETS must be a non-empty array of strings")
            for k in ("TAG", "DETALHE"):
                if k in text and not isinstance(text[k], str):
                    errs.append(f"slide {s.get('index')}: text.{k} must be a string")
            sources = s.get("sources")
            if not isinstance(sources, list) or len(sources) == 0:
                errs.append(f"slide {s.get('index')}: content slides require >=1 source (BR 10)")
            else:
                for j, src in enumerate(sources):
                    if not isinstance(src, dict) or not isinstance(src.get("url"), str) or not src["url"].strip():
                        errs.append(f"slide {s.get('index')}: sources[{j}].url is required")
                    if not re.match(r"^\d{4}-\d{2}-\d{2}$", src.get("accessed") or ""):
                        errs.append(f"slide {s.get('index')}: sources[{j}].accessed must be a date YYYY-MM-DD")
        elif stype == "cta":
            for k in ("HEADLINE", "CTA"):
                if not isinstance(text.get(k), str) or not text[k].strip():
                    errs.append(f"slide {s.get('index')}: text.{k} is required")
            for k in ("SUBHEADLINE", "RODAPE"):
                if k in text and not isinstance(text[k], str):
                    errs.append(f"slide {s.get('index')}: text.{k} must be a string")
        else:
            errs.append(f"slide {s.get('index')}: unknown type {stype!r}")

if errs:
    sys.stderr.write("\n".join("error: deck.json: " + e for e in errs) + "\n")
    sys.exit(1)
PY
)"; then
  echo "error: preflight — deck.json is invalid:" >&2
  echo "$deck_err" >&2
  exit 2
fi

  # --- Dependency gate (BR 8) ----------------------------------------------
  if [[ -z "$(convert_find_chrome)" ]]; then
    echo "error: Google Chrome not found (needed for the deterministic composition)" >&2
    exit 1
  fi
  if ! python3 -c 'import PIL' >/dev/null 2>&1; then
    echo "error: python3 Pillow not found (needed for the 1080x1080 dimension validation)" >&2
    exit 1
  fi

  # --- Mode selection -------------------------------------------------------
  local OUT_DIR="${OUT:-$DECK_DIR}"
  mkdir -p "$OUT_DIR" || { echo "error: cannot create output directory: $OUT_DIR" >&2; exit 1; }

  TMP="$(mktemp -d "$OUT_DIR/.carousel-tmp.XXXXXX")"
  # Robust EXIT trap: TMP is a global, but guard against unset under set -u
  # (e.g. an early exit path) so the temp dir is ALWAYS cleaned up.
  trap '[[ -n "${TMP:-}" ]] && rm -rf "$TMP"' EXIT

  # prompts+textos and instruções are generated in BOTH modes (BR 3/7).
  local PROMPTS_TXT="$TMP/prompts-textos.md"
  local INSTRUCOES="$TMP/instrucoes.md"
  write_prompts_textos "$DECK" "$PROMPTS_TXT"
  write_instrucoes "$DECK" "$INSTRUCOES" "prompts-only"

  if ! key_check; then
    # ---- prompts-only fallback (BR 7): exit 0, NO PNG/PDF, no API call ----
    mv -f "$PROMPTS_TXT" "$OUT_DIR/prompts-textos.md"
    mv -f "$INSTRUCOES" "$OUT_DIR/instrucoes.md"
    echo "Modo prompts-only: EACHLABS_API_KEY ausente — deck.json + prompts/textos + instruções gerados sem chamar API de imagem e sem criar PNG/PDF (BR 7)."
    echo "  $OUT_DIR/deck.json"
    echo "  $OUT_DIR/prompts-textos.md"
    echo "  $OUT_DIR/instrucoes.md"
    echo "Re-execute com EACHLABS_API_KEY definida para gerar artes + slide-*.png + deck.pdf."
    return 0
  fi

  # ---- image mode ----------------------------------------------------------
  if ! command -v curl >/dev/null 2>&1; then
    echo "error: curl not found — required to call the each::sense endpoint" >&2
    exit 1
  fi
  write_instrucoes "$DECK" "$INSTRUCOES" "image"

  local N
  N="$(python3 - "$DECK" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["n_slides"])
PY
)"

  # Per-slide: background art (each::sense, retry <=2) -> deterministic compose.
  local idx prompt bg
  local attempts=3 rc
  for idx in $(seq 1 "$N"); do
    prompt="$(python3 - "$DECK" "$idx" <<'PY'
import json, sys
deck = json.load(open(sys.argv[1], encoding="utf-8"))
slide = next(s for s in deck["slides"] if s["index"] == int(sys.argv[2]))
print(slide["design_prompt"])
PY
)"
    bg=""
    rc=1
    for attempt in $(seq 1 "$attempts"); do
      if gen_background "$prompt" "$TMP" "art-$(printf '%02d' "$idx")"; then
        bg="$TMP/art-$(printf '%02d' "$idx").png"
        rc=0
        break
      fi
      if [[ "$attempt" -lt "$attempts" ]]; then
        echo "warning: background generation failed (attempt $attempt/$attempts) — retrying slide $idx..." >&2
      fi
    done
    if [[ "$rc" -ne 0 || -z "$bg" ]]; then
      echo "error: could not generate a valid 1080x1080 background for slide $idx after $attempts attempts — aborting cleanly (no partial artifacts; deck.json + research preserved)." >&2
      exit 1
    fi
    echo "Background OK: slide $idx"
    if ! bash "$SCRIPT_DIR/slide-compose.sh" \
         --deck "$DECK" --person "$PERSON" --slide "$idx" \
         --bg "$bg" --out "$TMP/slide-$(printf '%02d' "$idx").png"; then
      echo "error: deterministic composition failed for slide $idx" >&2
      exit 1
    fi
  done

  # deck.pdf ONLY when every slide is valid (BR 9) — the PDF helper re-validates.
  if ! bash "$SCRIPT_DIR/carousel-pdf.sh" --deck "$DECK" --images "$TMP" --out "$TMP/deck.pdf"; then
    echo "error: deck.pdf assembly failed" >&2
    exit 1
  fi

  # --- Publish (all-or-nothing: only complete, validated artifacts) ---------
  local f
  for f in "$TMP"/slide-*.png "$TMP"/slide-*.html \
           "$TMP"/art-*.request.json "$TMP"/art-*.sse.log \
           "$TMP"/prompts-textos.md "$TMP"/instrucoes.md "$TMP"/deck.pdf; do
    [[ -e "$f" ]] || continue
    mv -f "$f" "$OUT_DIR/"
  done

  echo "Carousel gerado (modo imagem): $OUT_DIR"
  echo "  slide-01.png … slide-$(printf '%02d' "$N").png (1080x1080), deck.pdf (N páginas quadradas)"
  echo "  deck.json (fonte), prompts-textos.md, instrucoes.md, research/"
  echo "Nada é publicado — upload manual no LinkedIn."
  return 0
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
  --project)
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
