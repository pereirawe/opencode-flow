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
5. **Job language** — pt/en/es → defines the language of the generated resume.
6. **Company profile** — sector, size, culture (if available).

## Gap analysis vs hub

For each requirement, classify the match:

| Classification | Criterion |
|----------------|-----------|
| `met` | Skill/requirement present in the hub (skills, experience, certification) |
| `partial` | Present approximately (e.g. the job asks for Kubernetes, the hub has Docker + AWS ECS) |
| `not_met` | Requirement does not exist in the hub |

Record the result in `curriculos/<job-slug>/gap-analysis.md` with the
requirements → classification → hub evidence table.

**Gap analysis language**: `gap-analysis.md` and `inferencias.md` are
analysis artifacts — they MUST be written in the language the user
communicates in (session locale or explicit user instruction; English as the
fallback), like the other career analysis outputs. The resume itself follows
the job's language.

## Human validation flow for inferences

Before generating the final HTML/PDF, list ALL inferences and placeholders in
`curriculos/<job-slug>/inferencias.md` (one per line, with context) and ask
the candidate to decide on each one:

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
   list). In the final HTML/PDF (`index.html`/`curriculo.pdf`) NO `[INFERIDO]`
   may appear — nor case-insensitive variants (`[inferido]`, `[Inferido]`, the
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
├── gap-analysis.md       # requirements vs hub analysis
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
   `bash $SCRIPTS_DIR/cv/check-inferido.sh index.html` — the gate MUST pass
   (exit 0) before continuing. If it fails, remove/rephrase the markers and
   run again. This gate is mandatory and cannot be skipped.
4. Run `bash $SCRIPTS_DIR/cv/pdf.sh index.html curriculo.pdf`.
5. If the script fails, report the engine error — never deliver an empty PDF.
