---
name: cv-ats-score
description: Score the ATS compatibility of a generated resume — extracts the resume text from the generated PDF (pdftotext, best-effort), loads the job keywords from the cv-tailor gap analysis, computes keyword density, detects ATS red flags (tables, images as text, multi-column layouts, missing standard sections), and produces a 0-100 score (keyword_match 40%, section_completeness 30%, format_compliance 30%) with actionable recommendations. Outputs ats-score.md in the job's slug directory, in the user's communication language. NEVER fabricates counts or scores — every metric is computed from the actual resume text and job requirements. Use when you need to score a tailored resume against a job's ATS keywords, measure ATS compatibility, check resume format compliance, or get actionable recommendations to improve a resume's ATS match (command ocf:cv-ats-score; "pontuação ATS", "score ATS", "nota do currículo", "compatibilidade ATS", "avaliar currículo" also trigger this skill). Career sector.
---

# CV ATS Score — ATS compatibility scoring of a generated resume

Scores how well a generated resume (from `ocf:cv-tailor`) matches a job's ATS
keywords and format. Closes the generate → measure → optimize loop: the
candidate gets a measurable 0-100 score, a keyword density map, ATS red flag
detection, and actionable recommendations to improve the match before sending
the resume.

The analysis is computed from the ACTUAL files — the generated resume PDF/HTML
and the job requirements persisted by cv-tailor. Nothing is fabricated: every
count, flag and score must be reproducible from the sources.

## Prerequisite

The candidate must have a resume generated for the job slug by `ocf:cv-tailor`
(`cv-tailor` skill), producing:

```
~/career/<candidate-name>/resumes/<job-slug>/
├── curriculo.pdf         # generated A4 PDF (primary text source)
├── index.html            # resume HTML (fallback text source)
├── gap-analysis.md       # Job context + Required/Desirable requirements (keyword source)
└── inferences.md        # resolved inferences (optional context)
```

The candidate hub (`~/career/<candidate-name>/hub.json`) must exist and pass
`python3 $SCRIPTS_DIR/cv/validate.py` (exit 0). If the resume artifacts are
missing, tell the user to run `ocf:cv-tailor` for the job slug first.

## Inputs

- **Candidate directory** — `~/career/<candidate-name>/`.
- **Job slug** — the `<job-slug>` directory name under `resumes/` (the same
  slug used by cv-tailor).

## 1. Text extraction (best-effort)

1. Extract the resume text from `curriculo.pdf` with
   `pdftotext curriculo.pdf -` (single-column readable text). The PDF is the
   primary source because it is the artifact actually submitted to an ATS.
2. **pdftotext unavailable** → report the limitation in the report and fall
   back to the `index.html` text (real selectable text, same content as the
   PDF). The analysis still runs; the report notes the source used.
3. If BOTH sources are unavailable or empty, produce the report with a
   `cannot-analyze` outcome, explain why, and do not invent a score.

## 2. Keyword extraction (from the job)

Load the job keywords from `resumes/<job-slug>/gap-analysis.md`:

- **Job context** — job title, company, seniority, job language.
- **Required requirements** — the skills, technologies, certifications and
  experience the job demands.
- **Desirable requirements** — nice-to-haves and differentiators.

The keyword set = the normalized requirement terms (multi-word phrases kept
as phrases, e.g. "Google Cloud Platform", "Data Engineering"). If the user
also saved the raw job description text next to the slug directory, it may be
used to enrich the keyword set — otherwise gap-analysis.md is authoritative.

## 3. Scoring model (0-100)

The global score is 0-100, weighted:

```
global = keyword_match × 0.40
       + section_completeness × 0.30
       + format_compliance × 0.30
```

Each component is itself 0-100. Round the global score to the nearest
integer. All three components MUST be reported with their numeric value and a
textual justification.

### 3.1 keyword_match (40%)

`keyword_match = (job keywords found in resume text / total job keywords) × 100`

- A keyword counts as found when it appears in the resume text
  (case-insensitive, word-boundary aware for single terms).
- For each keyword, record the count in the resume (`0x` when missing).
- Missing keywords lower the score proportionally and MUST surface in the
  recommendations section.

### 3.2 section_completeness (30%)

`section_completeness = (standard sections detected / standard sections required) × 100`

Required standard sections (MUST be present for ATS parsing):

- Contact (name, email, phone, location)
- Experience
- Education
- Skills

Optional standard sections (detected when present, not penalized when absent
per the cv-design standard's empty-section rule): Summary, Certifications,
Projects, Languages, Áreas de Atuação.

Sections are detected from the resume text: `h2`-level headings in the HTML,
or recognizable heading blocks in the extracted PDF text (e.g. a line that is
a known section title in the job language).

### 3.3 format_compliance (30%)

Start at 100 and deduct per ATS red flag detected:

| Red flag | Deduction |
|----------|-----------|
| Complex table layout (`<table>` in HTML, or tab/grid-aligned text blocks in the PDF) | −25 |
| Images as text (`<img>` containing textual content, or text-only-in-image blocks) | −25 |
| Multi-column layout (CSS `columns`/multicol or two-column flex/grid in the HTML) | −20 |
| Missing standard section (any of the four required sections not detected) | −15 each |
| Contact not at the top / not recognizable as contact block | −10 |
| Web fonts or non-ATS-safe fonts in the HTML | −10 |
| Emoji or decorative characters in the resume text | −5 |

`format_compliance` is floored at 0. Every deduction MUST be listed in the red
flags section with evidence.

## 4. ATS red flags

Detect and report, with evidence from the resume HTML/text:

- **Tables** — any `table` element in `index.html` or grid-aligned text
  blocks in the extracted text (ATS parses in reading order; complex tables
  break parsing).
- **Images as text** — any `img` element whose content is textual (e.g. a
  logo with the candidate's name, a skill badge); real selectable text MUST
  carry the information.
- **Multi-column layouts** — CSS `columns`/multicol or two-column
  flex/grid layouts that reorder text for ATS parsing.
- **Missing standard sections** — any of contact, experience, education,
  skills not detected.
- **Other compliance issues** — web fonts (Google Fonts/remote fonts),
  emoji/decorative characters, text contrast below WCAG AA, contact block
  not at the top.

## 5. Recommendations

Actionable and specific — name the exact change, the section, and the impact:

- Keyword gaps: `Add "Kubernetes" to the skills section — it appears 5x in the
  job but 0x in your resume.`
- Format fixes: `Replace the two-column skills layout with a single-column
  list — ATS parsers read multi-column text out of order.`
- Section fixes: `Add an "Education" section heading — the education block was
  not detected as a standard section.`

Order recommendations by impact on the global score (highest first).

## Report structure

Output: `~/career/<candidate-name>/resumes/<job-slug>/ats-score.md`

Structure (per `standards/cv-analysis.md` §2 — new report type following the
same pattern as `gap-analysis.md` §3.2):

1. `H1` title — "ATS Score — <job-slug>" (or the report-language equivalent);
   NO metadata header ("Generated on:", "Source:", "Tool:", "Note:" — start
   directly with content).
2. `H2` — Job context (job title, company, seniority, job language from
   gap-analysis.md).
3. `H2` — ATS score — the canonical score table (per `standards/cv-analysis.md`
   §4.2: `Section | Score (0-100) | Justification`) with rows: `keyword_match`,
   `section_completeness`, `format_compliance`, and `Global` (the weighted
   total). A `cannot-analyze` note replaces the table when no text source is
   available.
4. `H2` — Keyword density — per-keyword lines (bullet list, not a table):
   `- Kubernetes — 5x in the job, 0x in the resume` / `- Python — 3x in the
   job, 3x in the resume`. Missing keywords listed last, each linking to its
   recommendation.
5. `H2` — ATS red flags — bullet list of detected flags, each with the
   evidence and the format_compliance deduction applied.
6. `H2` — Recommendations — ordered actionable items (highest impact first).

## Language

The report MUST be written in the language the user communicates in.
Resolution order (per `standards/cv-analysis.md` §1):

1. Explicit user instruction (when given).
2. The session/input language.
3. `.opencode/locale` in the project directory.
4. `~/.config/opencode/locale` (global fallback).
5. English.

Protocol tokens are NEVER translated: `keyword_match`,
`section_completeness`, `format_compliance`, hub.json section keys, command
names, and the `[INFERIDO]` marker.

## `[INFERIDO]` convention

`ats-score.md` is an INTERNAL analysis report (not submitted to an ATS), so
the `[INFERIDO]` marker MAY appear INLINE next to estimates, per
`standards/cv-analysis.md` §5 — e.g. an estimated ATS parse behavior
`[INFERIDO]`. It MUST NEVER appear in the shareable resume artifacts
(`index.html`, `curriculo.pdf`) — the report NEVER edits those files, and
`scripts/cv/check-inference.sh` remains the gate for the resume itself.

## Hard rules

1. **NEVER fabricate** — every count, score, flag and recommendation is
   computed from the actual resume text and gap-analysis.md. If a metric
   cannot be computed from the sources, say so instead of inventing it.
2. **Read-only** — the agent NEVER modifies `hub.json`, `gap-analysis.md`,
   `inferences.md`, `index.html` or `curriculo.pdf`. The ONLY file written is
   `ats-score.md`.
3. **No URL fetching** — the job and the resume are read from local files
   only; never fetch job descriptions from the web.
4. **Structure compliance** — exactly one H1 title, NO metadata header, only
   the canonical score table (§4.2) plus bullet lists.
5. **No sensitive data** — no CPF, full address, bank details in the report.
6. **`cannot-analyze` honesty** — when no text source is available, produce
   the report with the `cannot-analyze` outcome rather than a guessed score.

## Report to the user

Report: the output path
(`~/career/<candidate>/resumes/<job-slug>/ats-score.md`), the global score,
the breakdown (keyword_match / section_completeness / format_compliance), the
text source used (pdftotext of the PDF, or the HTML fallback with the
limitation noted), and the count of recommendations.
