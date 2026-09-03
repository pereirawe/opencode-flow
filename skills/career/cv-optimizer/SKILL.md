---
name: cv-optimizer
description: Analyze and optimize a candidate's profile from hub.json — general qualifications, profile score (0-100 per section + global), target job profiles, CLT vs PJ market salary ranges ([INFERIDO] bands), context gaps, integrated objective-calibrated LinkedIn improvements (banner, headline literal, Sobre com logros, experiência com bullets, revisão de skills — consistent with cv-linkedin, referencing ocf:cv-banner / linkedin-optimization.md / linkedin-sync.json) and a prioritized action plan. Use when you need to analyze and improve a candidate's profile (command ocf:cv-optimize). Career sector.
---

# CV Optimizer — profile analysis and improvement plan

Analyzes the candidate's `hub.json` (built by `cv-hub`) and produces an
actionable report with profile score, target job profiles, market salary
ranges, an integrated objective-calibrated **"Melhorias no LinkedIn"** plan
(issue #226) and a prioritized action plan. The goal is to **improve the profile
substantially** before generating tailored resumes (`cv-tailor`).

## Prerequisite

A valid `~/career/<candidate-name>/hub.json` (validated by
`python3 $SCRIPTS_DIR/cv/validate.py`). If it does not exist, the `ocf:cv-hub`
flow must run first (the `ocf:cv-optimize` command already handles this).

## LinkedIn context (optional inputs, consumed when present)

The report's "Melhorias no LinkedIn" section consumes — when present next to
the hub in `~/career/<candidate-name>/` — the outputs of the LinkedIn flow
(issues #222/#223/#224/#225). All are optional: their absence never blocks the
analysis, it only changes what the section recommends:

- `hub.profile_objective` (issue #222) — the profile objective that
  calibrates every LinkedIn action (`type` in {`job_search`, `connections`,
  `services_sales`, `personal_branding`} + optional `target_role`/`note`).
  Absent/ambiguous → ask the user ONE quick question (four type options +
  literal target roles/services) or, if unanswered, DECLARE the assumed
  objective at the top of the section — never silently, never founder/CEO for
  a `job_search` profile.
- `linkedin-optimization.md` (issue #223 / `ocf:cv-linkedin`) — the ready
  literal headline/Sobre/experience/skills copy. REFERENCE it — never
  duplicate its text into `profile-analysis.md`.
- `linkedin-sync.json` (issue #225 — `scripts/cv/linkedin-sync.py` +
  `cv-linkedin-sync` skill) — the real-LinkedIn skills diff
  (add/promote/remove). Absent → recommend running the issue-225 sync or
  applying from the hub + objective keywords.
- `ocf:cv-banner` (issue #224) — the planned banner command referenced as the
  artifact to run for the banner item; issue #224 is NOT implemented in this
  config version — never invent its output contract, just reference the
  command.

## Output

```
~/career/<candidate-name>/profile-analysis.md    # report (markdown)
~/career/<candidate-name>/profile-analysis.html  # rendered report (for PDF)
~/career/<candidate-name>/profile-analysis.pdf   # report PDF (A4)
~/career/<candidate-name>/tasks.json           # optional — structured tasks
```

The report does NOT modify `hub.json` — it only reports.

## Report language

The report MUST be written in the language the user communicates in (detected
from the session locale — `.opencode/locale` project → global → English — or
an explicit user instruction). This applies to `profile-analysis.md`,
`gap-analysis.md` and `inferences.md` (career analysis outputs). Technical
terms, command names and the `[INFERIDO]` label remain unchanged. See
`standards/cv-analysis.md` §1 for the full resolution order.

## Report format

The report MUST follow the canonical structure defined in
`standards/cv-analysis.md` (heading hierarchy, section order, canonical
tables, `[INFERIDO]` inline convention, report language rule). Load that
standard and conform to it.

Canonical section order (H2) in `profile-analysis.md`:

1. **Profile score** (global + per section)
2. **General qualifications**
3. **Target job profiles**
4. **Market salary (CLT vs PJ)**
5. **Context gaps**
6. **Melhorias no LinkedIn** (LinkedIn improvements — §7 of the analysis
   protocol below; heading rendered in the report language, PT form canonical)
7. **Prioritized action plan**

Rules (per `standards/cv-analysis.md`):

- **No metadata header** — no lines like "Generated on:", "Source:", "Tool:",
  "Note:". Start directly with the content (exactly one `H1` title, then the
  first section).
- **Score table** — the canonical table: `Section | Score (0-100) |
  Justification` (one row per hub section + the `Global` row).
- **Action plan table** — the canonical table: `ID | Action | Impact |
  Effort | Priority | Target profile`.
- The `[INFERIDO]` markers go inline next to each estimate — not as a warning
  at the top of the document.

## PDF generation

After writing `profile-analysis.md`, also generate the PDF for easier reading:

1. Copy the reference template
   `skills/career/cv-optimizer/templates/profile-analysis.html` to
   `profile-analysis.html` and adapt the CONTENT (never the CSS), following the
   design language of `standards/cv-design.md` and the structure of
   `standards/cv-analysis.md` (A4 via `@page { size: A4; margin: 12mm 15mm }`,
   clean typography, semantic headings, no metadata header). The template
   shares the resume's design language — the same `:root` typographic token
   scale and components (header lockup, tabular numerals, `.inline-list`,
   page-2 running footer) per `standards/cv-design.md` §3 (token scale,
   tabular numerals, page-2 footer) with the resume template as the reference
   implementation for the header-lockup and `.inline-list` patterns.
2. Run `bash $SCRIPTS_DIR/cv/pdf.sh profile-analysis.html profile-analysis.pdf`.
3. If the engine fails, report the error — never deliver an empty PDF.

## Analysis protocol

### 1. Validate and load the hub

1. Run `python3 $SCRIPTS_DIR/cv/validate.py hub.json`. Exit 0 → continue.
2. Missing/invalid hub → tell the user that `ocf:cv-hub` must run first and
   stop (do not fix data manually).
3. Load the JSON and extract: personal info, summary, experience, education,
   skills (with levels), certifications, projects, languages, links.

### 2. Analyze general qualifications

- **Detected domain(s)** — the candidate's primary domain(s), inferred from
  `personal_info.professional_title`, skill `category` values, experience
  `title`s and the `summary`. Always `[INFERIDO]`. Drives the domain-relative
  scoring criteria of §3 (per-domain section priorities).
- **Inferred seniority** — from the total years of experience, most recent
  titles and skill depth (junior/mid/senior/expert/lead). Always `[INFERIDO]`.
- **Top skills** — top skills by `level` and `importance`. For each skill,
  record **`since` (start year)** and compute the years of experience
  **dynamically up to the current year** (`current_year - since`). Never use
  a fixed `years_of_experience` from the hub as fact — it becomes stale over
  time; if the hub has `since`, recompute; if it only has
  `years_of_experience`, use it as a reference but mark the estimate
  `[INFERIDO]`.
- **Strengths** — strong sections (dense skills, achievements with metrics,
  certifications, projects with links).
- **Weaknesses** — empty/shallow sections, missing dates, experience gaps,
  skills without level.

### 3. Profile score (0-100)

**Domain-relative scoring.** Before scoring, apply the **Detected domain(s)**
from §2 (inferred from `professional_title`, skill categories, experience
titles and the summary — always `[INFERIDO]` in the report). Each domain maps
to high/medium/low section priorities (reference table below) that shape the
scoring criteria per priority tier — applied per tier, never globally. For a
domain NOT in the reference table, derive the priorities from the domain's
nature (extensibility rule below) and RECORD the derivation in the report.

Score each section based on **completeness and strength** relative to the
domain's priorities:

| Section | Scoring criteria (domain-relative) |
|---------|------------------------------------|
| personal_info | name + contact + location + professional links present |
| summary | summary present, clear, with differentiators; ideally bilingual (summary_i18n) |
| experience | titles with dates, summary, achievements (metrics = bonus); always high priority |
| education | complete institutions/courses, defined status; high priority in licensing/certification-driven domains (legal, HR) |
| skills | quantity, explicit level, categories, `since`/years of experience (bonus: `since` present — allows computing years dynamically) |
| certifications | present, with issuer and year; high priority in licensing/certification-driven domains |
| projects | present, with description and link (link = bonus); link REQUIRED when the domain's projects priority is high (portfolio-driven domains: engineering, technology/IT, design) |
| languages | present, with formal level (scale_note = bonus); high priority in client-facing domains |
| links | LinkedIn is near-universal — required for every domain. GitHub/site/portfolio is REQUIRED only when the domain's links priority is **high** (engineering, technology/IT, design). When links priority is low/medium, LinkedIn presence alone satisfies the criterion — a missing GitHub/site MUST NOT lower the links score. |

**Per-domain section priorities (reference table):**

| Domain | personal_info | summary | experience | education | skills | certifications | projects | languages | links |
|--------|---------------|---------|------------|-----------|--------|----------------|----------|-----------|-------|
| engineering | medium | medium | high | medium | high | medium | high | low | high |
| technology/IT | medium | medium | high | medium | high | medium | high | low | high |
| commercial/sales | medium | high | high | medium | medium | medium | low | high | medium |
| human resources | medium | medium | high | high | medium | high | low | medium | low |
| legal | medium | medium | high | high | medium | high | low | medium | low |
| marketing | medium | high | high | medium | medium | medium | medium | medium | medium |
| design | medium | medium | high | medium | medium | low | high | low | high |

**Extensibility rule (domains not in the reference table).** Derive the
section priorities from the domain's nature — portfolio-driven →
`projects` high; licensing/certification-driven → `certifications` high;
client-facing → `languages`/`experience` high — and RECORD the derivation in
the report (`[INFERIDO]`). Never fail and never silently fall back to the
engineering template.

Rules:
- Each empty section = 0. Each section with minimal data = 40-60. Complete
  sections = 70-90. With differentiators (metrics, links, formal notes) = 90-100.
- **Global = weighted average over ONLY the sections present AND non-empty**
  in the hub (single source of the exclusion rule:
  `standards/cv-analysis.md` §4.2). A section is present/non-empty when its
  array has ≥ 1 item (`experience`, `education`, `skills`, `certifications`,
  `projects`, `languages`, `links`) or when the value has content (`summary`
  string, `personal_info` object). Empty/missing sections keep a score row of
  0 in the table (they are context gaps) but are **excluded** from the Global
  average — never included as 0.
- **Explicit weights**: `experience` 1.5x, `skills` 1.5x, all other present
  sections 1x — the issue #215 base weights, preserved. The domain-relative
  part is the per-section score: the domain priorities (reference table)
  shape each section's criteria (required vs bonus), which drives the score
  that enters the Global average. Weighted formula (round to the nearest
  integer):

  ```
  Global = round( Σ (score_section × weight_section) / Σ weight_section )
  ```

- **Worked example** — experience 85, skills 90, education 65, personal_info
  80, summary 70; certifications, projects, languages and links empty (score
  0, excluded):

  ```
  (85×1.5 + 90×1.5 + 65×1 + 80×1 + 70×1) / (1.5 + 1.5 + 1 + 1 + 1)
  = 477.5 / 6 = 79.58 → Global = 80
  ```

  The Global row justification reads: "Weighted average over present sections
  (experience, skills, education, personal_info, summary); excluded: projects, certifications, languages, links — empty/missing sections."
- **0-global guard** — `Global = 0` is valid ONLY when every hub section is empty/missing.
  The Global MUST NEVER be 0 when at least one scored section has a score ≥ 40.
- **Global row justification MUST list the excluded sections and why** — no
  silent averages.
- Excluded empty sections remain listed under **Context gaps** (report §5) —
  never silently dropped.
- **Textual justification required** for every score.
- Scores are estimates — no `[INFERIDO]` on the score itself (it is
  computed), but any inference used in the justification must be marked.
- **Output table** — the report's score table MUST be the canonical format of
  `standards/cv-analysis.md` §4.2:
  `Section | Score (0-100) | Justification` — one row per hub section key
  (`personal_info`, `summary`, `experience`, `education`, `skills`,
  `certifications`, `projects`, `languages`, `links`) plus the `Global` row.

### 4. Target job profiles (offline)

Suggest **job profiles** (not real jobs) that fit the profile well, based on
the hub analysis:

- Likely titles (e.g. Senior Data Engineer, Data Platform Engineer)
- Segments/industries where the skills are in demand (e.g. fintech, e-commerce)
- Stacks that match the hub skills
- Seniority of the target jobs

**Forbidden**: listing concrete jobs, specific companies or URLs — everything
is a generic profile derived from the offline analysis. Each profile marked
`[INFERIDO]`.

### 5. Market salary range (CLT vs PJ)

Deliver reference ranges by **seniority/stack/region** for CLT (monthly) and
PJ (monthly), based on general market knowledge. **ALL** ranges MUST be
marked `[INFERIDO]` — the candidate reviews and adjusts before using. Never
invent specific sources.

Format:
```
- Senior Data Engineer | São Paulo (SP)
  - CLT: R$ 14.000 – 20.000 [INFERIDO]
  - PJ: R$ 22.000 – 30.000 [INFERIDO]
```
Include: suggested range, negotiation target range, and the candidate's
declared expectation (if present in `personal_info.salary_expectation`) with
an adherence assessment.

### 6. Context gaps in the hub

List **missing** information that, if filled, would increase the context and
impact of the profile:

- Achievements without metrics/numbers (suggest the format "Reduced X by Y%")
- Projects without link/description
- Certifications without year/issuer/expiry
- Languages without a formal level (scale_note: B2/C1, IELTS...)
- Experience with missing dates or unexplained gaps
- Skills without level OR without `since`/years of experience (the skill
  exists, but seniority cannot be sized — recommend recording the start year)
- Summary without differentiators/positioning
- Entirely missing sections (projects, certifications, languages)

### 7. LinkedIn improvements (integrated, objective-calibrated)

Produce the H2 section **"Melhorias no LinkedIn"** — the LinkedIn improvement
plan integrated into the analysis (issue #226). The section uses the SAME
topic taxonomy as the cv-linkedin report (`linkedin-optimization.md`, issue
#223) — banner do perfil, headline literal, Sobre com logros, experiência com
bullets de resultado, revisão de skills — so the two reports never
contradict.

**Objective first (never silently).** Read `hub.profile_objective` (issue
#222): `type` in {`job_search`, `connections`, `services_sales`,
`personal_branding`} + optional `target_role`/`note`.

- Present and clear → the section opens with an H3 **Objetivo do perfil**
  echoing it (key/value lines `Tipo:`/`Objetivo:`/`Cargo/serviço alvo:`/
  `Contexto:` + "Todo o plano de LinkedIn segue este objetivo.") and the
  items are calibrated by it:
  - `job_search` → headline literal com o nome da vaga + disponibilidade;
    Sobre CTA de disponibilidade; skills priorizadas para a busca.
  - `services_sales` → serviços pelo nome + banner de oferta; Sobre CTA de
    contato/orçamento.
  - `connections` / `personal_branding` → wording de identidade/niche
    conforme a referência de objetivo do cv-linkedin.
- Missing or ambiguous → ask the user ONE quick question (four type options +
  literal target roles/services). If they do not answer, open the section
  with an explicit declaration — "Objetivo assumido para este relatório:
  `<type>` como `<cargo/serviço>` — confirme se não for o caso." — choosing
  the assumed type from hub evidence (`professional_title`, summary,
  experience: salaried-career hubs default to `job_search` with the literal
  target role; service-selling hubs to `services_sales`). Never silently,
  **never founder/CEO positioning for a `job_search` profile**.

**Five topic items (actionable + prioritized).** One item per topic, each a
bullet with the action, the artifact/output to produce and a priority (P1/P2/
P3, consistent with the action-plan rules):

1. **Banner do perfil** (issue 224) — avaliar/criar o banner via
   `ocf:cv-banner` (planejado — issue 224 não implementada nesta versão;
   referencie o comando como o artefato a rodar, sem inventar o contrato de
   saída). O banner carrega telefone/e-mail/redes sociais/frase curta de
   impacto REAIS do hub (`personal_info`) e respeita a zona segura da foto de
   perfil (canto inferior esquerdo + banda central legível no mobile).
   Contatos ausentes do hub são omitidos — nunca inventados.
2. **Headline literal** — aplicar headline ≤220 chars com os nomes LITERAIS
   das vagas/serviços (job_search → título da vaga + disponibilidade;
   services_sales → serviços). Referencie as variantes prontas do
   `linkedin-optimization.md`; sem esse arquivo, a ação é "rodar
   `ocf:cv-linkedin`" para gerá-lo.
3. **Sobre estruturado com logros** (issue 223) — reestruturar o Sobre
   (≤2600 chars): hook → lógica de valor → bullets ✔ de conquistas com
   métricas reais (`ação → resultado quantificado`) → CTA alinhado ao
   objetivo. Referencie o rascunho do `linkedin-optimization.md`; conquistas
   sem métrica no hub → lacuna explícita, nunca número inventado.
4. **Experiência com bullets de resultado** (issue 223) — reescrever os
   cargos com bullets de resultado (conquistas com métricas + responsabilidades
   condensadas) prontos para colar no campo de descrição do LinkedIn.
   Referencie os bullets do `linkedin-optimization.md`; sem métrica → gap.
5. **Revisão de skills** (adicionar/promover/remover — issue 225/223) — vs a
   lista REAL de skills do LinkedIn: quando existir `linkedin-sync.json`,
   cite o diff (`sections.skills.recommendations[]`: `add_to_linkedin` /
   `promote_on_linkedin` / `remove_from_linkedin`) com os totais
   adicionar/promover/remover; sem export/sync → recomendar rodar o sync da
   issue 225 (`scripts/cv/linkedin-sync.py` + skill `cv-linkedin-sync`) ou
   aplicar a partir do hub + keywords do objetivo. Respeitar o top-3 de busca
   e o teto top-50 de exibição do LinkedIn. Nunca inventar a lista real.

**Reference, never duplicate.** `profile-analysis.md` is an internal analysis
artifact: `[INFERIDO]` markers are allowed inline here (§5). The section only
RECOMMENDS the LinkedIn actions and references the copy-paste-ready outputs
(`linkedin-optimization.md`, `ocf:cv-banner`, `linkedin-sync.json`) — it never
writes the literal headline/Sobre/bullets itself, so the `[INFERIDO]` ban of
the shareable `linkedin-optimization.md` is never violated.

### 8. Prioritized action plan

**Output table** — the report's action plan MUST be the canonical table of
`standards/cv-analysis.md` §4.3:

```
| ID | Action | Impact | Effort | Priority | Target profile |
```

- **ID** — sequential identifier (A1, A2, ...)
- **Action** — what to do (e.g. "Add metrics to 3 Acme achievements")
- **Impact** — high/medium/low on strengthening the profile
- **Effort** — low/medium/high
- **Priority** — P1 (high impact + low effort) up to P3
- **Target profile** — which job profile the action serves (`-` when general)

Group rows by category: fill hub gaps, strengthen weak sections, close
target-job gaps (courses/certifications/languages), positioning, **LinkedIn**.

**LinkedIn category rows.** Every LinkedIn improvement item of section 7
(§ "Melhorias no LinkedIn") MUST also appear here as an action row, with
Impact/Effort/Priority and the artifact/output to produce in the Action cell
(e.g. "LinkedIn — rodar `ocf:cv-banner` para gerar o banner do perfil",
"LinkedIn — aplicar headline literal do `linkedin-optimization.md` (vaga +
disponibilidade)", "LinkedIn — aplicar diff de skills do `linkedin-sync.json`
(adicionar/promover/remover)" or "rodar o sync da issue 225"). The rows
reference the cv-linkedin/cv-banner outputs — they never duplicate their
text.

## Hard rules

1. NO invented data: every estimate/inference marked `[INFERIDO]`.
2. NEVER modify `hub.json` — only analyze and report.
3. No web search: 100% offline analysis over the hub.
4. No sensitive data (CPF, full address, bank) in the report.
5. No concrete jobs/companies/URLs — only generic profiles.
6. Sensitive data already excluded by cv-hub stays excluded.
7. The report MUST follow `standards/cv-analysis.md` (canonical structure:
   heading hierarchy, section order, canonical tables, no metadata header).
   NO metadata header in the report (no "Generated on:", "Source:", "Tool:",
   "Note:" at the top) — start directly with the content. The `[INFERIDO]`
   markers are inline, not a global warning.
8. Skill years of experience MUST be computed dynamically
   (current year − `since`) whenever `since` is present in the hub — never
   display a fixed `years_of_experience` as current fact.
9. Report language = the user's communication language (session locale or
   explicit user instruction); English is the fallback — per
   `standards/cv-analysis.md` §1.
10. **LinkedIn taxonomy consistency (issue #226):** the five LinkedIn topics
    of the "Melhorias no LinkedIn" section (banner do perfil, headline
    literal, Sobre com logros, experiência com bullets, revisão de skills)
    MUST be the SAME topics of the cv-linkedin report (#223) — same labels,
    same semantics, never contradicting. Reference the outputs
    (`ocf:cv-banner`, `linkedin-optimization.md`, `linkedin-sync.json`)
    instead of duplicating their copy-paste content.
11. **Objective first (issue #222):** echo `hub.profile_objective` when
    present and calibrate the LinkedIn actions by it (`job_search` → headline
    literal com vaga + disponibilidade; `services_sales` → serviços + banner
    de oferta). Absent/ambiguous → ask one quick question or DECLARE the
    assumed objective at the top of the section — never silently, NEVER
    founder/CEO positioning for a `job_search` profile.

## tasks.json (optional)

Structured output for future traceability:

```json
{
  "generated_at": "2026-08-13",
  "score": { "global": 72, "sections": { "experience": 85, ... } },
  "tasks": [
    { "id": 1, "action": "Add metrics to Acme achievements",
      "impact": "high", "effort": "low", "priority": "P1",
      "category": "gaps", "target_role": "Senior Data Engineer" }
  ]
}
```
