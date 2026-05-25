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

### Agent Pipeline

1. **CTO** defines technical vision and guidelines
2. **Product Owner** defines priorities, creates user stories, and registers
   prioritization proposals in `standards/prioritization.md`
3. **Tech Lead** refines stories with technical detail, feasibility analysis,
   effort estimation, and task breakdown
4. **Project Manager** coordinates team, assigns stories, and tracks progress
5. **Quality Analyst** ensures stories are testable and meet quality standards
6. **Developer** implements features, writes automated tests, runs tests, and
   keeps `known_issues.md` in sync
7. **Senior Reviewers** (configurable count, default 1, parallel, by specialty)
   review code, verify acceptance criteria, confirm tests were written and pass,
   and identify issues
8. **Quality Analyst** verifies quality after senior review — checks that all
   identified issues were addressed and quality standards are met
9. **Developer** implements all corrections from senior review and QA
10. **Documentation** maintains project docs
11. **Test Automation** creates and maintains test suites
12. **Publish Requester** creates merge/pull request (only after QA gate passes)

> `known_issues.md` is the single source of truth — every agent must keep it in sync.
> **Business rules must be documented in every `feat` issue before promotion.**
> Missing business rules found during review = incomplete spec, not a bug.

### Issue Lifecycle

1. PO proposal registered in `standards/prioritization.md`
2. Item captured in `known_issues.md` with status `backlog`
3. Refined and approved → `ready`
4. Promoted for execution → `open`
5. Remote issue created, work started → `in-progress`
6. Senior review completed, QA verified, corrections applied → `in-review`
7. MR/PR created → `in-review`
8. MR/PR approved and merged → `resolved`

### Branch Naming

Pattern: `issue-<id>-<slug>`

### Definition of Done

- Tests written and passing (run before senior review)
- Acceptance criteria met (verified by Senior Reviewers)
- Business rules documented and implemented correctly
- QA verified after senior review
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
