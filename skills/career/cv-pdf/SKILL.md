---
name: cv-pdf
description: Geração de currículo em PDF a partir de HTML — Chrome headless (--print-to-pdf, A4) com fallback LibreOffice. Use quando precisar converter o HTML do currículo direcionado em PDF, ou qualquer HTML em PDF A4. Setor career.
---

# CV PDF — HTML → PDF

Converte um arquivo HTML de currículo em PDF A4, pronto para ATS e envio.

## Comando

```bash
bash $SCRIPTS_DIR/cv/pdf.sh <input.html> <output.pdf> [chrome|libreoffice]
```

- `<input.html>` — arquivo HTML do currículo (deve conter `@page` CSS para A4).
- `<output.pdf>` — caminho do PDF de destino.
- Engine opcional: `chrome` (padrão) ou `libreoffice` (força fallback).

Sem o terceiro argumento, tenta Chrome primeiro e cai para LibreOffice se o
Chrome não estiver disponível ou falhar.

## Regras de qualidade

1. **A4 obrigatório** — o HTML DEVE declarar `@page { size: A4; margin:
   16mm-18mm }`. Sem isso o Chrome usa o tamanho de página do browser e o PDF
   pode ficar com layout errado.
2. **Tipografia limpa** — system fonts (`Helvetica`, `Arial`, `sans-serif`)
   para máxima compatibilidade. Sem Google Fonts online (podem não renderizar
   no headless sem rede).
3. **ATS-friendly** — headings semânticos (`h1`/`h2`), texto selecionável
   (nunca transforme em imagem), sem tabelas complexas, sem ícones
   decorativos.
4. **Tamanho razoável** — se o PDF ficar com muitas páginas (> 2–3 para um
   currículo), sugira condensar o conteúdo (revisar seções menos relevantes).

## Verificação

Após gerar, confirme que o PDF:
- não está vazio (`ls -la` → > 0 bytes; usar `file` para confirmar "PDF document"),
- tem 1–2 páginas para um currículo padrão,
- abre sem erro de estrutura.

## Fallback

Se o Chrome falhar (ex.: sandbox/container), rode
`bash $SCRIPTS_DIR/cv/pdf.sh <input.html> <output.pdf> libreoffice`. O LibreOffice
converte o HTML com fidelidade menor de CSS, então revise o PDF resultante.
