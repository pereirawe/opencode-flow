# Issue-Tracking

Zweistufiges Issue-Tracking:
- **Global**: `~/.config/opencode/known_issues.md` — opencode-Konfigurationsebene
- **Projekt**: `<projekt>/.opencode/known_issues.md` — projektspezifische Issues

## Eintragsformat

```markdown
### <id>. <titel>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Report: <benutzername> | <modellname>
- Reviewers: <anzahl> (festgelegt bei Promotion, Standard 1)
- Remote: - | #<remote-id>
- Location: <dateipfad>:<zeilen>
- Description: <kurzbeschreibung>
- Impact: <wer oder was betroffen ist>
- Business rules: <spezifische Geschäftslogik und Domänenregeln>
- Acceptance criteria: <was für den Abschluss erfüllt sein muss>
- Suggested fix: <ansatz oder nächster Schritt>
```

`Business rules:` ist für `feat`-Typen erforderlich.
`Reviewers:` wird bei der Promotion festgelegt und bei Senior Review und MR-Erstellung verwendet.

## Lebenszyklus

```
backlog -> ready -> open -> in-progress -> in-review -> in-qa -> in-publish -> resolved
```

| Status | Bedeutung |
|--------|-----------|
| `backlog` | Erfasst, noch nicht verfeinert |
| `ready` | Klar, genehmigt, testbar — bereit zur Umsetzung |
| `open` | Ausgewählt, wartet auf Remote-Erstellung |
| `in-progress` | Remote-Issue existiert, Arbeit begonnen |
| `in-review` | Senior Review abgeschlossen, wartet auf QA |
| `in-qa` | QA prüft nach Review (kann zu `in-progress` zurückkehren) |
| `in-publish` | Committer genehmigt, MR erstellt, wartet auf Merge |
| `resolved` | MR genehmigt und gemergt (ins Archiv verschoben) |
