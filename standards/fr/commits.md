# Conventions de Commit

## Format

```
<type>: <description courte> (#<id-issue>)
```

## Types

| Type | Utilisation |
|------|-------------|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `refactor` | Restructuration de code |
| `test` | Modifications de tests |
| `docs` | Documentation |
| `chore` | Maintenance, configuration, dépendances |

## Exemples

```
feat: ajouter un endpoint analytics (#6)
fix: valider le schéma d'URL avant fetch (#3)
refactor: extraire la couche service du handler (#7)
docs: mettre à jour la documentation API (#12)
```

## Règles

- Utiliser l'impératif présent
- Première ligne sous 72 caractères
- Référencer le numéro d'issue entre parenthèses
- Corps optionnel mais encouragé pour les changements complexes
