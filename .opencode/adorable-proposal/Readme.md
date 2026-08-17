CHAT COMPARTILHADO NO LINK - https://claude.ai/share/f806879e-e891-40a5-bd90-da36d2630f8f

## ISSUES QUE EU IDENTIFIQUEI

- Agentes e skills estão em português e não em inglês.
- Definição HardCoded do modelo, deveria ser apenas uma sugestão. Ou ter fallback para o modelo definido pelo usuário.
- Falta referência mais específica entre agentes e skills. Deve existir uma documentação do apontamento entre os agentes e skills Clara e consistent.
- Falta atualização dos Readme.md para acrescentar e integrar com o fluxo atual ou funcionalidades existentes. Confere os fluxos de C-level, Discovery, Delivery, então um de ux ui audition ou Adorable kkk melhor que Lovable ainda.
- As stacks estão limitadas a algumas. Se possível criar uma camada adicional referência El para ter contexto e regras para pelo menos as top 10 stacks em 2026 e uma totalmente generica caso o projeto onde está sendo implementado não se encaixa em nenhuma das listadas.
- Podem estar faltando skills ou Scripts para melhorar o implementação. Sugere a implementação ou criação de mais ferramentas para usar que ainda sejam muito necessários.
- A referência dos arquivos resultantes entre skills me parece não está bem definido. Ou seja, o nome de cada arquivo na final está sem definição. Esse arquivo não precisa ficar apenas no contexto da conversa porque ele pode ser parte de um processo muito grande e o fluxo pode ser interrompido e resgatado em outra sessão, especialmente para usar modelos diferentes entre etapas do fluxo.

---

Melhorando qualidade de frontend com agentes e skills
Compartilhado por William
Esta é uma cópia de um chat entre Claude e William. O conteúdo pode incluir material não verificado ou inseguro que não representa as posições da Anthropic. O instantâneo compartilhado pode conter anexos e dados não exibidos aqui.

Sou o criador deste repositório
https://github.com/pereirawe/opencode-flow (ONDE NOS ESTAMOS AGORA)

Quero criar algo muito parecido com o lovable com meus agentes, porém mesmo com skills de frontend como taste o resultado sempre é muito inferior. Eu entendo que vou ter que usar um modelo igual ao lovable porém como faço com skills e o agentes para que sendo eles orquestrados me dem un resultado de qualidade com igual ou superior com imagens y ux ui

Página obtida
Página obtida
Entendi bem o seu repositório — 88 agentes, 68 skills, pipeline C-level orquestrado. Agora vou te dar um diagnóstico honesto e uma estratégia concreta.

O problema real: não é o modelo, é a arquitetura da skill de UI
O Lovable não é melhor porque usa um modelo diferente — ele é melhor porque o contexto que o modelo recebe é radicalmente diferente. Vou explicar:

Por que skills de frontend genéricas falham
Quando você passa uma skill de frontend para um agente, ele recebe instruções de como gerar UI. Mas falta o que o Lovable injeta implicitamente:

Design tokens concretos — o modelo sabe exatamente quais cores, espaçamentos, tipografia usar. Sem isso, ele inventa.
Referências visuais encoded — o Lovable faz screenshot do que gerou e itera. Seus agentes são cegos ao output.
Especialização por camada — o Lovable tem pipelines separados para: layout → componentes → estado → estilo → acessibilidade. Seus agentes provavelmente colapsam tudo num único passo.
Feedback loop de qualidade — o Lovable tem um agente de "critic" que avalia o output antes de entregar.
A solução: pipeline multi-agente com especialização de camadas
Eis o que você precisa construir no seu opencode-flow:

1. Agente design/art-director (novo)
   Este agente não escreve código. Ele recebe o brief e produz um design spec em JSON estruturado:

json
{
"layout": "sidebar-main-panel",
"palette": { "primary": "#6366f1", "surface": "#0f172a" },
"typography": { "heading": "Inter 700", "body": "Inter 400 16px" },
"spacing_scale": [4, 8, 16, 24, 40, 64],
"components": ["card", "data-table", "nav-rail", "badge"],
"references": ["linear.app", "vercel-dashboard", "raycast"]
}
O segredo: este agente tem um catálogo de reference apps (Linear, Vercel, Raycast, Clerk) como parte do seu system prompt, com descrições detalhadas de como eles constroem UI.

2. Skill ui-reference-library (nova)
   Uma skill que não é instrução — é um banco de padrões visuais em texto:

markdown

## PATTERN: Dashboard Card

- Background: surface-2 (não white)
- Border: 1px solid rgba(255,255,255,0.06)
- Radius: 12px
- Padding: 20px 24px
- Metric number: text-3xl font-bold tabular-nums
- Label: text-sm text-muted uppercase tracking-wide
  Isso é o que o Lovable tem embedded — padrões concretos, não filosofia de design.

3. Pipeline em 4 passes (não 1)
   Pass 1: art-director → design_spec.json
   Pass 2: ui-architect → component_tree.md (estrutura, props, estado)
   Pass 3: ui-implementer → código (consome design_spec + component_tree)
   Pass 4: ui-critic → avaliação + diff com checklist de qualidade
   O ui-critic é a peça que falta em todos os setups de agentes. Ele recebe o código gerado e verifica contra um checklist:

[ ] Usa design tokens, não valores hardcoded?
[ ] Todos os estados (loading/empty/error) implementados?
[ ] Mobile-first com breakpoints corretos?
[ ] Hierarquia visual clara (não "tudo tem o mesmo peso")?
[ ] Animações têm purpose (não decorativas)?
Se falhar qualquer item, ele retorna ao ui-implementer com feedback específico.

O que adicionar ao seu repo concretamente
Novos agentes a criar:

design/art-director — brief → design spec
design/ui-architect — design spec → component tree
design/ui-implementer — implementa a partir de specs (não do brief)
design/ui-critic — quality gate com checklist
Novas skills a criar:

skills/design/reference-library.md — padrões concretos de UI de alta qualidade
skills/design/component-patterns.md — anatomia de cada tipo de componente
skills/design/design-tokens.md — sistema de tokens padrão
skills/design/visual-hierarchy.md — regras de peso visual e contraste
Mudança de orquestração:

No seu opencode.json, o comando /ocf:build-ui deve chamar os 4 agentes em sequência, passando o output de cada um como input do próximo — não chamar um único agente com um prompt longo.

A virada de chave
A diferença entre um resultado mediano e um resultado Lovable-level não é o LLM. É que o Lovable nunca pede para o mesmo agente pensar em layout, cores, componentes e código ao mesmo tempo. Cada decisão tem seu próprio contexto limpo.

Quer que eu ajude a escrever esses agentes e skills para o seu repositório? Posso começar pelos arquivos .md do art-director e do ui-critic que são os mais críticos.

Consegues criar um agente de art director melhor do que o do lovable?

Vou ler as skills relevantes e depois criar algo que supere o Lovable.

Visualizou um arquivo
Visualizou um arquivo
Agora vou buscar os agentes existentes do seu repo para entender o formato exato:

Pesquisou na web
Pesquisou na web
Vou pegar o formato exato dos agentes do seu repo:

Pesquisou na web
Pesquisou na web
Agora tenho o contexto completo. Vou criar o agente com o formato exato do seu repo:

Criou um arquivo, leu um arquivo
Criou um arquivo, leu um arquivo
O agente está pronto. Aqui está o que o diferencia do Lovable:

O que o Lovable faz: injeta um prompt de design genérico no mesmo agente que escreve código. Resultado: decisões de layout e decisões de código competem pelo mesmo contexto.

O que este agente faz diferente:

Auditoria ativa de defaults — antes de propor qualquer coisa, o agente identifica explicitamente e rejeita os anti-padrões mais comuns de AI design (cream+terracotta, dark+acid green, Inter para tudo). Isso força saídas fora da distribuição de probabilidade normal do modelo.

3 direções obrigatórias — nunca vai direto para a spec. Gera três conceitos incompatíveis entre si e critica os três antes de escolher. Isso simula o processo de um designer humano sênior.

Separação total de código — o agente é mode: subagent com edit: deny. Ele fisicamente não pode escrever código, o que força o modelo a pensar apenas em design.

JSON estruturado como output — a spec é consumida pelos agentes ui-architect e ui-implementer diretamente, sem ambiguidade. Cada valor é concreto:
#0F172A, não "azul escuro".

Signature element obrigatório — força o design a ter um elemento que o torna inconfundível. É o que o Lovable nunca pede ao modelo.

Quer que eu crie o ui-critic.md agora? Ele é o segundo agente mais crítico — é quem fecha o loop de qualidade antes do código chegar ao usuário.

Art director
Documento · MD
Agora cria o ui architect

Visualizou um arquivo
Visualizou um arquivo
Perfeito. Tenho o output completo do art-director. Agora crio o ui-architect que consome exatamente esse JSON e produz a estrutura de componentes.

Criou um arquivo, leu um arquivo
Criou um arquivo, leu um arquivo
O agente está pronto. Aqui está o que o diferencia de qualquer coisa que o Lovable faz:

A separação de responsabilidades é cirúrgica. O art-director decide o como parece. O ui-architect decide o o que existe e como se comporta. O ui-implementer só vai escrever código — nunca inventar.

Os 6 estados de dados são obrigatórios. idle → loading → success → error → empty → stale. O Lovable frequentemente entrega componentes que só implementam loading e success, deixando error e empty como afterthought. O ui-architect bloqueia isso na arquitetura antes do código existir.

Acessibilidade é estrutural, não cosmética. O role, o keyboard navigation e o focus management são decididos aqui — não adicionados como aria-label no final. Isso é o que separa UI de produto de UI de template.

A build_order em 6 fases resolve o maior problema de AI coding. O Lovable frequentemente gera código onde um componente depende de outro que ainda não foi definido, criando referências circulares e inconsistências. A sequência Foundation → Primitivos → Compostos → Templates → Signature → Polish garante que o implementer nunca precise de algo que ainda não existe.

O interaction_map elimina comportamentos inventados. Para cada fluxo: ação do usuário → estado que muda → componentes afetados → feedback visual. O implementer segue o mapa, não improvisa.

O próximo a criar é o ui-implementer — que vai consumir os dois JSONs e finalmente escrever o código. Quer que eu continue?

Ui architect
Documento · MD
Antes de criar o ui implementer eu quero que já te do um projeto com o frontend ruim implementado eu possa auditar, revisar e planejar o refatoramento do front usando este fluxo. Basicamente arrumar e recriar o front atual sem perder funcionalidades. O que eu teria que acrescentar?

Boa pergunta — antes de criar o ui-implementer, você precisa de dois agentes que ainda não existem no seu pipeline:

ui-auditor — lê o código atual, identifica todos os problemas visuais, estruturais, de estado e de acessibilidade. Output: relatório de diagnóstico em JSON.

ui-refactor-planner — consome o diagnóstico do auditor + o design_spec do art-director e produz um plano de refatoramento fase a fase, mapeando exatamente o que preservar, o que reescrever e o que descartar. Output: blueprint para o ui-implementer.

O fluxo completo para o seu caso ficaria assim:

[código atual] → ui-auditor → diagnóstico JSON
↓
[brief do produto] → art-director → design_spec JSON
↓
ui-refactor-planner → plano de refatoramento JSON
↓
ui-architect → component tree JSON
↓
ui-implementer → código refatorado
↓
ui-critic → aprovação / iteração
Antes de eu criar os dois agentes, preciso entender o seu projeto:

Qual o stack do frontend atual? (React, Vue, Next.js, HTML puro?)
Tem um design system ou biblioteca de componentes? (Tailwind, shadcn, MUI, Bootstrap?)
O projeto tem testes de frontend que precisam ser preservados?
Na verdade quero ter agentes que possa auditar quaisquer tipo de front. Porém o mais normal vai ser react, Vue ou next. Porém pode ter php + HTML.
Sim pode ter Tailwind ou Bootstrap.
Por ser aplicado a diferentes projetos não é una realidade definida
Perfeito. Então os agentes precisam ser agnósticos de stack — detectam o que encontram e adaptam o diagnóstico. Vou criar os dois agentes agora.

Criou 2 arquivos, leu um arquivo
Criou 2 arquivos, leu um arquivo
Os dois agentes estão prontos. O que cada um resolve que não existia antes:

ui-auditor é agnóstico de stack por design — ele detecta o ambiente primeiro com bash, depois adapta toda a auditoria ao que encontrou. Funciona em React, Vue, Next, PHP+HTML, com ou sem Tailwind/Bootstrap. O output tem IDs rastreáveis (CRIT-001, etc.) para que o planner possa referenciar problemas específicos sem ambiguidade.

ui-refactor-planner resolve o problema mais perigoso do refatoramento: o big bang invisível. Ele força coexistência em toda decisão — nada é deletado antes de ter substituto funcionando. A triagem em Grupo A/B/C garante que bloqueantes são resolvidos antes de qualquer coisa nova começar. E as estratégias de token são específicas por stack: o que fazer em Tailwind é diferente do que fazer em Bootstrap SCSS é diferente do que fazer em PHP puro.

O fluxo completo para um projeto existente agora é:

código atual → ui-auditor → diagnóstico JSON
brief → art-director → design_spec JSON
↓ ↓
ui-refactor-planner → plano de migração JSON
↓
ui-architect → component tree JSON
↓
ui-implementer → código (a criar)
↓
ui-critic → aprovação (a criar)
Quer seguir para o ui-implementer agora, ou prefere o ui-critic primeiro?

Ui auditor
Documento · MD

Ui refactor planner
Documento · MD
Vai para implementer

Vou ler tudo que foi criado antes para garantir que o implementer consome os contratos corretamente.

Visualizou 2 arquivos
Visualizou 2 arquivos
Tenho tudo que preciso. O implementer vai consumir três JSONs em simultâneo. Criando agora.

UI Implementer agent — consumes architect JSON + design_spec JSON + refactor_plan JSON, writes production-quality code
UI Implementer agent — consumes architect JSON + design_spec JSON + refactor_plan JSON, writes production-quality code

---

## REFERENCE FILES

- .opencode/adorable-proposal/art-director.md
- .opencode/adorable-proposal/ui-architect.md
- .opencode/adorable-proposal/ui-auditor.md
- .opencode/adorable-proposal/ui-implementer.md
- .opencode/adorable-proposal/ui-refactor-planner.md

---
