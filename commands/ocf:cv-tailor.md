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
- **URL** — try `curl -L` respecting robots; LinkedIn always blocks, so in
  that case ask for pasted text. Never bypass anti-bot.

### Flow

1. **Validate hub** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`.
2. **Invoke the agent** `career/cv-tailor` via `task:` with the candidate
   directory and the job.
3. **Analyze the job** — required/desirable requirements, keywords, seniority,
   languages.
4. **Gap analysis** — requirements → met/partial/not_met table, saved in
   `curriculos/<job-slug>/gap-analysis.md` (written in the user's
   communication language).
5. **Human decision on inferences** — list all of them in
   `curriculos/<job-slug>/inferencias.md` and ask the candidate to decide on
   each (rephrase/omit/promote with real data) before the final output.
6. **Adapt content** — starting from the reference template
   `skills/career/cv-pdf/templates/resume.html`, following the
   `standards/cv-design.md` standard; reorder/highlight/condense only what
   exists in the hub; NEVER `[INFERIDO]` in the final HTML/PDF; language =
   job language.
7. **Verify conformity** with the standard (the ATS/print/pages checklist of
   `standards/cv-design.md`) before the PDF.
8. **Mandatory gate** — `bash $SCRIPTS_DIR/cv/check-inferido.sh index.html`
   MUST pass (exit 0) before the PDF.
9. **Generate the PDF** — `bash $SCRIPTS_DIR/cv/pdf.sh index.html curriculo.pdf`.

### Rules

- NEVER invent experience, skills, projects, certifications or contact.
- Layout per `standards/cv-design.md` (ATS/print/pages), starting from the
  template `skills/career/cv-pdf/templates/resume.html` — never CSS from
  scratch; verify conformity before the PDF.
- `[INFERIDO]` is allowed ONLY in internal artifacts (hub.json,
  gap-analysis.md, inferencias.md). In the final HTML/PDF NO `[INFERIDO]` may
  appear — the `check-inferido.sh` gate blocks generation.
- Contact only if present in the hub; sensitive data never.
- A4 PDF ready for ATS, clean typography, semantic headings.

### Report to the user

- Generated PDF path (`~/career/<name>/curriculos/<slug>/curriculo.pdf`).
- Gap analysis summary (met/partial/not_met requirements).
- Resolved inferences list (rephrased/omitted/promoted) the candidate
  approved — no `[INFERIDO]` marker in the shareable artifact.
