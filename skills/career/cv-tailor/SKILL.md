---
name: cv-tailor
description: Generate a resume tailored to a specific job from the candidate's hub.json. Analyzes the job (multi-portal, including LinkedIn, Indeed, Gupy, company sites — pasted text or official export files), extracts requirements/keywords, performs gap analysis vs the hub, adapts content (never fabricating) and generates the resume HTML + PDF in the job's language. Use when you need to create a custom resume for an application (command ocf:cv-tailor). Career sector.
---

# CV Tailor — job-tailored resume

Generates a version of the candidate's resume optimized for a specific job,
maximizing ATS/keyword match, using only data that already exists in
`hub.json`. Nothing is fabricated.

## Prerequisite

The candidate must have a built hub (`ocf:cv-hub` / `cv-hub` skill):
a valid `~/career/<candidate-name>/hub.json`.

## Job input

The user provides the job through one of these means:
- **Pasted text** — job description copied from any portal (recommended and
  most reliable).
- **Local file** — a file with the job description (txt, html, pdf).
- **Official LinkedIn export** — saved/viewed jobs may appear in Download My
  Data files.
- **URL** — NOT fetched: if the user pastes only a URL, ask them to paste the
  job description text instead. URLs are never downloaded — LinkedIn always
  blocks fetching and other portals may redirect to file:// (an SSRF vector).
  Never try to bypass blocking/anti-bot.

## Job analysis

Extract from the job:

1. **Required requirements** — skills, tools, certifications, languages,
   seniority, years of experience explicitly demanded.
2. **Desirable requirements** — what the job "wishes for" (nice to have).
3. **Keywords/technologies** — technical terms, products, stacks mentioned.
4. **Seniority** — junior/mid/senior/expert/lead (or inferred).
5. **Job language** — pt/en/es → defines the language of the generated resume.
6. **Company profile** — sector, size, culture (if available).

## Gap analysis vs hub

For each requirement, classify the match using the canonical match values of
`standards/cv-analysis.md` §4.1:

| Match (protocol token) | Criterion |
|------------------------|-----------|
| `atendido` | Requirement present in the hub (skill, experience, certification) |
| `parcial` | Present approximately (e.g. the job asks for Kubernetes, the hub has Docker + AWS ECS) |
| `not_met` | Requirement does not exist in the hub |

Record the result in `curriculos/<job-slug>/gap-analysis.md` following the
canonical structure of `standards/cv-analysis.md` §3.2, with the uniform gap
analysis table:

```
| Requirement | Match | Evidence in hub |
```

- `Requirement` — the requirement extracted from the job.
- `Match` — `atendido` | `parcial` | `not_met` (protocol tokens — never
  translated, never localized).
- `Evidence in hub` — citation of the hub entry supporting the match
  (e.g. `skills: Kubernetes (level: advanced)`) or a reason for the gap.

**Gap analysis language**: `gap-analysis.md` and `inferencias.md` are
analysis artifacts — they MUST be written in the language the user
communicates in (session locale or explicit user instruction; English as the
fallback), like the other career analysis outputs (resolution order in
`standards/cv-analysis.md` §1). The resume itself follows the job's language.

### Match percentage (weighted)

After classifying every requirement, compute the match percentage with
weighted scoring: **mandatory requirements weigh 2x, desirable 1x**. Only
`atendido` requirements count fully toward the met total; `parcial` counts
as half (0.5); `not_met` counts zero.

```
match_percentage = round( (Σ Met × Weight) / (Σ Total × Weight) × 100 )
```

Example: 4 mandatory + 2 desirable requirements, 3 mandatory + 1 desirable
met → `(3×2 + 1×1) / (4×2 + 2×1) × 100 = 70%`.

Record the weighted computation and the resulting percentage in
`gap-analysis.md` following the canonical match table of
`standards/cv-analysis.md` §4.5 (mandatory requirements weigh 2x, desirable
1x).

### Keyword density & coverage

AFTER generating the final resume (`index.html` and the PDF when available),
extract the FINAL resume text and compute the metrics against the job
keywords — never against the hub or the job text:

1. **Extract the text** — from `index.html` (strip the HTML tags and read
   the real selectable text) or from the PDF via `pdftotext <pdf> -` when
   available. If both sources are unavailable or empty, note the limitation
   in `gap-analysis.md` instead of inventing counts.
2. **Keyword density map** — count the occurrences of each job keyword in
   the extracted text (case-insensitive). Record `keyword → count` in
   `gap-analysis.md` following the canonical keyword density table of
   `standards/cv-analysis.md` §4.6.
3. **Coverage summary by section** — count how many job keyword occurrences
   fall in each resume section (Summary, Experience, Education, Skills,
   Certifications, Projects, Languages) and rank the sections by that count.
   Record the ranking in `gap-analysis.md` following the canonical coverage
   table of `standards/cv-analysis.md` §4.7.

These metrics complement the ATS score (`cv-ats-score` skill): the density
map here is computed at gap-analysis time on the generated resume text; the
ATS score re-computes its own keyword match on the final PDF. They must not
be duplicated or replaced by the ATS score.

## Human validation flow for inferences

Before generating the final HTML/PDF, list ALL inferences and placeholders in
`curriculos/<job-slug>/inferencias.md` following the canonical structure of
`standards/cv-analysis.md` §3.3 — the canonical inferences table:

```
| Inference | Context | Decision | Status |
```

- `Inference` — the inferred/placeholder content (with `[INFERIDO]` inline
  where the marker applies).
- `Context` — where the inference would be used (e.g. "summary — language
  level").
- `Decision` — `rephrase` | `omit` | `promote` (filled after the candidate
  decides; `-` while pending).
- `Status` — `pending` (awaiting decision) | `resolved` (candidate decided).

Ask the candidate to decide on each one:

| Decision | Action |
|----------|--------|
| `rephrase` | Rewrite the content without the `[INFERIDO]` marker (rephrasing what exists in the hub) |
| `omit` | Remove the content from the resume |
| `promote` | Use as fact only if the candidate confirms real data (no marker in the output) |

After the human decision, generate the HTML with NO `[INFERIDO]` marker. The
resolved list stays recorded in `inferencias.md` for traceability.

## Content adaptation (without fabricating)

Reorder, highlight and rephrase **only what already exists in the hub**:

- **Summary**: rewrite `summary`/`summary_i18n` to highlight the skills most
  relevant to the job (in the job's language).
- **Skills**: reorder prioritizing the job keywords. Skills with
  `importance: primary` and a job match come first.
- **Experience**: reorder achievements within each role — the ones with the
  most job relevance first. Do not remove roles; you may condense the least
  relevant ones.
- **Projects**: highlight projects using the job's technologies; mark
  `relevance: high`.
- **Certifications**: order the most relevant to the job first.
- **Sections**: omit empty sections (e.g. no certifications → omit the section).

### Hard rules

1. **NEVER invent** — experience, skills, projects, certifications, contact
   data that are not in the hub do NOT enter the resume. Only reorder,
   highlight, rephrase and condense what exists.
2. **Inferences NEVER in the final output** — `[INFERIDO]` is allowed ONLY in
   internal human-review artifacts (hub.json, gap-analysis.md, inferences
   list), per the `[INFERIDO]` convention of `standards/cv-analysis.md` §5. In
   the final HTML/PDF (`index.html`/`curriculo.pdf`) NO `[INFERIDO]` may appear
   — nor case-insensitive variants (`[inferido]`, `[Inferido]`, the
   word "inferido"). Inferred content (e.g. an unstated language level, a
   relevant project by analogy) is omitted, rephrased or approved by the
   candidate BEFORE generation. Never silently, never in the shareable artifact.
3. **Job language** — all content of the generated resume follows the job's
   language. Use `summary_i18n` when available; otherwise translate the
   summary from the hub (translating existing content is allowed — it is not
   fabrication).
4. **Contact** — include phone/email/address only if they exist in the hub.
   Sensitive data (CPF, document, bank) never.
5. **Mandatory design standard** — every resume MUST follow
   `standards/cv-design.md` (ATS, A4 print/B&W, sober style, page count by
   seniority), starting from the reference template
   `skills/career/cv-pdf/templates/resume.html` — adapt the content, NEVER
   write CSS from scratch. Before the PDF, verify conformity (standard
   checklist: semantic headings, single column, no emoji/Google Fonts,
   12–15mm margins, 1–2 pages).

## Output structure

```
~/career/<candidate-name>/curriculos/<job-slug>/
├── index.html            # resume HTML (job language)
├── curriculo.pdf         # generated A4 PDF
├── gap-analysis.md       # requirements vs hub analysis + match % + keyword density & coverage
└── inferencias.md        # resolved inferences list (human review)
```

`<job-slug>` = normalized company + title (e.g. `acme-senior-data-engineer`).

## PDF generation

1. Copy the reference template `skills/career/cv-pdf/templates/resume.html`
   to `curriculos/<job-slug>/index.html` and adapt the CONTENT (never the
   CSS) per the `standards/cv-design.md` standard: set `lang` to the job's
   language, translate the section titles, fill in the hub data and omit
   empty sections.
2. **Verify conformity with the standard** (the ATS/print/pages checklist of
   `standards/cv-design.md`) BEFORE generating the PDF: semantic headings,
   single column, no images/complex tables, no emoji/Google Fonts, `@page {
   size: A4; margin: 12mm 15mm; }`, clean `@media print`, 1–2 pages.
3. **Run the inference gate BEFORE the PDF**:
   `bash $SCRIPTS_DIR/cv/check-inference.sh index.html` — the gate MUST pass
   (exit 0) before continuing. If it fails, remove/rephrase the markers and
   run again. This gate is mandatory and cannot be skipped.
4. Run `bash $SCRIPTS_DIR/cv/pdf.sh index.html curriculo.pdf`.
5. If the script fails, report the engine error — never deliver an empty PDF.
