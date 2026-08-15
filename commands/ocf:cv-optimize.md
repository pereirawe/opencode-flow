## /ocf:cv-optimize <candidate-directory>

---
description: Analyze the candidate profile and generate an improvement plan — profile score, target job profiles, CLT vs PJ salary ranges, context gaps, and a prioritized action plan (analise-perfil.md + PDF)
---

Analyzes a candidate's profile from the hub (built with `/ocf:cv-hub`) and
generates an optimization report: per-section profile score, general
qualifications, target job profiles, CLT vs PJ market salary ranges
(`[INFERIDO]` bands), context gaps and a prioritized action plan. The goal is
to improve the profile substantially before generating tailored resumes with
`/ocf:cv-tailor`.

### Usage

```
/ocf:cv-optimize ~/carreira/maria-silva
```

### Flow

1. **Check the hub** — if `~/carreira/<candidate>/hub.json` does not exist or
   is invalid, invoke the `/ocf:cv-hub` flow first (asking for the source
   paths) and then continue.
2. **Validate** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`.
3. **Invoke the agent** `career/cv-optimizer` via `task:` with the candidate
   directory.
4. **Analyze** — the agent produces `analise-perfil.md` with:
   - Profile score (0-100 per section + global, with justification)
   - General qualifications (seniority, skills, strengths/weaknesses)
   - Target job profiles (offline — never concrete jobs)
   - CLT vs PJ salary ranges (all `[INFERIDO]` for human review)
   - Context gaps in the hub
   - Prioritized action plan (impact × effort)
5. **Generate the PDF** — the agent renders `analise-perfil.html` and runs
   `bash $SCRIPTS_DIR/cv/pdf.sh` to produce `analise-perfil.pdf` (A4), making
   reading/analysis easier.
6. **Report** — report paths (.md and .pdf), global score, top actions and
   the `[INFERIDO]` items the candidate should review.

### Rules

- NO invented data — every inference marked `[INFERIDO]`.
- The agent does NOT modify `hub.json` — it only reports.
- No web search — target job profiles are generic profiles derived from the
  offline analysis.
- No sensitive data appears in the report.
- NO metadata header in the report ("Generated on:", "Source:", "Tool:",
  "Note:") — start directly with the content; `[INFERIDO]` inline.
- Skill years of experience computed dynamically (current year − `since`)
  whenever `since` exists in the hub.
- Report language = the language the user communicates in (session locale or
  explicit user instruction; English as the fallback).
