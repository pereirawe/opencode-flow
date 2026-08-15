---
name: cv-hub
description: Build a candidate's resume hub — extract data from the CV PDF (pdftotext), official LinkedIn export (Download My Data), and complementary files, consolidating everything into hub.json (canonical AI schema) + a human-readable README.md. Use when you need to create or update a candidate's data hub (command ocf:cv-hub). Career sector.
---

# CV Hub — building the candidate hub

Consolidates all candidate sources into a single structured hub
(`hub.json` — source of truth for AI) + `README.md` (human executive
summary). The hub is the foundation for tailored resume generation
(`cv-tailor`).

## Candidate directory structure

```
~/carreira/<candidate-name>/
├── hub.json          # canonical schema (source of truth for AI)
├── README.md         # human executive summary, generated from hub.json
├── entradas/         # original source files
│   ├── curriculo.pdf # (required)
│   ├── linkedin/     # official LinkedIn export (optional)
│   └── extras/       # certificates, portfolio, projects (optional)
└── curriculos/       # generated resumes (HTML + PDF)
```

## Inputs

| Input | Required | How to obtain |
|-------|----------|---------------|
| CV in PDF | **Yes** | Provided by the user |
| Official LinkedIn export | No | `https://www.linkedin.com/mypreferences/d/download-my-data` → option **"Baixe um arquivo de dados maior..."** (LinkedIn emails the link when ready; includes `Profile/`, `Work/`, `Education/`). Never scrape linkedin.com |
| Extras | No | Certificates, portfolio, projects, awards |

## Extraction process

1. **Receive the sources** — confirm the candidate directory and copy the
   files into `entradas/` (`curriculo.pdf`, `linkedin/`, `extras/`).
2. **Extract the PDF** — run `pdftotext -layout curriculo.pdf -` (or use
   `pdftotext curriculo.pdf out.txt`). If `pdftotext` is not available, use
   Python: `python3 -c` with `pypdf`/`PyPDF2` if installed; otherwise ask the
   user to provide the text. Never attempt OCR if the tool does not exist.
3. **Structure the LinkedIn export** — in the official export, read the files
   under `Profile/` (positions, education, skills, languages, certifications,
   projects, publications, recommendations), `Work/`, `Education/` and
   `Certifications/`. Extract them into the hub structure.
4. **Consolidate into hub.json** — use the canonical schema (definition
   below). Prefer the most recent data; record each item in **one** of the
   sources.
5. **Validate** — run `python3 $SCRIPTS_DIR/cv/validate.py hub.json`. Fix until
   exit 0.
6. **Generate README.md** — derive it from hub.json: name, title, summary,
   contact (only if present in the hub), experience, education, top skills,
   certifications, projects, languages. The README is a **mirror** — never
   edit it manually in divergence with the JSON.
   - **Language**: the README MUST be written in the hub's primary language —
     the language of the `summary` field / the language the candidate uses
     (as reflected in `summary_i18n`). English is the default when the hub
     has no clear primary language.

## Canonical hub.json schema

```json
{
  "personal_info": {
    "name": "Full Name",
    "professional_title": "Data Engineer",
    "email": "cand@email.com",
    "phone": "+55 11 99999-9999",
    "city": "São Paulo", "state": "SP", "country": "BR",
    "linkedin": "https://linkedin.com/in/...",
    "github": "https://github.com/...",
    "site": "https://...",
    "availability": "Immediate"
  },
  "summary": "executive summary",
  "summary_i18n": { "pt": "...", "en": "...", "es": "..." },
  "experience": [
    {
      "company": "Acme", "title": "Data Engineer",
      "start_date": "2021-03", "end_date": "present", "current": true,
      "summary": "...",
      "achievements": ["Reduced infrastructure cost by 30%"],
      "responsibilities": ["...", "..."],
      "technologies": ["Python", "Airflow", "dbt"]
    }
  ],
  "education": [
    { "institution": "USP", "course": "Computer Science",
      "type": "Bachelor's degree", "status": "completed" }
  ],
  "skills": [
    { "name": "Python", "category": "language", "level": "advanced",
      "since": "2018", "years_of_experience": 6, "importance": "primary" }
  ],
  "certifications": [
    { "name": "AWS Solutions Architect", "issuer": "AWS", "year": "2023" }
  ],
  "projects": [
    { "name": "open-source x", "description": "...", "technologies": ["Go"] }
  ],
  "languages": [ { "language": "English", "level": "fluent", "scale_note": "C1" } ],
  "links": [ { "name": "GitHub", "url": "https://github.com/x" } ]
}
```

All keys and enum values are English (snake_case). The schema is the
canonical structure for every locale. When migrating an existing hub built
with the legacy Portuguese keys, run
`python3 $SCRIPTS_DIR/cv/migrate-schema.py hub.json` to convert it.

### Consolidation rules

- **Deduplicate**: if the same experience appears in the CV and on LinkedIn,
  prioritize LinkedIn (more granular) and merge achievements from the CV.
- **Bilingual**: when the candidate provides summaries in more than one
  language, use `summary_i18n`. The default `summary` is the one in the
  candidate's language.
- **Skills**: whenever possible, record `since` (year of first use of the
  skill, e.g. 2018) instead of (or alongside) a fixed `years_of_experience` —
  fixed years become stale over time. If the source only allows inferring a
  start year (e.g. first project/use), record `since` and mark the inference
  `[INFERIDO]` in the description.
- **Nothing invented**: any data not present in the sources stays **absent**
  from the hub — never fill with guesses. Data inferred from context must be
  marked `[INFERIDO]` in the description.
- **Sensitive**: full address, CPF, document, bank details are NOT copied to
  the hub (only city/state/country when available).
- **Reverse chronological order** in `experience`, `education`, `projects`.

## Tools and limits

- PDF extraction: `pdftotext -layout` (preferred) → Python fallback
  (`pypdf`/`PyPDF2`) → otherwise ask the user for the text. No automatic OCR.
- No network: the hub is built 100% from local files.
- The `README.md` and `hub.json` may be committed by the user if they version
  their career; never commit anything without authorization.
