---
name: cv-tailor
description: Geração de currículo direcionado a uma vaga específica a partir do hub.json do candidato. Analisa a vaga (multi-portal, incluindo LinkedIn, Indeed, Gupy, site da empresa — texto colado ou arquivos do export oficial), extrai requisitos/keywords, faz gap analysis vs hub, adapta conteúdo (sem fabricar nada) e gera currículo HTML + PDF no idioma da vaga. Use quando precisar criar um currículo sob medida para uma candidatura (comando ocf:cv-tailor). Setor career.
---

# CV Tailor — currículo direcionado a vaga

Gera uma versão do currículo do candidato otimizada para uma vaga
específica, maximizando match com ATS/keywords, usando apenas dados que já
existem no `hub.json`. Nada é fabricado.

## Pré-requisito

O candidato deve ter um hub construído (`ocf:cv-hub` / skill `cv-hub`):
`~/carreira/<nome-candidato>/hub.json` válido.

## Entrada da vaga

O usuário fornece a vaga por um destes meios:
- **Texto colado** — descrição da vaga copiada de qualquer portal (recomendado
  e mais confiável).
- **Arquivo local** — arquivo com a descrição da vaga (txt, html, pdf).
- **Export oficial LinkedIn** — vagas salvas/visualizadas podem aparecer em
  arquivos do Download My Data.
- **URL** — se o usuário colar apenas uma URL, tente baixar o conteúdo com
  `curl -L` respeitando robots. Se o portal bloquear (LinkedIn bloqueia
  sempre), peça o texto colado. NUNCA tente contornar bloqueio/anti-bot.

## Análise da vaga

Extraia da vaga:

1. **Requisitos obrigatórios** — habilidades, ferramentas, certificações,
   idiomas, senioridade, anos de experiência explicitamente exigidos.
2. **Requisitos desejáveis** — o que a vaga "deseja" (nice to have).
3. **Keywords/tecnologias** — termos técnicos, produtos, stacks citados.
4. **Senioridade** — júnior/pleno/sênior/especialista/lead (ou inferida).
5. **Idioma da vaga** — pt/en/es → define o idioma do currículo gerado.
6. **Perfil da empresa** — setor, tamanho, cultura (se disponível).

## Gap analysis vs hub

Para cada requisito, classifique o match:

| Classificação | Critério |
|---------------|----------|
| `atendido` | Habilidade/requisito presente no hub (skills, experiência, certificação) |
| `parcial` | Presente de forma aproximada (ex.: vaga pede Kubernetes, hub tem Docker + AWS ECS) |
| `nao-atendido` | Requisito não existe no hub |

Registre o resultado em `curriculos/<slug-vaga>/gap-analysis.md` com a
tabela de requisitos → classificação → evidência no hub.

## Adaptação do conteúdo (sem fabricar)

Reordene, destaque e reformule **apenas o que já existe no hub**:

- **Summary**: reescreva o `resumo`/`resumo_i18n` para destacar as
  competências mais relevantes à vaga (no idioma da vaga).
- **Skills**: reordene priorizando as keywords da vaga. Skills com
  `importancia: principal` e match com a vaga vão primeiro.
- **Experiência**: reordene conquistas dentro de cada cargo — as que têm
  mais aderência à vaga primeiro. Não remova cargos; pode condensar os menos
  relevantes.
- **Projetos**: destaque os projetos com tecnologias da vaga; marque
  `relevancia: alta`.
- **Certificações**: ordene as mais relevantes à vaga primeiro.
- **Seções**: omita seções vazias (ex.: sem certificações → omitir seção).

### Regras rígidas

1. **NUNCA inventar** — experiência, skills, projetos, certificações, dados
   de contato que não estão no hub NÃO entram no currículo. Apenas reordenar,
   destacar, reformular e condensar o que existe.
2. **`[INFERIDO]`** — qualquer inferência ou placeholder gerado (ex.: nível
   de idioma não informado mas inferido da vaga, projeto que parece relevante
   por analogia) DEVE ser marcado `[INFERIDO]` no HTML/PDF para revisão
   humana. Nunca silencioso.
3. **Idioma da vaga** — todo o conteúdo do currículo gerado segue o idioma
   da vaga. Use `resumo_i18n` quando disponível; senão traduza o resumo a
   partir do hub (tradução de conteúdo existente é permitida — não é
   fabricação).
4. **Contato** — inclua telefone/e-mail/endereço somente se existirem no hub.
   Dados sensíveis (CPF, documento, banco) nunca.
5. **ATS-friendly** — seções claras com headings (`h1`/`h2`), sem tabelas
   complexas, sem imagens/ícones decorativos, datas em formato texto, A4.

## Estrutura de saída

```
~/carreira/<nome-candidato>/curriculos/<slug-da-vaga>/
├── index.html            # currículo HTML (idioma da vaga)
├── curriculo.pdf         # PDF A4 gerado
└── gap-analysis.md       # análise de requisitos vs hub
```

`<slug-da-vaga>` = empresa + cargo normalizados (ex. `acme-senior-data-engineer`).

## Geração do PDF

1. Escreva `index.html` com CSS inline/embutido: `@page { size: A4; margin:
   16-18mm }`, tipografia limpa (system fonts: `Helvetica, Arial,
   sans-serif`), seções claras.
2. Rode `bash $SCRIPTS_DIR/cv/pdf.sh index.html curriculo.pdf`.
3. Se o script falhar, reporte o erro do engine — nunca entregue um PDF vazio.
