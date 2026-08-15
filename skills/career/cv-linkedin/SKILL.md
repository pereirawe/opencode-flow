---
name: cv-linkedin
description: Generate LinkedIn profile optimization suggestions from the candidate's hub.json — optimized headline (≤220 chars), about section (≤2600 chars), top-50 skills ranked by relevance, and featured section recommendations, tailored to a target job or to the candidate's inferred seniority/target profiles (from analise-perfil.md when available). Outputs linkedin-optimization.md in the user's communication language. NEVER scrapes or modifies LinkedIn — the user copies/pastes suggestions manually, and nothing is fabricated. Use when you need to optimize a LinkedIn profile for a target role or improve recruiter discoverability (command ocf:cv-linkedin; "otimização do perfil LinkedIn", "otimizar linkedin" and "melhorar linkedin" also trigger this skill). Career sector.
---

# CV LinkedIn — LinkedIn profile optimization suggestions

Generates actionable LinkedIn profile optimization suggestions from data that
already exists in `hub.json`. The four suggestion blocks (headline, about,
skills ranking, featured section) help the candidate improve recruiter
discoverability and match a target role. Nothing is fabricated and LinkedIn
is never scraped or modified — the user copies/pastes the suggestions
manually.

## Prerequisite

The candidate must have a built hub (`ocf:cv-hub` / `cv-hub` skill):
a valid `~/career/<candidate-name>/hub.json`, validated with
`python3 $SCRIPTS_DIR/cv/validate.py` (exit 0 required).

## Optional job input

The user may provide a target job to optimize the suggestions for that role:

- **Pasted text** — job description copied from any portal (recommended and
  most reliable).
- **Local file** — a file with the job description (txt, html, pdf).
- **Official LinkedIn export** — saved/viewed jobs may appear in Download My
  Data files.

**NEVER accept or fetch a URL for the job** — linkedin.com is never scraped
(anti-bot) and no other portal URL is fetched either. If the user pastes a
URL, ask them to paste the job description text instead.

When NO job is provided, read
`~/career/<candidate-name>/analise-perfil.md` (cv-optimizer output) and use
its target job profiles and inferred seniority when available; otherwise
infer seniority and target profiles from the hub itself.

## Target role determination

1. **Job provided** — analyze the job: required/desirable requirements,
   keywords/technologies, seniority, languages. These define the target role
   the suggestions optimize for.
2. **No job provided** — use the target job profiles and inferred seniority
   from `analise-perfil.md` (cv-optimizer) when present; otherwise infer from
   the hub (seniority from experience depth/titles, target profiles from the
   dominant skills and achievements).

## The four suggestion blocks

### 1. Headline (≤220 characters)

LinkedIn headlines are limited to **220 characters**. Suggest 2–3 candidate
headlines (choose or refine the best fit), each ≤220 chars, that combine:
current role, top differentiators (from the hub: seniority, key skills,
specialty), and 1–2 target-role keywords. Count characters explicitly and
state the length for each suggestion.

### 2. About section (≤2600 characters)

LinkedIn about sections are limited to **2600 characters**. Draft the about
text (≤2600 chars, state the length) rephrasing the hub's `summary`
(`summary_i18n` when available) and the achievements most relevant to the
target role. Structure suggestion: opening hook → core expertise → notable
achievements (real metrics/projects from the hub) → closing call-to-action.
NEVER invent achievements.

### 3. Skills ranking (top 50)

LinkedIn profiles allow up to **50 skills**. Rank the hub's skills by
relevance to the target role (skills matching the job's required keywords
first; `level`/`since` considered when present), capped at **top 50**. For
each ranked skill, note the target-role keyword it matches (or mark it as a
differentiator). Suggest which skills to add/promote and which are
lower-priority for this role.

### 4. Featured section

Recommendations of hub content worth featuring (LinkedIn's Featured section):
projects with links (from `projects`), certifications (`certifications`),
and relevant achievements. For each: what to feature, why it matters for the
target role, and a suggested caption (short, factual, no fabrication).

## Language

The report MUST be written in the language the user communicates in.
Resolution order (per `standards/cv-analysis.md` §1):

1. Explicit user instruction (when given).
2. The session/input language.
3. `.opencode/locale` in the project directory.
4. `~/.config/opencode/locale` (global fallback).
5. English.

The report language is the USER's communication language — NOT the job
language (unlike resumes/cover letters). Protocol tokens are never translated
(`atendido`/`parcial`/`not_met`, hub.json keys, command names).

## Output structure

```
~/career/<candidate-name>/linkedin-optimization.md
```

Structure (per `standards/cv-analysis.md` §2/§3):

1. `H1` title — the report title (no metadata header: no "Generated on:",
   "Source:", "Tool:", "Note:" — start directly with content).
2. `H2` — Target role (the job title or inferred profile the suggestions
   optimize for).
3. `H2` — Headline suggestions (≤220 chars each, with length stated).
4. `H2` — About section draft (≤2600 chars, with length stated).
5. `H2` — Skills ranking (top 50, ordered by relevance).
6. `H2` — Featured section recommendations.

Bullet lists and simple key/value lines are the default; only simple tables
(single row semantics, no complex merges) are allowed.

## Hard rules

1. **NEVER invent** — experience, skills, achievements, certifications or
   content that are not in the hub do NOT enter the suggestions. Only
   rephrase, reorder and highlight what exists.
2. **NEVER scrape or modify LinkedIn** — no URL fetching of linkedin.com
   (nor of any portal), no anti-bot bypass, no direct profile edits. All
   output is suggestions the user copies/pastes manually.
3. **NO `[INFERIDO]` in the output file** — `linkedin-optimization.md` is an
   actionable suggestion file, not an internal analysis: the `[INFERIDO]`
   marker (and case-insensitive variants, and the word "inferido") MUST NOT
   appear, same rule as final resume PDFs per `standards/cv-analysis.md` §5.
   Inferred content is omitted or rephrased from the hub — never silently
   included.
4. **Validate the hub** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`
   must pass (exit 0) before generating suggestions.
5. **Respect LinkedIn's limits** — headline ≤220 chars, about ≤2600 chars,
   skills top 50.
6. **No sensitive data** — no CPF, full address, bank details.

## Report

Report to the user: the output path
(`~/career/<candidate>/linkedin-optimization.md`), the target role used
(job title or inferred profile), and a summary of the four blocks: headline
length(s), about length, number of ranked skills (≤50), and featured items
count — no `[INFERIDO]` markers in the shareable suggestion file.
