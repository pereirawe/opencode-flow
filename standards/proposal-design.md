# Proposal Design Standard

Canonical design and delivery standard for every commercial proposal authored
by the business-ops sector (`/ocf:proposal`, skill `proposal-writer`). Every
proposal MUST be deliverable as a branded PDF (and an HTML source) in addition
to the markdown source, using the proposing company's logo and company data.

The rules below are concrete and testable (MUST statements with measurable
values), not opinions.

## 1. Outputs

1. Every proposal MUST have three outputs derived from one source of truth
   (`proposal.md`):
   - `proposal.md` — the markdown source (Mermaid allowed for gantt/pie).
   - `proposal.html` — self-contained HTML rendering, A4-ready, brand header.
   - `proposal.pdf` — A4 PDF generated from `proposal.html` via
     `scripts/proposal/pdf.sh` (Chrome headless, LibreOffice fallback).
2. The HTML/PDF MUST be generated from the reference template
   `skills/business-ops/proposal-writer/templates/proposal.html` — agents
   adapt the CONTENT, never rewrite the CSS from scratch.
3. The HTML/PDF MUST carry the proposing company's logo and company data in
   the header (see §3 Brand). A proposal generated with a missing brand MUST
   be an explicit, user-confirmed "no brand" build, never a silent omission.

## 2. Print (A4)

1. Page size MUST be A4. Top/side margins MUST be 14–16mm; the bottom margin
   MUST be ≥16mm (18mm in the reference template) to accommodate the
   page-number footer.
2. The proposal MUST be fully legible in black-and-white: no information may
   be conveyed by color alone. Status/price emphasis comes from weight, size,
   and spacing.
3. A clean `@media print` block MUST exist that removes interactive colors and
   keeps layout intact; backgrounds MUST be light/absent in print.
4. Sections and `.proposal-section` blocks MUST use `break-inside: avoid`;
   `h2` MUST use `break-after: avoid` so a section title is never orphaned at
   the bottom of a page. Long tables (effort/price) MAY break with
   `orphans: 3; widows: 3`.
5. A footer with page numbers is REQUIRED
   (`@page { @bottom-right { content: counter(page) } }` or an equivalent
   Chrome-print footer) so a printed proposal can be referenced by page.
   Chrome renders CSS margin boxes; the LibreOffice fallback does NOT — the
   fallback engine warns, and a LibreOffice-produced PDF MUST be checked
   manually for the footer (or the body footer variant used).
6. Fonts MUST be print-safe system fonts (`Helvetica`, `Arial`, `sans-serif`;
   `Courier`/mono for codes/ids). Remote web fonts are FORBIDDEN — they may
   not render headless.

## 3. Brand (proposing company)

1. Brand assets live at `docs/assets/` of the project where the flow is
   invoked. Resolution order (MUST):
   1. `<project>/docs/assets/company.json` + `<project>/docs/assets/logo.*`
      (project brand — preferred).
   2. `~/.config/opencode/assets/company.json` + `~/.config/opencode/assets/logo.*`
      (global fallback).
   3. Legacy compat: `docs/specs/<slug>/assets/logo.*` (spec-local copy from
      the previous `spec-init.sh` behavior). Never the primary source.
2. `company.json` schema (all fields optional; NEVER invent values — omit
   fields that are unknown):
   ```json
   {
     "name": "Legal or trading company name",
     "legal_name": "Full legal name (optional)",
     "document": "CNPJ/RIF/registry number (optional)",
     "contact": { "email": "…", "phone": "…", "website": "…" },
     "address": { "street": "…", "city": "…", "state": "…", "country": "…" }
   }
   ```
3. The HTML/PDF header MUST render, when present: the logo image, the company
   `name`, and a compact contact line (email/phone/website). Missing
   `company.json` fields are omitted — never replaced with placeholders or
   invented data.
4. The `proposal.html` MUST be self-contained: reference the logo as a data
   URI or copy it beside `proposal.html` and reference it relatively
   (`./logo.png`). NEVER use an absolute `file://` or remote URL for the logo —
   the file:// URL would leak in print and a remote URL may not load headless.
5. The `<html lang>` attribute MUST match the resolved proposal locale (not a
   hardcoded language) so screen readers and translation tools behave
   correctly.
6. `scripts/proposal/brand-resolve.sh` MUST be used to resolve brand
   availability before drafting. It resolves WHOLE-TIER (project → global →
   legacy), never cross-joining assets from different tiers (a project logo
   never pairs with a global `company.json`). Exit contract:
   - `0` — brand found (logo and/or `company.json`).
   - `1` — no brand anywhere (project nor global).
   The script prints the resolved absolute paths (`logo=…`,
   `company_json=…`) and the active tier (`source=…`).
7. When NO brand is found, the agent MUST ask the user (never assume):
   - (a) generate WITHOUT brand, or
   - (b) provide company data/logo now (saved to `<project>/docs/assets/`),
   - (c) create the brand standard in the project first (see §5).
   Only after the user answers does the agent generate. This is a hard gate.
8. Header rendering rules:
   - When both logo and `company.json` are present: logo on the left, company
     name + contact on the right.
   - When only one is present (logo-only / company-only): the single block is
     anchored left and the empty side is removed — never a half-empty
     space-between layout.
   - In a no-brand build the `<header class="brand-header">` element MUST be
     removed entirely (an empty header leaves a stray rule on the client
     document).
## 4. Proposal content structure

The canonical section order from the `proposal-writer` skill is preserved in
the HTML/PDF (§ Structure). Every pricing figure MUST be derived from visible
math (rate × hours, discounts, final) exactly as in the markdown source —
never a rounded number with no derivation.

## 5. Creating a brand standard in a project

When the user opts for (c) in §3.7, the agent MUST, in order:

1. Ask for or gather the proposing company's public identity (URL, logo file,
   or press kit) and factual data.
2. Run the `brand-to-design-md` skill against the public identity to produce
   `<project>/docs/assets/DESIGN.md` (design tokens: colors, typography,
   spacing, logo usage).
3. Save the company data as `<project>/docs/assets/company.json` following the
   §3.2 schema and the resolved logo as
   `<project>/docs/assets/logo.<ext>` (svg/png preferred).
4. Confirm the assets are readable by `scripts/proposal/brand-resolve.sh`
   (exit 0) before proceeding with the proposal.

## 6. Conformity checklist (run before generating the PDF)

- [ ] `proposal.md`, `proposal.html`, `proposal.pdf` all exist and match in
      content/figures
- [ ] HTML starts from the reference template (never CSS from scratch)
- [ ] `@page { size: A4; … }` present; top/side margins 14–16mm; bottom ≥16mm
- [ ] Header shows logo + company name + contact (when present in company.json);
      single-asset and no-brand builds follow §3.8 (no stray empty side/rule)
- [ ] No invented company data; missing `company.json` fields are omitted
- [ ] Logo referenced as data URI or relative copy — no `file://`/remote logo
- [ ] No remote fonts/network dependency; legible in black-and-white
- [ ] Page-number footer present (Chrome ≥131; LibreOffice output checked
      manually — engine warns)
- [ ] `<html lang>` matches the resolved proposal locale
- [ ] No unrendered template token: `grep -E '\{\{' proposal.html` → 0
- [ ] Brand resolution done via `brand-resolve.sh`; no-brand build is explicit
      and user-confirmed
- [ ] Price math visible and identical across `.md`/`.html`/`.pdf`
- [ ] Locale-correct prose; code identifiers/agent names absent from the
      client-facing document
- [ ] `proposal.pdf` non-empty and valid (Chrome or LibreOffice succeeded)

## 7. Locale

`proposal-design.md` originals live in English at `standards/`. Localized
versions exist at `standards/pt/proposal-design.md` and
`standards/es/proposal-design.md`. Never edit the English originals from the
translations; the English version is the source of truth.
