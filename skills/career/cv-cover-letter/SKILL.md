---
name: cv-cover-letter
description: Generate a tailored cover letter for a specific job from the candidate's hub.json and a job description. Analyzes the job (multi-portal, including LinkedIn, Indeed, Gupy, company sites — pasted text, local files, official LinkedIn export, or URL), extracts requirements/keywords, reuses or builds the gap analysis vs the hub, drafts the letter in the job's language (never fabricating — only rephrasing and highlighting real hub achievements) and generates the letter HTML + PDF. Use when you need to create a custom cover letter for an application (command ocf:cv-cover-letter; "carta de apresentação" also triggers this skill). Career sector.
---

# CV Cover Letter — job-tailored cover letter

Generates a tailored cover letter for a specific job application, using only
data that already exists in `hub.json`. The letter is a persuasive, concise
complement to the tailored resume (`cv-tailor`): it highlights the
achievements most relevant to the job's key requirements. Nothing is
fabricated.

## Prerequisite

The candidate must have a built hub (`ocf:cv-hub` / `cv-hub` skill):
a valid `~/career/<candidate-name>/hub.json`.

## Job input

The user provides the job through one of these means (same formats as
cv-tailor):

- **Pasted text** — job description copied from any portal (recommended and
  most reliable).
- **Local file** — a file with the job description (txt, html, pdf).
- **Official LinkedIn export** — saved/viewed jobs may appear in Download My
  Data files.
- **URL** — if the user pastes only a URL, try to download the content with
  `curl -L` respecting robots. If the portal blocks (LinkedIn always blocks),
  ask for pasted text. NEVER try to bypass blocking/anti-bot.

## Job analysis

Extract from the job:

1. **Required requirements** — skills, tools, certifications, languages,
   seniority, years of experience explicitly demanded.
2. **Desirable requirements** — what the job "wishes for" (nice to have).
3. **Keywords/technologies** — technical terms, products, stacks mentioned.
4. **Seniority** — junior/mid/senior/expert/lead (or inferred).
5. **Job language** — pt/en/es → defines the language of the cover letter.
6. **Company profile** — sector, size, culture (if available).

## Gap analysis — reuse or build

The gap analysis tells you which requirements the candidate already meets, so
the letter can highlight the strongest matches.

- **Reuse**: if `~/career/<candidate-name>/resumes/<job-slug>/gap-analysis.md`
  exists (produced by cv-tailor for the same job), load it and use its
  `atendido`/`parcial` matches to select the achievements to highlight.
- **Build inline**: otherwise, classify each requirement against the hub using
  the canonical match values of `standards/cv-analysis.md` §4.1:

  | Match (protocol token) | Criterion |
  |------------------------|-----------|
  | `atendido` | Requirement present in the hub (skill, experience, certification) |
  | `parcial` | Present approximately (e.g. the job asks for Kubernetes, the hub has Docker + AWS ECS) |
  | `not_met` | Requirement does not exist in the hub |

  When built inline, record the result in
  `cartas/<job-slug>/gap-analysis.md` following the canonical structure of
  `standards/cv-analysis.md` §3.2, with the uniform gap analysis table:

  ```
  | Requirement | Match | Evidence in hub |
  ```

  - `Requirement` — the requirement extracted from the job.
  - `Match` — `atendido` | `parcial` | `not_met` (protocol tokens — never
    translated, never localized).
  - `Evidence in hub` — citation of the hub entry supporting the match
    (e.g. `skills: Kubernetes (level: advanced)`) or a reason for the gap.

**Gap analysis language**: `gap-analysis.md` and `inferences.md` are
analysis artifacts — they MUST be written in the language the user
communicates in (session locale or explicit user instruction; English as the
fallback), like the other career analysis outputs (resolution order in
`standards/cv-analysis.md` §1). The cover letter itself follows the job's
language.

## Application gate (recommend-or-proceed)

The same gate as cv-tailor applies BEFORE the letter is drafted:

1. **Reuse**: when reusing `resumes/<job-slug>/gap-analysis.md` from
   cv-tailor, ALSO reuse its gate decision. If cv-tailor blocked the offer
   (match < threshold) and the candidate did not override, the letter is NOT
   generated — point the candidate to the cv-tailor `feedback.md`. The
   candidate can still override to proceed. The override is persisted in
   cv-tailor's `feedback.md` (Recommendation section: decision `proceed
   anyway`); READ that decision to determine whether the candidate overrode —
   never assume.
2. **Build inline**: when the gap analysis is built here, compute the
   weighted match percentage (mandatory 2x, desirable 1x, per
   `standards/cv-analysis.md` §4.5) and compare with
   `preferences.min_match_percentage` (default **70** when absent):
   - match < threshold → write `cartas/<job-slug>/feedback.md` (canonical
     §3.5 of `standards/cv-analysis.md`) explaining why it is not worth
     applying (match vs threshold, `not_met`/`parcial` drag, and dealbreakers
     from `preferences.dislikes`/`excluded_roles`) and ask the candidate to
     decide (proceed anyway / stop).
   - match ≥ threshold → proceed directly WITHOUT asking for confirmation;
     record the gate decision in the gap analysis.

`feedback.md` is an internal analysis artifact — the `check-inference.sh` gate
applies only to the final letter HTML/PDF.

## Human validation flow for inferences

Before generating the final HTML/PDF, list ALL inferences and placeholders in
`cartas/<job-slug>/inferences.md` following the canonical structure of
`standards/cv-analysis.md` §3.3 — the canonical inferences table:

```
| Inference | Context | Decision | Status |
```

- `Inference` — the inferred/placeholder content (with `[INFERIDO]` inline
  where the marker applies).
- `Context` — where the inference would be used (e.g. "opening — motivation
  for the role").
- `Decision` — `rephrase` | `omit` | `promote` (filled after the candidate
  decides; `-` while pending).
- `Status` — `pending` (awaiting decision) | `resolved` (candidate decided).

Ask the candidate to decide on each one:

| Decision | Action |
|----------|--------|
| `rephrase` | Rewrite the content without the `[INFERIDO]` marker (rephrasing what exists in the hub) |
| `omit` | Remove the content from the letter |
| `promote` | Use as fact only if the candidate confirms real data (no marker in the output) |

After the human decision, generate the HTML with NO `[INFERIDO]` marker. The
resolved list stays recorded in `inferences.md` for traceability.

## Drafting the letter (without fabricating)

The cover letter is a short, persuasive document (roughly 250–450 words)
structured as:

1. **Header** — candidate name and contact (from the hub, only if present).
2. **Date and recipient** — date of the application and the role/company
   (from the job, not metadata).
3. **Opening** — the role applied for and a single sentence that captures the
   candidate's fit.
4. **Body (2–3 paragraphs)** — for each of the job's key requirements,
   reference a SPECIFIC achievement from the hub that demonstrates it (e.g.
   "In my role as X at Acme I led the migration that reduced cost by 30% —
   the same profile as your Senior Platform Engineer opening"). Use real
   numbers, project names and outcomes from the hub — never invented ones.
   **Quantified achievements (numbers/%) are the strongest evidence**: prefer
   a metric-carrying achievement over a qualitative one whenever the hub has
   one for the requirement, and keep the number prominent in the phrasing.
5. **Closing** — enthusiasm for the role/company, availability for an
   interview, and a professional sign-off with the candidate's name.

### Hard rules

1. **NEVER invent** — experience, skills, achievements, project outcomes or
   contact data that are not in the hub do NOT enter the letter. Only
   rephrase, highlight and reorder what exists.
2. **Inferences NEVER in the final output** — `[INFERIDO]` is allowed ONLY in
   internal human-review artifacts (hub.json, gap-analysis.md, inferencias
   list), per the `[INFERIDO]` convention of `standards/cv-analysis.md` §5. In
   the final HTML/PDF (`index.html`/`carta-apresentacao.pdf`) NO `[INFERIDO]`
   may appear — nor case-insensitive variants (`[inferido]`, `[Inferido]`,
   the word "inferido"). Inferred content (e.g. an unstated language level, a
   relevant project by analogy) is omitted, rephrased or approved by the
   candidate BEFORE generation. Never silently, never in the shareable
   artifact.
3. **Job language** — all content of the generated letter follows the job's
   language. Use `summary_i18n` when available; otherwise translate the
   relevant content from the hub (translating existing content is allowed —
   it is not fabrication).
4. **Contact** — include phone/email/address only if they exist in the hub.
   Sensitive data (CPF, document, bank) never.
5. **Mandatory design standard** — every letter MUST follow
   `standards/cv-design.md` (ATS, A4 print/B&W, sober style), starting from
   the reference template `skills/career/cv-pdf/templates/resume.html` —
   adapt the content and structure, NEVER write CSS from scratch. Before the
   PDF, verify conformity (standard checklist: semantic headings, single
   column, no emoji/Google Fonts, 12–15mm margins, fits one page).

## Output structure

```
~/career/<candidate-name>/cartas/<job-slug>/
├── index.html            # cover letter HTML (job language)
├── carta-apresentacao.pdf  # generated A4 PDF
├── gap-analysis.md       # requirements vs hub analysis (when built inline)
├── inferences.md        # resolved inferences list (human review)
└── feedback.md          # gate feedback (ONLY when match < threshold) — why not worth applying + candidate decision
```

`feedback.md` exists only when the application gate blocked the offer
(match < `preferences.min_match_percentage`); it records the candidate's
decision (proceed anyway / stop).

`<job-slug>` = normalized company + title (e.g. `acme-senior-data-engineer`).

## PDF generation

1. Copy the reference template `skills/career/cv-pdf/templates/resume.html`
   to `cartas/<job-slug>/index.html` and adapt the CONTENT and STRUCTURE
   (never the CSS) per the `standards/cv-design.md` standard: set `lang` to
   the job's language, structure the letter (header, date, opening, body,
   closing), fill in the hub data.
2. **Verify conformity with the standard** (the ATS/print/pages checklist of
   `standards/cv-design.md`) BEFORE generating the PDF: semantic headings,
   single column, no images/complex tables, no emoji/Google Fonts, `@page {
   size: A4; margin: 12mm 15mm; }`, clean `@media print`, fits one page.
3. **Run the inference gate BEFORE the PDF**:
   `bash $SCRIPTS_DIR/cv/check-inference.sh index.html` — the gate MUST pass
   (exit 0) before continuing. If it fails, remove/rephrase the markers and
   run again. This gate is mandatory and cannot be skipped.
4. Run `bash $SCRIPTS_DIR/cv/pdf.sh index.html carta-apresentacao.pdf`.
5. If the script fails, report the engine error — never deliver an empty PDF.

## Report

Report to the user: the PDF path
(`~/career/<candidate>/cartas/<slug>/carta-apresentacao.pdf`), the gap
analysis summary (reused or inline, `atendido`/`parcial`/`not_met`) and the
list of resolved inferences (rephrased/omitted/promoted) the candidate
approved — no `[INFERIDO]` marker in the shareable artifact.
