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
- PR: - | #<pr-number>
- Location: <file-path>:<line-numbers>
- Description: <brief>
- Impact: <what or who is affected>
- Business rules: <specific business logic, constraints, and domain rules>
- Suggested fix: <approach or next step>
```

`Business rules:` is required for `feat` type issues.
`Reviewers:` is set during promotion and consumed during senior review and MR creation.


### 6. Revisar e enriquecer o PR template
- Status: backlog
- Type: feat
- Severity: medium
- Report: william.pereira@digitalup.intranet
- Reviewers: (set during promotion)
- Remote: -
- Location: `standards/pr-template.md`:1-16, `standards/pt/pr-template.md`:1-16, `standards/es/pr-template.md`, `standards/fr/pr-template.md`, `standards/de/pr-template.md`, `standards/ja/pr-template.md`, `standards/zh/pr-template.md`, `agents/publish-requester.md`:17-18
- Description: Expandir o PR template atual (en/pt/es/fr/de/ja/zh) para um template único mais completo, com seções opcionais. O publish-requester deve preencher automaticamente os dados da issue.
- Impact: PRs mais completos reduzem idas-e-voltas em revisão e documentam decisões técnicas.
- Business rules:
  1. O template DEVE ser único (não múltiplos templates por tipo de issue).
  2. Seções opcionais DEVEM ser claramente marcadas como `(opcional)` no template.
  3. O template DEVE incluir: Resumo executivo, Contexto/Motivação, O que mudou, Checklist, Screenshots/Evidências (opcional), Breaking Changes (opcional), Rollback Plan (opcional), Referência à Issue (obrigatório), Riscos, Como Testar.
  4. A seção "Referência à Issue" DEVE conter `Relates to: #<id>` linkando para a known_issues.md.
  5. O agente publish-requester DEVE preencher automaticamente o template com: título da issue, ID, branch name, e remote reference.
  6. Todas as traduções existentes (pt, es, fr, de, ja, zh) DEVEM ser atualizadas em paralelo com o template en.
  7. O template en (`standards/pr-template.md`) é o padrão; os localized templates devem seguir a mesma estrutura.
- Suggested fix: Revisar `standards/pr-template.md` adicionando as novas seções. Atualizar cada tradução. Atualizar `agents/publish-requester.md` para usar o novo template e preencher campos automaticamente.

### 7. Melhorar ocf:init com detecção de linguagens, sugestão de LSPs e configuração automática do editor
- Status: in-progress
- Type: feat
- Severity: medium
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: #14
- Location: `standards/lsp-catalog.json`:1-157, `commands/ocf:init.md`:1-31, `scripts/init.sh`:1-244, `Makefile`:49-55, `opencode.json`:10-13
- Description: O init global deve detectar linguagens do projeto via catálogo, sugerir LSPs e configurar .vscode/settings.json com merge preservando configurações existentes. Unificar `make bootstrap` para delegar em `init.sh`.
- Impact: Projetos inicializados com opencode ganham configuração de editor pronta para uso, com LSPs adequados ao tipo de projeto.
- Business rules:
  1. O init DEVE detectar linguagens com base na presença de arquivos característicos no projeto (package.json → JS/TS, *.py → Python, Cargo.toml → Rust, go.mod → Go, composer.json → PHP, *.sh → Shell, *.md → Markdown, tailwind.config.* → Tailwind CSS, *.html → HTML, *.css → CSS, *.yml/*.yaml → YAML).
  2. O catálogo DEVE ser mantido em `standards/lsp-catalog.json` como fonte única de verdade para mapeamentos linguagem → extensões VS Code + configurações.
  3. Cada entrada do catálogo DEVE conter: `detectors` (padrões de arquivo), `language` (nome), `extensions` (ids VS Code) e `settings` (configurações recomendadas).
  4. Para cada linguagem detectada, o init DEVE sugerir ao usuário as extensões e configurações correspondentes.
  5. Se o usuário aprovar, o init DEVE fazer merge em `.vscode/settings.json`, preservando configurações existentes do usuário.
  6. Se `.vscode/` não existir, o init DEVE criar o diretório.
  7. `make bootstrap` DEVE delegar para `scripts/init.sh` em vez de duplicar a lógica inline.
  8. O AGENTS.md gerado DEVE usar abordagem híbrida: template base fixo + placeholders substituídos (já existente), sem adicionar seção de LSPs.
- Suggested fix: Criar `standards/lsp-catalog.json` com mapeamentos. Atualizar `scripts/init.sh` para detectar linguagens, consultar catálogo, sugerir LSPs e configurar editor. Atualizar `commands/ocf:init.md` com o novo fluxo. Atualizar `opencode.json` command template. Unificar `make bootstrap` → `init.sh`.

### 8. Validar opencode instalado e atualizado antes do install.sh do opencode-flow
- Status: in-publish
- Type: feat
- Severity: high
- Report: william.pereira@digitalup.intranet
- Reviewers: 1
- Remote: #12
- PR: #13
- Location: `install.sh`:1-96, `README.md`:12-14, `scripts/update.sh`
- Description: O install.sh instala a config opencode-flow sem validar se o opencode (ferramenta AI) está instalado. Se não estiver, a config não tem funcionalidade. Deve também verificar se está atualizado e oferecer update.
- Impact: Usuários podem instalar a config sem ter o opencode, resultando em configuração inútil.
- Business rules:
  1. O install DEVE validar `command -v opencode` e `~/.config/opencode/` antes de prosseguir.
  2. Se opencode não instalado → DEVE perguntar "Instalar opencode? (s/N)". Se recusar, DEVE ABORTAR com a mensagem: "A instalação do opencode-flow não pode continuar pois o opencode não está instalado. Esta config é um overlay e não tem funcionalidade sem o opencode. Instale em: https://opencode.ai"
  3. Se usuário aceitar instalar → DEVE instalar via script curl bash oficial do opencode.ai.
  4. Se installed, DEVE verificar versão via `opencode --version` vs GitHub API latest.
  5. Se desatualizado → DEVE perguntar "Atualizar de vX para vY? (s/N)". Se recusar, DEVE continuar mesmo assim.
  6. Método de atualização DEVE ser detectado: npm (`npm list -g @opencode-ai/cli`), brew (`brew list opencode`), ou perguntar ao usuário.
  7. opencode-flow SÓ deve ser instalado após garantir que opencode existe.
- Suggested fix: Adicionar bloco de validação no início do install.sh antes da instalação da config. Criar função `validate_opencode` que verifica instalação, versão e atualiza se necessário. Atualizar README com o novo fluxo.

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
