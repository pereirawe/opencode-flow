---
name: cv-linkedin-banner
description: Generate the LinkedIn profile banner of the candidate (4:1, 1584×396) with an external image model (each::sense via the vendored poster-design-generation skill / scripts/cv/banner-gen.sh, EACHLABS_API_KEY) from the REAL hub.json data and an art-director visual direction — phone, email, social links and a short impact phrase derived from the profile, laid out as a footer while RESPECTING the profile-photo safe zone (bottom-left guard ≈ left 500px × bottom 260px on desktop) and staying legible in the mobile center-crop. Outputs land in ~/career/<candidate>/linkedin/banner/ (final PNG + spec md/json + desktop/mobile crop previews); nothing is published — the user uploads manually. AI text is gated (up to 2 retries) with a deterministic crisp-text overlay fallback that guarantees correct phone/email/handle. Use when you need to create a LinkedIn cover banner for a candidate (command ocf:cv-banner; "banner do LinkedIn", "banner do perfil", "capa do linkedin" also trigger this skill). Career sector.
---

# CV LinkedIn Banner — banner de perfil com direção de design + each::sense

Gera o **banner do perfil LinkedIn** do candidato (canvas 4:1, **1584×396**,
tamanho oficial recomendado) com um modelo de imagem externo (each::sense),
a partir de:
1. uma **direção visual** produzida pelo agente `design/art-director`
   (`agents/design/art-director.md` — reuso, não duplicação);
2. os **dados REAIS do hub** (`hub.json`) — telefone, e-mail, redes sociais e
   a **frase de impacto** curta destilada do perfil (~30 palavras do summary →
   frase curta e legível).

O objetivo do banner é chamar atenção do recrutador/cliente: ser contratado e
oferecer serviços. **Nada é publicado** — o usuário faz o upload manualmente no
LinkedIn; o fluxo entrega os arquivos prontos + previews de conferência.

> Requisito crítico: a **foto de perfil do LinkedIn fica sobreposta ao canto
> inferior esquerdo** do banner no desktop e o LinkedIn **corta/redimensiona a
> faixa central** no mobile — o texto crítico (telefone/e-mail/handle/frase)
> precisa permanecer legível nos dois contextos.

---

## Pré-requisitos

1. `hub.json` válido em `~/career/<candidate-name>/hub.json` — validar com
   `python3 $SCRIPTS_DIR/cv/validate.py` (exit 0 obrigatório). Sem hub → rodar
   `/ocf:cv-hub` antes e parar.
2. **`EACHLABS_API_KEY`** definida no ambiente/secret local (nunca em arquivo
   versionado). Verificação: `scripts/cv/banner-gen.sh --check`.
   Sem a key → **falha com mensagem clara** (exit != 0) e nenhum arquivo
   parcial; não bloqueia os demais comandos de carreira.
3. Skill vendor carregada antes de gerar: `poster-design-generation`
   (each::sense AI — endpoint
   `https://eachsense-agent.core.eachlabs.run/v1/chat/completions`,
   header `X-API-Key: $EACHLABS_API_KEY`,
   `Accept: text/event-stream`, modelo `eachsense/beta`, `mode: "max"`).
   O helper `scripts/cv/banner-gen.sh` encapsula esse contrato.
4. Google Chrome/Chromium disponível para o fallback determinístico de texto
   nítido e para os previews de corte (mesmo mecanismo do `scripts/cv/pdf.sh`).

---

## Regra de conteúdo (BR 1 — nunca inventar)

Todo o conteúdo textual do banner vem de **`hub.json`**:

| Elemento | Fonte no hub | Regra |
| --- | --- | --- |
| Telefone | `personal_info.phone` | incluir só se presente; ausência → omitir |
| E-mail | `personal_info.email` | incluir só se presente; ausência → omitir |
| Redes sociais | `personal_info.linkedin`, `personal_info.github`, `personal_info.site` e `links[]` (name/url) | incluir **somente as que o usuário escolher** e que existirem no hub; ausência → omitir; NUNCA adivinhar handle |
| Frase de impacto | `summary`/`summary_i18n` (no idioma do usuário) + `profile_objective` (type/target_role) | destilar ~30 palavras em **frase curta legível (≤ ~12 palavras)** reescrevendo o que existe — nunca acrescentar conquista/número que não esteja no hub |

Regras duras:
- **NUNCA inventar** telefone, e-mail, rede, handle, URL, cidade ou conquista.
  Se um contato não está no hub, ele não aparece no banner.
- O usuário escolhe quais contatos exibir (default: telefone + e-mail + as
  redes mais relevantes para o objetivo do perfil, até ~3 itens — mais que
  isso fica ilegível no canvas).
- Sem `summary` → a frase é omitida ou reduzida ao `profile_objective`.
  `target_role` (literal) é uma fonte legítima para a frase quando presente.
- Sem dados sensíveis: nada de CPF, endereço completo, dados bancários.

Tonalidade da frase pelo objetivo (`hub.profile_objective.type` — orientação
só, o texto continua 100% derivado do hub):

| type | tom da frase |
| --- | --- |
| `job_search` | cargo-alvo literal + senioridade + disponibilidade (ex.: "Tech Lead PHP | disponível para novos desafios remotos") |
| `services_sales` | serviço ofertado + diferencial (ex.: "Consultoria em dados — pipelines e dashboards que aceleram decisões") |
| `connections` | identidade profissional que convida à conversa |
| `personal_branding` | posicionamento de nicho/pessoal |

---

## Geometria, zonas seguras e legibilidade (BR 2)

Canvas único: **1584×396 px (proporção 4:1)** — resolução mínima oficial do
LinkedIn. Nenhum texto crítico fora do canvas; nada de letterboxing.

```
┌──────────────────────────────────────────────────────────────────────┐
│  x: 0                                                     x: 1584     │
│  fundo visual (direção art-director) — sem detalhe fino importante  │  y: 0
│                                                                      │
│        ┌───────────────────────────────────────────────┐             │
│        │  ZONA DE TEXTO CRÍTICO (faixa central)        │             │
│        │  frase de impacto (maior)                     │  texto      │
│        │  linha de contato (chips: tel/e-mail/redes)   │  legível    │
│        │  x ≈ 560–1560 · y ≈ 120–336                   │  mobile     │
│        └───────────────────────────────────────────────┘             │
│                                                ┌──────────────────────┤
│  ZONA DE GUARDA DA FOTO (desktop):             │  (nada crítico aqui) │
│  x 0–500 × y (396−260)–396                     │                      │
│  texto/detalhe NUNCA entram nesta região       │                      │
└────────────────────────────────────────────────┴──────────────────────┘
  y: 396
```

Zonas (valores padrão documentados; podem ser ajustados no spec JSON quando o
usuário tiver uma referência visual diferente):

1. **Zona de guarda da foto de perfil (desktop)** — a foto fica sobreposta no
   canto inferior esquerdo. Manter a região de **~500px esquerdos × ~260px
   inferiores** (x 0–500, y 136–396) **livre de texto crítico e de detalhe
   fino**. O fundo nessa área deve ser calmo (gradiente/abstrato limpo).
2. **Crop central do mobile** — no mobile o LinkedIn reduz o banner para a
   largura (≈640×160) e a leitura depende da faixa central. Por isso todo o
   texto crítico fica na **faixa central (middle ~75% da altura) e à direita
   do centro** (x ≈ 560–1560, y ≈ 120–336 no canvas 1584): sobra da guarda da
   foto, dentro do recorte móvel e longe das bordas que o crop pode cortar.
3. **Legibilidade de texto** — no canvas 1584: frase ≥ **48px** (bold),
   contatos ≥ **32px**, contraste alto contra o fundo (texto claro em fundo
   escuro ou vice-versa, com painel/soft shadow atrás quando o fundo for
   movimentado). Se o texto não passar nesses mínimos → fallback
   determinístico (seção Gate de texto).

---

## Direção visual (art-director)

1. Montar o **brief** para o banner: candidato (nome, área, senioridade,
   objetivo do perfil), conteúdo que será exibido (frase + contatos) e as
   restrições duras de geometria (4:1, guarda da foto 500×260, faixa central).
2. Invocar o agente `design/art-director` via `task:` com esse brief
   (subagent_type `design/art-director`). Ele devolve o `design_spec.json`
   com **conceito, paleta (hex exatos), tipografia, composição, direções
   consideradas e elemento-assinatura**. Para o banner, aproveitar os campos
   visuais; os campos de UI (component_vocabulary, motion etc.) não se
   aplicam — ignorá-los.
3. **Direção opcional do usuário** (`/ocf:cv-banner <candidate-dir>
   [direção]`): quando o usuário dá uma direção (ex.: "cores escuras com azul
   elétrico, vibe tech"), passá-la no brief como restrição e registrar a
   escolha no spec — a direção do art-director nunca contradiz uma restrição
   explícita do usuário.
4. Registrar as escolhas em `banner-spec.json` **e** `banner-spec.md`
   (legível pelo usuário, no idioma dele): conceito, paleta, composição,
   tipografia, zonas de segurança, texto a renderizar e a justificativa
   (por que essa direção serve a *este* perfil).

### Schema do `banner-spec.json`

```json
{
  "version": "banner-spec-v1",
  "canvas": {"width": 1584, "height": 396},
  "safe_zones": {
    "profile_photo": {"left_px": 500, "bottom_px": 260},
    "mobile_crop": {"width": 640, "height": 160}
  },
  "direction": {
    "concept": "…",
    "palette": {"background": "#0F172A", "surface": "#1E293B", "text_primary": "#F8FAFC", "accent_primary": "#38BDF8"},
    "style": "…",
    "composition": "…",
    "typography_hint": "…",
    "signature_element": "…"
  },
  "generation": {"model": "eachsense/beta", "mode": "max"},
  "session_id": "… opcional (iteração multi-turno) …",
  "prompt": "… opcional: override COMPLETO do prompt visual (quando presente, substitui a síntese de direction)"
}
```

Campos obrigatórios: `canvas.width`/`canvas.height` (> 0) e
`direction.concept` (ou `prompt`). O helper completa o resto com defaults
(safe_zones 500×260, mobile 640×160, mode max) e **sempre anexa o bloco de
texto exato** vindo do `content.json`.

---

## Geração (BR 3 — each::sense)

**Carregar a skill vendor `poster-design-generation` antes de gerar.** A
geração usa o mesmo provedor por um dos dois caminhos (o helper é o caminho
recomendado por ser determinístico e sem vazamento de key):

### Caminho A — helper `scripts/cv/banner-gen.sh` (recomendado)

```
scripts/cv/banner-gen.sh --check
scripts/cv/banner-gen.sh --spec <banner-spec.json> --content <content.json> --out <dir>
```

O `content.json` carrega o **texto exato** (montado pelo agente a partir do
hub + escolha do usuário):

```json
{
  "phrase": "Engenheiro de dados | transformo dados em decisões",
  "items": [
    {"kind": "phone",  "label": "Telefone", "value": "+55 (11) 98765-4321"},
    {"kind": "email",  "value": "candidato@example.com"},
    {"kind": "social", "network": "linkedin", "handle": "/in/candidato", "value": "/in/candidato"}
  ]
}
```

O helper: valida a key → valida os JSONs → monta o request (body salvo em
`<dir>/banner.request.json` — **sem a key**) → chama o endpoint via curl com
`X-API-Key` e `Accept: text/event-stream` → grava o stream SSE em
`<dir>/banner.sse.log` → extrai a URL da imagem dos eventos
`generation_response`/`complete` → baixa para `<dir>/banner.png` (só publica
depois de validar o magic byte PNG/JPEG). Falhas: exit 1 com mensagem clara e
**nenhum banner.png parcial**; key ausente → exit 1 **sem criar diretório**;
uso inválido → exit 2. A key **nunca** é impressa nem gravada.

### Caminho B — skill vendor direta

Seguir `poster-design-generation/SKILL.md` + `references/SSE-EVENTS.md`:
POST no endpoint com o mesmo body (`messages`, `model: "eachsense/beta"`,
`stream: true`, `mode: "max"`); salvar a imagem do evento
`generation_response` (`url`/`generations[]`). Usar quando o agente precisar
de iteração visual multi-turno (`session_id`).

### Sem `EACHLABS_API_KEY`

Falha limpa e não destrutiva: mensagem clara (ex.: o `--check` responde que a
key não está definida e o exit é != 0), **nenhum arquivo criado** e **nenhum
outro fluxo de carreira bloqueado**. Documentar no relatório que a geração
real exige a key do usuário em runtime.

---

## Gate de texto + retries + overlay determinístico (BR 4)

Texto gerado por IA erra (troca dígitos, inventa handle, borra). O entregável
final **DEVE** ter telefone/e-mail/handle/frase corretos e legíveis:

1. **Verificar** o texto na imagem gerada: gerar/atualizar os previews de
   corte (desktop e mobile) e conferir — comparando **exatamente** cada
   caractere com o `content.json`. Conferência manual assistida; se houver
   OCR disponível, usar como apoio, nunca como única fonte.
2. **Até 2 retries** com prompt refinado quando houver erro de texto:
   - Caminho A: repetir o helper com o mesmo spec (o prompt refinado entra em
     `spec.prompt` — override completo do prompt, incluindo instrução
     "reproduza EXATAMENTE os caracteres: …", isolar o texto do fundo,
     aumentar contraste, reduzir o número de itens se necessário). O conteúdo
     do `content.json` permanece idêntico — o texto não muda, só a instrução.
   - Caminho B: mesmo `session_id` para iteração na mesma composição.
3. **Se ainda incorreto → overlay determinístico de texto nítido** (garante
   texto correto e legível em desktop e mobile): compor o texto definitivo
   sobre o visual gerado com HTML/CSS e renderizar com Chrome headless no
   tamanho exato 1584×396. O overlay é determinístico (mesma entrada → mesma
   saída), então o gate passa sempre. Roteiro:
   1. Normalizar o visual gerado para 1584×396 (se o modelo devolver outra
      proporção, usar um HTML com a imagem em `object-fit: cover` num
      viewport 1584×396 e capturar a tela).
   2. Criar `overlay.html`: a imagem gerada como fundo (`position: absolute;
      inset: 0; width: 1584px; height: 396px`) e o bloco de texto crítico
      posicionado **dentro da zona de texto** (x ≈ 560–1560, y ≈ 120–336),
      com as strings **exatas** do `content.json` (frase grande; chips de
      contato com fonte do sistema, peso alto, contraste garantido e painel
      semitransparente quando o fundo for movimentado).
   3. Capturar:
      ```
      chrome --headless=new --disable-gpu --no-sandbox \
        --force-device-scale-factor=1 \
        --window-size=1584,396 \
        --screenshot="$OUT/banner.png" "file://$OUT/overlay.html"
      ```
   4. Conferir dimensões (1584×396) e legibilidade nos previews.

O resultado final (IA aceita no gate **ou** overlay determinístico) é o
`banner.png` que vai para o relatório — sempre com o texto correto.

---

## Previews de conferência (desktop e mobile)

Além do `banner.png` final, gerar dois previews para o usuário conferir antes
do upload (mesmo mecanismo Chrome do fallback):

- **`preview-desktop.png`** — o banner em 1584×396 (cópia do final ou render
  do `overlay.html`), para inspecionar a zona de guarda: o texto crítico
  **não** invade a região inferior-esquerda (x 0–500 × y 136–396).
- **`preview-mobile.png`** — recorte central 640×160 (CSS `object-fit: cover`
  com âncora central num viewport 640×160 sobre o `banner.png`), simulando o
  crop móvel do LinkedIn: o texto crítico precisa continuar visível/legível
  na faixa central.

Registrar no relatório a conferência dos dois cortes (item de `Tests:` da
issue — verificação manual assistida, documentada no report).

---

## Saídas (BR 5)

Tudo em **`~/career/<candidate-name>/linkedin/banner/`**:

```
linkedin/banner/
├── banner.png              # imagem final 4:1 1584×396 (texto correto/legível)
├── banner-spec.json        # direção visual (machine-readable)
├── banner-spec.md          # direção visual legível + decisões (idioma do usuário)
├── content.json            # texto exato exibido (frase + itens) — auditável vs hub
├── banner.request.json     # request enviado ao each::sense (sem key) — Caminho A
├── banner.sse.log          # stream SSE bruto — Caminho A (debug)
├── overlay.html            # fallback/overlay determinístico (quando usado)
├── preview-desktop.png     # conferência desktop (guarda da foto)
└── preview-mobile.png      # conferência mobile (crop central)
```

**Nada é publicado** — o usuário faz o upload manual (upload do arquivo no
LinkedIn; proporção 4:1, recorte da foto OK por causa da guarda).

---

## Segurança (BR 7)

- `EACHLABS_API_KEY` apenas em env/secret local. **Nunca** em arquivo
  versionado, nunca em logs, nunca no corpo do request salvo, nunca no
  relatório. `banner-gen.sh` nunca imprime a key (verificado por teste).
- Nenhum dado sensível além dos contatos do hub que o usuário escolheu
  exibir (CPF, endereço completo, banco → proibidos).
- Edições de arquivo permitidas apenas em `~/career/**` (e nos diretórios de
  saída do candidato). Não alterar `hub.json`.

---

## Fluxo resumido

1. Validar `hub.json` (`validate.py` exit 0).
2. Ler `profile_objective` + `summary` e definir a frase curta + contatos
   (com o usuário, quando ele quiser escolher).
3. Obter a direção visual do `design/art-director` (brief com geometria +
   conteúdo) — respeitando direção explícita do usuário quando houver.
4. Escrever `banner-spec.json`/`banner-spec.md` e `content.json`.
5. **Carregar a skill `poster-design-generation`** e gerar (Caminho A —
   `banner-gen.sh` — ou B — skill direta). Sem key → falha clara e para.
6. Gate de texto + previews; até 2 retries; se preciso, overlay
   determinístico (Chrome) para garantir o texto correto.
7. Salvar tudo em `~/career/<candidate-name>/linkedin/banner/` e conferir os
   previews desktop/mobile.
8. Relatar: caminho dos arquivos, direção usada, contatos exibidos, resultado
   do gate (IA aceita / retries / overlay) e observações de verificação —
   lembrar que a geração real exige o `EACHLABS_API_KEY` do usuário em
   runtime. Nada publicado; upload manual.
