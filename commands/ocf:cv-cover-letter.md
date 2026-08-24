## /ocf:cv-cover-letter <candidate-directory> <job>

---
description: Generate a job-tailored cover letter PDF from the candidate hub — analyze the job, reuse or build the gap analysis vs hub.json, draft the letter (never fabricate, highlight real achievements), HTML -> PDF in the job's language
---

Generates a tailored cover letter for a specific job application, from the
candidate's `hub.json` (built with `/ocf:cv-hub`). It analyzes the job, reuses
the gap analysis from cv-tailor when available (or builds it inline), drafts
the letter **without fabricating anything** — highlighting the specific hub
achievements that match the job's key requirements — and produces the letter
in PDF (HTML → PDF via Chrome headless, LibreOffice fallback) in the job's
language.

### Prerequisite

The candidate needs a valid hub at `~/career/<candidate-name>/hub.json`.
If it does not exist, run `/ocf:cv-hub` first.

### Usage

```
/ocf:cv-cover-letter ~/career/maria-silva "job URL or text"
```

The job can be provided as:
- **Pasted text** of the description (recommended — most reliable);
- **Local file** (txt/html/pdf) with the description;
- **Official LinkedIn export** (local Download My Data files);
- **URL** — try `curl -L` respecting robots; LinkedIn always blocks, so in
  that case ask for pasted text. Never bypass anti-bot.

### Flow

1. **Validate hub** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`; if the
   hub is missing/invalid, tell the user to run `/ocf:cv-hub` first.
2. **Invoke the agent** `career/cv-cover-letter` via `task:` with the
   candidate directory and the job.
3. **Analyze the job** — required/desirable requirements, keywords, seniority,
   languages, company profile.
4. **Gap analysis** — reuse `resumes/<job-slug>/gap-analysis.md` from
   cv-tailor when available; otherwise build it inline (uniform table
   `Requirement | Match | Evidence in hub`, match values
   `atendido`/`parcial`/`not_met` per `standards/cv-analysis.md` §4.1), saved
   in `cartas/<job-slug>/gap-analysis.md` (written in the user's communication
   language).
5. **Application gate** — compare the weighted match percentage with
   `preferences.min_match_percentage` (default **70%** when the hub has none).
   When reusing cv-tailor's gap analysis, reuse its gate decision (a blocked
   offer without override — read the `proceed anyway` decision persisted in
   cv-tailor's `feedback.md` — is NOT generated). When built inline: match <
   threshold → `cartas/<job-slug>/feedback.md` (per `standards/cv-analysis.md`
   §3.5) + candidate decision (proceed anyway / stop); match ≥ threshold →
   proceed directly WITHOUT confirmation.
6. **Human decision on inferences** — list all of them in
   `cartas/<job-slug>/inferences.md` per `standards/cv-analysis.md`
   §3.3/§4.4 (table `Inference | Context | Decision | Status`) and ask the
   candidate to decide on each (rephrase/omit/promote with real data) before
   the final output.
7. **Draft the letter** — in the job's language, referencing SPECIFIC
   achievements from the hub that match the job's key requirements, preferring
   quantified achievements (numbers/% prominent) when the hub has them; NEVER
   fabricate; starting from the reference template
   `skills/career/cv-pdf/templates/resume.html`, following the
   `standards/cv-design.md` standard; NEVER `[INFERIDO]` in the final HTML/PDF.
8. **Verify conformity** with the standard (the ATS/print/pages checklist of
   `standards/cv-design.md`) before the PDF.
9. **Mandatory gate** — `bash $SCRIPTS_DIR/cv/check-inference.sh index.html`
   MUST pass (exit 0) before the PDF.
10. **Generate the PDF** —
    `bash $SCRIPTS_DIR/cv/pdf.sh index.html carta-apresentacao.pdf`.

### Output

```
~/career/<candidate-name>/cartas/<job-slug>/
├── index.html             # cover letter HTML (job language)
├── carta-apresentacao.pdf # generated A4 PDF
├── gap-analysis.md        # requirements vs hub analysis (when built inline)
└── inferences.md         # resolved inferences list (human review)
```

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

- Generated PDF path
  (`~/career/<candidate>/cartas/<slug>/carta-apresentacao.pdf`).
- Gap analysis summary (reused or inline, `atendido`/`parcial`/`not_met`).
- Application gate decision: blocked (`feedback.md` written, candidate's
  decision) or approved (match ≥ threshold, no confirmation needed).
- Resolved inferences list (rephrased/omitted/promoted) the candidate
  approved — no `[INFERIDO]` marker in the shareable artifact.
