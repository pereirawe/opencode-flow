# Padrão de Design de Proposta

Padrão canônico de design e entrega para toda proposta comercial elaborada
pelo setor business-ops (`/ocf:proposal`, skill `proposal-writer`). Toda
proposta DEVE ser entregável em PDF com marca (e em HTML fonte), além da fonte
Markdown, usando o logo e os dados da empresa que emite a proposta.

As regras abaixo são concretas e testáveis (afirmações MUST com valores
mensuráveis), não opiniões.

## 1. Saídas

1. Toda proposta DEVE ter três saídas derivadas de uma única fonte de verdade
   (`proposal.md`):
   - `proposal.md` — a fonte Markdown (Mermaid permitido para gantt/pie).
   - `proposal.html` — renderização HTML autocontida, pronta para A4, com
     cabeçalho de marca.
   - `proposal.pdf` — PDF A4 gerado a partir de `proposal.html` via
     `scripts/proposal/pdf.sh` (Chrome headless, fallback LibreOffice).
2. O HTML/PDF DEVE ser gerado a partir do template de referência
   `skills/business-ops/proposal-writer/templates/proposal.html` — os agentes
   adaptam o CONTEÚDO, nunca reescrevem o CSS do zero.
3. O HTML/PDF DEVE conter o logo e os dados da empresa emissora no cabeçalho
   (ver §3 Marca). Uma proposta gerada sem marca DEVE ser uma construção
   "sem marca" explícita e confirmada pelo usuário, nunca uma omissão silenciosa.

## 2. Impressão (A4)

1. O tamanho da página DEVE ser A4. Margens superiores/laterais DEVEM ser
   14–16mm; a margem inferior DEVE ser ≥16mm (18mm no template de referência)
   para acomodar o rodapé com número de página.
2. A proposta DEVE ser totalmente legível em preto e branco: nenhuma informação
   pode depender apenas de cor. A ênfase de status/preço vem de peso, tamanho e
   espaçamento.
3. Um bloco `@media print` limpo DEVE existir removendo cores interativas e
   mantendo o layout; fundos DEVEM ser claros/ausentes na impressão.
4. Seções e blocos `.proposal-section` DEVEM usar `break-inside: avoid`; `h2`
   DEVE usar `break-after: avoid` para que um título de seção nunca fique
   órfão no fim da página. Tabelas longas (esforço/preço) PODEM quebrar com
   `orphans: 3; widows: 3`.
5. Rodapé com número de página É OBRIGATÓRIO
   (`@page { @bottom-right { content: counter(page) } }` ou rodapé equivalente
   do Chrome) para que uma proposta impressa possa ser referenciada por página.
   O Chrome renderiza margin boxes CSS; o fallback LibreOffice NÃO renderiza —
   o motor de fallback avisa, e um PDF produzido via LibreOffice DEVE ser
   verificado manualmente quanto ao rodapé (ou usar a variante de rodapé no
   corpo).
6. Fontes DEVEM ser fontes de sistema seguras para impressão (`Helvetica`,
   `Arial`, `sans-serif`; `Courier`/mono para códigos/ids). Fontes web remotas
   SÃO PROIBIDAS — podem não renderizar headless.

## 3. Marca (empresa emissora)

1. Os assets de marca ficam em `docs/assets/` do projeto onde o fluxo é
   invocado. Ordem de resolução (DEVE):
   1. `<projeto>/docs/assets/company.json` + `<projeto>/docs/assets/logo.*`
      (marca do projeto — preferida).
   2. `~/.config/opencode/assets/company.json` + `~/.config/opencode/assets/logo.*`
      (fallback global).
   3. Compat legado: `docs/specs/<slug>/assets/logo.*` (cópia local de spec do
      comportamento antigo do `spec-init.sh`). Nunca é a fonte primária.
2. Schema de `company.json` (todos os campos opcionais; NUNCA inventar valores —
   omita campos desconhecidos):
   ```json
   {
     "name": "Nome legal ou fantasia da empresa",
     "legal_name": "Razão social completa (opcional)",
     "document": "CNPJ/RIF/número de registro (opcional)",
     "contact": { "email": "…", "phone": "…", "website": "…" },
     "address": { "street": "…", "city": "…", "state": "…", "country": "…" }
   }
   ```
3. O cabeçalho do HTML/PDF DEVE renderizar, quando presente: a imagem do logo,
   o `name` da empresa e uma linha de contato compacta (email/phone/website).
   Campos ausentes do `company.json` são omitidos — nunca substituídos por
   placeholders ou dados inventados.
4. O `proposal.html` DEVE ser autocontido: referencie o logo como data URI ou
   copie-o ao lado de `proposal.html` e referencie-o relativamente
   (`./logo.png`). NUNCA use URL absoluta `file://` ou remota para o logo — a
   URL `file://` vazaria na impressão e uma URL remota pode não carregar
   headless.
5. O atributo `<html lang>` DEVE corresponder ao locale da proposta resolvido
   (não a um idioma fixo), para que leitores de tela e ferramentas de tradução
   se comportem corretamente.
6. `scripts/proposal/brand-resolve.sh` DEVE ser usado para resolver a
   disponibilidade de marca antes de redigir. Ele resolve POR TIER INTEIRO
   (projeto → global → legacy), nunca compondo assets de tiers diferentes (um
   logo de projeto nunca emparelha com um `company.json` global). Contrato de
   saída:
   - `0` — marca encontrada (logo e/ou `company.json`).
   - `1` — nenhuma marca em lugar algum (projeto nem global).
   O script imprime os caminhos absolutos resolvidos (`logo=…`,
   `company_json=…`) e o tier ativo (`source=…`).
7. Quando NÃO houver marca, o agente DEVE perguntar ao usuário (nunca assumir):
   - (a) gerar SEM marca, ou
   - (b) fornecer dados/logo agora (gravados em `<projeto>/docs/assets/`),
   - (c) criar o standard da marca no projeto primeiro (ver §5).
   Somente após a resposta do usuário o agente gera. Isto é um gate rígido.
8. Regras de renderização do cabeçalho:
   - Com logo e `company.json` presentes: logo à esquerda, nome + contato da
     empresa à direita.
   - Com apenas um presente (logo-only / company-only): o bloco único é
     ancorado à esquerda e o lado vazio é removido — nunca um layout
     `space-between` meio vazio.
   - Numa construção sem marca, o elemento `<header class="brand-header">`
     DEVE ser removido por completo (um header vazio deixa uma linha solta no
     documento do cliente).

## 4. Estrutura de conteúdo da proposta

A ordem canônica de seções da skill `proposal-writer` é preservada no
HTML/PDF (§ Estrutura). Todo valor de preço DEVE derivar de matemática visível
(taxa × horas, descontos, total) exatamente como na fonte Markdown — nunca um
número arredondado sem derivação.

## 5. Criar um standard de marca em um projeto

Quando o usuário optar por (c) na §3.7, o agente DEVE, em ordem:

1. Perguntar ou reunir a identidade pública da empresa emissora (URL, arquivo
   de logo ou press kit) e dados factuais.
2. Rodar a skill `brand-to-design-md` contra a identidade pública para produzir
   `<projeto>/docs/assets/DESIGN.md` (tokens de design: cores, tipografia,
   espaçamento, uso do logo).
3. Gravar os dados da empresa como `<projeto>/docs/assets/company.json`
   seguindo o schema da §3.2 e o logo resolvido como
   `<projeto>/docs/assets/logo.<ext>` (svg/png preferido).
4. Confirmar que os assets são legíveis por `scripts/proposal/brand-resolve.sh`
   (exit 0) antes de prosseguir com a proposta.

## 6. Checklist de conformidade (rodar antes de gerar o PDF)

- [ ] `proposal.md`, `proposal.html`, `proposal.pdf` existem e coincidem em
      conteúdo/valores
- [ ] HTML parte do template de referência (nunca CSS do zero)
- [ ] `@page { size: A4; … }` presente; margens superior/laterais 14–16mm;
      inferior ≥16mm
- [ ] Cabeçalho mostra logo + nome da empresa + contato (quando presente no
      company.json); builds de asset único e sem marca seguem a §3.8 (sem lado
      vazio/linha solta)
- [ ] Nenhum dado de empresa inventado; campos ausentes do `company.json` são
      omitidos
- [ ] Logo referenciado como data URI ou cópia relativa — sem logo `file://`/remoto
- [ ] Sem fontes/redes remotas; legível em preto e branco
- [ ] Rodapé com número de página presente (Chrome ≥131; saída LibreOffice
      verificada manualmente — o motor avisa)
- [ ] `<html lang>` corresponde ao locale da proposta resolvido
- [ ] Nenhum token de template sem renderizar: `grep -E '\{\{' proposal.html` → 0
- [ ] Resolução de marca feita via `brand-resolve.sh`; construção sem marca é
      explícita e confirmada pelo usuário
- [ ] Matemática de preço visível e idêntica em `.md`/`.html`/`.pdf`
- [ ] Prosa correta no locale; identificadores de código/nomes de agentes
      ausentes do documento voltado ao cliente
- [ ] `proposal.pdf` não vazio e válido (Chrome ou LibreOffice com sucesso)

## 7. Locale

Os originais de `proposal-design.md` ficam em inglês em `standards/`. Versões
localizadas existem em `standards/pt/proposal-design.md` e
`standards/es/proposal-design.md`. Nunca edite os originais em inglês a partir
das traduções; a versão em inglês é a fonte da verdade.
