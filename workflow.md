## Discovery to Issue Flow

The discovery flow transforms raw ideas into tracked, typed issues with
acceptance criteria, business rules, and test definitions. Each agent asks
context-based questions to progressively refine the proposal.

### Mandatory Rule

**Every new feature (`feat` type) MUST go through the full discovery pipeline
before development starts.** Issues promoted without documented business rules
will be blocked by the Committer. Missing business rules discovered during
review are not bugs — they are incomplete specs and must be refined back
through discovery.

### Discovery Pipeline

1. **PO** registers a prioritization proposal in `standards/prioritization.md`
   with business value, target, rationale, proposed issue type, and known
   business rules
2. **CTO** reviews architectural alignment, defines technical vision, and
   identifies strategic constraints
3. **Tech Lead** refines with technical detail: feasibility, effort, risks,
   dependencies, non-functional requirements, task breakdown, and validates
   business rules against the technical model
4. **PO** creates user story with acceptance criteria and documented business
   rules — every business rule must be explicit, not implicit
5. **QA** reviews story for testability, edge cases, and quality criteria —
   verifies that business rules are testable
6. **PM** validates dependencies, assigns to sprint, and promotes to
   `known_issues.md` with status `backlog` or `ready`

### Agent Discovery Questions

Each agent must ask context-based questions during discovery. The PO must
drive the conversation around **business rules** specifically.

- **CTO**: Quais princípios arquiteturais são afetados? Existem trade-offs
  conhecidos? Como isso se alinha com a visão técnica de longo prazo?
- **PO**: Quem é o usuário final? Qual o valor de negócio? Qual a urgência?
  Quais critérios definem sucesso? **Quais são as regras de negócio
  específicas? Quais condições, limites e exceções existem?**
- **Tech Lead**: Quais camadas são afetadas? Quais dependências existem?
  Quais requisitos não-funcionais? Qual o esforço estimado? **As regras de
  negócio estão completas e consistentes com o modelo técnico?**
- **QA**: Quais cenários de teste são necessários? Quais edge cases existem?
  Como validamos os critérios de aceite? **Como testamos cada regra de
  negócio isoladamente?**

## Development Workflow

### Mandatory Rule

**Every implementation request — regardless of how it's asked — MUST follow the
full pipeline.** This is enforced at the instruction level via `AGENTS.md`.
Any direct implementation without pipeline is a violation.

### Agent Pipeline

1. **CTO** — define technical vision and guidelines
2. **Product Owner** — define priorities, create user stories, register
   prioritization proposals in `standards/prioritization.md`
3. **Tech Lead** — refine stories with technical detail, feasibility analysis,
   effort estimation, and task breakdown
4. **Project Manager** — coordinate team, assign stories, track progress.
   **During promotion, PM MUST ask the user for the base branch:**
   *"A issue será resolvida na branch default do repositório [main/master] ou em
   outra branch existente?"*
   If another branch is chosen, list available local branches for selection.
   Checkout and pull the chosen base branch, then create the feature branch
   `issue-<id>-<slug>` from it. Update status to `open`.
   **PM MUST also ask: "Quantos revisores seniors devem revisar este trabalho?"
   (default 1) and store the number in `- Reviewers:` in the issue entry.**
5. **Quality Analyst (pre-development)** — ensure stories are testable and meet
   quality standards, validate business rules are testable
6. **Developer** — implement features, write automated tests, run tests, keep
   `known_issues.md` in sync. Verify the feature branch is based on the correct
   base branch before starting implementation.
7. **Senior Reviewers** — review code using the count stored in `- Reviewers:`
   in the issue entry (set during PM promotion), verify acceptance criteria,
   confirm tests were written and pass, identify issues
8. **Quality Analyst (post-review)** — verify quality after senior review,
   check that all identified issues were addressed and quality standards are met
9. **Developer** — implement all corrections from senior review and QA (loop
   with QA until approved)
10. **Committer** — verify pipeline gates: senior review completed, QA passed,
    business rules documented (for `feat` types), tests passing. Sets status to
    `in-publish` on approval.
11. **Publish Requester** — create merge/pull request after Committer gate passes.
    Does not re-validate gates — trusts Committer signal (`Status: in-publish`).

> **Documentation** and **Test Automation** are ongoing activities that run in
> parallel across all pipeline phases, not sequential gates.

> `known_issues.md` is the single source of truth — every agent must keep it in sync.
> **Business rules must be documented in every `feat` issue before promotion.**
> Missing business rules found during review = incomplete spec, not a bug.

### Issue Lifecycle

1. PO proposal registered in `standards/prioritization.md`
2. Item captured in `known_issues.md` with status `backlog`
3. Refined and approved, QA pre-development review → `ready`
4. PM promotes the issue, asks user for base branch (default or existing),
   checkouts+pulls the base branch, creates feature branch `issue-<id>-<slug>`
   from it, asks for reviewer count (default 1) and stores in `- Reviewers:`,
   creates remote issue → `open`
5. Remote issue exists, work started on branch → `in-progress`
   — Senior review feedback addressed while staying `in-progress`
6. Senior review completed, all issues resolved → `in-review`
7. QA verification:
   - Corrections needed → `in-qa` → `in-progress` (back to step 5)
   - Approved → `in-qa`
8. Committer gate passed → `in-publish`
9. MR/PR created → `in-publish`
10. MR/PR approved and merged → `resolved`

### Branch Naming

Pattern: `issue-<id>-<slug>`

Branches are created from the user-chosen base branch (default or another
existing branch) during the PM promotion step.

### Definition of Done

- Base branch correctly chosen and feature branch created from it
- Tests written and passing (run before senior review)
- Acceptance criteria met (verified by Senior Reviewers)
- Business rules documented and implemented correctly
- QA verified after senior review
- Committer gate passed before MR creation
- `known_issues.md` reflects current status at every step
- MR approved and merged

### Pre-commit

- Run tests for the project language
- Warn if `known_issues.md` not updated

### Pull/Merge Request

Must include:
- Tests passing
- Issue reference
- Updated docs
- QA verification confirmed
