## /ocf:linkedin-carousel <tema> [<direção>]

---
description: Generate a LinkedIn carousel deck (1080×1080 slides → deck.pdf) from a researched topic, running INSIDE the target project: preflight docs/assets/person.json + logo (validated schema), web research with saved sources (research/), editorial roteiro (1 cover + N−2 content + 1 CTA, 3≤N≤20 default 7), canonical per-slide spec (deck.json: EN design prompt + user-language structured text), each::sense background art when EACHLABS_API_KEY is set with deterministic Chrome typography/logo overlay, prompts-only fallback otherwise (no PNG/PDF); outputs under docs/carousel/<slug>/; identity never invented; nothing is published (manual upload)
---

Gera um **carrossel LinkedIn → PDF** a partir de um **tema**: o agente pesquisa
na web, monta o roteiro editorial, escreve a **spec canônica** (`deck.json` —
prompt de design em EN + texto estruturado no idioma do usuário) e compõe o
deck **1080×1080** com paleta preto/branco/`#E63946`/`#0077B6` (Inter ou Space
Grotesk). Com **`EACHLABS_API_KEY`** → artes de fundo each::sense +
**tipografia/logo deterministicamente** via Chrome headless → `deck.pdf`; sem a
key → **fallback prompts-only** (deck.json + prompts/textos + instruções, sem
PNG/PDF, exit 0). **Roda dentro do projeto alvo** — nunca no repo deste config.
**Nada é publicado** — o upload no LinkedIn é manual.

### Prerequisite

Projeto alvo com:

- `docs/` e **`docs/assets/person.json`** válido (schema `person.schema.json`:
  `schema` e `name` obrigatórios; `headline`, `handle` `^in/…$`, `cta_text`,
  `logo_path` opcionais). Validar:
  `python3 $SCRIPTS_DIR/marketing/person-validate.py docs/assets/person.json`
- Logo (opcional) em `docs/assets/` — imagem válida (magic-byte).
- Modo imagem exige **`EACHLABS_API_KEY`** (env/secret local, nunca commitada);
  sem ela o fluxo conclui em prompts-only. Verificar:
  `scripts/marketing/carousel-gen.sh --check`.
- Chrome/Chromium + python3 com Pillow.

### Usage

```
/ocf:linkedin-carousel "Arquitetura limpa em 7 pontos"
/ocf:linkedin-carousel "Data engineering na prática" "cores escuras, vibe tech"
```

A `<direção>` é opcional: preferência visual do usuário respeitada pelo roteiro
(nunca contradiz o padrão canônico).

### Flow

1. **Load skill** — `linkedin-carousel` (fases + schema + template canônico).
2. **Preflight (antes de pesquisar)** — `docs/` existe; `person.json` valida
   (exit 0); logo válido se presente. Falha → parar com erro claro, zero
   artefatos.
3. **Research** — webfetch do tema; salvar fontes em
   `docs/carousel/<slug>/research/<NN>-<slug>.md` (URL + data + notas); cada
   afirmação factual mapeada a ≥1 fonte; lacunas → `open_questions`.
4. **Roteiro** — N slides (1 capa + N−2 conteúdo + 1 CTA, 3≤N≤20, default 7);
   revisar com o usuário; aplicar a direção opcional.
5. **Spec** — escrever `docs/carousel/<slug>/deck.json` (sempre gerado, antes
   de qualquer render): por slide, `design_prompt` EN (arte sem texto/letras) +
   `text` no idioma do usuário (capa `TITULO/SUBTITULO/RODAPE`; conteúdo
   `TAG/HEADLINE/BULLETS/DETALHE`; cta `HEADLINE/SUBHEADLINE/CTA/RODAPE`).
   Identidade exclusivamente do `person.json` validado.
6. **Compose** — `bash $SCRIPTS_DIR/marketing/carousel-gen.sh --project <cwd>
   --slug <slug>`: preflight mecânico → modo imagem (each::sense + retry ≤2 +
   validação 1080×1080 + composição determinística + deck.pdf só com todas as
   imagens válidas) **ou** prompts-only (exit 0, sem PNG/PDF).
7. **Report** — caminhos, modo, estrutura N, fontes, open questions; lembrete
   de upload manual.

### Output

```
docs/carousel/<slug>/
├── research/               # fontes (URL + data + notas)
├── deck.json               # artefato fonte (prompt EN + texto por tipo)
├── prompts-textos.md       # prompts de design + textos por slide
├── instrucoes.md           # no idioma do usuário
├── slide-01.png … slide-0N.png   # 1080×1080 (modo imagem)
├── slide-0N.html           # fonte HTML/CSS do slide
├── art-0N.request.json     # request each::sense (sem a key)
├── art-0N.sse.log          # stream SSE bruto (sem a key)
└── deck.pdf                # N páginas quadradas (modo imagem)
```

### Rules

- **NUNCA inventar** identidade (person.json) nem conteúdo factual (fontes em
  `research/`); handle `in/…` apenas quando presente e válido.
- Texto/layout **sempre determinísticos** (HTML/CSS → Chrome 1080×1080); a IA
  de imagem contribui só com a arte/fundo (prompt sem texto/letras).
- `deck.json` **sempre gerado**, inclusive no prompts-only (que não cria
  PNG/PDF e não chama API).
- Sem `EACHLABS_API_KEY` → prompts-only é conclusão válida (exit 0), com aviso
  claro — não é erro.
- Key apenas em env/secret — nunca commitada/impressa/em artefatos.
- Edições apenas em `docs/` do projeto alvo; `hub.json`/demais arquivos do
  projeto não são alterados.
- **Nada é publicado** — upload manual no LinkedIn (slide-01.png … slide-0N.png
  em ordem).

### Report to the user

- Output path (`docs/carousel/<slug>/`).
- Modo usado (imagem / prompts-only) e a estrutura do deck (N: capa + conteúdo
  + CTA).
- Fontes salvas em `research/` (URL + data) e open questions registradas.
- Lembrete: upload manual e, no prompts-only, como gerar as artes externamente
  com os prompts (ou re-executar com a key).
