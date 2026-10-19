# PRD 00 — Fundação, Autenticação e Shell

> Feature **00** | Épico E0 (Fundação) | Depende de: — | Roadmap req. §12.0
> Convenção: **[hipótese]** = inferência do planejador; **a definir** = mantido do requisito.

## 1. Problema
O itallus precisa de uma **base técnica** antes de qualquer funcionalidade de negócio:
sem login, casca de navegação e arquitetura plugável, nenhuma área pode ser construída
de forma coerente, segura e substituível. O requisito define a **v1 operacional em
produção** como **login/autenticação + página inicial com a estrutura hierárquica das
áreas e seus departamentos**; na v1 as **páginas de departamento** trazem **placeholder
apenas de conteúdo** (o negócio entra nas features seguintes) e são **renderizadas como
telas acabadas no padrão** (RNF0.12), **não "em branco"** — a **área** é nó agrupador,
**sem página própria**.

## 2. Contexto
- Primeira entrega; **não há código de aplicação** ainda (projeto em planejamento).
- Stack fixada: **Python** no backend, **Supabase self-hosted** (auth/banco/logs/backup),
  **PostgreSQL**, **React + Tailwind + shadcn** no frontend. **Framework JS = Next.js**
  (escolhido visando possível migração futura para a nuvem — ecossistema SSR maduro).
  **Framework backend = FastAPI + SQLModel** (Pydantic + SQLAlchemy).
- **Estrutura = monorepo** (ver `visao-geral.md` ADR-004): **`apps/api`** (FastAPI + uv,
  Clean Architecture/ports-adapters) + **`apps/web`** (Next.js + Tailwind + shadcn).
  `docs/`, `.github/`, `.githooks/` e a skill `.claude/skills/ui-ux-pro-max/`
  ficam na raiz. **Esta feature monta esse esqueleto pela primeira vez.**
- **Contrato front↔back** (ver `visao-geral.md` ADR-005): o **FastAPI gera o OpenAPI**
  (fonte da verdade) e o `apps/web` gera um **client TS tipado via orval** (client + hooks
  **TanStack Query**, em `apps/web/lib/api/`). **Esta feature estabelece esse pipeline.**
- **Design system** (ADR-005): **ui-ux-pro-max** (skill offline/versionada) gera **uma
  vez** o `apps/web/design-system/MASTER.md` (Master + Overrides em `pages/*.md`), no
  **padrão SaaS/ERP corporativo moderno para uso interno diário** — estética **sóbria, de
  baixo ruído, minimalista** (**vedados** padrões de marketing/conversão e gradientes "AI"
  roxo/rosa). **Brief = plataforma operacional multi-módulo** (estilo ERP, orientada a
  processo/estado; 3 áreas expandindo seus departamentos sob navegação única hierárquica), **não** o brief
  genérico "Analytics Dashboard". **Requisitos transversais de UI:** componente reutilizável
  de **pipeline/stepper de status** (fluxos lineares pós-venda), **tabelas densas** com
  filtro/ordenação/paginação **server-side**, **anexo/preview de documentos** e **trilha de
  auditoria**; **variação por área** (BID = funil/comparação, feature 10). **Marca restrita
  a CORES + LOGOTIPO** (guia da marca em PDF, **não versionado**, para a paleta + ícones em
  `docs/references/brand-identity/logo/icons/`) — **tipografia e iconografia NÃO ficam vinculadas à
  marca** (escolha do padrão SaaS/ERP). As features seguintes herdam dele.
  **`frontend-design@claude-plugins-official` excluído.** **Tema = light na v1; dark mode
  diferido** (não-v1) — o design system **reserva os tokens** para não retrabalhar
  (clarificação 2026-06-24).
- **Data layer** (ver `visao-geral.md` ADR-006): **SQLModel** define tabelas/ORM e
  **Alembic** versiona o schema (`target_metadata = SQLModel.metadata`); **as policies de
  RLS vivem nas migrações** (schema+RLS juntos por feature). A **conexão de runtime ao
  Postgres respeita RLS** — usa **role não-privilegiado** (NUNCA `service_role`) e a
  **identidade do JWT é propagada por transação** via `set_config('request.jwt.claims', …,
  true)` — esta feature estabelece esse trilho (policies por tabela = feature 01). **Valores
  monetários e percentuais = `Decimal`/`NUMERIC`, nunca
  `float`.**
- **Dev/CI/CD** (ver `visao-geral.md` ADR-007/010/011): a aplicação é **100% containerizada**
  (`api`, `web` e qualquer **serviço da aplicação em runtime** rodam **só como containers Docker,
  nunca direto no host** — ADR-011; o **ferramental de verificação** — suíte de testes, verificadores
  de repositório, geração do client tipado — roda no **host de desenvolvimento** e no **runner da
  integração contínua**); o **`docker-compose` da raiz orquestra via `include`** os composes de cada serviço
  (`apps/api/docker-compose.yml`, `apps/web/docker-compose.yml`) + o do stack Supabase (raiz **não**
  inline) e sobe/derruba o **projeto inteiro** com **um comando** em
  **dev e produção** — **stack Supabase self-hosted COMPLETO** (~8–12 containers, incl. **Studio** e
  **Storage**; não um subconjunto mínimo) **+ `api` + `web`** —, config externalizada, com **paridade
  dev↔prod de stack/topologia**. **Dev × produção são explícitos no empacotamento (ADR-011):** o
  **compose base descreve DEV** (constrói localmente, **monta a fonte**, **recarga automática**) e uma
  **sobreposição de produção** o substitui pela **imagem versionada** — **sem montagem de fonte e sem
  recarga**; a **CI publica as imagens de aplicação num registry**, **versionadas de forma imutável por
  versão do código**, e a **produção PUXA a imagem pronta — não constrói nada no host** (coerente com
  pull-based/egress-only). A `api` conecta ao Postgres **direto
  na rede do compose** (serviço `db`); e o `web` faz **Auth ao Supabase de dois contextos** —
  **server-side** pela **rede interna do compose** (gateway Kong), **navegador** pela **URL publicada
  no host** — com a **config do `web` distinguindo as duas URLs** (ADR-011). **O deploy de produção
  é entregável desta feature** — implantado **de forma reproduzível via provisionamento
  (infra-as-code, nomeado por papel `infra/deploy`, inclui bootstrap/registro do runner no host de
  produção) + runbook `DEPLOY.md`** e **medido no momento próprio** (**(a)** mecanismo provado
  **antes do PR, sobre a aplicação** — deploy **disparado
  fora do fluxo de merge, a partir da definição já integrada à linha principal**, **apontando para a
  revisão da branch da feature** —, provando runner→imagem
  daquela versão puxada→stack saudável→migrações→serviço com evidência: **é esta a metade que
  constitui critério de pronto desta feature**; **(b)** liveness **pós-merge**
  com **smoke test + rollback automático**, sendo **rollback = re-implantar a versão imutável anterior
  do registry, sem reconstruir** — **entregue como MECANISMO por esta feature**; a **liveness
  pós-deploy** é **MEDIDA por ela** (deploys de produção `35136474611`, `35223484216`, `35227709700`
  com passo de saúde + smoke test passando — a versão implantada responde). A **execução da reversão
  pelo artefato** também está **MEDIDA sob a 00**, com a execução capturada em **2026-09-21** (run **35559037188**) —
  ADR-010)
  (O0.8/O0.12/RNF0.11/RNF0.15/RNF0.16);
  **CI = GitHub Actions (nuvem)** em **PR** **e exercitável sobre a revisão da branch antes do PR**
  (disparo **fora de `pull_request`**, **a partir da definição de CI já integrada à linha principal**)
  (lint + testes api + build web + **gate de drift OpenAPI→orval**
  + **RLS via testcontainers** no runner — só o Postgres que os testes exigem, **não** o stack
  completo — **e publicação das imagens versionadas no registry**) — **esta feature monta o pipeline**;
  testes com **pytest + testcontainers** (RLS
  real) e **Vitest** no frontend.
  **A definição do pipeline (CI + deploy) é entregável versionado desta feature e ENTRA NA LINHA
  PRINCIPAL ANTES de ser exercitada**, por **rota própria, separada do PR da aplicação** (ADR-010
  item 10) — **pipeline é código na linha principal**, que evolui **por PR como qualquer outro**;
  **quem aguarda o PR da feature é a aplicação**. **Integrar não é exercitar:** nessa integração
  **nenhuma execução de deploy chega a ser criada** (O0.13/RNF0.18/M0.11). **No PR que integra a
  definição, os gates de CI que verificam a aplicação ficam sem objeto** (ela ainda não está na linha
  principal) e **não são executados** — **exceção declarada e aceita**: o **job sem fonte fica
  visivelmente não-executado, nunca reportado como aprovado**, e **assim que a aplicação existe na
  linha principal os gates voltam a ser exigidos em todo PR, sem exceção** (O0.13/RNF0.18).
  **CD = pull-based** (o host de produção puxa da `master`; egress/sem-ingress;
  **mecanismo = runner self-hosted do GitHub Actions no host de produção**). **Topologia = dev (local) + prod
  (host único), ambos com o stack Supabase COMPLETO; NÃO há ambiente qa/staging de runtime** (a
  branch `qa` é gate de código; 2º stack always-on rejeitado — trade-off de custo aceito,
  constitution IX/ADR-010).
- **Convenções de API + auditoria** (ver `visao-geral.md` ADR-008): **paginação, envelope de erro
  único e versionamento** são **decididos aqui (1×)** e herdados
  por todas as features — **filtro/ordenação NÃO** entra na 00 (catálogo de navegação estático, sem
  lista filtrável real); a convenção de **filtro** é a da **1ª lista filtrável real — a lista de
  usuários da feature 06d** (um parâmetro de situação; omitido = todos), e a de **ordenação** fica p/
  a 1ª lista ordenável real. E a **tabela
  de auditoria de uso/operações sensíveis** (LGPD = um dos drivers) tem seu baseline criado aqui.
- Deploy **on-prem**, **VM dedicada**; acesso **interno (rede direta ou VPN)**, **sem
  entrada externa (ingress)**, **com saída para a internet (egress)**.
- Requisitos de arquitetura: **Clean Code, SOLID, design patterns**, padrões ISO
  (constitution) e **plugabilidade** de componentes em geral (catálogo de ports/adapters
  no ADR-004).
- Âncora dos **concerns cross-feature**: acesso por departamento (feature 01), LGPD, ports &
  adapters, observabilidade (**structlog desde a v1**; OpenTelemetry posterior), config
  externalizada (ver `visao-geral.md` §8).
- **Fronteira autenticação × autorização (ADR-009):** o **Supabase Auth** provê **só
  autenticação**; a **autorização** (`department_access` + papel, RLS) e o **ciclo de vida do
  usuário** (criação/convite/reset via **Auth Admin API**, com **credencial privilegiada
  server-side** distinta da conexão de dados) são da **feature 01** — reforça **00 e 01
  separados**. Aqui se estabelece o baseline de **autenticação** + a guarda de **secrets/config**.

## 3. Objetivos
- O0.1 — Login/autenticação funcional via Supabase Auth (self-hosted).
- O0.2 — **Shell** da aplicação com **navegação única hierárquica** refletindo **3 áreas,
  cada uma expandindo seus departamentos** (7 no total) — **Supply Chain Management**
  (Logística, Importação, Parcerias, BID), **Financeiro** (Compras) e **Planejamento**
  (Contratos, Faturamento). Quem tem **página** é o **departamento** (a **área** apenas
  agrupa/expande, **sem página própria**); na v1 a página traz **placeholder só de
  conteúdo**, **renderizada como tela acabada no padrão** (RNF0.12), **não "em branco"**.
- O0.3 — Esqueleto de **Clean Architecture / ports & adapters** com auth e banco atrás
  de **interfaces** (plugabilidade), no **monorepo** `apps/api` + `apps/web` (ADR-004).
- O0.4 — **Config 100% externalizada** por ambiente (**dev/prod**; **+ CI**) — a mesma config
  **seleciona o ambiente** (e, na feature 02a, o **alvo NetCorp** — ADR-010) — constitution VII.
- O0.5 — **Baseline de LGPD** e **observabilidade** estabelecido (registro de dados
  sensíveis, retenção, **logging estruturado com structlog sem PII/segredo**) —
  constitution VIII, V, VI. (**OpenTelemetry** = posterior; o **painel = Studio do Supabase**,
  disponível no ambiente porque o **stack Supabase completo** roda em dev e prod — ADR-009/010.)
- O0.6 — **Pipeline de contrato** `OpenAPI (FastAPI) → orval` operante: o `apps/web`
  consome um **client TS tipado + hooks TanStack Query** gerado do OpenAPI (ADR-005).
- O0.7 — **Bootstrap do design system**: gerar **uma vez** o `apps/web/design-system/
  MASTER.md` via **ui-ux-pro-max** (Master + Overrides), no **padrão SaaS/ERP corporativo
  moderno** (brief = plataforma operacional multi-módulo; marca restrita a cores + logotipo —
  ativos em `docs/references/brand-identity/`); telas futuras herdam dele.
- O0.8 — **Deploy de produção reproduzível e mensurável** (ADR-010): a v1 é implantada no **host
  de produção** **exclusivamente via o provisionamento + o runbook** (O0.12), **sem passos
  improvisados**, com **secrets de produção externalizados no host de produção** (nada versionado) e **acesso por
  VPN/rede interna sem ingress**. A **produção PUXA a imagem versionada do registry** publicada pela
  CI — **não constrói no host** (ADR-011). O deploy assume um **ambiente-alvo sem conflitos** (único
  pré-requisito genérico: **portas e nomes de container livres no host-alvo**). Tem **duas
  metades**, medidas em momentos distintos: **(a) ANTES do PR, sobre a aplicação** — o deploy é
  **disparado fora do fluxo de merge**,
  **a partir da definição de pipeline já integrada à linha principal** (O0.13), **apontando para a
  revisão da branch da feature** (**a definição habilita; a revisão determina o que é implantado**) —,
  implanta no host de produção e prova **runner→imagem daquela versão puxada do registry (o host não
  constrói)→stack saudável→migrações→serviço**, com **evidência**: **esta metade é o critério de
  pronto desta feature**;
  **(b)** a implantação **real na `master`** (pós-merge) é confirmada por **smoke test pós-deploy**
  (saúde + probe) com **rollback automático** em falha — **rollback = re-implantar a versão imutável
  anterior a partir do registry, sem reconstruir**, consultando o **estado do deploy (última versão
  boa conhecida) persistido no host de produção**. **A metade (b) é entregue como MECANISMO por esta
  feature**; a **liveness pós-deploy** é **MEDIDA por ela**: a **aplicação implantável da 00 é o
  próprio stack de fundação**, **já implantado em produção** (deploys de produção **35136474611**,
  **35223484216**, **35227709700** com passo de saúde + smoke test passando — a versão implantada
  responde). A **execução da reversão pelo artefato** também está **MEDIDA sob a 00**, com a execução
  capturada em **2026-09-21** (run **35559037188**). Nenhuma dessas responsabilidades é transferida à feature 01.
- O0.9 — **Data layer com migração**: SQLModel + **Alembic** (autogenerate); 1ª migração
  cria o baseline; conexão de runtime com **role não-privilegiado** (`itallus_app`) que
  **respeita RLS** e **propaga o JWT por transação** (`set_config('request.jwt.claims', …,
  true)`) (ADR-006).
- O0.10 — **Plataforma de dev/CI/CD**: **aplicação 100% containerizada** — `api` (FastAPI) e
  `web` (Next.js), como qualquer **serviço da aplicação em runtime**, rodam **exclusivamente como
  containers Docker, nunca direto no host** (ADR-011); o **ferramental de verificação** (suíte de
  testes, verificadores de repositório, geração do client tipado) roda no **host de desenvolvimento**
  e no **runner da integração contínua**. O **ambiente reproduzível de dev** inclui o **seed
  idempotente do usuário de desenvolvimento** (credenciais por **config externalizada**, nada
  versionado — RNF0.19). O **`docker-compose` da raiz** é um **orquestrador**: faz
  **`include`** dos composes de **cada serviço** (`apps/api/docker-compose.yml`, `apps/web/docker-compose.yml`
  — cada app descreve o próprio serviço) + o compose do stack Supabase **COMPLETO** (incl. Studio/Storage),
  **não** descrevendo `api`/`web` inline; o `up` na raiz sobe/derruba o **projeto inteiro** com **um
  comando**, em **dev e produção**. **Dev × produção são explícitos no empacotamento:** o **compose
  base descreve DEV** (constrói localmente, monta a fonte, recarga automática) e uma **sobreposição de
  produção** o substitui pela **imagem versionada** (**sem montagem de fonte, sem recarga**) — a
  **produção puxa a imagem do registry e não constrói no host**. A `api` conecta ao Postgres
  **direto na rede do compose** (serviço `db`), sem passar pelo Supavisor (ADR-006/010). O `web`
  (Next.js) faz **Auth ao Supabase de dois contextos**: o **server-side** alcança o **gateway (Kong)
  pela rede interna do compose (nome de serviço)** e o **navegador** a **URL publicada no host**,
  então a **config do `web` distingue as duas URLs** (ADR-011). **CI =
  GitHub Actions (nuvem)** em PR **e exercitável sobre a revisão da branch antes do PR** (disparo
  **fora de `pull_request`**, **a partir da definição de CI já integrada à linha principal** — O0.13)
  (lint + testes api + build web + **gate de drift OpenAPI→orval**
  + **RLS via testcontainers**), que **publica as imagens versionadas no registry** (RNF0.16), com
  **pytest** e **Vitest**. **No PR que integra a definição do pipeline (O0.13) esses gates ficam sem
  objeto** — a aplicação ainda não está na linha principal — e **não são executados**: **exceção
  declarada**, com o **job visivelmente não-executado (nunca "aprovado")** e **retomada obrigatória
  dos gates em todo PR** assim que a aplicação existir na linha principal. **CD = pull-based** (o host de produção puxa da
  `master`; mecanismo = **runner self-hosted do GitHub Actions no host de produção**) e **sem ambiente
  qa/staging de runtime** (ADR-007/010/011).
- O0.11 — **Convenções transversais de API + tabela de auditoria**: paginação,
  **envelope de erro único** e versionamento definidos 1× (**filtro/ordenação NÃO** — catálogo
  estático; o filtro fica com a 1ª lista filtrável real, a lista de usuários da 06d, e a ordenação com
  a 1ª lista ordenável real); baseline da **tabela
  de auditoria** (ADR-008).
- O0.12 — **Handoff de deploy entregue** (ADR-010): **provisionamento reproduzível do servidor**
  como **infra-as-code**, **nomeado por papel** (`infra/deploy`, não pela tecnologia do alvo) —
  **bootstrap/registro do runner self-hosted no host de produção** + configs de host, **idempotente e
  versionado** (hoje o CD **pressupõe o runner já existindo**; a 00 passa a entregar os **meios de
  criá-lo**) — e **runbook de deploy de produção (`DEPLOY.md`)**: **documento de foco único e
  autocontido** que reúne tudo o que o operador precisa para subir o ambiente do zero (obter código →
  bootstrap → config/segredos no host → subir o stack + aplicar migrações → verificação de saúde), com
  **pré-requisito concreto** (portas e nomes de container livres no host-alvo).
- O0.13 — **Definição do pipeline integrada à linha principal antes de ser exercitada** (ADR-010
  item 10): a **definição do pipeline** — **integração contínua e deploy** — é **entregável
  versionado desta feature** e **entra na linha principal ANTES de ser exercitada**, por **rota
  própria, separada do PR da aplicação**, **evoluindo por PR como qualquer código**. **Quem aguarda
  o PR da feature é a aplicação, não o pipeline.** **Integrar não é exercitar:** nessa integração
  **nenhuma execução de deploy chega a ser criada** — naquele instante a linha principal ainda **não
  tem aplicação** nem a **referência de última versão boa** a que reverter. **Gates de integração
  contínua nesse PR = exceção declarada e aceita:** os gates que **verificam a aplicação** **não têm
  objeto** e **não são executados** ali, sob **duas condições** — o **job sem fonte fica visivelmente
  NÃO-EXECUTADO, nunca reportado como aprovado** (uma exceção confundível com aprovação seria **pior
  do que não ter gate**: certificaria como verificado o que **ninguém verificou**) e, **a partir do
  momento em que a aplicação existe na linha principal**, os gates **voltam a ser exigidos em TODO
  PR, sem exceção**.

## 4. Solução Proposta
- **Monorepo (ADR-004):** `apps/api` (backend) + `apps/web` (frontend) no mesmo repo;
  `docs/`, `.github/`, `.githooks/` e `.claude/skills/ui-ux-pro-max/` na raiz.
- **Backend (`apps/api`):** FastAPI + uv; camadas `domain / application / ports / adapters`
  (KB clean-architecture). Auth e banco expostos como **portas** (Protocols/ABCs);
  implementações concretas = **adapters out** (Supabase Auth, Postgres). `tests/` espelha
  `app/`. **Logging/config/validação** são transversais (facade nas bordas — **não** ports,
  ADR-004). **Middlewares/circuit breaker:** o lugar fica reservado, mas **não** se
  implementa agora (posterior).
- **Frontend (`apps/web`):** **Next.js** + React + Tailwind + shadcn; `app/` (App Router),
  `components/`, `lib/api/`, `design-system/`. **Layout shell** (sidebar/topbar) com as
  **3 áreas** como itens de navegação **expansíveis em seus departamentos** (7) e
  **rotas por departamento** com **placeholder de conteúdo** (tela acabada no padrão —
  RNF0.12); a **área** apenas agrupa/expande na navegação, **sem página própria**.
- **Contrato OpenAPI → orval (ADR-005):** o FastAPI **gera o OpenAPI** automaticamente
  (fonte da verdade); o `apps/web` roda **orval** para gerar **client TS + hooks TanStack
  Query** por endpoint em `lib/api/`. O passo de codegen entra no build/CI (drift pego em
  compile-time).
- **Design system (ADR-005):** rodar o **ui-ux-pro-max** **uma vez** para gerar
  `apps/web/design-system/MASTER.md` (cores, tipografia, espaçamento, componentes shadcn) no
  **padrão SaaS/ERP corporativo moderno** (sóbrio/baixo ruído/minimalista; sem marketing nem
  gradientes "AI"), a partir do **brief da plataforma operacional multi-módulo** (não "Analytics
  Dashboard"). Contemplar os **requisitos transversais de UI** (stepper de status, tabelas densas
  server-side, anexo/preview de documentos, trilha de auditoria) e a **variação por área** (BID =
  funil). **Marca = cores + logotipo apenas:** extrair a **paleta** e as **regras de uso de logo**
  do **guia da marca** (PDF **não versionado**)
  e incorporar o **ícone/logotipo** (`docs/references/brand-identity/logo/icons/`: `Icon@2x (3).png` default,
  `Icon_black@2x.png`, `Icon_white@2x.png`) no shell; **tipografia/iconografia = escolha do padrão**,
  não do guia. Overrides por tela em `pages/*.md`. Telas das features seguintes herdam do Master.
- **AuthN:** sessão Supabase; backend valida o token em cada fronteira (constitution V). A
  **sessão do `web`** é acessada/renovada tanto no **navegador** quanto **server-side**
  (middleware/route handlers no container); o **caminho interno** das chamadas server-side ao Supabase
  e a **distinção das duas URLs** (navegador × interna) ficam no **ADR-011**.
- **Config:** variáveis de ambiente / arquivo externo; **sem segredo no repositório**; a config do
  `web` inclui **duas URLs do Supabase** — a **voltada ao navegador** e a **interna (rede do compose)
  usada server-side** (ADR-011).
- **Observabilidade:** **logging estruturado com structlog** desde a v1, sem PII/segredo;
  correlação de requisição. **OpenTelemetry** (métricas/tracing) = **posterior**.
- **LGPD baseline:** registro (data map) das entidades com dado pessoal + política de
  retenção com prazos (**prazos a definir**) + ganchos de apagamento/anonimização +
  **baseline da tabela de auditoria** (ADR-008) para operações sensíveis (PII + valores).
- **Migração de schema (ADR-006):** **SQLModel** define as tabelas; **Alembic**
  (`target_metadata = SQLModel.metadata`, autogenerate) versiona o schema feature a feature.
  As **policies de RLS** são escritas **dentro das migrações** (`op.execute("CREATE POLICY …")`)
  — schema e RLS versionados juntos. (Substitui a [hipótese] de "ferramenta de migration".)
- **Caminho de dados / endpoint do Postgres (ADR-006/010):** a **API é o único componente que
  acessa o banco**, **gerencia o próprio pool de conexões** e conecta-se **diretamente à instância
  Postgres** — **nas migrations (Alembic) e na persistência de runtime**. O **Supavisor** (pooler do
  stack self-hosted) atende ao **ecossistema interno do Supabase** e **não está no caminho de dados
  da aplicação**; o endpoint concreto por ambiente vem de **config externalizada** (constitution VII).
- **Acesso ao banco que respeita RLS (ADR-006):** a conexão de runtime usa **role
  não-privilegiado** (`itallus_app`, NUNCA `service_role`) e **propaga a identidade do JWT
  por transação** via `set_config('request.jwt.claims', …, true)` para as policies (feature
  01) aplicarem. **Esta feature fixa o trilho** (role + setagem do claim por transação); as
  **policies concretas por tabela** ficam para a **feature 01**. Jobs administrativos (ex.:
  sync NetCorp, features 02a/02b) usam role próprio fora do caminho do usuário.
- **Valores = `Decimal`/`NUMERIC`, nunca `float`** (ADR-006): convenção fixada no baseline
  (tipos e serialização **string** no JSON do OpenAPI) — herdada por todas as features de
  valor.
- **Containerização + compose raiz único (ADR-011):** `api` (FastAPI), `web` (Next.js) e qualquer
  **serviço da aplicação em runtime** rodam **exclusivamente como containers Docker, nunca direto no
  host**; o **ferramental de verificação** (suíte de testes, verificadores de repositório, geração do
  client tipado) **não** é serviço de runtime — roda no **host de desenvolvimento** e no **runner da
  integração contínua**. O
  **`docker-compose` da raiz orquestra via `include`** os composes de **cada serviço**
  (`apps/api/docker-compose.yml`, `apps/web/docker-compose.yml` — cada app descreve o próprio serviço)
  **+ o compose do stack Supabase completo**; a raiz **não** descreve `api`/`web` inline. O `up` na raiz
  sobe/derruba o **projeto inteiro** com **um comando**, em **dev e produção**. A `api` conecta ao
  Postgres **direto na rede do compose** (serviço `db`), coerente com
  ADR-006/010 (Supavisor fora do caminho de dados). O `web` (Next.js) roda o **mesmo código no
  navegador e server-side** (middleware/handlers no container) e faz **Auth ao Supabase nos dois**: o
  **server-side** usa o **gateway (Kong) pela rede interna do compose (nome de serviço)** e o
  **navegador** a **URL publicada no host**, então a **config externalizada do `web` distingue as duas
  URLs** — mesmo princípio da `api`→Postgres (ADR-006/010). Alternativa rejeitada = **composes por app sem
  orquestrador raiz** (exigiria vários comandos); a orquestração via `include` mantém "**um comando p/ o
  projeto inteiro**".
- **Empacotamento — dev constrói, produção roda imagem versionada (ADR-011):** o **compose base
  descreve DEV** — **constrói a imagem localmente**, **monta a fonte** e roda com **recarga
  automática**; uma **sobreposição de produção** **substitui** isso pela **imagem versionada**, **sem
  montagem de fonte e sem recarga**. A **CI publica as imagens de aplicação num registry**,
  **versionadas de forma imutável por versão do código**, e a **produção PUXA a imagem já construída —
  não constrói nada no host** (coerente com o **CD pull-based / egress-only**, ADR-010). Assim, a
  **imagem validada na CI é exatamente a que sobe em produção**, o **build sai do host de produção** e
  passa a existir um **artefato imutável para onde o rollback reverte**. Permanecem: **aplicação 100%
  containerizada** e **um comando sobe o projeto inteiro** — muda **de onde vem a imagem**. Forma
  concreta (registry, esquema de versão/tag, layout da sobreposição) = **derivada no Design**.
- **Deploy de produção (entregável da 00 — ADR-010):** **workflow de CD real** implanta a v1 no **host
  de produção** por **pull** da `master` — **puxando a imagem versionada do registry** (o host **não
  constrói**, ADR-011) e subindo/reiniciando o stack —, **de forma reproduzível via o
  provisionamento + runbook** (sem passos improvisados); **secrets de produção externalizados no host de produção**
  (nada versionado); **acesso verificado por VPN/rede interna sem ingress**. O deploy assume um
  **ambiente-alvo sem conflitos** — único pré-requisito genérico: **portas e nomes de container
  exigidos pelo stack livres no host-alvo**. **Duas metades:** **(a)** **antes do PR**, o deploy é
  **disparado fora do fluxo de merge**, **a partir da definição de pipeline já integrada à linha
  principal**, **apontando para a revisão da branch da feature**, provando
  runner→imagem daquela versão puxada→stack saudável→migrações→serviço, com **evidência** — **metade
  que constitui o critério de pronto da 00**; **(b)** a
  implantação real
  na `master` (pós-merge) é confirmada por **smoke test pós-deploy** (saúde + probe) com **rollback
  automático** em falha — **mecanismo entregue por esta feature**; a **liveness pós-deploy** é **MEDIDA
  por ela**: a **aplicação implantável da 00 é o próprio stack de fundação**, **já implantado em
  produção** (deploys de produção **35136474611**, **35223484216**, **35227709700** com passo de saúde
  + smoke test passando — a versão implantada responde). A **execução da reversão pelo artefato**
  também está **MEDIDA sob a 00**, com a execução capturada em **2026-09-21** (run **35559037188**).
  Nenhuma dessas responsabilidades é transferida à feature 01.
- **Definição do pipeline na linha principal (ADR-010 item 10):** a **definição do pipeline** (CI +
  deploy) é **versionada** e **entra na linha principal ANTES de ser exercitada**, por **rota própria,
  separada do PR da aplicação** — **pipeline é código na linha principal**, que evolui **por PR como
  qualquer outro**; definição que vive **só numa branch** é **rascunho, não pipeline**. É **fronteira
  de segurança da plataforma**: o **disparo manual** só existe para definição **já na linha
  principal** — de outra forma **qualquer branch executaria o pipeline com os segredos do
  repositório**, contra o host de produção. **A integração NÃO implanta produção**, e isso é
  verificado por **prova de origem** — **nenhuma execução de deploy chega a ser criada**: o **registro
  de execuções do pipeline logo após a integração não exibe execução de deploy alguma**, com
  **evidência** (M0.11). **Não basta** que a execução **não tenha implantado**: uma execução **criada
  e interrompida internamente** **aparece no registro** e obriga quem lê a **interpretar** em vez de
  **observar** (**ausência de execução é fato; presença interrompida é interpretação**); e **declarar
  a intenção do gatilho não basta**. **Gates de CI nesse PR:** os que **verificam a aplicação** ficam
  **sem objeto** e **não são executados** — **exceção declarada**, com **não-execução visível** (nunca
  "aprovado") e **retomada obrigatória dos gates em todo PR** assim que a aplicação existir na linha
  principal. **Ordenação:** definição integrada → prova do mecanismo sobre a **revisão da branch** → PR
  da aplicação → liveness pós-deploy (**medida sob a 00** — a aplicação implantável da 00 é o próprio
  stack de fundação, já implantado em produção). **Rota concreta de integração, forma de integrar sem criar execução de deploy e forma
  da não-execução visível = derivadas no Design.**
- **Rollback = reverter para o artefato anterior, não reconstruir (ADR-010):** o **rollback automático**
  **re-implanta a versão imutável anterior a partir do registry**, **sem reconstruir**. O **registry é o
  repositório de artefatos** do fluxo de entrega, e o **estado do deploy** (**qual é a última versão boa
  conhecida**) é **persistido no host de produção** — é o que o rollback **consulta**. Reconstruir
  durante um rollback é **lento** e pode **falhar por causas novas** (dependência indisponível,
  imagem-base alterada, rede) **justamente com a produção quebrada**. O **mecanismo de entrega
  permanece** (pull-based, runner self-hosted, egress-only, sem ingress). Mecânica concreta = **derivada
  no Design**.
- **Handoff de deploy (provisionamento + runbook — ADR-010):** entregar o **provisionamento
  reproduzível do servidor** como **infra-as-code**, **nomeado por papel** (`infra/deploy`, não pela
  tecnologia do alvo) (**bootstrap/registro do runner self-hosted no host de produção** + configs de
  host, **idempotente e versionado** — o runner deixa de ser **pressuposto**) e o **runbook de deploy
  de produção (`DEPLOY.md`)** — **documento de foco único e autocontido** (reúne tudo o que o operador
  precisa; pré-requisito concreto = portas/nomes de container livres no host-alvo; sem meta-informação
  nem escopo de desenvolvimento), cobrindo o caminho ponta-a-ponta (código → bootstrap → config/segredos
  no host → stack + migrações → verificação de saúde). Forma concreta (ferramenta/gatilho/rollback) =
  **derivada no Design**.
- **Dev/CI/CD (ADR-007/010):** o mesmo **`docker-compose` da raiz** sobe o **stack Supabase
  self-hosted COMPLETO** (~8–12 containers, incl. **Studio** e **Storage** — não um subconjunto
  mínimo; config externalizada — paridade **dev↔prod** de **stack/topologia**, sendo o **empacotamento
  dos apps** o que distingue dev × produção (ADR-011); o **host de produção** roda o mesmo stack
  completo + apps, único stack, trade-off de custo aceito — constitution IX); **CI = GitHub
  Actions (nuvem)** em **PR** — **e exercitável sobre a revisão da branch antes do PR** (disparo
  **fora de `pull_request`**, **a partir da definição de CI já integrada à linha principal**), p/
  **evidência ao vivo** do gate de drift e da suíte de RLS **antes de abrir o
  PR** — roda
  **lint + testes da api + build do web + gate de drift** (regenera o client orval e **falha**
  se divergir do OpenAPI) + **RLS via testcontainers** (Postgres real no runner, p/ exercitar
  RLS já na 01) e **publica as imagens de aplicação no registry**, versionadas de forma **imutável por
  versão do código** (é o artefato que a produção puxa e o alvo do rollback — ADR-010/011);
  frontend com **Vitest**. **CD = pull-based** — o **host único (só produção)**
  **puxa** da `master` (egress/sem-ingress); o **mecanismo = runner self-hosted do GitHub
  Actions no host de produção** (event-driven, egress-only; polling caseiro rejeitado). **Não há ambiente
  qa/staging de runtime** — a branch `qa` é **gate de código** (ADR-010).
- **Seed do usuário de desenvolvimento (ADR-007):** o **ambiente reproduzível de dev** inclui um
  **seed idempotente do usuário de desenvolvimento** — aplicável **em ambiente limpo, sem passo
  manual**, **reexecutável sem duplicar** o usuário, com **credenciais por config externalizada**
  (nenhum segredo versionado). É **parte do ambiente reproduzível**, **distinto** de **seed/dados de
  referência de negócio** (diferidos — §7).
- **Convenções de API (ADR-008):** definir **1×** **paginação cursor** (`?limit=&cursor=`;
  limit default 50, máx 200), **envelope de erro único**
  `{ error: { code, message, details[]?, request_id } }` e **versionamento** — refletidos no
  OpenAPI e herdados pelas features seguintes. **Filtro/ordenação NÃO** é definido na 00 (catálogo
  de navegação estático, sem lista filtrável real); o **filtro** segue a **1ª lista filtrável real — a
  lista de usuários da feature 06d** (um parâmetro de situação; omitido = todos) — e a **ordenação**
  fica p/ a 1ª lista ordenável real.

## 5. Requisitos
**Funcionais**
- RF0.1 — Usuário autentica com credenciais; sessão estabelecida e encerrável (logout).
- RF0.2 — Pós-login, exibir **home** com a estrutura **hierárquica** navegável — **3 áreas
  expandindo seus 7 departamentos**.
- RF0.3 — Rotas protegidas: sem sessão válida ⇒ redireciona para login.
- RF0.4 — Quem tem **página** é o **departamento**; a **área** é **nó agrupador da
  navegação, sem página própria**. Na v1 a página de departamento traz **placeholder
  apenas de CONTEÚDO** (o conteúdo de negócio pertence às features seguintes) e é
  **renderizada como tela acabada dentro do padrão SaaS/ERP** (estados, movimento,
  contraste, foco — RNF0.12) — **nunca "em branco" nem tela plana**.
- RF0.5 — O `apps/web` consome um **client TS tipado gerado do OpenAPI via orval**
  (client + hooks TanStack Query); o pipeline de codegen roda no build/CI (ADR-005).
- RF0.6 — Existe um `apps/web/design-system/MASTER.md` gerado **uma vez** pelo
  **ui-ux-pro-max**, no **padrão SaaS/ERP corporativo moderno** (brief = plataforma operacional
  multi-módulo; **marca = cores da paleta + logotipo/ícone**, ativos em `docs/references/brand-identity/`;
  **tipografia/iconografia não vinculadas à marca**), contemplando os **requisitos transversais
  de UI** (stepper de status, tabelas densas server-side, anexo/preview, auditoria) e **variação
  por área** (BID = funil); base visual (shadcn) das telas futuras (ADR-005).
- RF0.7 — Schema versionado por **Alembic** (autogenerate a partir do `SQLModel.metadata`);
  **1ª migração** cria o baseline e as policies de RLS vão **na migração** (ADR-006).
- RF0.8 — Convenções de API (**paginação, envelope de erro único, versionamento**) definidas e
  refletidas no OpenAPI (**filtro/ordenação NÃO** — catálogo estático; o filtro fica com a 1ª lista
  filtrável real, a lista de usuários da 06d, e a ordenação com a 1ª lista ordenável real); **baseline da tabela de auditoria** presente (ADR-008).

**Não-funcionais / arquiteturais**
- RNF0.1 — Auth e banco atrás de **portas**; troca de adapter com **baixo esforço**
  (plugabilidade — **profundidade a avaliar**, ver `visao-geral.md` ADR-001/ADR-004/§5).
- RNF0.2 — **Config externalizada**: **nenhum valor de ambiente é embutido na imagem** — a **imagem
  publicada pela CI é promovida a produção sem rebuild**, trocando só a config (constitution VII;
  ADR-010/011). Em **dev**, a imagem é **construída localmente** a partir do mesmo código, também com
  **config externa**.
- RNF0.3 — Entrada validada nas fronteiras; **logging estruturado com structlog**, **sem
  PII/segredo em log** (constitution V/VI). **OpenTelemetry** = posterior.
- RNF0.4 — Acessível **internamente (rede direta ou VPN)**; **sem entrada externa
  (ingress)**, **com saída para internet (egress)** habilitada.
- RNF0.5 — Alvo de latência de login/carga inicial **a definir** (constitution II: onde o uso
  justifica, alvo explícito para o caminho crítico, derivado de decisão registrada) — **[hipótese]** carga inicial < 2 s em rede interna.
- RNF0.6 — **Estrutura monorepo** `apps/api` + `apps/web` (ADR-004): camadas do backend
  (`domain/application/ports/adapters`), `tests/` espelhando `app/`, sem vazar
  framework/ORM para o domínio.
- RNF0.7 — **Sem drift de contrato**: divergência entre o OpenAPI do backend e o client do
  frontend é pega em **compile-time/CI** (constitution III) — ADR-005. **Casa concreta:** o
  **gate de drift do pipeline de CI** (ADR-007) regenera o client orval e **falha** se
  divergir. **Condição habilitante declarada:** a **evidência antes do PR** deste gate — como a do
  **isolamento de acesso** em Postgres real (M0.8) — **repousa sobre a definição de CI já integrada
  à linha principal** (RNF0.18), disparada **fora de `pull_request`** sobre a **revisão da branch**.
- RNF0.8 — A conexão de runtime ao Postgres **respeita RLS** (**role não-privilegiado**,
  nunca `service_role`, no caminho do usuário) e **propaga os claims do JWT por transação**
  (`set_config('request.jwt.claims', …, true)`) (ADR-006) — segurança/menor privilégio
  (constitution V). A **API conecta-se diretamente à instância Postgres** com **pool próprio**
  (migrations e runtime); **não** passa pelo pooler **Supavisor** (que serve só o ecossistema
  interno do Supabase) — ADR-006/010.
- RNF0.9 — **Config externalizada** também em **dev/CI** via **docker-compose**; o **perfil de dev**
  (build local + fonte montada + recarga) e o **de produção** (imagem versionada do registry) diferem
  **só no empacotamento** — **nunca** em config embutida (constitution VII; ADR-007/010/011).
- RNF0.10 — Valores monetários/percentuais em **`Decimal`/`NUMERIC`/string-JSON**, **nunca
  `float`** (ADR-006) — correção no núcleo de valor (constitution I/II).
- RNF0.11 — **Deploy de produção é entregável da 00, reproduzível e mensurável** (ADR-010):
  **workflow de CD real** implanta a v1 no **host de produção** por **pull** da
  `master` (egress; **sem ingress**) — coerente com RNF0.4; **mecanismo = runner self-hosted do
  GitHub Actions no host de produção** (event-driven, egress-only). A **produção PUXA a imagem
  versionada do registry** publicada pela CI e **NÃO constrói no host** (RNF0.16 / ADR-011). A
  implantação é feita **exclusivamente via o
  provisionamento + o runbook** (RNF0.15), **sem passos improvisados** (reproduzível **do zero**, como
  o schema em M0.7); **secrets de produção geridos por configuração externalizada no host de produção** (nenhum
  segredo versionado); **acesso verificado por VPN/rede interna sem ingress**; **sem ambiente
  qa/staging de runtime** (ADR-010). O deploy assume um **ambiente-alvo sem conflitos** (único
  pré-requisito genérico: **portas e nomes de container livres no host-alvo**). **Duas
  metades:** **(a) antes do PR** — o deploy é **disparado fora do fluxo de merge**, **a partir da
  definição de pipeline já integrada à linha principal** (RNF0.18), **apontando para a revisão da
  branch da feature**, e implanta no host de produção provando runner→imagem daquela versão
  puxada→stack saudável→migrações→serviço, com
  **evidência** — **é esta a metade exigida como critério de pronto da 00**; **(b)** a
  implantação real na `master` (pós-merge) é confirmada por **smoke test pós-deploy** (saúde + probe)
  com **rollback automático** em falha (RNF0.17) — **o mecanismo é entregue por esta feature**; a
  **liveness pós-deploy** é **MEDIDA por ela**: a **aplicação implantável da 00 é o próprio stack de
  fundação**, **já implantado em produção** (deploys de produção **35136474611**, **35223484216**,
  **35227709700** com passo de saúde + smoke test passando — a versão implantada responde). A
  **execução da reversão pelo artefato** também está **MEDIDA sob a 00**, com a execução capturada em
  **2026-09-21** (run **35559037188**). Nenhuma dessas responsabilidades é transferida à feature 01.
- RNF0.13 — **Aplicação 100% containerizada** (ADR-011): `api`, `web` e qualquer **serviço da
  aplicação em runtime**
  rodam **exclusivamente como containers Docker, nunca direto no host** — o **ferramental de
  verificação** (suíte de testes, verificadores de repositório, geração do client tipado) **não** está
  sob essa regra e roda no **host de desenvolvimento** e no **runner da integração contínua**; o **`docker-compose` da
  raiz orquestra via `include`** os composes de cada serviço (`apps/api/docker-compose.yml`,
  `apps/web/docker-compose.yml`) + o do stack Supabase (raiz **não** inline) e sobe/derruba o **projeto
  inteiro** com **um comando** em **dev e produção**. O **compose base descreve DEV** (constrói
  localmente, **monta a fonte**, **recarga automática**); uma **sobreposição de produção** o substitui
  pela **imagem versionada** — **sem montagem de fonte e sem recarga** (RNF0.16). A `api` conecta ao
  Postgres **direto na rede do
  compose** (serviço `db`), fora do Supavisor (ADR-006/010). O `web` (Next.js) faz **Auth ao Supabase
  de dois contextos** — **server-side** pela **rede interna do compose** (gateway Kong, por nome de
  serviço), **navegador** pela **URL publicada no host** —, e a **config externalizada do `web`
  distingue as duas URLs** (constitution VII).
- RNF0.12 — A **v1 (login + casca) realiza integralmente o padrão SaaS/ERP corporativo moderno**:
  **estados, movimento, contraste e foco** no nível de um produto moderno (não telas planas nem
  placeholders visuais), **em TODAS as telas da v1 sem exceção** — ADR-005.
- RNF0.14 — **Responsividade = alvo por tela** (ADR-005): a **tela de login** atende viewports **a
  partir de 375px**; a **casca autenticada** (topbar/sidebar, breadcrumb, páginas de departamento)
  atende viewports **a partir de 768px**. Viewports **abaixo de 768px na casca autenticada NÃO são
  suportados na v1** — o layout **pode quebrar**, e isso é **comportamento aceito, não defeito**.
- RNF0.15 — **Provisionamento reproduzível (infra-as-code) + runbook** (ADR-010): o **bootstrap/
  registro do runner self-hosted no host de produção** e as **configs de host** são entregues de forma
  **idempotente e versionada**, com o componente **nomeado por papel** (`infra/deploy`, não pela
  tecnologia do alvo) (o runner deixa de ser **pressuposto** e passa a ser **criável** pelo
  provisionamento); o **runbook `DEPLOY.md`** é um **documento de foco único e autocontido** que
  descreve o caminho ponta-a-ponta de implantação **do zero** (código → bootstrap → config/segredos no
  host → stack + migrações → verificação de saúde), com **pré-requisito concreto** (portas/nomes de
  container livres no host-alvo) e **sem** meta-informação nem escopo de desenvolvimento. **Forma
  concreta** (ferramenta/gatilho/mecânica do rollback) = **derivada no Design**.
- RNF0.16 — **Artefato imutável: a CI publica a imagem, a produção puxa** (ADR-011): a **CI publica as
  imagens de aplicação (`api`, `web`) num registry**, **versionadas de forma imutável por versão do
  código**; a **produção PUXA a imagem já construída e NÃO constrói nada no host** — a **imagem validada
  na CI é exatamente a que roda em produção**. O **registry é o repositório de artefatos** do fluxo de
  entrega (insumo do deploy e do rollback — RNF0.17). Depende de **egress** (postura já decidida — sem
  ingress). **Registry concreto e esquema de versão/tag = derivados no Design.**
- RNF0.17 — **Rollback = re-implantar o artefato anterior, não reconstruir** (ADR-010): o **rollback
  automático** do deploy (RNF0.11) **re-implanta a versão imutável anterior a partir do registry**,
  **sem reconstruir**; o **estado do deploy** (**última versão boa conhecida**) é **persistido no host de
  produção** e é o que o rollback **consulta**. **É vedado** rollback que **re-obtenha o código e
  reconstrua no host** (lento; pode falhar por causas novas — dependência indisponível, imagem-base
  alterada, rede — justamente com a produção quebrada). **Mecânica concreta = derivada no Design.**
- RNF0.18 — **Definição do pipeline versionada e integrada à linha principal antes de ser
  exercitada** (ADR-010 item 10): a **definição do pipeline** (**CI + deploy**) é **entregável
  versionado desta feature**, **integrado à linha principal ANTES de qualquer exercício**, por **rota
  própria, separada do PR da aplicação**, e **evolui por PR como qualquer código** — definição que
  vive **só numa branch** é **rascunho, não pipeline**. É a **condição habilitante** do disparo fora
  do fluxo de merge usado pelas evidências pré-PR (RNF0.7/RNF0.11): **a definição habilita; a revisão
  da branch determina o que é verificado/implantado**. **É vedado** que a **integração** dessa
  definição **crie qualquer execução de deploy** — a linha principal, naquele instante, **não tem
  aplicação** nem **última versão boa conhecida** para onde reverter (RNF0.17); **não basta** uma
  execução **criada e interrompida internamente** (aparece no registro e exige **interpretação**;
  só a **ausência de execução** é **fato observável** — M0.11). **Gates de integração contínua no PR
  que integra essa definição = exceção declarada e aceita:** os gates que **verificam a aplicação**
  **não têm objeto** e **não são executados** nesse PR, sob **duas condições** — (1) o **job sem fonte
  fica visivelmente NÃO-EXECUTADO**, **nunca reportado como aprovado** (uma exceção confundível com
  aprovação **certificaria como verificado o que ninguém verificou** — pior do que não ter gate); (2)
  **a partir do momento em que a aplicação existe na linha principal**, os gates **voltam a ser
  exigidos em TODO PR, sem exceção**. **Rota concreta de
  integração, forma de integrar sem criar execução de deploy e forma de manter o job visivelmente
  não-executado = derivadas no Design.**
- RNF0.19 — **Seed idempotente do usuário de desenvolvimento** (ADR-007): o **ambiente reproduzível de
  dev** inclui um **seed do usuário de desenvolvimento**, **aplicável em ambiente limpo sem passo
  manual** (mesmo critério do schema — M0.7), **idempotente** (reexecução **não duplica** o usuário) e
  com **credenciais por config externalizada** (nenhum segredo versionado — constitution VII). É
  **parte do ambiente reproduzível** — **distinto** de **seed/dados de referência de negócio**, que
  seguem **diferidos** (§7).

## 6. Métricas
- M0.1 — **Deploy de produção — mecanismo, ANTES do PR** (O0.8/RNF0.11; ADR-010): o deploy,
  **disparado fora do fluxo de merge a partir da definição já integrada à linha
  principal** (M0.11) e **apontando para a revisão da branch da feature**, implanta no host de
  produção e
  prova **runner atende o job → imagem versionada daquela revisão é puxada do registry (o host não
  constrói) → stack sobe saudável →
  migrações aplicam → serviço responde**, com
  **evidência** (sim/não). **A metade (a) permanece o gate de prontidão do mecanismo sobre a
  aplicação.** A **liveness pós-deploy** — v1 **implantada e acessível via VPN/rede interna**,
  confirmada por **smoke test pós-deploy** (saúde + probe) com **rollback automático** em falha — é
  **entregue como mecanismo** (RNF0.11/RNF0.17) **e MEDIDA sob a 00**: a **aplicação implantável da 00
  é o próprio stack de fundação**, **já implantado em produção** (deploys de produção **35136474611**,
  **35223484216**, **35227709700** com passo de saúde + smoke test passando — a versão implantada
  responde). A **execução da reversão pelo artefato** (M0.10) também está **MEDIDA sob a 00**, com a
  execução capturada em **2026-09-21** (run **35559037188**). Nenhuma das duas é transferida à feature 01.
- M0.2 — As **3 áreas** e seus **7 departamentos** presentes na navegação hierárquica (contagem).
- M0.3 — 0 segredos versionados; 0 ocorrências de PII/segredo em log (auditoria).
- M0.4 — **[hipótese]** Tempo de carga inicial dentro do alvo (**alvo a definir**).
- M0.5 — Pipeline **OpenAPI → orval** gera o client e o **CI falha** se houver drift de contrato
  (sim/não) — ADR-005/007; **verificável sobre a revisão da branch antes do PR** (CI **exercitável
  fora de `pull_request`**, **a partir da definição de CI já integrada à linha principal** —
  RNF0.18/M0.11), além de no PR (o **gate de drift do ADR-007 é a casa desta métrica**).
- M0.6 — `design-system/MASTER.md` gerado e presente, no **padrão SaaS/ERP corporativo moderno**
  (brief multi-módulo, não "Analytics Dashboard"; marca = cores + logotipo; sem gradientes "AI")
  (sim/não) — ADR-005.
- M0.7 — `alembic upgrade head` aplica o schema do zero em ambiente limpo (sim/não) — ADR-006.
- M0.8 — **CI verde** (lint + testes api + build web) com testcontainers; suíte de exemplo de
  **RLS** roda em Postgres real (sim/não) — ADR-007; **exercitável sobre a revisão da branch antes do
  PR** (disparo **fora de `pull_request`**, **a partir da definição de CI já integrada à linha
  principal** — RNF0.18/M0.11), para evidência ao vivo antes de abrir o PR.
- M0.9 — **Handoff de deploy** (O0.12/RNF0.15; ADR-010): o **provisionamento** registra o runner e
  prepara o host **de forma idempotente/reproduzível** (do zero) e o **runbook `DEPLOY.md`** está
  **presente, autocontido e suficiente para implantar do zero** (sim/não).
- M0.10 — **Artefato imutável** (RNF0.16/RNF0.17; ADR-010/011): a **CI publica a imagem versionada no
  registry** (sim/não); o **host de produção roda essa imagem — puxada do registry, não construída no
  host** (sim/não); e **construir é estruturalmente impossível no passo de reversão** — o passo que
  reverte **não dispõe de construção de imagem**, verificável na própria definição do pipeline
  (sim/não). **A EXECUÇÃO da reversão** — voltar para a **versão imutável anterior**, lida do **estado
  do deploy persistido no host**, **sem reconstruir** — está **MEDIDA sob a 00**, com a execução
  capturada em **2026-09-21** (run **35559037188**) (sim) — não transferida à feature 01.
- M0.11 — **Definição do pipeline integrada sem que nenhuma execução de deploy seja criada**
  (O0.13/RNF0.18; ADR-010 item 10): a
  **integração da definição do pipeline à linha principal ocorreu** e o **registro de execuções do
  pipeline logo após ela NÃO exibe execução de deploy alguma**, com **evidência** capturada (sim/não)
  — **prova de origem**. **Não satisfaz** uma execução **criada e interrompida internamente**: ela
  **aparece no registro** e obriga quem lê a **interpretar** em vez de **observar** — **ausência de
  execução é fato; presença interrompida é interpretação**. **Afirmar a intenção do gatilho também não
  satisfaz** (convive com um pipeline que disparou). É a métrica que **habilita** as evidências pré-PR
  de M0.1, M0.5 e M0.8.
- M0.12 — **Seed do usuário de desenvolvimento** (O0.10/RNF0.19; ADR-007): o seed **aplica em ambiente
  limpo, sem passo manual**; a **reexecução não duplica** o usuário; e o **usuário semeado autentica de
  fato** (sim/não).

## 7. Fora de escopo
- **Controle de acesso por departamento** (feature **01**) — aqui o shell mostra a estrutura;
  o **gating por permissão**, a **autorização** (`department_access` + papel) e o **ciclo de
  vida do usuário** (criação/convite via **Auth Admin API** — ADR-009) são da **01**. Aqui o
  Supabase Auth provê **só autenticação**.
- Qualquer **conteúdo de negócio** das áreas (contratos, colaboradores etc.).
- **Backup & disaster recovery**, **circuit breaker**, **middlewares avançados**,
  **OpenTelemetry** (métricas/tracing), **microsserviços** — itens **"posterior"** do
  requisito §4. O ADR-004 **reserva o lugar** dos middlewares em FastAPI, mas **não** os
  implementa nesta feature.
- **Testes e2e (Playwright)** e **seed/dados de referência DE NEGÓCIO** — **diferidos de propósito**
  (ADR-007 / visão §11): Vitest (unit) e config externalizada em dev/CI já entram. **O seed
  idempotente do usuário de desenvolvimento NÃO está aqui**: é **parte do ambiente reproduzível** e
  **entregável desta feature** (O0.10/RNF0.19/M0.12) — os dois deixam de ser cobertos pelo mesmo
  termo. **(O deploy de
  produção — incluindo a definição do pipeline (CI + deploy), o provisionamento reproduzível +
  runbook `DEPLOY.md` e os
  secrets de produção externalizados no host de produção — É entregável da 00; ver
  O0.8/O0.12/O0.13/RNF0.11/RNF0.15/RNF0.18 e
  ADR-010.)**
- **Nada de deploy/liveness/rollback fica fora de escopo desta feature.** A **liveness pós-deploy**
  (confirmar que a **versão implantada responde**, com **reversão automática em falha**) e a
  **EXECUÇÃO da reversão pelo artefato** (voltar para a **versão imutável anterior**, lida do **estado
  do deploy persistido no host**, **sem reconstruir**) são **entregues por esta feature** e
  permanecem **sob a 00** (M0.1, M0.10): a **aplicação implantável da 00 é o próprio stack de
  fundação**, **já implantado em produção**. A **liveness pós-deploy** está **MEDIDA** (deploys de
  produção **35136474611**, **35223484216**, **35227709700** com passo de saúde + smoke test passando);
  a **execução da reversão** está **entregue e MEDIDA** (execução capturada em **2026-09-21**, run **35559037188**). A premissa
  de que a medição só seria observável depois de uma aplicação de negócio mergear **envelheceu**, e
  **nenhuma dessas responsabilidades é transferida à feature 01**.

## 8. Riscos e dependências
- **Dependências:** nenhuma (feature raiz). Habilita **todas** as demais.
- **Risco — escopo de plugabilidade:** generalizar **todos** os componentes pode gerar
  **over-engineering**. Mitigar: aplicar ports/adapters onde a troca é plausível
  (auth/banco) e **avaliar custo** antes de ampliar (requisito pede avaliar a complexidade).
- **Risco — shell expõe áreas antes do acesso (01):** baixo (páginas de departamento
  **sem dado de negócio real** — placeholder de conteúdo); entregar **01 antes** de
  qualquer dado real.
- **[hipótese]** Self-hosting do **stack Supabase completo** (~8–12 containers) exige operação
  (atualização/observação) e **divide CPU/RAM com os apps** na VM de 16 GB — considerar esforço
  de ops e **monitorar headroom** em prod; mitigação se houver pressão = desligar containers não
  usados (ex.: Edge Functions/Analytics), trade-off aceito conscientemente (ADR-010/constitution IX).
- **Risco — adequação do ui-ux-pro-max:** seu catálogo é enviesado a **produto/marketing/landing**;
  o itallus é um app **operacional interno (SaaS/ERP)**. Mitigar: usar o gerador **uma vez** a
  partir do **brief da plataforma multi-módulo** (não "Analytics Dashboard") para um `MASTER.md`
  **disciplinado/consistente** (shadcn) no **padrão SaaS/ERP corporativo moderno** (sóbrio/baixo
  ruído; **sem marketing nem gradientes "AI"**), e fazer as telas **herdarem** dele.
- **Risco — cores/logo da marca:** os valores concretos de **paleta** e **regras de uso de logo**
  são **extraídos do guia da marca** (PDF **não versionado**) e estão fixados em
  `apps/web/design-system/MASTER.md`; mitigar tratando o guia como **fonte da verdade de cor/logo**
  e validando o Master contra ele.
  **Tipografia e iconografia não vêm do guia** (escolha do padrão SaaS/ERP).
- **Risco — padrão de v1 não atingido:** o estado atual (design gerado de brief genérico, tipografia
  presa ao guia, telas planas) **não** satisfaz o padrão-alvo. Mitigar: a **v1 (login + casca)
  realiza integralmente** o padrão — estados, movimento, contraste e foco de produto moderno em
  todas as telas — validados no `MASTER.md` e nas telas da casca; a **responsividade segue o alvo
  por tela** (login ≥375px; casca ≥768px, abaixo disso na casca = fora de suporte v1 — RNF0.14).
- **Risco — passo de codegen (orval) no build/CI:** acopla o build do `apps/web` à geração
  do OpenAPI; mitigar com etapa explícita de codegen no pipeline e falha em drift (ADR-005).
- **Risco — propagação de identidade JWT→conexão→RLS** (a "mina"): se a identidade não chegar
  à conexão, as policies não aplicam; mitigar fixando **role não-privilegiado** (`itallus_app`)
  + propagação por transação via `set_config('request.jwt.claims', …, true)` (ADR-006) e
  **testando RLS com Postgres real** (testcontainers, ADR-007). **Trilho fixado na 00**; as
  **policies concretas por tabela** ficam para a **feature 01**.
- **Risco — NetCorp não existe em dev:** mitigar com **stub/fake do port ACL** (ADR-007) — o
  pipeline e os testes rodam sem o legado.
- **Risco — CD pull-based (operação do runner self-hosted):** o **mecanismo decidido** =
  runner self-hosted do GitHub Actions no host de produção (event-driven, egress-only); mitigar com o **runner
  provisionado de forma reproduzível/idempotente** (infra-as-code — deixa de ser **pressuposto**,
  RNF0.15) e o **runbook `DEPLOY.md`**, mantendo o princípio **pull** (egress/sem-ingress) — ADR-010.
- **Risco — a integração da definição do pipeline dispara deploy de produção:** ao chegar à linha
  principal (RNF0.18), a definição pode implantar num momento em que a linha principal **ainda não
  tem aplicação** nem **última versão boa conhecida** para onde reverter (RNF0.17). Mitigar tratando
  o gatilho como **fato verificado, não intenção declarada**: a integração só fecha com **prova de
  origem** — **nenhuma execução de deploy criada**, isto é, **registro de execuções logo após ela sem
  execução de deploy alguma**, com evidência (M0.11); execução **criada e interrompida** não serve
  (aparece no registro e obriga a **interpretar**; só a **ausência** é fato).
- **Risco — gate sem objeto lido como aprovação:** no PR que integra a definição do pipeline os gates
  que verificam a aplicação **não têm o que verificar**, e um relatório de "aprovado" ali
  **certificaria como verificado o que ninguém verificou** — pior do que não ter gate. Mitigar com a
  exceção existindo **apenas** como **não-execução visível** (job **nunca** reportado como aprovado) e
  com a **retomada obrigatória dos gates em todo PR, sem exceção**, assim que a aplicação existir na
  linha principal (O0.13/RNF0.18).
- **Risco — registry no caminho de deploy/rollback:** com a produção **puxando a imagem** (RNF0.16), o
  **registry** vira **dependência** do deploy e do rollback (disponibilidade por **egress**,
  autenticação, retenção das imagens). Mitigar: **imagem imutável por versão** torna a (re)implantação
  **idempotente**; o **estado do deploy (última versão boa conhecida) persistido no host** dá ao
  rollback um **alvo determinado** (RNF0.17); e **produção nunca constrói** — o insumo é sempre um
  artefato **já validado na CI** (ADR-010/011).

---

## Changelog
| Versão | Data | Autor | Mudança |
|--------|------|-------|---------|
| 1.0 | 2026-06-22 | the-planner | Versão inicial |
| 1.1 | 2026-06-23 | refino | Framework JS = Next.js e backend = FastAPI + SQLModel (decididos); rede com egress (interno/VPN, sem ingress, com saída p/ internet); acesso "por departamento"; 00/01 separados |
| 1.2 | 2026-06-23 | refino | ADR-004/005: monorepo (`apps/api` + `apps/web`); esqueleto/shells + pipeline OpenAPI→orval (client + hooks TanStack Query); bootstrap do design-system (MASTER.md via ui-ux-pro-max, 1×); structlog desde a v1 (OTel posterior); catálogo ports/adapters; middlewares só reservam lugar |
| 1.3 | 2026-06-23 | refino | ADR-006/007/008: data layer SQLModel+Alembic (RLS nas migrações) + conexão com role não-privilegiado que respeita RLS e propaga JWT + `Decimal`/`NUMERIC`; docker-compose + CI em PR (lint/test/build/**gate de drift** = casa do M0.5/RNF0.7) + pytest/testcontainers/Vitest + stub do NetCorp; convenções de API (paginação/erro/versionamento) + baseline da tabela de auditoria; Playwright/secrets-prod/seed diferidos |
| 1.4 | 2026-06-23 | refino | ADR-009 (menção leve): fronteira autenticação(Supabase)/autorização(itallus) explícita — a autorização e o ciclo de vida do usuário (criação/convite/reset via Auth Admin API, credencial privilegiada server-side distinta da conexão de dados) são da feature 01; reforça 00/01 separados |
| 1.5 | 2026-06-23 | refino | ADR-010 (ambientes/deploy): topologia **dev (local) + prod (VM única)**, **sem qa/staging de runtime** (`qa` = gate de código); **CI = GitHub Actions (nuvem)** com gate de drift + **RLS via testcontainers**; **CD = pull-based** (VM puxa da master; egress/sem-ingress; mecanismo a definir); config externalizada seleciona o ambiente; corrige "dev/staging/prod" → "dev↔prod" (§2/O0.4/O0.10/§4/RNF0.2/0.9); +RNF0.11 + risco CD |
| 1.6 | 2026-06-24 | refino | Design system (O0.7/RF0.6/ADR-005) **ancorado na identidade visual da marca Italtel** (`docs/brand-identity/`: guia 2024 + ícones `logo/icons/`) em vez de tema genérico — cores/tipografia/logotipo extraídos do guia da marca ao gerar o `MASTER.md` (1×); risco de extração da marca registrado; telas seguintes herdam |
| 1.7 | 2026-06-25 | the-planner | Back-port das decisões da revisão do `/plan` da 00: **CD = runner self-hosted do GitHub Actions na VM** (polling rejeitado); **envelope de erro único** `{error:{code,message,details[]?,request_id}}` + **paginação cursor** (limit 50/200); **propagação JWT→RLS** fixada = `set_config('request.jwt.claims', …, true)` por transação + role `itallus_app` (policies por tabela = feature 01); **auditoria** reenquadrada p/ "uso/operações sensíveis" (LGPD = um dos drivers); **tema light na v1, dark diferido** |
| 1.8 | 2026-06-30 | refino | ADR-010: **docker-compose (dev) e VM (prod) sobem o stack Supabase self-hosted COMPLETO** (~8–12 containers, incl. **Studio** e **Storage**), **não** um subconjunto mínimo — §2 Dev/CI/CD, O0.5 (painel = Studio disponível no ambiente), O0.10 e §4; **trade-off de custo na VM de 16 GB aceito** (único stack; 2º stack qa/staging segue rejeitado — constitution IX); CI no runner sobe só o Postgres dos testes, não o stack completo |
| 1.9 | 2026-06-30 | refino | ADR-006/010: **caminho de dados fixado** — a **API é o único acessor do banco**, **gerencia o próprio pool** e conecta-se **diretamente à instância Postgres** (migrations Alembic + runtime); o **Supavisor** (pooler do stack self-hosted) serve só o **ecossistema interno do Supabase** e **não está no caminho de dados da aplicação** (§4, RNF0.8) — remove a ambiguidade do endpoint Postgres no self-hosted |
| 1.10 | 2026-06-30 | refino | ADR-005 (design system revisado): **padrão-alvo = SaaS/ERP corporativo moderno para uso interno diário** (sóbrio/baixo ruído/minimalista; **vedados** marketing/conversão e gradientes "AI"); brief = **plataforma operacional multi-módulo** (revoga "Analytics Dashboard"); **marca restrita a CORES + LOGOTIPO** — **tipografia/iconografia deixam de ser vinculadas à marca** (revoga ancoragem tipográfica em `MASTER.md`/`globals.css`); **requisitos transversais de UI** (stepper de status, tabelas densas server-side, anexo/preview, auditoria) + **variação por área** (BID = funil); **navegação única + seletor de módulo** (O0.2); **v1 realiza integralmente o padrão** (+RNF0.12); §2/§4/O0.7/RF0.6/M0.6 + riscos atualizados |
| 1.11 | 2026-06-30 | refino | ADR-002: shell reflete a hierarquia **3 áreas › 7 departamentos** (Supply Chain Management › Logística/Importação/Parcerias/BID; Finanças › Compras; Planejamento › Contratos/Faturamento) — corrige a lista plana de 6 "áreas" (as divisões eram departamentos); navegação hierárquica (áreas expandindo departamentos) — §1/O0.2/§2/§4/RF0.2/M0.2 |
| 1.12 | 2026-06-30 | refino | ADR-002: rótulo pt-BR da área `finance` = **"Financeiro"** (era "Finanças") — O0.2 |
| 1.13 | 2026-07-01 | refino | **Deploy de produção reconhecido como entregável da 00** (reconcilia §1/M0.1 vs. §7): implanta na **VM interna existente** via **CD real** pull-based, **secrets de prod externalizados na VM** (nada versionado), **acesso verificado por VPN/rede interna sem ingress** — mecanismo de CD inalterado (ADR-010/R4). Ajusta O0.8 ("implantável"→"implantada"), M0.1 (gate explícito), RNF0.11, §2/§4; remove o descarte de "secrets de prod" do Fora de escopo |
| 1.14 | 2026-07-01 | refino | **ADR-011** (aplicação containerizada + compose raiz único): `api`/`web`/qualquer componente rodam **só como containers Docker, nunca no host**; **`docker-compose` da raiz** sobe/derruba o **projeto inteiro** com **um comando** em **dev e prod** (dev com hot-reload); `api`→Postgres **direto na rede do compose** (serviço `db`), Supavisor fora (ADR-006/010) — O0.10, §2/§4, +RNF0.13 |
| 1.15 | 2026-07-02 | refino | **ADR-011 (compose per-service):** o `docker-compose` da raiz é **orquestrador** — faz **`include`** dos composes de cada serviço (`apps/api/docker-compose.yml`, `apps/web/docker-compose.yml`, cada app descreve o próprio serviço) + o do stack Supabase; a raiz **não** descreve `api`/`web` inline; mantém "um comando p/ o projeto inteiro"; alternativa rejeitada = composes por app **sem** orquestrador raiz — §2/§4/O0.10/RNF0.13 |
| 1.16 | 2026-07-02 | refino | **ADR-008 (G1):** **filtro/ordenação removido da 00** — não se define aqui (catálogo de navegação estático, sem lista filtrável real); a convenção fica p/ a **1ª lista filtrável real (feature 02+)** — O0.11, RF0.8, §2/§4 |
| 1.17 | 2026-07-02 | refino | **ADR-011 (web — caminho interno das chamadas de Auth):** o `web` (Next.js) faz Auth ao Supabase de **dois contextos** — **navegador** (URL publicada no host) e **server-side** (middleware/route handlers no container, que alcançam o **gateway Kong pela rede interna do compose, por nome de serviço**); a **config externalizada do `web` distingue as duas URLs** (voltada ao navegador × interna server-side) — mesmo princípio da `api`→Postgres (ADR-006/010). §2/§4 (AuthN/Config/ADR-011), O0.10, RNF0.13 |
| 1.18 | 2026-07-09 | refino | **ADR-005 (responsividade = alvo por tela):** login atende viewports **≥375px**; a **casca autenticada** (topbar/sidebar, breadcrumb, páginas de departamento) atende **≥768px** — **abaixo de 768px na casca não é suportado na v1** (quebra aceita, não defeito). Os demais atributos do padrão — **estados, movimento, contraste, foco** — aplicam-se a **todas as telas da v1 sem exceção**. RNF0.12 (separa responsividade dos demais atributos), **+RNF0.14**, risco de padrão de v1 |
| 1.19 | 2026-07-10 | refino | **ADR-010 (handoff + reprodutibilidade + mensurabilidade do deploy):** entram como entregáveis da 00 o **provisionamento reproduzível do servidor** (infra-as-code idempotente/versionado — inclui **bootstrap/registro do runner self-hosted na VM**; runner deixa de ser pressuposto) e o **runbook `DEPLOY.md`** (distinto do quickstart de dev) — **+O0.12, +RNF0.15, +M0.9**; **deploy reproduzível via eles** (sem passos improvisados, como M0.7) e **medido em duas metades** — **(a)** mecanismo **exercitável na branch antes do PR** (implanta na VM e prova runner→stack saudável→migrações→serviço, com evidência) + **(b)** liveness **pós-merge** (smoke test + **rollback**) — **O0.8/RNF0.11/M0.1** reformulados; **CI exercitável fora de `pull_request`** (evidência pré-PR) — **O0.10/M0.5/M0.8**; deploy assume **ambiente-alvo sem conflitos** (pré-requisito genérico: portas/nomes de container livres no host-alvo); §2/§4/§7/§8 atualizados |
| 1.20 | 2026-07-10 | refino | **Naming/estrutura desacoplados da tecnologia do alvo + disciplina do runbook (ADR-010):** o framing operacional (títulos, tabelas, objetivos, requisitos, métricas) passa a descrever o alvo por **papel** — "host de produção"/"produção" — e o componente de provisionamento é nomeado por papel (**`infra/deploy`**, não `infra/vm`); a **decisão de ambiente do ADR-010 permanece** (on-prem, VM dedicada com o dimensionamento, sem ingress, egress-only, CD pull-based via runner self-hosted) — muda só **a forma de expressá-la** (agnóstica). **Runbook `DEPLOY.md`** reespecificado como **documento de foco único e autocontido** (pré-requisito concreto = portas/nomes de container livres no host-alvo; **sem** meta-informação nem escopo de desenvolvimento — esse conteúdo mora em research/plan). Reenquadra §2/§3/§4/§5/§6/§7/§8 (O0.8/O0.10/O0.12/RNF0.11/RNF0.15/M0.1/M0.9); estratégia de envs por componente inalterada |
| 1.21 | 2026-07-12 | refino | **Artefato imutável no empacotamento e no rollback (ADR-011 + ADR-010).** **Empacotamento (ADR-011):** a **CI publica as imagens de aplicação num registry**, **versionadas de forma imutável por versão do código**; a **produção PUXA a imagem pronta e NÃO constrói no host** (coerente com pull-based/egress-only); **dev × produção passam a ser explícitos** — o **compose base descreve DEV** (constrói localmente, monta a fonte, recarga automática) e uma **sobreposição de produção** o substitui pela **imagem versionada** (sem montagem de fonte, sem recarga). **Rollback (ADR-010):** deixa de **reconstruir no host** e passa a **re-implantar a versão imutável anterior a partir do registry**; o **registry é o repositório de artefatos** do fluxo de entrega e o **estado do deploy (última versão boa conhecida) é persistido no host de produção**, sendo o que o rollback consulta. Permanecem **aplicação 100% containerizada**, **um comando p/ o projeto inteiro**, o **mecanismo de entrega** (pull-based, runner self-hosted, egress-only, sem ingress) e a **rejeição do 2º stack always-on**. §2/§4 (novos bullets de empacotamento e de rollback), O0.8/O0.10, RNF0.2/RNF0.9/RNF0.11/RNF0.13 ajustados, **+RNF0.16 / +RNF0.17**, M0.1 e **+M0.10**, +risco "registry no caminho de deploy/rollback"; registry concreto, esquema de versão/tag e mecânica do rollback = **derivados no `/plan`** |
| 1.22 | 2026-07-12 | refino | **ADR-012 — confiabilidade em chamadas externas NÃO é entregue pela 00.** O requisito de **timeout/retry** (constitution IV) **não tinha casa declarada** no planejamento; fica registrado que a **00 não o entrega nem entregará** e que a **casa é a feature 02** (detentora da **única chamada a um sistema fora da fronteira de implantação** — NetCorp, visão §3/ADR-001). §2 (a âncora dos concerns cross-feature ganha **exceção declarada**) e §7 (**Fora de escopo** explicita a não-entrega e a **distingue do circuit breaker**, que segue **diferido** — adiar um **não** adia o outro). Se a chamada de **login** ao Supabase Auth (dependência de saída **dentro** da fronteira) também deve satisfazer o requisito = **ponto em aberto na visão §11**, não decidido aqui. **Nenhum objetivo/requisito/métrica da 00 é alterado** |
| 1.23 | 2026-07-13 | refino | **REVERSÃO do ADR-012** (removido da visão): com a **constitution IV reformulada** (v2.0.0), **toda chamada que sai do processo tem prazo/deadline** — invariante **de todas as features, a 00 inclusive** (que tem chamadas saindo do processo: api→Postgres, web→gateway) — e **retry só em operação idempotente**. Cai a premissa do ADR-012 (alocar um concern "órfão" a uma única feature): saem a **exceção declarada** de §2 e o item de **Fora de escopo** de §7 que negavam o concern nesta feature. **Circuit breaker segue diferido** (ADR-004), inalterado. **Nenhum objetivo/requisito/métrica da 00 é alterado** |
| 1.24 | 2026-07-13 | refino | **RF0.4 reconciliado com RNF0.12 e com o modelo Área › Departamento:** quem tem **página** é o **departamento** (a **área** é nó agrupador da navegação, **sem página própria**); na v1 o **placeholder é só de CONTEÚDO**, **renderizado como tela acabada no padrão** — **não "em branco" nem tela plana**. Elimina a contradição interna (RF0.4 "em branco" × RNF0.12 estrito); **RNF0.12 é o critério ratificado**. §1, O0.2, §4, RF0.4 e risco §8 alinhados |
| 1.25 | 2026-07-27 | refino | **ADR-010 item 10 — a definição do pipeline mora na linha principal; a ordenação da prova muda, a exigência não.** A **definição do pipeline (CI + deploy)** passa a ser **entregável versionado da 00 integrado à linha principal ANTES de ser exercitado**, por **rota própria separada do PR da aplicação**, evoluindo **por PR como qualquer código** (**+O0.13, +RNF0.18**) — fronteira de **segurança** da plataforma (disparo manual só existe para definição na linha principal; senão qualquer branch rodaria o pipeline com os **segredos do repositório** contra o host de produção). A **prova do mecanismo continua sendo gate ANTES do PR e recai sobre a aplicação**: deploy **disparado fora do fluxo de merge, a partir da definição já integrada**, **apontando para a revisão da branch** (a definição habilita; a revisão determina o que é implantado) — **o que a prova exige não muda** (O0.8/RNF0.11/M0.1(a), §2/§4). **Integrar não é exercitar:** a integração **não pode produzir deploy de produção** (sem aplicação nem versão boa anterior na linha principal), falsificado por **prova de origem** — registro de execuções logo após a integração **sem deploy de produção**, com evidência (**+M0.11**; **+risco** em §8); **afirmar a intenção do gatilho não satisfaz**. A **evidência pré-PR dos critérios de contrato e de isolamento de acesso** passa a **declarar a mesma condição habilitante** (RNF0.7, M0.5, M0.8, O0.10). §7 explicita a definição do pipeline entre os entregáveis. **Permanecem inalterados** o mecanismo de entrega (pull-based, runner self-hosted, egress-only, sem ingress), as **duas metades** e o **rollback pelo artefato imutável**; **rota concreta de integração = derivada no `/plan`** |
| 1.26 | 2026-07-27 | refino | **Três decisões do gate de conformidade sobre deploy e definição do pipeline (ADR-010 itens 5b e 10 / ADR-007).** **(1) Gates de CI no PR que integra a definição do pipeline = exceção declarada e aceita:** ali a **aplicação ainda não está na linha principal**, então os gates que **a verificam** ficam **sem objeto** e **não são executados** — sob **duas condições**: o **job sem fonte fica visivelmente NÃO-EXECUTADO, nunca reportado como aprovado** (exceção confundível com aprovação **certificaria como verificado o que ninguém verificou** — pior do que não ter gate) e, **assim que a aplicação existe na linha principal**, os gates **voltam a ser exigidos em todo PR, sem exceção** (§2, O0.10, O0.13, RNF0.18, §4, **+risco** em §8). **(2) Liveness pós-merge deixa de ser critério de pronto da 00:** a confirmação de que **a versão implantada responde**, com **reversão automática em falha**, só é observável **depois do merge da aplicação** — logo **depois do gate que precede o PR** —, sendo **insatisfazível na ordem do fluxo** e ficando **permanentemente não-medida**. O **mecanismo permanece entregável da 00** (smoke test pós-deploy + **rollback automático** para a versão imutável anterior, **sem reconstruir**); **sai apenas a exigência de tê-lo medido antes do PR**, e a **medição passa à primeira implantação real em produção, sob a feature que a realizar** (**M0.1 reduzida à metade (a)**; O0.8, RNF0.11, §2, §4, **§7** explicita a não-medição). **(3) Precisão da prova de origem:** a métrica que prova que **integrar não é exercitar** deixa de se satisfazer com "o registro **não contém deploy de produção**" — redação que admite **execução criada e interrompida internamente** — e passa a exigir que **NENHUMA execução de deploy chegue a ser CRIADA**, lida no **registro de execuções** (**ausência de execução é fato; presença interrompida é interpretação**) — **M0.11** reescrita; O0.13, RNF0.18, §2, §4 e o risco correspondente em §8 alinhados. **Permanecem inalterados** o mecanismo de entrega (pull-based, runner self-hosted, egress-only, sem ingress), o **empacotamento/artefato imutável** e o **rollback pelo registry**; **forma da não-execução visível e forma de integrar sem criar execução de deploy = derivadas no `/plan`** |
| 1.27 | 2026-07-28 | refino | **Quatro decisões: divisão do M0.10, feature da medição nomeada, fronteira do termo "componente" e desambiguação do seed.** **(1) M0.10 dividida em duas:** o **artefato imutável** permanece critério sim/não da 00 e cobre **a CI publica a imagem versionada no registry**, **a produção puxa essa imagem e não constrói no host** e **construir é estruturalmente impossível no passo de reversão** (verificável na definição do pipeline); a **EXECUÇÃO da reversão** — voltar para a versão imutável anterior, lida do **estado do deploy persistido no host**, **sem reconstruir**, com evidência — **sai do pronto da 00** e vira **métrica da feature 01** (M1.5 do PRD 01), medida na **primeira implantação real em produção**. **(2) A feature que realiza a primeira implantação real em produção é a 01** — e portanto **herda a medição da liveness pós-merge** (smoke test + reversão automática) **e a métrica nova de (1)**: as seis ocorrências de "sob a feature que a realizar" passam a **nomear a 01** (§2, O0.8, §4, RNF0.11, M0.1, §7); o **mecanismo permanece entregável da 00**. **(3) Fronteira do termo "componente" (ADR-011):** na regra de rodar **exclusivamente como container Docker, nunca direto no host**, "componente" = **serviço da aplicação em runtime** (`api`, `web` e o stack); o **ferramental de verificação** (suíte de testes, verificadores de repositório, geração do client tipado) roda no **host de desenvolvimento** e no **runner da integração contínua** — §2, O0.10, §4, RNF0.13. **(4) Seed desambiguado:** "**seed/dados de referência**" do Fora de escopo passa a significar **dados de NEGÓCIO** (seguem diferidos); o **seed idempotente do usuário de desenvolvimento** é **parte do ambiente reproduzível e entregável da 00** — O0.10, §4 (novo bullet), **+RNF0.19**, **+M0.12** (aplica em ambiente limpo sem passo manual · reexecução não duplica · usuário semeado autentica de fato). **Permanecem inalterados** o mecanismo de entrega (pull-based, runner self-hosted, egress-only, sem ingress), as **duas metades** do deploy, o **empacotamento/artefato imutável** e a **definição do pipeline na linha principal** |
| 1.28 | 2026-09-17 | refino | **Liveness pós-deploy e execução da reversão pelo artefato passam a ser propriedade da 00 e são dadas como MEDIDAS** (ADR-010 itens 5b e 9). **Base:** a "primeira implantação real em produção" que o registro 1.27 atribuiu à feature 01 é, de fato, o **próprio stack de fundação da 00** — a aplicação implantável da 00 é ela mesma —, **já implantado em produção** (reinstalação a frio em **2026-09-17**) com o **rollback automático observado disparando**. Envelhece a premissa de que a medição só seria observável depois que uma aplicação de negócio mergeasse. **M0.1** passa a dar a **liveness pós-deploy** como medida sob a 00 (além da metade (a), mecanismo pré-PR); **M0.10** passa a dar a **EXECUÇÃO da reversão** como medida sob a 00 (deixa de ir para M1.5 do PRD 01); **O0.8/RNF0.11/§2/§4** ajustados (metade (b) entregue **e** medida por esta feature); **§7** deixa de diferir essas medições à feature 01 (nenhuma sai de escopo). **Remissão a 1.26/1.27** (histórico): onde aqueles registros transferiam a medição à 01, prevalece esta entrada. **Permanecem inalterados** o mecanismo de entrega (pull-based, runner self-hosted, egress-only, sem ingress), as **duas metades** do deploy, o **empacotamento/artefato imutável**, a **definição do pipeline na linha principal** e o **rollback pelo registry** |
| 1.30 | 2026-09-21 | refino | Migração SDD **Spec Kit → AgentSpec** (ciclo Brainstorm→Define→Design→Build→Ship): as remissões de detalhe deixado à fase de arquitetura (registry/tag e sobreposição, mecânica do rollback, forma de integração da definição do pipeline e da não-execução visível — §4/RNF0.15/RNF0.16/RNF0.17) passam a nomear o **Design** (eram `/plan`) |
| 1.31 | 2026-09-25 | refino | **Constitution II (v2.0.0):** a remissão do **RNF0.5** deixa de dizer que a constituição exige alvo explícito (para cada componente) e passa a refletir a redação vigente — **sem custo oculto** e, **onde o uso justifica**, alvo explícito para o **caminho crítico**, **derivado de decisão registrada**. O alvo de login/carga inicial **segue a definir** e a **[hipótese]** permanece marcada como tal; **nenhum objetivo/requisito/métrica da 00 muda de conteúdo** |
| 1.29 | 2026-09-17 | refino | **Correção do ESTADO DA MEDIÇÃO da reversão (ADR-010 item 9), após o gate de conformidade re-derivar a evidência ao vivo — a PROPRIEDADE da 00 permanece.** A **liveness pós-deploy (M0.1(b))** **continua MEDIDA sob a 00** (deploys de produção `35136474611`/`35223484216`/`35227709700` com passo de saúde + smoke test passando). A **execução da reversão pelo artefato (M0.10)** é **rebaixada de "dada como MEDIDA" para NÃO-MEDIDA / em aberto sob a própria 00**: o mecanismo é entregue pela 00 e **dispara em falha**, mas nos deploys que passaram o rollback ficou **skipped** e no único em que disparou (`35218615973`) **falhou por resíduo de host, não por defeito do mecanismo** — **uma reversão íntegra e saudável nunca foi capturada**; a medição fica **pendente de um exercício real bem-sucedido**. Redação separada: "o mecanismo dispara em falha" (entregue) ≠ "a reversão foi medida com sucesso" (ainda não). Ajustados **M0.1, M0.10, O0.8, RNF0.11, §2, §4, §7**; **liveness (M0.1(b)) intocada**; a propriedade **não** volta à feature 01. **Remissão a 1.28** (histórico): onde aquele registro dava a execução da reversão como MEDIDA, prevalece esta entrada |
| 1.32 | 2026-09-28 | refino | **Organização em épicos:** cabeçalho passa a nomear o **Épico E0 (Fundação)** no lugar da fase (as fases do roadmap deixam de existir). Remissões à feature 02 (desmembrada) apontam o recorte: alvo NetCorp por config → **02a** (O0.4); jobs de sync NetCorp → **02a/02b** (§4). **Nenhum objetivo/requisito/métrica da 00 muda de conteúdo** |
| 1.33 | 2026-10-13 | refino | **Correções de fato, sem mudar requisito, regra nem restrição.** **(1) Marca:** os ativos de marca ficam em `docs/references/brand-identity/` e o guia da marca em PDF **não é versionado**; os valores concretos de paleta e uso de logo estão fixados em `apps/web/design-system/MASTER.md` (§2, O0.7, §4, RF0.6, risco de cores/logo em §8). **(2) `.specify/`** deixa de constar entre os diretórios da raiz — não existe mais (§2, §4); registros datados do Changelog ficam como estão. **(3) Execução da reversão pelo artefato MEDIDA sob a 00**, com a execução capturada em **2026-09-21** (run **35559037188**; a issue #101 segue fechada) (§2, O0.8, §4, RNF0.11, M0.1, M0.10, §7). **Remissão a 1.29** (histórico): onde aquele registro dava a execução da reversão como não-medida, prevalece esta entrada. **(4) Convenção de filtro** propagada da visão: a 1ª lista filtrável real é a lista de usuários da **06d** (um parâmetro de situação; omitido = todos); a ordenação fica para a 1ª lista ordenável real (§2, O0.11, §4, RF0.8). **Nenhum objetivo/requisito/métrica da 00 muda de conteúdo**; muda só o estado de medição da M0.10 |