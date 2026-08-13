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


def check(cond, msg, errors):
    if not cond:
        errors.append(msg)


def validate_hub(hub):
    errors = []

    if not isinstance(hub, dict):
        return ["hub.json root must be an object"]

    required_sections = [
        "dados_pessoais", "resumo", "experiencia", "educacao",
        "skills", "certificacoes", "projetos", "idiomas", "links",
    ]
    for section in required_sections:
        check(section in hub, f"missing required section: '{section}'", errors)

    dados = hub.get("dados_pessoais", {})
    if isinstance(dados, dict):
        check("nome" in dados and dados.get("nome"), "dados_pessoais.nome is required", errors)

    for array_field in ["experiencia", "educacao", "skills", "certificacoes", "projetos", "idiomas", "links"]:
        val = hub.get(array_field, [])
        check(isinstance(val, list), f"'{array_field}' must be an array", errors)
        if isinstance(val, list):
            for i, item in enumerate(val):
                if not isinstance(item, dict):
                    errors.append(f"{array_field}[{i}] must be an object")

    for i, item in enumerate(hub.get("experiencia", [])):
        if isinstance(item, dict):
            check(item.get("empresa"), f"experiencia[{i}].empresa is required", errors)
            check(item.get("cargo"), f"experiencia[{i}].cargo is required", errors)

    for i, item in enumerate(hub.get("educacao", [])):
        if isinstance(item, dict):
            check(item.get("instituicao"), f"educacao[{i}].instituicao is required", errors)
            check(item.get("curso"), f"educacao[{i}].curso is required", errors)

    for i, item in enumerate(hub.get("skills", [])):
        if isinstance(item, dict):
            check(item.get("nome"), f"skills[{i}].nome is required", errors)

    for i, item in enumerate(hub.get("certificacoes", [])):
        if isinstance(item, dict):
            check(item.get("nome"), f"certificacoes[{i}].nome is required", errors)

    for i, item in enumerate(hub.get("projetos", [])):
        if isinstance(item, dict):
            check(item.get("nome"), f"projetos[{i}].nome is required", errors)

    for i, item in enumerate(hub.get("idiomas", [])):
        if isinstance(item, dict):
            check(item.get("idioma"), f"idiomas[{i}].idioma is required", errors)

    for i, item in enumerate(hub.get("links", [])):
        if isinstance(item, dict):
            check(item.get("nome"), f"links[{i}].nome is required", errors)
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
