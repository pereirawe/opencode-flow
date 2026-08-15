## /ocf:cv-linkedin <candidate-directory> [<job>]

---
description: Generate LinkedIn profile optimization suggestions from the candidate hub — optimized headline (≤220 chars), about section (≤2600 chars), top-50 skills ranking and featured section recommendations, tailored to a target job or the candidate's inferred seniority/target profiles; outputs linkedin-optimization.md in the user's communication language (never scrapes or modifies LinkedIn, never fabricates)
---

Generates LinkedIn profile optimization suggestions for the candidate from
`hub.json` (built with `/ocf:cv-hub`). The suggestions cover the four
high-impact LinkedIn profile sections: **headline** (≤220 chars), **about
section** (≤2600 chars), **skills ranking** (top 50 by relevance) and
**featured section** recommendations. When a job is provided the suggestions
are optimized for that target role; without a job they follow the candidate's
inferred seniority and target job profiles (from `analise-perfil.md` when
available). Nothing is fabricated and LinkedIn is **never scraped or
modified** — the user copies/pastes the suggestions manually.

### Prerequisite

The candidate needs a valid hub at `~/career/<candidate-name>/hub.json`.
If it does not exist, run `/ocf:cv-hub` first.

### Usage

```
/ocf:cv-linkedin ~/career/maria-silva
/ocf:cv-linkedin ~/career/maria-silva "job text for the target role"
```

The optional job can be provided as:
- **Pasted text** of the description (recommended — most reliable);
- **Local file** (txt/html/pdf) with the description;
- **Official LinkedIn export** (local Download My Data files).

URLs are NOT accepted — linkedin.com is never scraped. If the user pastes a
URL, ask them to paste the job description text instead.

### Flow

1. **Validate hub** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`; if the
   hub is missing/invalid, tell the user to run `/ocf:cv-hub` first.
2. **Invoke the agent** `career/cv-linkedin` via `task:` with the candidate
   directory and the job (when provided).
3. **Determine the target role** — job provided: analyze its requirements,
   keywords and seniority; no job: read `analise-perfil.md` target job
   profiles (cv-optimizer) or infer from the hub.
4. **Generate the four suggestion blocks** — headline (≤220 chars), about
   (≤2600 chars), skills ranking (top 50 by relevance), featured section
   recommendations — from real hub data only, in the user's communication
   language per `standards/cv-analysis.md` §1.
5. **Write** `~/career/<candidate-name>/linkedin-optimization.md` following
   the `standards/cv-analysis.md` structure (exactly one H1 title, NO
   metadata header, start directly with content).

### Output

```
~/career/<candidate-name>/linkedin-optimization.md
```

Sections: Target role | Headline suggestions (≤220 chars each) | About
section draft (≤2600 chars) | Skills ranking (top 50) | Featured section
recommendations.

### Rules

- NEVER invent experience, skills, achievements or content — only rephrase,
  reorder and highlight what exists in the hub.
- NEVER scrape, access or modify linkedin.com — all output is suggestions the
  user copies/pastes manually. No URL fetching, no anti-bot bypass.
- NO `[INFERIDO]` in `linkedin-optimization.md` (nor case-insensitive
  variants, nor the word "inferido") — actionable suggestion file, same rule
  as final resume PDFs per `standards/cv-analysis.md` §5.
- Respect LinkedIn's actual limits: headline ≤220 chars, about ≤2600 chars,
  skills top 50.
- Report language = the user's communication language (never the job language
  by default).
- No sensitive data (CPF, full address, bank).

### Report to the user

- Output path (`~/career/<candidate>/linkedin-optimization.md`).
- The target role used (job title or inferred profile).
- Summary of the four blocks: headline length(s), about length, number of
  ranked skills (≤50), featured items count — no `[INFERIDO]` markers in the
  shareable suggestion file.
