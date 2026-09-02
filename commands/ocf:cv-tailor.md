## /ocf:cv-tailor <candidate-directory> <job>

---
description: Generate a job-tailored resume PDF from the candidate hub — analyze the job, gap analysis vs hub.json, adapt content (never fabricate), HTML -> PDF in the job's language
---

Generates a version of the candidate's resume optimized for a specific job,
from the candidate's `hub.json` (built with `/ocf:cv-hub`). It analyzes the
job, performs the gap analysis vs the hub, adapts the content **without
fabricating anything** and produces the resume in PDF (HTML → PDF via Chrome
headless, LibreOffice fallback) in the job's language.

### Prerequisite

The candidate needs a valid hub at `~/career/<candidate-name>/hub.json`.
If it does not exist, run `/ocf:cv-hub` first.

### Usage

```
/ocf:cv-tailor ~/career/maria-silva "job URL or text"
```

The job can be provided as:
- **Pasted text** of the description (recommended — most reliable);
- **Local file** (txt/html/pdf) with the description;
- **Official LinkedIn export** (local Download My Data files);
- **URL** — not fetched: ask the user to paste the job description text
  (URL fetching is removed — LinkedIn always blocks it and redirects may
  point to file://, an SSRF vector). Never bypass anti-bot.

### Flow

1. **Validate hub** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`.
2. **Invoke the agent** `career/cv-tailor` via `task:` with the candidate
   directory and the job.
3. **Analyze the job** — required/desirable requirements, keywords, seniority,
   languages.
4. **Gap analysis** — uniform table `Requirement | Match | Evidence in hub`
   (match values `atendido`/`parcial`/`not_met` per
   `standards/cv-analysis.md` §4.1) + the weighted match percentage
   (mandatory requirements weigh 2x, desirable 1x per §4.5), saved in
   `resumes/<job-slug>/gap-analysis.md` (written in the user's
   communication language).
5. **Application gate** — compare the weighted match percentage with
   `preferences.min_match_percentage` (default **70%** when the hub has none).
   If match < threshold → the agent writes `resumes/<job-slug>/feedback.md`
   (per `standards/cv-analysis.md` §3.5) explaining why it is not worth
   applying and asks the candidate to decide (proceed anyway / stop); no
   resume is generated unless the candidate overrides. If match ≥ threshold →
   proceed directly WITHOUT confirmation.
6. **Human decision on inferences** — list all of them in
   `resumes/<job-slug>/inferences.md` per `standards/cv-analysis.md`
   §3.3/§4.4 (table `Inference | Context | Decision | Status`) and ask the
   candidate to decide on each (rephrase/omit/promote with real data) before
   the final output.
7. **Adapt content** — starting from the reference template
   `skills/career/cv-pdf/templates/resume.html`, following the
   `standards/cv-design.md` standard; reorder/highlight/condense only what
   exists in the hub; prioritize quantified achievements (numbers/% first,
   metric prominent — never invented); NEVER `[INFERIDO]` in the final
   HTML/PDF; language = job language.
8. **Verify conformity** with the standard (the ATS/print/pages checklist of
   `standards/cv-design.md`) before the PDF.
9. **Mandatory gate** — `bash $SCRIPTS_DIR/cv/check-inference.sh index.html`
   MUST pass (exit 0) before the PDF.
10. **Generate the PDF** — name the final PDF `<FirstName> <LastName> -
    <JobTitle>.pdf` (first + last name tokens from `hub.json →
    personal_info.name`, ASCII-normalized — `João` → `Joao` —, job title in
    the job's language, Title Case on main words, ` - ` separator; fallbacks
    `<job-slug>.pdf` when the name is unavailable / `<FirstName> <LastName> -
    Resume.pdf` when the title is unavailable — see the cv-tailor skill,
    "PDF filename" rule) and run
    `bash $SCRIPTS_DIR/cv/pdf.sh index.html "<FirstName> <LastName> - <JobTitle>.pdf"`.
11. **Gap-analysis metrics** — after the PDF, extract the FINAL resume text
    (`index.html` stripped of HTML tags, or the PDF via `pdftotext` when
    available) and record the keyword density map (`Keyword | Count in
    resume`) and the coverage summary by section in `gap-analysis.md` per
    `standards/cv-analysis.md` §4.6/§4.7. Never invent counts.

### Rules

- NEVER invent experience, skills, projects, certifications or contact.
- Layout per `standards/cv-design.md` (ATS/print/pages), starting from the
  template `skills/career/cv-pdf/templates/resume.html` — never CSS from
  scratch; verify conformity before the PDF.
- `[INFERIDO]` is allowed ONLY in internal artifacts (hub.json,
  gap-analysis.md, inferences.md) per `standards/cv-analysis.md` §5. In the
  final HTML/PDF NO `[INFERIDO]` may appear — the `check-inference.sh` gate
  blocks generation.
- Contact only if present in the hub; sensitive data never.
- A4 PDF ready for ATS, clean typography, semantic headings.

### Report to the user

- Generated PDF path (`~/career/<name>/resumes/<slug>/<FirstName> <LastName> - <JobTitle>.pdf`).
- Gap analysis summary (`atendido`/`parcial`/`not_met` requirements) and the
  weighted match percentage.
- Application gate decision: blocked (`feedback.md` written, candidate's
  decision) or approved (match ≥ threshold, no confirmation needed).
- Keyword density map and coverage summary by section (computed from the
  generated resume text).
- Resolved inferences list (rephrased/omitted/promoted) the candidate
  approved — no `[INFERIDO]` marker in the shareable artifact.
