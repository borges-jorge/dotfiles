# itallus — Visão geral do sistema (épicos, features e grafo de dependência)

> Documento de **visão do sistema** produzido no brainstorm de planejamento.
> Serve como **âncora de coerência cross-feature** junto com a `constitution`
> (`docs/constitution/principios.md`), conforme o [roteiro SDD](roteiro-sdd.md).
> Insumos: [`docs/requisitos.md`](requisitos.md) + princípios de qualidade + **identidade
> visual da marca** ([`docs/brand-identity/`](references/brand-identity/) — guia da marca + ícones,
> referência do design system; ver ADR-005).
>
> **Convenção:** inferências do planejador são marcadas com **[hipótese]**; onde o
> requisito diz "a definir", o texto mantém **a definir** (não inventa valor).

---

## 1. Overview

- **Propósito:** sistema interno da diretoria de planejamento para **automatizar e
  sistematizar** seus processos, num **único sistema** multi-área. Majoritariamente
  **pós-venda** — gestão do **contrato** do início ao fim depois da venda; exceção: o
  **BID** (pré-venda).
- **Escopo (hierarquia Área › Departamento — ADR-002):** **3 áreas** contendo **7
  departamentos** — **Supply Chain Management** (`supply-chain-management`) › Logística,
  Importação, Parcerias, BID; **Financeiro** (`finance`) › Compras; **Planejamento**
  (`planning`) › Contratos, Faturamento. Foco inicial: o departamento **Contratos**
  (`contracts`, área Planejamento), atendido pelo épico **E3 Gestão de Contratos** (§7).
- **Abordagem:** **incremental** — começar pelos processos mais críticos/maduros; o
  planejamento se organiza em **épicos** (iniciativa com objetivo e critério de pronto) que
  agrupam **features** (1 PRD = 1 ciclo de implementação), e a ordem de implementação vem do
  **grafo de dependência** entre features (§6). **Épico não é departamento:** o departamento
  atendido fica registrado nesta visão (§6/§7); departamentos **sem escopo concreto** ficam
  registrados **sem épico** (§7).
- **Restrições (do requisito):**
  - **On-premises**, **VM dedicada**; acesso **interno (rede direta ou VPN)**, **sem
    entrada externa (ingress)**, porém **com saída para a internet (egress)**.
  - **Backend Python**; **Supabase self-hosted** (auth, banco, logs, backup);
    **PostgreSQL**; **frontend React + Tailwind + shadcn**.
  - **Clean Code / SOLID / design patterns / padrões ISO** (ver constitution).
  - **Plugabilidade:** componentes **em geral** substituíveis com baixo esforço
    (auth, banco e outros) — **complexidade a avaliar**.
  - **LGPD desde a v1**.

---

## 2. Visão lógica — modelo de domínio (entidades compartilhadas)

> Definição **canônica** das entidades compartilhadas (evita drift de modelo entre
> features — mitigação cross-feature do roteiro SDD). Cardinalidades sem fonte
> explícita no requisito vêm marcadas **[hipótese]**.

```text
Usuário (Supabase Auth = só AUTENTICAÇÃO) ──< department_access >── Departamento ──> Área
   │  AUTORIZAÇÃO = domínio itallus (department_access + papel, lidos na RLS — ADR-002/009)
   │  papéis cumulativos: usuário ⊂ manager ⊂ admin ⊂ superadmin  (hierarquia Área › Departamento)
   │  (link opcional, editável só na gestão de usuário; desativar o usuário preserva o colaborador)
   ▼
Colaborador ──< HistDepartamento >── Departamento ──FK──> CR interno (1000XX, sem 50/60/70)
   │        └─< HistSkill >── Skill ──< HistSPC(valor/hora) >── (SPC)   │
   │                                                                    ▼
   │   Centro de Resultado (CR) ── fonte NetCorp `tbcencus`, 6 dígitos numéricos
   │     ├─ CR interno (1000XX sem sufixo) ──────────► Departamento
   │     ├─ CR de suporte à pré-venda (1000XX 50/60/70; 1 por time comercial)
   │     └─ CR de projeto ──1:1── BR/Projeto (assoc. vem da fonte) ── tem PCR
   │
   └──< Alocação (colaborador×BR, 12 meses, dias) >── BR/Projeto
                                                        │
Cliente (CNPJ) ──> Grupo de Cliente (CNPJ principal)    │
                          ▲                              │
Contrato Jurídico ──FK(Grupo = CNPJ principal)──┘       │
   └──1:N── Contrato Operacional ──1:N── BR/Projeto ──1:1── PCR
                                                        │
Oportunidade (BID, pré-venda; trata a PROPOSTA COMERCIAL; 1 BR atribuído)
   └─ handoff: muda status + registro local; e-mail (mailto); SEM escrita no NetCorp
   Projeto (pós-venda) ── importado do NetCorp ─────────┘
Parcerias: Rebate · Renovação de licenças   |   Faturamento: PO · BOQ
```

**Entidades e regras-chave (do requisito):**

| Entidade | Pontos essenciais |
|----------|-------------------|
| **Usuário** | Identidade no **Supabase Auth** (**só autenticação** — mecanismo entregue pela 00); a **autorização** é domínio do itallus (`department_access` + papel/**permissão**, lidos na RLS — ADR-002/006/009). Pode existir sem ser colaborador. **Baseline de login/sessão/guarda de rota na UI = feature 00** (já implantado); **ciclo de vida voltado ao produto = feature 01** (criar/convidar, convite/reset + **mecanismo de anonimização do usuário, sem interface**), que **consome** esse baseline — ADR-009 item 1a; **desativação/reativação, correção de nome/e-mail e apagamento dos dados pessoais do usuário = feature 06d** (épico E1), que aciona a anonimização entregue pela 01 — ADR-009 item 7; **não há exclusão de usuário**. **Criado/convidado pelo Admin** na tela admin (sem self-signup; backend→**Auth Admin API** server-side; convite/reset pelo **mesmo link de uso único** — token do backend, uso único, expiração curta — **exibido na tela admin, sem e-mail**, com o usuário definindo a própria senha — ADR-009). **Acesso por departamento** a nível de usuário (1+ departamentos); **papéis cumulativos** **usuário ⊂ manager ⊂ admin ⊂ superadmin**. **Enforcement por permissão** (papel = bundle) com **interseção escopo∧capacidade** — ADR-002. |
| **Permissão / Papel** | `permission` = **catálogo genérico** de capacidades (qualquer ação/domínio), **semeado por migração**, desacoplado do catálogo de departamentos. **Papel = unidade de concessão** = bundle de permissões (`role_permission`); v1 = bundle default grosso por papel. Ponto de decisão (guard/RLS) opera sobre **permissão**; autoridade efetiva = **permissão ∧ escopo**, deny-by-default. `approve` semeada/escopada, **sem fluxo**. Concessão fina por usuário e ABAC = ganchos futuros — ADR-002. |
| **Área / Departamento (catálogo)** | **3 áreas + 7 departamentos semeados por migração**; mudam **só via desenvolvimento** — **sem CRUD de usuário**. A **associação** departamento↔usuário (`department_access`) é editável na gestão de acessos — ADR-002. |
| **Colaborador** | Tabela **nativa** (preenchimento manual), só **internos** por ora — cadastro e histórico de departamento = **feature 06a**. **Link opcional** a Usuário; desativar o usuário **preserva** o colaborador (garantia da **feature 06c**). Vínculo **editável somente na tela admin de gestão de usuário** (opção entregue pela feature 06c como melhoria dessa tela); na edição de colaborador, **somente leitura** — ADR-009. |
| **Centro de Resultado (CR)** | **Dado-mestre** importado do NetCorp (tabela **`tbcencus`** — centro de custo; **tudo é CR**), via cache local (feature **02b**, ADR-001). Identificador **sempre numérico, 6 dígitos**. **Classificação** (derivada do próprio padrão numérico que já vem da fonte): `1000XX` **sem** 50/60/70 = **CR interno** (identifica Departamento); `1000XX` em **50/60/70** = **CR de suporte à pré-venda** (1 por time comercial, times **a definir**); demais = **CR de projeto**. **Só CR de projeto tem PCR.** A associação **CR de projeto ⇄ BR** **vem pronta da fonte** — o itallus **não** calcula/deriva (sem fórmula). |
| **Departamento** | Vincula-se (**FK**) a um **CR interno** (`1000XX` sem 50/60/70) do catálogo da feature 02b — **deriva do NetCorp**, não é nativo puro. Pertence a uma **Área** (hierarquia Área › Departamento). **Modelo concreto — 3 áreas / 7 departamentos:** **Supply Chain Management** (`supply-chain-management`) › `logistics`, `imports`, `partnerships`, `bid`; **Financeiro** (`finance`) › `procurement`; **Planejamento** (`planning`) › `contracts`, `invoicing`. `procurement` e `contracts` são **novos** no catálogo. Colaborador pode **migrar** (muda também a skill — migração = feature 06b). **Histórico obrigatório**. |
| **Skill** | Classificação que agrupa habilidades num **padrão de preço**. Identificada por **código** (**formato a definir**). **Histórico obrigatório** por colaborador. |
| **SPC** (Standard Price Cost) | Mapeia **skill → valor/hora**. Atualizado **~2×/ano**. Vale p/ custo **interno e externo**. **Histórico obrigatório** dos valores. |
| **Cliente / Grupo** | Cliente = **CNPJ**; agrupados por **CNPJ principal**. Vem do **NetCorp** (CNPJ, nome, grupo). |
| **Contrato Jurídico** | Guarda-chuva. **FK ao Grupo** (CNPJ principal do cliente — não ao CNPJ individual). **Código interno** (gerado) + **externo** (do cliente; ausente ⇒ externo = interno). Campos **não exaustivos**, **a definir**. |
| **Contrato Operacional** | 1+ por jurídico; gera **entregas/demandas**; mesma regra de código; datas/valor/descrições próprias. |
| **BR / Projeto** | 1+ por operacional. **BR = projeto = CR de projeto**, **importado do NetCorp** pós-venda (oportunidade vendida); a associação **CR de projeto ⇄ BR vem pronta da fonte** (`tbcencus`). Pode herdar o BR da oportunidade, receber BR derivado (A.1, A.2…) ou novo — o itallus **NÃO modela/rastreia essa linhagem**. Tem **PCR**. |
| **PCR** | **Aplica-se só a CR de projeto** (CR interno e de suporte à pré-venda **não têm PCR**). 4 infos principais: **invoice**, **revenue** (≈ invoice), **% 1ª margem**, **% 2ª margem** + outras (**a definir**). |
| **Alocação de esforço** | Planilha mensal de Operações: linha **colaborador×BR**, **12 colunas de mês**, célula = **dias**. Cobre **mês + 3** (4 meses forecast). Férias/licença/treinamento → **centro de custo interno**. |
| **Fechamento mensal** | Coluna do mês → skill do colaborador → **dias→horas × SPC** → **custo R$** efetivo. |
| **Oportunidade (BID)** | Pré-venda. **≠ Projeto.** No itallus, a princípio só a **proposta comercial** da oportunidade; **1 BR atribuído**. Armazena **documentos** (WBS, PCR, PT) para **download** no itallus. **Handoff:** o itallus **NÃO escreve no NetCorp** — apenas muda o **status** para "handoff realizado", **registra localmente** o acionamento (quando/por quem) e gera **e-mail `mailto:`** pré-preenchido; uma **área externa** cadastra no NetCorp; depois o itallus **puxa os Projetos** do NetCorp. Fluxo BID completo: **a definir**. |
| **Parcerias** | **Rebate** (% do fornecedor sobre vendas; direto ou via distribuidor, % diferentes) + **renovação de licenças/software**. |
| **Faturamento** | **PO** (grupo de equip./serviços/materiais) + **BOQ** (lista de material). Processo **pouco claro**. |

---

## 3. Visão de componentes (containers)

```text
┌──────────────────────────────────────────────────────────────────────┐
│  VM dedicada (on-prem; acesso interno rede/VPN; sem ingress; COM egress)│
│                                                                       │
│  ┌───────────────┐   HTTPS    ┌────────────────────┐                  │
│  │  Frontend     │ ─────────► │  Backend Python    │ FastAPI+SQLModel  │
│  │  React +      │            │  (Clean Arch /     │                  │
│  │  Tailwind +   │            │   SOLID; ports &   │                  │
│  │  shadcn       │ ◄───────── │   adapters)        │                  │
│  │  Next.js (SSR)│            └─────────┬──────────┘                  │
│  │               │                      │ adapters (plugáveis)        │
│  └───────────────┘            ┌─────────┼───────────────┐             │
│                               ▼         ▼               ▼             │
│                       ┌────────────┐ ┌──────────┐ ┌──────────────┐    │
│                       │ Supabase   │ │ Postgres │ │ Conector     │    │
│                       │ (Auth/logs/│ │ (via     │ │ NetCorp      │    │
│                       │  backup)   │ │ Supabase)│ │ (MS SQL,     │    │
│                       └────────────┘ └──────────┘ │ read-only)   │    │
│                                                    └──────┬───────┘    │
└───────────────────────────────────────────────────────────┼──────────┘
                                                             ▼ (só leitura)
                                              NetCorp (MS SQL Server, legado)
```

- **Organização do código (monorepo — ADR-004):** um **único repositório** com
  **`apps/api`** (backend FastAPI + uv, Clean Architecture / Ports & Adapters) e
  **`apps/web`** (frontend Next.js + Tailwind + shadcn). Coerente com a governança já
  existente (hooks `.githooks`, fluxo `feature/* → qa → master`, branch protection,
  deploy em host único). `docs/`, `.specify/`, `.github/`, `.githooks/` e a skill de design
  (`.claude/skills/ui-ux-pro-max/`) permanecem na raiz. Detalhe interno por feature fica
  para o **Design** do AgentSpec (ver §9 ADR-004).
- **Observabilidade (concern §8):** **logging estruturado com structlog desde a v1**
  (sem PII/segredo — constitution V/VI); **métricas/tracing com OpenTelemetry** ficam
  **posteriores**. Logging/métricas/config são **transversais** (facade nas bordas, não
  ports & adapters — ver §9 ADR-004).
- **Plugabilidade (ports & adapters):** auth, banco e **conector NetCorp** ficam atrás
  de **interfaces (portas)** no domínio; implementações concretas (Supabase Auth,
  Postgres, MS SQL) são **adapters** trocáveis. O **catálogo de ports/adapters** (critério
  e itens que são / não são port) está fixado no **ADR-004** (§9). **[hipótese]** A
  complexidade de generalizar **todos** os componentes deve ser **avaliada feature a
  feature** — o requisito pede explicitamente "avaliar a complexidade".
- **Empacotamento — aplicação containerizada (ADR-011):** `api` (FastAPI), `web` (Next.js) e
  qualquer **serviço da aplicação em runtime** rodam **exclusivamente como containers Docker, nunca
  direto no host** — o **ferramental de verificação** roda no **host de dev** e no **runner da CI**
  (fronteira definida no ADR-011 item 1). Um
  **`docker-compose` na raiz** orquestra o **projeto inteiro** via **`include`** dos composes de cada
  serviço (`apps/api/docker-compose.yml`, `apps/web/docker-compose.yml`) + o compose do stack Supabase
  completo — a raiz **não** descreve `api`/`web` inline; o `up` na raiz sobe/derruba tudo com **um
  comando**. **Dev × produção são explícitos no empacotamento:** o **compose base descreve DEV**
  (constrói localmente, **monta a fonte**, **recarga automática**) e uma **sobreposição de produção**
  substitui isso pela **imagem versionada**, **sem montagem de fonte e sem recarga**. A **CI publica
  as imagens de aplicação num registry de imagens**, versionadas de forma **imutável por versão do
  código**; a **produção PUXA a imagem já construída — não constrói nada no host** (coerente com a
  postura **pull-based / egress-only** — ADR-010). A
  `api` conecta ao Postgres **direto na rede do compose** (serviço `db`), fora do Supavisor
  (ADR-006/010). O `web` (Next.js) faz chamadas de Auth ao Supabase de **dois contextos** —
  **navegador** e **server-side** (middleware/handlers no container): o **server-side** alcança o
  **gateway (Kong) pela rede interna do compose (nome de serviço)** e o **navegador** a **URL
  publicada no host**, então a config externalizada do `web` **distingue as duas URLs** (ADR-011).
- **Stack Supabase (ADR-010):** dev (docker-compose) e prod (host de produção) rodam o **stack Supabase
  self-hosted COMPLETO** (~8–12 containers: Postgres, Auth/GoTrue, Studio, Kong, PostgREST,
  postgres-meta, Realtime, Storage + imgproxy, Edge Functions, Analytics/Logflare + Vector) —
  **não** um subconjunto mínimo; o **Studio** serve de painel de observabilidade (§8/ADR-009) e
  o **Storage** já fica pronto para features futuras (ADR-004; feature 10). Trade-off de custo
  na VM de 16 GB aceito conscientemente (constitution IX — ver ADR-010). **Caminho de dados:**
  no stack, o Postgres fica atrás do pooler **Supavisor**, que serve o **ecossistema interno do
  Supabase**; a **aplicação não passa por ele** — a **API acessa diretamente a instância Postgres**,
  com **pool próprio** (migrations e runtime — ADR-006/010).
- **Integração NetCorp:** **read-only PURO**, via **anti-corruption layer** — itallus
  **nunca** escreve no NetCorp (inclusive no handoff do BID: lá só muda status local +
  e-mail `mailto:`, sem escrita). A integração usa **cache/replicação local**: um **job
  periódico** lê do NetCorp e **espelha em tabelas locais (PostgreSQL)**; todo o restante
  do itallus lê do **espelho local**, **nunca** consultando o NetCorp em runtime. Vale
  para Clientes/Grupos e para os **Projetos** puxados pós-venda. **Frequência e
  reconciliação a definir.** **Evolução possível:** promover uma entidade específica
  (candidata: PCR/valores sensíveis no fechamento) a consulta ao vivo (híbrido) no futuro.

---

## 4. Visão de deploy

| Item | Decisão | Origem |
|------|---------|--------|
| Hospedagem | On-prem, **VM dedicada** (4 núcleos 2,2 GHz · 16 GB · 100 GB) — **hospeda APENAS produção**: o **stack Supabase self-hosted COMPLETO** (~8–12 containers) **+ apps** (único stack; 2º stack qa/staging permanece rejeitado — trade-off de custo aceito, constitution IX) | Requisito + ADR-010 |
| Rede | Acesso **interno (rede direta ou VPN)**; **sem entrada externa (ingress)**; **com saída para internet (egress)** | Requisito |
| Ambientes | **dev (local, docker-compose) + prod (host único)** — **ambos com o stack Supabase COMPLETO** (não subconjunto mínimo) e **config externalizada** (constitution VII); **sem staging/qa de runtime** — a branch `qa` é **gate de código**, não servidor | ADR-010 |
| Definição do pipeline (CI + deploy) | **Entregável versionado da feature 00 que ENTRA NA LINHA PRINCIPAL ANTES de ser exercitado**, por **rota própria, separada do PR da aplicação** — pipeline é **código na linha principal**, que evolui **por PR como qualquer outro**; definição que vive **só numa branch** é **rascunho, não pipeline**. **Quem aguarda o PR da feature é a aplicação, não o pipeline.** É **fronteira de segurança**: o **disparo manual** só existe para definição **já na linha principal** (senão qualquer branch executaria o pipeline com os **segredos do repositório**, contra o host de produção). **Integrar não é exercitar:** a integração **não pode produzir deploy de produção** (a linha principal ainda não tem aplicação nem versão boa anterior) — falsificado por **prova de origem**: **nenhuma execução de deploy chega a ser criada**, isto é, o **registro de execuções logo após a integração não exibe execução de deploy alguma**, com evidência (**ausência de execução é fato; execução criada e interrompida é interpretação**). **Gates de integração contínua nesse PR:** os gates que verificam a **aplicação** ficam **sem objeto** (ela ainda não está na linha principal) e **não são executados** — **exceção declarada e aceita**, sob **duas condições**: o **job sem fonte fica visivelmente não-executado, nunca reportado como aprovado**, e **a partir do momento em que a aplicação existe na linha principal os gates voltam a ser exigidos em todo PR, sem exceção** | ADR-010 |
| CI (pipeline, não ambiente) | **GitHub Actions (nuvem)**, efêmero no runner: lint/test/build + **gate de drift** do contrato + **RLS via testcontainers**; **exercitável sobre a revisão da branch antes do PR** (disparo **fora de `pull_request`**), **a partir da definição de CI já integrada à linha principal** — dá evidência ao vivo dos critérios de contrato/RLS **antes** de abrir o PR. **Também PUBLICA as imagens de aplicação no registry**, versionadas de forma **imutável por versão do código** (é o artefato que a produção puxa) | ADR-007/010/011 |
| Empacotamento | **Aplicação 100% containerizada** — `api`, `web` e qualquer **serviço da aplicação em runtime** rodam **só como containers Docker, nunca no host** (o **ferramental de verificação** — suíte de testes, verificadores de repositório, geração do client tipado — roda no **host de dev** e no **runner da CI**, ADR-011 item 1); **`docker-compose` da raiz orquestra via `include`** os composes de cada serviço (`apps/api/docker-compose.yml`, `apps/web/docker-compose.yml`) + o do stack Supabase (raiz **não** inline) e sobe/derruba o **projeto inteiro** com **um comando**. **Dev × produção explícitos:** o **compose base = DEV** (constrói localmente, monta a fonte, recarga automática); a **sobreposição de produção** substitui pela **imagem versionada** (**sem montagem de fonte, sem recarga**) — **produção não constrói no host**; `api`→Postgres **direto na rede do compose** (serviço `db`); o `web` faz Auth ao Supabase de **dois contextos** — **server-side** pela **rede interna do compose** (gateway Kong), **navegador** pela **URL publicada** (config do web distingue as duas URLs) | ADR-011 |
| Registry de imagens (repositório de artefatos) | A **CI publica** as imagens de aplicação num **registry**, **versionadas de forma imutável por versão do código**. É o **repositório de artefatos do fluxo de entrega**: a **imagem validada na CI é exatamente a que sobe em produção**, e é o **artefato para onde o rollback reverte**. **Produto/instância concretos = derivados no Design** | ADR-010/011 |
| CD | **pull-based**: o **host de produção puxa** da `master` (coerente com egress/sem-ingress); GitHub **não** empurra; **mecanismo = runner self-hosted do GitHub Actions no host de produção** (event-driven, egress-only, dispara no merge à `master`); polling caseiro = alternativa rejeitada. **Produção PUXA a imagem versionada do registry — não constrói no host.** **O deploy de produção é entregável da feature 00**, feito **de forma reproduzível via o provisionamento + runbook** (sem passos improvisados; secrets de prod externalizados no host de produção; acesso por VPN/rede interna sem ingress) e **medido no momento próprio**: o **critério de pronto da 00 é a metade (a) — mecanismo, ANTES do PR, sobre a aplicação** — disparo **fora do fluxo de merge**, **a partir da definição já integrada à linha principal**, **apontando para a revisão da branch da feature** (a definição habilita; a revisão determina o que é implantado): implanta no host de produção e prova runner→imagem daquela versão puxada do registry (host não constrói)→stack saudável→migrações→serviço, com evidência. A **metade (b) — liveness pós-deploy** (**smoke test pós-deploy**: saúde + probe, com **rollback automático** em falha) é **entregável da 00 como MECANISMO E MEDIDA pela 00**: a **aplicação implantável da 00 é o próprio stack de fundação**, **já implantado em produção** (reinstalação a frio em 2026-09-17) com o **rollback automático observado disparando** — logo a **liveness pós-deploy** é **dada como MEDIDA** sob a 00, enquanto a **execução da reversão pelo artefato** (linha Rollback) é **entregue como mecanismo mas NÃO-MEDIDA / em aberto sob a 00** (issue #101); nenhuma transferida à feature 01 | ADR-010/011 |
| Rollback | **Re-implanta a versão IMUTÁVEL ANTERIOR a partir do registry — NÃO reconstrói.** O **estado do deploy** (qual é a **última versão boa conhecida**) é **persistido no host de produção** e é o que o rollback consulta. Reconstruir durante um rollback é lento e pode falhar por causas novas (dependência indisponível, imagem-base alterada, rede) justamente com a produção quebrada. **Medição:** a **impossibilidade estrutural de construir no passo de reversão** é **medida sob a 00** (prova negativa, unit — SC-013); a **EXECUÇÃO da reversão** é **item operacional aberto, NÃO-MEDIDA / em aberto sob a 00** (issue #101) — o rollback foi observado disparando na reinstalação a frio de 2026-09-17, mas nenhuma reversão íntegra e saudável foi capturada; a aplicação implantável da 00 é o próprio stack de fundação, já implantado | ADR-010/011 |
| Provisionamento / runbook (handoff) | **Entregáveis da feature 00** (hoje ausentes): **provisionamento reproduzível do servidor** como **infra-as-code**, **nomeado por papel** (`infra/deploy`) — não pela tecnologia do alvo —, cobrindo **bootstrap/registro do runner self-hosted no host de produção** + demais configs de host, **idempotente e versionado** (o runner deixa de ser pressuposto e passa a ser criável pelos meios entregues); e **runbook de deploy de produção (`DEPLOY.md`)** — **documento de foco único e autocontido** que reúne tudo o que o operador precisa para subir o ambiente do zero (obter código → bootstrap → config/segredos externalizados no host → subir o stack + aplicar migrações → verificação de saúde), com **pré-requisito concreto** (portas e nomes de container livres no host-alvo) | ADR-010 |
| Backup / DR | **Posterior** (não exigido na v1) | Requisito §4 |

---

## 5. Decisões de tecnologia

| Área | Escolha | Racional / status |
|------|---------|-------------------|
| Backend | **Python** | Requisito |
| Banco | **PostgreSQL** (Supabase self-hosted) | Requisito |
| Auth | **Supabase Auth** (self-hosted), atrás de porta/adapter | Requisito + plugabilidade |
| Frontend | **React + Tailwind + shadcn** | Requisito |
| Framework JS | **Next.js** (sobre React + Tailwind + shadcn) | Escolhido visando **possível migração futura para a nuvem** (ecossistema de hospedagem SSR maduro) |
| Framework backend | **FastAPI** + **SQLModel** (Pydantic + SQLAlchemy) | Casa com ports & adapters e com a ACL; tipado/assíncrono |
| Migração de schema | **Alembic** (`target_metadata = SQLModel.metadata`, autogenerate) | SQLModel não migra; schema **e RLS** versionados juntos por feature; ver ADR-006 |
| Sincronização NetCorp | **Cache/replicação local** (job periódico → espelho PostgreSQL) | read-only; runtime lê o espelho; frequência **a definir**; ver ADR-001 |
| Controle de acesso | **RLS no Postgres** + tabela de permissões **por departamento** (padrão KB Supabase) | Defesa em profundidade; ver ADR-002 |
| Identidade → RLS | Conexão de runtime com **role não-privilegiado** (`itallus_app`, nunca `service_role`) + **propagação dos claims do JWT por transação** via `set_config('request.jwt.claims', …, true)` | RLS realmente aplica; trilho fixado na 00; policies concretas por tabela = feature 01. **A 01 reaproveita o trilho da 00 sem alterá-lo** (a API segue propagando o JSON completo dos claims; sem canal novo dedicado ao `user_id`); a policy lê **só o `sub`** desse JSON (`current_setting('request.jwt.claims', true)::jsonb ->> 'sub'`) e decide o escopo por `EXISTS`/`JOIN` em `department_access`/`role_permission` para todos os papéis (escopo global = permissão explícita em `role_permission`); ver ADR-002/006 |
| Representação de valores | **`Decimal` (Python) / `NUMERIC` (Postgres) / string (JSON)** — **nunca `float`** | Núcleo de valor (R$) sem erro de arredondamento; ver ADR-006 |
| Históricos | **SCD Tipo 2** (linha por versão, `is_current` + vigência) | Padrão KB data-modeling; ver ADR-003 |
| Arquitetura | **Clean Architecture / SOLID / ports-adapters** | Requisito + constitution |
| Estrutura do repo | **Monorepo** (`apps/api` + `apps/web`); diretriz de esqueleto + convenções | Coerente com a governança (hooks/branch/deploy único); ver ADR-004 |
| Contrato front↔back | **OpenAPI gerado pelo FastAPI** (fonte da verdade) → **client TS tipado via orval** (gera client + hooks **TanStack Query**; `apps/web/lib/api/`) | Drift pego em compile-time/CI; ver ADR-005 |
| Data-fetching (web) | **TanStack Query** (convenção; hooks gerados pelo orval por endpoint) | Padronização do acesso à API num app CRUD-pesado; ver ADR-005 |
| Design system / UI | **ui-ux-pro-max** (skill offline/versionada em `.claude/skills/`) → `apps/web/design-system/` **MASTER.md + pages/\*.md**, no **padrão SaaS/ERP corporativo moderno** (sóbrio/baixo ruído/minimalista; sem marketing nem gradientes "AI"); **marca restrita a cores + logotipo** (`docs/brand-identity/`) — **tipografia/iconografia NÃO vinculadas à marca** | Único "cérebro" de design (Master + Overrides); shadcn/Tailwind; brief = plataforma operacional multi-módulo (não "Analytics Dashboard"); requisitos transversais de UI (stepper de status, tabelas densas server-side, anexo/preview, auditoria) + variação por área (BID = funil); ver ADR-005 e §11 |
| Tema (UI) | **Tema claro (light) na v1; dark mode diferido** (não-v1) | Reduz escopo da 00 (constitution IX); o design system **reserva os tokens** para não retrabalhar; ver ADR-005 e §11 |
| Observabilidade — logging | **structlog** (estruturado, **desde a v1**, sem PII/segredo) | Transversal/facade nas bordas (não port); constitution V/VI |
| Observabilidade — métricas/tracing | **OpenTelemetry** — **posterior** (não-v1) | Entra quando a maturidade exigir |
| Empacotamento / containers | **Aplicação 100% containerizada** (`api`, `web`, qualquer **serviço da aplicação em runtime** = **só containers Docker, nunca no host**; **ferramental de verificação** no **host de dev / runner da CI**); **`docker-compose` da raiz orquestra via `include`** os composes por serviço (`apps/api/docker-compose.yml`, `apps/web/docker-compose.yml`) + o do stack Supabase (raiz não inline) e sobe/derruba o **projeto inteiro** com **um comando**; **compose base = DEV** (constrói localmente, monta a fonte, recarga automática) + **sobreposição de produção** = **imagem versionada** (sem montagem de fonte, sem recarga); `api`→Postgres direto na rede do compose (serviço `db`); **web**: Auth **server-side** pela **rede interna do compose** (gateway), **navegador** pela **URL publicada** (duas URLs na config) | Um comando p/ o projeto todo; **produção não constrói no host** — roda o artefato validado na CI; ver ADR-011 |
| Registry de imagens / artefatos | **Registry de imagens** — a **CI publica** as imagens de aplicação, **versionadas de forma imutável por versão do código**; a **produção puxa** a imagem pronta (não constrói). **Produto/instância concretos = derivados no Design** | **Repositório de artefatos** do fluxo de entrega: a imagem validada na CI **é** a que sobe em produção, e é o **alvo do rollback**; ver ADR-010/011 |
| Rollback de produção | **Re-implantação da versão imutável anterior** a partir do registry — **sem reconstruir**; **estado do deploy** (última versão boa conhecida) **persistido no host de produção** | Prática consolidada: reverter para artefato **já construído e testado**; reconstruir sob incidente é lento e pode falhar por causas novas; ver ADR-010 |
| Ambiente local (dev) | **docker-compose** com o **stack Supabase self-hosted COMPLETO** (~8–12 containers, incl. Studio e Storage), config externalizada | Paridade **dev↔prod** de **stack/topologia** (o **empacotamento dos apps** distingue dev × produção — ADR-011); Studio/Storage prontos sem subir serviço depois; ver ADR-007/010 |
| NetCorp por ambiente | **3 alvos atrás do MESMO port ACL**, por **config externalizada** (VII): **stub/fake** (test double — CI + default dev) · **NetCorp de teste** (réplica de prod, rede interna, ~1×/semana — validação real em dev) · **NetCorp de produção** (read-only, só prod) | ADR-010 (ver ADR-001/004) |
| Definição do pipeline (CI + deploy) | **Entregável versionado da 00**, **integrado à linha principal ANTES de ser exercitado**, por **rota própria** (separada do PR da aplicação) e **evoluindo por PR** como qualquer código; **integrar não é exercitar** — **nenhuma execução de deploy chega a ser criada** na integração; **gates de CI sem objeto nesse PR** = **exceção declarada** (job **visivelmente não-executado**, nunca "aprovado"; **gates voltam a ser exigidos em todo PR** assim que a aplicação existe na linha principal) | Fronteira de **segurança** da plataforma (disparo manual só existe para definição na linha principal — senão qualquer branch rodaria o pipeline com os **segredos do repositório**); ver ADR-010 item 10 |
| CI (pipeline, não ambiente) | **GitHub Actions (nuvem)** em **PR** e **exercitável sobre a revisão da branch antes do PR** (disparo **fora de `pull_request`**, **a partir da definição de CI já integrada à linha principal**): **lint + testes (api) + build (web) + gate de drift** (regenera orval, falha se divergir) + **RLS via testcontainers** (Postgres no runner); **publica as imagens de aplicação no registry** (imutáveis por versão do código) | Concretiza M0.5/RNF0.7 da 00 e dá evidência pré-PR; a imagem publicada **é o artefato que a produção puxa**; ver ADR-007/010/011 |
| CD | **pull-based**: o **host de produção** (**só produção**) **puxa** da `master` (egress; sem ingress); GitHub não empurra; **mecanismo = runner self-hosted do GitHub Actions no host de produção** (event-driven, egress-only; polling caseiro rejeitado). **Produção puxa a imagem versionada do registry — não constrói no host** (ADR-011). **Provisionamento reproduzível (infra-as-code, inclui bootstrap do runner) + runbook `DEPLOY.md`** entregues pela 00; deploy **reproduzível** via eles; **critério de pronto da 00 = prova do mecanismo pré-PR**, disparado **fora do fluxo de merge** a partir da **definição já na linha principal** e **apontando para a revisão da branch**, com evidência; a **liveness pós-deploy** (smoke test + **rollback = re-implantar o artefato imutável anterior**) é **mecanismo entregue E MEDIDO pela 00** — a aplicação implantável da 00 é o próprio stack de fundação, **já implantado em produção** (reinstalação a frio em 2026-09-17) com o rollback automático observado disparando; a **execução da reversão pelo artefato** permanece **sob a 00**, entregue como mecanismo mas ainda **NÃO-MEDIDA / em aberto** (pendente de um rollback real bem-sucedido; disparos observados falharam por resíduo de host), não transferida à feature 01 | ADR-010/011 |
| Teste (backend) | **pytest + testcontainers** (Postgres real p/ RLS) + **testes point-in-time** (SCD-2) | Cobre os 2 hotspots de risco (isolamento, custo do mês); ver ADR-007 |
| Teste (frontend) | **Vitest** (unit); **Playwright (e2e) posterior** | Unit desde já; e2e quando a maturidade exigir; ver ADR-007 |
| Convenções de API | **Envelope de erro único** `{error:{code,message,details[]?,request_id}}`, **paginação cursor** (limit default 50, máx 200), **versionamento** — decididas 1× na feature 00; **filtro/ordenação NÃO** entra na 00 (catálogo estático), fica p/ a 1ª lista filtrável real (feature 02+) | Decididas 1× na feature 00, herdadas por todas; ver ADR-008 |
| Auditoria (uso/operações sensíveis) | **Tabela de auditoria** + escrita nas operações sensíveis (PII de colaboradores + valores); LGPD = um dos drivers | Casa de implementação da constitution VIII; ver ADR-008 |

> **Itens "posterior" (não-v1, sem PRD agora):** backup & disaster recovery; circuit
> breaker e middlewares (o **lugar** fica reservado em FastAPI — ADR-004 — mas **não** se
> implementa agora); **OpenTelemetry** (métricas/tracing); **Playwright (e2e de frontend)**;
> **seed/dados de referência de NEGÓCIO** (o **seed do usuário de desenvolvimento** **não** está aqui —
> é parte do ambiente reproduzível, entregue pela **feature 00**); **runtime/agendador do job de sync NetCorp** (cron/systemd/worker — detalhe
> de deploy da feature 02a); microsserviços stateless para tarefas específicas (ex.: processar
> planilha). São **adiados de propósito** (não esquecidos): entram quando a maturidade exigir.

---

## 6. Decomposição em features (1 PRD por feature)

Cada feature tem PRD em `docs/prds/E<n>-<slug>/<id>-<slug>.md` (8 seções pt-BR + Changelog),
no diretório do seu **épico** (§7). O **ID** da feature é **estável** — feature desmembrada
ganha letra (`02a`, `02b`); o número **não** indica ordem. A **ordem de implementação vem do
grafo de dependência** abaixo. A coluna **Depende de** lista dependências **duras**; (s) marca
dependência **recomendada/soft**. A coluna **Departamento atendido** registra quem a feature
serve (épico **não** é departamento).

| ID | Feature | Épico | Departamento atendido | Depende de | PRD |
|----|---------|-------|-----------------------|------------|-----|
| **00** | Fundação, Autenticação e Shell | E0 | — (base transversal) | — | [00](prds/E0-fundacao/00-fundacao-auth-shell.md) |
| **01** | Controle de Acesso por Departamento | E1 | — (transversal) | 00 | [01](prds/E1-controle-acesso/01-controle-acesso-area.md) |
| **06d** | Desativação, correção e apagamento de usuário | E1 | — (administração de usuários, transversal) | 01 | [06d](prds/E1-controle-acesso/06d-desativacao-exclusao-correcao-usuario.md) |
| **02a** | Integração NetCorp — Clientes e conector NetCorp | E2 | — (dado-mestre cross-área) | 00, 01(s) | [02a](prds/E2-integracao-netcorp/02a-clientes.md) |
| **02b** | Integração NetCorp — catálogo de CR (`tbcencus`) | E2 | — (dado-mestre cross-área) | 02a | [02b](prds/E2-integracao-netcorp/02b-catalogo-cr.md) |
| **03** | Contrato Jurídico | E3 | Contratos (`contracts`) | 02a | [03](prds/E3-gestao-de-contratos/03-contrato-juridico.md) |
| **04** | Contrato Operacional | E3 | Contratos (`contracts`) | 03 | [04](prds/E3-gestao-de-contratos/04-contrato-operacional.md) |
| **05a** | BR/Projeto | E3 | Contratos (`contracts`) | 04, 02b | [05a](prds/E3-gestao-de-contratos/05a-br-projeto.md) |
| **05b** | PCR (só em **CR de projeto**) | E3 | Contratos (`contracts`) | 05a | [05b](prds/E3-gestao-de-contratos/05b-pcr.md) |
| **06a** | Colaboradores (histórico de departamento) | E4 | Planejamento (área) ¹ | 00, 01, 02b, 06d (fluxo de apagamento por pessoa) | [06a](prds/E4-gestao-de-custos/06a-colaboradores.md) |
| **06b** | Skills (catálogo, histórico, migração de departamento) | E4 | Planejamento (área) ¹ | 06a | [06b](prds/E4-gestao-de-custos/06b-skills.md) |
| **06c** | Vínculo colaborador–usuário | E4 | — (administração de usuários, transversal) | 01, 06a; 06d `[a definir]` | [06c](prds/E4-gestao-de-custos/06c-vinculo-colaborador-usuario.md) |
| **07** | SPC — Standard Price Cost (histórico de valor) | E4 | Planejamento (área) ¹ | 06b | [07](prds/E4-gestao-de-custos/07-spc-standard-price-cost.md) |
| **08** | Importação da planilha de alocação de esforço | E4 | Planejamento (área) ¹ | 05a, 06a | [08](prds/E4-gestao-de-custos/08-importacao-alocacao-esforco.md) |
| **09** | Fechamento mensal / cálculo de custo | E4 | Planejamento (área) ¹ | 07, 08, 06b | [09](prds/E4-gestao-de-custos/09-fechamento-mensal-custo.md) |
| **10** | Controle de BR | E5 | BID (`bid`) | 02a, 05a | [10](prds/E5-proposta-comercial/10-controle-de-br.md) |
| **11a** | Rebate | E6 | Parcerias (`partnerships`) | 00, 01 | [11a](prds/E6-gestao-de-rebates/11a-rebate.md) |
| **11b** | Renovação de licenças de software | E7 | Parcerias (`partnerships`) | 00, 01 | [11b](prds/E7-renovacao-de-licencas/11b-renovacao-licencas.md) |

¹ O PRD fixa a **área** (acesso), não o departamento dentro dela.

### Grafo de dependências

```text
00 ─► 01 ─┬─► 02a ─┬─► 03 ─► 04 ─┐
          │        │             ▼
          │        ├─► 02b ───► 05a ─┬─► 05b
          │        │     │           ├─► 08 ─► 09
          │        │     │           └─► 10 ◄── 02a
          │        │     └─► 06a ─┬─► 06b ─► 07 ─► 09
          │        │              ├─► 08        (09 também ◄── 06b)
          │        │              └─► 06c ◄── 01   (06c ◄── 06d: [a definir])
          ├─► 06d ─► 06a   (fluxo de apagamento por pessoa)
          ├─► 11a
          └─► 11b
```

(01 → 02a é dependência **soft**; as demais são duras — ver a coluna **Depende de**.)

- **Caminho crítico (núcleo de valor — Gestão de Contratos):** `00 → 01 → 02a → 03 → 04 → 05a →
  05b`, com `02a → 02b → 05a` (a 05a precisa do catálogo de CR).
- **Cadeia de custeio:** `02b → 06a → 06b → 07` e `05a + 06a → 08`; `07 + 08 + 06b → 09`
  (junta pessoas + projetos).
- **Paralelizável:** `06a–06b–07` (pessoas/skills) é **independente** de `03–05b` (contratos) —
  depende apenas do **catálogo de CR (feature 02b)** para o vínculo `departamento → CR interno`
  (**não** do PCR nem do BR/Projeto). Encontra-se com os contratos só na **alocação (08)**.
  `11a`, `11b` e `06d` dependem só de `00`/`01` e podem correr em paralelo se houver capacidade; a
  `06a` depende também da `06d`, porque só pluga o anonimizador do colaborador num fluxo de
  apagamento por pessoa que já existe.

---

## 7. Épicos

> **Sem estimativas de duração** — o requisito **não fornece prazos**. Durações = **a
> definir**. A **ordem de implementação** vem do **grafo de dependência** entre features (§6).

| Épico | Features | Objetivo / critério de pronto |
|-------|----------|-------------------------------|
| **E0 — Fundação** | 00 | v1 em produção: login + shell com as 3 áreas expandindo seus 7 departamentos. **00 (shell/auth) e 01 (autorização) permanecem separados** — o acesso não nasce no 00. A **liveness pós-deploy** e a **execução da reversão pelo artefato** são **entregues pela própria 00** e permanecem **sob ela** — a aplicação implantável da 00 é o **próprio stack de fundação**, **já implantado em produção**; a **liveness** está **MEDIDA**, a **execução da reversão** segue **entregue como mecanismo, porém NÃO-MEDIDA / em aberto sob a 00** (pendente de um exercício real bem-sucedido) (ADR-010 itens 5b/9); a 01 **não** herda essas medições nem essa propriedade. |
| **E1 — Controle de Acesso** | 01, 06d | **Acesso por departamento** aplicado. Cobertura da **06d** (desativação, correção e apagamento de usuário) no critério de pronto = **`[a definir]`**. |
| **E2 — Integração NetCorp** | 02a, 02b | **Clientes/Grupos** e **catálogo de CR (`tbcencus`)** do NetCorp disponíveis (unicidade garantida) para todo o sistema — habilita Departamentos (06a) e CR de projeto (05a). |
| **E3 — Gestão de Contratos** | 03, 04, 05a, 05b | Hierarquia Jurídico→Operacional→BR+PCR operante. |
| **E4 — Gestão de Custos** | 06a, 06b, 06c, 07, 08, 09 | Colaboradores, skills/SPC, alocação e **custo do mês** calculável. Cobertura da **06c** (vínculo colaborador–usuário) no critério de pronto = **`[a definir]`**. |
| **E5 — Proposta Comercial** | 10 | **`[a definir]`** |
| **E6 — Gestão de Rebates** | 11a | **`[a definir]`** |
| **E7 — Controle de Renovação de Licenças de Software** | 11b | **`[a definir]`** |

**Departamentos sem épico** (sem escopo concreto; entram no plano quando houver iniciativa
definida): **Faturamento** (`invoicing`, área Planejamento), **Compras** (`procurement`, área
Financeiro), **Logística** (`logistics`) e **Importação** (`imports`), ambos na área Supply Chain
Management. Os itens **"posterior"**
(backup/DR, circuit breaker, microsserviços etc.) seguem em §5.

---

## 8. Concerns cross-feature (constitution-enforced)

Não são features isoladas; são **propriedades** que **toda** feature respeita (a
`constitution` é a **âncora de coerência cross-feature**, aplicada pelo **gate de conformidade**
(`conformance-gate`)). Âncora técnica em **00**.

| Concern | Como se materializa | Constitution |
|---------|---------------------|--------------|
| **Acesso por departamento** | **Fronteira:** Supabase Auth = só **autenticação**; **autorização** (quem acessa o quê) = domínio itallus (`department_access` + papel/**permissão**). **Enforcement por permissão** (papel = bundle de dados) com **interseção escopo∧capacidade**, deny-by-default: **RLS = eixo escopo** (dept/área), **PEP na app = eixo capacidade/ação**, escrita valida os dois; UI condicionada ao departamento/área. Catálogo de áreas/depts **semeado, sem CRUD**. **Escalonamento de privilégio:** Admin concede **usuário/manager**; **só o SuperAdmin** concede **admin/superadmin** (sem auto-elevação) — ADR-009. **Mecanismo:** conexão de runtime com **role não-privilegiado** (nunca `service_role`) + **propagação dos claims do JWT por transação pelo trilho da 00** (`set_config('request.jwt.claims', …, true)`, inalterado); a policy lê **só o `sub`** desse JSON e decide o escopo por `EXISTS`/`JOIN` em `department_access`/`role_permission` para todos os papéis — escopo global de admin/superadmin por **permissão explícita** em `role_permission`, não por papel propagado — ADR-002/006 | V |
| **LGPD (desde v1)** | Mapa de dados sensíveis, retenção com prazos; **right-to-erase = ANONIMIZAÇÃO do PII** (não hard-delete — preserva o registro de-identificado p/ SCD-2/auditoria/custo); o direito é do **titular-pessoa, não do registro** — a **feature 06d é dona de um fluxo único de apagamento por pessoa** que **coordena um anonimizador por entidade** (o da **01** para o usuário, o da **06a** para o colaborador quando entregue, futuros). **Executor = SuperAdmin**, **dois gatilhos** (pedido do titular / fim de retenção), **sem disparo automático** (ADR-009); **anonimização do usuário** = **mecanismo da feature 01, sem interface**, acionado na **feature 06d**, que **desativa antes de anonimizar**; a **06d é dona do mecanismo de retenção** dos dados do usuário e da trilha de auditoria (o prazo do **perfil** do usuário corre a partir do **fim da finalidade** — quando ele deixou de estar ativo —, e o **perfil de usuário ativo nunca entra em retenção**; as trilhas mantêm o expurgo por faixa de data; prazos/base legal `[a definir]` com responsável nomeado); **auditoria de operações sensíveis em tabela de auditoria** (PII de colaboradores + valores) — casa fixada no ADR-008 | VIII |
| **Correção monetária** | Valores e percentuais em **`Decimal`/`NUMERIC`/string-JSON**, **nunca `float`** — sem erro de arredondamento no núcleo de valor (R$) — ADR-006 | I, II |
| **Plugabilidade** | Ports & adapters (auth, banco, NetCorp e demais); **catálogo de ports/adapters** fixado no ADR-004 (critério: dependência de **saída** que o domínio chama e se troca/mocka) | III, VI, VII |
| **Observabilidade** | **structlog desde a v1** (logs suficientes p/ diagnosticar só pelos logs; **sem PII/segredo**); **OpenTelemetry posterior**. **Painel de monitoramento = usar o do Supabase por ora** (não construir painel próprio agora — ADR-009, coerente com OTel posterior); como o **stack Supabase completo** roda em dev e prod (ADR-010), o **Studio fica disponível no ambiente** como esse painel, sem ferramenta extra. Logging/métricas = **transversais via facade nas bordas** (não ports — ADR-004) | V, VI |
| **Eficiência de performance** | **Sem custo oculto** (N+1, full scan, O(n²)); onde o uso justifica, o **caminho crítico** tem alvo **explícito** de latência/throughput, **derivado de decisão registrada** | II |
| **Config externalizada** | 100% por ambiente; sem hardcode; **seleciona o ambiente (dev/prod) e o alvo NetCorp (stub/teste/prod)** por config — ADR-010; no `web`, **distingue a URL do Supabase voltada ao navegador da URL interna (rede do compose) usada server-side** — ADR-011 | VII |
| **Compatibilidade de contrato** | **Convenções transversais de API** (paginação, **envelope de erro único**, versionamento) decididas 1× e herdadas; **filtro/ordenação** fica p/ a 1ª lista filtrável real (feature 02+), não na 00; **gate de drift OpenAPI→orval em CI** — ADR-007/008 | III |
| **Histórico/auditoria** | SCD-2 nos 3 históricos obrigatórios; **trilha de auditoria** (ADR-008; **leitura integral só para o SuperAdmin**, demais usuários leem **só as próprias ações**); cobertos por **testes point-in-time** (ADR-007) | IV, VIII |

---

## 9. Decisões de arquitetura (ADRs)

### ADR-001 — Integração NetCorp **read-only PURO** via anti-corruption layer + cache local
- **Status:** Proposto.
- **Contexto:** NetCorp é o **core de informação** (20+ anos, sem manutenção, pouca
  doc). Objetivo: extrair info evitando **duplicidade** e garantindo **unicidade**.
- **Decisão:** itallus consome NetCorp **somente leitura** (**read-only PURO** — sem
  nenhuma escrita, **inclusive no handoff do BID**), via **adapter/ACL** que traduz o
  modelo legado para o domínio itallus. A integração usa **cache/replicação local**: um
  **job periódico** lê do NetCorp e **espelha em tabelas locais (PostgreSQL)**; todo o
  resto do itallus lê do **espelho local**, **nunca** consulta o NetCorp em runtime.
  Vale para Clientes/Grupos e para os **Projetos** puxados pós-venda. NetCorp permanece
  **fonte da verdade** dos dados que origina (Clientes, Centro de Resultado, Projetos).
- **Consequências:** + isola o legado, reduz acoplamento, facilita troca de origem,
  desacopla runtime da disponibilidade do legado; − **frequência/reconciliação a
  definir** (idempotência — constitution IV); tratamento de **schema sem documentação**.
- **Evolução:** uma entidade específica (candidata: PCR/valores sensíveis ao mês no
  fechamento) pode ser promovida a **consulta ao vivo** no futuro (vira híbrido) — apenas
  possibilidade, não decisão agora.
- **Alternativas:** escrever no NetCorp (rejeitado — risco em sistema legado crítico);
  duplicar dados como master no itallus (rejeitado — fere unicidade); consulta ao vivo
  em runtime (rejeitado por ora — acopla runtime ao legado indisponível/sem doc).

### ADR-002 — Acesso **por departamento** com **RLS no Postgres** + papéis
- **Status:** Proposto.
- **Contexto:** acesso **por departamento** a nível de usuário; hierarquia **Área ›
  Departamento** (uma área contém vários departamentos). **Modelo concreto — 3 áreas / 7
  departamentos:** **Supply Chain Management** (`supply-chain-management`) › `logistics`,
  `imports`, `partnerships`, `bid`; **Financeiro** (`finance`) › `procurement`; **Planejamento**
  (`planning`) › `contracts`, `invoicing` (`procurement` e `contracts` são novos). O
  **controle de acesso e a RLS são a nível de departamento** (cada usuário acessa os
  departamentos aos quais tem permissão); a área deriva do(s) departamento(s). **4 papéis**
  (privilégio
  hierárquico): **Usuário** (escopo = seu(s) departamento(s); padrão só o seu, pode
  receber +1; multivalorado) < **Manager** (escopo = toda(s) a(s) área(s) que gerencia =
  todos os departamentos delas; faz **aprovações**; **não** vê outras áreas nem gerencia
  acessos) < **Admin** (vê/gerencia tudo + gerencia acessos/permissões, exceto exclusivo
  do SuperAdmin) < **SuperAdmin** (tudo do Admin + configurações complexas exclusivas).
- **Decisão:** autorização em **defesa em profundidade** — RLS no banco (fonte de
  verdade do acesso) + checagem na aplicação + condicionamento na UI. Escopo usuário↔departamento em
  **tabela** (`department_access`) + papel, lidos nas policies; **nunca** confiar em
  claim editável pelo usuário (`user_metadata`). **[hipótese]** Claims podem ir ao
  `app_metadata` via Auth Hook para performance — a **avaliar**. O **ciclo de vida do
  usuário**, os **planos de administração** (Admin × SuperAdmin) e a **fronteira
  autenticação × autorização** estão no **ADR-009**.
- **Permissão como moeda + interseção escopo∧capacidade:** o **ponto de decisão** (guard na
  aplicação e RLS) opera sobre **permissão**, não sobre papel. `permission` é um **catálogo
  genérico de capacidades** de qualquer ação/domínio (criar/editar/cancelar/exportar/fechar
  mês/aprovar…), **desacoplado** do catálogo de departamentos. **Papel = unidade de concessão**
  = bundle de permissões definido em dados (`role_permission`); o Admin concede **papel**. Na v1
  cada papel tem um **bundle default grosso** ("tudo dentro do escopo") + as capacidades que o
  distinguem. **Dois eixos ortogonais que se intersectam:** **escopo** (departamento/área) e
  **capacidade** (permissão) — a capacidade é exercida **dentro** do escopo; autoridade efetiva =
  **permissão ∧ escopo**, avaliada por request, **deny-by-default**. Uma permissão sem alvo no
  escopo do usuário é **inerte**, não um furo. **Divisão por camada:** **RLS = eixo escopo** (gate
  de escopo deny-by-default, testado com Postgres real e tentativa cross-departamento que deve
  falhar); **PEP na aplicação = eixo capacidade/ação**; a **escrita valida os dois**. O
  **escalonamento** (ADR-009) é expresso na moeda-permissão. **Ganchos futuros (não construir
  agora):** concessão **fina por usuário** (fora do papel) e condições **ABAC/alçada** ("aprovar
  até R$X", via payload de atributo na permissão concedida); validar coerência da concessão contra
  o escopo é **UX opcional futura**, não mecanismo de segurança (a RLS já isola).
- **Escopo na policy — todos os papéis pela tabela** (refino 2026-09-23, brainstorm da 01): a
  policy decide o escopo por `EXISTS`/`JOIN` em `department_access`/`role_permission` para
  **todos** os papéis. O **escopo global** de Admin/SuperAdmin é reconhecido por uma **permissão
  explícita de escopo global** em `role_permission`, verificada **no mesmo `EXISTS`** da policy —
  **não** por papel propagado. Um **índice cobre o `EXISTS`/`JOIN`** da policy (sem full scan).
  Propagação da identidade: ver ADR-006. **Desenho exato** da permissão de escopo global e da
  cláusula `EXISTS` = **[a definir no Design da 01]**.
- **Catálogo de áreas/departamentos = semeado, sem CRUD de usuário:** as **3 áreas + 7
  departamentos** são criadas por **seed/migração** e mudam **só via desenvolvimento** — **não há
  cadastro/CRUD** de área/departamento pelo usuário. A **associação de departamento a usuário**
  (`department_access`) permanece editável (gestão de acessos).
- **Consequências:** + acesso garantido mesmo se a app falhar; + ação futura (por capacidade) =
  linha de dado + atribuição, sem reescrever o enforcement; − policies viram parte
  do contrato de cada tabela (toda feature de dados precisa declarar as suas); − dois lugares de
  enforcement (RLS escopo + PEP capacidade), esperado numa defesa em profundidade.
- **Aprovações — ponto em aberto:** a capacidade **`approve`** é **semeada, escopada e sem
  fluxo** de aprovação; **quais fluxos têm etapa de aprovação ainda não está definido** (único
  caso conhecido = ordens de compra). **Não modelar aprovação em nenhum fluxo agora.**
- **Alternativas:** só autorização na aplicação (rejeitado — banco fica exposto);
  só claim no JWT (rejeitado — escopo muda com frequência e exige re-login); **guard sobre papel**
  (rejeitado — granularizar por ação depois reescreveria o ponto de decisão); **RBAC/ABAC completo
  agora** (rejeitado — YAGNI: nenhuma condição/alçada tem requisito ativo); **inflar
  `department_access` com uma linha por departamento para Admin/SuperAdmin** (rejeitado — refino
  2026-09-23; o escopo global é permissão explícita em `role_permission`); **função `SECURITY
  DEFINER` / role de banco separada com `BYPASSRLS`** para liberar Admin/SuperAdmin (rejeitado —
  refino 2026-09-23; o escopo global é verificado dentro da própria policy).

### ADR-003 — Históricos obrigatórios em **SCD Tipo 2**
- **Status:** Proposto.
- **Contexto:** 3 históricos obrigatórios — **departamento** e **skill** por
  colaborador, **valor de skill (SPC)** — usados no **fechamento mensal** (custo
  depende do valor **vigente no mês**).
- **Decisão:** modelar como **SCD Tipo 2** (uma linha por versão, `vigencia_inicio` /
  `vigencia_fim` + `is_current`), permitindo consulta **point-in-time** (custo do mês X
  usa a skill/SPC vigentes naquele mês).
- **Consequências:** + auditabilidade e cálculo retroativo corretos; − escrita mais
  complexa (encerrar versão + abrir nova) e queries filtram vigência.
- **Alternativas:** SCD-1/overwrite (rejeitado — perde o histórico exigido); tabela de
  log separada (Tipo 4) — viável, mas point-in-time fica mais custoso.

### ADR-004 — Estrutura de repositório: **monorepo** (`apps/api` + `apps/web`)
- **Status:** Proposto.
- **Contexto:** o the-planner **não** havia fixado estrutura de pastas (é decisão de
  implementação). A governança já existente (hooks `.githooks`, fluxo `feature/* → qa →
  master`, branch protection, **deploy em host único**) favorece um **único repositório**.
- **Decisão:** **monorepo, um único repo**, com dois apps:
  - **`apps/api`** — backend **FastAPI + uv**, em **Clean Architecture / Hexagonal
    (Ports & Adapters)** — Clean Arch e Hexagonal são a **mesma família** (a visão já
    chamava de "Clean Architecture / ports-adapters"); **não é troca de abordagem**.
    Camadas: `domain/` (entidades + regras), `application/` (casos de uso), `ports/`
    (interfaces), `adapters/` (**in:** rotas API; **out:** Postgres, ACL NetCorp,
    Supabase). `tests/` espelha `app/`. **Config externalizada** (constitution VII).
  - **`apps/web`** — frontend **Next.js + Tailwind + shadcn**: `app/` (App Router),
    `components/`, `lib/api/` (client tipado gerado do OpenAPI — ver ADR-005),
    `design-system/` (`MASTER.md` + `pages/*.md` do **ui-ux-pro-max**).
  - **Raiz:** `docs/`, `.specify/`, `.github/`, `.githooks/` e a skill embutida
    `.claude/skills/ui-ux-pro-max/` permanecem no nível-repo.
- **Catálogo de ports/adapters** — critério: **port/adapter = dependência de SAÍDA que o
  domínio chama e que se troca/mocka**.
  - **SÃO port/adapter (out):** **Persistência** (repositórios Postgres) · **Auth/
    identidade** (Supabase) · **NetCorp** (ACL read-only) · **EmailSender** (handoff BID:
    `mailto:` v1 → SMTP/Graph depois) · **Storage de documentos** (Oportunidade WBS/PCR/PT;
    Supabase Storage → S3/local) · **Clock/tempo** (determinístico em teste; SCD-2
    vigência + fechamento "vigente no mês").
  - **NÃO são port/adapter:** transversais — **logging** (structlog), **métricas/tracing**
    (OpenTelemetry), **config**, **validação** (Pydantic), **tradução de erro**
    (middleware) → **facade padrão nas bordas**, domínio limpo. Adapters de **entrada**
    (rotas FastAPI, scheduler do job de sync, parser de planilha) **chamam** o domínio,
    não o contrário. Detalhe interno: SQLModel/ORM (vive **dentro** do adapter de
    persistência — o port é o **repositório**), RLS/policies (no banco), geração do
    código interno do contrato (domínio).
- **Middlewares e circuit breaker:** **deferidos** (requisito §4 = "posterior/não-v1").
  O ADR **deixa o lugar** (FastAPI middlewares/dependencies) mas **não os implementa**.
- **Altitude:** este ADR fixa **esqueleto + convenções** (camadas, testes, config,
  catálogo port/adapter); **internos por feature ficam para o Design** do AgentSpec
  (evitar over-engineering — constitution "avaliar a complexidade").
- **Consequências:** + um só repo simplifica governança/CI e o deploy único; + fronteiras
  claras backend/frontend; + domínio testável (I/O nas bordas); − exige disciplina para
  não vazar framework/ORM ao domínio; − tooling de monorepo (build/CI dos dois apps).
- **Alternativas:** dois repositórios separados (rejeitado — duplica governança/branch
  protection e dificulta o contrato compartilhado e o deploy único); estrutura flat sem
  camadas (rejeitado — fere Clean Arch/constitution VI).

### ADR-005 — Fluxo de desenvolvimento e **contrato front↔back** (OpenAPI → orval)
- **Status:** Proposto.
- **Contexto:** cada feature é **ponta a ponta** (backend + frontend). É preciso um
  **conector (seam)** tipado entre os dois apps do monorepo (ADR-004) que pegue **drift**
  cedo, e um fluxo de AgentSpec que ordene backend→frontend dentro da mesma feature.
- **Decisão:**
  - **Uma feature = um PRD = ponta a ponta** (backend + frontend juntos). **Não**
    fragmentar em features separadas de front e back.
  - **Por ciclo AgentSpec:** **Define** (escopo/requisitos inteiros) → **Design** (**define
    endpoints da API + telas = é AQUI o mapeamento front↔back**; ordena a construção: domínio →
    adapters → **API/contrato** → client tipado → tela, no File Manifest) → **Build** (deriva do
    File Manifest do Design — sem fase de tarefas isolada) → **Ship**.
  - **Backend-first dentro da feature** — o frontend precisa do contrato para ser tipado.
  - **Seam = contrato OpenAPI:** o **FastAPI gera o OpenAPI automaticamente** (fonte da
    verdade do contrato); o **`apps/web` gera um client TS tipado** com **orval** (client +
    hooks **TanStack Query** por endpoint, em `apps/web/lib/api/`). Front bate com back em
    **compile-time**; drift pego em **CI/build**.
  - **Frontend** segue o design system do **ui-ux-pro-max** (`MASTER.md`) na metade
    frontend do **Build**.
  - **Padrão-alvo = SaaS/ERP corporativo moderno para uso interno diário.** O design system
    deve atingir o nível de um produto operacional moderno — **estados, movimento, contraste,
    foco e responsividade** de produto, **não** telas planas. **Direção de estilo (referência):**
    estética **sóbria, de baixo ruído, minimalista**, adequada a **trabalho operacional diário**.
    **Anti-patterns (vedados):** padrões de **marketing/conversão** e **gradientes "AI"
    (roxo/rosa)**.
  - **Responsividade = alvo por tela (v1).** A **tela de login** atende viewports **a partir de
    375px**; a **casca autenticada** (topbar/sidebar, breadcrumb, páginas de departamento) atende
    viewports **a partir de 768px**. Viewports **abaixo de 768px na casca autenticada NÃO são
    suportados na v1** — o layout **pode quebrar**, e isso é **comportamento aceito, não defeito**.
    Os **demais atributos do padrão — estados, movimento, contraste, foco — aplicam-se a TODAS as
    telas da v1 sem exceção** (a exceção de alvo vale **só** para responsividade).
  - **Brief do gerador = plataforma operacional multi-módulo (estilo ERP), orientada a
    processo/estado** — ciclo de vida de contrato pós-venda (abre → etapas → encerra), com
    **3 áreas** — **Planejamento** [foco primário] (Contratos, Faturamento), **Supply Chain
    Management** (Logística, Importação, Parcerias, BID) e **Financeiro** (Compras) —, cada uma
    **expandindo seus departamentos** sob **navegação única hierárquica** (não uma lista plana
    de "áreas"). **(Revoga** o brief genérico
    "Analytics Dashboard" com que o `MASTER.md` foi gerado.)
  - **Requisitos transversais de UI** (vivem no design system; as telas das features herdam):
    **componente reutilizável de pipeline/stepper de status** para os fluxos lineares pós-venda
    (contrato, faturamento, logística, importação); **tabelas densas** com **filtro/ordenação/
    paginação server-side** (alinhado ao ADR-008); **anexo/preview de documentos**; **trilha de
    auditoria** (quem/o quê/quando — alinhado ao ADR-008). **Variação de UI por área:** o **BID é
    exceção pré-venda** — padrão de **funil/comparação de oportunidades**, distinto do stepper
    linear (ver feature 10).
  - **Alinhamento de marca = restrito a CORES e LOGOTIPO.** Apenas a **paleta** e o **logotipo/
    ícone** da Italtel vinculam-se à marca; **tipografia e iconografia NÃO ficam vinculadas à
    marca** (escolhidas pelo padrão SaaS/ERP acima). **Revoga a ancoragem tipográfica anterior**
    (tipografia presa ao guia — em ADR-005/`MASTER.md`/`globals.css`). A **referência de marca
    está versionada em `docs/brand-identity/`**: guia `brand-guidelines/Italtel_Brand_Guidelines_2024.pdf`
    (cores) e ícones em `logo/icons/` (`Icon@2x (3).png` default, `Icon_black@2x.png`,
    `Icon_white@2x.png`). Os **valores concretos de cor/uso de logo** são **extraídos do guia na
    implementação** (PRD 00) — a visão **não** os transcreve (fonte externa).
  - **v1 (login + casca) realiza integralmente o padrão** — com estados, movimento, contraste
    e foco no nível de um produto moderno (não é placeholder visual); **responsividade segue o
    alvo por tela** acima (login ≥375px; casca ≥768px, abaixo disso na casca = fora de suporte v1).
  - **Feature 00 é especial:** monta de uma vez o **esqueleto monorepo**, os dois shells
    (api+web), auth, o **pipeline OpenAPI → orval** e **gera o `design-system/MASTER.md`**
    (1×) via ui-ux-pro-max, **no padrão SaaS/ERP corporativo moderno** (brief = plataforma
    operacional multi-módulo, não "Analytics Dashboard"; marca restrita a cores + logotipo).
    As features seguintes só **acrescentam endpoints + telas** sobre esse trilho.
- **Consequências:** + contrato único e verificável (sem drift silencioso — constitution
  III); + produtividade num app CRUD-pesado (hooks prontos por endpoint); + design
  consistente (um só Master); − acopla o build do web à geração do OpenAPI (passo de
  codegen no CI); − orval adiciona dependência/configuração vs. uma abordagem mais enxuta.
- **Alternativas:** **openapi-typescript** (gera **só** os tipos, mais enxuta, **sem
  hooks**) — **preterida**: o orval foi escolhido pela **produtividade** num app
  CRUD-pesado (gera client + hooks TanStack Query). Cliente HTTP tipado à mão (rejeitado —
  drift manual). Definir o contrato no frontend e gerar o backend (rejeitado — o backend é
  a fonte da verdade do domínio).

### ADR-006 — Persistência, migração e acesso a dados (data layer)
- **Status:** Proposto.
- **Contexto:** o ADR-002 fixou "RLS no Postgres" mas **não** o **mecanismo** de como a
  identidade do usuário chega ao banco para as policies aplicarem; **SQLModel não faz
  migração** de schema; e não havia decisão sobre **representação monetária** — sendo o
  sistema todo sobre **R$** (invoice, revenue, valor de contrato, SPC, custo do mês).
- **Decisão:**
  - **Stack de dados = FastAPI + SQLModel + Alembic.** **SQLModel define** tabelas/ORM
    (encapsula Pydantic + SQLAlchemy); **Alembic** (pacote separado do mesmo ecossistema)
    **versiona as mudanças de schema** com `target_metadata = SQLModel.metadata`
    (autogenerate). Alembic **complementa**, não substitui, o SQLModel. (Substitui a
    [hipótese] de "migrações versionadas" que o PRD 00 deixava em aberto.)
  - **RLS-como-migração:** as **policies de RLS** (ADR-002) vivem **dentro das migrações
    Alembic** (`op.execute("CREATE POLICY …")`) — **schema e RLS versionados juntos**, por
    feature. Cada feature de dados declara suas policies na própria migração.
  - **Caminho de dados / endpoint do Postgres:** a **API (FastAPI) é o único componente que
    acessa o banco**, **gerencia o próprio pool de conexões** e conecta-se **diretamente à
    instância Postgres** — **tanto nas migrations (Alembic) quanto na persistência de runtime**.
    O **Supavisor** (pooler de conexões do stack self-hosted) atende ao **ecossistema interno do
    Supabase** e **não faz parte do caminho de dados da aplicação**: a aplicação **não** alcança o
    Postgres através dele. (Endpoint concreto por ambiente = config externalizada, constitution VII;
    ver ADR-010.)
  - **Mecanismo JWT → conexão → RLS:** a **conexão de runtime do FastAPI ao Postgres
    RESPEITA RLS** — usa um **role não-privilegiado** (NUNCA `service_role`, que **bypassa**
    RLS, no caminho do usuário); a **identidade do usuário** (claims do JWT do Supabase
    Auth) é **propagada por request** para a conexão/transação (ex.: `SET LOCAL` /
    `set_config` dos claims) de modo que as policies (`department_access` + papel — ADR-002)
    apliquem. **Jobs administrativos** (ex.: sync NetCorp) podem usar **role próprio fora do
    caminho do usuário**. Liga-se ao ADR-002 (que discute claim em `app_metadata` vs. tabela —
    manter coerência: a **tabela** é a fonte da verdade; `app_metadata` continua [a avaliar]
    só para performance). **Trilho fixado na feature 00:** propagação por **transação** via
    `set_config('request.jwt.claims', '<claims-json>', true)` (equivale a `SET LOCAL`, seguro
    com pool) executada pelo role **não-privilegiado `itallus_app`** antes de qualquer query; as
    policies lerão `current_setting('request.jwt.claims', true)::jsonb`. **As policies concretas
    por tabela ficam `[a definir no Design da feature 01]`.**
    **Refino 2026-09-23 (brainstorm da 01):** a policy decide o escopo por `EXISTS`/`JOIN` em
    `department_access`/`role_permission` para **todos** os papéis, inclusive o escopo global de
    Admin/SuperAdmin (permissão explícita em `role_permission` — ADR-002). **A identidade chega à
    policy pelo trilho da 00, sem alteração:** a API **continua propagando o JSON completo dos
    claims** via `set_config('request.jwt.claims', …, true)`, **sem canal novo dedicado ao
    `user_id`**; a policy da 01 lê **só o `sub`** de dentro desse JSON
    (`current_setting('request.jwt.claims', true)::jsonb ->> 'sub'`). A 01 **não altera o
    mecanismo de propagação** — só as policies que o consomem.
  - **Dinheiro e percentuais = Decimal/NUMERIC, nunca float.** Valores monetários (invoice,
    revenue, valor de contrato, SPC valor/hora, custo do mês) e percentuais (% 1ª/2ª margem,
    rebate) usam **`Decimal` no Python**, **`NUMERIC` no Postgres** e **string no JSON** do
    contrato OpenAPI — **nunca `float` em nenhuma camada** (evita erro de arredondamento no
    núcleo de valor). Cascateia aos PRDs que tratam valores (03, 04, 05b, 07, 08, 09; e
    percentuais na 11a).
- **Consequências:** + schema/RLS versionados e auditáveis; + acesso garantido **no banco**
  (RLS realmente aplica, não só na app); + correção monetária; − disciplina de migração por
  feature; − a propagação de claims adiciona **um passo** no acesso a dados (por request).
- **Alternativas:** **migrations nativas do Supabase** (preterida — o backend usa SQLModel e
  **não** a API PostgREST; Alembic integra com os próprios modelos); `float` para dinheiro
  (rejeitado — arredondamento no núcleo de valor); **propagar escopo/papel já resolvido pela API**
  (rejeitado — refino 2026-09-23; duplica na sessão a fonte da verdade, que é a tabela — ADR-002);
  **propagar o papel via `SET LOCAL`** para liberar Admin/SuperAdmin direto (rejeitado — refino
  2026-09-23; a decisão opera sobre permissão, e um papel propagado errado liberaria escopo global
  sem verificação); **`SET LOCAL app.user_id` novo, paralelo ao trilho `request.jwt.claims` da 00**
  (rejeitado — refino 2026-09-23; o `sub` já chega à policy pelo trilho existente); **restringir o
  trilho da 00 para propagar só o `user_id`** (rejeitado — refino 2026-09-23; a 01 não altera o
  mecanismo de propagação, só as policies que o consomem).

### ADR-007 — Plataforma de desenvolvimento, teste e CI
- **Status:** Proposto.
- **Contexto:** o **NetCorp (MS SQL legado) não existe em dev**; o ADR-005 **prometeu**
  "drift de contrato pego em CI" (M0.5/RNF0.7 da feature 00) mas **não havia CI definido**;
  e os **2 maiores riscos de correção** — isolamento de acesso por departamento (RLS) e
  cálculo **point-in-time** SCD-2 (custo do mês) — **não tinham infra de teste**.
- **Decisão:**
  - **Ambiente local reproduzível = `docker-compose`** (Postgres / Supabase self-hosted
    local), com **config externalizada** (constitution VII) — **paridade dev↔prod**
    (topologia consolidada no **ADR-010**: dev + prod, **sem staging permanente**). O ambiente
    reproduzível inclui o **seed idempotente do usuário de desenvolvimento** — **aplicável em ambiente
    limpo sem passo manual**, **reexecutável sem duplicar** o usuário e com **credenciais por config
    externalizada** —, **entregue pela feature 00**. Ele é **parte do ambiente**, **distinto** de
    **seed/dados de referência de negócio** (esses seguem **diferidos** — §11).
  - **Onde o ferramental deste ADR roda:** **host de desenvolvimento** e **runner da CI** — nunca como
    serviço containerizado da aplicação (fronteira definida no **ADR-011 item 1**).
  - **Stub/fake do NetCorp:** o **port ACL** (ADR-001/004) tem uma **implementação de
    teste/dev** com dados de amostra/fixtures (**test double** do adapter NetCorp) — permite
    **desenvolver e testar sem o legado**.
  - **CI (concretiza a promessa do ADR-005):** pipeline em **PR** (plataforma = **GitHub
    Actions**/nuvem — ADR-010; alinhado ao fluxo de branches `feature/* → qa → master`) que
    roda **lint + testes (api) + build (web) + gate
    de drift de contrato** — **regenera o client orval** e **falha** se divergir do OpenAPI.
    **Dá casa concreta ao M0.5 / RNF0.7 da feature 00** (que já os exige). O pipeline é também
    **exercitável fora de `pull_request`, sobre a revisão da branch, antes do PR**, para que
    o **gate de drift** e a **suíte de RLS em Postgres real** tenham **evidência ao vivo antes de
    abrir o PR** — sem isso, esses critérios só seriam observáveis no PR, deixando-os **não-medidos**
    no gate de DoD que precede a abertura do PR. **Condição habilitante declarada:** essa evidência
    pré-PR **exige a definição de CI já integrada à linha principal** (**ADR-010 item 10**) — é ela
    que **habilita o disparo**; a **revisão da branch** é que determina **o que é verificado**.
  - **Gates no PR que integra a definição do pipeline — exceção declarada e aceita.** Quando a
    **definição** chega à linha principal por **rota própria** (ADR-010 item 10), a **aplicação ainda
    não está lá**: os gates que **verificam a aplicação** (lint, testes, build, drift de contrato,
    RLS) **não têm objeto** e **não são executados nesse PR**. A exceção vale sob **duas condições**:
    (1) o **job sem fonte fica visivelmente NÃO-EXECUTADO**, **nunca reportado como aprovado** — uma
    exceção que se deixasse confundir com aprovação seria **pior do que não ter gate** (certificaria
    como verificado o que **ninguém verificou**); (2) **a partir do momento em que a aplicação existe
    na linha principal**, os gates **voltam a ser exigidos em TODO PR, sem exceção**. **Forma concreta
    de manter o job visivelmente não-executado = derivada no Design.**
  - **Publicação do artefato:** a CI **publica as imagens de aplicação num registry**, **versionadas
    de forma imutável por versão do código** (**ADR-011**). É **essa** imagem — a que a CI validou —
    que a **produção puxa** (nunca uma construída no host) e para onde o **rollback reverte**
    (**ADR-010**).
  - **Estratégia de teste:** **pytest + testcontainers** (Postgres **real** para testar **RLS
    de verdade** — isolamento por departamento/área) + **testes point-in-time** para SCD-2
    (custo do mês usa skill/SPC **vigentes**). Frontend: **Vitest** (unit); **Playwright
    (e2e)** fica **posterior** (`[a definir]`).
- **Consequências:** + qualquer um (inclusive um agente) **roda/testa local**; + os 2
  hotspots de risco ficam **testáveis**; + o contrato sem drift virou **gate real**; −
  tooling de CI/compose para **2 apps** a manter.
- **Alternativas:** testar RLS só com Postgres mockado (rejeitado — RLS não se exercita sem
  banco real); depender do NetCorp em dev (inviável — legado indisponível/sem doc).

### ADR-008 — Convenções de API e trilha de auditoria
- **Status:** Proposto.
- **Contexto:** app **CRUD-pesado** com dezenas de telas de lista; **sem contrato
  transversal**, cada feature reinventaria paginação/erro. E a **LGPD** (constitution VIII)
  exige **"auditoria de operações sensíveis"** — é concern (§8), mas **sem casa de
  implementação**.
- **Decisão:**
  - **Convenções transversais de API** (decididas **1×**, herdadas por **todas** as
    features, refletidas no OpenAPI → orval): **paginação cursor-based** (`?limit=&cursor=`;
    `limit` default **50**, máx **200**; resposta com `next_cursor` opaco) para listas
    grandes/estáveis, **envelope de erro único**
    `{ error: { code, message, details[]?, request_id } }` (`code` estável p/ máquina/i18n;
    `message` ao usuário; `request_id` correlaciona com o log) e **versionamento de API**.
    Decididas na feature 00 e herdadas pelas demais. **Filtro/ordenação NÃO é definido aqui:** o
    catálogo de navegação da 00 é **estático** (sem lista filtrável real); a **convenção de
    filtro/ordenação fica para a 1ª lista filtrável real (feature 02+)**, quando houver uso concreto.
  - **Trilha de auditoria de uso/operações sensíveis:** casa de implementação fixada —
    **tabela de auditoria** + **mecanismo de escrita** (ex.: nos casos de uso/adapters das
    operações **sensíveis** sobre **dados pessoais de colaboradores** e **valores**). Registra
    **quem / quando / o quê**. **LGPD é um dos drivers** (não a definição da tabela). Atende a
    constitution VIII e o concern de Histórico/auditoria (§8). O **escopo exato das operações
    auditadas** fica `[a definir por feature]`.
  - **Leitura da trilha de auditoria** (refino 2026-09-24): **integral para o SuperAdmin**;
    **restrita às próprias ações** para os **demais usuários**. A **consulta da trilha pela
    interface não pertence à feature 01**; a feature que a entrega segue **[a definir]**.
- **Consequências:** + consistência de API e auditoria **desde a v1** (sem retrofit); − um
  contrato transversal a respeitar em **toda** feature.
- **Alternativas:** cada feature define seu próprio padrão de paginação/erro (rejeitado —
  drift de contrato num app CRUD-pesado); auditoria só via logs (rejeitado — log não é trilha
  consultável nem atende ao direito do titular da LGPD).

### ADR-009 — Ciclo de vida de usuário, planos de administração e fronteira autenticação × autorização
- **Status:** Proposto.
- **Contexto:** o **ADR-002** fixou os **4 papéis** e a **RLS**, mas **não** definiu **como** o
  usuário é criado/administrado, **quem** o administra, nem a **fronteira** entre o **provedor de
  identidade** (Supabase) e o **modelo de acesso** do itallus. Liga-se ao **ADR-002**
  (papéis/`department_access`), **ADR-003** (SCD-2), **ADR-006** (mecanismo JWT→RLS / caminhos de
  conexão), **ADR-007** (observabilidade) e **ADR-008** (auditoria).
- **Decisão:**
  1. **Fronteira autenticação × autorização (explícita):** o **Supabase Auth** provê **apenas
     autenticação** (identidade, emissão/validação de JWT, primitivas de credencial). A
     **autorização** (quem acessa o quê) é **domínio do itallus**: tabela **`department_access`** +
     **papel**/**permissão**, lidos nas **policies RLS** (ADR-002). O Supabase **não comporta nem
     deve comportar** o modelo de acesso do itallus (departamento, hierarquia Área › Departamento,
     4 papéis, permissões).
  1a. **Fronteira 00 × 01 (produto):** a **feature 00** entrega o **mecanismo de identidade**
     (Supabase Auth/GoTrue, JWT, provisionamento) **e o baseline de auth na UI já implantado**:
     **tela de login** (`signInWithPassword`), **manejo/refresh de sessão**, **guarda de rota
     autenticado-ou-não** (`apps/web/middleware.ts`), **logout**, e o **shell** que lista **todas** as
     áreas/departamentos **sem** condicionamento de escopo. A **feature 01** **consome** esse baseline
     e acrescenta o que o torna utilizável e seguro por escopo: **(a)** o **ciclo de vida do usuário
     voltado ao produto** — **criar/convidar** usuário e **convite/reset** de credencial mediados pelo
     Admin (hoje `auth.users=0`); **(b)** tornar **navegação e rotas cientes de escopo+permissão** (o
     shell/middleware da 00 mostram tudo a qualquer autenticado); **(c)** o **mecanismo de
     anonimização do usuário**, **sem interface** (item 7). "Baseline de login/sessão/guarda de
     rota = 00; ciclo de vida do usuário + condicionamento por escopo/permissão = 01." A
     **desativação/reativação** e a **correção de nome e e-mail** de usuário **não** são da 01 —
     ficam com a **feature 06d** (item 7).
  2. **Dois planos de administração:** **Admin** (perfil de **negócio**) opera **100% dentro do
     itallus** (tela admin) e **NUNCA** acessa o Supabase Studio/infra; **SuperAdmin** (perfil
     **técnico**) é o **único** com acesso ao **Supabase Studio/infra** e às configurações
     técnicas/estruturais.
  3. **Criação de usuário (dentro do itallus, sem híbrido):** o **Admin cria/convida** o usuário
     **na tela admin** e, no mesmo fluxo, atribui **departamento(s) + papel** (o vínculo a
     colaborador nessa tela entra com a feature 06c — item 6). O **backend (FastAPI) cria a conta no Supabase Auth server-side**
     via **Auth Admin API**, com **credencial privilegiada usada SOMENTE server-side** — **distinta**
     da conexão de dados do usuário (role **não-privilegiado** que respeita RLS — ADR-006). São
     **dois caminhos**: **Auth Admin API privilegiada** para **gestão de conta**; **conexão RLS**
     (não-privilegiada) para **dados**. **Sem self-signup; sem fluxo híbrido.**
     **Convite/reset = link de uso único, mediado pelo Admin, sem e-mail** (refino 2026-09-23,
     brainstorm da 01): o backend gera um **token de uso único**, com **expiração curta**,
     **invalidado ao ser usado ou ao se gerar um novo**; o link é **exibido na tela admin** para o
     Admin repassar e o **usuário define a própria senha**. O **mesmo mecanismo** serve para
     **convite** e **reset**. A rota **"definir senha"** no `apps/web` é **exceção explícita ao guard
     de sessão da 00** (acessível **sem sessão prévia**), **sem abrir as demais rotas do produto**; a
     superfície exposta sem sessão é **só o consumo do token**. **Contexto verificável:** o stack
     vendorizado **não tem serviço de e-mail provisionado** (dev nem produção) — e-mail transacional
     é gancho futuro. **Formato, armazenamento e tempo de expiração do token** = **[a definir no
     Design da 01]**.
  4. **Papéis cumulativos + escalonamento de privilégio:** cumulatividade
     **`usuário ⊂ manager ⊂ admin ⊂ superadmin`** — cada papel **contém** o anterior (o **Admin faz
     tudo o que o Manager faz** — inclusive **aprovações** e ver/editar — porém em **escopo
     GLOBAL**, todas as áreas, **mais** a gestão de acessos). **Fronteira de segurança:** o **Admin**
     concede **usuário** e **manager**; **apenas o SuperAdmin** concede **Admin** e **SuperAdmin**
     (impede auto-elevação). Expressa na **moeda-permissão** (ADR-002): o Admin detém a capacidade de
     conceder `user`/`manager`; só o SuperAdmin a de conceder `admin`/`superadmin`.
  5. **Escopo do SuperAdmin (técnico):** **LGPD** (executar right-to-erase/anonimização),
     **observabilidade/monitoramento** (= **usar o painel do Supabase por ora**; **não** construir
     painel próprio agora — coerente com OTel posterior, ADR-007; o **Studio** está disponível no
     ambiente porque o **stack Supabase completo** roda em dev e prod — ADR-010) e demais
     configurações técnicas.
     O **conteúdo detalhado** das "configurações complexas" **se anexa feature a feature** (ex.:
     config NetCorp = 02a; retenção LGPD = transversal; fator dias→horas = 09) — não enumerado agora
     **[altitude]**.
  6. **Vínculo usuário ↔ colaborador:** opcional (usuário sem colaborador e vice-versa; desativar
     o usuário preserva o colaborador) e **editável somente na tela admin de gestão de usuário**.
     Na **tela de edição de colaborador** o usuário vinculado é **exibido somente para leitura**
     (em branco quando não houver vínculo), **sem edição**. Como a feature **01** não tem
     colaborador, a opção de **vincular colaborador** na gestão de usuário é **diferida para a
     feature 06c**, entregue como **melhoria da tela admin de gestão de usuário**; a 06c também
     garante que a desativação do usuário **preserva** o colaborador. A **fonte do
     registro** de colaborador é a **feature 06a**. *(Refino 2026-09-23: substitui o vínculo
     editável nas duas telas.)*
  7. **Right-to-erase = ANONIMIZAÇÃO (não hard-delete):** atende o direito ao apagamento (LGPD,
     constitution VIII) por **anonimização do PII** (nome e identificadores diretos), **preservando
     o registro de-identificado** que **SCD-2 (ADR-003)**, **trilha de auditoria (ADR-008)** e
     **cálculo de custo** exigem (hard-delete quebraria integridade financeira/auditoria).
     Campos/política exatos = **[a definir]**.
     **Usuário — divisão 01 × 06d** (refino 2026-09-24): a **desativação** e a **correção de nome e
     e-mail** de usuário ficam com a **feature 06d** (épico E1); a **feature 01 não as entrega**.
     **Não há exclusão de usuário** (refino 2026-10-08): o **Admin** desativa/reativa e corrige nome
     e e-mail, operações reversíveis; o **SuperAdmin** apaga os dados pessoais, operação
     irreversível — o caso reversível, inclusive a recontratação, é atendido pela desativação, e o
     definitivo pelo apagamento; o **usuário desativado continua visível na gestão de usuários**.
     Desativar, reativar e corrigir seguem o **escalonamento do item 4** (refino 2026-10-07): o
     **Admin só age sobre quem pode gerir** — papéis **abaixo do seu** (usuário e manager) —, e
     agir sobre **Admin ou SuperAdmin exige SuperAdmin**. O **SuperAdmin não desativa nem anonimiza
     a si mesmo**, e nenhuma dessas operações atinge o **último SuperAdmin ativo**; o direito ao apagamento do titular SuperAdmin continua atendível — **outro SuperAdmin é
     nomeado antes** e executa a operação. A **feature 01**
     entrega o **mecanismo de anonimização do usuário** — **nome e e-mail no domínio do itallus** e
     **conta no provedor de identidade** —, **sem interface**, que o **executor da feature 06d
     aciona**. Forma concreta do mecanismo = **[a definir no Design da 01]**.
     **Apagamento por pessoa** (refino 2026-10-02): o direito ao apagamento é do **titular-pessoa,
     não do registro** — quando usuário e colaborador são a mesma pessoa, o pedido cobre **todo o PII
     dela** (usuário, colaborador vinculado se houver e PII futura); substitui o recorte anterior de
     usuário e colaborador como titulares distintos com fluxos separados. A **06d é dona de um fluxo
     único de apagamento por pessoa** que **coordena um anonimizador por entidade**: o da **01** para
     o usuário, o da **06a** para o colaborador quando entregue, features futuras plugam o seu. A
     dependência é da **06a em relação à 06d**, não o inverso (refino 2026-10-07): a 06a só pluga o
     seu anonimizador num fluxo que já existe; e, como o **vínculo colaborador↔usuário só passa a
     existir com a 06c**, que depende da 06a, **não ocorre colaborador vinculado e não coberto** pelo
     fluxo. A anonimização tem **dois gatilhos** — **pedido do titular** (LGPD art. 18) e **fim do
     prazo de retenção** —, ambos **executados pelo SuperAdmin**, **sem disparo automático**, e a
     anonimização **desativa o usuário antes de anonimizar**, no mesmo ato. A anonimização **a pedido do titular alcança o
     usuário em qualquer estado** — ativo ou desativado (o registro desativado ainda contém PII): o
     apagamento é obrigação legal que **não depende do estado**, desativar **não encerra** o ciclo, e
     o passo de desativar é **no-op** para quem já está desativado (fluxo idempotente). O **prazo de
     retenção do perfil do usuário** (nome e e-mail no domínio e conta no provedor) **corre a partir
     do fim da finalidade** — o instante da **desativação** (refino 2026-10-08) —, **não da criação
     da conta** (refino 2026-10-07): reativar **zera** a contagem, e o **perfil de usuário ativo
     nunca entra em retenção** nem é anonimizado por fim de prazo; as **trilhas** (auditoria e autenticação do provedor) mantêm o **expurgo por faixa de
     data**. A **LGPD do titular usuário** (incluindo o **mecanismo de retenção** dos dados do usuário e da
     **trilha de auditoria** — janela por classe de dado, expurgo auditado e destino ao vencer, prazos e base
     legal **[a definir]** com responsável nomeado) é da **06d**; o **anonimizador do titular
     colaborador** é da **06a**.
- **Consequências:** + Admin de negócio onboarda pessoas sozinho (TI fora do dia a dia); + fronteira
  de privilégio clara (sem auto-escalonamento); + autorização **desacoplada** do provedor de
  identidade (troca de auth preservada — plugabilidade); − o backend assume gestão de contas
  (convite/reset via Auth Admin API); − a **credencial privilegiada** do Supabase exige **guarda
  server-side** cuidadosa (secret).
- **Alternativas:** modelo de acesso **dentro do Supabase** (rejeitado — não comporta
  departamento/papéis; e Admin de negócio não deve acessar o Supabase); **criação de conta híbrida**
  (TI cria, Admin atribui) — rejeitado (operacionalmente pesado); **hard-delete** para right-to-erase
  — rejeitado (quebra históricos/auditoria/custo); **senha temporária exibida na tela admin** para
  convite/reset — rejeitada (refino 2026-09-23; a senha passaria pelas mãos do Admin).

### ADR-010 — Estratégia de ambientes e deploy (dev local + prod em host único; CI cloud; CD pull-based)
- **Status:** Proposto.
- **Contexto:** a §4 listava genericamente "dev / staging / produção", mas a infra real é
  **uma única VM** (4 núcleos 2,2 GHz · 16 GB RAM · 100 GB, ~31 GB livres + o que a versão
  antiga do itallus libera ao ser aposentada — o novo a substitui). Um stack **Supabase
  self-hosted completo** não é leve (~8–12 containers: Postgres, Auth/GoTrue, Studio, Kong,
  PostgREST, postgres-meta, Realtime, Storage + imgproxy, Edge Functions, Analytics/Logflare
  + Vector). Este ADR **consolida** a topologia que o **ADR-007** já iniciara (docker-compose,
  stub do port ACL, CI, testcontainers) e **acrescenta** o **NetCorp de teste**, o **CD
  pull-based** e a decisão de rodar o **stack Supabase COMPLETO** (não um subconjunto) tanto
  em **dev** quanto em **prod**.
- **Decisão:**
  1. **O host de produção hospeda APENAS produção.** Rodar um 2º stack (qa/staging) *always-on* na mesma VM
     de 16 GB foi **rejeitado** — competiria CPU/RAM com a produção real da diretoria
     (over-engineering e risco; **constitution IX**). **Não há ambiente de qa/staging de
     runtime.**
  2. **Os "ambientes" reais são dois lugares + o CI:**
     - **dev = local** por desenvolvedor, via **docker-compose** rodando o **stack Supabase
       self-hosted COMPLETO** (Postgres real; **NÃO** PocketBase — rejeitado: SQLite + access
       model próprio quebraria a paridade Postgres/RLS, a "mina" do **ADR-006**). Ver ADR-007.
     - **CI = GitHub Actions (nuvem)** — efêmero no runner; roda lint/test/build + **gate de
       drift** do contrato (regenera orval, ADR-005/007) + **testes de RLS via testcontainers**
       (Postgres sobe no próprio runner). É **pipeline, não ambiente** (não sobe o stack
       Supabase completo — só o Postgres que os testes exigem).
     - **prod = o host único** (stack Supabase self-hosted **COMPLETO** + apps).
  6. **Stack Supabase COMPLETO em dev e prod (não um subconjunto mínimo).** Tanto o
     docker-compose de **dev** quanto o **host de produção** sobem o **stack oficial inteiro**
     (Postgres, Auth/GoTrue, Studio, Kong, PostgREST, postgres-meta, Realtime, Storage +
     imgproxy, Edge Functions, Analytics/Logflare + Vector), **não** um recorte mínimo.
     **Motivação:** (a) o painel de observabilidade/monitoramento já era "usar o do Supabase"
     (ADR-009/§8) — com o stack completo o **Studio** fica disponível no ambiente, sem
     ferramenta extra; (b) evita ter que **subir serviços depois** (ex.: **Storage**, já porto
     out no ADR-004, será usado por features futuras — Oportunidade/BID, feature 10); (c)
     **simplicidade operacional** (uma topologia só, **paridade dev↔prod de stack/topologia** — o
     **empacotamento dos apps** é que distingue dev × produção, ADR-011). **Caminho de
     dados da aplicação (topologia fixada):** dentro do stack completo, o Postgres fica **atrás do
     pooler Supavisor** para o **ecossistema interno do Supabase**; a **aplicação não passa pelo
     Supavisor** — a **API é o único componente que acessa o banco** e conecta-se **diretamente à
     instância Postgres**, com **pool próprio**, em migrations e runtime (ADR-006). Remove a
     ambiguidade de qual endpoint a aplicação usa para alcançar o Postgres no self-hosted. **Trade-off de
     custo (constitution IX) — explícito:** o stack completo (~8–12 containers) **divide CPU/RAM
     com os apps na VM de 16 GB**. A preocupação de custo do item 1 **continua válida e não é
     apagada** — ela se aplica a um **2º stack always-on (qa/staging)**, que **permanece
     rejeitado**; rodar **um único** stack completo (o de produção) no host de produção é o trade-off
     **aceito conscientemente** em troca de simplicidade operacional e de não pagar retrabalho
     para subir serviços sob demanda. **Dimensionamento/headroom da VM = `[a monitorar em prod]`**
     (16 GB + o que a versão antiga libera ao ser aposentada); se a pressão de memória se
     confirmar, a mitigação é **desligar containers não usados** (ex.: Edge Functions/Analytics)
     — não voltar a um subconjunto por antecipação.
  3. **"qa" = gate de código, não servidor:** a branch `qa` (fluxo `feature/* → qa → master`)
     é **gate de PR + CI + validação local**; **não** corresponde a um ambiente de runtime.
     **Corrige a §4:** a matriz de ambientes passa a ser **dev + prod** (+ CI como pipeline),
     **sem staging permanente**.
  4. **NetCorp por ambiente — TRÊS alvos atrás do MESMO port ACL** (ADR-001/004),
     selecionados por **config externalizada** (constitution VII), sem tocar o domínio:
     - **stub/fake** (test double do port ACL; dados de amostra fixos, determinístico,
       offline, sem rede/credencial) → usado no **CI** (runner na nuvem **não** tem acesso à
       rede interna) e como **default em dev** (rápido/offline).
     - **NetCorp de teste** = **réplica do banco de produção** do NetCorp, **na rede interna**
       (a máquina de dev a alcança), atualizada **~1×/semana** → usado em **dev** para
       **validação de integração real** (calibrar o ACL contra schema e dados reais),
       especialmente na **feature 02a**. A defasagem de ~1 semana é **irrelevante** (o itallus
       lê via cache local — **ADR-001**). Resolve o risco de a integração real só ser
       exercitada em prod.
     - **NetCorp de produção** (real, read-only) → só em **prod**.

     *(O "stub" do ADR-007 é este test double; convive com o NetCorp de teste — papéis
     distintos: stub p/ testes automáticos/CI, NetCorp de teste p/ validação real em dev.)*
  5. **Deploy = pull-based, via runner self-hosted (decidido no Design da 00):** o **host de
     produção puxa** da `master` (tem **egress**, não **ingress** — coerente com a §4 "sem entrada
     externa"); o GitHub **não** empurra para ele (push-based exigiria ingress — rejeitado).
     **CI na nuvem; CD no host de produção, pull-based.** O **mecanismo = runner self-hosted do GitHub
     Actions no host de produção** (event-driven, postura egress-only — long-poll de saída ao GitHub —,
     dispara o deploy no merge à `master`; um runner self-hosted na rede interna poderia, no
     futuro, rodar os testes de integração NetCorp-teste no CI). **Polling caseiro** (o que
     existe hoje no itallus antigo) foi **rejeitado** (latência + script próprio a manter).
     **O deploy de produção é entregável da feature 00** (não diferido): workflow de
     **CD real** por **pull da imagem versionada** publicada pela CI no **registry** (o host de
     produção **não constrói** — ADR-011) + subida/restart do stack, **secrets de produção
     externalizados no host de produção** (nada
     versionado) e **acesso verificado por VPN/rede interna sem ingress**. O **mecanismo de CD acima
     não muda** — apenas se reconhece que a 00 o entrega operante. **A implantação é REPRODUZÍVEL:**
     é feita **exclusivamente via o provisionamento (item 7) + o runbook (item 8)**, **sem passos
     improvisados** — mesmo critério de "**schema aplicável do zero, sem passo manual**" do
     ADR-006/M0.7. **O deploy tem DUAS METADES, observáveis em momentos distintos** — porque "**está em
     produção**" é fato **pós-merge**, não mensurável antes do PR, e o gate de DoD exige critério
     **medido no momento próprio**. **Só a metade (a) é critério de pronto da feature 00**; a metade
     (b) é **mecanismo entregue pela 00** cuja **medição ocorre depois**:
     - **(a) Prova do mecanismo — ANTES do PR, sobre a APLICAÇÃO:** o **deploy é disparado fora do
       fluxo de merge**, **a partir da definição de pipeline já integrada à linha principal**
       (item 10), **apontando para a revisão da branch da feature** — **a definição habilita; a
       revisão determina o que é implantado**. A prova exige o mesmo de sempre: **o runner atende o
       job → a imagem versionada daquela revisão é puxada do registry (o host não constrói) → o
       stack sobe saudável → as migrações aplicam → o serviço responde**, com **evidência**
       capturada. O deploy assume um
       **ambiente-alvo sem conflitos**; o
       único pré-requisito é **genérico**: as **portas e os nomes de container** exigidos pelo stack
       estão **livres no host-alvo**.
     - **(b) Liveness de produção — entregável E MEDIDA pela 00:** o **mecanismo é entregável da 00**
       — o deploy **confirma a saúde por smoke test pós-deploy** (saúde dos serviços + probe) e
       **reverte automaticamente para a versão imutável anterior** em caso de falha, **sem
       reconstruir** (item 9) — **e é MEDIDO pela própria 00**. A **aplicação implantável da 00 é o
       próprio stack de fundação**: ela **já foi implantada em produção** (reinstalação a frio em
       **2026-09-17**), com o **rollback automático observado disparando**. A premissa original — de
       que a confirmação de que "a versão implantada responde" só seria observável **depois** que uma
       aplicação de negócio mergeasse à linha principal, logo **sob a feature 01** — **envelheceu**: a
       aplicação implantável da 00 é ela mesma, e a implantação real **já ocorreu**. Portanto a
       **liveness pós-deploy** é **MEDIDA sob a 00** (deploys de produção 35136474611/35223484216/
       35227709700 com passo de saúde + smoke test passando). A **execução da reversão pelo artefato**
       (item 9), porém, **permanece NÃO-MEDIDA / em aberto sob a própria 00** — entregue como mecanismo
       (dispara em falha), mas **uma reversão íntegra e saudável nunca foi capturada** (ver item 9);
       **nenhuma** das duas é transferida à feature 01.
  7. **Provisionamento reproduzível do servidor = entregável da 00 (infra-as-code).** Hoje o CD
     **pressupõe o runner já existindo**; falta o requisito de **ENTREGAR os meios de criá-lo**. A
     00 passa a entregar o **provisionamento do servidor de forma reproduzível, idempotente e
     versionada** (postura **infra-as-code**): **bootstrap e registro do runner self-hosted no host
     de produção** + as **demais configs de host** necessárias ao deploy. O componente é **nomeado
     por papel** (`infra/deploy`), **não** pela tecnologia do alvo — o que amarra o repo ao alvo de
     hoje apodrece se o alvo mudar; a identidade concreta do alvo é declarada **uma vez**, no
     contexto/decisão acima. A **forma concreta** (ferramenta/scripts) é **derivada no Design** — a
     visão fixa **o requisito e a postura** (idempotente/versionado; nomeação por papel), **não** a
     implementação.
  8. **Runbook de deploy de produção (`DEPLOY.md`) = entregável da 00.** **Documento de foco único
     e autocontido:** descreve **só** como fazer o deploy e reúne **tudo o que o operador precisa**
     para subir o ambiente **do zero**, cobrindo o caminho **ponta-a-ponta**: **obtenção do código →
     bootstrap (item 7) → configuração externalizada no host (variáveis/segredos) → subida do stack +
     aplicação de migrações → verificação de saúde**. **Pré-requisito concreto:** as **portas e os
     nomes de container** exigidos pelo stack **livres no host-alvo**. O runbook **não** carrega
     **meta-informação** (comparações com outros docs, "X não é Y") nem **escopo de desenvolvimento**
     (prova de mecanismo / validação de DoD do PR) — esse conteúdo mora nos **artefatos de design**
     (DESIGN), não no runbook.
  9. **Rollback = REVERTER PARA O ARTEFATO ANTERIOR, NÃO RECONSTRUIR.** O **rollback automático** do
     item 5(b) **re-implanta a versão imutável anterior a partir do registry** — **sem reconstruir**
     nada. **Reconstruir durante um rollback contraria a prática consolidada** (Humble & Farley;
     Google SRE): é **lento** e pode **falhar por causas novas** (dependência indisponível,
     imagem-base alterada, rede) **justamente quando a produção está quebrada**; o rollback deve
     voltar para um artefato **já construído e testado**.
     - **O registry de imagens é o repositório de artefatos do fluxo de entrega** (ADR-011): a **CI
       publica** a imagem **versionada de forma imutável por versão do código**; a **produção puxa**;
       o **rollback re-puxa/re-implanta a versão anterior**. Sem artefato imutável não há para onde
       reverter.
     - **O estado do deploy é persistido no host de produção:** qual é a **última versão boa
       conhecida** fica registrado **no próprio host**, e é **o que o rollback consulta** para saber
       para onde voltar.
     - **Estado de cada medição:** a **impossibilidade estrutural de construir no passo de
       reversão** — o passo que reverte **não dispõe de construção de imagem**, verificável na própria
       **definição do pipeline** — está **medida sob a 00**. Já a **EXECUÇÃO da reversão** (voltar para
       a versão imutável anterior, lida do estado do deploy persistido no host, **sem reconstruir**)
       **permanece NÃO-MEDIDA / em aberto sob a própria 00**: o mecanismo é entregue pela 00 e
       **dispara em falha**, mas **uma reversão íntegra e saudável nunca foi capturada** — nos deploys
       de produção que passaram (35136474611/35223484216/35227709700) o rollback ficou **skipped** e no
       único em que **disparou** (35218615973) **falhou por resíduo de host, não por defeito do
       mecanismo**; a medição fica **pendente de um exercício real bem-sucedido**. Separar: "o
       mecanismo dispara em falha" (verdade, entregue) ≠ "a reversão foi medida com sucesso" (ainda
       não). A **liveness (item 5b)** segue medida.
     - O **mecanismo de entrega permanece inalterado** (pull-based, runner self-hosted, egress-only,
       sem ingress — item 5), assim como a **rejeição de um 2º ambiente always-on por custo** (item 1).
     - **Forma concreta** (registry concreto, esquema de versão/tag, como o estado é persistido,
       gatilho do rollback) = **derivada no Design** — a visão fixa **a decisão e a postura**.
  10. **A DEFINIÇÃO DO PIPELINE MORA NA LINHA PRINCIPAL — integra-se ANTES de ser exercitada.**
      A **definição do pipeline** (**integração contínua** e **deploy**) é **entregável versionado da
      feature 00** e **entra na linha principal ANTES de ser exercitada**, por **rota própria,
      separada do PR da aplicação**. **Pipeline é código na linha principal**, que **evolui por PR
      como qualquer outro**; uma definição que vive **só numa branch** é **rascunho, não pipeline**.
      **Quem aguarda o PR da feature é a APLICAÇÃO, não o pipeline.** Isso é **fronteira de
      segurança da plataforma**, não preferência: o **disparo manual** só existe para uma definição
      **já na linha principal** — de outra forma **qualquer branch executaria o pipeline com os
      segredos do repositório**, aqui **contra o host de produção**.
      - **Integrar NÃO é exercitar:** a **chegada da definição à linha principal NÃO pode produzir
        deploy de produção** — naquele instante a linha principal **ainda não tem aplicação** nem a
        **referência de última versão boa** a que reverter (item 9).
      - **O que falsifica isso é PROVA DE ORIGEM — NENHUMA EXECUÇÃO DE DEPLOY CHEGA A SER CRIADA:**
        a **integração ocorreu** e o **registro de execuções do pipeline logo após ela NÃO exibe
        execução de deploy alguma**, com **evidência** capturada. **Não basta** que a execução **não
        tenha implantado**: essa redação é satisfeita por uma implementação que **cria a execução e a
        interrompe internamente**, sem implantar nada — e essa execução **aparece no registro**,
        obrigando quem lê a **interpretar** em vez de **observar**. **Ausência de execução é fato;
        presença interrompida é interpretação.** **Afirmar a intenção do gatilho não satisfaz** —
        convive com um pipeline que **disparou**.
      - **Gates de integração contínua no PR que integra a definição — exceção declarada e aceita:**
        nesse PR a **aplicação ainda não está na linha principal**, então os gates que **a verificam**
        **não têm objeto** e **não são executados**. Duas **condições**: (1) o **job sem fonte fica
        visivelmente NÃO-EXECUTADO**, **nunca reportado como aprovado** — uma exceção que se deixasse
        confundir com aprovação seria **pior do que não ter gate**, pois **certificaria como
        verificado o que ninguém verificou**; (2) **assim que a aplicação existe na linha principal**,
        os gates **voltam a ser exigidos em TODO PR, sem exceção** (ver ADR-007).
      - **Ordenação resultante:** definição do pipeline **integrada** → **prova do mecanismo** sobre
        a **revisão da branch** (item 5a — **critério de pronto da 00**) → **liveness pós-deploy**
        (item 5b — **entregue E MEDIDA pela 00**) e **execução da reversão pelo artefato** (item 9 —
        **entregue como mecanismo pela 00, porém ainda NÃO-MEDIDA / em aberto sob a 00**), pois a
        aplicação implantável da 00 é o próprio stack de fundação, já implantado em produção.
- **Consequências:** + simplicidade e segurança em 16 GB (qa não disputa recurso com prod);
  + integração NetCorp real validada **desde o dev** contra a réplica de teste (mitiga o
  maior risco do projeto sem ambiente extra); + plugabilidade do port ACL paga (stub/teste/
  prod por config); − **sem ambiente de homologação permanente** idêntico a prod (mitigado
  pela paridade docker-compose/testcontainers e pelo NetCorp de teste); − CD pull-based via
  runner self-hosted exige **manter o runner registrado/atualizado no host de produção**; + stack Supabase
  completo dá **Studio (observabilidade) e Storage prontos** no ambiente, sem subir serviço
  depois e com **paridade dev↔prod de stack/topologia** (o **empacotamento dos apps** distingue dev ×
  produção — ADR-011); − o stack completo (~8–12 containers) **consome
  CPU/RAM** dividindo com os apps na VM de 16 GB (trade-off aceito — constitution IX; headroom
  a monitorar em prod, mitigação = desligar containers não usados se preciso); + a 00 entrega os
  **meios reproduzíveis** de provisionar/implantar (**runner criável, não pressuposto** — item 7)
  e um **runbook** de deploy do zero (item 8), e o deploy vira **mensurável no momento próprio** — o
  **mecanismo** é medido **pré-PR** (critério de pronto da 00) e a **liveness pós-deploy** também é
  **medida sob a 00** — a aplicação implantável da 00 é o próprio stack de fundação, **já implantado em
  produção** (reinstalação a frio em 2026-09-17) —, **destravando o gate de DoD**;
  + a **feature 00 entrega** os mecanismos (smoke test + rollback automático) e **mede a liveness
  pós-deploy** — a medição **não depende** de uma aplicação de negócio mergear, pois a implantação
  real da fundação **já ocorreu**; a **execução da reversão pelo artefato** segue **entregue como
  mecanismo, porém ainda não medida com sucesso** (pendente de um exercício real bem-sucedido, sob a
  00); + **rollback rápido e determinístico** — volta para um artefato **já construído e
  testado**, **sem reconstruir sob incidente** (item 9); + o **build sai do host de produção** (poupa
  CPU/RAM do host — coerente com o trade-off dos 16 GB); − o **registry** entra no **caminho de
  deploy/rollback** (nova superfície: disponibilidade por egress, autenticação, retenção das imagens);
  − o **estado do deploy** (última versão boa conhecida) passa a ser **persistido e gerido no host**;
  − **rollback automático** e **provisionamento idempotente**
  adicionam superfície a manter; + a **prova do mecanismo pré-PR torna-se satisfazível** — a
  definição já integrada **habilita o disparo**, e a **revisão da branch** determina **o que é
  implantado** (item 10); − a **definição do pipeline passa a ter ciclo de vida próprio** (rota de
  integração separada da aplicação, com o **cuidado de integrar sem implantar** — falsificado por
  **prova de origem**: **nenhuma execução de deploy criada**); − o **PR que integra a definição corre
  com gates sem objeto** (a aplicação ainda não está na linha principal), aceito **apenas** sob
  **não-execução visível** e **retomada obrigatória dos gates em todo PR** assim que a aplicação
  existir na linha principal (item 10 / ADR-007).
- **Alternativas:** **subconjunto mínimo** do Supabase (só Postgres + Auth/GoTrue + Kong/
  PostgREST) no host de produção (preterido — exigiria subir Studio/Storage/etc. depois, quebrando a
  simplicidade e a paridade; o ganho de RAM não compensa o retrabalho); 2º stack qa *always-on*
  no host de produção (rejeitado — recurso/risco); **PocketBase**
  em dev (rejeitado — quebra paridade Postgres/RLS, ADR-006); deploy **push-based** GitHub→host de produção
  (rejeitado — exige ingress); estrear NetCorp real **só em prod** (rejeitado — risco;
  resolvido pelo NetCorp de teste); **deploy por passos manuais/improvisados** (rejeitado — não
  reproduzível, fere o critério "do zero sem passo manual"); **runner pressuposto** (sem entregar os
  meios de provisioná-lo) — rejeitado, o CD ficaria dependente de setup fora do repo; **medir o
  deploy só no PR/pós-merge** sem prova de mecanismo pré-PR (rejeitado — deixaria o critério
  **não-medido** no gate que precede o PR); **rollback que RECONSTRÓI a versão anterior no host**
  (rejeitado — reconstruir é **lento** e pode **falhar por causas novas** — dependência indisponível,
  imagem-base alterada, rede — **justamente com a produção quebrada**; contraria a prática consolidada
  (Humble & Farley; Google SRE) de **reverter para um artefato já construído e testado**);
  **construir a imagem no host de produção** (rejeitado — ver ADR-011: consome recursos do host e faz
  a produção rodar um artefato **não validado pela CI**, sem **artefato imutável** para onde reverter);
  **exercitar o pipeline a partir de uma definição que só existe na branch da feature** (rejeitado —
  **insatisfazível na plataforma**: o disparo manual só existe para definição **já na linha
  principal**; admiti-lo significaria **qualquer branch executando o pipeline com os segredos do
  repositório** contra o host de produção — item 10); **manter a definição do pipeline fora do
  versionamento/da linha principal até o merge da feature** (rejeitado — seria **rascunho, não
  pipeline**, e adiaria para depois do PR justamente a prova que o gate exige **antes** dele);
  **integrar a definição do pipeline deixando-a implantar produção nesse instante** (rejeitado — a
  linha principal ainda **não tem aplicação** nem **versão boa anterior** para onde reverter);
  **satisfazer-se com uma execução de deploy CRIADA e interrompida internamente** na integração
  (rejeitado — a execução **aparece no registro** e obriga a **interpretar**; só a **ausência de
  execução** é **fato observável** — item 10); **reportar como APROVADOS, no PR que integra a
  definição, os gates que não têm o que verificar** (rejeitado — **certificaria como verificado o que
  ninguém verificou**, pior do que não ter gate; a exceção só existe como **não-execução visível** —
  item 10/ADR-007); **manter a LIVENESS PÓS-MERGE como critério de pronto da feature 00** (rejeitado —
  **insatisfazível na ordem do fluxo**: só é observável **depois do merge**, portanto **depois do gate
  que a exige**; ficaria **permanentemente não-medida** — item 5b).
- **Cross-ref:** ADR-001 (NetCorp read-only/cache — torna a defasagem da réplica irrelevante),
  ADR-004 (port ACL/monorepo/host único), ADR-006 (Postgres/RLS — porquê não PocketBase; **critério
  "do zero sem passo manual"** = M0.7), ADR-007 (docker-compose/stub/CI/testcontainers —
  **consolidado**, não duplicado; **CI exercitável pré-PR** = mesma lógica de evidência pré-PR e
  **mesma condição habilitante** — definição de CI **já integrada à linha principal**, item 10),
  ADR-011 (**empacotamento**: a CI publica a **imagem versionada** no **registry** — artefato que a
  produção **puxa** e para onde o **rollback reverte**).

### ADR-011 — Empacotamento: aplicação containerizada + `docker-compose` raiz único; **dev constrói, produção roda imagem versionada**
- **Status:** Proposto.
- **Contexto:** o **ADR-007/010** fixou o **stack Supabase self-hosted completo** via
  docker-compose e o **caminho de dados** (a API acessa o Postgres direto, fora do Supavisor —
  **ADR-006**), mas **não** fixou **como os apps (`api`/`web`) são empacotados e executados**, nem
  se dev e prod compartilham **um único** orquestrador. Rodar `api`/`web` **direto no host**
  quebraria a paridade dev↔prod, exigiria toolchain (Python/uv, Node) instalada em cada máquina e
  no host de produção, e fragmentaria o sobe/derruba do projeto. Ademais, o `web` (Next.js) executa o **mesmo
  código no navegador e server-side** (middleware/route handlers no container) e faz **chamadas de
  Auth ao Supabase nos dois contextos** — cujo **caminho de rede difere** (host publicado × rede
  interna do compose) e ainda não estava distinguido. **Faltava ainda distinguir DEV de PRODUÇÃO no
  empacotamento:** o mesmo compose de serviço **montava o código-fonte e rodava em modo de recarga
  automática**, e **o build acontecia no host de produção** — o que consome os recursos do host, faz a
  produção rodar um artefato **que não é o validado na CI** e **não deixa artefato imutável** para
  onde reverter (rollback — ADR-010).
- **Decisão:**
  1. **Aplicação 100% containerizada.** `api` (FastAPI), `web` (Next.js) e **qualquer** componente
     rodam **exclusivamente como containers Docker** — **nunca direto no host** (nem em dev, nem em
     prod). O host só provê Docker.
     - **O que "componente" significa nesta regra — fronteira normativa, válida para TODAS as
       features:** **componente = serviço da aplicação em RUNTIME** — a **`api`**, o **`web`** e o
       **stack**. É a esses que a proibição de "rodar direto no host" se aplica.
     - **O ferramental de VERIFICAÇÃO não é serviço de runtime** e **não está sob a proibição**:
       **suíte de testes**, **verificadores de repositório** e **geração do client tipado** rodam no
       **host de desenvolvimento** e no **runner da integração contínua** (ADR-007) — onde o
       repositório inteiro coexiste. Com o compose **per-service** (item 2), o container de cada
       serviço monta **só o próprio código**, de modo que verificação que **cruza serviços** não teria
       sequer o que ler dentro de um container de serviço único.
     - A fronteira é **definida aqui uma vez** e vale para **todas as features**, não só para a 00.
  2. **Um `docker-compose` na raiz orquestra o projeto inteiro via `include`.** O compose da raiz é
     um **orquestrador**: faz **`include`** do compose de **cada serviço** — **`apps/api/docker-compose.yml`**
     e **`apps/web/docker-compose.yml`** (cada app descreve o **próprio serviço**) — **mais o compose
     do stack Supabase self-hosted completo** (ADR-010). A raiz **não descreve `api`/`web` inline**. Com
     **um comando**, o `up` na raiz sobe/derruba o **projeto completo** (stack Supabase **+ `api` + `web`**).
     Vale **em dev e em produção** — mesma topologia, **empacotamento distinto** (item 5).
  3. **`api` → Postgres na rede do compose.** A `api` conecta ao Postgres **diretamente pelo
     serviço `db`** na rede do compose (pool próprio, migrations e runtime), **sem** passar pelo
     **Supavisor** — que serve só o ecossistema interno do Supabase (ADR-006/010).
  4. **`web`: caminho interno das chamadas de Auth (server-side × navegador).** O `web` (Next.js)
     executa o **mesmo código em dois contextos** — no **navegador** e **server-side** (middleware e
     route/server handlers rodando **dentro do container**) — e faz **chamadas de Auth ao Supabase**
     nos dois. As chamadas **server-side** alcançam o **gateway do stack (Kong) pela rede interna do
     compose (nome de serviço)**, **não** pela **URL publicada no host** que o **navegador** usa —
     **mesmo princípio** do caminho de dados interno da `api`→Postgres (item 3 / ADR-006). Logo, a
     **config externalizada do `web` distingue a URL do Supabase voltada ao navegador da URL interna
     usada server-side** (dois valores; constitution VII).
  5. **Dev × produção explícitos no empacotamento — o compose base é DEV; produção é uma sobreposição
     com imagem versionada.**
     - **DEV = compose base:** os composes de serviço descrevem o **perfil de desenvolvimento** —
       **constroem a imagem localmente**, **montam a fonte** e rodam com **recarga automática**.
     - **PRODUÇÃO = sobreposição:** uma **sobreposição de produção** **substitui** isso pela **imagem
       versionada** — **sem montagem de fonte** e **sem recarga**. Continua valendo **um comando** para
       o **projeto inteiro** (item 2); o que muda é **de onde vem a imagem**.
     - **A CI PUBLICA as imagens de aplicação num REGISTRY DE IMAGENS**, **versionadas de forma
       imutável por versão do código** (ADR-007).
     - **PRODUÇÃO PUXA a imagem já construída do registry — NÃO CONSTRÓI NADA NO HOST.** Coerente com
       a postura **pull-based / egress-only** já decidida (ADR-010: o runner no host de produção
       **puxa** a imagem e sobe/reinicia o stack).
     - **Racional:** a **imagem validada na CI é exatamente a que sobe em produção** (fim do "funciona
       no meu host"); o **build sai do host de produção**, poupando seus recursos; e passa a existir um
       **artefato imutável para onde reverter** — base do **rollback** do **ADR-010** (item 9).
     - **Forma concreta** (registry concreto, esquema de versão/tag, layout da sobreposição) =
       **derivada no Design** — a visão fixa **a decisão e a postura**.
- **Consequências:** + um comando sobe todo o projeto; + **paridade dev↔prod de topologia** (mesmo
  stack, mesma orquestração) e **fim do "funciona no meu host"** — a **imagem validada na CI é a que
  roda em produção**; + host sem toolchain de app (só Docker); + **produção não constrói** (o build sai
  do host, poupando CPU/RAM/disco — coerente com o trade-off dos 16 GB, ADR-010); + **artefato imutável
  por versão** habilita o **rollback por re-implantação** (ADR-010 item 9); + CD pull-based simples
  (puxa a imagem + sobe);
  + cada app é **dono do próprio compose** (coeso; a raiz só orquestra via `include`);
  + a fronteira do item 1 é **explícita** — só **serviços de runtime** são containerizados, e o
  **ferramental de verificação** roda no **host de dev / runner da CI**, onde o repositório inteiro
  coexiste (verificação que cruza serviços não caberia num container de serviço único);
  − imagens/compose a manter para os dois apps, agora com **dois perfis** (dev × produção);
  − o **registry** vira **dependência do caminho de deploy** (disponibilidade por egress, autenticação,
  retenção); − hot-reload em dev exige montagem de fonte + watch
  dentro do container; + as chamadas de Auth **server-side** do `web` usam a **rede do compose**
  (independem de resolução/publicação de host); − a **config do `web`** ganha um **segundo endpoint
  do Supabase** (interno server-side) além do voltado ao navegador.
- **Alternativas:** **rodar `api`/`web` direto no host** (rejeitado — quebra paridade dev↔prod,
  exige toolchain no host e fragmenta o sobe/derruba); **composes por app SEM orquestrador raiz**
  (rejeitado — exigiria **vários comandos**, perde o "um comando p/ o projeto todo" e a topologia
  única). *(A orquestração via `include` **não** é a alternativa rejeitada — é a própria decisão.)*
  **Construir a imagem no host de produção** (rejeitado — consome os recursos do host; produção
  passaria a rodar um artefato **que não é o validado na CI**; e **não sobra artefato imutável** para o
  rollback — ADR-010 item 9). **Um único perfil de compose para dev e produção** (rejeitado — levaria
  **montagem de fonte e recarga automática** para produção, e o build para o host).
- **Cross-ref:** ADR-004 (monorepo `apps/api`+`apps/web`), ADR-006 (caminho de dados / Supavisor
  fora), ADR-007 (CI — **publica as imagens versionadas**; **casa do ferramental de verificação**, que
  a fronteira do item 1 mantém no **host de dev** e no **runner da CI**), ADR-010 (stack completo / CD
  pull-based / **rollback pelo artefato imutável**), ADR-009 (fronteira auth — chamadas de Auth do
  `web`).

---

## 10. Risk Assessment

| Risco | Impacto | Probab. | Mitigação |
|-------|---------|---------|-----------|
| **NetCorp sem documentação** (schema/regras obscuros) | ALTO | ALTA | Descoberta guiada por amostras; ACL isolando o legado; validar campo a campo com a área; **calibrar o ACL contra o NetCorp de teste** (réplica de prod, rede interna) **desde o dev** — integração real exercitada antes de prod (ADR-010). |
| **Sincronização NetCorp** (frescor do cache; duplicidade) | ALTO | MÉDIA | Estratégia decidida = **cache/replicação local** (job → espelho); definir **frequência/reconciliação** de cada carga (Clientes na feature 02a; catálogo de CR na 02b); idempotência (constitution IV). |
| **Requisitos imaturos** (PCR, contrato op., BID, Faturamento, Logística) | MÉDIO | ALTA | Manter "**a definir**"; entregar incremental; não modelar o que não está claro. |
| **Plugabilidade ampla → over-engineering** | MÉDIO | MÉDIA | Aplicar ports/adapters onde há troca plausível (auth/banco/NetCorp); **avaliar custo** antes de generalizar tudo (requisito pede). |
| **Acesso por departamento incompleto** (vazamento entre departamentos/áreas) | ALTO | MÉDIA | RLS + **mecanismo identidade→RLS** (role não-privilegiado + claims propagados pelo trilho da 00, policy lendo só o `sub`; escopo — inclusive o global — decidido na policy por `EXISTS` indexado sobre a tabela, ADR-002/006) + **testes de isolamento com Postgres real (testcontainers, ADR-007)**; gate de segurança (constitution V). |
| **Cálculo de custo incorreto** (skill/SPC vigente errada; arredondamento) | ALTO | MÉDIA | SCD-2 + **testes point-in-time (ADR-007)** + **`Decimal`/`NUMERIC` (ADR-006)**; fechamento idempotente e reprodutível. |
| **LGPD em colaboradores** (PII) | ALTO | MÉDIA | Mapa de dados, retenção, apagamento/anonimização desde a v1 (constitution VIII). |
| **Shell expõe todas as áreas antes do 01** | BAIXO | MÉDIA | Páginas de departamento na v1 **sem dado de negócio real** (placeholder de conteúdo, tela acabada no padrão); entregar 01 antes de qualquer dado real (02+). |
| **CD pull-based — operação do runner self-hosted** | BAIXO | MÉDIA | Mecanismo **decidido** = runner self-hosted no host de produção (event-driven, egress-only); **runner provisionado de forma reproduzível/idempotente** (infra-as-code — deixa de ser pressuposto) + **runbook `DEPLOY.md`**; mecanismo **provado pré-PR** (com evidência, a partir da **definição já integrada à linha principal**, apontando para a **revisão da branch**); **liveness pós-deploy com rollback = re-implantação do artefato imutável anterior** (sem reconstruir) é **entregue como mecanismo E medida sob a própria 00** — a aplicação implantável da 00 é o próprio stack de fundação, **já implantado em produção** (reinstalação a frio em 2026-09-17) com o rollback automático observado disparando; latência aceitável p/ sistema interno (ADR-010). |
| **Integrar a definição do pipeline dispara deploy de produção** (linha principal ainda **sem aplicação** e **sem versão boa anterior** para onde reverter) | ALTO | MÉDIA | O gatilho do deploy é **fato verificado, não intenção declarada**: a integração fecha com **prova de origem** — **nenhuma execução de deploy chega a ser criada**, isto é, o **registro de execuções logo após ela não exibe execução de deploy alguma**, com **evidência** capturada. Execução **criada e interrompida** não satisfaz (aparece no registro e obriga a **interpretar**; só a **ausência** é fato) — ADR-010 item 10. |
| **Gate sem objeto lido como aprovação** no PR que integra a definição do pipeline (a aplicação ainda não está na linha principal) | ALTO | MÉDIA | A exceção existe **apenas** como **não-execução visível**: o **job sem fonte nunca é reportado como aprovado** — certificar como verificado o que ninguém verificou é **pior do que não ter gate**; e **assim que a aplicação existe na linha principal** os gates **voltam a ser exigidos em todo PR, sem exceção** (ADR-010 item 10 / ADR-007). |
| **Registry no caminho de deploy/rollback** (produção depende de **obter a imagem**) | MÉDIO | BAIXA | O registry é dependência de **egress** — postura já decidida (sem ingress, com saída); a **imagem imutável por versão** torna a (re)implantação **idempotente**; o **estado do deploy (última versão boa conhecida) persiste no host de produção**, dando ao rollback um **alvo determinado**; **produção nunca constrói** — o insumo é sempre um artefato **já validado na CI** (ADR-010 item 9 / ADR-011 item 5). |

**Contingência:** se a integração NetCorp atrasar/bloquear: a **02a** (conector + Clientes)
bloqueia **03–05b**, **10** e a própria **02b**; a **02b** (catálogo de CR) bloqueia **05a** e
**06a–06b–07**. Como o catálogo **reutiliza o conector da 02a**, não há como antecipá-lo à 02a;
entregue a 02a, priorizar a 02b destrava **06a–06b–07** (pessoas/skills) em paralelo a
**03–04** para manter o fluxo. **06d**, **11a** e **11b** não dependem do NetCorp.

---

## 11. Pontos em aberto

**Do requisito (§14) — manter como a definir:**
- Formato real do **código de skill**.
- Demais informações do **PCR** e do **contrato operacional**.
- Campos do **contrato jurídico** (lista não exaustiva) — mas a **FK ao Grupo** já está
  decidida (CNPJ principal).
- Até onde vai a **plugabilidade** (e sua complexidade) — avaliar feature a feature.
- Magnitude dos **valores ilustrativos**.
- Se o **fluxo do BID** (além da **proposta comercial**) entra agora.

**Levantados neste planejamento (ainda em aberto):**
- **Fator dias→horas** no fechamento mensal.
- **Aprovações** — quais fluxos têm etapa de aprovação (Manager aprova, mas o único caso
  conhecido = ordens de compra). **Não modelar agora.**
- **Frequência/reconciliação** do sync NetCorp (estratégia = **cache local já decidida**).
- Detalhamento dos **3 times comerciais** (sufixos 50/60/70 do centro de resultado).
- **Handoff do BID — fora de escopo na v1 (dependem da TI / controle de domínio):**
  envio automático do e-mail pelo itallus (SMTP/Graph); **anexo automático** dos
  documentos (`mailto:` não suporta anexo); **captura de respostas/histórico do thread**.
  Justificativa: enviar como `@dominio-corporativo` exige SPF/DKIM/DMARC = controle de
  domínio (TI); receber respostas exige caixa compartilhada lida via IMAP/Graph (TI). Ter
  saída para internet **não** resolve identidade corporativa nem recebimento.

**Decididos neste refino (não mais abertos):** Framework JS (**Next.js**); Framework
backend (**FastAPI + SQLModel**); estratégia de sync NetCorp (**cache/replicação local**);
**Departamento → FK Centro de Resultado NetCorp** (com sufixos 50/60/70); **Contrato
Jurídico → FK Grupo (CNPJ principal)**; **acesso por departamento** com 4 papéis;
**00 e 01 separados**; **handoff do BID sem escrita no NetCorp** (status local + `mailto:`);
**catálogo de CR (`tbcencus`) = dado-mestre na feature 02** (id 6 dígitos; classificação
interno/suporte-pré-venda/projeto vinda da fonte; só CR de projeto tem PCR); FK
**Departamento → CR interno** consome o catálogo da 02 (06 volta a ser paralela a 03–05);
**modelo concreto de áreas/departamentos fixado (3 áreas / 7 departamentos)** —
`supply-chain-management` › `logistics`/`imports`/`partnerships`/`bid`; `finance` ›
`procurement`; `planning` › `contracts`/`invoicing` (`procurement` e `contracts` novos no
catálogo) — a **navegação do shell reflete a hierarquia** (áreas expandindo departamentos,
não lista plana) e **acesso/RLS são a nível de departamento** (feature 01).

**Decididos neste refino — estrutura e fluxo (ADR-004/005):**
- **Estrutura = monorepo** `apps/api` (FastAPI/uv, Clean Arch/ports-adapters) + `apps/web`
  (Next.js/Tailwind/shadcn) — **ADR-004**; internos por feature seguem no **Design**.
- **Catálogo de ports/adapters** fixado (ADR-004): SÃO out — persistência, auth, NetCorp,
  EmailSender, Storage de documentos, Clock; NÃO são — logging/métricas/config/validação/
  tradução de erro (facade), adapters de entrada e detalhe interno (ORM/RLS).
- **Contrato front↔back = OpenAPI (FastAPI) → orval** (client + hooks TanStack Query) —
  **ADR-005**; `openapi-typescript` foi avaliado e **preterido** (sem hooks).
- **Design system = ui-ux-pro-max** (skill offline/versionada), Master + Overrides em
  `apps/web/design-system/`; **`frontend-design@claude-plugins-official` excluído**
  explicitamente (um só "cérebro" de design). **Padrão-alvo = SaaS/ERP corporativo moderno
  para uso interno diário** (sóbrio/baixo ruído/minimalista; **vedados** marketing/conversão
  e gradientes "AI" roxo/rosa); brief = **plataforma operacional multi-módulo** (não "Analytics
  Dashboard"). **Marca restrita a CORES + LOGOTIPO** (`docs/brand-identity/`) — **tipografia e
  iconografia NÃO vinculadas à marca** (revoga a ancoragem tipográfica anterior). **Requisitos
  transversais de UI** no design system: stepper/pipeline de status (fluxos lineares pós-venda),
  tabelas densas server-side, anexo/preview de documentos, trilha de auditoria; **variação por
  área** (BID = funil/comparação, ver feature 10). **v1 (login + casca) realiza integralmente o
  padrão** (estados/movimento/contraste/foco em todas as telas); **responsividade = alvo por tela**
  (login ≥375px; casca autenticada ≥768px — abaixo de 768px na casca = fora de suporte v1, quebra
  aceita). Ver ADR-005 (refinos 2026-06-30 e 2026-07-09).
- **Tema da UI:** **light na v1; dark mode diferido** (não-v1) — o design system **reserva os
  tokens** para não retrabalhar quando o dark entrar (clarificação 2026-06-24; ver ADR-005).
- **Observabilidade:** **structlog desde a v1**; **OpenTelemetry posterior**.
- **Fluxo AgentSpec por feature:** ponta a ponta, backend-first, o **Design** mapeia
  endpoints↔telas; **feature 00** monta o esqueleto + pipeline OpenAPI→orval + gera o
  `MASTER.md` (1×).

**Decididos neste refino — data layer, dev/CI e contrato (ADR-006/007/008):**
- **Data layer = FastAPI + SQLModel + Alembic** (ADR-006): SQLModel define tabelas; **Alembic
  versiona schema** (autogenerate) e **as policies de RLS vivem nas migrações** (schema+RLS
  juntos por feature). Resolve a [hipótese] de "migrações versionadas" do PRD 00.
- **Mecanismo identidade→RLS** (ADR-006): **trilho fixado na 00** = conexão com **role
  não-privilegiado `itallus_app`** (nunca `service_role`) + **propagação dos claims por
  transação** via `set_config('request.jwt.claims', …, true)`. As **policies concretas por
  tabela** ficam `[a definir no Design da feature 01]`. Coerente com ADR-002 (tabela é a
  verdade; `app_metadata` segue [a avaliar] só p/ performance). **Refino 2026-09-23 (brainstorm
  da 01):** a 01 **reaproveita o trilho da 00 sem alterá-lo** — a API segue propagando o JSON
  completo dos claims, **sem canal novo dedicado ao `user_id`**, e a policy lê **só o `sub`**
  (`current_setting('request.jwt.claims', true)::jsonb ->> 'sub'`); a policy decide o escopo por
  `EXISTS`/`JOIN` em `department_access`/`role_permission` para **todos** os papéis; o **escopo
  global** de Admin/SuperAdmin = **permissão explícita de escopo global** em `role_permission`, no
  mesmo `EXISTS` (não por papel propagado); **índice** cobre o `EXISTS`/`JOIN`. Rejeitados: propagar
  escopo/papel resolvido pela API; propagar papel via `SET LOCAL`; `SET LOCAL app.user_id` novo,
  paralelo ao trilho da 00; restringir o trilho da 00 para propagar só o `user_id`; inflar
  `department_access` para Admin/SuperAdmin; `SECURITY DEFINER`/role com `BYPASSRLS`.
- **Valores = `Decimal`/`NUMERIC`/string-JSON, nunca `float`** (ADR-006) — cascata aos PRDs
  03, 04, 05, 07, 08, 09, 12 (e percentuais na 11).
- **Caminho de dados / endpoint do Postgres** (ADR-006/010, refino 2026-06-30): a **API é o
  único componente que acessa o banco**, **gerencia o próprio pool** e conecta-se **diretamente à
  instância Postgres** (migrations Alembic **e** runtime), com o **role não-privilegiado
  `itallus_app`** + propagação de claims já fixados. O **Supavisor** (pooler do stack self-hosted)
  atende ao **ecossistema interno do Supabase** e **não está no caminho de dados da aplicação** —
  remove a ambiguidade de qual endpoint a aplicação usa no self-hosted.
- **Dev/CI** (ADR-007): **docker-compose** local; **stub do NetCorp** (impl. de teste do port
  ACL); **CI em PR** = lint + testes + build + **gate de drift OpenAPI→orval** (concretiza
  M0.5/RNF0.7 da 00); **pytest + testcontainers** (RLS real) + **point-in-time** (SCD-2);
  **Vitest** no frontend.
- **Convenções de API + auditoria** (ADR-008): **paginação cursor** (limit default 50, máx 200),
  **envelope de erro único** `{error:{code,message,details[]?,request_id}}`,
  versionamento — decididos 1× na 00 e herdados; **filtro/ordenação NÃO** entra na 00 (catálogo
  estático), fica p/ a **1ª lista filtrável real (feature 02+)**; **tabela de auditoria de uso/operações
  sensíveis** (PII de colaboradores + valores; LGPD = um dos drivers).

**Decididos neste refino — ciclo de vida de usuário e administração (ADR-009):**
- **Fronteira auth × authz:** Supabase Auth = **só autenticação** (identidade/login/senha/JWT);
  **autorização** (`department_access` + papel, RLS) = **domínio do itallus** — o Supabase não
  comporta o modelo de acesso (departamento/hierarquia/4 papéis).
- **Dois planos de administração:** **Admin** (negócio) opera **100% no itallus** (nunca o
  Supabase Studio); **SuperAdmin** (técnico) = **único** com acesso ao Supabase Studio/infra.
- **Criação de usuário = dentro do itallus, sem híbrido:** Admin cria/convida na tela admin
  (atribui **departamento+papel**); o backend cria a conta no
  Supabase **server-side via Auth Admin API** com **credencial privilegiada server-side**,
  **distinta** da conexão de dados (role não-privilegiado/RLS — ADR-006). **Sem self-signup.**
- **Papéis cumulativos + escalonamento:** `usuário ⊂ manager ⊂ admin ⊂ superadmin` (Admin faz
  tudo do Manager em escopo **global** + gestão de acessos); **Admin concede usuário/manager**,
  **só SuperAdmin concede admin/superadmin** (sem auto-elevação).
- **Vínculo usuário↔colaborador** (refino 2026-09-23, substitui "editável nas duas telas"):
  **editável somente na tela admin de gestão de usuário**; na edição de colaborador, **somente
  leitura** (em branco sem vínculo). A opção de vincular na gestão de usuário é **diferida para a
  06**, como **melhoria dessa tela**; **fonte** do colaborador = **06**.
- **Right-to-erase = anonimização** do PII (não hard-delete; preserva registro de-identificado p/
  SCD-2/auditoria/custo); **casa do PII = 06**, **executor = SuperAdmin**.
- **Convite/reset = link de uso único** (refino 2026-09-23, brainstorm da 01): token do backend,
  uso único, expiração curta, invalidado ao usar ou ao reemitir; exibido na tela admin, sem e-mail;
  mesmo mecanismo para convite e reset; o usuário define a própria senha. Rota **"definir senha"** =
  exceção explícita ao guard de sessão da 00, sem abrir as demais rotas (sem sessão, só o consumo
  do token). **Senha temporária exibida na tela admin = rejeitada.**
- **Fora do escopo da 01** (refino 2026-09-23): CRUD de papéis/permissões pela UI; reenvio de
  convite como mecanismo à parte do reset; desfazer ("undo") de edição de usuário; 2FA.
- **Desativação, exclusão e correção de nome/e-mail de usuário = feature 06** (refino 2026-09-24,
  ADR-009 item 7): a 06 já pressupõe bloqueio e remoção lógica de usuário; a **01 não as entrega**.
  A **01 entrega o mecanismo de anonimização do usuário** (nome e e-mail no domínio do itallus +
  conta no provedor de identidade), **sem interface**, acionado pelo executor da 06.
- **Leitura da trilha de auditoria** (refino 2026-09-24, ADR-008): **integral para o SuperAdmin**,
  **restrita às próprias ações** para os demais usuários; a **consulta pela interface não pertence
  à 01**.

**Decididos neste refino — estratégia de ambientes e deploy (ADR-010):**
- **Topologia = dev (local) + prod (host único) + CI (pipeline)**; o host de produção hospeda **APENAS
  produção** — **sem staging/qa de runtime** (rodar um 2º stack na VM de 16 GB foi rejeitado:
  custo/risco — constitution IX). A branch `qa` é **gate de código**, não servidor. **Corrige
  a §4** (que dizia "dev/staging/produção").
- **dev = docker-compose** (Postgres real); **PocketBase rejeitado** (SQLite/access model
  próprio quebraria a paridade Postgres/RLS do ADR-006).
- **CI = GitHub Actions (nuvem)** — **pipeline, não ambiente**: gate de drift do contrato +
  **RLS via testcontainers** no runner.
- **NetCorp = 3 alvos por config externalizada** atrás do mesmo port ACL (ADR-001/004):
  **stub** (CI + default dev) · **NetCorp de teste** (réplica de prod, rede interna,
  ~1×/semana → validação de integração real em dev, esp. feature 02) · **NetCorp de
  produção** (read-only, só prod). A defasagem da réplica é **irrelevante** (runtime lê o
  cache local — ADR-001).
- **CD = pull-based** (princípio fixado): o **host de produção puxa** da `master` (egress; sem ingress);
  GitHub não empurra. **Mecanismo = runner self-hosted do GitHub Actions no host de produção**
  (event-driven, egress-only, dispara no merge à `master`); **polling caseiro rejeitado**.
- **Deploy de produção = entregável da feature 00** (refino 2026-07-01): a v1 é **implantada no
  host de produção** por **CD real** pull-based (mecanismo inalterado), com **secrets de
  produção externalizados no host de produção** (nada versionado) e **acesso verificado por VPN/rede interna sem
  ingress**. Reconcilia a contradição do PRD 00 (§1/M0.1 "v1 em produção" vs. Fora-de-escopo, que
  diferia secrets/deploy de prod); a **gestão de secrets de prod deixa de ser diferida**.
- **Handoff de deploy entregue pela 00 — provisionamento + runbook** (refino 2026-07-10): entram
  como **entregáveis da 00** o **provisionamento reproduzível do servidor** (infra-as-code,
  **idempotente e versionado**, **nomeado por papel** — `infra/deploy`, não pela tecnologia do alvo —,
  incluindo **bootstrap/registro do runner self-hosted no host de produção** + configs de host; o
  runner deixa de ser **pressuposto** e passa a ser **criável** pelos meios entregues) e o **runbook de
  deploy de produção (`DEPLOY.md`)** — **documento de foco único e autocontido** (reúne tudo o que o
  operador precisa; pré-requisito concreto = portas/nomes de container livres no host-alvo; sem
  meta-informação nem escopo de desenvolvimento), cobrindo o caminho ponta-a-ponta (código → bootstrap
  → config/segredos no host → stack + migrações → verificação de saúde).
- **Deploy de produção reproduzível e mensurável no momento próprio** (refino 2026-07-10; metade (b)
  revista em **2026-07-27**, abaixo): a
  implantação é feita **exclusivamente via o provisionamento + runbook** (sem passos improvisados —
  mesmo critério "do zero sem passo manual" de M0.7). Como "**está em produção**" é fato **pós-merge**,
  o critério tem **duas metades** observáveis em momentos distintos: **(a) mecanismo** — o deploy é
  **disparado fora do fluxo de merge, antes do PR** (ordenação refinada em **2026-07-27**, abaixo),
  implanta no host de produção e prova
  runner→stack saudável→migrações→serviço, **com evidência** — **esta é a metade que constitui
  critério de pronto da 00**; **(b) liveness pós-merge** — implantação
  real na `master` confirmada por **smoke test pós-deploy** (saúde + probe) com **rollback automático**
  em falha — **entregue como mecanismo pela 00**, porém **medida fora dela** (ver o refino de
  2026-07-27). O deploy assume um **ambiente-alvo sem conflitos** (único pré-requisito genérico: **portas
  e nomes de container livres no host-alvo**). Torna cada critério **medível no momento próprio**,
  destravando o gate de DoD.
- **CI exercitável antes do PR** (refino 2026-07-10; condição habilitante declarada em 2026-07-27):
  além de rodar em **PR**, o pipeline
  de CI (gate de drift de contrato + **RLS via testcontainers** em Postgres real) é **disparável fora
  de `pull_request`** **sobre a revisão da branch**, dando **evidência ao vivo** desses critérios
  **antes** da abertura do PR. A evidência **repousa sobre a definição de CI já integrada à linha
  principal** (ver o refino de **2026-07-27**) — a definição **habilita**; a **revisão** determina
  **o que é verificado**.
- **A definição do pipeline mora na linha principal — integra-se antes de ser exercitada** (refino
  2026-07-27; **ADR-010 item 10**): a **definição do pipeline** (**CI + deploy**) é **entregável
  versionado da feature 00** e **entra na linha principal ANTES de ser exercitada**, por **rota
  própria, separada do PR da aplicação**, **evoluindo por PR como qualquer código**; definição que
  vive **só numa branch** é **rascunho, não pipeline**, e **quem aguarda o PR da feature é a
  aplicação**. É **fronteira de segurança da plataforma**: o **disparo manual** só existe para
  definição **já na linha principal** — de outra forma **qualquer branch executaria o pipeline com os
  segredos do repositório**, contra o host de produção. **A prova do mecanismo segue sendo gate ANTES
  do PR e recai sobre a aplicação:** o deploy é **disparado fora do fluxo de merge, a partir da
  definição já integrada**, **apontando para a revisão da branch da feature** (**a definição habilita;
  a revisão determina o que é implantado**); **o que a prova exige não muda** (runner atende → imagem
  daquela versão puxada do registry sem o host construir → stack saudável → migrações aplicam →
  serviço responde, com **evidência**). **Integrar não é exercitar:** a chegada da definição à linha
  principal **não pode produzir deploy de produção** (ali ainda não há aplicação nem **última versão
  boa** para onde reverter) — falsificado por **prova de origem** (**precisão refinada em 2026-07-27**,
  abaixo): a integração ocorreu e o **registro
  de execuções do pipeline logo após ela não exibe execução de deploy alguma**, com **evidência**;
  **afirmar a intenção do gatilho não satisfaz** (convive com um pipeline que disparou). A **evidência
  pré-PR dos critérios de contrato e de isolamento de acesso** repousa sobre a **mesma condição
  habilitante** e passa a **declará-la**. **Permanecem inalterados** o mecanismo de entrega
  (pull-based, runner self-hosted, egress-only, sem ingress), as **duas metades** do deploy e o
  **rollback pelo artefato imutável**.
- **Gates de integração contínua no PR que integra a definição do pipeline = exceção declarada e
  aceita** (refino 2026-07-27; **ADR-010 item 10 / ADR-007**): quando a **definição** chega à linha
  principal por **rota própria**, a **aplicação ainda não está lá** — os gates que **verificam a
  aplicação** (lint, testes, build, drift de contrato, RLS) **não têm objeto** e **não são executados
  nesse PR**. A exceção vale sob **duas condições**: (1) o **job sem fonte fica visivelmente
  NÃO-EXECUTADO**, **nunca reportado como aprovado** — uma exceção que se deixasse **confundir com
  aprovação** seria **pior do que não ter gate**, pois **certificaria como verificado o que ninguém
  verificou**; (2) **a partir do momento em que a aplicação existe na linha principal**, os gates
  **voltam a ser exigidos em TODO PR, sem exceção**. **Forma concreta da não-execução visível =
  derivada no Design.**
- **Liveness pós-merge deixa de ser critério de pronto da feature 00** (refino 2026-07-27; **ADR-010
  item 5b**): a confirmação de que **a versão implantada responde**, com **reversão automática em
  falha**, só é observável **depois do merge da aplicação à linha principal** — isto é, **depois do
  próprio gate que precede o PR**. Como **critério de pronto da 00** ela é **insatisfazível na ordem
  em que o fluxo a exige**, e mantê-la ali só produziria um critério **permanentemente não-medido**.
  **O mecanismo permanece entregável da 00:** o deploy segue **confirmando saúde por smoke test** e
  **revertendo automaticamente para a versão imutável anterior** em caso de falha, **sem
  reconstruir**. **O que sai é a exigência de tê-lo MEDIDO antes do PR**; a **medição** passa a
  acontecer na **primeira implantação real em produção**, **sob a feature 01** (ver o bullet
  "**Primeira implantação real em produção = feature 01**").
- **Primeira implantação real em produção = feature 01** (refino 2026-07-28; **ADR-010 itens 5b e 9**):
  a feature que leva a aplicação à produção pela primeira vez é a **01** — e, portanto, é ela que
  **mede** o que a 00 entrega como **mecanismo** e não pode medir antes do merge: a **liveness
  pós-merge** (smoke test de saúde + probe, com **reversão automática** em falha) **e** a **EXECUÇÃO
  da reversão pelo artefato** (re-implantar a **versão imutável anterior** a partir do registry, com o
  alvo **lido do estado do deploy persistido no host**, **sem reconstruir**, com **evidência
  capturada**). Esta segunda medição nasce da **divisão do critério de artefato imutável da 00**: o que
  **permanece** critério de pronto da 00 é **a CI publicar a imagem versionada no registry**, **a
  produção puxar essa imagem sem construir no host** e **construir ser estruturalmente impossível no
  passo de reversão**; o que **sai** é a **execução** da reversão. As **obrigações correspondentes
  estão registradas no PRD 01**; a **forma da evidência** de cada uma fica `[a definir no Design da 01]`.
  **Fecha** o item que estava em aberto ("qual feature realiza a primeira implantação real").
- **Liveness pós-deploy e execução da reversão são propriedade da 00, dadas como MEDIDAS** (refino
  **2026-09-17**; **ADR-010 itens 5b e 9**; **supersede** os bullets datados de **2026-07-27** —
  "Liveness pós-merge deixa de ser critério de pronto da 00" — e **2026-07-28** — "Primeira implantação
  real em produção = feature 01" —, que ficam como **histórico**): a **medição** da **liveness
  pós-deploy** (smoke test de saúde + probe, com **rollback automático** em falha) e da **execução da
  reversão pelo artefato** (re-implantar a **versão imutável anterior** do registry, **sem
  reconstruir**, lida do estado do deploy persistido no host) passa a ser **da própria feature 00** e
  é **dada como satisfeita**. **Base:** a "**primeira implantação real em produção**" antes atribuída
  à 01 é, de fato, o **próprio stack de fundação da 00** — a **aplicação implantável da 00 é ela
  mesma** —, **já implantado em produção** na **reinstalação a frio de 2026-09-17**, com o **rollback
  automático observado disparando**. A premissa de que a medição só seria observável **depois** que
  uma aplicação de negócio mergeasse **envelheceu** (a implantação real já ocorreu). **Propagação:** no
  PRD 00 a 00 assume os critérios como próprios já medidos (M0.1, M0.10, O0.8, RNF0.11, §2, §4, §7); no
  PRD 01 saem os critérios que ela só herdara (O1.8, RNF1.6, M1.4, M1.5, o bullet de §2 e o inciso de
  §8). **Permanecem inalterados** o mecanismo de entrega (pull-based, runner self-hosted, egress-only,
  sem ingress), as **duas metades** do deploy, o **empacotamento/artefato imutável** e a **definição do
  pipeline na linha principal**.
- **Correção: execução da reversão é NÃO-MEDIDA / em aberto sob a 00 — a propriedade permanece**
  (refino **2026-09-17**; **ADR-010 item 9**; **remissão ao bullet anterior de 2026-09-17**, que fica
  como histórico no ponto da reversão): após o gate de conformidade **re-derivar a evidência ao vivo**,
  a **execução da reversão pelo artefato** deixa de ser **dada como MEDIDA** e passa a **entregue como
  mecanismo pela 00, porém NÃO-MEDIDA / em aberto sob a própria 00**. O mecanismo **dispara em falha**
  (entregue), mas **uma reversão íntegra e saudável nunca foi capturada**: nos deploys de produção que
  passaram (35136474611/35223484216/35227709700) o rollback ficou **skipped** e no único em que
  **disparou** (35218615973) **falhou por resíduo de host, não por defeito do mecanismo** — a medição
  fica **pendente de um exercício real bem-sucedido**. **A liveness pós-deploy permanece MEDIDA** sob a
  00 (mesmos deploys, com passo de saúde + smoke test passando) — **não** é afetada. **A propriedade da
  00 sobre deploy/liveness/execução da reversão permanece — não volta à feature 01.** Separar a
  redação: "o mecanismo dispara em falha" (verdade) ≠ "a reversão foi medida com sucesso" (falso).
  **Propagação:** PRD 00 (M0.1, M0.10, O0.8, RNF0.11, §2, §4, §7) e PRD 01 §8 ajustados; itens
  5b/9/10 e consequências da ADR-010 acima alinhados.
- **Prova de origem da integração = NENHUMA execução de deploy criada** (refino 2026-07-27; **ADR-010
  item 10**): a métrica que prova que **integrar não é exercitar** deixa de se satisfazer com "o
  **registro de execuções não contém deploy de produção**" — redação que admite uma implementação que
  **cria a execução e a interrompe internamente**, sem implantar nada. A exigência passa a ser que
  **nenhuma execução de deploy chegue a ser CRIADA**. A **evidência é lida no registro de execuções**:
  uma execução **criada e interrompida aparece lá** e obriga quem lê a **interpretar** em vez de
  **observar** — **ausência de execução é fato; presença interrompida é interpretação**.
- **Rollback = reverter para o ARTEFATO ANTERIOR, não reconstruir** (refino 2026-07-12; **ADR-010
  item 9**): o **rollback automático re-implanta a versão imutável anterior a partir do registry**,
  **sem reconstruir**. O **registry de imagens é o repositório de artefatos** do fluxo de entrega
  (ADR-011), e o **estado do deploy** (**qual é a última versão boa conhecida**) é **persistido no host
  de produção** — é o que o rollback **consulta**. **Rejeitado:** rollback que **re-obtém o código da
  versão anterior e reconstrói no host** — lento e sujeito a **falhar por causas novas** (dependência
  indisponível, imagem-base alterada, rede) **justamente com a produção quebrada**; a prática
  consolidada (Humble & Farley; Google SRE) manda voltar para um **artefato já construído e testado**.
  O **mecanismo de entrega permanece** (pull-based, runner self-hosted, egress-only, sem ingress),
  assim como a **rejeição do 2º ambiente always-on por custo**.
- **Forma concreta = derivada no Design** (refino 2026-07-10; ampliado em 2026-07-12 e 2026-07-27):
  **ferramenta/
  scripts de provisionamento**, **gatilho do disparo fora do merge/PR**, **rota concreta de integração
  da definição do pipeline à linha principal e forma de manter a integração sem que nenhuma execução
  de deploy seja criada**, **forma de manter visivelmente não-executado o job de gate sem fonte** no
  PR de integração, **registry concreto**,
  **esquema de versão/tag da imagem**, **forma de persistir o estado do deploy no host** e **a mecânica
  do rollback** são **detalhe de implementação** e ficam **`[a definir no Design]`** — a visão fixa
  **requisito e postura** (reproduzível/idempotente/versionado; duas metades — **pronto da 00 = a
  metade pré-PR**, liveness **medida sob a própria 00** (ver o bullet de 2026-09-17);
  **rollback = re-implantar o artefato imutável anterior, sem reconstruir**), não os artefatos.
- **Naming/estrutura desacoplados da tecnologia do alvo** (refino 2026-07-10): o **framing
  operacional** (títulos, tabelas, objetivos, requisitos, métricas) descreve o alvo por **papel** —
  **"host de produção" / "produção"** —, reservando à **decisão do ADR-010** a identidade concreta do
  alvo (on-prem, **VM dedicada** com o dimensionamento, sem ingress, egress-only, CD pull-based via
  runner self-hosted), **declarada uma vez**. O **componente de provisionamento** é nomeado por papel
  (**`infra/deploy`**), **não** por tecnologia (`infra/vm`). Racional: o que amarra o repo ao alvo de
  hoje **apodrece** se o alvo mudar (ex.: host on-prem → nuvem). **A decisão de ambiente permanece**;
  muda só **a forma de expressá-la** (agnóstica). A estratégia de **envs por componente** segue
  inalterada.
- **Runbook `DEPLOY.md` = foco único e autocontido** (refino 2026-07-10): reúne **tudo o que o
  operador precisa** para subir o ambiente de produção **do zero**, com **pré-requisito concreto**
  (portas e nomes de container livres no host-alvo); **não** carrega **meta-informação** (comparações
  "X não é Y") nem **escopo de desenvolvimento** (prova de mecanismo / validação de DoD do PR) —
  esse conteúdo mora nos **artefatos de design** (DESIGN).
- **Stack Supabase COMPLETO em dev e prod** (refino 2026-06-30): docker-compose (dev) e host de produção
  (prod) sobem o **stack oficial inteiro** (~8–12 containers: Postgres, Auth/GoTrue, Studio,
  Kong, PostgREST, postgres-meta, Realtime, Storage + imgproxy, Edge Functions,
  Analytics/Logflare + Vector), **não** um subconjunto mínimo — motivado por Studio
  (observabilidade já era "usar o do Supabase"), Storage pronto p/ features futuras e
  simplicidade operacional. **Trade-off de custo (constitution IX) registrado**: o stack
  completo divide CPU/RAM com os apps na VM de 16 GB — aceito por rodar **um único** stack
  (o de prod); o **2º stack qa/staging always-on permanece rejeitado**. Gestão de usuários
  **inalterada** (ADR-009): Admin cria/convida na tela admin do itallus; SuperAdmin usa o
  Studio só para infra/elevação de papel.

**Decididos neste refino — empacotamento/containers (ADR-011):**
- **Aplicação 100% containerizada** (refino 2026-07-01; **fronteira do termo precisada em 2026-07-28**):
  `api` (FastAPI), `web` (Next.js) e qualquer **serviço da aplicação em runtime** rodam
  **exclusivamente como containers Docker, nunca direto no host** (dev e prod). **"Componente" nessa
  regra = serviço da aplicação em runtime** (`api`, `web` e o **stack**); o **ferramental de
  verificação** (**suíte de testes**, **verificadores de repositório**, **geração do client tipado**)
  roda no **host de desenvolvimento** e no **runner da integração contínua** — fronteira **válida para
  todas as features**, definida **uma vez** no **ADR-011 item 1**. Alternativa "rodar api/web direto no
  host" **rejeitada** (quebra paridade, exige toolchain no host).
- **`docker-compose` da raiz = orquestrador via `include`**: faz **`include`** dos composes de **cada
  serviço** (`apps/api/docker-compose.yml`, `apps/web/docker-compose.yml` — cada app descreve o próprio
  serviço) + o compose do stack Supabase completo; a raiz **não** descreve `api`/`web` inline. O `up` na
  raiz sobe/derruba o **projeto inteiro** com **um comando**, em **dev e produção** (**empacotamento
  distinto por perfil** — ver o bullet de **2026-07-12** abaixo).
  A `api` conecta ao Postgres **direto na rede do compose** (serviço `db`), fora do
  Supavisor (coerente com ADR-006/010). Alternativa rejeitada = **composes por app sem orquestrador raiz**
  (exigiria vários comandos); a orquestração via `include` **é** a decisão (refino 2026-07-02).
- **Web — chamadas de Auth de dois contextos (navegador × server-side)** (refino 2026-07-02): o
  `web` (Next.js) executa o **mesmo código no navegador e server-side** (middleware + route/server
  handlers no container) e faz **Auth ao Supabase nos dois**. O **server-side** alcança o **gateway
  (Kong) pela rede interna do compose (nome de serviço)**; o **navegador** usa a **URL publicada no
  host**. A **config externalizada do `web` distingue as duas URLs** (voltada ao navegador × interna
  server-side) — **mesmo princípio** do caminho de dados interno da `api`→Postgres (ADR-006/010).
- **Produção roda IMAGEM VERSIONADA do registry; dev constrói** (refino 2026-07-12; **ADR-011 item
  5**): a **CI publica as imagens de aplicação num registry de imagens**, **versionadas de forma
  imutável por versão do código**; a **produção PUXA a imagem já construída e NÃO constrói nada no
  host** (coerente com a postura **pull-based / egress-only** — ADR-010). **Dev × produção passam a ser
  explícitos no empacotamento:** o **compose base descreve DEV** (constrói localmente, **monta a
  fonte**, **recarga automática**) e uma **sobreposição de produção** o substitui pela **imagem
  versionada**, **sem montagem de fonte e sem recarga**. **Permanecem inalterados:** **aplicação 100%
  containerizada** e **um comando sobe o projeto inteiro** — o que muda é **de onde vem a imagem**.
  Ganhos: a **imagem validada na CI é exatamente a que sobe em produção** (fim do "funciona no meu
  host"); o **build sai do host de produção** (poupa seus recursos); e passa a existir um **artefato
  imutável para onde reverter** (rollback — ADR-010 item 9). **Rejeitados:** **build no host de
  produção** e **perfil único de compose para dev e produção**. **Produto de registry, esquema de
  versão/tag e layout da sobreposição = derivados no Design.**

**Decididos neste refino — organização em épicos (refino 2026-09-28):**
- **Hierarquia:** **épico** = iniciativa com objetivo e critério de pronto; **feature** = 1 PRD =
  1 ciclo de implementação. **Épico não é departamento** — o departamento atendido fica registrado
  na visão (§6). Épicos: **E0 Fundação** (00) · **E1 Controle de Acesso** (01, 06d) · **E2
  Integração NetCorp** (02a, 02b) · **E3 Gestão de Contratos** (03, 04, 05a, 05b) · **E4 Gestão de
  Custos** (06a, 06b, 06c, 07, 08, 09) · **E5 Proposta Comercial** (10 — Controle de BR) · **E6
  Gestão de Rebates** (11a) · **E7 Controle de Renovação de Licenças de Software** (11b).
- **IDs estáveis:** cada feature mantém o número; feature desmembrada recebe letra e o PRD de
  origem deixa de existir como feature única (02 → 02a/02b; 05 → 05a/05b; 06 → 06a/06b/06c/06d;
  11 → 11a/11b).
- **Donos nos desmembramentos** (cada objetivo, requisito funcional e métrica com um único dono):
  conector NetCorp reutilizável, validação contra o NetCorp de teste e requisitos não funcionais de
  integração → **02a** (a 02b depende da 02a); garantia de que bloquear/excluir o usuário preserva
  o colaborador → **06c**; migração de departamento que arrasta a skill → **06b** (depende da 06a);
  LGPD do colaborador → **06a**, do usuário → **06d** (inclui a retenção da trilha de auditoria).
  Métricas e requisitos que atravessavam o corte foram **divididos** por recorte (M2.2, M2.3, RF6.3,
  M6.2, M6.3). **Restrição que vale para os dois lados de um corte é repetida em cada recorte com o
  mesmo identificador.**
- **Retirados:** o objetivo "base mínima do departamento" do PRD 11 (O11.3, com a M11.3) —
  descrevia o departamento, não uma entrega; o **PRD 12** (Faturamento — demandas avulsas).
  **Faturamento, Compras, Logística e Importação** ficam registrados como departamentos **sem
  épico** (§7);
  a entidade Faturamento (PO/BOQ) permanece no modelo canônico (§2).
- **Sem fases:** as fases do roadmap deixam de existir; a ordem vem do **grafo de dependência**
  (§6). Os critérios de pronto das fases 0–3 migram para E0–E4 (§7); a fase de ganhos rápidos
  desaparece. O cabeçalho de cada PRD nomeia o seu épico.

**Diferidos de propósito (não esquecidos — entram quando a maturidade exigir):**
- **Runtime/agendador do job de sync NetCorp** (cron/systemd/worker) — detalhe de deploy da
  feature 02a (o *adapter de entrada* scheduler é decidido; o **runtime** que o dispara, não).
- **Testes e2e de frontend** (Playwright) — Vitest (unit) já entra na v1.
- **Seed / dados de referência DE NEGÓCIO** — entram quando houver dados de referência estáveis a
  semear. **Não** cobre o **seed idempotente do usuário de desenvolvimento**: esse é **parte do
  ambiente reproduzível** (ADR-007) e **entregável da feature 00** — os dois deixam de ser cobertos
  pelo mesmo termo (refino 2026-07-28).

**Continua em aberto (estrutura/frontend e data layer):** **detalhes internos por feature**
(arquivos/módulos dentro de cada app — ficam para o **Design**); **middlewares e circuit breaker** (posteriores — o
ADR-004 só reserva o lugar); **espelhar escopo/papel em `app_metadata`** via Auth Hook
(performance — a avaliar, ADR-002/006); **adequação do catálogo do ui-ux-pro-max** a um app
interno LOB/admin (mitigação: gerar o `MASTER.md` **uma vez**, disciplinado, no padrão SaaS/ERP
moderno, e as telas herdam dele); **valores concretos de marca** (**paleta** e **regras de uso de
logo/ícone** — marca restrita a cores + logotipo) — **a extrair do guia da marca**
(`docs/brand-identity/Italtel_Brand_Guidelines_2024.pdf`) na implementação do design system
(PRD 00), não fixados na visão; **tipografia e iconografia = escolha do padrão SaaS/ERP**, não do
guia da marca.

**Continua em aberto (ciclo de vida de usuário — ADR-008/009):** **campos/política exatos da
anonimização** (right-to-erase) `[a definir]` — para o **usuário**, o alcance (nome e e-mail no
domínio + conta no provedor de identidade) está decidido; a **forma concreta do mecanismo** =
`[a definir no Design da 01]`; **em que operações e por qual superfície a feature 06d aciona** esse
mecanismo `[a definir]`; **qual feature entrega a consulta da trilha de auditoria pela
interface** `[a definir]`; **conteúdo detalhado das "configurações complexas"
do SuperAdmin** — anexa-se **feature a feature** (ex.: NetCorp = 02a, retenção LGPD = transversal,
fator dias→horas = 09); o **mapeamento da credencial privilegiada** = `[a definir no Design da
01]`. **Do refino 2026-09-23 (brainstorm da 01), `[a definir no Design da 01]`:** desenho exato da
**permissão de escopo global** em `role_permission` e da **cláusula `EXISTS`** que a reconhece; **formato, armazenamento
e tempo de expiração do token** de convite/reset; **mapeamento endpoints↔telas** da tela admin de
gestão de usuários/acessos, com as **telas de referência adaptadas à identidade visual do
projeto**; **se/como o seed inicial de usuários** entra como migração/script versionado. (As **aprovações do Manager** seguem em
aberto — ver acima — e **não** são resolvidas aqui.)

**Em aberto — épicos (refino 2026-09-28):** **objetivo e critério de pronto** dos épicos **E5**,
**E6** e **E7** `[a definir]`; **cobertura da 06d** no critério de pronto do **E1** e **da 06c** no
do **E4** `[a definir]`; **dependência da 06c em relação à 06d** (a M6.1 mede a preservação do
colaborador ao desativar o usuário, operação da 06d) `[a definir]`.

**Em aberto — deploy/ambientes (ADR-010):**
- **[a confirmar]** se o **CI na nuvem** roda algum **teste de integração** real (default
  **não** — o runner não alcança a rede interna; usa o stub).
- **Credencial/rota de acesso** por ambiente ao **NetCorp de teste** (rede interna) e ao
  **NetCorp de produção** (read-only) — `[a definir]`.
- **Headroom de CPU/RAM da VM** com o **stack Supabase completo + apps** em 16 GB —
  `[a monitorar em prod]`; mitigação se houver pressão = **desligar containers não usados**
  (ex.: Edge Functions/Analytics), não voltar a um subconjunto por antecipação (ADR-010).

---

**Confiança:** 0.85 — requisitos claros e bem consolidados, porém **sem padrões de
arquitetura específicos do projeto no KB** e com várias áreas explicitamente imaturas
("a definir"). A decomposição em épicos e features segue o grafo de dependência (§6);
incertezas concentradas em NetCorp e nos departamentos de requisitos imaturos
(BID/Faturamento/Logística).

**Fontes:** Requisitos (`docs/requisitos.md`), Constituição (`docs/constitution/principios.md`),
Roteiro SDD (`docs/roteiro-sdd.md`). KB: `supabase/rls-policies` + `supabase/multi-tenant-rls`
(acesso por departamento), `data-modeling/scd-types` (históricos), `python/clean-architecture`
(estrutura backend).
