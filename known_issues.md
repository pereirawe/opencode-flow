## Known Issues

Single source of truth for tracked work in this project.

### Format

```markdown
### <id>. <title>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Report: <user-name> | <model-name>
- Reviewers: <number> (set during promotion, default 1)
- Remote: - | #<remote-id>
- Location: <file-path>:<line-numbers>
- Description: <brief>
- Impact: <what or who is affected>
- Business rules: <specific business logic, constraints, and domain rules>
- Suggested fix: <approach or next step>
```

`Business rules:` is required for `feat` type issues.
`Reviewers:` is set during promotion and consumed during senior review and MR creation.

### 1. Resolved issue archive goes to global instead of project `.opencode/`
- Status: open
- Type: bug
- Severity: high
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: -
- Location: `scripts/config.sh`:25
- Description: Ao arquivar uma issue resolvida de dentro de um projeto que usa a configuração global (mas sem `.opencode/known_issues.md` próprio), o `RESOLVED_FILE` aponta para `$CONFIG_DIR/resolved_issues.md` (global) em vez de `$(pwd -P)/.opencode/resolved_issues.md` (projeto).
- Impact: Projetos que compartilham o issue tracker global perdem o histórico de issues resolvidas no contexto do projeto — toda resolução vai parar no arquivo global.
- Business rules:
  1. Se o projeto possui diretório `.opencode/`, o resolved issues DEVE ser salvo em `.opencode/resolved_issues.md` do projeto, independentemente de onde as issues ativas são trackeadas.
  2. Se NÃO existe diretório `.opencode/` no CWD (ou seja, não há contexto de projeto), o resolved issues DEVE usar o mesmo diretório do issue tracker global (`$CONFIG_DIR`).
  3. A detecção do diretório `.opencode/` deve usar `pwd -P` (caminho físico, sem symlinks).
- Suggested fix: Separar a lógica do `RESOLVED_FILE` da lógica do `PROJECT_ISSUES_DIR` em `config.sh`. Adicionar um bloco `elif [ -d ".opencode" ]` para determinar o diretório de arquivamento.


### 2. Adicionar etapa de definição da branch base no pipeline de promoção
- Status: in-progress
- Type: feat
- Severity: medium
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: -
- Location: `workflow.md`:59-79, `scripts/promote.sh`:1-67
- Description: Antes de iniciar o desenvolvimento de uma issue, o PM deve perguntar ao usuário se a branch base será a default do repositório (main/master) ou outra branch existente, fazer checkout+pull da branch base, e criar a branch de feature a partir dela.
- Impact: Sem essa etapa, o desenvolvedor pode criar a branch a partir de uma branch desatualizada ou incorreta, gerando conflitos e retrabalho.
- Business rules:
  1. O PM DEVE perguntar ao usuário durante a promoção: "A issue será resolvida na branch default do repositório [main/master] ou em outra branch existente?"
  2. Se o usuário escolher outra branch, o PM DEVE listar as branches locais disponíveis para escolha.
  3. O PM DEVE fazer checkout e pull da branch base escolhida antes de criar a branch de feature.
  4. A branch de feature DEVE ser criada a partir da branch base escolhida com o padrão `issue-<id>-<slug>`.
  5. O script promote.sh DEVE aceitar um parâmetro opcional de base branch e executar checkout+pull + criação da branch.
- Suggested fix: Adicionar etapa no workflow.md Agent Pipeline (passo 4 - PM) e Issue Lifecycle (passo 4). Atualizar project-manager.md, developer.md, branching.md, promote.sh e Makefile.

### 3. Workflow Issue Lifecycle não reflete o pipeline completo
- Status: in-publish
- Type: feat
- Severity: medium
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: #1
- Location: `workflow.md`:82-91
- Description: O Issue Lifecycle no workflow.md não mapeia corretamente o Agent Pipeline. Status `in-review` usado para duas fases distintas (senior review e MR criado). Falta Committer gate, branch creation, e QA pós-senior-review como etapas explícitas.
- Impact: Ambiguidade no fluxo de desenvolvimento, risco de pular etapas (QA, Committer) sem detecção.
- Business rules:
  1. Cada gate do pipeline (senior review, QA, Committer) DEVE ter etapa explícita no lifecycle.
  2. Status `in-review` DEVE refletir uma única fase semântica — ou divide-se em múltiplos status ou documenta-se os sub-passos com clareza.
  3. O lifecycle DEVE espelhar o Agent Pipeline (12 passos) para evitar gaps.
  4. Branch creation (via promote) DEVE constar no lifecycle.
- Suggested fix: Revisar o `### Issue Lifecycle` para incluir: promotion+branch, development, senior review, QA+corrections, Committer gate, MR creation, MR merge. Alinhar com o Agent Pipeline.

### 4. Pergunta sobre quantidade de revisores seniors não está documentada no pipeline
- Status: in-progress
- Type: bug
- Severity: medium
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: -
- Location: `workflow.md`:57-86, `opencode.json`:18-25, `agents/publish-requester.md`:26-27
- Description: O PM/desenvolvedor não pergunta ao usuário quantos revisores seniors devem revisar o código. O pipeline não documenta essa pergunta, e o valor padrão está sendo 2 revisores (divergente do especificado como default 1). O publish-requester lê de `opencode.json` (que não existe) ao invés de ler do campo `Reviewers:` na issue.
- Impact: Revisão sempre usa 2 revisores sem consultar o usuário, podendo gastar recursos desnecessários ou ser insuficiente.
- Business rules:
  1. Durante a promoção (PM), DEVE ser perguntado: "Quantos revisores seniors devem revisar este trabalho?" (default 1).
  2. O número DEVE ser armazenado no campo `- Reviewers:` na issue em `known_issues.md`.
  3. Durante a revisão, a quantidade DEVE ser lida do campo `- Reviewers:` da issue, não do `opencode.json`.
  4. O publish-requester DEVE ler do campo `Reviewers:` da issue, não do `opencode.json`.
- Suggested fix: Adicionar etapa no workflow.md Agent Pipeline (passo 4) e Issue Lifecycle (passo 4). Atualizar project-manager.md, publish-requester.md, e opencode.json (ocf:promote). Alterar publish-requester para ler do campo `Reviewers:` da issue.

### Status Lifecycle

- `backlog`: item captured but not yet refined or prioritized
- `ready`: item refined, approved, testable — ready for development
- `open`: item selected locally and awaiting remote issue creation
- `in-progress`: remote issue exists and work has started
- `in-review`: senior review completed, awaiting QA verification
- `in-qa`: QA verifying post-review corrections (may loop back to `in-progress`)
- `in-publish`: Committer gate passed, MR created, awaiting merge
- `resolved`: MR approved and merged (moved to archive)

Resolved issues move to `resolved_issues.md` (same directory as this file). See `standards/resolved-issue.md` for the archive format.
