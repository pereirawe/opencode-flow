#!/usr/bin/env python3
"""Validate a hub.json against the canonical schema (scripts/cv/schema.json).

Usage:
    validate.py <hub.json>

Exit codes:
    0 - valid
    1 - invalid (prints errors)
    2 - usage error / missing file / missing schema

Validation strategy
-------------------
1. **jsonschema path (preferred)** — when the ``jsonschema`` package is
   installed, the hub is validated against ``schema.json`` with
   ``jsonschema.Draft7Validator``. The schema enforces the required sections,
   nested required fields, types, enums, the ``since``/``year`` pattern and
   the ``additionalProperties`` contract (unknown keys are rejected).
2. **Hand-rolled fallback** — when ``jsonschema`` is not installed, a
   built-in validator enforces the same structural contract (required
   sections, nested required fields, basic types). The fallback is
   intentionally less strict than the jsonschema path (enums and
   unknown-key rejection are not enforced) — it guarantees zero dependency
   regression: every hub that is valid per the schema passes both paths.
3. **Shared semantic checks** — both paths run the same semantic checks on
   top of the structural validation:
   - email format (basic regex) on ``personal_info.email``;
   - URL format (basic regex) on ``personal_info.site/github/linkedin``,
     ``links[].url``, ``certifications[].url`` and ``projects[].link``;
   - ``summary_i18n`` keys must be a subset of {pt, en, es} and the values
     must be strings;
   - cross-field date consistency: ``experience.start_date <= end_date`` and
     ``education.start_date <= end_date`` (an end of "present"/"atual" or a
     missing end is treated as open-ended); ``certifications.year <=
     certifications.expiry_date`` year when both parse; ``skills[].since``
     and ``certifications[].year`` must be 4-digit years (1900-2099) not in
     the future (<= current year).

Set the environment variable ``CV_VALIDATE_FALLBACK=1`` to force the
hand-rolled path even when jsonschema is installed (used by the test suite
to verify both paths agree on the shared checks).
"""
import json
import os
import re
import sys
import time

SCHEMA_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "schema.json")

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
URL_RE = re.compile(r"^[a-z][a-z0-9+.-]*://\S+$", re.IGNORECASE)
OPEN_ENDED_END = {"present", "atual"}
LOCALE_KEYS = {"pt", "en", "es"}


def check(cond, msg, errors):
    if not cond:
        errors.append(msg)


def _use_jsonschema():
    """True when the jsonschema package should be used (default), False when
    it is unavailable or explicitly disabled via CV_VALIDATE_FALLBACK."""
    if os.environ.get("CV_VALIDATE_FALLBACK"):
        return False
    try:
        import jsonschema  # noqa: F401
    except ImportError:
        return False
    return True


def load_schema():
    """Load the canonical schema.json placed next to this script."""
    with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def _validate_structure_jsonschema(hub, schema, errors):
    """Structural validation via the jsonschema library (schema is the
    source of truth). Formats are intentionally NOT checked here — the
    shared semantic checks below apply the same basic regexes on both paths."""
    from jsonschema import Draft7Validator

    validator = Draft7Validator(schema)
    for error in validator.iter_errors(hub):
        path = "/".join(str(part) for part in error.absolute_path)
        location = f"{path}: " if path else ""
        errors.append(f"{location}{error.message}")


def _validate_structure_fallback(hub, errors):
    """Hand-rolled structural validation used when jsonschema is absent.

    Enforces the same structural contract as schema.json — required sections,
    nested required fields and basic types. It intentionally does not enforce
    enums or unknown-key rejection (the jsonschema path does), keeping the
    fallback a zero-dependency, best-effort validator: a schema-valid hub
    always passes here.
    """
    if not isinstance(hub, dict):
        errors.append("hub.json root must be an object")
        return

    required_sections = [
        "personal_info", "summary", "experience", "education",
        "skills", "certifications", "projects", "languages", "links",
    ]
    for section in required_sections:
        check(section in hub, f"missing required section: '{section}'", errors)

    personal = hub.get("personal_info", {})
    if isinstance(personal, dict):
        check("name" in personal and personal.get("name"), "personal_info.name is required", errors)
    else:
        check(False, "personal_info must be an object", errors)

    summary = hub.get("summary", "")
    check(isinstance(summary, str), "summary must be a string", errors)

    for array_field in ["experience", "education", "skills", "certifications", "projects", "languages", "links"]:
        val = hub.get(array_field, [])
        check(isinstance(val, list), f"'{array_field}' must be an array", errors)
        if isinstance(val, list):
            for i, item in enumerate(val):
                if not isinstance(item, dict):
                    errors.append(f"{array_field}[{i}] must be an object")

    for i, item in enumerate(hub.get("experience", [])):
        if isinstance(item, dict):
            check(item.get("company"), f"experience[{i}].company is required", errors)
            check(item.get("title"), f"experience[{i}].title is required", errors)

    for i, item in enumerate(hub.get("education", [])):
        if isinstance(item, dict):
            check(item.get("institution"), f"education[{i}].institution is required", errors)
            check(item.get("course"), f"education[{i}].course is required", errors)

    for i, item in enumerate(hub.get("skills", [])):
        if isinstance(item, dict):
            check(item.get("name"), f"skills[{i}].name is required", errors)

    for i, item in enumerate(hub.get("certifications", [])):
        if isinstance(item, dict):
            check(item.get("name"), f"certifications[{i}].name is required", errors)

    for i, item in enumerate(hub.get("projects", [])):
        if isinstance(item, dict):
            check(item.get("name"), f"projects[{i}].name is required", errors)

    for i, item in enumerate(hub.get("languages", [])):
        if isinstance(item, dict):
            check(item.get("language"), f"languages[{i}].language is required", errors)

    for i, item in enumerate(hub.get("links", [])):
        if isinstance(item, dict):
            check(item.get("name"), f"links[{i}].name is required", errors)
            check(item.get("url"), f"links[{i}].url is required", errors)


def _validate_formats(hub, errors):
    """Basic email/URL format checks (shared by both validation paths)."""
    personal = hub.get("personal_info")
    if isinstance(personal, dict):
        email = personal.get("email")
        if isinstance(email, str) and email and not EMAIL_RE.match(email):
            check(False, f"personal_info.email is not a valid email address: {email!r}", errors)
        for field in ("site", "github", "linkedin"):
            value = personal.get(field)
            if isinstance(value, str) and value and not URL_RE.match(value):
                check(False, f"personal_info.{field} is not a valid URL: {value!r}", errors)

    for i, item in enumerate(hub.get("links", [])):
        if isinstance(item, dict):
            url = item.get("url")
            if isinstance(url, str) and url and not URL_RE.match(url):
                check(False, f"links[{i}].url is not a valid URL: {url!r}", errors)

    for i, item in enumerate(hub.get("certifications", [])):
        if isinstance(item, dict):
            url = item.get("url")
            if isinstance(url, str) and url and not URL_RE.match(url):
                check(False, f"certifications[{i}].url is not a valid URL: {url!r}", errors)

    for i, item in enumerate(hub.get("projects", [])):
        if isinstance(item, dict):
            link = item.get("link")
            if isinstance(link, str) and link and not URL_RE.match(link):
                check(False, f"projects[{i}].link is not a valid URL: {link!r}", errors)


def _validate_summary_i18n(hub, errors):
    """summary_i18n must be an object keyed by pt/en/es with string values."""
    value = hub.get("summary_i18n")
    if value is None:
        return
    if not isinstance(value, dict):
        check(False, "summary_i18n must be an object", errors)
        return
    for key in value:
        if key not in LOCALE_KEYS:
            check(
                False,
                f"summary_i18n has an invalid locale key {key!r} (allowed: pt, en, es)",
                errors,
            )
    for key, text in value.items():
        if not isinstance(text, str):
            check(False, f"summary_i18n.{key} must be a string", errors)


def _parse_year(value):
    """Parse a 4-digit year string within 1900-2099; None when not a valid
    year."""
    if not isinstance(value, str):
        return None
    v = value.strip()
    if len(v) != 4 or not v.isdigit():
        return None
    year = int(v)
    if not (1900 <= year <= 2099):
        return None
    return year


def _date_parts(value, side="start"):
    """Parse 'YYYY', 'YYYY-MM' or 'YYYY-MM-DD' into a comparable (y, m, d)
    tuple.

    Missing month/day default to the earliest bound for a start date and the
    latest bound for an end date, so '2021' as an end is treated as
    end-of-2021. Returns None when the value is missing, open-ended
    ('present'/'atual') or not parseable within the 1900-2099 range.
    """
    if not isinstance(value, str):
        return None
    v = value.strip()
    if not v or v.lower() in OPEN_ENDED_END:
        return None
    parts = v.split("-")
    try:
        year = int(parts[0])
        month = int(parts[1]) if len(parts) > 1 and parts[1] else None
        day = int(parts[2]) if len(parts) > 2 and parts[2] else None
    except ValueError:
        return None
    if not (1900 <= year <= 2099):
        return None
    if month is not None and not (1 <= month <= 12):
        return None
    if day is not None and not (1 <= day <= 31):
        return None
    if side == "end":
        month = month if month is not None else 12
        day = day if day is not None else 28
    else:
        month = month if month is not None else 1
        day = day if day is not None else 1
    return (year, month, day)


def _validate_cross_field_dates(hub, errors):
    """Cross-field date consistency (shared by both validation paths):

    - experience/education: start_date must not be after end_date (an end of
      'present'/'atual' or a missing end is open-ended);
    - skills[].since and certifications[].year: 4-digit year (1900-2099),
      not in the future (<= current year);
    - certifications: year (issue) must not be after the expiry_date year.
    """
    current_year = int(time.strftime("%Y"))

    for section in ("experience", "education"):
        for i, item in enumerate(hub.get(section, [])):
            if not isinstance(item, dict):
                continue
            start = item.get("start_date")
            end = item.get("end_date")
            start_parts = _date_parts(start, "start")
            end_parts = _date_parts(end, "end")
            if start_parts is not None and end_parts is not None and start_parts > end_parts:
                check(
                    False,
                    f"{section}[{i}].start_date ({start!r}) must not be after end_date ({end!r})",
                    errors,
                )

    for i, item in enumerate(hub.get("skills", [])):
        if isinstance(item, dict):
            since = item.get("since")
            year = _parse_year(since)
            if since is not None and year is None:
                check(
                    False,
                    f"skills[{i}].since must be a year string (YYYY, 1900-2099), got {since!r}",
                    errors,
                )
            elif year is not None and year > current_year:
                check(False, f"skills[{i}].since cannot be in the future ({since})", errors)

    for i, item in enumerate(hub.get("certifications", [])):
        if isinstance(item, dict):
            year_str = item.get("year")
            year = _parse_year(year_str)
            if year_str is not None and year is None:
                check(
                    False,
                    f"certifications[{i}].year must be a year string (YYYY, 1900-2099), got {year_str!r}",
                    errors,
                )
            elif year is not None and year > current_year:
                check(False, f"certifications[{i}].year cannot be in the future ({year_str})", errors)
            expiry = item.get("expiry_date")
            expiry_parts = _date_parts(expiry, "end")
            if year is not None and expiry_parts is not None and year > expiry_parts[0]:
                check(
                    False,
                    f"certifications[{i}].year ({year_str!r}) must not be after expiry_date ({expiry!r})",
                    errors,
                )


def validate_hub(hub, schema):
    """Validate a loaded hub against the schema. Returns a list of error
    strings (empty when valid)."""
    errors = []

    if _use_jsonschema():
        _validate_structure_jsonschema(hub, schema, errors)
    else:
        _validate_structure_fallback(hub, errors)

    # Shared semantic checks — identical on both validation paths.
    _validate_formats(hub, errors)
    _validate_summary_i18n(hub, errors)
    _validate_cross_field_dates(hub, errors)

    return errors


def main():
    if len(sys.argv) != 2:
        print("Usage: validate.py <hub.json>", file=sys.stderr)
        return 2

    try:
        schema = load_schema()
    except (OSError, json.JSONDecodeError) as e:
        print(f"could not load schema {SCHEMA_PATH}: {e}", file=sys.stderr)
        return 2

    path = sys.argv[1]
    try:
        with open(path, "r", encoding="utf-8") as f:
            hub = json.load(f)
    except IsADirectoryError:
        print(f"path is a directory, not a file: {path}", file=sys.stderr)
        return 2
    except FileNotFoundError:
        print(f"file not found: {path}", file=sys.stderr)
        return 2
    except json.JSONDecodeError as e:
        print(f"invalid JSON in {path}: {e}", file=sys.stderr)
        return 1

    errors = validate_hub(hub, schema)
    if errors:
        print(f"hub.json is INVALID ({len(errors)} error(s)):")
        for err in errors:
            print(f"  - {err}")
        return 1

    print("hub.json is VALID")
    return 0


if __name__ == "__main__":
    sys.exit(main())
