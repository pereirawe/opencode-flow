# Suivi des Issues

Suivi à deux niveaux :
- **Global** : `~/.config/opencode/known_issues.md` — issues de configuration opencode
- **Projet** : `<projet>/.opencode/known_issues.md` — issues spécifiques au projet

## Format d'entrée

```markdown
### <id>. <titre>
- Status: backlog | ready | open | in-progress | in-review | in-qa | in-publish | resolved
- Type: bug | feat | doc | chore
- Severity: critical | high | medium | low
- Report: <nom-utilisateur> | <nom-modèle>
- Reviewers: <nombre> (défini lors de la promotion, défaut 1)
- Remote: - | #<id-distante>
- Location: <chemin-fichier>:<lignes>
- Description: <brève description>
- Impact: <qui ou quoi est affecté>
- Business rules: <règles métier spécifiques et contraintes domaine>
- Acceptance criteria: <ce qui doit être vrai pour clore l'issue>
- Suggested fix: <approche ou prochaine étape>
```

`Business rules:` est requis pour les types `feat`.
`Reviewers:` est défini lors de la promotion et utilisé lors de la revue senior et de la création MR.

## Cycle de vie

```
backlog -> ready -> open -> in-progress -> in-review -> in-qa -> in-publish -> resolved
```

| Statut | Signification |
|--------|---------------|
| `backlog` | Capturé, pas encore affiné |
| `ready` | Clair, approuvé, testable — prêt pour exécution |
| `open` | Sélectionné, en attente de création distante |
| `in-progress` | Issue distante existe, travail commencé |
| `in-review` | Revue senior terminée, en attente QA |
| `in-qa` | QA vérifie après-revue (peut revenir à `in-progress`) |
| `in-publish` | Committer approuvé, MR créé, en attente de merge |
| `resolved` | MR approuvé et fusionné (déplacé vers archive) |
