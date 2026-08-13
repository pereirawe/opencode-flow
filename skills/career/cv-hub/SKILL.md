---
name: cv-hub
description: Construção do hub de currículo de um candidato — extração de dados a partir de currículo PDF (pdftotext), export oficial do LinkedIn (Download My Data), e arquivos complementares, consolidação em hub.json (schema canônico para IA) + README.md humano. Use quando precisar criar ou atualizar o hub de dados de um candidato (comando ocf:cv-hub). Setor career.
---

# CV Hub — construção do hub do candidato

Consolida todas as fontes do candidato em um único hub estruturado
(`hub.json` — fonte de verdade para IA) + `README.md` (resumo executivo
humano). O hub é a base da geração de currículos direcionados (`cv-tailor`).

## Estrutura do diretório do candidato

```
~/carreira/<nome-candidato>/
├── hub.json          # schema canônico (fonte de verdade para IA)
├── README.md         # resumo executivo humano, gerado a partir do hub.json
├── entradas/         # arquivos-fonte originais
│   ├── curriculo.pdf # (obrigatório)
│   ├── linkedin/     # export oficial LinkedIn (opcional)
│   └── extras/       # certificados, portfólio, projetos (opcional)
└── curriculos/       # currículos gerados (HTML + PDF)
```

## Entradas

| Entrada | Obrigatório | Como obter |
|---------|-------------|------------|
| Currículo em PDF | **Sim** | Fornecido pelo usuário |
| Export oficial LinkedIn | Não | `https://www.linkedin.com/mypreferences/d/download-my-data` → opção **"Baixe um arquivo de dados maior..."** (email o link quando pronto; inclui `Profile/`, `Work/`, `Education/`). Nunca scrape linkedin.com |
| Complementos | Não | Certificados, portfólio, projetos, premiações |

## Processo de extração

1. **Receber as fontes** — confirme o diretório do candidato e copie os
   arquivos para `entradas/` (`curriculo.pdf`, `linkedin/`, `extras/`).
2. **Extrair o PDF** — rode `pdftotext -layout curriculo.pdf -` (ou use
   `pdftotext curriculo.pdf out.txt`). Se `pdftotext` não estiver disponível,
   use Python: `python3 -c` com `pypdf`/`PyPDF2` se instalado; senão peça ao
   usuário para fornecer o texto. Nunca tente OCR se a ferramenta não existir.
3. **Estruturar o export do LinkedIn** — no export oficial, leia os arquivos
   sob `Profile/` (positions, education, skills, languages, certifications,
   projects, publications, recommendations), `Work/`, `Education/` e
   `Certifications/`. Extraia para a estrutura do hub.
4. **Consolidar no hub.json** — use o schema canônico (definição abaixo).
   Prefira os dados mais recentes; registre cada item em **uma** das fontes.
5. **Validar** — rode `python3 $SCRIPTS_DIR/cv/validate.py hub.json`. Corrija até
   exit 0.
6. **Gerar README.md** — derive do hub.json: nome, título, resumo, contato
   (somente se presente no hub), experiência, educação, skills principais,
   certificações, projetos, idiomas. O README é um **espelho** — nunca edite
   manualmente em divergência com o JSON.

## Schema canônico do hub.json

```json
{
  "dados_pessoais": {
    "nome": "Nome Completo",
    "titulo_profissional": "Engenheiro de Dados",
    "email": "cand@email.com",
    "telefone": "+55 11 99999-9999",
    "cidade": "São Paulo", "estado": "SP", "pais": "BR",
    "linkedin": "https://linkedin.com/in/...",
    "github": "https://github.com/...",
    "site": "https://...",
    "disponibilidade": "Imediata"
  },
  "resumo": "resumo executivo",
  "resumo_i18n": { "pt": "...", "en": "...", "es": "..." },
  "experiencia": [
    {
      "empresa": "Acme", "cargo": "Engenheiro de Dados",
      "inicio": "2021-03", "fim": "atual", "atual": true,
      "resumo": "...",
      "conquistas": ["Reduziu custo de infra em 30%"],
      "responsabilidades": ["...", "..."],
      "tecnologias": ["Python", "Airflow", "dbt"]
    }
  ],
  "educacao": [
    { "instituicao": "USP", "curso": "Ciência da Computação",
      "tipo": "Graduação", "status": "Concluído" }
  ],
  "skills": [
    { "nome": "Python", "categoria": "linguagem", "nivel": "avancado",
      "desde": "2018", "anos_experiencia": 6, "importancia": "principal" }
  ],
  "certificacoes": [
    { "nome": "AWS Solutions Architect", "emissor": "AWS", "ano": "2023" }
  ],
  "projetos": [
    { "nome": "open-source x", "descricao": "...", "tecnologias": ["Go"] }
  ],
  "idiomas": [ { "idioma": "Inglês", "nivel": "fluente", "nota_escala": "C1" } ],
  "links": [ { "nome": "GitHub", "url": "https://github.com/x" } ]
}
```

### Regras de consolidação

- **Deduplicar**: se a mesma experiência aparece no currículo e no LinkedIn,
  priorize o LinkedIn (mais granular) e mescle conquistas do currículo.
- **Bilíngue**: quando o candidato fornecer resumos em mais de um idioma,
  use `resumo_i18n`. O `resumo` default é o do idioma do candidato.
- **Skills**: sempre que possível, registre `desde` (ano de início do uso da
  habilidade, ex.: 2018) em vez de (ou junto de) `anos_experiencia` fixo —
  anos fixos ficam desatualizados com o tempo. Se a fonte só permite inferir
  um ano de início (ex.: primeiro projeto/uso), registre `desde` e marque a
  inferência `[INFERIDO]` na descrição.
- **Nada inventado**: qualquer dado não presente nas fontes fica **ausente**
  do hub — nunca preencha com suposições. Dados inferidos de contexto devem
  ser marcados `[INFERIDO]` na descrição.
- **Sensíveis**: endereço completo, CPF, documento, dados bancários NÃO são
  copiados para o hub (apenas cidade/estado/pais se disponíveis).
- **Ordem cronológica reversa** em `experiencia`, `educacao`, `projetos`.

## Ferramentas e limites

- Extração de PDF: `pdftotext -layout` (preferido) → fallback Python
  (`pypdf`/`PyPDF2`) → senão peça o texto ao usuário. Sem OCR automático.
- Sem rede: o hub é construído 100% a partir de arquivos locais.
- O `README.md` e o `hub.json` devem ser commitáveis pelo usuário se ele
  versionar a carreira; não commite nada sem autorização.
