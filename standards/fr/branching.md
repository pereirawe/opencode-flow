# Stratégie de Branche

## Convention de nommage

```
issue-<id>-<slug>
```

- `<id>` : numéro d'issue de `known_issues.md` ou du tracker distant
- `<slug>` : description en minuscules avec tirets

Exemples :
- `issue-3-weak-url-validation`
- `issue-12-add-analytics-endpoint`

## Workflow

1. Choisir la branche de base (par défaut ou autre branche existante choisie lors de la promotion PM)
2. Checkout et pull de la branche de base
3. Créer la branche de fonctionnalité `issue-<id>-<slug>` depuis la branche de base
4. Implémenter les modifications et committer
5. Pusher et ouvrir un PR/MR
6. Après le merge, supprimer la branche
