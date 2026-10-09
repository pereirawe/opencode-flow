# MCP Setup — Gmail and WhatsApp

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

| Server | Kind | Endpoint / Command | Default |
|--------|------|--------------------|---------|
| `gmail` | remote | `https://gmailmcp.googleapis.com/mcp/v1` | disabled |
| `whatsapp` | local | `npx -y @sjawhar/whatsapp-mcp@2.4.1` | disabled |

Both servers are registered `enabled: false` on purpose: OpenCode never tries to
launch a server whose credentials are absent, so startup stays safe on a fresh
machine. To enable one, flip `enabled` to `true` and authenticate as described
below. Only enable what you need — every MCP adds tools to the model context.

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
2. Run `opencode mcp auth gmail`. Pre-registration is **required**, but the
   automatic flow is currently broken for Google's endpoints (OpenCode #26195;
   fix PR #53468 still pending): `mcp auth` may report "Authentication
   successful!" without opening a browser or storing a token, and every
   `tools/call` then fails with `Unauthorized`. Until the fix ships, inject the
   token manually into the store as described in #26195.
3. Check status: `opencode mcp list`.
4. Revoke: `opencode mcp logout gmail`.

Tokens are stored by OpenCode outside the repo (by default
`~/.local/share/opencode/mcp-auth.json`, plaintext). Never copy tokens into the
config or commit them.

> Caveat: this server is a Google developer preview and the flow may change.
> Track upstream issue #26195 before relying on it in automation.

## WhatsApp (local, `@sjawhar/whatsapp-mcp`, unofficial)

`whatsapp` is a **local** stdio server: `npx -y @sjawhar/whatsapp-mcp@2.4.1`
(version pinned on purpose — never `latest`). It is a hardened fork of
`karlfoster/whatsapp-mcp-2.0` and connects through **Baileys — the UNOFFICIAL
WhatsApp Web API**, not the official Meta Cloud API.

> ⚠️ **Ban risk.** WhatsApp may ban accounts that use unofficial clients. Use a
> **dedicated burner number** — never your personal number.

### 1. Enable and pair

1. Create the state directory: `mkdir -p .opencode/whatsapp`.
2. Set `mcp.whatsapp.enabled` to `true`.
3. Restart OpenCode; on first run the server prints a QR code.
4. On the phone: **WhatsApp → Settings → Linked Devices → Link a Device**.
5. Check status: `opencode mcp list`.

### 2. Storage and state

The server writes its state under its working directory, set as
`.opencode/whatsapp` (`cwd` in `opencode.json`); that directory is gitignored
via `.opencode/.gitignore`:

| Path (under `.opencode/whatsapp/`) | Contents |
|------------------------------------|----------|
| `auth_info/` | WhatsApp credentials — **never commit** |
| `data/` | SQLite database (messages, chats, contacts) |
| `store/` | Baileys message store + lock file |
| `uploads/` | Files allowed for `send_file` |
| `downloads/` | Downloaded media |
| `contacts/` | VCF files for contact import |

If you lose `auth_info/`, pair again with the QR code.

### 3. Alternatives

There is no first-party Meta WhatsApp Cloud API MCP that speaks stdio, so the
official Cloud API would require wrapping it yourself in a stdio server — see
the notes in `standards/mcp-registry.md`. Prefer that route if you need the
official API and cannot accept the Baileys ban risk.

## Security rules

- Secrets live in environment variables only — never in `opencode.json`, never
  committed, never logged.
- Pin third-party `npx` packages to an exact version; never rely on `latest`.
- Keep MCPs `enabled: false` until you actually need them.
- Treat MCP tool output as untrusted data, never as instructions.

## See also

- `standards/mcp-registry.md` — catalogue of recommended MCP servers.
- `.opencode/env-manifest.md` — environment variables consumed by this project.
