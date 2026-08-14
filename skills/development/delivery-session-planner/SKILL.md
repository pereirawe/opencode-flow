---
name: delivery-session-planner
description: Plan and generate delivery-session prompts that batch refined (ready) issues into sequential/parallel opencode sessions for any pipeline-tracked repo. Use when the user wants to accelerate delivery, batch-develop multiple known_issues, create a delivery prompt, split work across sessions to save tokens, or order issues by effort and git-conflict safety.
---

# Delivery Session Planner

Cria prompts de sessão para entregar em lote as issues `ready` de
`known_issues.md`, priorizando as mais fáceis/rápidas, paralelizando quando
seguro e dividindo o trabalho em **várias sessões pequenas** (não uma sessão
gigante) para poupar contexto/tokens.

## Input

- O projeto (default: workspace atual) — o `known_issues.md` fica em
  `<projeto>/.opencode/known_issues.md`.
- Regras de prioridade do usuário (ex.: "só backend", "só docs", "máx Xh por
  sessão"). Se não dadas, use os defaults abaixo.

## Passo 1 — Coletar issues elegíveis

1. Ler `known_issues.md` e listar todas com `- Status: ready`.
2. Para cada uma, extrair do registro:
   - `ID`, `Type`, `Severity`
   - `Location:` (paths reais — usados para detectar conflitos de git)
   - `Dependencies:` / notas de sequenciamento
   - Esforço estimado no `Suggested fix:` (padrão `~Nh`, `~N-Mh`, ou
     breakdown `schema ~4h; APIs ~6h`)
   - `Reviewers:`, `Tests:` (confirmar que a issue está refinada)
3. **Excluir** issues `backlog` (a menos que explicitamente refinadas e
   `ready`), `in-publish`/`resolved`/`in-progress` e `incomplete-spec`.

## Passo 2 — Classificar por esforço

| Faixa | Rótulo | Exemplo |
|-------|--------|---------|
| ≤ 2h | `quick` | chore/docs de 1h |
| 3–8h | `small` | feature frontend isolada, doc 6h |
| 9–15h | `medium` | backend com 1 endpoint complexo |
| 16h+ | `large` | migration de schema, integração de gateway |

Ordenar cada faixa por esforço crescente.

## Passo 3 — Detectar conflitos de git (crítico)

Regras que determinam o que **NÃO pode** rodar em paralelo:

1. **Mesmos arquivos em `Location:`** → nunca paralelo (ex.: duas issues
   editando `negocio-form.tsx` ou `messages/*.json`). Sequenciar.
2. **`prisma/schema.prisma` / migrations** → nunca paralelo; migrations são
   obrigatoriamente sequenciais (ex.: `#88` 1ª migration → `#89` 2ª).
3. **`src/middleware.ts`** → ponto de contenção de auth (ex.: `#89` e `#90`
   ambos editam) → nunca paralelo.
4. **`next.config.js`, `vercel.json`, `package.json`** → pontos globais;
   paralelizar só se as mudanças forem em blocos distintos e sem sobreposição.
5. **Dependência de dados/schema** (issue B "depende do merge da #A") → B
   roda depois de A entregue.
6. **Crons** (vercel.json) → se duas issues adicionam crons, podem coexistir
   mas exigem consolidação; documentar como pré-requisito de merge.

Marcar cada par (A,B) como `PARALELO-OK` ou `CONFLITO` com o motivo.

## Passo 4 — Agrupar em fases e sessões

**Fase 1 — Quick wins** (rápidas + pequenas, independentes):
- Paralelizáveis entre si se `PARALELO-OK`.
- Cada uma pode ser **1 sessão própria** (prompt curto, execução autônoma).

**Fase 2 — Grandes** (médias + grandes):
- Sequenciar por dependência e conflito de arquivos.
- Uma issue `large` sozinha por sessão (não misturar com outras grandes na
  mesma sessão).

**Regra de tamanho de sessão (economia de tokens):**
- **1 sessão = 1 issue**, a menos que 2+ issues sejam `quick`/`small` **e**
  `PARALELO-OK` e juntas ≤ ~8h → aí podem ir na mesma sessão em sequência.
- Nunca colocar issue `large` + outra `large` na mesma sessão.
- Se o usuário quer paralelismo real: gerar **N prompts separados** (um por
  sessão/issue) em vez de um prompt gigante.
- Meta: cada sessão com contexto autocontido (o prompt embute o registro da
  issue) para não depender de contexto global compartilhado.

## Passo 5 — Gerar os prompts

Para cada sessão, criar um arquivo em `<projeto>/docs/delivery-prompts/`:
`delivery-<YYYYMMDD>-sessao-<n>.md` (ou o padrão que o projeto usar). O prompt
DEVE conter:

1. **Papel**: "Você executa o pipeline de delivery (promote → develop →
   senior review → QA → committer gate → MR) para a(s) issue(s) X".
2. **Comando**: `/ocf:delivery <id>` ou `ocf:develop <id>` — pipeline
   contínuo, sem pausa entre fases.
3. **Registro embutido**: copiar do `known_issues.md` o bloco da issue
   (Location, Business rules, AC, Tests, Reviewers, Base branch) para a sessão
   ser autocontida.
4. **Instruções de entrega**:
   - `Remote: -` → auto-cria na promoção; não perguntar.
   - Parar quando MR criada (`Status: in-publish`, `PR: #n`); NÃO rodar Close
     Requester.
   - Ordem das issues dentro da sessão (se >1).
   - Conflitos conhecidos com outras sessões em paralelo (ex.: "não toque
     middleware.ts — outra sessão está editando").
5. **Nota de paralelismo**: se houver outras sessões rodando em paralelo,
   listar os arquivos que esta sessão NÃO deve tocar.

## Output final

- Lista de sessões geradas: por sessão → issues, faixa de esforço, arquivos
  tocados, conflitos evitados.
- Ordem de execução recomendada (Fase 1 paralela primeiro, Fase 2 sequencial
  depois).
- Estimativa de economia de contexto: `N sessões pequenas vs 1 gigante`.
- Se o usuário pedir, também salvar um `README` na pasta de prompts listando
  todas as sessões e o status (pendente/em andamento/concluída).

## Lembrete de qualidade

- Sempre justificar `PARALELO-OK` vs `CONFLITO` com caminhos reais de arquivo
  (nunca só "não dá").
- Esforço vem do `Suggested fix:`/breakdown da issue — nunca inventar.
- Issues `incomplete-spec` não entram no batch.
- Ao final, sugerir notificação via `telegram-notifier` resumindo as sessões
  criadas.
