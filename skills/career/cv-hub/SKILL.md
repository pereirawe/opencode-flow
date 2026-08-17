---
name: cv-hub
description: Build a candidate's resume hub — extract data from the CV PDF (pdftotext), official LinkedIn export (Download My Data), and complementary files, consolidating everything into hub.json (canonical AI schema) + a human-readable README.md. Update mode (command ocf:cv-hub-update) merges new information into an existing hub.json incrementally — ADD/UPDATE only, duplicates merged, [INFERIDO] preserved. Use when you need to create or update a candidate's data hub (commands ocf:cv-hub, ocf:cv-hub-update). Career sector.
---

# CV Hub — building the candidate hub

Consolidates all candidate sources into a single structured hub
(`hub.json` — source of truth for AI) + `README.md` (human executive
summary). The hub is the foundation for tailored resume generation
(`cv-tailor`).

## Candidate directory structure

```
~/career/<candidate-name>/
├── hub.json          # canonical schema (source of truth for AI)
├── README.md         # human executive summary, generated from hub.json
├── entradas/         # original source files
│   ├── curriculo.pdf # (required)
│   ├── linkedin/     # official LinkedIn export (optional)
│   └── extras/       # certificates, portfolio, projects (optional)
└── resumes/       # generated resumes (HTML + PDF)
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

## README.md template

`README.md` is the human-readable **mirror** of `hub.json` — it MUST be
generated from the hub and never edited manually in divergence. The canonical
structure (sections appear ONLY when the hub has data for them):

```markdown
# <name> — <professional_title>

## Contact
- Phone: <phone>                (only when present in the hub)
- Email: <email>                (only when present in the hub)
- Location: <city>, <state> — <country>
- LinkedIn: <linkedin>
- GitHub: <github>
- Site: <site>

## Summary
<summary> (the hub's primary-language summary — from `summary` or
`summary_i18n`)

## Experience
### <title> — <company>
<start_date> — <end_date> · <location> · <type>
- <achievement / responsibility bullet>

## Education
### <course> — <institution>
<start_date> — <end_date> · <status>

## Skills
- <name> (<level>, since <since>) — grouped by <category> when present

## Certifications
- <name> — <issuer> (<year>)

## Projects
### <name>
<description> · <link> · <technologies>

## Languages
- <language> (<level> — <scale_note>)

## Links
- <name>: <url>
```

Rules:

1. Section order mirrors the hub: name + title, contact, summary, experience,
   education, skills, certifications, projects, languages, links.
2. Empty sections are omitted (e.g. no certifications → no `## Certifications`).
3. Contact fields appear only when present in `personal_info`; sensitive data
   (CPF, document, bank details) never.
4. The README language follows the hub's primary language (the `summary`
   field / `summary_i18n`; English is the default when the hub has no clear
   primary language).

## Tools and limits

- PDF extraction: `pdftotext -layout` (preferred) → Python fallback
  (`pypdf`/`PyPDF2`) → otherwise ask the user for the text. No automatic OCR.
- No network: the hub is built 100% from local files.
- The `README.md` and `hub.json` may be committed by the user if they version
  their career; never commit anything without authorization.

## Update mode (`ocf:cv-hub-update`)

The update mode extends the build flow above for **incremental edits** to an
existing hub. It NEVER recreates `hub.json` from scratch — the existing file
is the base for the update.

### When to use update mode

- The user wants to add **new entries** to an existing hub: a new
  experience, skill, certification, project, language, or link.
- The user provides **new information** in any of these forms:
  1. **Pasted text** — a new job, certification, project description, etc.
  2. **New PDF** — extract with `pdftotext -layout` (same flow as the build
     mode).
  3. **New file** — a text/JSON/export file (e.g. a new certificate, a
     portfolio file).
  4. **Manual key-value edits** — the user edited `hub.json` by hand; the
     command validates the edited hub, regenerates `README.md`, and reports
     the changes.

### Update-mode process

1. **Verify the hub exists** — `hub.json` must exist in the candidate
   directory. If it does not, tell the user to run `ocf:cv-hub` first and
   stop. Update mode never builds a hub.
2. **Collect the new information** — pasted text, new PDF (pdftotext), new
   file, or the user's manual edits.
3. **Snapshot for the diff** — record the current state of `hub.json`
   (or a per-section summary) BEFORE any change, so the final diff/summary
   is precise.
4. **Merge into the existing hub** — follow the build-mode extraction and
   consolidation rules (schema above, consolidation rules below), but apply
   them to the EXISTING entries:
   - **ADD** new entries into their section (`experience`, `education`,
     `skills`, `certifications`, `projects`, `languages`, `links`, ...),
     keeping reverse chronological order where applicable.
   - **UPDATE** existing entries with corrected/more recent data when the
     new information supersedes them.
5. **Validate** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`; fix until
   exit 0.
6. **Regenerate `README.md`** — derive it from the UPDATED `hub.json` (same
   rules as the build mode: mirror, never edited manually).
7. **Report the diff/summary** — entries added, updated, merged as
   duplicates, and preserved (BR 10 of the hub-update issue).

### Update-mode rules

- **ADD or UPDATE only — NEVER delete** an existing entry without the user's
  explicit confirmation. If a deletion seems needed (e.g. duplicated entry,
  outdated role), PROPOSE it and wait for explicit approval — never apply
  silently.
- **Duplicates are detected and merged, not duplicated**:
  - `experience`: same `company` + `title` + `start_date` → merge into one
    entry (union of achievements/responsibilities/technologies, prefer the
    most complete version).
  - `skills`, `certifications`, `projects`: same `name` → merge into one
    entry (union of fields, prefer the most complete version).
  - `education`: same `institution` + `course` → merge.
  - `languages`: same `language` → merge.
  - `links`: same `name` (or same `url`) → merge.
- **Preserve existing `[INFERIDO]` markers** — an entry that already carries
  the marker KEEPS it after an update; only the candidate can remove it by
  confirming real data. New inferences introduced by the update are marked
  `[INFERIDO]` inline per the build-mode conventions.
- Nothing is invented — data not present in the new information or the
  existing hub stays absent.
- Sensitive data (CPF, document, full address, bank details) does not enter
  the hub — including in updates.
- The update never touches other candidate artifacts (resumes/, cartas/,
  reports) — it only updates `hub.json` and regenerates `README.md`.
