# Diretrizes de Revisão de Código

## Princípios

- Revisar por corretude, não por estilo (estilo deve ser automatizado)
- Seja construtivo e específico
- Separe pequenas sugestões de problemas bloqueantes
- Aprove quando satisfeito, solicite alterações quando não

## Checklist

- [ ] O código está correto e trata casos de borda
- [ ] Testes cobrem adequadamente a alteração
- [ ] Sem regressões de segurança ou performance
- [ ] Alterações de API estão documentadas
- [ ] Caminhos de erro são tratados
- [ ] Sem código morto ou comentado
- [ ] Segue as convenções do projeto

## Fluxo de Revisão

1. Committer faz a revisão inicial
2. Publish Requester atribui Senior Reviewers por domínio
3. Senior Reviewers revisam em paralelo
4. Todos os revisores devem aprovar antes do merge
