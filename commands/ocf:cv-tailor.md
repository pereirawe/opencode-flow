## /ocf:cv-tailor <diretório-do-candidato> <vaga>

---
description: Generate a job-tailored resume PDF from the candidate hub — analyze the job, gap analysis vs hub.json, adapt content (never fabricate), HTML -> PDF in the job's language
---

Gera uma versão do currículo do candidato otimizada para uma vaga específica,
a partir do `hub.json` do candidato (construído com `/ocf:cv-hub`). Analisa a
vaga, faz gap analysis vs hub, adapta o conteúdo **sem fabricar nada** e
produz o currículo em PDF (HTML → PDF via Chrome headless, fallback
LibreOffice) no idioma da vaga.

### Pré-requisito

O candidato precisa de um hub válido em `~/career/<nome-candidato>/hub.json`.
Se não existir, rode `/ocf:cv-hub` primeiro.

### Uso

```
/ocf:cv-tailor ~/career/maria-silva "URL ou texto da vaga"
```

A vaga pode ser fornecida como:
- **Texto colado** da descrição (recomendado — mais confiável);
- **Arquivo local** (txt/html/pdf) com a descrição;
- **Export oficial LinkedIn** (arquivos locais do Download My Data);
- **URL** — tenta `curl -L` respeitando robots; LinkedIn bloqueia sempre, então
  nesse caso pede o texto colado. Nunca contorna anti-bot.

### Fluxo

1. **Validar hub** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`.
2. **Invocar o agente** `career/cv-tailor` via `task:` com o diretório do
   candidato e a vaga.
3. **Analisar vaga** — requisitos obrigatórios/desejáveis, keywords, senioridade,
   idiomas.
4. **Gap analysis** — tabela requisito → atendido/parcial/não-atendido,
   salva em `curriculos/<slug-da-vaga>/gap-analysis.md`.
5. **Decisão humana sobre inferências** — listar todas em
   `curriculos/<slug-da-vaga>/inferencias.md` e pedir a decisão do candidato
   (reformular/omitir/promover com dado real) antes do output final.
6. **Adaptar conteúdo** — a partir do template de referência
   `skills/career/cv-pdf/templates/resume.html`, seguindo o padrão
   `standards/cv-design.md`; reordenar/destacar/condensar apenas o que existe
   no hub; NUNCA `[INFERIDO]` no HTML/PDF final; idioma = idioma da vaga.
7. **Verificar conformidade** com o padrão (checklist ATS/print/páginas do
   `standards/cv-design.md`) antes do PDF.
8. **Gate obrigatório** — `bash $SCRIPTS_DIR/cv/check-inferido.sh index.html`
   DEVE passar (exit 0) antes do PDF.
9. **Gerar PDF** — `bash $SCRIPTS_DIR/cv/pdf.sh index.html curriculo.pdf`.

### Regras

- NUNCA inventar experiência, skills, projetos, certificações ou contato.
- Layout conforme `standards/cv-design.md` (ATS/print/páginas), partindo do
  template `skills/career/cv-pdf/templates/resume.html` — nunca CSS do zero;
  verificar conformidade antes do PDF.
- `[INFERIDO]` é permitido APENAS em artefactos internos (hub.json,
  gap-analysis.md, inferencias.md). No HTML/PDF final NENHUM `[INFERIDO]` pode
  aparecer — o gate `check-inferido.sh` bloqueia a geração.
- Contato apenas se presente no hub; dados sensíveis nunca.
- PDF A4 pronto para ATS, tipografia limpa, headings semânticos.

### Reporte ao usuário

- Caminho do PDF gerado (`~/career/<nome>/curriculos/<slug>/curriculo.pdf`).
- Resumo do gap analysis (requisitos atendidos/parciais/não-atendidos).
- Lista de inferências resolvidas (reformuladas/omitidas/promovidas) que o
  candidato aprovou — nenhuma marcação `[INFERIDO]` no artefacto partilhável.
