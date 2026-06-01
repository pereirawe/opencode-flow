## Known Issues

Single source of truth for tracked work in this project.

### Format

```markdown
### <id>. <title>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Reported by: <user-name> | <model-name>
- Remote: - | #<remote-id>
- Location: <file-path>:<line-numbers>
- Description: <brief>
- Impact: <what or who is affected>
- Business rules: <specific business logic, constraints, and domain rules>
- Suggested fix: <approach or next step>
```

`Business rules:` is required for `feat` type issues.

### 1. Resolved issue archive goes to global instead of project `.opencode/`
- Status: open
- Type: bug
- Severity: high
- Reported by: william.pereira@digitalup.intranet
- Remote: -
- Location: `scripts/config.sh`:25
- Description: Ao arquivar uma issue resolvida de dentro de um projeto que usa a configuração global (mas sem `.opencode/known_issues.md` próprio), o `RESOLVED_FILE` aponta para `$CONFIG_DIR/resolved_issues.md` (global) em vez de `$(pwd -P)/.opencode/resolved_issues.md` (projeto).
- Impact: Projetos que compartilham o issue tracker global perdem o histórico de issues resolvidas no contexto do projeto — toda resolução vai parar no arquivo global.
- Business rules:
  1. Se o projeto possui diretório `.opencode/`, o resolved issues DEVE ser salvo em `.opencode/resolved_issues.md` do projeto, independentemente de onde as issues ativas são trackeadas.
  2. Se NÃO existe diretório `.opencode/` no CWD (ou seja, não há contexto de projeto), o resolved issues DEVE usar o mesmo diretório do issue tracker global (`$CONFIG_DIR`).
  3. A detecção do diretório `.opencode/` deve usar `pwd -P` (caminho físico, sem symlinks).
- Suggested fix: Separar a lógica do `RESOLVED_FILE` da lógica do `PROJECT_ISSUES_DIR` em `config.sh`. Adicionar um bloco `elif [ -d ".opencode" ]` para determinar o diretório de arquivamento.


### 2. Workflow Issue Lifecycle não reflete o pipeline completo
- Status: in-publish
- Type: feat
- Severity: medium
- Reported by: william.pereira@digitalup.intranet
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
