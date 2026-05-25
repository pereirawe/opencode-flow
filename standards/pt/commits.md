# Convenções de Commit

## Formato

```
<tipo>: <descrição curta> (#<id-da-issue>)
```

## Tipos

| Tipo | Uso |
|------|-----|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `refactor` | Reestruturação de código |
| `test` | Alterações em testes |
| `docs` | Documentação |
| `chore` | Manutenção, config, dependências |

## Exemplos

```
feat: adicionar endpoint de analytics (#6)
fix: validar esquema de URL antes do fetch (#3)
refactor: extrair camada de serviço do handler (#7)
docs: atualizar documentação da API (#12)
```

## Regras

- Use o presente imperativo
- Mantenha a primeira linha com menos de 72 caracteres
- Referencie o número da issue entre parênteses
- Corpo é opcional, mas encorajado para alterações complexas
