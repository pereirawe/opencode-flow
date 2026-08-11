---
name: test-runner
description: Entrypoint único de testes com cache de resultados (fingerprint) para agentes de development. Use quando precisar validar testes (check/run/status), consumir um cache fresco sem re-executar, ou rodar a suite para o próprio uso quando não há cache. Nunca invoque comandos de teste ad hoc (go test, pytest, npm test) — use este runner.
---

# Test Runner

Entrypoint único de testes para agentes de development. Elimina execuções
repetidas da mesma suite com saída idêntica ao longo do pipeline e padroniza o
diagnóstico de ambiente.

## Protocolo

```bash
scripts/test-runner.sh --check    # cache fresco? exit 0 + caminho do relatório; senão exit 3
scripts/test-runner.sh --run      # executa a suite (ou reutiliza cache fresco), imprime resumo + exit code
scripts/test-runner.sh --status   # estado legível do runner/cache/fingerprint
```

Args adicionais após `--` são passados ao comando de teste
(ex.: `test-runner.sh --run -- -run TestFoo`).

## Regras para o agente

1. **Sempre use o runner** — nunca `go test`, `pytest`, `npm test` ad hoc.
2. **Cache fresco e passando → reutilize.** `--check` com exit 0 significa que o
   código não mudou desde a última execução **e** a suite passou: use o
   relatório cacheado, não re-rote.
3. **Sem cache válido → rode para o seu próprio uso.** `--check` exit 3 não é
   bloqueio: rode `--run` e use o resultado para a sua validação.
4. **Cache nunca bloqueia.** Se o script falhar por qualquer motivo, rode os
   testes diretamente e siga com o resultado.
5. **Testes pontuais do domínio** (ex.: um teste específico que você quer
   verificar) são livres — use `--run -- <filtro>`. Runs filtrados NUNCA tocam
   o cache compartilhado: executam de verdade e não afetam o sinal "suite
   passou" que check/committer/pre_commit consomem.
6. **Exit codes** de `--run`: `0` = suite passou; `1` = suite falhou; `2` =
   impossível rodar (sem runner/suite) — trata `2` como "sem testes", não como
   falha. O relatório completo fica em `.opencode/test-cache/<branch>-<runner>.log`.
7. **`--check`** exit 0 apenas quando há cache fresco E a última execução passou
   (`exit_code=0`). Cache fresco de suite falhada → exit 3.

## Onde o cache fica

```
.opencode/test-cache/<branch>-<runner>.result   # fingerprint + exit_code + timestamp
.opencode/test-cache/<branch>-<runner>.log      # saída completa da última execução
```

O diretório `.opencode/test-cache/` é gitignored. O fingerprint é derivado do
HEAD do git + arquivos de código/teste alterados — qualquer mudança mínima
invalida o cache e força re-execução.

## Fallback

Sem git repo, o runner usa fingerprint por conteúdo (ainda funcional). Sem
runner detectado, o runner diagnostica claramente e o agente deve rodar os
testes do projeto diretamente, reportando o resultado para o próprio uso.
