## /ocf:cv-hub <candidate-directory>

---
description: Build the candidate's resume hub — extract CV PDF + official LinkedIn export + extras into hub.json (AI canonical schema) + README.md
---

Builds a candidate's data hub from the CV in PDF (required), the official
LinkedIn export (optional) and complementary files (optional). The hub
(`hub.json` + `README.md`) is the source of truth for generating tailored
resumes via `/ocf:cv-tailor`.

### Official LinkedIn flow (only accepted way)

1. The user visits: <https://www.linkedin.com/mypreferences/d/download-my-data>
2. Chooses the option **"Baixe um arquivo de dados maior..."** (LinkedIn sends
   a link by email when the file is ready — takes a few days).
3. Unzips the `.zip` and tells the command the directory.

**NEVER** scrape linkedin.com (anonymous or logged in) — LinkedIn blocks it
and it violates the terms. Only the official export is accepted.

### Usage

```
/ocf:cv-hub ~/carreira/maria-silva
```

- If the directory does not exist, create the structure:
  `hub.json`, `README.md`, `entradas/` (curriculo.pdf, linkedin/, extras/),
  `curriculos/`.
- Ask the user where the following are: the CV PDF, the LinkedIn export
  directory (if any) and the extras (if any).

### Flow

1. **Collect sources** — the user provides the file paths; copy them into
   `entradas/`.
2. **Invoke the agent** `career/cv-extractor` via `task:` with the candidate
   directory and the source paths.
3. **Extract and consolidate** — the agent runs `pdftotext -layout` on the
   PDF, structures the LinkedIn export, consolidates everything into
   `hub.json` (canonical schema) and generates `README.md`.
4. **Validate** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`; fix until exit 0.
5. **Report** — `hub.json` path, whether validation passed, and a summary of
   the populated sections. Tell the user the next step is `/ocf:cv-tailor`.

### Rules

- Minimum input: CV in PDF. LinkedIn and extras are optional.
- Nothing is invented — missing data stays missing; inferences are marked
  `[INFERIDO]`.
- Sensitive data (CPF, document, full address) does not enter the hub.
- The flow runs 100% locally, without network.
