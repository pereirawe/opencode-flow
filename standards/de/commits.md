# Commit-Konventionen

## Format

```
<typ>: <kurzbeschreibung> (#<issue-id>)
```

## Typen

| Typ | Verwendung |
|-----|------------|
| `feat` | Neue Funktionalität |
| `fix` | Fehlerbehebung |
| `refactor` | Code-Umstrukturierung |
| `test` | Test-Änderungen |
| `docs` | Dokumentation |
| `chore` | Wartung, Konfiguration, Abhängigkeiten |

## Beispiele

```
feat: Analytics-Endpunkt hinzufügen (#6)
fix: URL-Schema vor Fetch validieren (#3)
refactor: Dienstschicht aus Handler extrahieren (#7)
docs: API-Dokumentation aktualisieren (#12)
```

## Regeln

- Imperativ Präsens verwenden
- Erste Zeile unter 72 Zeichen halten
- Issue-Nummer in Klammern referenzieren
- Textkörper optional, aber bei komplexen Änderungen empfohlen
