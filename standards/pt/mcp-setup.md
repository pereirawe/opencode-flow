# Configuração de MCP — Gmail (e WhatsApp pendente)

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

| Servidor | Tipo | Endpoint | Padrão |
|----------|------|----------|--------|
| `gmail` | remote | `https://gmailmcp.googleapis.com/mcp/v1` | desabilitado |

O servidor é registrado com `enabled: false` de propósito: o OpenCode nunca
tenta iniciar um servidor cujas credenciais estão ausentes, então o startup
permanece seguro numa máquina nova. Para habilitar, mude `enabled` para `true` e
autentique como descrito abaixo. Habilite só o que precisar — todo MCP adiciona
ferramentas ao contexto do modelo.

O WhatsApp **ainda não está registrado** — veja “WhatsApp (decisão pendente)”.

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
2. Rode `opencode mcp auth gmail` e conclua o fluxo no navegador. Diferente do
   caminho de descoberta automática quebrado, o cliente pré-registrado faz o
   navegador abrir e o token persistir.
3. Verifique o status: `opencode mcp list`.
4. Revogue: `opencode mcp logout gmail`.

Os tokens são guardados pelo OpenCode fora do repositório (por padrão
`~/.local/share/opencode/mcp-auth.json`, em texto puro). Nunca copie tokens para
a config nem os versione.

> Atenção: este servidor é um developer preview do Google e o fluxo pode mudar.
> Acompanhe a issue upstream #26195 antes de depender dele em automação.

## WhatsApp (decisão pendente)

Nenhum MCP de WhatsApp adequado está registrado hoje. O candidato original
`@fredshred7/whatsapp-mcp-server` **não existe no npm** (o registry retorna 404)
e foi removido — apontar `npx -y` para um nome inexistente é risco de cadeia de
suprimentos / typosquatting.

As opções levantadas, nenhuma habilitada ainda:

| Candidato | Transporte | Observações |
|-----------|------------|-------------|
| `@sjawhar/whatsapp-mcp` (fixar versão) | stdio | WhatsApp Web (Baileys), **não** é a Cloud API oficial; exige pareamento por QR e número dedicado; o README alerta risco de ban da conta; fork reforçado com proveniência SLSA |
| `@iflow-mcp/mmarqueti-whatsapp-mcp` | WebSocket (porta) | Espelho comunitário do servidor Cloud API; o transporte WebSocket obrigatório é incompatível com o MCP local stdio do OpenCode |
| Servidor Cloud API próprio | stdio | Encapsular você mesmo a WhatsApp Cloud API oficial da Meta; mais trabalho, sem dependência de terceiros |

Decisão adiada (issue #249 no `known_issues.md`). Quando houver escolha, registre
sob `mcp` com `enabled: false` e documente as credenciais aqui; nunca versione
tokens.

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
