---
name: cv-interview-prep
description: Generate a structured interview preparation kit from the candidate's hub.json and a target job — likely interview questions (behavioral + technical), suggested STAR-format answers mapped to real hub experience, questions to ask the interviewer, and technical topics to review, with preparation gaps flagged for human review. Outputs preparacao-entrevista.md in the user's communication language. NEVER fabricates experience — STAR answers always reference real hub entries. Use when you need to prepare for a job interview, build an interview prep kit, draft STAR answers from real experience, or identify what to review before an interview (command ocf:cv-interview-prep; "preparação para entrevista", "entrevista de emprego", "entrevista" and "STAR" also trigger this skill). Career sector.
---

# CV Interview Prep — interview preparation kit

Generates a structured interview preparation kit from data that already
exists in `hub.json` plus a target job. The kit covers likely behavioral and
technical questions for the role, suggested STAR-format answers mapped to
real hub experience, questions the candidate should ask the interviewer, and
technical topics to review. Nothing is fabricated — if the hub cannot answer
a question, it becomes a flagged preparation gap.

## Prerequisite

The candidate must have a built hub (`ocf:cv-hub` / `cv-hub` skill):
a valid `~/career/<candidate-name>/hub.json`, validated with
`python3 $SCRIPTS_DIR/cv/validate.py` (exit 0 required).

## Job input

The job the candidate is preparing for is REQUIRED (unlike cv-linkedin):

- **Pasted text** — job description copied from any portal (recommended and
  most reliable).
- **Local file** — a file with the job description (txt, html, pdf).
- **Official LinkedIn export** — saved/viewed jobs may appear in Download My
  Data files.

**NEVER accept or fetch a URL for the job** — linkedin.com is never scraped
(anti-bot) and no other portal URL is fetched either. If the user pastes a
URL, ask them to paste the job description text instead.

## Job analysis

Analyze the job to derive the role the kit prepares for:

1. **Required requirements** — skills, technologies, certifications and
   experience the job demands.
2. **Desirable requirements** — nice-to-haves and differentiators.
3. **Keywords/technologies** — the stack and tools mentioned.
4. **Seniority** — junior/mid/senior/lead signals (years, scope, autonomy).
5. **Languages** — the interview/work languages.

These define the questions, STAR answers, and technical topics.

## The kit components

### 1. Likely interview questions

Two groups, each with role-appropriate questions derived from the job:

- **Behavioral** — "Tell me about a time when..." questions probing
  collaboration, conflict, failure, leadership, ownership, communication.
  Tailor the themes to the job's context (e.g. team size, product stage).
- **Technical** — questions derived from the job's required skills and
  seniority (concepts, stack specifics, architecture, problem solving).

For each question note why it is likely for THIS role (the job requirement it
probes). Never generic filler.

### 2. Suggested STAR answers

For the most likely questions, draft **Situation / Task / Action / Result**
answers mapped to REAL hub entries:

- Situation/Task — from the relevant `experience` entry (company, title,
  summary) or `projects` entry (name, description). The candidate's opening
  pitch and context phrasing may draw on the hub's `summary` (`summary_i18n`
  when available).
- Action — from the entry's `achievements`/`responsibilities` or the
  project's `impact`/`technologies`.
- Result — the measurable outcome from the entry's `achievements` or
  `impact` (metrics, percentages, scope) — as recorded in the hub.

Each answer MUST cite the hub entry it comes from (e.g.
`experience: Acme — Data Engineer (2021–present), achievement: "Reduced query
latency by 40%"`). Skills referenced in answers come from the hub `skills`
section. **NEVER invent an achievement, metric, project or outcome that is
not in the hub.**

If a question cannot be answered from real hub data, do NOT draft a fake
answer — record it in the preparation gaps section instead.

### 3. Questions to ask the interviewer

5–8 role-appropriate questions the candidate can ask: team and product,
success expectations for the role, growth, process, next steps. Generic
contextual questions only — no fabricated company knowledge.

### 4. Technical topics to review

From the job's required skills/technologies, build a review list:

- **Have from the hub** — skills the candidate already has (level/since from
  the hub's `skills`), with a note of what to refresh.
- **Gap topics** — job-required skills with no or weak hub evidence, marked
  as topics to study before the interview.

### 5. Preparation gaps

Every question, requirement or STAR angle that cannot be answered or evidenced
from the hub — listed as a preparation gap the candidate must review (e.g.
"question 'Tell me about X' — no hub evidence; add a real example or prepare
an honest answer"). This section is REQUIRED even when empty ("none").

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
(hub.json keys, command names).

## Output structure

```
~/career/<candidate-name>/preparacao-entrevista.md
```

Structure (per `standards/cv-analysis.md` §2/§3):

1. `H1` title — the report title (no metadata header: no "Generated on:",
   "Source:", "Tool:", "Note:" — start directly with content).
2. `H2` — Target role (job title, company and seniority from the job).
3. `H2` — Likely interview questions (H3 subsections: Behavioral; Technical).
4. `H2` — Suggested STAR answers (one H3 per question, with the mapped hub
   entry cited).
5. `H2` — Questions to ask the interviewer.
6. `H2` — Technical topics to review (H3 subsections: Have from the hub; Gap
   topics).
7. `H2` — Preparation gaps.

Bullet lists and simple key/value lines are the default; only simple tables
(single row semantics, no complex merges) are allowed.

## Hard rules

1. **NEVER invent** — experience, skills, achievements, projects or content
   that are not in the hub do NOT enter the kit. STAR answers MUST reference
   real hub entries (experience achievements, project impact,
   certifications, summary). No hub evidence → preparation gap.
2. **NO `[INFERIDO]` in the output file** — `preparacao-entrevista.md` is an
   actionable preparation file, not an internal analysis: the `[INFERIDO]`
   marker (and case-insensitive variants, and the word "inferido") MUST NOT
   appear, same rule as final resume PDFs per `standards/cv-analysis.md` §5.
3. **Validate the hub** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`
   must pass (exit 0) before generating the kit.
4. **Role-appropriate questions** — derived from the job's requirements and
   seniority, never generic filler.
5. **No sensitive data** — no CPF, full address, bank details.

## Report

Report to the user: the output path
(`~/career/<candidate>/preparacao-entrevista.md`), the target role used,
and a summary of the kit: question count (behavioral/technical), STAR answers
count, questions-to-ask count, technical topics count (have/gap), and
preparation gaps count — no `[INFERIDO]` markers in the actionable
preparation file.
