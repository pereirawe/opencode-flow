# Career Agents

Subagent definitions for the **career** sector: resume optimization and job
application support. The sector operates on a per-candidate directory
(`~/career/<candidate-name>/`) with `hub.json` (canonical English schema) as
the single source of truth for every agent and skill.

## Agents

| Agent | Function |
|-------|----------|
| `cv-extractor` | Builds the candidate hub — extracts data from the CV PDF (required), the official LinkedIn export and optional extras into `hub.json` + `README.md`. Update mode (`ocf:cv-hub-update`) merges new information into an existing hub incrementally (ADD/UPDATE only, duplicates merged, `[INFERIDO]` preserved) |
| `cv-optimizer` | Analyzes the candidate profile from `hub.json` — profile score (0-100 per section + global), target job profiles, CLT vs PJ market salary ranges, context gaps, a prioritized action plan and an integrated **"Melhorias no LinkedIn"** section (banner, headline, sobre, experiência, skills) calibrated by the profile objective (`profile-analysis.md` + PDF) |
| `cv-tailor` | Analyzes a job (multi-portal) and generates a job-tailored resume PDF (HTML -> PDF) from the hub, with gap analysis, in the job's language |
| `cv-cover-letter` | Generates a tailored cover letter PDF for a job from the hub, reusing or building the gap analysis, in the job's language |
| `cv-linkedin` | Generates an objective-driven LinkedIn action report — confirmed profile objective, literal headline (≤220), structured Sobre with ✔ metric bullets (≤2600), per-role Experiência bullets and an add/promote/remove Skills review (against the real LinkedIn list via `cv-linkedin-sync` or a pasted list) — never scrapes or modifies LinkedIn, nothing fabricated, no `[INFERIDO]` in the shareable file |
| `cv-interview-prep` | Generates an interview preparation kit — likely questions, STAR answers mapped to real hub experience, questions to ask, technical topics to review |
| `cv-ats-score` | Scores the generated resume's ATS compatibility (keyword_match 40%, section_completeness 30%, format_compliance 30%) with actionable recommendations |

## Career flow

1. **Hub** — `ocf:cv-hub` (agent `career/cv-extractor`): build `hub.json` +
   `README.md` from the CV PDF (required) + official LinkedIn export
   (Download My Data, never scraping) + optional extras.
   `ocf:cv-hub-update` merges new information into an existing hub.
2. **Optimize** — `ocf:cv-optimize` (agent `career/cv-optimizer`): profile
   score, target job profiles, salary ranges, context gaps and action plan —
   including the integrated **LinkedIn improvements** (banner, headline, sobre,
   experiência, skills) calibrated by the profile objective
   (`profile-analysis.md`).
3. **LinkedIn improvements** — run the profile's LinkedIn actions when
   applicable: `ocf:cv-linkedin` (objective-driven six-section action report),
   `ocf:cv-banner` (4:1 banner via each::sense) and `cv-linkedin-sync`
   (offline hub ↔ LinkedIn diff to feed the add/promote/remove skills review).
4. **Tailor per job** — `ocf:cv-tailor` (agent `career/cv-tailor`):
   job-tailored resume PDF + gap analysis. Complements:
   `ocf:cv-cover-letter` (letter), `ocf:cv-interview-prep` (interview kit) and
   `ocf:cv-ats-score` (ATS score of the generated resume).

## Commands

| Command | Purpose |
|---------|---------|
| `ocf:cv-hub <candidate-directory>` | Build the candidate hub (hub.json + README.md) |
| `ocf:cv-hub-update <candidate-directory>` | Incrementally update an existing hub |
| `ocf:cv-optimize <candidate-directory>` | Analyze the profile and generate the improvement plan (incl. LinkedIn improvements) |
| `ocf:cv-tailor <candidate-directory> <job>` | Generate a job-tailored resume PDF |
| `ocf:cv-cover-letter <candidate-directory> <job>` | Generate a tailored cover letter PDF |
| `ocf:cv-linkedin <candidate-directory> [<job>]` | Generate the objective-driven LinkedIn action report |
| `ocf:cv-banner <candidate-directory> [direction]` | Generate the LinkedIn profile banner (4:1) via each::sense |
| `ocf:cv-interview-prep <candidate-directory> <job>` | Generate an interview preparation kit |
| `ocf:cv-ats-score <candidate-directory> <job-slug>` | Score the generated resume's ATS compatibility |

## Shared conventions

- `hub.json` follows `scripts/cv/schema.json` (English keys) and is validated
  with `scripts/cv/validate.py` (jsonschema with a hand-rolled fallback).
- Analysis reports (`profile-analysis.md`, `gap-analysis.md`, `inferences.md`,
  `interview-preparation.md`, `linkedin-optimization.md`, `linkedin-sync.md`,
  `linkedin-sync.json`, `ats-score.md`) follow `standards/cv-analysis.md`.
- Resumes and PDFs follow `standards/cv-design.md`, starting from the
  reference template `skills/career/cv-pdf/templates/resume.html`.
- Skills live under `skills/career/*` (`cv-hub`, `cv-optimizer`, `cv-tailor`,
  `cv-cover-letter`, `cv-linkedin`, `cv-linkedin-banner`, `cv-linkedin-sync`,
  `cv-interview-prep`, `cv-ats-score`, `cv-pdf`); supporting scripts under
  `scripts/cv/*` (`pdf.sh`, `validate.py`, `check-inference.sh`,
  `linkedin-sync.py`, `banner-gen.sh`, `migrate-schema.py`).
