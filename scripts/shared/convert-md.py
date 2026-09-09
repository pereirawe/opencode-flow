#!/usr/bin/env python3
"""Deterministic Markdown -> HTML renderer (Python 3 stdlib only). Issue #227.

Renders a CLOSED markdown subset (everything else becomes escaped literal text,
exit 0 — never an error, never active markup):

  - ATX headings (#..######)
  - paragraphs (soft breaks join with a space; hard break = two trailing spaces)
  - unordered/ordered lists with basic nesting (one level)
  - fenced code blocks with language
  - blockquotes (single level)
  - GFM pipe tables (header + separator + rows, alignment via :---:)
  - horizontal rules (---, ***, ___)
  - inline: code spans, bold (**/__), italic (*/_), links, images, escapes

Security (BR 8, input = untrusted data):
  - RAW HTML in the input is ESCAPED and rendered as literal text — it is never
    interpreted as active markup.
  - `javascript:` link targets are dropped (href="#") with a warning.
  - Remote image URLs are never fetched (offline) — the src is preserved.
  - Local images become data: URIs only when the file exists and is <= 512 KiB
    (BR 9); larger/missing files warn and keep the raw src in the HTML.

Determinism (BR 1): no randomness, no clock, no network; identical input always
yields byte-identical output.

CLI: convert-md.py <input.md> <output.html>
Exits: 0 ok; 1 runtime failure; 2 usage/invalid input (handled by the caller).
"""

import base64
import html
import mimetypes
import os
import re
import sys

MAX_IMAGE_BYTES = 512 * 1024  # BR 9: 512 KiB per embedded local image

HEADING_RE = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
FENCE_RE = re.compile(r"^```(\S*)\s*$")
HR_RE = re.compile(r"^\s*([-*_])(\s*\1){2,}\s*$")
BLOCKQUOTE_RE = re.compile(r"^\s*>\s?(.*)$")
LIST_RE = re.compile(r"^(\s*)([-+*]|\d+[.)])\s+(.*)$")
TABLE_SEP_RE = re.compile(r"^\s*\|?[\s:|-]+\|[\s:|-]*\|?[\s:|-]*$")

INLINE_MASTER = re.compile(
    r"(`+)(.+?)\1"
    r"|(\*\*|__)(.+?)\3"
    r"|(\*|_)(.+?)\5"
    r"|!\[([^\]]*)\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)"
    r"|\[([^\]]*)\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)"
    r"|\\([\\`*_[\]{}()#+\-.!|>])"
)

JS_URL_RE = re.compile(r"^\s*javascript:", re.IGNORECASE)
REMOTE_URL_RE = re.compile(r"^(https?|ftp)://", re.IGNORECASE)


def esc_txt(s):
    return html.escape(str(s), quote=False)


def esc_attr(s):
    return html.escape(str(s), quote=True)


def warn(msg):
    sys.stderr.write("warning: %s\n" % msg)


def _image_src(url, md_dir):
    """Resolve an image URL to an <img src> value (BR 9, offline).

    - remote URL -> preserved as-is (never fetched)
    - local file <= 512 KiB -> data: URI (base64)
    - local file missing / larger -> warning + raw src preserved
    """
    if REMOTE_URL_RE.match(url) or url.startswith("data:"):
        return esc_attr(url)
    path = url.split("#", 1)[0].split("?", 1)[0]
    if not path:
        return esc_attr(url)
    full = path if os.path.isabs(path) else os.path.join(md_dir, path)
    if not os.path.isfile(full):
        warn("image not found, keeping raw src: %s" % url)
        return esc_attr(url)
    size = os.path.getsize(full)
    if size > MAX_IMAGE_BYTES:
        warn("image %s is %d bytes (> %d KiB) — keeping raw src" % (url, size, MAX_IMAGE_BYTES // 1024))
        return esc_attr(url)
    mime, _ = mimetypes.guess_type(full)
    mime = mime or "application/octet-stream"
    try:
        with open(full, "rb") as fh:
            data = base64.b64encode(fh.read()).decode("ascii")
    except OSError as exc:
        warn("cannot read image %s: %s — keeping raw src" % (url, exc))
        return esc_attr(url)
    return 'data:%s;base64,%s' % (mime, data)


def render_inline(text, md_dir, depth=0):
    """Render inline markdown. Recursion is depth-limited so adversarial input
    (e.g. 10k nested **) can never blow the stack — beyond the limit the rest
    is escaped literally (still deterministic, still safe)."""
    if depth > 10:
        return esc_txt(text)

    def repl(m):
        if m.group(1) is not None:      # code span
            return "<code>%s</code>" % esc_txt(m.group(2))
        if m.group(3) is not None:      # bold
            return "<strong>%s</strong>" % render_inline(m.group(4), md_dir, depth + 1)
        if m.group(5) is not None:      # italic
            return "<em>%s</em>" % render_inline(m.group(6), md_dir, depth + 1)
        if m.group(7) is not None:      # image ![alt](url)
            alt, url = m.group(7), m.group(8)
            return '<img alt="%s" src="%s">' % (esc_attr(alt), _image_src(url, md_dir))
        if m.group(9) is not None:      # link [text](url)
            text, url = m.group(9), m.group(10)
            if JS_URL_RE.match(url):
                warn("javascript: link target dropped (security): %s" % url)
                href = "#"
            else:
                href = esc_attr(url)
            return '<a href="%s">%s</a>' % (href, render_inline(text, md_dir, depth + 1))
        if m.group(11) is not None:     # escape \X
            return esc_txt(m.group(11))
        return esc_txt(m.group(0))

    return INLINE_MASTER.sub(repl, text)


def _split_row(line):
    line = line.strip()
    if line.startswith("|"):
        line = line[1:]
    if line.endswith("|"):
        line = line[:-1]
    return [c.strip() for c in line.split("|")]


def _render_table(header, sep, body_lines, md_dir):
    cells = _split_row(header)
    seps = _split_row(sep)
    aligns = []
    for i, s in enumerate(seps):
        if s.startswith(":") and s.endswith(":"):
            aligns.append("center")
        elif s.endswith(":"):
            aligns.append("right")
        elif s.startswith(":"):
            aligns.append("left")
        else:
            aligns.append("")
    out = ["<table>", "<thead><tr>"]
    for i, c in enumerate(cells):
        a = ' style="text-align:%s"' % aligns[i] if i < len(aligns) and aligns[i] else ""
        out.append("<th%s>%s</th>" % (a, render_inline(c, md_dir)))
    out.append("</tr></thead><tbody>")
    for row in body_lines:
        if not row.strip():
            continue
        cells = _split_row(row)
        out.append("<tr>")
        for i, c in enumerate(cells):
            a = ' style="text-align:%s"' % aligns[i] if i < len(aligns) and aligns[i] else ""
            out.append("<td%s>%s</td>" % (a, render_inline(c, md_dir)))
        out.append("</tr>")
    out.append("</tbody></table>")
    return "".join(out)


def _looks_like_table_header(lines, i):
    """A table needs: current line with '|' + next line that is a GFM separator
    (contains '-' and only |, :, -, spaces)."""
    if i + 1 >= len(lines) or "|" not in lines[i]:
        return False
    nxt = lines[i + 1]
    if "-" not in nxt or not TABLE_SEP_RE.match(nxt):
        return False
    return True


def parse_list(lines, i, md_dir):
    """Consume a list starting at lines[i]; return (html, next_index).
    Basic nesting (one level): an item indented deeper than its sibling opens a
    sub-list inside the previous <li>. A blank line or a non-list block line
    ends the list (GFM-lite)."""
    n = len(lines)
    items = []  # (indent, ordered:bool, text)
    while i < n:
        line = lines[i]
        if not line.strip():
            break
        m = LIST_RE.match(line)
        if m is None:
            break
        indent = len(m.group(1))
        ordered = bool(re.match(r"^\d+[.)]$", m.group(2)))
        parts = [m.group(3)]
        i += 1
        # continuation lines belonging to the item (no marker, non-blank)
        while i < n and lines[i].strip() and LIST_RE.match(lines[i]) is None \
                and not line_starts_block(lines[i]):
            parts.append(lines[i].strip())
            i += 1
        items.append((indent, ordered, " ".join(parts)))
    if not items:
        return "", i
    html, _ = _render_items(items, 0, items[0][0], md_dir)
    return html, i


def _render_items(items, k, base_indent, md_dir):
    """Render items[k:] as sibling list items (indent >= base_indent); items
    indented deeper become a nested list inside the previous <li>.
    Returns (html, next_k)."""
    out = []
    tag = "ol" if items[k][1] else "ul"
    while k < len(items):
        indent, _ordered, text = items[k]
        if indent < base_indent:
            break
        content = [render_inline(text, md_dir)]
        if k + 1 < len(items) and items[k + 1][0] > indent:
            sub, k = _render_items(items, k + 1, items[k + 1][0], md_dir)
            content.append(sub)
            out.append("<li>%s</li>" % "".join(content))
            continue
        out.append("<li>%s</li>" % "".join(content))
        k += 1
    return "<%s>%s</%s>" % (tag, "".join(out), tag), k


def line_starts_block(line):
    s = line.strip()
    if not s:
        return True
    if HEADING_RE.match(s) or FENCE_RE.match(s) or HR_RE.match(s):
        return True
    if s.startswith(">"):
        return True
    if LIST_RE.match(s):
        return True
    if _line_is_raw_html(s):
        return True
    return False


def _line_is_raw_html(line):
    """Raw HTML line — escaped as literal text (BR 8), never interpreted."""
    return line.lstrip().startswith("<")


def render(md_text, md_dir):
    lines = md_text.splitlines()
    blocks = []
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        if not line.strip():
            i += 1
            continue

        # fenced code
        m = FENCE_RE.match(line)
        if m:
            lang = m.group(1)
            j = i + 1
            buf = []
            while j < n and not FENCE_RE.match(lines[j]):
                buf.append(lines[j])
                j += 1
            if j >= n:
                # unterminated fence: render the remaining lines as code anyway
                j = n
            code = "\n".join(buf)
            cls = ' class="language-%s"' % esc_attr(lang) if lang else ""
            blocks.append("<pre><code%s>%s</code></pre>" % (cls, esc_txt(code)))
            i = j + 1
            continue

        # ATX heading
        m = HEADING_RE.match(line)
        if m:
            lvl = len(m.group(1))
            blocks.append("<h%d>%s</h%d>" % (lvl, render_inline(m.group(2), md_dir), lvl))
            i += 1
            continue

        # horizontal rule
        if HR_RE.match(line):
            blocks.append("<hr>")
            i += 1
            continue

        # blockquote (single level)
        if BLOCKQUOTE_RE.match(line):
            buf = []
            while i < n and BLOCKQUOTE_RE.match(lines[i]):
                m = BLOCKQUOTE_RE.match(lines[i])
                buf.append(m.group(1))
                i += 1
            blocks.append("<blockquote><p>%s</p></blockquote>" % render_inline(" ".join(buf), md_dir))
            continue

        # GFM pipe table
        if _looks_like_table_header(lines, i):
            header = lines[i]
            sep = lines[i + 1]
            j = i + 2
            body = []
            while j < n and "|" in lines[j] and lines[j].strip():
                body.append(lines[j])
                j += 1
            blocks.append(_render_table(header, sep, body, md_dir))
            i = j
            continue

        # lists (ul/ol with basic nesting)
        if LIST_RE.match(line):
            html_out, i = parse_list(lines, i, md_dir)
            blocks.append(html_out)
            continue

        # raw HTML line -> escaped literal text (BR 8)
        if _line_is_raw_html(line):
            blocks.append("<p>%s</p>" % esc_txt(line.strip()))
            i += 1
            continue

        # paragraph: collect until a blank line or another block start
        buf = [line.strip()]
        i += 1
        while i < n and lines[i].strip() and not line_starts_block(lines[i]):
            l = lines[i].rstrip()
            if l.endswith("  "):
                buf.append("<br>")
                buf.append(l.rstrip())
            else:
                buf.append(l.strip())
            i += 1
        blocks.append("<p>%s</p>" % render_inline(" ".join(buf), md_dir))

    return "\n".join(blocks)


DOC_CSS = """\
@page { size: A4; margin: 15mm; }
@media print { body { max-width: 100%; margin: 0; padding: 0; } }
body { font-family: -apple-system, 'Segoe UI', Helvetica, Arial, sans-serif;
       max-width: 860px; margin: 2em auto; padding: 0 1em; color: #1f2328;
       line-height: 1.55; }
pre { background: #f6f8fa; border: 1px solid #d0d7de; border-radius: 6px;
      padding: 12px; overflow-x: auto; }
code { font-family: 'SFMono-Regular', Consolas, 'Liberation Mono', monospace;
       font-size: 0.92em; }
p > code, li > code, td > code, th > code { background: #f6f8fa; padding: 2px 4px;
       border-radius: 4px; }
table { border-collapse: collapse; margin: 1em 0; display: block;
        overflow-x: auto; }
th, td { border: 1px solid #d0d7de; padding: 6px 12px; }
th { background: #f6f8fa; }
blockquote { border-left: 4px solid #d0d7de; margin: 1em 0;
             padding: 0.1em 1em; color: #57606a; }
hr { border: none; border-top: 2px solid #d0d7de; margin: 1.6em 0; }
img { max-width: 100%; }
"""


def main(argv):
    if len(argv) != 3:
        sys.stderr.write("Usage: convert-md.py <input.md> <output.html>\n")
        return 2
    md_path, out_path = argv[1], argv[2]
    try:
        with open(md_path, "r", encoding="utf-8") as fh:
            md_text = fh.read()
    except OSError as exc:
        sys.stderr.write("error: cannot read input markdown: %s\n" % exc)
        return 2
    md_dir = os.path.dirname(os.path.abspath(md_path))
    body = render(md_text, md_dir)
    stem = os.path.splitext(os.path.basename(out_path))[0]
    doc = (
        "<!DOCTYPE html>\n"
        '<html lang="en"><head><meta charset="utf-8">\n'
        "<title>%s</title>\n"
        "<style>%s</style>\n"
        "</head><body>\n%s\n</body></html>\n"
    ) % (esc_txt(stem), DOC_CSS, body)
    try:
        with open(out_path, "w", encoding="utf-8") as fh:
            fh.write(doc)
    except OSError as exc:
        sys.stderr.write("error: cannot write output html: %s\n" % exc)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
