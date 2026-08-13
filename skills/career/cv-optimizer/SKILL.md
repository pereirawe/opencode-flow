---
name: cv-optimizer
description: Análise e otimização do perfil de um candidato a partir do hub.json — qualificações gerais, score do perfil (0-100 por seção + global), perfis de vagas-alvo, pretensão salarial de mercado CLT vs PJ (faixas [INFERIDO]), lacunas de contexto e plano de ações priorizado. Use quando precisar analisar e melhorar o perfil de um candidato (comando ocf:cv-optimize). Setor career.
---

# CV Optimizer — análise e plano de melhorias do perfil

Analisa o `hub.json` do candidato (construído pelo `cv-hub`) e produz um
relatório acionável com score do perfil, vagas-alvo, mercado salarial e plano
de ações priorizado. O objetivo é **aprimorar muito o perfil** antes de gerar
currículos direcionados (`cv-tailor`).

## Pré-requisito

`~/carreira/<nome-candidato>/hub.json` válido (validado por
`python3 $SCRIPTS_DIR/cv/validate.py`). Se não existir, o fluxo `ocf:cv-hub`
deve ser executado primeiro (o comando `ocf:cv-optimize` já trata isso).

## Saída

```
~/carreira/<nome-candidato>/analise-perfil.md   # relatório único (principal)
~/carreira/<nome-candidato>/tasks.json          # opcional — tarefas estruturadas
```

O relatório NÃO modifica `hub.json` — apenas reporta.

## Protocolo de análise

### 1. Validar e carregar o hub

1. Rode `python3 $SCRIPTS_DIR/cv/validate.py hub.json`. Exit 0 → continuar.
2. Hub ausente/inválido → informar que o `ocf:cv-hub` deve rodar primeiro e
   interromper (não corrigir dados manualmente).
3. Carregue o JSON e extraia: dados pessoais, resumo, experiência, educação,
   skills (com níveis), certificações, projetos, idiomas, links.

### 2. Analisar qualificações gerais

- **Senioridade inferida** — pela soma de anos de experiência, cargos mais
  recentes e profundidade das skills (júnior/pleno/sênior/especialista/lead).
  Sempre `[INFERIDO]`.
- **Principais skills** — top skills por `nivel` e `importancia`, com anos de
  experiência quando presentes.
- **Pontos fortes** — seções fortes (skills densas, conquistas com métrica,
  certificações, projetos com link).
- **Pontos fracos** — seções vazias/rasas, datas ausentes, gaps de experiência,
  skills sem nível.

### 3. Score do perfil (0-100)

Pontue cada seção com base em **completude e força**:

| Seção | Critérios de pontuação |
|-------|------------------------|
| dados_pessoais | nome + contato + localização + links profissionais presentes |
| resumo | resumo presente, claro, com diferencial; idealmente bilingue (resumo_i18n) |
| experiencia | cargos com datas, resumo, conquistas (métrica = bonus) |
| educacao | instituições/cursos completos, status definido |
| skills | quantidade, nível explícito, categorias, anos de experiência |
| certificacoes | presentes, com emissor e ano |
| projetos | presentes, com descrição e link (link = bonus) |
| idiomas | presentes, com nível formal (nota_escala = bonus) |
| links | ao menos LinkedIn + GitHub/site |

Regras:
- Cada seção vazia = 0. Cada seção com dados mínimos = 40-60. Seções
  completas = 70-90. Com diferenciais (métricas, links, notas formais) = 90-100.
- Score global = média ponderada (experiencia e skills pesam mais: 1.5x).
- **Justificativa textual obrigatória** para cada nota.
- Scores são estimativas — sem `[INFERIDO]` no score em si (é calculado), mas
  qualquer inferência usada na justificativa deve ser marcada.

### 4. Perfis de vagas-alvo (offline)

Sugira **perfis de vagas** (não vagas reais) que o perfil encaixa bem, com base
na análise do hub:

- Cargos prováveis (ex.: Senior Data Engineer, Data Platform Engineer)
- Segmentos/indústrias onde as skills têm demanda (ex.: fintech, e-commerce)
- Stacks que combinam com as skills do hub
- Senioridade das vagas-alvo

**Proibido**: listar vagas concretas, empresas específicas ou URLs — tudo é
perfil genérico derivado da análise offline. Cada perfil marcado `[INFERIDO]`.

### 5. Pretensão salarial de mercado (CLT vs PJ)

Entregue faixas de referência por **senioridade/stack/região** para CLT (mensal)
e PJ (mensal), com base em conhecimento geral de mercado. **TODAS** as faixas
DEVEM ser marcadas `[INFERIDO]` — o candidato revisa e ajusta antes de usar.
Nunca invente fontes específicas.

Formato:
```
- Senior Data Engineer | São Paulo (SP)
  - CLT: R$ 14.000 – 20.000 [INFERIDO]
  - PJ: R$ 22.000 – 30.000 [INFERIDO]
```
Inclua: faixa sugerida, faixa alvo de negociação, e a pretensão declarada do
candidato (se presente em dados_pessoais.pretensao_salarial) com avaliação de
aderência à faixa.

### 6. Lacunas de contexto no hub

Liste informações **ausentes** que, se preenchidas, aumentariam o contexto e o
impacto do perfil:

- Conquistas sem métrica/número (sugira formato "Reduziu X em Y%")
- Projetos sem link/descrição
- Certificações sem ano/emissor/validade
- Idiomas sem nível formal (nota_escala: B2/C1, IELTS...)
- Experiência com datas ausentes ou gaps não explicados
- Skills sem nível/anos de experiência
- Resumo sem diferencial/posicionamento
- Seções totalmente ausentes (projetos, certificações, idiomas)

### 7. Plano de ações priorizado

Cada ação com:
- **Ação** — o que fazer (ex.: "Adicionar métricas a 3 conquistas da Acme")
- **Impacto estimado** — alto/médio/baixo no fortalecimento do perfil
- **Esforço** — baixo/médio/alto
- **Prioridade** — P1 (impacto alto + esforço baixo) até P3
- **Vaga-alvo relacionada** — qual perfil de vaga a ação atende

Agrupe por categoria: preencher lacunas do hub, fortalecer seções fracas,
fechar gaps das vagas-alvo (cursos/certificações/idiomas), posicionamento.

## Regras rígidas

1. NENHUM dado inventado: toda estimativa/inferência marcada `[INFERIDO]`.
2. NUNCA modificar `hub.json` — apenas analisar e reportar.
3. Sem busca web: análise 100% offline sobre o hub.
4. Nenhum dado sensível (CPF, endereço completo, banco) no relatório.
5. Nada de vagas concretas/empresas/URLs — apenas perfis genéricos.
6. Dados sensíveis já excluídos pelo cv-hub permanecem excluídos.

## tasks.json (opcional)

Estrutura estruturada para futura rastreabilidade:

```json
{
  "gerado_em": "2026-08-13",
  "score": { "global": 72, "secoes": { "experiencia": 85, ... } },
  "tarefas": [
    { "id": 1, "acao": "Adicionar métricas às conquistas da Acme",
      "impacto": "alto", "esforco": "baixo", "prioridade": "P1",
      "categoria": "lacunas", "vaga_alvo": "Senior Data Engineer" }
  ]
}
```
