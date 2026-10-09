#!/usr/bin/env bash
# Tests for the Gmail MCP registration (#248; WhatsApp deferred to #249).
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
read -r GMAIL_OK OAUTH_OK NOWHATS <<EOF
$(python3 - "$CFG" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))
mcp = cfg.get("mcp", {})
g = mcp.get("gmail", {})
gmail_ok = (
    g.get("type") == "remote"
    and "gmailmcp.googleapis.com" in str(g.get("url", ""))
    and g.get("enabled") is False
)
# OAuth must be pre-registered (Google has no dynamic client registration),
# with clientId/clientSecret as {env:...} placeholders.
oauth = g.get("oauth", {}) if isinstance(g.get("oauth"), dict) else {}
oauth_ok = (
    str(oauth.get("clientId", "")).startswith("{env:")
    and str(oauth.get("clientSecret", "")).startswith("{env:")
    and isinstance(oauth.get("scope"), str)
    and len(oauth.get("scope", "")) > 0
)
# WhatsApp must NOT be registered until a provider decision (#249).
nowhats = "whatsapp" not in mcp
print("yes" if gmail_ok else "no", "yes" if oauth_ok else "no", "yes" if nowhats else "no")
PY
)
EOF

if [ "$GMAIL_OK" = "yes" ]; then
  t_ok "mcp.gmail is remote OAuth endpoint and disabled"
else
  t_fail "mcp.gmail missing/invalid (expected remote gmailmcp.googleapis.com, enabled:false)"
fi

if [ "$OAUTH_OK" = "yes" ]; then
  t_ok "mcp.gmail oauth uses {env:...} clientId/clientSecret and a scope"
else
  t_fail "mcp.gmail oauth block missing/incomplete (need {env:...} clientId+clientSecret+scope)"
fi

if [ "$NOWHATS" = "yes" ]; then
  t_ok "mcp.whatsapp not registered (decision deferred — issue #249)"
else
  t_fail "mcp.whatsapp is registered but no vetted package was chosen"
fi

# --- t05: the fictional cloud package is gone from config/registry ----------
# (setup docs may mention it as a removed candidate; the config must not use it)
if grep -q '@fredshred7/whatsapp-mcp-server' "$CFG" "$REG"; then
  t_fail "nonexistent @fredshred7/whatsapp-mcp-server still referenced in config"
else
  t_ok "nonexistent @fredshred7/whatsapp-mcp-server not used in config/registry"
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
