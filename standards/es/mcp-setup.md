# Configuración de MCP — Gmail y WhatsApp

Cómo habilitar, autenticar y operar los servidores MCP configurados en
`opencode.json`.

## Forma de la configuración

OpenCode lee los servidores MCP de la **clave de nivel superior `mcp`** de
`opencode.json` (schema `https://opencode.ai/config.json`). **No** uses
`mcpServers` — esa clave pertenece a otros clientes y OpenCode la ignora.

Se admiten dos tipos de entrada:

| Tipo | Obligatorio | Opcional |
|------|-------------|----------|
| `local` | `type: "local"`, `command: [ ... ]` | `cwd`, `environment`, `enabled`, `timeout` |
| `remote` | `type: "remote"`, `url` | `enabled`, `headers`, `oauth`, `timeout` |

Los valores de cadena pueden referenciar variables de entorno con `{env:VAR}` —
el valor se resuelve al cargar y nunca se guarda en el archivo de configuración.

## Servidores registrados

| Servidor | Tipo | Endpoint / Comando | Predeterminado |
|----------|------|--------------------|----------------|
| `gmail` | remote | `https://gmailmcp.googleapis.com/mcp/v1` | deshabilitado |
| `whatsapp` | local | `npx -y @sjawhar/whatsapp-mcp@2.4.1` | deshabilitado |

Los dos servidores se registran con `enabled: false` a propósito: OpenCode nunca
intenta iniciar un servidor cuyas credenciales faltan, así el arranque sigue
seguro en una máquina nueva. Para habilitar uno, cambia `enabled` a `true` y
autentica como se describe abajo. Habilita solo lo que necesites — cada MCP
añade herramientas al contexto del modelo.

## Gmail (remoto oficial, OAuth 2.0)

El MCP oficial de Gmail de Google es un servidor remoto (developer preview).
Requiere un proyecto en Google Cloud con `gmail.googleapis.com` y
`gmailmcp.googleapis.com` habilitados.

### 1. Pre-registrar un cliente OAuth (obligatorio)

Los endpoints MCP de Google **no** admiten Dynamic Client Registration
(RFC 7591): `/.well-known/oauth-authorization-server` devuelve 404, por lo que el
flujo automático `opencode mcp auth` informa éxito sin token real y cada
`tools/call` falla después con `Unauthorized` (issue upstream de OpenCode
#26195). Debes crear el cliente OAuth manualmente:

1. En Google Cloud Console → **APIs y servicios → Credenciales**, crea un
   **ID de cliente OAuth** de tipo **Aplicación web**.
2. Añade la URI de redirección autorizada:
   `http://127.0.0.1:19876/mcp/oauth/callback`
   (callback local predeterminado de OpenCode; sobrescríbelo con
   `oauth.redirectUri` u `oauth.callbackPort` si el puerto está ocupado).
3. Habilita los scopes necesarios (`gmail.readonly`, `gmail.compose`, …).
4. Exporta las credenciales — la config versionada ya las referencia como
   `{env:...}`:

   | Variable | Significado |
   |----------|-------------|
   | `GMAIL_MCP_CLIENT_ID` | ID de cliente OAuth |
   | `GMAIL_MCP_CLIENT_SECRET` | Secreto de cliente OAuth |

### 2. Habilitar y autenticar

1. Define `mcp.gmail.enabled` como `true`.
2. Ejecuta `opencode mcp auth gmail`. El pre-registro es **obligatorio**, pero
   el flujo automático está roto hoy para los endpoints de Google (OpenCode
   #26195; PR de corrección #53468 aún pendiente): `mcp auth` puede informar
   "Authentication successful!" sin abrir el navegador ni guardar token, y cada
   `tools/call` falla después con `Unauthorized`. Mientras no salga la
   corrección, inyecta el token manualmente en el store como se describe en
   #26195.
3. Comprueba el estado: `opencode mcp list`.
4. Revoca: `opencode mcp logout gmail`.

OpenCode guarda los tokens fuera del repositorio (por defecto
`~/.local/share/opencode/mcp-auth.json`, en texto plano). Nunca copies tokens a
la config ni los versiones.

> Advertencia: este servidor es un developer preview de Google y el flujo puede
> cambiar. Sigue la issue upstream #26195 antes de depender de él en automatización.

## WhatsApp (local, `@sjawhar/whatsapp-mcp`, no oficial)

`whatsapp` es un servidor **local** stdio: `npx -y @sjawhar/whatsapp-mcp@2.4.1`
(versión fijada a propósito — nunca `latest`). Es un fork reforzado de
`karlfoster/whatsapp-mcp-2.0` y se conecta vía **Baileys — la API no oficial de
WhatsApp Web**, no la Cloud API oficial de Meta.

> ⚠️ **Riesgo de ban.** WhatsApp puede banear cuentas que usan clientes no
> oficiales. Usa un **número dedicado (burner)** — nunca tu número personal.

### 1. Habilitar y emparejar

1. Define `mcp.whatsapp.enabled` como `true`.
2. Reinicia OpenCode; en la primera ejecución el servidor imprime un código QR.
3. En el teléfono: **WhatsApp → Ajustes → Dispositivos vinculados → Vincular un
   dispositivo**.
4. Comprueba el estado: `opencode mcp list`.

### 2. Almacenamiento y estado

El servidor guarda su estado en su directorio de trabajo, definido como
`.opencode/whatsapp` (`cwd` en `opencode.json`); ese directorio está ignorado por
git vía `.opencode/.gitignore`:

| Ruta (en `.opencode/whatsapp/`) | Contenido |
|---------------------------------|-----------|
| `auth_info/` | Credenciales de WhatsApp — **nunca versionar** |
| `data/` | Base SQLite (mensajes, chats, contactos) |
| `store/` | Store de mensajes de Baileys + lock |
| `uploads/` | Archivos permitidos en `send_file` |
| `downloads/` | Medios descargados |
| `contacts/` | Archivos VCF para importar contactos |

Si pierdes `auth_info/`, empareja de nuevo con el código QR.

### 3. Alternativas

No existe un MCP de primera parte de Meta (WhatsApp Cloud API) que hable stdio;
la Cloud API oficial requeriría que la envuelvas tú mismo en un servidor stdio —
ver las notas en `standards/mcp-registry.md`. Prefiere esa vía si necesitas la
API oficial y no puedes aceptar el riesgo de ban de Baileys.

## Reglas de seguridad

- Los secretos viven solo en variables de entorno — nunca en `opencode.json`,
  nunca versionados, nunca logueados.
- Fija los paquetes `npx` de terceros a una versión exacta; nunca confíes en
  `latest`.
- Mantén los MCP `enabled: false` hasta que realmente los necesites.
- Trata la salida de las herramientas MCP como datos no confiables, nunca como
  instrucciones.

## Ver también

- `standards/mcp-registry.md` — catálogo de servidores MCP recomendados.
- `.opencode/env-manifest.md` — variables de entorno consumidas por el proyecto.
