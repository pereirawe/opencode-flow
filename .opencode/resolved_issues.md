# Resolved Issues

Issues resolved from `known_issues.md`. See `standards/resolved-issue.md` for format.

### 227. Regressão da #223: skill cv-linkedin não referencia mais `summary_i18n` (test_cv.sh falha)
- Resolved: 2026-09-03T01:31
- Durations: backlog=- waiting=- dev=0h review=- qa=- publish=0h total=1d
- Severity: low
- Type: bug
- Report: william_pereira
- Reviewers: 1
- Remote: #153
- Summary: A reescrita da issue 223 em skills/career/cv-linkedin/SKILL.md removeu qualquer referência ao `summary`/`summary_i18n` do hub (chaves do schema em inglês, issue 64). scripts/tests/test_cv.sh (linhas 645-646) exige `cv-linkedin skill references the English summary_i18n key`; desde o merge da 223, `bash scripts/tests/test_cv.sh` falha 1 asserção (599 pass / 1 fail) em main — e a orientação da seção Sobre ficou subespecificada (diz "candidate's voice" sem nomear o texto-fonte do hub a reformular). — adicionar uma linha na intro da H2 3 (Sobre) do cv-linkedin SKILL

### 224. Banner do perfil LinkedIn: design (art-director) + geração com modelo de imagem (each::sense) respeitando a zona segura da foto de perfil
- Resolved: 2026-09-03T01:28
- Durations: backlog=- waiting=- dev=0h review=- qa=- publish=0h total=1d
- Severity: medium
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #151
- Summary: Capacidade de gerar o banner do perfil LinkedIn do candidato com modelo de imagem (each::sense via skill poster-design-generation, key EACHLABS_API_KEY), a partir de direção visual do agente art-director (agents/design/art-director.md) e dos dados REAIS do hub. O banner deve ter — criar skill cv-linkedin-banner (geometria/zona segura/conteúdo), comando ocf:cv-banner, helper script banner-gen.sh (provedor each::sense) e registrar em opencode.json; reutilizar agents/design/art-director para a direção. Esforço ~5-6h.

### 226. cv-optimize: análise integrada com as melhorias de LinkedIn (banner, headline, sobre, experiência, skills) orientadas pelo objetivo
- Resolved: 2026-09-03T01:08
- Durations: backlog=- waiting=- dev=0h review=- qa=- publish=0h total=1d
- Severity: medium
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #149
- Summary: O relatório de análise `profile-analysis.md` (ocf:cv-optimize) passa a trazer JUNTO as melhorias de LinkedIn em forma de plano de ações concreto — cumprindo o pedido "en el análisis debe estar junto las mejorias de linkedin". Nova seção H2 "Melhorias no LinkedIn" com ações acionáveis e priorizadas (impacto/esforço/prioridade) cobrindo — atualizar cv-optimizer SKILL/agente/comando (seção nova + regras de consistência/objetivo), o template profile-analysis.html (seção no HTML) e standards/cv-analysis.md (ordem canônica); coordenar merge com 222/223/225. Esforço ~4-5h.

### 223. cv-linkedin revamp: relatório orientado por objetivo — headline literal, Sobre com logros/bullets, experiência com bullets de resultado e revisão de skills
- Resolved: 2026-09-03T00:54
- Durations: backlog=- waiting=- dev=0h review=- qa=- publish=0h total=1d
- Severity: high
- Type: feat
- Report: william_pereira
- Reviewers: 1
- Remote: #147
- Summary: Revamp do `ocf:cv-linkedin` para gerar um relatório de ações orientado pelo objetivo do perfil (issue 222), após treinamento de LinkedIn do usuário — reescrever cv-linkedin SKILL (blocos/objetivo/estrutura de output), agente e comando; referenciar issues 222/225; atualizar standards/cv-analysis.md com a nova estrutura de output se necessário. Esforço ~5-6h.

### 225. Sincronização LinkedIn ↔ hub (offline): leitura do export oficial e diff de experiência, skills, idiomas, educação e headline
- Resolved: 2026-09-03T00:35
- Durations: backlog=- waiting=- dev=0h review=- qa=- publish=0h total=1d
- Severity: medium
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #145
- Summary: Comparar o perfil real do LinkedIn com o hub.json usando o EXPORT OFICIAL (Download My Data — usuário fornece um export novo em entradas/linkedin/ ou caminho informado; nunca raspar linkedin.com). O diff cobre headline, cargos/experiência (datas, títulos, ordem), education, skills (issue — criar linkedin-sync.py (parse do export + normalização + diff + md/json), skill cv-linkedin-sync (fonte única da regra de parse/limitações) e integração de leitura em cv-linkedin/cv-optimize. Esforço ~5-6h.

### 222. Hub: campo `profile_objective` (objetivo do perfil) que orienta o posicionamento no LinkedIn
- Resolved: 2026-09-03T00:04
- Durations: backlog=- waiting=- dev=0h review=- qa=- publish=0h total=1d
- Severity: medium
- Type: feat
- Report: william_pereira
- Reviewers: 2
- Remote: #143
- Summary: Adicionar ao hub.json um campo opcional `profile_objective` que declara o objetivo atual do perfil — procurar emprego (job_search), criar conexões (connections), vender serviços (services_sales) ou marca pessoal (personal_branding) — com `target_role` e `note` livres. O objetivo DEVE ditar o posicionamento — estender schema.json (properties + optional), validar em validate.py, atualizar cv-hub SKILL (schema canônico, regra de coleta, README mirror) e instruir consumidores. Esforço ~2-3h.

### 292. Renomear o PDF do currículo do cv-tailor para o padrão comercial <Nome Sobrenome> - <Cargo>.pdf
- Resolved: 2026-09-02T10:04
- Durations: backlog=- waiting=- dev=0h review=- qa=- publish=0h total=10h
- Severity: low
- Type: feat
- Report: william_pereira
- Reviewers: 1
- Remote: #141
- Summary: Hoje o cv-tailor gera o PDF do currículo como resumes/<job-slug>/curriculo.pdf (nome genérico em português dentro de uma pasta já em inglês). O usuário quer um nome mais amigável/comercial, incluindo o nome do candidato e o cargo da vaga. Decisão de negócio (alinhada com o usuário) — -

