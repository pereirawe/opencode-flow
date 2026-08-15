## /ocf:cv-optimize <diretório-do-candidato>

---
description: Analyze the candidate profile and generate an improvement plan — profile score, target job profiles, CLT vs PJ salary ranges, context gaps, and a prioritized action plan (analise-perfil.md + PDF)
---

Analisa o perfil de um candidato a partir do hub (construído com
`/ocf:cv-hub`) e gera um relatório de otimização: score do perfil por seção,
qualificações gerais, perfis de vagas-alvo, pretensão salarial de mercado
CLT vs PJ (faixas `[INFERIDO]`), lacunas de contexto e plano de ações
priorizado. O objetivo é aprimorar muito o perfil antes de gerar currículos
direcionados com `/ocf:cv-tailor`.

### Uso

```
/ocf:cv-optimize ~/career/maria-silva
```

### Fluxo

1. **Verificar o hub** — se `~/career/<candidato>/hub.json` não existir ou
   for inválido, invoca o fluxo do `/ocf:cv-hub` primeiro (perguntando os
   caminhos das fontes) e então continua.
2. **Validar** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`.
3. **Invocar o agente** `career/cv-optimizer` via `task:` com o diretório do
   candidato.
4. **Analisar** — o agente produz `analise-perfil.md` com:
   - Score do perfil (0-100 por seção + global, com justificativa)
   - Qualificações gerais (senioridade, skills, pontos fortes/fraques)
   - Perfis de vagas-alvo (offline — nunca vagas concretas)
   - Faixas salariais CLT vs PJ (todas `[INFERIDO]` para revisão humana)
   - Lacunas de contexto no hub
   - Plano de ações priorizado (impacto × esforço)
5. **Gerar PDF** — o agente renderiza `analise-perfil.html` e roda
   `bash $SCRIPTS_DIR/cv/pdf.sh` para produzir `analise-perfil.pdf` (A4),
   facilitando leitura/análise.
6. **Reportar** — caminho do relatório (.md e .pdf), score global, top ações
   e itens `[INFERIDO]` que o candidato deve revisar.

### Regras

- NENHUM dado inventado — toda inferência marcada `[INFERIDO]`.
- O agente NÃO modifica `hub.json` — apenas reporta.
- Sem busca web — vagas-alvo são perfis genéricos derivados da análise offline.
- Nenhum dado sensível aparece no relatório.
- NENHUM cabeçalho de metadados no relatório ("Gerado em:", "Fonte:",
  "Ferramenta:", "Nota:") — comece direto pelo conteúdo; `[INFERIDO]` inline.
- Anos de experiência de skills calculados dinamicamente (ano atual − `desde`)
  sempre que `desde` existir no hub.
