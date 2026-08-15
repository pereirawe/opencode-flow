## /ocf:cv-hub-update <candidate-directory>

---
description: Update an existing candidate hub incrementally — accept new information (pasted text, new PDF, new file, or manual key-value edits), merge it into the existing hub.json without recreating the hub, re-validate, regenerate README.md, and report a diff/summary of the changes
---

Updates an existing candidate hub (`hub.json` + `README.md`) with **new
entries** — a new experience, skill, certification, project, or any other
field — without recreating the entire hub from scratch. The existing
`hub.json` is the source of truth: entries are only **added** or **updated**,
never deleted without explicit confirmation.

This is the incremental counterpart of `/ocf:cv-hub` (full build).

### Prerequisite

The candidate needs an existing hub at `~/career/<candidate-name>/hub.json`
(built with `/ocf:cv-hub`). If `hub.json` does not exist, tell the user to
run `/ocf:cv-hub` first — this command does not build hubs.

### Usage

```
/ocf:cv-hub-update ~/career/maria-silva
```

- `<candidate-directory>` — the candidate directory with an existing
  `hub.json`.

### Inputs (the new information to add)

The command accepts the new information in any of these forms (BR 2):

1. **Pasted text** — a new job, certification, project description, etc.,
   pasted by the user in the conversation.
2. **New PDF** — a new CV/PDF with additional content; extract with
   `pdftotext -layout` (same flow as `ocf:cv-hub`).
3. **New file** — a text/JSON/export file (e.g. a new certificate, a
   portfolio file, an updated LinkedIn export entry).
4. **Manual key-value edits** — the user edited `hub.json` by hand; the
   command validates the edited hub, regenerates `README.md`, and reports
   the changes.

### Flow

1. **Check the hub exists** — `~/career/<candidate-name>/hub.json`; if
   missing, tell the user to run `/ocf:cv-hub` first and stop (BR 5).
2. **Receive the new information** — collect the pasted text / PDF path /
   file path, or confirm the manual edits (BR 2).
3. **Snapshot for the diff** — before any change, record the current state
   of `hub.json` so a precise diff can be reported at the end (BR 10).
4. **Invoke the agent** `career/cv-extractor` via `task:` with the candidate
   directory, the update-mode instruction, and the new information. The
   agent loads the `cv-hub` skill (update mode — BR 9) and:
   - merges the new entries into `hub.json` (ADD or UPDATE only, BR 3);
   - detects and merges duplicates (BR 6);
   - preserves existing `[INFERIDO]` markers (BR 7).
5. **Validate** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`; fix until
   exit 0 (BR 4).
6. **Regenerate `README.md`** — from the updated `hub.json` (the README is a
   mirror, never edited manually; BR 4).
7. **Report** — the diff/summary of changes (what was added, updated, merged
   and preserved), the validation result, and the regenerated `README.md`
   path (BR 10).

### Rules

- **ADD or UPDATE only** — NEVER delete an existing entry from `hub.json`
  without the user's explicit confirmation (BR 3). Deletions are proposed,
  never applied silently.
- **Duplicates are merged, not duplicated** — same `company` + `title` +
  `start_date` in `experience`; same `name` in `skills`, `certifications`
  and `projects` (BR 6).
- **Preserve `[INFERIDO]` markers** — entries that had the marker keep it;
  new inferences are marked `[INFERIDO]` per the hub conventions (BR 7).
- Nothing is invented — data not present in the new information or the
  existing hub stays absent.
- Sensitive data (CPF, document, full address, bank) does not enter the hub.
- The flow runs 100% locally, without network.
- The command NEVER recreates `hub.json` from scratch — the existing file is
  the base for the update (BR 1).

### Report to the user

- The diff/summary of changes: entries added, updated, merged as duplicates,
  and preserved (BR 10).
- Validation result (`validate.py` exit 0).
- The regenerated `README.md` path.
