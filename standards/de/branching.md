# Branching-Strategie

## Namenskonvention

```
issue-<id>-<slug>
```

- `<id>`: Issue-Nummer aus `known_issues.md` oder Remote-Tracker
- `<slug>`: Beschreibung in Kleinschreibung mit Bindestrichen

Beispiele:
- `issue-3-weak-url-validation`
- `issue-12-add-analytics-endpoint`

## Workflow

1. Basis-Branch wählen (Standard oder anderer existierender Branch, ausgewählt während PM-Promotion)
2. Basis-Branch auschecken und pullen
3. Feature-Branch `issue-<id>-<slug>` vom Basis-Branch erstellen
4. Änderungen implementieren und committen
5. Pushen und PR/MR öffnen
6. Nach dem Merge den Branch löschen
