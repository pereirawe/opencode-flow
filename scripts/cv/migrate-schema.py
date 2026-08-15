#!/usr/bin/env python3
"""Migrate a hub.json from the legacy Portuguese schema to the English schema.

The career sector standardized hub.json keys and enum values to English
(issue #64). This helper converts an existing hub built with the old
Portuguese keys (dados_pessoais, experiencia, resumo, ...) to the canonical
English schema (personal_info, experience, summary, ...), including enum
value translation (e.g. "Concluído" -> "completed", "iniciante" -> "beginner").

It is idempotent: an already-English hub passes through unchanged (English
keys and enum values are never re-mapped), so it is safe to re-run.

Usage:
    migrate-schema.py <hub.json> [--output <out.json>] [--validate <cmd>]

    <hub.json>        Path to the hub to migrate (required).
    --output <path>   Write the migrated hub to <path>. Default: in place.
    --validate <cmd>  Optional: run <cmd> <out> after migrating to validate
                      the result (e.g. the path to validate.py). The command
                      is run with the output path appended. Non-zero exit is
                      reported as a warning, not a failure.

Exit codes:
    0 - migrated (or already English) successfully
    1 - input error (missing/unreadable/invalid JSON)
"""
import argparse
import json
import shlex
import subprocess
import sys

# Context-free key mapping: the same Portuguese key always maps to the same
# English key (exact match). Keys already in English pass through unchanged.
KEY_MAP = {
    # top-level sections
    "dados_pessoais": "personal_info",
    "resumo": "summary",
    "resumo_i18n": "summary_i18n",
    "experiencia": "experience",
    "educacao": "education",
    "certificacoes": "certifications",
    "idiomas": "languages",
    "projetos": "projects",
    "data_geracao": "generated_date",
    "fontes": "sources",
    # personal_info
    "nome": "name",
    "apelido": "nickname",
    "titulo_profissional": "professional_title",
    "telefone": "phone",
    "cidade": "city",
    "estado": "state",
    "pais": "country",
    "data_nascimento": "date_of_birth",
    "disponibilidade": "availability",
    "pretensao_salarial": "salary_expectation",
    "visto_trabalho": "work_visa",
    # experience / education
    "empresa": "company",
    "cargo": "title",
    "instituicao": "institution",
    "curso": "course",
    "tipo": "type",
    "inicio": "start_date",
    "fim": "end_date",
    "atual": "current",
    "local": "location",
    "conquistas": "achievements",
    "responsabilidades": "responsibilities",
    "tecnologias": "technologies",
    "linguagem": "language",
    # skills
    "categoria": "category",
    "nivel": "level",
    "desde": "since",
    "anos_experiencia": "years_of_experience",
    "importancia": "importance",
    # certifications
    "emissor": "issuer",
    "ano": "year",
    "validade": "expiry_date",
    # projects
    "descricao": "description",
    "impacto": "impact",
    "relevancia": "relevance",
    # languages
    "idioma": "language",
    "nota_escala": "scale_note",
    # cv-optimizer tasks.json (auxiliary structured output)
    "gerado_em": "generated_at",
    "secoes": "sections",
    "tarefas": "tasks",
    "acao": "action",
    "esforco": "effort",
    "prioridade": "priority",
    "vaga_alvo": "target_role",
}

# Context-aware enum value mapping: section array -> field -> {pt: en}.
ENUM_MAPS = {
    "experience": {
        "end_date": {
            "atual": "present",
        },
        "type": {
            "Estágio": "Internship",
            "Tempo integral": "Full-time",
            "Meio período": "Part-time",
            "Remoto": "Remote",
            "Presencial": "On-site",
            "Híbrido": "Hybrid",
        },
    },
    "education": {
        "type": {
            "Graduação": "Bachelor's degree",
            "Pós-graduação": "Postgraduate",
            "Mestrado": "Master's degree",
            "Doutorado": "Doctorate",
            "Técnico": "Technical",
            "Curso livre": "Short course",
            "Ensino médio": "High school",
        },
        "status": {
            "Concluído": "completed",
            "Em andamento": "in_progress",
            "Trancado": "suspended",
            "Interrompido": "interrupted",
        },
    },
    "skills": {
        "level": {
            "iniciante": "beginner",
            "usar": "intermediate",
            "avancado": "advanced",
            "especialista": "expert",
        },
        "category": {
            "linguagem": "language",
            "ferramenta": "tool",
            "nuvem": "cloud",
            "dado": "data",
            "soft-skill": "soft_skill",
            "metodologia": "methodology",
            "outro": "other",
        },
        "importance": {
            "principal": "primary",
            "secundaria": "secondary",
        },
    },
    "projects": {
        "relevance": {
            "alta": "high",
            "media": "medium",
            "baixa": "low",
        },
    },
    "languages": {
        "level": {
            "básico": "basic",
            "intermediário": "intermediate",
            "avançado": "advanced",
            "fluente": "fluent",
            "nativo": "native",
            "leitura": "reading",
            "conversação": "conversational",
        },
    },
}

# Top-level fields whose values are locale-keyed free text (pt/en/es) — the
# inner keys are locale codes and must never be translated or mapped.
LOCALE_CONTAINER_KEYS = {"summary_i18n", "resumo_i18n"}


def transform_value(value, section=None):
    """Recursively migrate a JSON value's keys (context-free mapping)."""
    if isinstance(value, dict):
        result = {}
        for key, child in value.items():
            new_key = KEY_MAP.get(key, key)
            if key in LOCALE_CONTAINER_KEYS:
                # Locale containers hold free text keyed by locale code.
                result[new_key] = child
                continue
            child_section = section
            if new_key in ENUM_MAPS:
                child_section = new_key
            result[new_key] = transform_value(child, child_section)
        return result
    if isinstance(value, list):
        return [transform_value(item, section) for item in value]
    return value


def translate_enums_in_section(section_entries, section):
    """Translate enum values inside one section array (context-aware)."""
    field_maps = ENUM_MAPS.get(section, {})
    if not field_maps or not isinstance(section_entries, list):
        return
    for item in section_entries:
        if not isinstance(item, dict):
            continue
        for field, value_map in field_maps.items():
            value = item.get(field)
            if isinstance(value, str) and value in value_map:
                item[field] = value_map[value]


def migrate_hub(hub):
    """Migrate a loaded hub (dict) to the English schema, in place."""
    # 1. Context-free key mapping at the top level and nested objects
    #    (including the entries inside every section array).
    migrated = {}
    for key, child in hub.items():
        new_key = KEY_MAP.get(key, key)
        migrated[new_key] = child
    hub.clear()
    hub.update(migrated)

    for key, child in list(hub.items()):
        if key not in LOCALE_CONTAINER_KEYS:
            hub[key] = transform_value(child, None)

    # 2. Context-aware enum value translation for each section array.
    for section in ENUM_MAPS:
        if section in hub:
            translate_enums_in_section(hub[section], section)

    # 3. Bump the schema version so tooling can detect migrated hubs.
    hub["version"] = 2
    return hub


def main():
    parser = argparse.ArgumentParser(
        description="Migrate a hub.json from the legacy Portuguese schema to the English schema (issue #64).",
    )
    parser.add_argument("hub", help="path to the hub.json to migrate")
    parser.add_argument("--output", "-o", help="output path (default: in place)")
    parser.add_argument(
        "--validate",
        help="optional validator command run against the output (e.g. a path to validate.py)",
    )
    args = parser.parse_args()

    try:
        with open(args.hub, "r", encoding="utf-8") as f:
            hub = json.load(f)
    except IsADirectoryError:
        print(f"error: path is a directory, not a file: {args.hub}", file=sys.stderr)
        return 1
    except FileNotFoundError:
        print(f"error: file not found: {args.hub}", file=sys.stderr)
        return 1
    except json.JSONDecodeError as e:
        print(f"error: invalid JSON in {args.hub}: {e}", file=sys.stderr)
        return 1

    migrate_hub(hub)

    output = args.output or args.hub
    try:
        with open(output, "w", encoding="utf-8") as f:
            json.dump(hub, f, ensure_ascii=False, indent=2)
            f.write("\n")
    except OSError as e:
        print(f"error: could not write {output}: {e}", file=sys.stderr)
        return 1

    if args.validate:
        cmd = shlex.split(args.validate) + [output]
        try:
            proc = subprocess.run(cmd, capture_output=True, text=True)
        except FileNotFoundError:
            print(f"warning: validator command not found: {args.validate}", file=sys.stderr)
        else:
            if proc.returncode != 0:
                print(
                    f"warning: validator returned {proc.returncode} for {output}:\n"
                    f"{proc.stdout}{proc.stderr}",
                    file=sys.stderr,
                )

    print(f"migrated hub.json to the English schema: {output} (version 2)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
