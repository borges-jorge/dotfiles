# Roteiro SDD — playbook para iniciar projetos

> Guia para iniciar um projeto com **Spec-Driven Development (SDD)**: escolha de
> ferramentas, decomposição em features, documentação de arquitetura e constituição.

---

## 1. A ferramenta: AgentSpec (migrado do Spec Kit)
A implementação roda pelo **AgentSpec** (plugin Claude Code): **agentes especializados** +
workflow SDD de 5 fases **Brainstorm → Define → Design → Build → Ship**, com `/iterate` para
mudança mid-stream. As fases produzem artefatos em `.claude/sdd/` (DEFINE/DESIGN/BUILD_REPORT/
SHIPPED); no Design cada arquivo recebe um **agente responsável** (agent matching) que o Build
delega automaticamente.

> **Migração (2026-09-21):** o projeto veio do **GitHub Spec Kit** (slash-commands
> `/specify`→`/plan`→`/tasks`→`/implement` + `/analyze`). Só a **constituição** era nativa do
> Spec Kit e foi mantida (movida para `docs/constitution/constitution.md`); toda a camada
> anti-drift do projeto (`conformance-gate`, traceability, §10) era **externa** e foi
> re-apontada aos artefatos do AgentSpec; the-planner/ui-ux-pro-max/refine já eram AgentSpec.

**Ponto de atenção do catálogo:** o AgentSpec é **voltado a data engineering** (24 KB domains
dbt/Spark/Airflow; ~58 agentes majoritariamente DE). Num app FastAPI/Next.js, o agent-matching
pode atribuir mal — mitigação: **override local** (versionar agentes próprios em `.claude/agents/`
que sobrescrevem os do plugin por nome).

**Fato-chave:** o AgentSpec **não decompõe o projeto inteiro** nem analisa coerência entre
features (é per-feature). A quebra do sistema em features é trabalho do **brainstorm humano +
agente**, feito **antes** do ciclo, e a coerência cross-feature mora na **constituição + visão +
`conformance-gate`**.

## 2. O gap central: coerência cross-feature
- O AgentSpec é **feature-a-feature**. Não há **análise entre features** nem gate de
  **consistência cross-artefato** nativo (o `/analyze` do Spec Kit **não tem equivalente**;
  essa checagem passa ao `conformance-gate readiness`).
- A **constituição** (`docs/constitution/constitution.md`) é a **única âncora
  cross-feature** — e é **prescritiva** (toda feature obedece), **não analítica**
  (não compara features entre si). O AgentSpec não tem épico nem gestão de dependências: o
  agrupamento em épicos e o grafo entre features moram na **visão** (§4).

**Mitigações (padrão a seguir):**
1. Escrever a **constituição primeiro**, com os padrões compartilhados.
2. Manter um **doc de visão do sistema** (épicos + features + grafo de dependências).
3. **Sequenciar features por dependência** (fundação/ambiente/design primeiro).
4. Ao rodar `/define` e `/design` da feature N, **apontar manualmente** para os
   DEFINE/DESIGN das features anteriores relevantes.
5. Review cross-feature **manual**; manter uma definição **canônica** das entidades
   compartilhadas (evita drift de modelo de dados).
6. **Decomposição e refino** pelo `the-planner`, **único escritor** da visão e dos PRDs (sem drift
   de formato), por duas skills user-level (em `~/.claude/skills/`):
   **`/decompose-requirements-with-the-planner`** cria o plano a partir do documento de requisitos
   e reformula em dois ou mais o PRD que se revela grande demais; **`/refine-prd-with-the-planner`**
   refina o PRD de uma feature já decomposta, propaga a mudança aos artefatos pertinentes e versiona
   via Changelog.
7. **Design system persistido** (`MASTER.md` + overrides por tela) — âncora de coerência
   **do frontend** entre telas/sessões, análoga à constituição para o backend (ver §7).

## 3. Extensão do AgentSpec (agentes, KB, override local)
O AgentSpec estende-se por **agentes** e **KB domains**, não por comandos/hooks de terceiros:

| Necessidade | Como estender |
|---|---|
| **Agente próprio** (ex.: especialista FastAPI/hexagonal, Next/orval) | criar `.claude/agents/<categoria>/<nome>.md` no repo — o Design descobre por `Glob`; um agente local **sobrescreve** o do plugin de mesmo nome (resolução local-first) |
| **Padrões de domínio** (KB) | KB domains ficam no plugin (`kb/`); o app não é data-eng, então o valor é baixo — preferir os agentes próprios acima |
| **Coerência cross-feature** (o gap) | **não** há extensão nativa; fica com **constituição + visão + `conformance-gate`** (§2) |
| **Arquitetura** | mora na **visão/ADRs** (via the-planner) — 4+1 reduzido, §5 |

## 4. Decomposição em épicos e features
- A **decomposição** é o passo que falta no AgentSpec, e roda **antes** de qualquer ciclo: a skill
  **`/decompose-requirements-with-the-planner`** invoca o `the-planner` com o documento de requisitos
  e gera a visão e um PRD por feature, agrupados em épicos. As regras (hierarquia épico → feature →
  cenário, feature grande demais, IDs estáveis, dono no corte, restrição repetida, ordem pelo grafo,
  altitude) moram na própria skill, em `references/regras-de-decomposicao.md` — não são repetidas
  aqui.
- **Por que as regras são estas** (o que o itallus viveu antes delas):
  - **O the-planner produz nativamente um roadmap por fases**, e seguir o roadmap do seed ou as
    entidades do domínio gerou épicos disfarçados de feature: a fundação e o controle de acesso
    foram épicos inteiros executados como um ciclo só, e cinco PRDs agrupavam entregas
    independentes ("colaboradores e skills", "rebate e licenças").
  - **Feature grande demais custa rodadas, não linhas.** A feature 01 teria sido acesso por
    departamento → convite/reset de senha → anonimização → acabamento de UI, cada fatia com seu
    ciclo; num ciclo só, passou por sete rodadas de readiness e cerca de 130 achados, quase todos
    sobre precisão de prova, não sobre produto. O sintoma que aparece primeiro é o File Manifest do
    `/design` explodindo.
  - **IDs estáveis** porque renumerar muda o sentido de toda referência já registrada (histórico
    congelado, issues, commits).
- **O que o the-planner propõe é insumo, não veredito:** a revisão do diff confere cada feature
  contra o teste de "grande demais" e cada requisito contra a decisão que o sustenta.
- **Depois da decomposição:** cada feature passa por brainstorm e `/refine-prd-with-the-planner`
  antes do seu ciclo; feature que se revela grande demais volta à skill de decomposição.

## 5. Documentação de arquitetura: 4+1 reduzido
O **4+1 View Model** (Kruchten) documenta a arquitetura em 5 visões: **Lógica**
(domínio), **Processo** (runtime), **Desenvolvimento** (código), **Física/Deploy**,
**+1 Cenários** (casos de uso que costuram as outras). O modelo completo é **pesado**
para web apps pequenos/médios.

**Padrão recomendado:** usar **2–3 visões** — **Lógica (modelo de domínio) + Deploy +
Cenários** — que é exatamente o que cabe no **doc de visão do sistema** produzido no
brainstorm. Alternativa leve e moderna: **C4 model** (Context → Containers →
Components → Code).

## 6. A constituição e a estrutura dos princípios
**Mecânica (pós-migração):** a constituição é um **doc versionado** em
`docs/constitution/constitution.md` — template **conciso e declarativo** (nome + regra +
racional por princípio), com **semver próprio** (MAJOR/MINOR/PATCH) e um **Sync Impact Report**
no topo a cada emenda. Emenda-se **manualmente** por PR no fluxo `<tipo>/* → qa → master` (não
há mais `/speckit.constitution` que a preencha/propague); a aplicação é pelo **`conformance-gate
readiness`** (não pelo `/analyze`).

**Distinção crucial — princípio do PROJETO vs harness do AGENTE:**
- **Princípio do projeto** = propriedade que o **sistema** deve ter (ex.: os pilares
  de qualidade) → vai para a **constituição**.
- **Harness do agente** = como o **agente trabalha** (verificar antes de afirmar,
  crítica proativa, pesquisar sob incerteza) → vai para o **`AGENTS.md`**, **não** a
  constituição. E **nada de prescrição de formato de resposta** no AGENTS.md
  sempre-carregado: ele chega aos subagents e **colide** com o formato nativo deles.

**Split de dois artefatos (padrão):**
- **`principios.md`** (artefato A) — princípios **declarativos**, com tag do padrão
  (ISO/IEC 25010 / extensão). É a **fonte** dos princípios da constituição.
- **`padroes-qualidade.md`** (referência **compartilhada** no **diretório-pai dos
  projetos** — fora do repo, reutilizável entre projetos) — o **manancial detalhado**
  (perguntas-guia por pilar). **Não é artefato de pipeline; nada nativo o lê.** Seus
  papéis: (a) **destilar** os princípios de A e (b) referência para um **review
  profundo opt-in**. O gate automático fica com o `conformance-gate readiness`, que avalia
  cada feature contra a **constituição** (princípios de A): conflito entra com o **peso máximo**
  da severidade e segue a manifestação, como qualquer afirmação em vigor. O detalhe só é usado se
  você apontar um **agente/skill de review** explicitamente para o doc.

**Propagação de contexto (doc do Claude Code):** o `CLAUDE.md` (que importa
`@AGENTS.md`) carrega em **toda sessão** e em **subagents custom** (o `the-planner`
inclui; os embutidos **Explore/Plan pulam** o CLAUDE.md). É **contexto, não config
forçada** — o **system prompt do subagent tem prioridade**.

**A constituição é o gate — e quem a escreve é a IA.** Isso a torna o ponto mais perigoso
da cadeia: um MUST inventado ali vira obrigação em toda feature, e o `conformance-gate readiness`
valida **contra ela**. Três regras que impedem o gate de virar teatro (ver §10):

- **Todo MUST cita a decisão humana que o sustenta** — seção da fonte de requisitos ou
  clarificação datada. **Sem lastro → não é MUST.** Um gancho genérico na fonte
  ("arquitetura dentro das boas práticas / padrões de qualidade tipo ISO") legitima a
  **existência** dos princípios; **não legitima nenhuma cláusula MUST específica** derivada
  deles. É exatamente nessa lacuna que nasce requisito inventado.
- **Endurecer indicativo → imperativo é uma decisão, e se registra.** O `principios.md`
  descreve ("cada componente **tem** um alvo de latência"); a constituição obriga
  ("**DEVE** ter"). Essa conversão precisa aparecer no **Sync Impact Report** — senão nove
  MUSTs vinculantes nascem em silêncio, e ninguém sabe que foram escolhidos.
- **Invariante comportamental, nunca topológico.** "timeout/retry em **chamadas externas**"
  é intraduzível: obriga a decidir o que é "externo", e acaba exigindo um ADR **só para
  definir o próprio termo**. "**Toda chamada que sai do processo tem deadline**" é auditável
  e não tem fronteira ambígua. **Teste:** se um invariante precisa de um ADR para definir
  seus termos, o termo está errado.
- **Manter a faixa vinculante em dia.** Se a constituição diz "vinculam-se os ADR-001..010"
  e a visão já tem o 012, o gate roda **cego** justamente para as decisões mais recentes.

## 7. Estrutura do projeto e fluxo full-stack

> **Quando entra:** depois da decomposição/PRDs e **antes** de implementar a feature de
> fundação. São decisões de **plataforma** — entram como **ADR** via refino, **nunca**
> ad hoc.

- **Estrutura como ADR, na altitude certa.** O `the-planner` **não** fixa layout de
  pastas no brainstorm (é decisão de implementação). Ele entra depois, como **ADR**, e
  fixa **esqueleto + convenções** (camadas, testes, config externalizada, **catálogo de
  ports/adapters**) — os **internos por feature ficam para o `/design`** (AgentSpec)
  (evita over-engineering). Critério de port/adapter: **dependência de saída que o
  domínio chama e se troca/mocka** (banco, auth, integrações, e-mail, storage, clock);
  transversais (logging/tracing/config) e adapters de **entrada** **não** viram port.
  - *itallus:* **monorepo** `apps/api` (FastAPI, Clean/Hexagonal) + `apps/web` (Next.js) —
    **ADR-004**. Um repo casa com a governança única (hooks, branch protection, deploy).
- **Uma feature = um PRD = ponta a ponta** (backend + frontend juntos), **não** features
  separadas de front e back. No ciclo AgentSpec: o **`/design` mapeia endpoints↔telas** e o
  File Manifest ordena **backend-first** (domínio → adapters → contrato → client → tela),
  porque o frontend precisa do contrato para ser tipado.
- **Contrato front↔back = seam tipado e gerado.** O backend é a fonte da verdade do
  contrato (ex.: **OpenAPI gerado pelo FastAPI**); o frontend **gera um client tipado**
  dele (codegen) → drift pego em **compile-time/CI**, não em produção (reforça a
  constituição III; vale virar **gate verificável** — CI falha em drift).
  - *itallus:* OpenAPI → **orval** (hooks TanStack Query) — **ADR-005**.
- **Design system embarcado + persistência Master/Overrides** — mais um anti-drift
  cross-feature (ver §2.7). A ferramenta de design fica **embutida/versionada** no repo
  (offline) e **persiste** um `MASTER.md` + overrides por tela → consistência entre telas
  e sessões. Gerar o Master **uma vez** (disciplinado ao tipo de app) e as telas herdam.
  - *itallus:* **ui-ux-pro-max** embarcado em `.claude/skills/`; `apps/web/design-system/`;
    `frontend-design@claude-plugins-official` **excluído** (um só "cérebro" de design).

## 8. Checklist de início de um novo projeto SDD
0. **Rastrear toda exigência a uma decisão humana registrada.** O documento de requisitos
   escrito pela pessoa é o **seed imutável**: ele **semeia os PRDs** (via the-planner) e **não
   é mantido vivo** — depois dele, as decisões humanas se acumulam **nos artefatos derivados**,
   registradas **onde nascem** (`/iterate` no DEFINE, Changelog de PRD, ADR de refino). Todo o
   resto (princípios, constituição, visão, ADRs, PRDs, DEFINE, DESIGN) é **derivado por IA**.
   Regra **desde o dia 1**: todo requisito normativo **rastreia a uma decisão humana registrada**
   — o seed **ou** um `/iterate`/refino logado; o que não rastreia a decisão humana nenhuma é
   **invenção da IA** (§10). **Não** se "sincroniza de volta" o seed — ele cumpriu o papel ao
   gerar os PRDs.
1. Repo + **workflow de branches** + `AGENTS.md` (e `CLAUDE.md` importando `@AGENTS.md`).
2. **Decomposição** com `/decompose-requirements-with-the-planner` a partir do documento de
   requisitos → visão + épicos + features + grafo de dependência (§4).
3. **1 PRD por feature** (template fixo de 8 seções), no diretório do épico — saída da mesma skill.
4. **Estrutura + ferramentas (ADR via refino):** layout do repo (apps/camadas/catálogo
   ports-adapters), **fluxo full-stack** (feature ponta a ponta, backend-first, contrato
   OpenAPI→codegen) e **design system embarcado** — esqueleto + convenções; internos por
   feature → `/design` (ver §7).
5. Destilar **princípios de qualidade** → `principios.md` (fonte da constituição), com
   o `padroes-qualidade.md` (referência compartilhada no diretório-pai) como base.
6. Escrever a **constituição** (`docs/constitution/constitution.md`) a partir dos princípios de A.
7. Implementar **feature a feature** com AgentSpec, sequenciado por dependência (a
   **fundação** monta o esqueleto do repo, o pipeline de contrato e o Master do design).
   Ver o **ciclo por feature** abaixo (§8.1). **Na fundação, o caminho até produção vem primeiro**
   (walking skeleton / deploy-first) — ver **§8.3**.
8. Cuidar da **coerência cross-feature**: constituição + doc de visão + design system
   (`MASTER.md`) + `conformance-gate` + review manual.
9. **Auditoria de lastro, recorrente** (§10) — não é opcional e não se descobre sozinha: nenhum
   gate nativo do AgentSpec **a faz** (o `conformance-gate readiness` valida a cadeia **contra a
   constituição**, que é parte da cadeia). Rodar ao fechar cada feature e **antes de iniciar a
   seguinte**.

### 8.1 Ciclo por feature (AgentSpec) — com os loops que não são óbvios
O ciclo nominal é `brainstorm → define → design → build → ship`, mas na prática há **loops de
controle** que evitam drift e retrabalho. Sequência completa (sempre as 5 fases):

1. **`/brainstorm`** → `BRAINSTORM_{FEATURE}.md` (fase 0): explora abordagens (2-3), aplica YAGNI.
   Em seguida, **`/refine-prd-with-the-planner`** com o brainstorm e o PRD da feature leva as
   decisões ao PRD; brainstorm e refino se alternam até o PRD ficar adequado, a critério do
   responsável. Durante o ciclo, decisão nova que muda só requisito da feature entra pelo `/iterate`
   no DEFINE ou no DESIGN e chega ao PRD na sincronização da entrega (passo 12); a que muda a base
   (constituição, ADR, concern cross-feature) volta ao PRD na hora pelo mesmo refino, com ou sem
   brainstorm; feature que se revela grande demais volta à decomposição (§4).
2. **`/define`** → `DEFINE_{FEATURE}.md`: problema, usuários, objetivos (MUST/SHOULD/COULD),
   critérios de sucesso, **acceptance tests**, fora de escopo, assumptions. Gate nativo: Clarity
   Score ≥12/15. **`/iterate` no `DEFINE`** é a ferramenta para ajustar o requisito depois.
3. **`/design`** → `DESIGN_{FEATURE}.md`: arquitetura, **ADRs inline**, **File Manifest** (cada
   arquivo com **agente responsável**), code patterns e **testing strategy**, ancorado nos ADRs
   (não re-deriva stack).
4. **▶ Loop 1 — revisar o output do `/design`**, em duas frentes: **(a) nomes concretos** que
   ele inventou (rotas, schemas, roles, tabelas, layout) — coerentes com os ADRs, mas **sem**
   decisão explícita do responsável; **(b) adequação dos artefatos** — toda dependência ou
   necessidade de setup precisa aparecer como **passo explícito no File Manifest** (não nota
   marginal), senão **não cascateia** para o `/build`. Ajustar = **`/iterate` no `DESIGN`**
   (mudança em artefato AgentSpec flui re-executando o comando — não editar à mão).
5. **▶ Loop 2 — higienizar a visão (back-port):** um `[a definir]` da visão/ADRs que o `/design`
   resolveu **fecha** na visão via `/refine-prd-with-the-planner` (o the-planner é o **único
   escritor** da visão) — senão a visão "mente". Fecha na hora quando o ponto é de ADR ou concern
   cross-feature; senão, na sincronização da entrega (passo 12). **Filtro de altitude:** o que volta é a
   **decisão**, com remissão ao DESIGN; o **mecanismo** (policies, rotas, forma do token, nomes de
   tabela) fica no DESIGN. Este loop foi o mecanismo do inchaço da 01: sem o filtro, cada
   back-port copiava mecanismo para cima — o PRD 00 foi de 5,7 para 87,6 KB, o PRD 01 de 4,4 para
   41,5 KB e a visão de 22 para 160 KB, enquanto os PRDs pouco refinados seguiram com 5–14 KB. E
   mecanismo no PRD vira critério a auditar em todo DEFINE e DESIGN abaixo dele.
6. **▶ Pré-build — validar o toolchain do ambiente.** Antes do passo longo, conferir que as
   ferramentas que o design **assume como pré-requisito** (runtimes/linguagens/daemons: o
   gerenciador de pacotes, o runtime, o container engine) estão **presentes e funcionais** — a
   checagem é barata e pega bloqueadores **antes** de um `/build` que falharia no meio com
   estado parcial. **Toolchain é pré-requisito, não passo de setup:** os passos de setup criam
   manifestos e instalam as *dependências do projeto* (assumindo o runtime), **não** o runtime em si.
   - **Runtime isolado por projeto (sem poluir o host):** se faltar uma ferramenta, preferir um
     **version manager por-projeto** (`pyenv`/`uv` p/ Python, `fnm`/`nvm` p/ Node) — versões no
     `~`, escolhidas por projeto via arquivo de versão, sem `sudo`/system-wide. Se o instalador
     oficial exigir uma dep ausente (ex.: `unzip`), baixar o binário e extrair com o que há
     (ex.: `python3 -m zipfile`).
   - **Para o agente enxergar o runtime — configurar na fonte certa, não remendar.** O Claude Code
     **congela o `PATH` herdado do terminal de lançamento** num *shell snapshot* sourçado em todo
     comando do tool — ele **não** re-roda dotfiles nem (de forma confiável) o `BASH_ENV`. Logo, a
     correção é garantir o runtime no `PATH` do **shell de login** que lança o agente: uma linha no
     `~/.bashrc` que prepende o **bin estável** do version manager (não o caminho efêmero/lazy), e
     **relançar o agente de um terminal novo** para regenerar o snapshot. Evitar gambiarras de
     `source` por comando (mascaram o ambiente mal configurado). *(itallus: linha no `~/.bashrc`
     prependendo `~/.local/share/fnm/aliases/default/bin` — segue o alias `default` do fnm, sem
     hardcode de versão; convive com o auto-switch `fnm env --use-on-cd` como fallback estável.)*
7. **▶ Gate de conformidade — readiness (`/conformance-gate readiness`).** O AgentSpec **não** tem
   gate de consistência cross-artefato nem confronto com a **fonte-upstream** (PRD/visão/ADRs), nem
   verifica **satisfação de DoD**. Antes de `/build`, rodar o gate em modo `readiness`: **absorve a
   consistência interna** (DEFINE↔DESIGN — o que o `/analyze` do Spec Kit fazia) **e** confronta a
   cadeia com o upstream — pega **requisito enfraquecido/dropado**, **scope-creep**, **contradição
   na própria fonte** e **decisões de interpretação** resolvidas em silêncio — **antes** de codar.
   Read-only; a correção entra corrigindo o **upstream** (`/iterate` no DEFINE ou refine) e re-rodando.
   **O que bloqueia é risco, não letra:** achado é o que põe em risco a **base protegida** ou o **DoD**
   da feature; variação de texto entre as camadas sem esse risco vai para a **sincronização** (com
   decisão registrada) ou para **confirmação** do responsável (sem registro), sem bloquear (AGENTS.md,
   Gates). **Limiar:** achado **crítico ou alto** bloqueia o `/build`; **médio e baixo** viram issue,
   **uma por unidade que fecha sozinha**, e o ciclo segue. Sem limiar, cada rodada gera achados novos
   sobre a precisão da rodada anterior e o gate não converge — na 01 foram sete rodadas. A saída de
   cada rodada fica em `.claude/sdd/reports/READINESS_{FEATURE}.md` (template
   `.claude/sdd/templates/GATE_REPORT_TEMPLATE.md`), com as respostas às confirmações, cumulativas
   entre rodadas. Sem o fato que decide um item, o gate não supõe: pergunta, e o veredito aguarda
   a resposta.
8. **`/build`** → código + `BUILD_REPORT_{FEATURE}.md`. O build-agent **gera as tasks on-the-fly do
   File Manifest** e **delega a especialistas automaticamente** (a delegação é o modelo do AgentSpec,
   não requer aprovação passo-a-passo); verificação por arquivo (import/lint) e cheia (lint/tipos/testes).
9. **▶ Reviews de código e de segurança (`/code-review high origin/qa...HEAD` e
   `/security-review`).** Procuram o que o gate não procura: defeito de código (bug, caso de erro, validação de entrada) e vulnerabilidade
   explorável no diff da branch. Não ancoram em afirmação dos artefatos, não verificam o que acham e
   não classificam pela régua — um achado deles pode ser decisão registrada, cenário fora da régua
   ou falso positivo. Por isso **não decidem nada**: a saída de cada um é gravada **sem alteração**
   em `.claude/sdd/reports/{CODE_REVIEW|SECURITY_REVIEW}_{FEATURE}.md` (template
   `.claude/sdd/templates/REVIEW_REPORT_TEMPLATE.md`), com o commit revisado e a base do diff, num
   commit próprio, e vira **entrada do conformance**, que prova cada achado contra o código, aplica
   o filtro de admissão e a tabela de severidade. Classificar no chat criaria uma segunda régua. O
   relatório vale enquanto o diff contra a base que ele declara for o que ele revisou (mesmo hash de
   patch); mudar o código o invalida. Sem alvo, o code review revisa só os commits ainda não enviados
   ao remoto (`@{upstream}...HEAD`) mais a árvore, e o escopo muda com o estado do repositório: por
   isso o alvo explícito. O security review não aceita alvo e compara com a branch padrão
   (`origin/HEAD`), que contém o diff contra a `qa`.
10. **▶ Validação que o gate não consegue repetir.** Quando a prova de um critério exige credencial
    do responsável (ex.: leitura real de um sistema externo só de produção), o responsável a
    executa no terminal dele e a saída é gravada sem alteração em
    `.claude/sdd/reports/VALIDATION_{FEATURE}.md` (template
    `.claude/sdd/templates/VALIDATION_REPORT_TEMPLATE.md`), com o commit validado, num commit
    próprio. Saída colada no chat não chega ao gate, que roda num agente novo; sem o relatório, o
    critério fica não medido e bloqueia.
11. **▶ Gate de conformidade — conformance (`/conformance-gate conformance`), OBRIGATÓRIO antes de PR.**
    Como a delegação do `/build` é automática, este é **a única trava forte e roda depois do código** —
    por isso é obrigatório **sem exceção**. **Antes de abrir PR para `qa`/declarar "done"**, rodar o gate
    em modo `conformance`: além do readiness, confronta **artefatos↔código** e **exige evidência ao vivo**
    de cada critério de sucesso/métrica "sim/não" (sobe/roda o que for preciso: ambiente, migração, CI,
    performance, UI headless). Pega **placeholder marcado como pronto** e **DoD não medido**. **PROIBIDO**
    declarar "done"/abrir PR com um DoD **não medido** ou **falhando** — "existe código" ≠ "gate passou".
    Achados que **não** são critério de DoD seguem o limiar do readiness. O DoD é medido na **variante
    decidida**: o critério do DEFINE lido com as decisões registradas depois dele; o texto superado
    vai para a sincronização. A saída fica em `.claude/sdd/reports/CONFORMANCE_{FEATURE}.md`, no
    mesmo template do readiness.
    *(Enforcement hoje = esta regra + o bullet do `AGENTS.md`; hook de harness que barre o PR mecanicamente
    = pendência futura — se entrar, marcador com hash da árvore + interceptar `gh pr create --base qa`.)*
12. **▶ Sincronização da entrega, depois `/ship`.** A visão e o PRD são os documentos que sobrevivem
    à feature; o DEFINE, o DESIGN e o BUILD_REPORT são arquivados como estão. Antes do arquivamento, o
    `/refine-prd-with-the-planner` lê o relatório do último `conformance` (sincronização e
    confirmações respondidas) e leva à visão e ao PRD o que foi decidido e entregue, com o filtro de
    altitude. Depois, **`/ship`** → arquiva os artefatos em `.claude/sdd/archive/{FEATURE}/` +
    `SHIPPED_{DATA}.md` com lessons learned, incluídos os relatórios de review e do gate; os dois
    entram no PR do arquivamento.

**Princípios do ciclo:** (a) artefato AgentSpec muda **re-rodando o comando** (`/iterate` para
DEFINE/DESIGN; `/build` regenera código), nunca por edição manual; (b) argumentos dos comandos
descrevem **o quê a nível de negócio**, não instruções imperativas de editar arquivo X; (c) **sem
arquivos de controle paralelos** — estado volátil de acompanhamento vive na memória do agente, não
no repo; (d) política de commit/branch: os **hooks versionados** (`.githooks/`) + o fluxo por PR
`<tipo>/* → qa → master` (não há mais helpers `speckit-git-*`).

### 8.2 Semântica de escrita por comando — INCREMENTAL × REGENERA (AgentSpec)
Cada comando tem um **modo de escrita** diferente; violá-lo injeta comportamento no fluxo. Fonte:
`WORKFLOW_CONTRACTS.yaml` do AgentSpec (status-transitions, iterate cascade).

| Comando | Modo |
|---|---|
| `/define` | **cria do zero** (1ª vez); depois **INCREMENTAL** via `/iterate` |
| `/iterate` | **INCREMENTAL — edição pontual** + bump da Revision History + cascata downstream |
| `/design` | **cria do zero** (1ª vez); depois **INCREMENTAL** via `/iterate` |
| `/build` | **REGENERA o código** a partir do File Manifest; escreve `BUILD_REPORT` |
| `/ship` | arquiva; escreve `SHIPPED` + atualiza Status upstream |
| `/conformance-gate` | **read-only** sobre artefatos e código; a saída de cada rodada **regenera** o relatório do gate |

**Consequências operacionais:**
- **Não há `tasks.md` com checkboxes.** O Build gera as tasks on-the-fly do File Manifest; o estado
  real de "o que já está implementado" **não mora em checkbox** — é medido ao vivo pelo
  **`/conformance-gate`**. As fases reescrevem os **Status** dos artefatos upstream ao concluir
  (status-transitions) — isso é esperado, não edição fora de fluxo.
- **`DEFINE`/`DESIGN` são incrementais** — editar por `/iterate` É a disciplina deles; a acumulação
  (Revision History datada) é **esperada**, não fóssil. Porém, como **não** regeneram do zero, **um
  resíduo neles NÃO se auto-corrige por re-rodar** — corrige-se na **origem** (visão/PRD via refine,
  ou o próprio `DEFINE` via `/iterate`) e propaga-se; nunca editando o downstream à mão fora do fluxo.

### 8.3 A feature de fundação: ordem de construção e decisões de infra
A fundação (feature 00) não é "o esqueleto do código" — é o **caminho até produção**. A ordem em que
ela é construída determina se a infra nasce validada ou apodrece.

**Ordem: o pipeline de deploy vem PRIMEIRO, não por último.**
- O padrão é o **Walking Skeleton / deploy-first** (Freeman & Pryce, *GOOS*; Humble & Farley, *CD*):
  a **primeira coisa automatizada é o caminho até produção**, e uma **fatia vertical fininha** (um
  login, uma tela) é empurrada por ele **antes** de empilhar features. O pipeline é validado por
  **algo real atravessando-o**.
- O anti-padrão (fácil de cair): construir tudo no host/dev, deixar o deploy para o fim. A infra fica
  **escrita mas nunca exercitada** — workflow de deploy que referencia um runner que ninguém
  registrou, imagem que "builda" só em cache. *Sintoma típico: o critério de deploy é o último a ser
  medido e trava a entrega.*
- **Não** criar uma "feature de infra" isolada antes da fundação: entrega zero valor observável e
  produz infra **sem nada atravessando-a** — exatamente o que o walking skeleton existe para evitar.
  Deploy é parte constitutiva da fundação.
- **Dois artefatos com ciclos de vida distintos**, ambos dentro da fundação: **(a) provisionamento
  one-time do host** (preparar o host, registrar o agente de deploy) — script **idempotente** +
  runbook; **(b) deploy por release** (pipeline de CD). Confundir os dois faz o "provisionamento"
  virar passo manual esquecido.

**Rollback: reverter para artefato, nunca reconstruir.**
- Regra de ouro (Humble & Farley; Google SRE): o rollback volta para um **artefato já construído e
  testado**. Reconstruir a partir do código **durante** um rollback é lento e pode **falhar por causas
  novas** (dependência sumiu do registry de pacotes, imagem-base mudou, rede) — justamente com a
  produção quebrada. Você fica sem produção **e** sem rollback.
- Ordem de robustez: **blue-green/canary** (troca de tráfego; exige 2× recursos) > **redeploy de
  imagem versionada** (registry; rollback = subir a tag anterior) > **re-checkout + rebuild** (a mais
  fraca — é *revert do source*, não rollback de artefato).
- Sem recursos para blue-green, o alvo é o **registry**: a CI **publica** a imagem versionada
  (tag = versão do código), produção **puxa** — e o rollback é **puxar a tag anterior**. Efeitos
  colaterais que valem por si: o build **sai do host de produção** e **a imagem testada na CI é
  exatamente a que sobe**.
- O registry cobre a camada de **aplicação** de um DR futuro; **dados** (banco/volumes) e **segredos**
  exigem backup próprio — não confundir as duas coisas.

**Empacotamento: dev e produção são perfis distintos — e isso tem de estar no código, não só no ADR.**
- Um compose que monta o código-fonte e recarrega é **dev**. Se o mesmo arquivo serve produção, a
  produção **está rodando em modo dev** — mesmo que o ADR afirme o contrário. *(Armadilha real: o ADR
  dizia "prod roda imagens buildadas"; nada implementava isso.)*
- Mecanismo: **overlay de produção** (base = dev; overlay sobrescreve para imagem versionada, sem
  bind-mount e sem recarga). **Não** parametrizar por variável — **volumes não são condicionáveis**
  em Compose, o bind-mount do código sobreviveria em produção.
- A **config permanece 100% externalizada**: nenhum valor de ambiente embutido na imagem. Cuidado com
  a formulação ingênua "**o mesmo artefato roda em dev e prod**" — com registry ela deixa de ser
  literal (dev constrói; prod puxa). O princípio real é: **a imagem da CI é promovida a produção sem
  rebuild**.

**Estado do deploy precisa de um lugar durável — e de um contrato.**
- O CD é *stateless* (workspace efêmero a cada execução). Segredos de produção e o **marcador da
  última versão boa** (que o rollback consulta) precisam de um **diretório persistente no host**,
  fora da árvore do código.
- Esse diretório é um **contrato** entre o provisionamento (quem cria) e o pipeline (quem lê) —
  **declare-o nos artefatos**. Se ele nascer direto na implementação, aparece "do nada" no runbook e
  ninguém sabe o que é.

**Runbook de deploy: fatos derivados dos arquivos, nunca de memória.**
- Um runbook diz **só como fazer o deploy** e é **autocontido** (tudo o que o operador precisa).
  **Fora dele:** meta-informação ("distinto do cenário de validação", "X não é Y") e **escopo de
  desenvolvimento** (prova de mecanismo, validação de DoD do PR) — isso mora nos docs de design.
- **Pré-requisitos concretos, extraídos da fonte:** portas publicadas e nomes de container vêm dos
  **arquivos de orquestração**; variáveis compartilhadas vêm dos **templates de config**, citadas pelo
  **nome literal** e com o mapeamento **origem→destino**. Container **sem nome fixo declarado** é
  descrito como **nome derivado pelo orquestrador**, não com um nome inventado.
- *Por que a regra existe:* "pré-requisitos concretos" **sem exigir a fonte** é satisfeito por uma
  lista redigida de memória — que **parece** concreta e **quebra** o operador (nomes de container que
  não existem, segredo citado por apelido em vez do nome da variável).

## 9. Armadilhas a evitar
- **Separar fato verificado de hipótese.** Não fixar conteúdo não-validado em docs;
  rascunhos não viram fonte da verdade.
- **Fonte única da verdade.** `AGENTS.md` = verdade do projeto (versionada, do time);
  memória local = pessoal/efêmero. Não duplicar — duplicação gera drift.
- **Verificar a mecânica das ferramentas na fonte** (docs do AgentSpec e do Claude
  Code), não de memória.
- **`AGENTS.md` carrega comportamento, não formato de resposta.**
- **Toda mudança entra pelo TOPO da cadeia — nunca pelo meio.** Se o `/build` gerou algo errado,
  **algo antes falhou**: ou o design não dizia o bastante, ou o requisito não existia. Corrigir o
  downstream (ou re-rodar só o `/build`) **mascara o furo na origem** e ele volta. Entrada:
  **`refine`** (muda a fonte: visão/PRD/ADR) **ou `/iterate` no DEFINE** (muda o requisito) → e
  cascateia. Um entregável ruim é **sintoma**, não a doença.
- **Requisito vago é satisfeito por qualquer coisa.** Um critério como "pré-requisitos concretos" ou
  "segredos que batem entre si" **não exige a fonte do fato** nem o **nome** do que precisa coincidir —
  então é atendido por uma lista inventada. Ao escrever critério verificável, diga **de onde o fato
  vem** e **o que exatamente** tem de aparecer.
- **O que nasce no `/build` sem passar por artefato vira dívida invisível.** Uma variável de
  ambiente, um diretório de estado, um contrato entre dois componentes — se só existe no código,
  ninguém o documenta (nada o exige) e ele "cai de paraquedas" no runbook. Se é **contrato**, declare
  no artefato.
- **Um ADR que o código não implementa é ficção.** "Prod roda imagens buildadas" enquanto o compose
  monta a fonte e recarrega = a decisão existe **só no papel**. Ao fechar um ADR de infra, verificar
  se há **mecanismo** que o realize — senão é aspiração, não decisão.
- **Trabalho planejado ≠ defeito.** Artefato que descreve o alvo e código que ainda não o implementa é
  o estado **normal** entre o `/design` e o `/build`. Antes de gritar "doc × código divergem",
  conferir se o `/build` **daquele delta** já rodou. Auditoria que confunde os dois cria pânico e
  queima credibilidade.
- **Nunca converter item aberto em "default razoável".** Um DEFINE que declara Clarity Score cheio
  porque os itens `[a definir]` "têm default razoável ou pertencem ao `/design`" é o mecanismo por
  onde (a) **número inventado vira gate** — um alvo de p95 que ninguém pediu passa a travar o DoD **e
  a satisfazer o próprio princípio que o exigiu** — e (b) **requisito humano evapora** (o `/design` é
  nomeado dono, não define, e ninguém mais pergunta). **Item aberto vira pergunta ao humano ou fica
  em Open Questions.**
- **MUST órfão é bomba-relógio.** Um MUST que **nenhuma feature entrega** não fica inerte: no dia em
  que um gate o pegar, nasce um ADR que o **enfia** numa feature qualquer, por invenção. Teste
  barato: `grep` do termo do MUST no repo — se **só aparece na constituição**, é órfão.
- **Não colapsar conceitos distintos da fonte numa entidade só.** Se o humano usa três palavras para
  três coisas (área de **acesso** · centro de **custo** · departamento **operacional**), o modelo tem
  de manter três. Colapsar parece simplificação e é **bug de domínio** — e só aparece features depois,
  no cálculo que lê a entidade errada. Teste: cada substantivo do vocabulário humano tem `grep` > 0
  nos artefatos derivados?
- **Enforcement afirmado tem de existir.** Regra apresentada como hook/gate **mecânico** e sem
  mecanismo é **pior que nenhuma regra**: o agente confia nela e para de validar. Conferir de fato —
  `git config core.hooksPath`; o hook citado existe?; o `pre-commit` **autodescobre** o arquivo de
  config (`.pre-commit-config.yaml`, não `.pre-commit.yaml`)?
- **A regra vale também para o exemplo da regra.** Uma regra "fato operacional vem do arquivo, nunca
  de memória" cujo **exemplo-âncora** foi escrito de memória ensina exatamente o erro que pretende
  impedir — e quem a aplicar propaga o erro.
- **Citar a origem certa de cada decisão.** O seed de requisitos **não** é mantido vivo (semeia os
  PRDs e para aí); uma decisão posterior mora **no artefato onde nasceu** (`/iterate` no DEFINE, Changelog de
  PRD, ADR de refino) — é **lá** que se rastreia, não no seed. O erro a evitar é o **DEFINE mentir sobre
  a origem**: atribuir ao seed ("conforme o requisito") algo que veio de um `/iterate` e que o seed
  **não diz** — ou até contradiz. Cite a decisão real; nunca finja que o seed a contém.
- **Critério que não diz o que o FALSIFICA é satisfeito por uma fachada.** "A CI passa", "0 ocorrências
  em log", "o runbook está completo" descrevem o **estado desejado** — e são satisfeitos por um mecanismo
  que **existe e não funciona**: CI verde prova que o gate **rodou**, não que **detecta**; "0 ocorrências"
  é o mesmo zero de um **log vazio** ou de um detector que **não casa nada**; "runbook completo" cabe num
  runbook **inexecutável**. Todo gate só fecha quando é **visto ACUSANDO uma falha semeada** (prova
  negativa) **ou** medindo uma **execução que exercitou o que ele mede** (prova de origem). Teste do
  critério: *existe um mundo em que o mecanismo está quebrado e o critério passa?* Se sim, o furo é do
  **critério**, não da task.
- **O falsificador é exigido de critério de DoD, não de toda frase.** Aplicada a todo o texto do
  design, a regra acima faz a superfície auditável crescer sem fim: cada detalhe interno vira critério,
  cada critério pede falsificador, cada falsificador é uma frase nova a auditar. Na 01 a grande maioria
  dos achados de readiness foi desse tipo, e os poucos defeitos reais (conversão de JSON numa conexão
  reaproveitada do pool; anonimização sem checar permissão antes do provedor) apareceriam em minutos num
  teste contra o Postgres real. O sujeito da regra são as métricas do PRD, os critérios de sucesso e os
  testes de aceite do DEFINE; o detalhe de design prova-se por teste e pelo `conformance`.
- **Proibição sem gate é preferência.** Quando o `/design` rejeita uma alternativa por razão
  **comportamental**, pergunte se existe critério que **distinga** a forma rejeitada da escolhida; se
  não existe, o `/build` pode escolher a forma proibida e passar em tudo. Se a rejeição importa, ela
  vira critério de DoD no `DEFINE` antes de o design fechar; se é só preferência entre formas válidas —
  ou rejeição por **custo** ("sem 2º stack", "script em vez de Ansible") — não precisa de gate.
  **Simétrico, e mais traiçoeiro:** descopar um critério leva junto o que morava dentro dele. *Origem:*
  no mesmo ciclo da 00, o plano vedou uma forma de escopo que o critério aprovava; e a redução de um
  critério de deploy levou junto a prova de "nenhuma construção de imagem", deixando o MUST de rollback
  sem nada que o falsificasse. Os dois furos nasceram das próprias correções anteriores.
- **Atribuir um falsificador não é ter um.** A versão disfarçada do furo acima: o design **nomeia um
  critério existente** como falsificador de uma cláusula; como ele existe e roda, tudo parece fechado.
  Teste: escreva a violação e veja se o critério reprova. Se passa nas duas formas, ou a cláusula é
  declaração de escopo (tira-se a atribuição) ou precisa de critério próprio. *Origem:* "esta feature não
  cria usuário em produção" recebeu como falsificador a execução do runbook — que mede que a implantação
  resulta; um runbook **com** o passo proibido também resulta.
- **Regra normativa sem sujeito é lida contra dois objetos.** *Origem:* "o job entra na mudança em que
  seu verificador já existe" foi lido contra a ordem dos passos — auditando uma reconstrução do zero
  que não acontece, insatisfazível sobre a árvore já construída — quando o sujeito devido era a
  **árvore avaliada**. Declarado o sujeito, o falsificador costuma já existir (ali, a execução do CI).
- **O nível da prova é onde a EVIDÊNCIA existe — "prova negativa" ≠ "unit".** Detector sobre lógica pura =
  **unit**. Evidência que depende de **dependência real** (banco, serviço) ou de **execução real** (fluxos
  que têm de ter rodado) = **integração/validação**, **nunca unit** — senão o teste **forja** a evidência e
  reabre o furo que o critério fechou. Se o design descreve a prova **sem fixar o nível**, o downstream a
  aloja no nível errado: **o `/design` fixa o nível por tipo de prova**, o `/build` deriva. *Origem:* a
  prova de "origem do log" — que só existe se login, sessão e navegação tiverem rodado — foi alojada num
  teste unit que estruturalmente não a produz.
- **Prova sobre árvore não commitada evapora no merge.** O `conformance` mede o que será mergeado; se o
  artefato provado só existe na árvore de trabalho, nenhuma revisão contém a prova. *Origem:* um
  `conformance` fechou um critério de proibição estrutural a partir de um teste não rastreado e de dois
  workflows modificados — a prova existia, a revisão não.
- **Build no host prova o código, não a imagem.** *Origem:* o `web/Dockerfile` com `NODE_ENV=production`
  antes do install passou como verde por build local + cache; o boot ao vivo do container é que pegou.
- **Container de serviço único não roda verificação que cruza serviços.** Com compose por serviço, cada
  container monta só o próprio código. *Origem:* o quickstart da 00 mandava `docker compose exec api
  pytest` (imagem `--no-dev`) e `docker compose exec web npm run gen:api` (`../api/openapi.json`
  inexistente no container `web`) — ambos falham no container; o real roda no host ou no CI.
- **Gate estático não substitui execução.** Um verificador que confronta o runbook com os arquivos-fonte
  prova coerência, não executabilidade: não vê autenticação que falta, dono de diretório errado,
  ferramenta ausente no host nem valor obrigatório não documentado. *Origem:* a 1ª execução real do
  `DEPLOY.md` produziu 12 achados com o gate estático verde (#45) — `git clone` que não autentica em repo
  privado, `gh` usado sem ser pré-requisito, script de provisionamento declarando "Concluído" sem
  registrar runner, e 4 variáveis obrigatórias do stack fora do runbook (o `up --wait` trava). Config
  **vendorizada** costuma ficar fora de todos os gates: é o maior arquivo de config e o único sem contrato.
- **O workflow é mergeado antes de ser exercitado.** `workflow_dispatch` só existe se o arquivo estiver
  na branch default — fronteira de segurança: senão qualquer branch rodaria workflow arbitrário com os
  secrets do repo (aqui, um runner self-hosted com acesso à produção). *Origem:* um critério da 00
  nasceu insatisfazível ao exigir disparar, da branch de feature, um workflow que ainda não estava na
  `master` (`404 workflow not found on the default branch`). A intenção "provar antes do merge" estava
  certa; a ordenação, não. O pipeline evolui por PR como qualquer código; quem espera o PR é a aplicação.
- **Nome de container inventado quebra o operador.** *Origem:* o `DEPLOY.md` v1 tratou `api`/`web` como
  se tivessem `container_name` — o nome é derivado pelo orquestrador (`itallus-api-1`/`itallus-web-1`) —
  e citou segredos por apelido ("senha do Postgres") em vez do nome literal da variável.
- **Bloco de estado não ganha PR próprio.** Cada ajuste do bloco de estado do `CLAUDE.md` custaria dois
  PRs e uma release patch; ele muda dentro do PR de transição de feature (abertura ou entrega). Na
  abertura, a branch aponta a feature ativa antes do `/build`: na 02a o bloco mudou depois dos reviews,
  o diff da branch mudou e os relatórios de review e de validação tiveram de ser refeitos.
- **Um gate que valida os artefatos contra ELES MESMOS auto-valida.** O `conformance-gate readiness`, ao
  conferir `DEFINE`/`DESIGN` entre si, tem esse risco: um critério vago **+** um design vago **concordam**
  e passam — por isso é preciso não parar nessa checagem interna. Fechar a classe exige um referente
  **externo**: o **upstream** (fidelidade) ou a **evidência ao vivo** (satisfação) — o papel do
  `conformance` (§8.1/§10). Os dois são **complementares, não redundantes**: o `/iterate` no DEFINE
  **escreve** a régua no critério; o gate **verifica** que ela sobreviveu até o entregável. Sem o
  primeiro, o segundo aprova a fachada.
- **A régua é do planejamento; as fases seguintes só a cobram.** Um gate que procura todo defeito
  possível não converge: cada rodada acha um cenário novo, e a severidade de um cenário que nenhum
  artefato exige fica no julgamento do agente — o mesmo texto sai médio numa rodada e alto na
  seguinte. A feature vai para produção na régua do estágio do produto e se refina pelo uso; a régua
  sobe com evidência de uso (incidente, volume, retorno de usuário), obrigação nova ou decisão do
  responsável, nunca por antecipação de uma fase a jusante. Por isso o planejamento pesa as dimensões
  de risco e declara a régua, e o gate só mede o desvio em relação a ela, com severidade derivada de
  fatos citados (risco × manifestação). Boas práticas e convenções ficam fora dessa conta:
  são a base, cobrada desde a primeira entrega. A régua limita quais cenários o código trata, não a
  qualidade da estrutura — "o mais simples" lido ao pé da letra autoriza o `if` aninhado que trava a
  evolução; o desenho é o melhor para a feature dentro da arquitetura e dos princípios do projeto. E o
  cenário adiado não some: falha de forma explícita onde é detectável e fica registrado com o gatilho
  que o traz de volta. *Origem:* na 06d, duas rodadas seguidas de readiness
  classificaram três achados sobre o mesmo texto como médios e depois como altos; outra rodada deu
  como crítico o requisitante perder a permissão na janela de segundos antes de o reconciliador
  concluir — a correção pedia um lock novo no ciclo de vida do usuário, e o caso foi aceito como
  limite.
- **Gate que protege a letra do documento não deixa a feature sair.** Se a severidade vem do nível do
  documento citado — um MUST do PRD pesa o máximo —, toda variação que o DEFINE ou o DESIGN decidem
  vira bloqueante, e cada correção reescreve prosa que a rodada seguinte audita de novo. O gate
  protege o que não pode ser ferido — a base protegida (segurança, dado pessoal, integridade de dado,
  estrutura, contrato, ADRs) e o DoD da feature —; a variação sem esse risco segue, e o texto de cima
  se sincroniza uma vez, na entrega. Variação sem registro vira pergunta ao responsável, nunca
  aceite silencioso. *Origem:* na 02b, quatro rodadas de readiness deram NÃO PRONTO; oito dos nove
  bloqueantes eram o PRD dizendo uma coisa e o DEFINE ou o DESIGN outra, já decidida — a opção
  "Em branco" em cada filtro, a identidade do CR, a data de cadastro —, e o código a construir
  quase não mudou entre as rodadas. Fora dos gates, um terço das issues abertas era divergência de
  texto do mesmo tipo.

- **Gate que escolhe na dúvida não é reproduzível.** Se a skill deixa o agente supor — ficar com o
  nível menor, aceitar uma prova que o design não declarou, tratar texto de agente como decisão —,
  duas rodadas sobre a mesma entrada classificam a mesma lacuna de jeitos diferentes, e cada rodada
  reabre o que a anterior fechou. A régua fecha essas portas: só prova declarada conta, cláusula a
  cláusula; o risco sai de uma ordem fixa de perguntas; decisão registrada é só a humana explícita;
  sem o fato, o item fica indeterminado e vira pergunta; a resposta vale para as rodadas seguintes.
  *Origem:* na 02b, a mesma lacuna da prova do stub anonimizado saiu médio numa rodada e crítico na
  seguinte; na mesma rodada, uma prova não declarada foi aceita para um critério e recusada para
  outro.

## 10. Lastro humano: rastrear toda exigência a uma decisão registrada

Num projeto SDD **um único autor de IA** escreve os princípios, a constituição, a visão, os ADRs, os
PRDs e o DEFINE. Cada camada cita a anterior como se fosse autoridade externa — e o gate
(`conformance-gate readiness`) valida a cadeia **contra a constituição**, que é parte da cadeia. É o
autor conferindo o próprio trabalho contra as próprias regras. A âncora fora do circuito é o conjunto
de **decisões humanas registradas** — o seed **e** os `/iterate`/refinos logados; sem rastrear a elas,
a cadeia **se autoalimenta**:

```
fonte humana (requisitos)
   │  gancho genérico ("qualidade tipo ISO")   ← o único lastro real, e é FRACO
   ▼
principios.md (IA) — norma no INDICATIVO
   │  endurecimento indicativo → imperativo, não registrado
   ▼
constituição (IA) — MUSTs vinculantes
   ▼
ADRs citam "constituição N" como lei externa → PRDs citam ADR+constituição como lastro de RNF e de gate
   ▼
conformance-gate readiness valida DEFINE/DESIGN CONTRA a constituição
```

**Nenhuma seta sai de uma decisão humana** — nem do seed, nem de um `/iterate`/refino logado (decisão
legítima também entra **downstream**, não só pelo seed).

**Antes das patologias, o que NÃO é patologia:** **divergir do seed não é defeito — é refinamento.**
O seed é obsoleto por construção; modelo, vocabulário e escopo **evoluem** downstream (uma "área" virou
"departamento", um conceito foi absorvido por outro). A auditoria mede **duas** coisas, **ambas
independentes do seed**: **(1) coerência interna do downstream** — o artefato vivo sustenta o que ele
mesmo afirma? — e **(2) rastreabilidade a uma decisão registrada**. O seed entra só como **uma** fonte
possível de decisão em (2), **nunca** como gabarito a comparar. "Está diferente do `requisitos.md`"
**não** é achado.

As três patologias de **proveniência** que a auto-alimentação produz:

| Classe | O que acontece | Como se detecta |
|---|---|---|
| **A. Invenção sem lastro** | Requisito nasce na constituição, vira ADR, vira RNF, vira métrica de gate. Um limiar inventado (`p95 < 50 ms`) chega a **satisfazer o princípio que o exigiu**. | `grep` do termo no seed = **0** **e** ausente de todo `/iterate`/refino logado — mas é MUST e tem gate |
| **B. Comportamento exigido que evapora** | Uma decisão registrada pede um **comportamento** ("retenção **com prazos**, desde a v1"); a cadeia adia em cada camada e o DEFINE certifica "0 pendências". Ninguém é dono. *(Só vale para **comportamento exigido** — não para vocabulário/modelo, que pode ser refinado.)* | Um comportamento de uma decisão registrada segue **"a definir"** em todo entregável, **sem decisão que o adie/dispense** e sem dono |
| **C. Artefato que afirma o falso** | Doc diz que um container/porta/variável/hook existe, e ele não existe; ou diz que algo é "conforme o requisito" quando o requisito diz o contrário. | Confrontar **doc × arquivo** (composes, `.env.example`, código, `git ls-files`) |

### Rotina de auditoria (barata, e o `conformance-gate readiness` não a faz sozinho)

```bash
# 1. Todo MUST tem lastro?  Para cada termo normativo da constituição, procure a DECISÃO humana —
#    o seed OU um /iterate/refino logado (DEFINE "Revision History"/"Open Questions", Changelog de PRD):
grep -ci "<termo>" docs/requisitos.md                           # o seed
grep -rl "<termo>" .claude/sdd/**/DEFINE_*.md docs/prds/        # iterates + PRDs/refinos
#    0 em AMBOS = sem decisão humana atrás → invenção da IA; não pode ser MUST

# 2. MUST órfão (ninguém entrega)?
grep -rl "<termo>" docs/ .claude/sdd/ | grep -v constitution   # vazio = órfão → bomba-relógio

# 3. Corroboração circular (a cadeia citando a si mesma):
grep -rc "constitui" docs/prds/    # alto + (1) = 0  →  o planejamento se autoriza sozinho

# 4. Coerência interna do modelo (SEED-FREE — NÃO se compara com o seed):
#    para cada encadeamento que um artefato VIVO afirma ("X migra e isso muda Y, que muda Z"),
#    confirme que o modelo downstream tem a entidade/campo que carrega X, Y e Z e que o cálculo
#    lê a dimensão certa. Incoerência AQUI (no visao/PRD/código) é bug; divergir do seed, não.
#    Um conceito do seed que sumiu é PERGUNTA (foi refinado de propósito? o downstream fica
#    coerente sem ele?) a resolver no /iterate do DEFINE — nunca veredito de defeito.

# 5. Enforcement fantasma:
git config core.hooksPath && ls .claude/hooks/ 2>/dev/null
ls .pre-commit-config.yaml 2>/dev/null   # se o arquivo tem outro nome, o pre-commit NÃO roda

# 6. Fato operacional × arquivo (classe C):
docker compose config --format json | jq -r '.services[].container_name // "derived"'
#    → nome citado no runbook que não sai daqui é nome inventado
```

**Quando rodar:** ao fechar cada feature e **antes de iniciar a seguinte** — é aí que uma **incoerência
interna do modelo** (checada no downstream, **não** contra o seed) ainda é barata. Uma incoerência que
só aparece quando a feature que depende dela é construída custa muito mais para desfazer.

**Quem responde:** a auditoria **levanta**; quem **decide** é o humano. Um termo que a IA inventou
não se resolve pedindo ao humano que arbitre entre as leituras possíveis dele — resolve-se **na origem**,
reformulando o princípio.
