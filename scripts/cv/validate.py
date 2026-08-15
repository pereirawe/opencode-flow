#!/usr/bin/env python3
"""Validate a hub.json against the canonical schema.

Usage:
    validate.py <hub.json>

Exit codes:
    0 - valid
    1 - invalid (prints errors)
    2 - usage error / missing file
"""
import json
import sys
import time


def check(cond, msg, errors):
    if not cond:
        errors.append(msg)


def validate_hub(hub):
    errors = []

    if not isinstance(hub, dict):
        return ["hub.json root must be an object"]

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
            since = item.get("since")
            if since is not None:
                check(
                    isinstance(since, str) and len(since) == 4 and since.isdigit() and 1900 <= int(since) <= 2099,
                    f"skills[{i}].since must be a year string (YYYY, 1900-2099), got {since!r}",
                    errors,
                )
                if isinstance(since, str) and since.isdigit():
                    check(
                        int(since) <= int(time.strftime("%Y")),
                        f"skills[{i}].since cannot be in the future ({since})",
                        errors,
                    )

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

    return errors


def main():
    if len(sys.argv) != 2:
        print("Usage: validate.py <hub.json>", file=sys.stderr)
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

    errors = validate_hub(hub)
    if errors:
        print(f"hub.json is INVALID ({len(errors)} error(s)):")
        for err in errors:
            print(f"  - {err}")
        return 1

    print("hub.json is VALID")
    return 0


if __name__ == "__main__":
    sys.exit(main())
