#!/usr/bin/env bash
# Tests for the Gmail/WhatsApp MCP registration (#248).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$HERE/lib.sh"

REPO="$(cd "$HERE/../.." && pwd -P)"
CFG="$REPO/opencode.json"
REG="$REPO/standards/mcp-registry.md"

t_begin "test_mcp_config"

if ! command -v python3 >/dev/null 2>&1; then
  t_ok "python3 unavailable — skipping JSON assertions"
  t_finish
  exit $?
fi

# --- t01: opencode.json is valid JSON ---------------------------------------
if python3 -m json.tool "$CFG" >/dev/null 2>&1; then
  t_ok "opencode.json is valid JSON"
else
  t_fail "opencode.json is not valid JSON"
fi

# --- t02..t04: mcp entries ------------------------------------------------
read -r GMAIL_OK WHATS_OK NOSECRET <<EOF
$(python3 - "$CFG" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))
mcp = cfg.get("mcp", {})
g = mcp.get("gmail", {})
w = mcp.get("whatsapp", {})
gmail_ok = (
    g.get("type") == "remote"
    and "gmailmcp.googleapis.com" in str(g.get("url", ""))
    and g.get("enabled") is False
)
cmd = w.get("command", [])
whats_ok = (
    w.get("type") == "local"
    and cmd[:1] == ["npx"]
    and any("@fredshred7/whatsapp-mcp-server" in c for c in cmd)
    and w.get("enabled") is False
)
# secrets must be {env:...} placeholders, never literals
envblob = json.dumps(w.get("environment", {}))
nosecret = all(v.startswith("{env:") for v in w.get("environment", {}).values()) if w.get("environment") else False
print("yes" if gmail_ok else "no", "yes" if whats_ok else "no", "yes" if nosecret else "no")
PY
)
EOF

if [ "$GMAIL_OK" = "yes" ]; then
  t_ok "mcp.gmail is remote OAuth endpoint and disabled"
else
  t_fail "mcp.gmail missing/invalid (expected remote gmailmcp.googleapis.com, enabled:false)"
fi

if [ "$WHATS_OK" = "yes" ]; then
  t_ok "mcp.whatsapp is local npx @fredshred7/whatsapp-mcp-server and disabled"
else
  t_fail "mcp.whatsapp missing/invalid (expected local npx server, enabled:false)"
fi

if [ "$NOSECRET" = "yes" ]; then
  t_ok "whatsapp environment values are {env:...} placeholders (no secrets)"
else
  t_fail "whatsapp environment contains a non-placeholder value (possible secret)"
fi

# --- t05: no literal secret patterns in the mcp block ----------------------
if grep -Eq '"(WHATSAPP_ACCESS_TOKEN|WHATSAPP_PHONE_NUMBER_ID|WHATSAPP_BUSINESS_ACCOUNT_ID)":[[:space:]]*"[^"{]' "$CFG"; then
  t_fail "opencode.json embeds a literal WhatsApp credential"
else
  t_ok "no literal WhatsApp credential embedded in opencode.json"
fi

# --- t06: registry no longer uses the wrong key ----------------------------
if grep -q '"mcpServers"' "$REG"; then
  t_fail "standards/mcp-registry.md still uses the mcpServers key"
else
  t_ok "standards/mcp-registry.md uses the 'mcp' key"
fi

# --- t07: setup docs exist in all locales ----------------------------------
for f in standards/mcp-setup.md standards/pt/mcp-setup.md standards/es/mcp-setup.md; do
  if [ -f "$REPO/$f" ]; then
    t_ok "docs: $f present"
  else
    t_fail "docs: $f missing"
  fi
done

t_finish
