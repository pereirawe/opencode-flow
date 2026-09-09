#!/usr/bin/env python3
"""Validate docs/assets/person.json against the LinkedIn-carousel person schema
(skills/marketing/linkedin-carousel/person.schema.json).

Usage:
    person-validate.py <person.json> [<schema.json>]

Exit codes:
    0 - valid
    1 - invalid (prints errors)
    2 - usage error / missing file / unreadable schema

Validation strategy
-------------------
1. **jsonschema path (preferred)** — when the ``jsonschema`` package is
   installed, the person file is validated against the canonical schema with
   ``jsonschema.Draft7Validator`` (enforces required fields, types, the
   ``handle`` pattern and ``additionalProperties: false``).
2. **Hand-rolled fallback** — when ``jsonschema`` is not installed, a
   built-in mini-validator enforces the same structural contract: root
   object, required fields, property types, the ``handle`` regex, the
   ``schema`` const and unknown-key rejection. Guarantees zero-dependency
   behaviour: a schema-valid person always passes both paths.

BR 1 (issue #225): ``schema`` and ``name`` are required; ``headline``,
``handle`` (regex ^in/[A-Za-z0-9._-]+$), ``cta_text`` and ``logo_path`` are
optional. A missing optional field is valid — it is omitted/signalled by the
caller, never filled in.
"""
import json
import os
import re
import sys

DEFAULT_SCHEMA = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "..", "skills", "marketing", "linkedin-carousel", "person.schema.json",
)

HANDLE_RE = re.compile(r"^in/[A-Za-z0-9._-]+$")
KNOWN_TYPES = {"string": str, "object": dict, "array": list, "boolean": bool}


def check(cond, msg, errors):
    if not cond:
        errors.append(msg)


def _use_jsonschema():
    if os.environ.get("PERSON_VALIDATE_FALLBACK"):
        return False
    try:
        import jsonschema  # noqa: F401
    except ImportError:
        return False
    return True


def load_json(path, what):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"{what} not found: {path}", file=sys.stderr)
        return None
    except IsADirectoryError:
        print(f"path is a directory, not a file: {path}", file=sys.stderr)
        return None
    except json.JSONDecodeError as e:
        print(f"invalid JSON in {path}: {e}", file=sys.stderr)
        return None


def _validate_structure_jsonschema(person, schema, errors):
    from jsonschema import Draft7Validator

    validator = Draft7Validator(schema)
    for error in validator.iter_errors(person):
        path = "/".join(str(part) for part in error.absolute_path)
        location = f"{path}: " if path else ""
        errors.append(f"{location}{error.message}")


def _validate_structure_fallback(person, schema, errors):
    """Hand-rolled structural validation mirroring person.schema.json.

    The schema is the source of truth: required/properties/pattern/const are
    read from the schema file itself, so the fallback stays in sync without
    duplicating the field list in code.
    """
    if not isinstance(person, dict):
        errors.append("person.json root must be an object")
        return

    required = schema.get("required", [])
    props = schema.get("properties", {})

    for field in required:
        if field not in person:
            errors.append(f"missing required field: '{field}'")
        elif person[field] is None:
            errors.append(f"required field '{field}' must not be null")

    for field, value in person.items():
        if field not in props:
            errors.append(f"unknown field: '{field}' (additionalProperties: false)")
            continue
        spec = props[field]
        expected = KNOWN_TYPES.get(spec.get("type"))
        if expected is not None and not isinstance(value, expected):
            errors.append(f"'{field}' must be a {spec['type']}, got {type(value).__name__}")
            continue
        if isinstance(value, str):
            if spec.get("minLength") and len(value) < spec["minLength"]:
                errors.append(f"'{field}' must have at least {spec['minLength']} character(s)")
            pattern = spec.get("pattern")
            if pattern and not re.match(pattern, value):
                errors.append(
                    f"'{field}' does not match the required pattern {pattern!r} "
                    f"(got {value!r})"
                )
        if "const" in spec and value != spec["const"]:
            errors.append(f"'{field}' must be the constant {spec['const']!r}, got {value!r}")


def main():
    if len(sys.argv) not in (2, 3):
        print("Usage: person-validate.py <person.json> [<schema.json>]", file=sys.stderr)
        return 2

    person_path = sys.argv[1]
    schema_path = sys.argv[2] if len(sys.argv) == 3 else DEFAULT_SCHEMA

    schema = load_json(schema_path, "schema")
    if schema is None:
        return 2

    person = load_json(person_path, "person file")
    if person is None:
        # Unreadable/invalid JSON: 1 when the file exists but is malformed
        # (a data problem), 2 when it is missing (a usage problem).
        if os.path.isfile(person_path):
            return 1
        return 2

    errors = []
    if _use_jsonschema():
        _validate_structure_jsonschema(person, schema, errors)
    else:
        _validate_structure_fallback(person, schema, errors)

    if errors:
        print(f"person.json is INVALID ({len(errors)} error(s)):")
        for err in errors:
            print(f"  - {err}")
        return 1

    print("person.json is VALID")
    return 0


if __name__ == "__main__":
    sys.exit(main())
