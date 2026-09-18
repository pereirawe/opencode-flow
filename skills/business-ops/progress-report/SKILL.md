---
name: progress-report
description: Generate a client-facing progress/delivery report for a tracked project (issues vs commercial proposal) — with Codetomika logo, PDF output, Mermaid Gantt, date, what is done, % completion by hours, delivery metrics for the client, and an explicit highlight of tasks that were not mapped in the proposal/issues. Use when the user asks to create, refresh, or standardize a progress report, delivery report, status report, "relatório de avanço", "relatório de progresso", "relatório de entrega", or to communicate value/delivery to the client. Also use when creating/improving the progress-report skill/script itself.
---

# Progress Report Skill

Produce a **client-facing progress report** that turns tracked issues
(`known_issues.md` + `resolved_issues.md`) and the commercial proposal into a
clear statement of delivered value, % completion, schedule health, and risk —
in a format the client can read in minutes.

This skill standardizes the report for **regular** generation (daily/retro).
The report must look and feel like the proposal and tech spec: same logo, same
PDF pipeline, same visual language.

## When to use

- Creating a new progress report (e.g. `ocf:progress-report`).
- Improving the generator script `.opencode/scripts/progress-report.sh` or the
  command `.opencode/commands/ocf:progress-report.md`.
- Reviewing an existing report for client-readability.

## Output contract

The generated report is written as Markdown and rendered to **HTML + PDF**:

- **Markdown**: `docs/progress/<date>-progress-report.md` (source of truth).
- **HTML**: `docs/progress/<date>-progress-report.html` (intermediate, kept).
- **PDF**: `docs/progress/<date>-progress-report.pdf` (client deliverable).

The PDF must be produced with the same pipeline as the proposal/spec
(`~/.config/opencode/scripts/shared/convert-md.sh`), which inlines the
Codetomika logo and the Gantt SVG as data URIs — so the PDF is self-contained.

## Required report sections (client standard)

Order is deliberate — the client reads value first, then details.

1. **Header block** — logo (see §Logo), title "Relatório de Avanço — <Projeto>",
   Para/De/Data (report date), Período coberto, Fase atual.
2. **Resumo executivo** (3–5 bullets) — value delivered so far, % completion
   (by hours), status vs the next milestone, top blocker, and whether the
   contract deadline is on track. Written for a non-technical reader.
3. **Cálculo de % concluído (por horas)** — table mapping proposal modules →
   hours → status → estimated % delivered. The % must come from **hours**, not
   from issue count (issue count is an internal metric). Show the running total
   (X h / 474 h contratadas) and the derived global %.
4. **Cronograma (Gantt)** — rendered Gantt (see §Gantt) with current date
   marker, milestones (from the proposal: 19/09, 01/10, 20/10, 24/10, 31/10),
   and visual status per phase (done / active / at risk / not started).
5. **O que já foi entregue** — issues resolved + frontend work delivered by the
   Lovable platform, grouped by phase/module, with the issue numbers.
6. **Métricas de entrega** — issues resolved/total, in-progress, in-review,
   critical open, rate of closure (last 7 days), % resolved vs % by hours
   (explain the gap), test status.
7. **Tarefas não mapeadas** (mandatory) — explicit table of tasks done/in
   progress that were NOT in the proposal/issues (e.g. WhatsApp/Meta number
   connection, Twilio connection, QR reader, event capture, WhatsApp group CTA).
   Each row: tarefa, status real, por que não estava mapeada, impacto.
8. **Riscos ativos e dependências** — deadlocks (external inputs from the
   client, e.g. Twilio templates, Meta approval) with the date they were due.
9. **Próximos passos (2 semanas)** — ordered by the proposal Gantt.

## Logo

- Use `docs/assets/logo/logo-blue.png` (30.9 KB — fits the 512 KiB data-URI
  limit of `convert-md.py`). Reference it relative to the report:
  `![Codetomika](./assets/logo-blue.png)`.
- Copy the logo into `docs/progress/assets/logo-blue.png` when generating.
- Never invent a logo; if the asset is missing, warn instead of fabricating.

## Gantt

- The Gantt source is a `.mmd` file (Mermaid) in `docs/progress/assets/`,
  rendered offline with
  `~/.config/opencode/scripts/shared/convert-mermaid.sh <in.mmd> <out.svg>`
  (Chrome headless, vendored mermaid, offline-safe).
- The proposal Gantt (`docs/proposta-dia-educacao-2026.md` §5) is the **base**;
  add the current date as a vertical marker (`todayMarker`) and set `done`/
  `active`/`crit` per phase based on the real issue status.
- The SVG is referenced in the MD as `![Gantt](./assets/<name>.svg)` so
  `convert-md.sh` inlines it into the PDF.

## Generation pipeline

Run these in order (the `ocf:progress-report` command does this):

1. `progress-report.sh --date <YYYY-MM-DD>` reads `known_issues.md` +
   `resolved_issues.md` and the proposal hours table, computes metrics, and
   writes the MD. It must:
   - resolve the report date dynamically (never hardcode a past date);
   - read `resolved` issues from `resolved_issues.md` (they are never in
     `known_issues.md`), so % resolved is correct;
   - compute % by **hours** (proposal modules) with a per-module status;
   - print a one-line summary to stdout for the agent/user.
2. `convert-mermaid.sh` renders the Gantt SVG (idempotent — same input, same
   output; skip if unchanged).
3. `convert-md.sh <report.md> <report.pdf>` produces HTML + PDF with logo and
   Gantt inlined.
4. Validate: PDF exists, `pdfinfo` pages sane, SVG embedded, logo present.
5. Notify via Telegram (`telegram-notify.sh`) with the one-line summary.

## Readability rules (client-facing)

- Language: **pt-BR** for the client-facing text (project rule), technical
  terms in English are OK.
- No jargon in the executive summary; internal terms (issue #, status names)
  belong in the delivery-metrics section, not the summary.
- Numbers first: % completion and deadline status must appear in the first
  screen.
- Always show the "Tarefas não mapeadas" section — it demonstrates rigor and
  explains work the client sees but was never quoted.
- Dates in DD/MM/AAAA format in prose; YYYY-MM-DD in files/scripts.
- The % by hours and the % resolved may differ — explain the difference in one
  line (hours = scope weight; resolved = backlog health).

## Anti-patterns to avoid

- Hardcoding a past date or a fixed "days remaining" (compute from the report
  date).
- Reporting % resolved as scope completion.
- Dropping the "Tarefas não mapeadas" section.
- Generating only MD and skipping the PDF (the client needs the PDF).
- Editing the generated numbers by hand — change the source
  (`known_issues.md`/`resolved_issues.md`) and regenerate.

## Quality checklist

- [ ] Logo present in the MD and embedded in the PDF.
- [ ] Gantt rendered (SVG) and embedded in the PDF.
- [ ] Report date is the actual generation date.
- [ ] % by hours computed from the proposal module hours.
- [ ] Delivery metrics table present (resolved, in-progress, critical open).
- [ ] "Tarefas não mapeadas" section present and truthful.
- [ ] Executive summary readable by a non-technical client.
- [ ] PDF generated and verified.
- [ ] Telegram notification sent.