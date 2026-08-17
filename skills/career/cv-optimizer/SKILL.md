---
name: cv-optimizer
description: Analyze and optimize a candidate's profile from hub.json — general qualifications, profile score (0-100 per section + global), target job profiles, CLT vs PJ market salary ranges ([INFERIDO] bands), context gaps, and a prioritized action plan. Use when you need to analyze and improve a candidate's profile (command ocf:cv-optimize). Career sector.
---

# CV Optimizer — profile analysis and improvement plan

Analyzes the candidate's `hub.json` (built by `cv-hub`) and produces an
actionable report with profile score, target job profiles, market salary
ranges and a prioritized action plan. The goal is to **improve the profile
substantially** before generating tailored resumes (`cv-tailor`).

## Prerequisite

A valid `~/career/<candidate-name>/hub.json` (validated by
`python3 $SCRIPTS_DIR/cv/validate.py`). If it does not exist, the `ocf:cv-hub`
flow must run first (the `ocf:cv-optimize` command already handles this).

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
6. **Prioritized action plan**

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
   clean typography, semantic headings, no metadata header).
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

Score each section based on **completeness and strength**:

| Section | Scoring criteria |
|---------|------------------|
| personal_info | name + contact + location + professional links present |
| summary | summary present, clear, with differentiators; ideally bilingual (summary_i18n) |
| experience | titles with dates, summary, achievements (metrics = bonus) |
| education | complete institutions/courses, defined status |
| skills | quantity, explicit level, categories, `since`/years of experience (bonus: `since` present — allows computing years dynamically) |
| certifications | present, with issuer and year |
| projects | present, with description and link (link = bonus) |
| languages | present, with formal level (scale_note = bonus) |
| links | at least LinkedIn + GitHub/site |

Rules:
- Each empty section = 0. Each section with minimal data = 40-60. Complete
  sections = 70-90. With differentiators (metrics, links, formal notes) = 90-100.
- Global score = weighted average (experience and skills weigh more: 1.5x).
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

### 7. Prioritized action plan

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
target-job gaps (courses/certifications/languages), positioning.

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
