## /ocf:cv-optimize <candidate-directory>

---
description: Analyze the candidate profile and generate an improvement plan — profile score, target job profiles, CLT vs PJ salary ranges, context gaps, integrated objective-calibrated LinkedIn improvements (banner/headline/Sobre/experiência/skills consistent with cv-linkedin) and a prioritized action plan (profile-analysis.md + PDF)
---

Analyzes a candidate's profile from the hub (built with `/ocf:cv-hub`) and
generates an optimization report: per-section profile score, general
qualifications, target job profiles, CLT vs PJ market salary ranges
(`[INFERIDO]` bands), context gaps, an integrated **"Melhorias no LinkedIn"**
section (banner/headline/Sobre/experiência/skills, calibrated by the profile
objective and consistent with the `ocf:cv-linkedin` taxonomy) and a
prioritized action plan. The goal is
to improve the profile substantially before generating tailored resumes with
`/ocf:cv-tailor`.

### Usage

```
/ocf:cv-optimize ~/career/maria-silva
```

### Flow

1. **Check the hub** — if `~/career/<candidate>/hub.json` does not exist or
   is invalid, invoke the `/ocf:cv-hub` flow first (asking for the source
   paths) and then continue.
2. **Validate** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`.
3. **Invoke the agent** `career/cv-optimizer` via `task:` with the candidate
   directory.
4. **Analyze** — the agent produces `profile-analysis.md` following the
   canonical structure of `standards/cv-analysis.md` (§3.1, tables §4.2/§4.3):
   - Profile score (0-100 per section + global, with justification —
     domain-relative criteria per the skill's §3 priority table)
   - General qualifications (detected domain(s), seniority, skills,
     strengths/weaknesses)
   - Target job profiles (offline — never concrete jobs)
   - CLT vs PJ salary ranges (all `[INFERIDO]` for human review)
   - Context gaps in the hub
   - Melhorias no LinkedIn (H2 — objective-calibrated, five cv-linkedin
     topics: banner via `ocf:cv-banner`, headline literal, Sobre com logros,
     experiência com bullets, revisão de skills com o diff da issue 225)
   - Prioritized action plan (impact × effort) — every LinkedIn item mirrored
     as an action row with the artifact/output to produce
5. **Objective handling** (issue #222) — read `hub.profile_objective`
   (`job_search` | `connections` | `services_sales` | `personal_branding` +
   optional `target_role`/`note`): present → echo at the top of the LinkedIn
   section and calibrate the items (`job_search` → headline literal com vaga
   + disponibilidade; `services_sales` → serviços + banner de oferta);
   absent/ambiguous → ask one quick question or declare the assumed objective
   explicitly — never silently, never founder/CEO for a `job_search` profile.
6. **Generate the PDF** — the agent renders `profile-analysis.html` from the
   reference template
   `skills/career/cv-optimizer/templates/profile-analysis.html` (adapt content,
   never the CSS — sharing the resume's design language per
   `standards/cv-design.md`; the template contains the "Melhorias no
   LinkedIn" section) and runs `bash $SCRIPTS_DIR/cv/pdf.sh` to produce
   `profile-analysis.pdf` (A4), making reading/analysis easier.
7. **Report** — report paths (.md and .pdf), global score, top actions and
   the `[INFERIDO]` items the candidate should review.

### Rules

- NO invented data — every inference marked `[INFERIDO]`.
- The agent does NOT modify `hub.json` — it only reports.
- No web search — target job profiles are generic profiles derived from the
  offline analysis.
- No sensitive data appears in the report.
- Report structure per `standards/cv-analysis.md`: NO metadata header in the
  report ("Generated on:", "Source:", "Tool:", "Note:") — start directly with
  the content; canonical tables (score, action plan); `[INFERIDO]` inline.
- Skill years of experience computed dynamically (current year − `since`)
  whenever `since` exists in the hub.
- Report language = the language the user communicates in (session locale or
  explicit user instruction; English as the fallback) — per
  `standards/cv-analysis.md` §1.
- LinkedIn consistency (issue #226): the five LinkedIn topics of the
  "Melhorias no LinkedIn" section == the cv-linkedin taxonomy (#223); the
  items reference `ocf:cv-banner` / `linkedin-optimization.md` /
  `linkedin-sync.json` instead of duplicating their copy-paste content.
- Objective first (issue #222): echo `hub.profile_objective` and calibrate
  the LinkedIn actions; absent → ask or explicitly declare the assumed
  objective — never founder/CEO for a `job_search` profile. No `[INFERIDO]`
  leakage into LinkedIn copy: this report only recommends actions and
  references the copy-paste-ready files.
