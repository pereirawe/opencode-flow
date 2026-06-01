# Estratégia de Ramificação

## Convenção de Nomenclatura

```
issue-<id>-<slug>
```

- `<id>`: número da issue do `known_issues.md` ou rastreador remoto
- `<slug>`: descrição em minúsculas com hífens

Exemplos:
- `issue-3-weak-url-validation`
- `issue-12-add-analytics-endpoint`

## Fluxo de Trabalho

1. Escolha o branch base (padrão ou outro branch existente escolhido durante a promoção do PM)
2. Faça checkout e pull do branch base
3. Crie o branch de feature `issue-<id>-<slug>` a partir do branch base
4. Implemente as alterações e faça commit
5. Envie e abra um PR/MR
6. Após o merge, exclua o branch
