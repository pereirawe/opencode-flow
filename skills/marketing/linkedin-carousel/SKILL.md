---
name: linkedin-carousel
description: Generate a LinkedIn carousel deck (1:1, 1080×1080) as PDF from a researched topic — agent-driven phases (preflight assets/schema → web research with saved sources → editorial roteiro → per-slide canonical spec → image-model background art [optional] + deterministic Chrome typography/logo overlay → deck.pdf). Runs INSIDE the target project (docs/assets/person.json + logo); identity never invented; prompts-only fallback without EACHLABS_API_KEY; nothing is published (manual upload). Use when the user asks to create a LinkedIn carousel, generate a slide deck PDF from a topic, or "carrossel LinkedIn", "deck linkedin", "carrossel para o linkedin" also trigger this skill. Marketing sector.
---

# LinkedIn Carousel — deck 1080×1080 → PDF (pesquisa + spec + arte + composição determinística)

Gera um **carrossel LinkedIn → PDF** a partir de um **tema**: pesquisa na web,
roteiro editorial, spec canônica por slide (`deck.json`) e — quando o modelo de
imagem está disponível — artes de fundo via each::sense com **tipografia/logo
compostos deterministicamente** via Chrome headless (o texto nunca sai da IA
de imagem). Sem modelo → **fallback prompts-only** (deck.json + prompts/textos +
instruções, sem PNG/PDF).

> Roda **dentro do projeto alvo** (nunca no repo deste config). O projeto
> fornece em `docs/assets/` o `person.json` (identidade do publicador) e o logo.
> **Nada é publicado** — o upload do carrossel no LinkedIn é manual.

---

## Pré-requisitos

1. **Projeto alvo** com `docs/` e `docs/assets/person.json` (schema
   `person.schema.json` junto desta skill). Sem `person.json` válido → falha
   de preflight antes de pesquisar/gerar (exit ≠ 0, zero artefatos).
2. **Logo** (opcional): `docs/assets/<logo_path>` válido (magic-byte
   PNG/JPEG/WebP/GIF/SVG). Ausência → logo omitido (nunca inventado).
3. **`EACHLABS_API_KEY`** (opcional, env/secret local — nunca commitada):
   presente → modo imagem (artes each::sense); ausente → fallback prompts-only
   (exit 0, sem PNG/PDF). Verificação: `scripts/marketing/carousel-gen.sh --check`.
4. **Google Chrome/Chromium** + **python3 com Pillow** (composição
   determinística + validação 1080×1080). Verificar com `--check`.

---

## Fluxo em fases (ordem obrigatória)

### Fase 0 — Preflight de assets/schema (ANTES de pesquisar)

Executar **antes de gastar tokens em pesquisa** (token saver + BR 1):

1. `docs/` existe no projeto alvo.
2. `docs/assets/person.json` existe e valida:
   `python3 $SCRIPTS_DIR/marketing/person-validate.py docs/assets/person.json`
   (exit 0 obrigatório).
3. Logo presente é imagem válida (magic-byte).
4. Falha → parar com erro claro, **nenhum artefato criado**.

### Fase 1 — Research web (fontes salvas, nada fabricado)

1. Pesquisar o tema com a ferramenta de web/webfetch do agente (nunca
   `curl`/fetch de URL arbitrária do usuário nos scripts — BR 11).
2. Para cada fonte usada, salvar em **`docs/carousel/<slug>/research/`**:
   `research/<NN>-<slug>.md` contendo **URL + data de acesso + notas** e o
   que dela foi aproveitado.
3. **Cada afirmação factual de cada slide mapeia a ≥1 fonte** (URL+data).
   Lacuna/dúvida → `open_questions` explícita no `deck.json`, **nunca** texto
   afirmativo. Paráfrase — sem cópia literal longa de fontes.

### Fase 2 — Roteiro editorial (N slides)

1. Derivar **N** da profundidade da pesquisa: **1 capa + (N−2) conteúdo + 1
   CTA**, com **3 ≤ N ≤ 20**, default **7** (BR 4).
2. Revisar o roteiro **com o usuário** antes de escrever a spec (ajuste de N
   acontece aqui — não há flag CLI na v1).
3. Ajustar a **direção** opcional do usuário (`/ocf:linkedin-carousel <tema>
   [<direção>]`) como restrição visual (paleta/tom), nunca contradizendo o
   padrão canônico (BR 5).

### Fase 3 — Spec por slide (deck.json — artefato fonte)

Escrever **`docs/carousel/<slug>/deck.json`** — **SEMPRE gerado em toda
execução, antes de qualquer render** (BR 3). Cada slide tem **2 blocos**:

- **`design_prompt`** — prompt de design em **ENGLISH** (arte/fundo **sem
  texto/letras/logo**; canvas quadrado 1080×1080; paleta e composição);
- **`text`** — texto do slide **no idioma do usuário**, estruturado por tipo:

| Tipo | Chaves canônicas do bloco `text` |
| --- | --- |
| `cover` (1) | `TITULO` (obrigatório), `SUBTITULO`, `RODAPE` |
| `content` (N−2) | `TAG`, `HEADLINE` (obrigatório), `BULLETS` (array ≥1), `DETALHE` |
| `cta` (último) | `HEADLINE` (obrigatório), `SUBHEADLINE`, `CTA` (obrigatório), `RODAPE` |

Schema canônico:

```json
{
  "schema": "linkedin-carousel-deck-v1",
  "slug": "nome-do-slug",
  "topic": "Tema pesquisado",
  "locale": "pt",
  "n_slides": 7,
  "created": "2026-09-09T13:27:00Z",
  "open_questions": ["…"],
  "slides": [
    {
      "index": 1,
      "type": "cover",
      "design_prompt": "Design a bold editorial background… NO text, NO letters, square 1080x1080…",
      "text": {"TITULO": "…", "SUBTITULO": "…", "RODAPE": "Nome · in/handle"},
      "sources": []
    },
    {
      "index": 2,
      "type": "content",
      "design_prompt": "…",
      "text": {"TAG": "…", "HEADLINE": "…", "BULLETS": ["…", "…"], "DETALHE": "…"},
      "sources": [{"url": "https://…", "accessed": "2026-09-09", "note": "…"}]
    },
    {
      "index": 7,
      "type": "cta",
      "design_prompt": "…",
      "text": {"HEADLINE": "…", "SUBHEADLINE": "…", "CTA": "…", "RODAPE": "Nome · in/handle"},
      "sources": []
    }
  ]
}
```

Regras da spec (BR 3/4/10):
- `locale` = idioma do usuário resolvido (conversa → `.opencode/locale` do
  projeto alvo → locale global). Prompts de design SEMPRE em EN (BR 2).
- Identidade (nome/handle/headline/CTA) **exclusivamente do `person.json`
  validado** — campo ausente → omitido e sinalizado, nunca preenchido.
- Slide de conteúdo **exige `sources` ≥ 1** (URL + data `YYYY-MM-DD`).
- Ajuste de N/roteiro ocorre na Fase 2; o script valida a estrutura mecanicamente.

### Fase 4 — Composição (scripts determinísticos)

```bash
scripts/marketing/carousel-gen.sh --check
scripts/marketing/carousel-gen.sh --project <projeto-alvo> --slug <slug>
```

O orquestrador faz, nesta ordem (tudo atômico, contrato exit 0/1/2):

1. **Preflight mecânico** (BR 1): docs/, person.json (via `person-validate.py`),
   logo, `deck.json` estrutural (schema, N, ordem capa/CTA, blocos por tipo,
   prompts EN, `sources`).
2. **Modo imagem** (`EACHLABS_API_KEY` válida): por slide, gera a **arte de
   fundo** via each::sense (mesmo contrato do `scripts/cv/banner-gen.sh` —
   key só no header HTTP; request/SSE logados **sem a key**), valida
   **magic-byte + dimensão 1080×1080**, **retry ≤ 2**; depois compõe o slide
   com `slide-compose.sh` (HTML/CSS determinístico → Chrome screenshot
   1080×1080; texto exato HTML-escaped + **logo overlay canto inferior
   direito** quando presente). `deck.pdf` só com **TODAS** as N imagens
   válidas (`carousel-pdf.sh` — engine compartilhada #226).
3. **Fallback prompts-only** (BR 7): `deck.json` + `prompts-textos.md` +
   `instrucoes.md`; **nunca** chama API, **nunca** cria PNG/PDF; exit 0 com
   aviso claro.

### Fase 5 — Entrega (BR 12)

Tudo em **`docs/carousel/<slug>/`** do projeto alvo:

```
docs/carousel/<slug>/
├── research/               # fontes: URL + data de acesso + notas
├── deck.json               # artefato fonte (prompt EN + texto por tipo)
├── prompts-textos.md       # derivado: prompts de design + textos por slide
├── instrucoes.md           # derivado, no idioma do usuário
├── slide-01.png … slide-0N.png   # 1080×1080 (modo imagem)
├── slide-0N.html           # fonte HTML/CSS do slide (debug/re-edição)
├── art-0N.request.json     # request each::sense (SEM a key)
├── art-0N.sse.log          # stream SSE bruto (SEM a key)
└── deck.pdf                # N páginas quadradas (modo imagem)
```

**Nada é publicado/uploadado automaticamente** — o usuário posta as imagens
`slide-*.png` em ordem (capa → conteúdo → CTA) no LinkedIn.

---

## Padrão visual canônico (BR 5 — fixo, não negociável)

| Token | Valor |
| --- | --- |
| Canvas | 1080×1080 px (1:1) |
| Paleta | preto `#000000` · branco `#FFFFFF` · vermelho `#E63946` · azul elétrico `#0077B6` |
| Fontes | Inter ou Space Grotesk (Bold títulos, Regular corpo; fallback system-ui) |
| Estilo | editorial typographic-first, alto contraste, scrim sobre a arte p/ legibilidade |
| Validação | pós-render: magic-byte + dimensão **exata** 1080×1080 |

A camada tipográfica (texto exato + logo) é **SEMPRE** HTML/CSS determinístico
via Chrome headless — o modelo de imagem contribui **apenas** com a arte/fundo
(prompt sem texto/letras), eliminando texto inventado/borrado de IA (BR 6).

---

## Segurança (BR 11)

- `EACHLABS_API_KEY` apenas em env/secret local — **nunca** commitada,
  impressa, logada ou presente em request/relatório/artefatos (só no header
  HTTP). `carousel-gen.sh --check` nunca imprime a key.
- Scripts nunca fazem fetch de URL arbitrária do usuário — a pesquisa roda via
  webfetch do agente; os scripts só baixam a URL de imagem devolvida pela API.
- Nenhum dado sensível além da identidade do `person.json` escolhida pelo
  usuário.

---

## Regras de conteúdo (BR 10 — nunca inventar)

> **NUNCA inventar** identidade ou conteúdo factual — nem nome/headline/handle/CTA,
> nem afirmações, números ou fontes. Tudo é derivado do `person.json` validado e
> das fontes salvas em `research/`.

- **Identidade**: nome/headline/handle/CTA vêm exclusivamente do `person.json`
  validado; ausência → omitir e sinalizar.
- **Fatos**: 100% rastreáveis às fontes em `research/` (URL + data); cada
  afirmação mapeada a ≥1 fonte; lacuna → `open_questions`, nunca texto
  afirmativo; paráfrase (sem cópia literal longa).
- **Handle** (`in/…`) apenas quando presente no person.json e válido
  (`^in/[A-Za-z0-9._-]+$`).

---

## Open question registrada (v2, não bloqueia)

O Tech Lead propôs que, sem modelo de imagem, o deck pudesse renderizar PDF
com fundos 100% CSS determinísticos; a **v1 mantém o contrato do usuário**
(fallback prompts-only sem PNG/PDF) — variante para revisão de PO/usuário.
