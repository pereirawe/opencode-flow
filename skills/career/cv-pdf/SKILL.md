---
name: cv-pdf
description: Generate a resume PDF from HTML — Chrome headless (--print-to-pdf, A4) with LibreOffice fallback. Use when you need to convert a tailored resume's HTML into a PDF, or any HTML into an A4 PDF. Career sector.
---

# CV PDF — HTML → PDF

Converts a resume HTML file into an A4 PDF, ready for ATS and submission.

## Command

```bash
bash $SCRIPTS_DIR/cv/pdf.sh <input.html> <output.pdf> [chrome|libreoffice]
```

- `<input.html>` — the resume's HTML file (must contain `@page` CSS for A4).
- `<output.pdf>` — destination PDF path.
- Optional engine: `chrome` (default) or `libreoffice` (forces the fallback).

Without the third argument, it tries Chrome first and falls back to
LibreOffice if Chrome is unavailable or fails.

## Mandatory design standard

Every resume HTML MUST follow the `standards/cv-design.md` standard
(ATS-friendly, A4 print/B&W, sober style, page-count rule by seniority). Use
the reference template `skills/career/cv-pdf/templates/resume.html` as the
starting point — adapt the content, NEVER rewrite the CSS from scratch.

## Quality rules

1. **A4 required** — the HTML MUST declare `@page { size: A4; margin:
   12mm 15mm; }` (margins between 12mm and 15mm). Without it Chrome uses the
   browser's page size and the PDF may end up with a wrong layout.
2. **Clean typography** — system fonts (`Helvetica`, `Arial`, `sans-serif`)
   for maximum compatibility. No Google Fonts online (they may not render
   headless without network and break some ATS parsers).
3. **ATS-friendly** — semantic headings (`h1`/`h2`), selectable text (never
   turned into an image), single column (no multicol), no complex tables, no
   decorative icons/emoji, dates as text.
4. **Printable** — legible in black-and-white (no information dependent on
   color); no backgrounds/images in print; clean `@media print`.
5. **Reasonable size** — Junior/Mid: 1 page; Senior/Expert/Lead: up to 2
   pages; never 3+. Max density ~600–700 words/page. If the PDF exceeds the
   limit, suggest condensing the content (review the least relevant sections).

## Verification

After generating, confirm the PDF:
- is not empty (`ls -la` → > 0 bytes; use `file` to confirm "PDF document"),
- has 1–2 pages for a standard resume,
- opens without structural errors.

## Fallback

If Chrome fails (e.g. sandbox/container), run
`bash $SCRIPTS_DIR/cv/pdf.sh <input.html> <output.pdf> libreoffice`. LibreOffice
converts the HTML with lower CSS fidelity, so review the resulting PDF.
