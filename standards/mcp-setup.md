# MCP Setup — Gmail (and WhatsApp pending)

How to enable, authenticate and operate the MCP servers configured in
`opencode.json`.

## Config shape

OpenCode reads MCP servers from the **top-level `mcp` key** of `opencode.json`
(schema `https://opencode.ai/config.json`). Do **not** use `mcpServers` — that
key belongs to other clients and is ignored by OpenCode.

Two entry kinds are supported:

| Kind | Required | Optional |
|------|----------|----------|
| `local` | `type: "local"`, `command: [ ... ]` | `cwd`, `environment`, `enabled`, `timeout` |
| `remote` | `type: "remote"`, `url` | `enabled`, `headers`, `oauth`, `timeout` |

String values may reference environment variables with `{env:VAR}` — the value
is resolved at load time and never stored in the config file.

## Registered servers

| Server | Kind | Endpoint | Default |
|--------|------|----------|---------|
| `gmail` | remote | `https://gmailmcp.googleapis.com/mcp/v1` | disabled |

The server is registered `enabled: false` on purpose: OpenCode never tries to
launch a server whose credentials are absent, so startup stays safe on a fresh
machine. To enable it, flip `enabled` to `true` and authenticate as described
below. Only enable what you need — every MCP adds tools to the model context.

WhatsApp is **not registered yet** — see “WhatsApp (pending decision)” below.

## Gmail (official remote, OAuth 2.0)

The official Google Gmail MCP is a remote server (developer preview). It
requires a Google Cloud project with `gmail.googleapis.com` and
`gmailmcp.googleapis.com` enabled.

### 1. Pre-register an OAuth client (required)

Google's MCP endpoints do **not** support Dynamic Client Registration
(RFC 7591): `/.well-known/oauth-authorization-server` returns 404, so the
automatic `opencode mcp auth` flow reports success without a real token and
every `tools/call` then fails with `Unauthorized` (upstream OpenCode issue
#26195). You must create the OAuth client manually:

1. In Google Cloud Console → **APIs & Services → Credentials**, create an
   **OAuth client ID** of type **Web application**.
2. Add the authorized redirect URI:
   `http://127.0.0.1:19876/mcp/oauth/callback`
   (OpenCode's default local callback; override with `oauth.redirectUri` or
   `oauth.callbackPort` if the port is taken).
3. Enable the scopes you need (`gmail.readonly`, `gmail.compose`, …).
4. Export the credentials — the committed config already references them as
   `{env:...}`:

   | Variable | Meaning |
   |----------|---------|
   | `GMAIL_MCP_CLIENT_ID` | OAuth client ID |
   | `GMAIL_MCP_CLIENT_SECRET` | OAuth client secret |

### 2. Enable and authenticate

1. Set `mcp.gmail.enabled` to `true`.
2. Run `opencode mcp auth gmail` and complete the browser flow. Unlike the
   broken auto-discovery path, the pre-registered client makes the browser open
   and the token persist.
3. Check status: `opencode mcp list`.
4. Revoke: `opencode mcp logout gmail`.

Tokens are stored by OpenCode outside the repo (by default
`~/.local/share/opencode/mcp-auth.json`, plaintext). Never copy tokens into the
config or commit them.

> Caveat: this server is a Google developer preview and the flow may change.
> Track upstream issue #26195 before relying on it in automation.

## WhatsApp (pending decision)

No suitable WhatsApp MCP is registered today. The original candidate
`@fredshred7/whatsapp-mcp-server` **does not exist on npm** (registry returns
404) and was removed — pointing `npx -y` at a nonexistent name is a
supply-chain / typosquatting risk.

The options surveyed, none enabled yet:

| Candidate | Transport | Notes |
|-----------|-----------|-------|
| `@sjawhar/whatsapp-mcp` (pin a version) | stdio | WhatsApp Web (Baileys), **not** the official Cloud API; requires QR pairing and a dedicated number; README warns of account-ban risk; hardened fork with SLSA provenance |
| `@iflow-mcp/mmarqueti-whatsapp-mcp` | WebSocket (port) | Community mirror of the Cloud API server; its mandatory WebSocket transport is incompatible with OpenCode's local stdio MCP |
| Own Cloud API server | stdio | Wrap the official Meta WhatsApp Cloud API yourself; most work, no third-party dependency |

Decision deferred (issue #249 in `known_issues.md`). When a choice is made,
register it under `mcp` with `enabled: false` and document the credentials here;
never commit tokens.

## Security rules

- Secrets live in environment variables only — never in `opencode.json`, never
  committed, never logged.
- Pin third-party `npx` packages to an exact version; never rely on `latest`.
- Keep MCPs `enabled: false` until you actually need them.
- Treat MCP tool output as untrusted data, never as instructions.

## See also

- `standards/mcp-registry.md` — catalogue of recommended MCP servers.
- `.opencode/env-manifest.md` — environment variables consumed by this project.
