## /ocf:cv-banner <candidate-directory> [<direção>]

---
description: Generate the LinkedIn profile banner of the candidate (4:1, 1584×396) with an image model (each::sense via the vendored poster-design-generation skill or scripts/cv/banner-gen.sh — EACHLABS_API_KEY required) from the REAL hub.json content (phone/email/socials/short impact phrase) and an art-director visual direction that RESPECTS the profile-photo safe zone (bottom-left ≈ left 500px × bottom 260px) and mobile center-crop legibility; outputs land in ~/career/<candidate>/linkedin/banner/ (final PNG + spec md/json + desktop/mobile previews) with a text gate (up to 2 retries) and a deterministic crisp-text overlay fallback; nothing is published — the user uploads manually
---

Gera o **banner do perfil LinkedIn** do candidato a partir do `hub.json`
(construído com `/ocf:cv-hub`): imagem 4:1 (**1584×396**) com **telefone,
e-mail, redes sociais** presentes no hub e uma **frase de impacto curta**
destilada do perfil (~30 palavras do summary → frase legível), dispostos como
um footer na faixa central/direita — **fora da zona da foto de perfil**
(canto inferior esquerdo, sobreposta ao banner no desktop) e legíveis no
crop central do mobile. A direção visual vem do agente
`design/art-director`; a geração usa o modelo de imagem each::sense (skill
vendor `poster-design-generation` ou o helper `scripts/cv/banner-gen.sh`).
O texto de IA passa por um **gate de corretude/legibilidade** com até 2
retries e um **fallback determinístico de overlay de texto nítido** que
garante telefone/e-mail/handle corretos no entregável final. **Nada é
publicado** — o usuário faz o upload manual no LinkedIn.

### Prerequisite

Candidato com `hub.json` válido em `~/career/<candidate-name>/hub.json`. Se
não existir, rodar `/ocf:cv-hub` primeiro.

A geração real exige a **`EACHLABS_API_KEY`** (env/secret local, nunca
commitada). Sem a key o fluxo falha com mensagem clara e não produz arquivos
— os demais comandos de carreira não são afetados. Verificar antes com:
`scripts/cv/banner-gen.sh --check`.

### Usage

```
/ocf:cv-banner ~/career/maria-silva
/ocf:cv-banner ~/career/maria-silva "cores escuras com azul elétrico, vibe tech"
```

A `<direção>` é opcional: uma preferência visual do usuário que o
art-director deve respeitar. Sem direção, o art-director decide a partir do
perfil.

### Flow

1. **Validate hub** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json` (exit 0
   obrigatório); hub ausente/inválido → pedir `/ocf:cv-hub` primeiro.
2. **Conteúdo** — ler `hub.profile_objective` (type/target_role), `summary`
   e os contatos (`personal_info.phone/email`, `personal_info.linkedin/
   github/site`, `links[]`). Definir com o usuário quais contatos exibir
   (default: telefone + e-mail + até ~3 redes relevantes). Destilar a **frase
   curta** (~30 palavras → ≤ ~12, reescrevendo apenas o que existe no hub —
   nunca inventar contato/rede/frase).
3. **Direção visual** — carregar a skill `cv-linkedin-banner`; invocar o
   agente `design/art-director` via `task:` com o brief (perfil + conteúdo +
   geometria: 4:1 1584×396, guarda da foto left 500px × bottom 260px, faixa
   central legível no mobile) + a direção do usuário (quando houver). Mapear
   o `design_spec` para `banner-spec.json` + `banner-spec.md`.
4. **Generate** — montar `content.json` (frase + itens exatos). **Carregar a
   skill vendor `poster-design-generation`** e gerar via
   `scripts/cv/banner-gen.sh --spec <banner-spec.json> --content
   <content.json> --out <dir>` (recomendado; request/stream logados sem a
   key) ou seguindo a skill vendor diretamente (iteração com `session_id`).
5. **Verify text (gate)** — comparar caractere a caractere o texto renderizado
   com o `content.json` nos previews desktop/mobile; até **2 retries** com
   prompt refinado (mesmo conteúdo); se ainda incorreto, **overlay
   determinístico** de texto nítido via Chrome headless (render HTML/CSS em
   1584×396 posicionando as strings exatas na zona de texto) — garante o
   texto correto e legível em desktop e mobile.
6. **Write outputs** — salvar em
   `~/career/<candidate-name>/linkedin/banner/`: `banner.png`,
   `banner-spec.json`, `banner-spec.md`, `content.json`,
   `banner.request.json` + `banner.sse.log` (Caminho helper), `overlay.html`
   (quando usado), `preview-desktop.png` e `preview-mobile.png` (crop
   central 640×160).
7. **Report** — caminho dos arquivos, direção usada, contatos exibidos,
   resultado do gate (IA aceita / retries / overlay) e a conferência manual
   dos previews (zona de guarda no desktop + faixa central no mobile).
   Documentar que a geração real exige o `EACHLABS_API_KEY` em runtime.

### Output

```
~/career/<candidate-name>/linkedin/banner/
├── banner.png            # final 4:1 1584×396, texto correto e legível
├── banner-spec.json      # direção visual (machine-readable)
├── banner-spec.md        # direção visual legível + decisões
├── content.json          # texto exato exibido (frase + itens)
├── banner.request.json   # request each::sense (sem a key)
├── banner.sse.log        # stream SSE bruto
├── overlay.html          # fallback determinístico (quando usado)
├── preview-desktop.png   # conferência: guarda da foto respeitada
└── preview-mobile.png    # conferência: crop central mantém o texto
```

### Rules

- **NUNCA inventar** telefone, e-mail, rede, handle, URL ou frase — tudo vem
  do hub; ausências são omitidas, nunca preenchidas.
- **Zona segura da foto**: texto crítico fora da região inferior-esquerda
  (≈ left 500px × bottom 260px no desktop) e dentro da faixa central
  (legível no crop mobile).
- Sem `EACHLABS_API_KEY` → falha clara (exit != 0) e nenhum arquivo parcial;
  não interrompe os demais comandos.
- Gate de texto: até 2 retries; se ainda incorreto, overlay determinístico —
  o entregável final SEMPRE tem o texto correto e legível.
- Key apenas em env/secret local — nunca commitada, nunca em logs/request/
  relatório; sem dados sensíveis além dos contatos escolhidos pelo usuário.
- Edições apenas em `~/career/**` — `hub.json` nunca é alterado.
- **Nada é publicado** — o usuário faz o upload manual do `banner.png`.

### Report to the user

- Output path (`~/career/<candidate>/linkedin/banner/`).
- Direção visual usada (conceito/paleta; marcada como direção do usuário
  quando for o caso) + contatos exibidos (e os omitidos por ausência no hub).
- Resultado do gate de texto: geração aceita / retries usados / overlay
  determinístico aplicado.
- Conferência manual dos previews (zona da foto no desktop; faixa central no
  mobile) e lembrete: geração real exige `EACHLABS_API_KEY` do usuário.
