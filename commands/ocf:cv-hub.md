## /ocf:cv-hub <diretório-do-candidato>

---
description: Build the candidate's resume hub — extract CV PDF + official LinkedIn export + extras into hub.json (AI canonical schema) + README.md
---

Constrói o hub de dados de um candidato a partir do currículo em PDF
(obrigatório), do export oficial do LinkedIn (opcional) e de arquivos
complementares (opcionais). O hub (`hub.json` + `README.md`) é a fonte de
verdade para gerar currículos direcionados via `/ocf:cv-tailor`.

### Fluxo oficial do LinkedIn (única forma aceita)

1. O usuário acessa: <https://www.linkedin.com/mypreferences/d/download-my-data>
2. Escolhe a opção **"Baixe um arquivo de dados maior..."** (o LinkedIn envia
   um link por e-mail quando o arquivo estiver pronto — leva alguns dias).
3. Descompacta o `.zip` e informa o diretório ao comando.

**NUNCA** se faz scraping de linkedin.com (anônimo ou logado) — o LinkedIn
bloqueia e isso viola os termos. Apenas o export oficial é aceito.

### Uso

```
/ocf:cv-hub ~/carreira/maria-silva
```

- Se o diretório não existir, cria-se a estrutura:
  `hub.json`, `README.md`, `entradas/` (curriculo.pdf, linkedin/, extras/),
  `curriculos/`.
- O comando pergunta ao usuário onde estão: o PDF do currículo, o diretório
  do export do LinkedIn (se houver) e os complementos (se houver).

### Fluxo

1. **Coletar fontes** — usuário informa os caminhos dos arquivos; copiar para
   `entradas/`.
2. **Invocar o agente** `career/cv-extractor` via `task:` com o diretório do
   candidato e o caminho das fontes.
3. **Extrair e consolidar** — o agente roda `pdftotext -layout` no PDF,
   estrutura o export do LinkedIn, consolida em `hub.json` (schema canônico)
   e gera `README.md`.
4. **Validar** — `python3 $SCRIPTS_DIR/cv/validate.py hub.json`; corrigir até exit 0.
5. **Reportar** — caminho do `hub.json`, se a validação passou, e resumo das
   seções populadas. Informar que o próximo passo é `/ocf:cv-tailor`.

### Regras

- Entrada mínima: currículo em PDF. LinkedIn e extras são opcionais.
- Nada é inventado — dados ausentes ficam ausentes; inferências são marcadas
  `[INFERIDO]`.
- Dados sensíveis (CPF, documento, endereço completo) não entram no hub.
- O fluxo roda 100% local, sem rede.
