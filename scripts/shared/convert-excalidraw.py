#!/usr/bin/env python3
"""Deterministic Excalidraw JSON -> HTML (SVG inline) renderer. Issue #227.

Renders the CLOSED v1 subset of Excalidraw elements with Python 3 stdlib only:

  rectangle, diamond, ellipse, line, arrow, freedraw, text, image (data: URI
  pass-through)

Position, angles, strokeColor/backgroundColor/fillStyle and roughness are
APPROXIMATED deterministically (no randomness — roughness is drawn as straight
strokes; hachure/cross-hatch fills use a translucent fill approximation, BR 1
+ BR 11). The SVG gets a canvas-sized background rect.

Out-of-subset elements (valid Excalidraw types like frame/embeddable/equation)
emit a warning to stderr and are SKIPPED without aborting (exit 0, valid
artifacts). JSON that does not fit the elements v1/v2 schema (no "elements"
array, element without a known type) exits 2 (BR 11).

Canvas size: when no viewport is declared, the elements' bounding box (+20px
padding, minimum 100x100) is used — open question (2) resolved at
implementation.

CLI: convert-excalidraw.py <input.json> <output.html>
stdout: "<width>x<height>" (the canvas dimensions, consumed by the shell
wrapper for the JPEG/PDF paths).

Exits: 0 ok; 1 runtime failure; 2 schema/usage error.
"""

import html
import json
import math
import os
import sys

SUPPORTED = {
    "rectangle", "diamond", "ellipse", "line",
    "arrow", "freedraw", "text", "image",
}
# Valid Excalidraw element types outside the closed v1 subset: warn + skip.
KNOWN_OUT_OF_SCOPE = {
    "frame", "embeddable", "magicframe", "equation", "iframe",
    "brush", "linearElement",
}

PADDING = 20
MIN_CANVAS = 100
DEFAULT_STROKE = "#1e1e1e"
DEFAULT_BG = "transparent"


def esc_attr(s):
    return html.escape(str(s), quote=True)


def esc_txt(s):
    return html.escape(str(s), quote=False)


def warn(msg):
    sys.stderr.write("warning: %s\n" % msg)


def num(el, key, default):
    try:
        v = el.get(key, default)
        if v is None:
            return default
        return float(v)
    except (TypeError, ValueError):
        return default


def hex_color(v, default):
    if not isinstance(v, str):
        return default
    if v == "transparent" or v.startswith("#") or v.startswith("rgb") or v.startswith("hsl"):
        return v
    return default


def load_elements(raw):
    """Parse the input JSON and return the elements list.
    Raises ValueError with a clear message on schema violations (exit 2)."""
    try:
        data = json.loads(raw)
    except ValueError as exc:
        raise ValueError("input JSON is not valid: %s" % exc)
    if isinstance(data, dict):
        if "elements" not in data:
            raise ValueError("input JSON has no \"elements\" array (not an Excalidraw file)")
        elements = data["elements"]
    elif isinstance(data, list):
        # Bare element array (some exports) — accept as elements v1/v2
        elements = data
    else:
        raise ValueError("input JSON is neither an Excalidraw object nor an elements array")
    if not isinstance(elements, list):
        raise ValueError("\"elements\" is not an array (schema violation)")
    for idx, el in enumerate(elements):
        if not isinstance(el, dict):
            raise ValueError("element %d is not an object (schema violation)" % idx)
        if not isinstance(el.get("type"), str):
            raise ValueError("element %d has no \"type\" string (schema violation)" % idx)
    return elements, (data.get("appState", {}) if isinstance(data, dict) else {})


def bounds_of(elements):
    """Bounding box over the supported elements (x, y, width, height).
    Text without width/height is estimated from fontSize and content; for
    line/arrow/freedraw the absolute endpoints (x+points) are used so a long
    arrow widens the canvas. Elements with no measurable extent are ignored."""
    xs, ys, xe, ye = [], [], [], []
    for el in elements:
        t = el.get("type")
        if t not in SUPPORTED:
            continue
        x = num(el, "x", 0)
        y = num(el, "y", 0)
        if t in ("line", "arrow", "freedraw"):
            pts = el.get("points")
            if isinstance(pts, list) and pts:
                absx = [x + float(p[0]) for p in pts if isinstance(p, list) and len(p) >= 2]
                absy = [y + float(p[1]) for p in pts if isinstance(p, list) and len(p) >= 2]
                if absx:
                    xs.append(min(absx))
                    xe.append(max(absx))
                    ys.append(min(absy))
                    ye.append(max(absy))
                    continue
            continue
        if t == "text":
            w = num(el, "width", 0) or (num(el, "fontSize", 20) * 0.62 * max(
                (len(line) for line in str(el.get("text", "")).splitlines()), default=0))
            h = num(el, "height", 0) or (num(el, "fontSize", 20) * 1.25 *
                                         max(1, str(el.get("text", "")).count("\n") + 1))
        else:
            w = num(el, "width", 0)
            h = num(el, "height", 0)
        xs.append(x)
        ys.append(y)
        xe.append(x + w)
        ye.append(y + h)
    if not xs:
        return MIN_CANVAS, MIN_CANVAS, MIN_CANVAS, MIN_CANVAS
    return min(xs), min(ys), max(xe), max(ye)


def canvas_size(elements, app_state):
    """Canvas dimensions: viewport width/height when declared, else the
    elements' bounding box + padding (open question 2 resolved)."""
    vw = app_state.get("width")
    vh = app_state.get("height")
    if isinstance(vw, (int, float)) and isinstance(vh, (int, float)) and vw > 0 and vh > 0:
        return float(vw), float(vh), 0, 0
    minx, miny, maxx, maxy = bounds_of(elements)
    w = max(MIN_CANVAS, maxx - minx + 2 * PADDING)
    h = max(MIN_CANVAS, maxy - miny + 2 * PADDING)
    return w, h, minx - PADDING, miny - PADDING


def dash_array(stroke_style):
    return {
        "dashed": "6,4",
        "dotted": "2,3",
    }.get(stroke_style, "")


def render_transform(x, y, w, h, angle):
    if not angle:
        return ""
    cx, cy = x + w / 2.0, y + h / 2.0
    deg = math.degrees(angle)
    return ' transform="rotate(%s %s %s)"' % (round(deg, 4), round(cx, 2), round(cy, 2))


def common_attrs(el, x, y, w, h):
    stroke = hex_color(el.get("strokeColor"), DEFAULT_STROKE)
    stroke_width = max(0.1, num(el, "strokeWidth", 1))
    stroke_style = el.get("strokeStyle") if isinstance(el.get("strokeStyle"), str) else "solid"
    opacity = max(0.0, min(100.0, num(el, "opacity", 100))) / 100.0
    attrs = []
    if opacity < 1.0:
        attrs.append('opacity="%s"' % round(opacity, 3))
    da = dash_array(stroke_style)
    if da:
        attrs.append('stroke-dasharray="%s"' % da)
    return stroke, stroke_width, attrs


def fill_attrs(el):
    """Approximate Excalidraw fillStyle deterministically (BR 11): solid fills
    opaque; hachure/cross-hatch use a translucent fill (straight-stroke
    approximation of the hand-drawn texture)."""
    fill = hex_color(el.get("backgroundColor"), DEFAULT_BG)
    if fill in ("", "transparent", None):
        return ""
    style = el.get("fillStyle") if isinstance(el.get("fillStyle"), str) else "solid"
    if style in ("hachure", "cross-hatch"):
        return ' fill="%s" fill-opacity="0.35"' % esc_attr(fill)
    return ' fill="%s"' % esc_attr(fill)


def polygon_points(cx, cy, w, h):
    return "%s,%s %s,%s %s,%s %s,%s" % (
        round(cx, 2), round(cy - h / 2.0, 2),
        round(cx + w / 2.0, 2), round(cy, 2),
        round(cx, 2), round(cy + h / 2.0, 2),
        round(cx - w / 2.0, 2), round(cy, 2),
    )


def points_to_str(points):
    return " ".join("%s,%s" % (round(float(p[0]), 2), round(float(p[1]), 2)) for p in points)


def render_element(el, idx):
    t = el.get("type")
    x = num(el, "x", 0)
    y = num(el, "y", 0)
    w = num(el, "width", 1)
    h = num(el, "height", 1)
    stroke, stroke_width, extra = common_attrs(el, x, y, w, h)
    stroke_attr = ' stroke="%s" stroke-width="%s"' % (esc_attr(stroke), round(stroke_width, 2))
    transform = render_transform(x, y, w, h, num(el, "angle", 0))

    if t == "rectangle":
        return '<rect x="%s" y="%s" width="%s" height="%s"%s%s%s%s/>' % (
            round(x, 2), round(y, 2), round(w, 2), round(h, 2),
            fill_attrs(el), stroke_attr, " ".join(extra), transform), None
    if t == "diamond":
        cx, cy = x + w / 2.0, y + h / 2.0
        return '<polygon points="%s"%s%s%s%s/>' % (
            polygon_points(cx, cy, w, h), fill_attrs(el), stroke_attr,
            " ".join(extra), transform), None
    if t == "ellipse":
        return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s"%s%s%s%s/>' % (
            round(x + w / 2.0, 2), round(y + h / 2.0, 2), round(w / 2.0, 2),
            round(h / 2.0, 2), fill_attrs(el), stroke_attr, " ".join(extra), transform), None
    if t in ("line", "arrow", "freedraw"):
        pts = el.get("points")
        if not isinstance(pts, list) or len(pts) < 2:
            warn("element %d (%s) has no usable points — skipped" % (idx, t))
            return "", None
        rel = [(float(p[0]), float(p[1])) for p in pts if isinstance(p, list) and len(p) >= 2]
        if len(rel) < 2:
            warn("element %d (%s) has no usable points — skipped" % (idx, t))
            return "", None
        abs_pts = [(x + px, y + py) for px, py in rel]
        points = points_to_str(abs_pts)
        if t == "freedraw":
            # thin freehand polyline, no fill (roughness approximated straight)
            return '<polyline points="%s" fill="none" stroke="%s" stroke-width="%s"%s%s/>' % (
                points, esc_attr(stroke), round(stroke_width, 2), " ".join(extra), transform), None
        marker = ""
        marker_def = None
        if t == "arrow":
            marker = ' marker-end="url(#arrowhead-%d)"' % idx
            marker_def = ('<marker id="arrowhead-%d" viewBox="0 0 10 10" refX="9" refY="5" '
                          'markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
                          '<path d="M0,0 L10,5 L0,10 z" fill="%s"/></marker>'
                          % (idx, esc_attr(stroke)))
        return '<polyline points="%s" fill="none"%s%s%s%s%s/>' % (
            points, marker, fill_attrs(el), stroke_attr, " ".join(extra), transform), marker_def
    if t == "text":
        text = str(el.get("text", ""))
        size = num(el, "fontSize", 20)
        family = {1: "Comic Sans MS, cursive", 2: "sans-serif", 3: "monospace"}.get(
            int(num(el, "fontFamily", 2)), "sans-serif")
        align = el.get("textAlign") if isinstance(el.get("textAlign"), str) else "left"
        anchor = {"center": "middle", "right": "end"}.get(align, "start")
        lines = text.splitlines() or [""]
        tspans = []
        for i, line in enumerate(lines):
            dy = round(i * size * 1.25, 2) if i else 0
            tspans.append('<tspan x="%s" dy="%s">%s</tspan>' % (
                round(x, 2), dy, esc_txt(line)))
        return '<text x="%s" y="%s" font-size="%s" font-family="%s" fill="%s" text-anchor="%s"%s>%s</text>' % (
            round(x, 2), round(y + size, 2), round(size, 2), esc_attr(family),
            esc_attr(stroke), anchor, transform, "".join(tspans)), None
    if t == "image":
        uri = el.get("dataURI") or el.get("dataUri") or el.get("data")
        if not isinstance(uri, str) or not uri.startswith("data:"):
            warn("element %d (image) has no data: URI — drawn as a placeholder" % idx)
            return ('<rect x="%s" y="%s" width="%s" height="%s" fill="none" stroke="%s" '
                    'stroke-width="%s" stroke-dasharray="4,3"%s/>' % (
                        round(x, 2), round(y, 2), round(w, 2), round(h, 2),
                        esc_attr(stroke), round(stroke_width, 2), transform)), None
        return '<image href="%s" x="%s" y="%s" width="%s" height="%s" preserveAspectRatio="none"%s/>' % (
            esc_attr(uri), round(x, 2), round(y, 2), round(w, 2), round(h, 2), transform), None
    raise ValueError("unsupported element type: %s" % t)  # unreachable (guarded)


def build_svg(elements, app_state):
    w, h, ox, oy = canvas_size(elements, app_state)
    bg = app_state.get("viewBackgroundColor")
    bg = hex_color(bg, "#ffffff") if isinstance(bg, str) else "#ffffff"
    markers = []
    body = []
    for idx, el in enumerate(elements):
        t = el.get("type")
        if t in KNOWN_OUT_OF_SCOPE:
            warn("element %d (%s) is outside the closed v1 subset — skipped" % (idx, t))
            continue
        if t not in SUPPORTED:
            raise ValueError("element %d has unknown type %r (schema violation)" % (idx, t))
        svg, marker_def = render_element(el, idx)
        if marker_def:
            markers.append(marker_def)
        if svg:
            body.append(svg)
    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">'
        % (int(round(w)), int(round(h)), int(round(w)), int(round(h))),
        '<rect x="0" y="0" width="%d" height="%d" fill="%s"/>' % (int(round(w)), int(round(h)), esc_attr(bg)),
    ]
    if markers:
        parts.append("<defs>%s</defs>" % "".join(markers))
    parts.append('<g transform="translate(%s %s)">' % (round(-ox, 2), round(-oy, 2)))
    parts.extend(body)
    parts.append("</g></svg>")
    return "\n".join(parts), int(round(w)), int(round(h))


def main(argv):
    if len(argv) != 3:
        sys.stderr.write("Usage: convert-excalidraw.py <input.json> <output.html>\n")
        return 2
    in_path, out_path = argv[1], argv[2]
    try:
        with open(in_path, "r", encoding="utf-8") as fh:
            raw = fh.read()
    except OSError as exc:
        sys.stderr.write("error: cannot read input JSON: %s\n" % exc)
        return 2
    try:
        elements, app_state = load_elements(raw)
    except ValueError as exc:
        sys.stderr.write("error: %s\n" % exc)
        return 2
    try:
        svg, w, h = build_svg(elements, app_state)
    except ValueError as exc:
        sys.stderr.write("error: %s\n" % exc)
        return 2
    stem = os.path.splitext(os.path.basename(out_path))[0]
    doc = (
        "<!DOCTYPE html>\n"
        '<html lang="en"><head><meta charset="utf-8">\n'
        "<title>%s</title>\n"
        "<style>@page{size:A4;margin:15mm}body{margin:0;background:#fff}svg{display:block}</style>\n"
        "</head><body>\n%s\n</body></html>\n"
    ) % (esc_txt(stem), svg)
    try:
        with open(out_path, "w", encoding="utf-8") as fh:
            fh.write(doc)
    except OSError as exc:
        sys.stderr.write("error: cannot write output html: %s\n" % exc)
        return 1
    sys.stdout.write("%dx%d\n" % (w, h))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
