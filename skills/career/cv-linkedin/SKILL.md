---
name: cv-linkedin
description: Generate an objective-driven LinkedIn profile action report from the candidate's hub.json — confirmed profile objective (issue #222 profile_objective), 2–3 LITERAL headline variants (≤220 chars) naming the target role/services, a structured Sobre/About draft (≤2600 chars) opening with a hook and listing ✔ achievement bullets, per-role Experiência bullets with real metrics ready to paste into the role description, an add/promote/remove Skills review (against the real LinkedIn list from the issue-225 linkedin-sync output or a user-pasted list) and prioritized next steps (banner, featured, sections). Outputs linkedin-optimization.md in the user's communication language. NEVER scrapes or modifies LinkedIn — the user copies/pastes suggestions manually; nothing is fabricated; NO [INFERIDO]/"inferido" in the shareable file. Use when you need to optimize a LinkedIn profile for a target role or improve recruiter discoverability (command ocf:cv-linkedin; "otimização do perfil LinkedIn", "otimizar linkedin", "melhorar linkedin" also trigger this skill). Career sector.
---

# CV LinkedIn — objective-driven LinkedIn profile action report

Generates an actionable LinkedIn profile action report (`linkedin-optimization.md`)
from data that already exists in `hub.json`. The report is **driven by the
candidate's profile objective** (issue #222 — `hub.profile_objective`): the
objective decides the literal headline wording, the Sobre tone and closing
CTA, the experience highlights and the prioritized skills. The report sections
(headline, Sobre/About, Experiência, Skills, next steps) turn the LinkedIn
training the user received into concrete copy/paste-ready actions. Nothing is
fabricated and LinkedIn is never scraped or modified — the user copies/pastes
the suggestions manually.

## Prerequisite

The candidate must have a built hub (`ocf:cv-hub` / `cv-hub` skill):
a valid `~/career/<candidate-name>/hub.json`, validated with
`python3 $SCRIPTS_DIR/cv/validate.py` (exit 0 required).

## Optional inputs

- **Target job (pasted text or local file)** — when the candidate is in
  `job_search`, a job description refines the literal target title and the
  1–2 target keywords of the headline. **NEVER accept or fetch a URL** —
  linkedin.com is never scraped (anti-bot) and no other portal URL is fetched
  either; if the user pastes a URL, ask them to paste the job description text
  instead.
- **`profile-analysis.md`** (cv-optimizer output) — target profiles/seniority
  context when available.
- **The candidate's REAL LinkedIn skills** — needed for the Skills section
  comparison. Two legitimate sources (never scraped):
  1. **`~/career/<candidate-name>/linkedin-sync.json`** — produced by the
     issue-225 offline sync (`scripts/cv/linkedin-sync.py` +
     `skills/career/cv-linkedin-sync/SKILL.md`) when the user processed an
     official LinkedIn "Download My Data" export. This skill CONSUMES that
     JSON (`sections.skills.recommendations[]`) — it never re-implements the
     export parsing.
  2. **A list the user pastes** of their current LinkedIn skills.
  When the user has an export but no `linkedin-sync.json` yet, point them to
  the sync flow (issue-225 skill/script) or ask for the pasted list — never
  parse the export CSVs here and never scrape linkedin.com.

## Report language

The report MUST be written in the language the user communicates in.
Resolution order (per `standards/cv-analysis.md` §1):

1. Explicit user instruction (when given).
2. The session/input language.
3. `.opencode/locale` in the project directory.
4. `~/.config/opencode/locale` (global fallback).
5. English.

The report language is the USER's communication language — NOT the job
language (unlike resumes/cover letters). Section headings and the Sobre
draft's block names are rendered in that language (PT canonical names below;
translate the headings/blocks when the report runs in another language,
keeping the meaning and order). Protocol tokens are never translated
(hub.json keys, `profile_objective.type` values, command names,
`[INFERIDO]` — which is banned here anyway).

## Step 1 — Determine the objective FIRST (never silently)

Before any suggestion, read `hub.profile_objective` (issue #222):

- `type` — closed enum: `job_search` (looking for a job) | `connections`
  (building a network) | `services_sales` (selling services) |
  `personal_branding` (building a personal brand).
- `target_role` — optional literal target role(s)/service(s) in the
  candidate's words (e.g. `"Tech Leader"`, `"Tech Lead PHP/Laravel"`).
- `note` — optional context (e.g. `"unemployed, immediate availability,
  remote"`).

Resolution:

1. **Present and clear** → use it as the confirmed objective.
2. **Missing or ambiguous** → ask the user ONE quick question (the four
   `type` options + literal target roles/services). If they do not answer,
   **explicitly state the assumed objective at the top of the report**
   (H2 "Objetivo do perfil") for confirmation — never proceed silently.
3. **NEVER assume founder/CEO positioning** when the candidate is in
   `job_search` (a founder/CEO angle can hurt a job-search profile). When the
   type is `job_search`, the positioning is the target role's — literal job
   titles, availability, results that a recruiter for that role looks for.

The objective governs the whole report: headline wording, Sobre tone + CTA,
which experience achievements lead, and the prioritized skills.

Objective → positioning reference (rules are deterministic over the hub, never
fabricated):

| `type` | headline/tone logic | Sobre closing CTA |
| --- | --- | --- |
| `job_search` | literal target role title(s) + seniority + differentiators; tone = open to opportunities | availability for the role / apply invitation (e.g. open to a Tech Leader position) |
| `services_sales` | literal offered service(s) + differentiator; tone = solution/offer | contact / quote invitation |
| `connections` | professional identity that invites conversation | invitation to connect / exchange |
| `personal_branding` | identity/niche statement | invitation to follow / share / engage |

## Step 2 — Write the report

Output path:

```
~/career/<candidate-name>/linkedin-optimization.md
```

Structure (per `standards/cv-analysis.md` §3.4): exactly one `H1` title (the
report title — no metadata header: no "Generated on:", "Source:", "Tool:",
"Note:" — start directly with content), then the six `H2` sections in this
mandated order:

1. `H2` — **Objetivo do perfil** (confirmado — Profile objective)
2. `H2` — **Headline**
3. `H2` — **Sobre** (About)
4. `H2` — **Experiência** (Experience)
5. `H2` — **Skills**
6. `H2` — **Próximos passos priorizados** (Prioritized next steps)

(The H2 headings are rendered in the report language; the PT forms above are
canonical for this flow — translate "Objetivo do perfil"/"Sobre"/
"Experiência"/"Próximos passos priorizados" only when the report runs in
another language, preserving order and meaning.)

Bullet lists and simple key/value lines are the default; only simple tables
(single row semantics, no complex merges) are allowed.

### H2 1 — Objetivo do perfil (confirmado)

Key/value lines stating the objective used to drive the report:

- `Tipo:` — the `profile_objective.type` value (e.g. `job_search`).
- `Objetivo:` — short sentence in the report language (e.g. "conseguir uma
  vaga como Tech Leader").
- `Cargo/serviço alvo:` — the literal `target_role` when present.
- `Contexto:` — the `note` when present (e.g. availability).
- One line: "Todo o relatório (headline, Sobre, skills priorizadas, CTA)
  segue este objetivo."

When the objective was ASSUMED (missing/ambiguous and the user did not
answer), this section opens with the explicit declaration — e.g. "Objetivo
assumido para este relatório: `job_search` como Tech Leader — confirme se
não for o caso." — never a silent assumption, never founder/CEO for a
job_search. When the user answered the quick question, record the confirmed
objective here.

### H2 2 — Headline (literal, ≤220 characters each)

LinkedIn headlines are limited to **220 characters**. Produce **2–3 variants**
(each ≤220 chars — count the characters and state the count per variant),
combining:

1. the target role/service names **LITERALLY** — `job_search` → the actual
   job titles the profile targets (from `profile_objective.target_role` or
   the provided job, e.g. "Tech Leader", "Tech Lead Laravel/PHP");
   `services_sales` → the offered services by their real names;
2. seniority (from real hub titles/experience);
3. real differentiators from the hub (specialty/stack/domain/scale);
4. 1–2 target keywords (from the job text when provided).

The role/service names come verbatim from the hub/job — never paraphrased into
a generic label. Example shape: `Tech Leader | Laravel/PHP | +120 clientes |
Liderança de times` — content always real. State the character count for each
variant and indicate the recommended one for the objective.

### H2 3 — Sobre (About, ≤2600 characters)

LinkedIn about sections are limited to **2600 characters**. Draft ONE about
text (≤2600 chars — state the length) in the candidate's voice, following the
proven high-converting structure below. The structure follows the reference
example pattern; the TEXT is always the candidate's own — never copy anyone
else's text, only rephrase/highlight what exists in the hub:

1. **Opening hook line** — provocative/positioning first line built from real
   facts (years of experience, scale, results, domain).
2. **One-line value logic** — the logic of the work in one sentence (e.g.
   "Minha atuação segue uma lógica clara: Experiência do Cliente → Adoção →
   Retenção e Expansão").
3. **Headline achievements as ✔ bullets** — real metrics/achievements from the
   hub only, in `action → quantified result` format (e.g. "+7 anos liderando
   times de produto", "+120 clientes atendidos", "+R$ 1.8M em receita
   gerada"). Numbers never invented; a duration computed from hub dates is
   factual and allowed.
4. **Optional block "E como isso acontece na prática?"** — real methods/tools
   from the hub (how the work is done).
5. **Languages / certifications / current learning** when present in the hub.
6. **Optional "palavras que me definem" line**.
7. **Closing CTA aligned with the objective** (per the Step-1 reference):
   `job_search` → availability/open to the role; `services_sales` → invitation
   to quote/contact; `connections` → invitation to connect;
   `personal_branding` → invitation to follow/engage.

If the hub lacks quantified achievements, add a short "antes de publicar"
(gap) note after the draft — e.g. "adicionar resultado quantificado em X" —
so the pasted text never contains fabricated numbers and the gaps are
visible. Block names above (e.g. "E como isso acontece na prática?") are
rendered in the report language.

### H2 4 — Experiência (bullets per role, ready to paste)

For **each relevant role** in the hub (relevant = aligned with the objective
or recent; the candidate decides what to paste), produce:

- **Role summary** — `title — company (period)`, from the hub, no invention.
- **Achievement bullets with metrics** — from the hub's `achievements` for the
  role (rephrased `action → quantified result`); every number exists in the
  hub or is derived from hub dates.
- **Condensed responsibility bullets** — the role's responsibilities (from the
  hub) condensed into short paste-ready bullets.

All bullets are ready to paste into the LinkedIn role description field
(plain text lines, no markdown decorations). Hub achievements WITHOUT metrics
→ mark explicitly as a gap in a separate line — "adicionar resultado
quantificado" — NEVER invent a number to fill it. Roles without metrics keep
responsibility bullets only, with the gap flagged.

### H2 5 — Skills (adicionar / promover / remover)

LinkedIn shows the **top 50** skills on a profile and the **top 3** are the
most visible (recruiter search/preview). Recommend against the candidate's
REAL LinkedIn skills when one of the sources from "Optional inputs" exists:

- **`linkedin-sync.json` present (issue 225)** — consume
  `sections.skills.recommendations[]` (each item carries `name`, `side`,
  `action`, `priority`, `reason`; actions: `add_to_linkedin`,
  `add_to_hub`, `remove_from_linkedin`, `promote_on_linkedin`, `keep`).
  Render three lists:
  - **Adicionar** — hub skills absent from LinkedIn (`add_to_linkedin`) and
    objective keywords missing from both sides (add them to the hub AND
    LinkedIn).
  - **Promover ao topo (top 3 de busca)** — skills relevant to the
    objective/target role (`promote_on_linkedin`, `consistent` + relevant):
    pick the best 3 to move to the top of the LinkedIn ranking.
  - **Despriorizar/remover** — `remove_from_linkedin` items (the sync only
    recommends removal when a declared objective exists) and low-relevance
    skills to move down.
  Note per the sync count semantics: spoken languages recorded in
  `hub.languages` are handled by the languages section, never proposed as
  skill adds. Human review stays needed for `keep`/`no_hub_reference` items.
- **User-pasted list present** — perform the same comparison manually
  (add/promote/remove vs the hub + objective keywords).
- **NO LinkedIn source** — say so explicitly ("comparação com a lista real de
  skills do LinkedIn não realizada — rode o sync do export oficial (issue 225)
  ou cole a lista atual de skills do LinkedIn") and recommend from the hub +
  objective keywords only: which hub skills to add and which to promote to the
  top 3. NEVER invent the candidate's LinkedIn list.

The whole Skills section respects the display cap: after adds, the promoted/
prioritized top of the list must fit LinkedIn's top-50 display and the top 3
must be the objective-relevant ones.

### H2 6 — Próximos passos priorizados

An ordered, prioritized action list (P1 high / P2 medium / P3 low) so the
user executes the report after the LinkedIn training. Each item: the action,
the rationale tied to the objective, and the priority. A simple table
(`Ação | Porquê | Prioridade`) is allowed. Cover at minimum:

- **Banner do perfil** — recommend creating/updating the profile banner when
  relevant to the objective (contact channels + impact phrase per the
  issue-224 banner flow; never invent contact data absent from the hub).
- **Seção em destaque (Featured)** — what to feature from the hub (projects
  with links, certifications, real achievements), with a short factual caption
  suggestion per item.
- **Seções do perfil** — apply the headline, the Sobre text, the experience
  bullets and the skills reordering produced above; complete/adjust profile
  sections that exist in the hub (idiomas, certificações, educação, projetos)
  and list the data gaps found along the way (e.g. metrics to collect).

## Hard rules

1. **NEVER invent** — experience, skills, achievements, certifications,
   numbers or content that are not in the hub (or derived from hub dates) do
   NOT enter the report. Only rephrase, reorder and highlight what exists.
   Achievements without metrics are flagged as gaps, never filled with
   invented numbers.
2. **NEVER scrape or modify LinkedIn** — no URL fetching of linkedin.com (nor
   of any portal), no anti-bot bypass, no direct profile edits, no export-CSV
   parsing here (the issue-225 sync owns that). All output is suggestions the
   user copies/pastes manually.
3. **NO `[INFERIDO]` in the output file** — `linkedin-optimization.md` is an
   actionable, copy/paste-able suggestion file: the `[INFERIDO]` marker (and
   case-insensitive variants, and the word "inferido") MUST NOT appear — same
   rule as final resume PDFs per `standards/cv-analysis.md` §5. Assumed
   content (e.g. an assumed objective) is DECLARED in prose or omitted —
   never silently included.
4. **Validate the hub** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json` must
   pass (exit 0) before generating the report.
5. **Respect LinkedIn's limits** — headline ≤220 chars, Sobre ≤2600 chars,
   skills top 50 shown (top 3 most visible).
6. **Objective first** — never silently assume an objective; never
   founder/CEO positioning for a `job_search` candidate.
7. **No sensitive data** — no CPF, full address, bank details.

## Report

Report to the user: the output path
(`~/career/<candidate>/linkedin-optimization.md`), the objective used
(`type` + literal target role/service; mark it "assumido" when that is the
case), and a summary of the sections: number of headline variants with their
lengths, Sobre length, number of experience roles covered, the skills source
used (sync JSON / pasted list / none) with the add/promote/remove counts, and
the top next-step priorities — no `[INFERIDO]` markers in the shareable
suggestion file.
