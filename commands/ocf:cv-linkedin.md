## /ocf:cv-linkedin <candidate-directory> [<job>]

---
description: Generate an objective-driven LinkedIn profile action report from the candidate hub — confirmed profile objective (issue #222), 2–3 LITERAL headline variants (≤220 chars), structured Sobre/About draft (≤2600 chars) with ✔ achievement bullets and objective-aligned CTA, per-role Experiência bullets with real metrics, add/promote/remove Skills review (issue-225 linkedin-sync output or pasted list) and prioritized next steps (banner, featured, sections); outputs linkedin-optimization.md in the user's communication language (never scrapes or modifies LinkedIn, never fabricates, NO [INFERIDO] in the shareable file)
---

Generates an objective-driven LinkedIn profile action report for the
candidate from `hub.json` (built with `/ocf:cv-hub`). The report is governed
by the profile objective (`hub.profile_objective`, issue #222) and covers the
high-impact LinkedIn sections in order: **Objetivo do perfil** (confirmado),
**Headline** (2–3 literal variants ≤220 chars), **Sobre** (structured ≤2600
chars), **Experiência** (bullets per role with real metrics), **Skills**
(adicionar/promover/remover vs the real LinkedIn list) and **Próximos passos
priorizados** (banner, featured, seções). The objective is never silently
assumed — when the hub has none the report asks the user or explicitly
declares the assumed objective at the top (never founder/CEO for a
`job_search` profile). Nothing is fabricated and LinkedIn is **never scraped
or modified** — the user copies/pastes the suggestions manually.

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
- **Local file** (txt/html/pdf) with the description.

URLs are NOT accepted — linkedin.com is never scraped. If the user pastes a
URL, ask them to paste the job description text instead.

For the Skills comparison the agent uses the REAL LinkedIn skills when
available: the issue-225 `linkedin-sync.json` output
(`~/career/<candidate-name>/linkedin-sync.json`, produced from an official
Download My Data export by `scripts/cv/linkedin-sync.py` + the
`cv-linkedin-sync` skill) or a list the user pastes. Without either, the
report says so explicitly and recommends from the hub + objective keywords —
never scraped, never invented.

### Flow

1. **Validate hub** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`; if the
   hub is missing/invalid, tell the user to run `/ocf:cv-hub` first.
2. **Invoke the agent** `career/cv-linkedin` via `task:` with the candidate
   directory and the job (when provided).
3. **Determine the profile objective FIRST** (issue #222) — read
   `hub.profile_objective` (`job_search` | `connections` | `services_sales` |
   `personal_branding` + optional `target_role`/`note`); missing/ambiguous →
   quick question or explicit assumed-objective declaration at the top of the
   report. The objective governs headline wording, Sobre tone + CTA and the
   prioritized skills.
4. **Generate the six report sections** in order: Objetivo do perfil
   (confirmado), Headline (2–3 literal variants ≤220 chars with char counts),
   Sobre (structured ≤2600 chars with ✔ achievement bullets and
   objective-aligned CTA), Experiência (per-role summary + metric bullets +
   condensed responsibilities, ready to paste; metric-less achievements
   flagged as gaps), Skills (adicionar/promover/remover vs the real LinkedIn
   list, top-3 search promote, top-50 display cap) and Próximos passos
   priorizados (banner, featured, seções) — from real hub data only, in the
   user's communication language per `standards/cv-analysis.md` §1.
5. **Write** `~/career/<candidate-name>/linkedin-optimization.md` following
   the `standards/cv-analysis.md` structure (exactly one H1 title, NO
   metadata header, H2 sections in the mandated order, start directly with
   content).

### Output

```
~/career/<candidate-name>/linkedin-optimization.md
```

Sections (H2, in order): Objetivo do perfil (confirmado) | Headline (≤220
chars each) | Sobre (≤2600 chars) | Experiência (bullets por cargo) | Skills
(adicionar/promover/remover) | Próximos passos priorizados (banner, featured,
seções).

### Rules

- NEVER invent experience, skills, achievements, numbers or content — only
  rephrase, reorder and highlight what exists in the hub; metric-less
  achievements are explicit gaps, never filled with invented numbers.
- NEVER scrape, access or modify linkedin.com — all output is suggestions the
  user copies/pastes manually. No URL fetching, no anti-bot bypass, no
  export-CSV parsing here (the issue-225 sync owns that).
- NO `[INFERIDO]` in `linkedin-optimization.md` (nor case-insensitive
  variants, nor the word "inferido") — actionable suggestion file, same rule
  as final resume PDFs per `standards/cv-analysis.md` §5. Assumed content
  (e.g. an assumed objective) is declared in prose or omitted.
- Objective first — read `profile_objective`; never silently assume an
  objective; never founder/CEO positioning for a `job_search` profile.
- Respect LinkedIn's actual limits: headline ≤220 chars, Sobre ≤2600 chars,
  skills top 50 shown (top 3 most visible in search).
- Report language = the user's communication language (never the job language
  by default).
- No sensitive data (CPF, full address, bank).

### Report to the user

- Output path (`~/career/<candidate>/linkedin-optimization.md`).
- The objective used (`type` + literal target role/service; flagged "assumido"
  when assumed).
- The skills source used (sync JSON / pasted list / none).
- Section summary: headline variant lengths, Sobre length, roles covered,
  add/promote/remove counts, top next-step priorities — no `[INFERIDO]`
  markers in the shareable suggestion file.
