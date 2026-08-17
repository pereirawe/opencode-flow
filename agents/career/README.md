# Career Agents

Subagent definitions for the **career** sector: resume optimization and job
application support. The sector operates on a per-candidate directory
(`~/career/<candidate-name>/`) with `hub.json` (canonical English schema) as
the single source of truth for every agent and skill.

## Agents

| Agent | Function |
|-------|----------|
| `cv-extractor` | Builds the candidate hub — extracts data from the CV PDF (required), the official LinkedIn export and optional extras into `hub.json` + `README.md`. Update mode (`ocf:cv-hub-update`) merges new information into an existing hub incrementally (ADD/UPDATE only, duplicates merged, `[INFERIDO]` preserved) |
| `cv-optimizer` | Analyzes the candidate profile from `hub.json` — profile score (0-100 per section + global), target job profiles, CLT vs PJ market salary ranges, context gaps and a prioritized action plan (`analise-perfil.md`) |
| `cv-tailor` | Analyzes a job (multi-portal) and generates a job-tailored resume PDF (HTML -> PDF) from the hub, with gap analysis, in the job's language |
| `cv-cover-letter` | Generates a tailored cover letter PDF for a job from the hub, reusing or building the gap analysis, in the job's language |
| `cv-linkedin` | Generates LinkedIn profile optimization suggestions — headline, about section, top-50 skills ranking, featured section — never scrapes or modifies LinkedIn |
| `cv-interview-prep` | Generates an interview preparation kit — likely questions, STAR answers mapped to real hub experience, questions to ask, technical topics to review |
| `cv-ats-score` | Scores the generated resume's ATS compatibility (keyword_match 40%, section_completeness 30%, format_compliance 30%) with actionable recommendations |

## Career flow

1. **Hub** — `ocf:cv-hub` (agent `career/cv-extractor`): build `hub.json` +
   `README.md` from the CV PDF (required) + official LinkedIn export
   (Download My Data, never scraping) + optional extras.
   `ocf:cv-hub-update` merges new information into an existing hub.
2. **Optimize** — `ocf:cv-optimize` (agent `career/cv-optimizer`): profile
   score, target job profiles, salary ranges, context gaps and action plan
   (`analise-perfil.md`).
3. **Tailor per job** — `ocf:cv-tailor` (agent `career/cv-tailor`):
   job-tailored resume PDF + gap analysis. Complements:
   `ocf:cv-cover-letter` (letter), `ocf:cv-linkedin` (profile suggestions),
   `ocf:cv-interview-prep` (interview kit) and `ocf:cv-ats-score` (ATS score
   of the generated resume).

## Commands

| Command | Purpose |
|---------|---------|
| `ocf:cv-hub <candidate-directory>` | Build the candidate hub (hub.json + README.md) |
| `ocf:cv-hub-update <candidate-directory>` | Incrementally update an existing hub |
| `ocf:cv-optimize <candidate-directory>` | Analyze the profile and generate the improvement plan |
| `ocf:cv-tailor <candidate-directory> <job>` | Generate a job-tailored resume PDF |
| `ocf:cv-cover-letter <candidate-directory> <job>` | Generate a tailored cover letter PDF |
| `ocf:cv-linkedin <candidate-directory> [<job>]` | Generate LinkedIn profile optimization suggestions |
| `ocf:cv-interview-prep <candidate-directory> <job>` | Generate an interview preparation kit |
| `ocf:cv-ats-score <candidate-directory> <job-slug>` | Score the generated resume's ATS compatibility |

## Shared conventions

- `hub.json` follows `scripts/cv/schema.json` (English keys) and is validated
  with `scripts/cv/validate.py` (jsonschema with a hand-rolled fallback).
- Analysis reports (`analise-perfil.md`, `gap-analysis.md`, `inferences.md`,
  `interview-preparation.md`, `linkedin-optimization.md`, `ats-score.md`)
  follow `standards/cv-analysis.md`.
- Resumes and PDFs follow `standards/cv-design.md`, starting from the
  reference template `skills/career/cv-pdf/templates/resume.html`.
- Skills live under `skills/career/*`; supporting scripts under
  `scripts/cv/*` (`pdf.sh`, `validate.py`, `check-inference.sh`,
  `migrate-schema.py`).
