## /ocf:cv-ats-score <candidate-directory> <job-slug>

---
description: Score the ATS compatibility of a generated resume against the job's requirements — extracts the resume text from the PDF (pdftotext, best-effort), loads job keywords from the cv-tailor gap analysis, computes keyword density, detects ATS red flags (tables, images as text, multi-column layouts, missing standard sections), produces a 0-100 score (keyword_match 40%, section_completeness 30%, format_compliance 30%) with actionable recommendations; outputs ats-score.md in the job's slug directory, in the user's communication language
---

Scores how well a generated resume (from `/ocf:cv-tailor`) matches a job's
ATS keywords and format, closing the generate → measure → optimize loop. The
resume PDF is analyzed with `pdftotext` (best-effort), the job keywords come
from the cv-tailor gap analysis, and the output is a 0-100 score broken down
into **keyword_match (40%)**, **section_completeness (30%)** and
**format_compliance (30%)**, plus **ATS red flag detection** and **actionable
recommendations**. Nothing is fabricated: every count, flag and score is
computed from the actual resume text and job requirements.

### Prerequisite

The candidate needs a valid hub at `~/career/<candidate-name>/hub.json`
(built with `/ocf:cv-hub`) AND a resume generated for the job slug by
`/ocf:cv-tailor`:

```
~/career/<candidate-name>/resumes/<job-slug>/
├── <FirstName> <LastName> - <JobTitle>.pdf   # generated A4 PDF (primary text source; cv-tailor commercial name)
├── index.html            # resume HTML (fallback text source)
└── gap-analysis.md       # Job context + Required/Desirable requirements
```

If the hub is missing, run `/ocf:cv-hub` first; if the resume artifacts are
missing, run `/ocf:cv-tailor` for the job slug first.

### Usage

```
/ocf:cv-ats-score ~/career/maria-silva backend-engineer-remote
```

- `<candidate-directory>` — the candidate directory with `hub.json`.
- `<job-slug>` — the slug directory name under
  `~/career/<candidate>/resumes/` (the same slug used by cv-tailor).

### Flow

1. **Verify artifacts** — check `resumes/<job-slug>/` contains the generated
   resume PDF (named `<FirstName> <LastName> - <JobTitle>.pdf` per the
   cv-tailor commercial name rule — locate it by listing the `*.pdf` files),
   plus `index.html` and `gap-analysis.md`; missing → tell the user to run
   `/ocf:cv-tailor` for the job slug first.
2. **Validate hub** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`; if the
   hub is missing/invalid, tell the user to run `/ocf:cv-hub` first.
3. **Invoke the agent** `career/cv-ats-score` via `task:` with the candidate
   directory and the job slug.
4. **Extract resume text** — `pdftotext "<resume pdf>" -` on the located
   resume PDF (best-effort; if `pdftotext` is unavailable, report the
   limitation and fall back to the `index.html` text; no source →
   `cannot-analyze` outcome, never an invented score).
5. **Load job keywords** — from `resumes/<job-slug>/gap-analysis.md`
   (Job context + Required/Desirable requirements).
6. **Analyze** —
   - Keyword density (job keywords found vs total, per-keyword counts);
   - ATS red flags (tables, images as text, multi-column layouts, missing
     standard sections — contact, experience, education, skills);
   - Score 0-100: `keyword_match` (40%), `section_completeness` (30%),
     `format_compliance` (30%), global weighted total.
7. **Write** `~/career/<candidate-name>/resumes/<job-slug>/ats-score.md`
   in the user's communication language per `standards/cv-analysis.md` §1,
   following the standard's structure (exactly one H1 title, NO metadata
   header, start directly with content; canonical score table per §4.2; H2
   sections: Job context, ATS score, Keyword density, ATS red flags,
   Recommendations).

### Output

```
~/career/<candidate-name>/resumes/<job-slug>/ats-score.md
```

Sections: Job context | ATS score | Keyword density | ATS red flags |
Recommendations.

### Rules

- NEVER fabricate counts, scores, flags or recommendations — every metric is
  computed from the actual resume text and gap-analysis.md.
- The agent is read-only besides the report: it NEVER modifies `hub.json`,
  `gap-analysis.md`, `inferences.md`, `index.html` or the generated resume
  PDF.
- `[INFERIDO]` MAY appear inline in `ats-score.md` (internal analysis report
  per `standards/cv-analysis.md` §5) — never in the shareable resume
  artifacts.
- Report language = the user's communication language.
- Recommendations MUST be actionable and specific (e.g. "Add 'Kubernetes' to
  the skills section — it appears 5x in the job but 0x in your resume").
- No URL fetching — local files only. No sensitive data (CPF, full address,
  bank).

### Report to the user

- Output path (`~/career/<candidate>/resumes/<job-slug>/ats-score.md`).
- The global score and the breakdown (keyword_match / section_completeness /
  format_compliance).
- The text source used (pdftotext of the PDF, or the HTML fallback with the
  limitation noted).
- The count of recommendations.
