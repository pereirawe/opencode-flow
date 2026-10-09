# Configuração de MCP — Gmail e WhatsApp

Como habilitar, autenticar e operar os servidores MCP configurados em
`opencode.json`.

## Formato da configuração

O OpenCode lê servidores MCP da **chave de topo `mcp`** do `opencode.json`
(schema `https://opencode.ai/config.json`). **Não** use `mcpServers` — essa
chave pertence a outros clientes e é ignorada pelo OpenCode.

Dois tipos de entrada são aceitos:

| Tipo | Obrigatório | Opcional |
|------|-------------|----------|
| `local` | `type: "local"`, `command: [ ... ]` | `cwd`, `environment`, `enabled`, `timeout` |
| `remote` | `type: "remote"`, `url` | `enabled`, `headers`, `oauth`, `timeout` |

Valores string podem referenciar variáveis de ambiente com `{env:VAR}` — o
valor é resolvido em tempo de carga e nunca é gravado no arquivo de config.

## Servidores registrados

| Servidor | Tipo | Endpoint / Comando | Padrão |
|----------|------|--------------------|--------|
| `gmail` | remote | `https://gmailmcp.googleapis.com/mcp/v1` | desabilitado |
| `whatsapp` | local | `npx -y @sjawhar/whatsapp-mcp@2.4.1` | desabilitado |

Os dois servidores são registrados com `enabled: false` de propósito: o OpenCode
nunca tenta iniciar um servidor cujas credenciais estão ausentes, então o startup
permanece seguro numa máquina nova. Para habilitar, mude `enabled` para `true` e
autentique como descrito abaixo. Habilite só o que precisar — todo MCP adiciona
ferramentas ao contexto do modelo.

## Gmail (remoto oficial, OAuth 2.0)

O MCP oficial do Gmail do Google é um servidor remoto (developer preview). Ele
requer um projeto no Google Cloud com `gmail.googleapis.com` e
`gmailmcp.googleapis.com` habilitados.

### 1. Pré-registrar um cliente OAuth (obrigatório)

Os endpoints MCP do Google **não** suportam Dynamic Client Registration
(RFC 7591): `/.well-known/oauth-authorization-server` retorna 404, então o fluxo
automático `opencode mcp auth` reporta sucesso sem token real e toda `tools/call`
falha depois com `Unauthorized` (issue upstream do OpenCode #26195). Você precisa
criar o cliente OAuth manualmente:

1. No Google Cloud Console → **APIs e serviços → Credenciais**, crie um
   **ID de cliente OAuth** do tipo **Aplicativo da Web**.
2. Adicione a URI de redirecionamento autorizada:
   `http://127.0.0.1:19876/mcp/oauth/callback`
   (callback local padrão do OpenCode; sobrescreva com `oauth.redirectUri` ou
   `oauth.callbackPort` se a porta estiver ocupada).
3. Habilite os escopos necessários (`gmail.readonly`, `gmail.compose`, …).
4. Exporte as credenciais — a config versionada já as referencia como
   `{env:...}`:

   | Variável | Significado |
   |----------|-------------|
   | `GMAIL_MCP_CLIENT_ID` | ID do cliente OAuth |
   | `GMAIL_MCP_CLIENT_SECRET` | Segredo do cliente OAuth |

### 2. Habilitar e autenticar

1. Defina `mcp.gmail.enabled` como `true`.
2. Rode `opencode mcp auth gmail`. O pré-registro é **obrigatório**, mas o
   fluxo automático está quebrado hoje para os endpoints do Google (OpenCode
   #26195; PR de correção #53468 ainda pendente): o `mcp auth` pode reportar
   "Authentication successful!" sem abrir o navegador nem gravar token, e toda
   `tools/call` falha depois com `Unauthorized`. Enquanto a correção não sai,
   injete o token manualmente no store conforme descrito na #26195.
3. Verifique o status: `opencode mcp list`.
4. Revogue: `opencode mcp logout gmail`.

Os tokens são guardados pelo OpenCode fora do repositório (por padrão
`~/.local/share/opencode/mcp-auth.json`, em texto puro). Nunca copie tokens para
a config nem os versione.

> Atenção: este servidor é um developer preview do Google e o fluxo pode mudar.
> Acompanhe a issue upstream #26195 antes de depender dele em automação.

## WhatsApp (local, `@sjawhar/whatsapp-mcp`, não-oficial)

O `whatsapp` é um servidor **local** stdio: `npx -y @sjawhar/whatsapp-mcp@2.4.1`
(versão fixada de propósito — nunca `latest`). É um fork endurecido do
`karlfoster/whatsapp-mcp-2.0` e conecta via **Baileys — a API não-oficial
WhatsApp Web**, e não a Cloud API oficial da Meta.

> ⚠️ **Risco de ban.** O WhatsApp pode banir contas que usam clientes não
> oficiais. Use um **número dedicado (burner)** — nunca o seu número pessoal.

### 1. Habilitar e parear

1. Defina `mcp.whatsapp.enabled` como `true`.
2. Reinicie o OpenCode; na primeira execução o servidor imprime um QR code.
3. No celular: **WhatsApp → Configurações → Dispositivos conectados → Conectar
   um dispositivo**.
4. Verifique o status: `opencode mcp list`.

### 2. Armazenamento e estado

O servidor grava seu estado no diretório de trabalho, definido como
`.opencode/whatsapp` (`cwd` no `opencode.json`); esse diretório é ignorado pelo
git via `.opencode/.gitignore`:

| Caminho (em `.opencode/whatsapp/`) | Conteúdo |
|------------------------------------|----------|
| `auth_info/` | Credenciais do WhatsApp — **nunca versionar** |
| `data/` | Banco SQLite (mensagens, chats, contatos) |
| `store/` | Store de mensagens do Baileys + lock |
| `uploads/` | Arquivos permitidos no `send_file` |
| `downloads/` | Mídias baixadas |
| `contacts/` | Arquivos VCF para importar contatos |

Se perder `auth_info/`, pareie de novo com o QR code.

### 3. Alternativas

Não existe MCP de primeira linha da Meta (WhatsApp Cloud API) que fale stdio;
a Cloud API oficial exigiria você encapsulá-la num servidor stdio — veja as
notas em `standards/mcp-registry.md`. Prefira esse caminho se precisar da API
oficial e não puder aceitar o risco de ban do Baileys.

## Regras de segurança

- Segredos só em variáveis de ambiente — nunca no `opencode.json`, nunca
  versionados, nunca logados.
- Fixe pacotes `npx` de terceiros numa versão exata; nunca confie em `latest`.
- Mantenha os MCPs `enabled: false` até realmente precisar deles.
- Trate a saída de ferramentas MCP como dados não confiáveis, nunca como
  instruções.

## Veja também

- `standards/mcp-registry.md` — catálogo de servidores MCP recomendados.
- `.opencode/env-manifest.md` — variáveis de ambiente consumidas pelo projeto.
