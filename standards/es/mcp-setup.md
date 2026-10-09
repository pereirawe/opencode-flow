# MCP Setup — Gmail & WhatsApp

Cómo habilitar, autenticar y operar los servidores MCP de Gmail y WhatsApp
registrados en `opencode.json`.

## Forma del config

OpenCode lee los servidores MCP desde la **clave top-level `mcp`** de
`opencode.json` (schema `https://opencode.ai/config.json`). **No** uses
`mcpServers` — esa clave pertenece a otros clientes y OpenCode la ignora.

Se soportan dos tipos de entrada:

| Tipo | Obligatorio | Opcional |
|------|-------------|----------|
| `local` | `type: "local"`, `command: [ ... ]` | `cwd`, `environment`, `enabled`, `timeout` |
| `remote` | `type: "remote"`, `url` | `enabled`, `headers`, `oauth`, `timeout` |

Los valores de texto pueden referenciar variables de entorno con `{env:VAR}` —
se resuelven al cargar y nunca quedan escritos en el archivo de config.

## Servidores registrados

Ambos servidores quedan `enabled: false` a propósito: OpenCode nunca intenta
iniciar un servidor cuyo binario o credenciales faltan, así el arranque sigue
siendo seguro en una máquina nueva.

| Servidor | Tipo | Endpoint / comando | Por defecto |
|----------|------|--------------------|-------------|
| `gmail` | remote | `https://gmailmcp.googleapis.com/mcp/v1` | deshabilitado |
| `whatsapp` | local | `npx -y @fredshred7/whatsapp-mcp-server` | deshabilitado |

Para habilitar, cambia `enabled` a `true` en `opencode.json` y autentícate como
se indica abajo. Habilita solo lo necesario — cada MCP añade herramientas al
contexto.

## Gmail (remoto oficial, OAuth 2.0)

El Gmail MCP oficial de Google es un servidor remoto (developer preview).
Requiere un proyecto en Google Cloud con `gmail.googleapis.com` y
`gmailmcp.googleapis.com` habilitadas.

1. Define `mcp.gmail.enabled` como `true`.
2. Autentica: `opencode mcp auth gmail` (abre el flujo OAuth en el navegador).
3. Verifica: `opencode mcp list`.
4. Revoca: `opencode mcp logout gmail`.

Los tokens se guardan fuera del repositorio (por defecto
`~/.local/share/opencode/mcp-auth.json`). Nunca copies tokens al config ni los
commitees.

## WhatsApp (Cloud API oficial)

`@fredshred7/whatsapp-mcp-server` habla con la WhatsApp Cloud API oficial de
Meta. Necesita tres variables de entorno (obténlas en Meta for Developers →
WhatsApp → API Setup):

| Variable | Significado |
|----------|-------------|
| `WHATSAPP_ACCESS_TOKEN` | Token de acceso de la Cloud API |
| `WHATSAPP_PHONE_NUMBER_ID` | ID del número remitente |
| `WHATSAPP_BUSINESS_ACCOUNT_ID` | ID de la cuenta WhatsApp Business |

Expórtalas en el shell/gestor de secretos y define `mcp.whatsapp.enabled` como
`true`. El config las referencia como `{env:...}`, así ningún secreto se escribe
en el repositorio.

### Cloud API vs WhatsApp personal

Registramos la **Cloud API oficial** porque no necesita bridge ni QR y no corre
riesgo de baneo de la cuenta. La alternativa — bridge en el número personal como
`lharries/whatsapp-mcp` (bridge Go + servidor Python, auth por QR) — solo vale
la pena si necesitas actuar como usuario personal de WhatsApp y puedes mantener
la bridge corriendo.

## Reglas de seguridad

- Los secretos viven solo en variables de entorno — nunca en `opencode.json`,
  nunca commiteados, nunca logueados.
- Mantén los MCPs `enabled: false` hasta que realmente los necesites.
- Trata la salida de las herramientas MCP como dato no confiable, nunca como
  instrucción.

## Ver también

- `standards/mcp-registry.md` — catálogo de MCPs recomendados.
- `.opencode/env-manifest.md` — variables de entorno consumidas por el proyecto.
