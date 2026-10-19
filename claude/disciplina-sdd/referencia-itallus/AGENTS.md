# itallus — Guia para agentes

**itallus** é um projeto Python (gerenciado com **uv**) — sistema interno de
**pós-venda / gestão de contratos** da diretoria de planejamento. Seed de requisitos em
`docs/requisitos.md`; visão geral em `docs/visao-geral.md`; PRDs agrupados por épico em `docs/prds/`.
A implementação roda pelo **AgentSpec, uma feature por vez** (a feature ativa fica no bloco AGENTSPEC
do `CLAUDE.md`). Entregues na `master`: a **fundação (00)** — monorepo **`apps/api`** (FastAPI, Clean
Arch/Ports & Adapters), **`apps/web`** (Next.js) e **`infra/supabase`** (stack Supabase self-hosted,
vendorizado), artefatos congelados em `specs/` — e o **controle de acesso (01)**, arquivado em
`.claude/sdd/archive/`. Detalhe de stack/estrutura mora no DESIGN da feature (não duplicar aqui).
O racional e os casos de origem das regras abaixo estão em `docs/roteiro-sdd.md` (§9 e §10).

## Stack e ferramentas
- **Python >= 3.12**, gerenciado com **uv** (`uv sync`, `uv run ...`).
- **black / ruff** — checados no **CI** (`ci.yml`, job `api-lint`, em `apps/api`); **não** há
  git hook local que os rode automaticamente.
- **pre-commit** — existe um `.pre-commit.yaml` (`check-yaml`, `black`, `check-added-large-files`
  máx. 500 kb), mas ele **NÃO está ativo**: o repo usa `core.hooksPath=.githooks`. Rodar sob
  demanda: `pre-commit run --all-files` (para `pre-commit install` autodescobrir, o arquivo teria
  de se chamar `.pre-commit-config.yaml`).
- **Hooks versionados** em `.githooks/`: guarda de branch (`pre-commit`, `pre-push`) e validação
  do assunto do commit (`commit-msg`, via `scripts/check_subject.sh`).

## Contribuição — os templates são a regra

Cada artefato tem um template, e é nele que a regra está escrita, no momento de uso:

| Artefato | Template | Quem cobra |
|---|---|---|
| commit | `.gitmessage` (ligado pelo hook `post-checkout`) | `.githooks/commit-msg` — bloqueia |
| issue | `.github/ISSUE_TEMPLATE/` — bug, tech-debt, chore | `check-issue.yml` — sinaliza e comenta |
| pull request | `.github/PULL_REQUEST_TEMPLATE.md` | `check-pr-direction.yml` — título e corpo |
| release notes | `.github/RELEASE_TEMPLATE/release-notes.md` | `check-release.yml` — sinaliza |
| argumento de `/iterate` | seções `Mudança:`, `Fato provado:` e `Hipótese:` (Fluxo AgentSpec) | `.claude/hooks/check_iterate_argument.py` — bloqueia |
| relatório de review | `.claude/sdd/templates/REVIEW_REPORT_TEMPLATE.md` (Gates) | `/conformance-gate conformance` — bloqueia |
| relatório de validação | `.claude/sdd/templates/VALIDATION_REPORT_TEMPLATE.md` (Gates) | `/conformance-gate conformance` — lê como evidência |

Assunto e título passam por `scripts/check_subject.sh`; os corpos, por `scripts/check_body.sh`.
Uma implementação por regra, várias portas. **Uma issue por achado:** cada issue é uma unidade que
fecha sozinha, nunca uma lista de achados.

**Versionamento — automático.** SemVer em `0.x`: desde a última tag, um commit `feat` ou uma quebra
declarada faz minor, qualquer outro faz patch. Quando a CI fecha verde na `master`, o job `release`
calcula a versão a partir dos tipos dos commits, cria a tag e publica a release com as notas
montadas dos assuntos (`scripts/next_version.sh`), assinadas como geradas automaticamente. Ninguém
publica versão à mão. A `v1.0.0` fica para quando a primeira feature de gestão de contratos
(épico E3) estiver em produção.

**`master` e `qa` são protegidas** — commit e push diretos são bloqueados por hook local e
revertidos por workflow. O merge tem direção única, **`<tipo>/* → qa → master`**, sempre por
Pull Request, e a branch de trabalho é **`<tipo>/<nome>`** com `tipo` em
`feature | fix | chore | docs | refactor | test`.

## Planejamento

### Épicos e features
- A quebra em **épicos** e **features** segue a skill **`/decompose-requirements-with-the-planner`**,
  que carrega as regras (hierarquia, feature grande demais, IDs estáveis, dono no corte, restrição
  repetida, ordem pelo grafo). Neste projeto:
  - épico = diretório `docs/prds/E<n>-<slug>/`, com objetivo e critério de pronto na visão;
  - feature = `docs/prds/E<n>-<slug>/<id>-<slug>.md`, **1 PRD = 1 ciclo do AgentSpec**;
  - cenário = story da feature, no DEFINE.
- **ID de feature estável** (`00`, `06a`). Requisitos do PRD com os prefixos `O`, `RF`, `RNF` e `M`
  mais o número da feature de origem; num recorte, o requisito mantém o ID que tinha (`RF2.4` na
  `02b`).

### Artefatos de planejamento
- O **the-planner** (AgentSpec) é o único escritor da **visão** e dos **PRDs** — a fonte da verdade
  do planejamento —, por duas skills: **`/decompose-requirements-with-the-planner`** cria o plano a
  partir do documento de requisitos e reformula em dois ou mais o PRD que se revela grande demais;
  **`/refine-prd-with-the-planner`** refina o PRD de uma feature já decomposta. O brainstorm decide;
  não escreve PRD. As **seções da visão não se renumeram** — constituição, PRDs e specs citam os
  números.
- **Template do PRD:** 8 seções em pt-BR — Problema · Contexto · Objetivos · Solução Proposta ·
  Requisitos · Métricas · Fora de escopo · Riscos e dependências — mais o rodapé `## Changelog`
  (Versão · Data · Autor · Mudança). O cabeçalho nomeia o épico.
- **Altitude:** PRD e visão carregam **problema, resultado, regra de negócio e restrição**. Mecanismo
  (rotas, schema, policies, forma de token, nomes de tabela) mora só no **DESIGN**; ADR registra a
  **decisão**, não a implementação. Decisão fechada no `/design` que resolve um `[a definir]` da visão
  fecha lá **com remissão ao DESIGN**, sem copiar o mecanismo. O cross-feature (arquitetura, ADRs,
  modelo de domínio) mora na visão.
- **`docs/requisitos.md` é SEED IMUTÁVEL.** Semeou visão e PRDs e não se atualiza; as decisões
  posteriores ficam **onde nascem** (Revision History/Open Questions do DEFINE, `## Changelog` de PRD,
  ADR de refino). Divergir do seed **é refinamento, não defeito**; o seed não é gabarito de auditoria;
  nunca atribuir ao seed uma decisão de refino. *("Requisito" na visão/PRDs costuma ser o seed; num
  DEFINE é o PRD da feature.)*
- **Todo MUST rastreia a uma decisão humana registrada** (o seed ou um `/iterate`/refino logado) —
  sem lastro, não é MUST. Princípio genérico legitima a existência dos pilares, não uma cláusula
  derivada. **Item em aberto nunca vira "default razoável"**: vira pergunta ao responsável ou fica
  marcado. (Rotina de auditoria: roteiro §10.)
- **Onde cada decisão mora:** nos próprios artefatos — AgentSpec (`DEFINE`/`DESIGN`/`BUILD_REPORT`,
  em `.claude/sdd/`) e the-planner (visão + PRDs/ADRs). Nada de `.md` ad hoc de controle no repo;
  estado volátil fica na memória do agente. O **bloco de estado do `CLAUDE.md`** muda só dentro de PR
  de transição de feature (abertura ou entrega), nunca em PR próprio. Na abertura, a branch da feature
  aponta a feature ativa no bloco antes do `/build`: mudança depois dos reviews tira a âncora dos
  relatórios.
- **Cenário de validação ≠ runbook.** Aceitação no DEFINE, estratégia de teste no DESIGN; setup de
  ambiente mora no `README.md` (dev) e no `DEPLOY.md` (produção).

### Régua de exigência
A feature vai para produção na régua do estágio do produto e se refina pelo uso. O processo cobra a
régua declarada, não a perfeição. A régua limita **quais cenários** o código trata, nunca **a
qualidade da estrutura**.
- **Base fixa, desde a primeira entrega:** constituição, convenções deste arquivo, ADRs e regras de
  CI, onde entram segurança e obrigação legal. Inclui a qualidade estrutural: Clean Architecture
  (regra de dependência entre camadas, ports & adapters), SOLID, clean code, padrões de projeto e
  de mercado. Não varia com o estágio do produto.
- **Régua que sobe com o uso:** robustez para cenário raro, escala além do uso atual, automação de
  operação rara, observabilidade profunda e cobertura exaustiva de casos de borda. Sobe só com
  justificativa registrada: evidência de uso (incidente, volume, retorno de usuário), obrigação nova
  ou decisão do responsável.
- **Quem define a régua é o planejamento** (brainstorm e refino), e quem decide é o responsável.
  Impacto, probabilidade, reversibilidade, detectabilidade, alcance e evidência de uso pesam nessa
  decisão: operação irreversível ou silenciosa pode justificar declarar cedo a proteção contra um
  cenário raro.
- **Nenhuma fase depois do planejamento sobe a régua sozinha.** O que define, design, build e gate
  encontram além dela vira evolução registrada, com o gatilho que a justificaria; não vira requisito
  nem bloqueio.
- **Acima da régua não é ignorado.** Onde o código consegue detectar o cenário, falha de forma
  explícita — erro tratado, mensagem clara, log —, nunca em silêncio; isso é base. O tratamento
  completo do cenário vira evolução registrada.
- **Registro de evoluções:** issue com a label `deferred`, no template "Tech-debt / deferred", uma
  por item, com a origem (feature e artefato) e o gatilho que a traz de volta. Cada fase lista o que
  adiou; o agente principal abre as issues com o aval do responsável. O registro é consultado no
  brainstorm e no refino de cada feature (as `deferred` da mesma área) e quando um incidente em
  produção bate com um item registrado.
- **Por fase:**
  - **brainstorm** — o que passa da régua sai como evolução a registrar, não como requisito;
  - **refino** — o adiado vai para o Fora de escopo do PRD, com o gatilho, e para o registro; MUST
    que sobe a régua sem justificativa registrada vira pergunta;
  - **define** — critério e teste de aceite só para requisito em vigor; as linhas de caso de erro e
    de borda do template entram quando um requisito em vigor as cobre; cenário raro que a régua
    exige entra declarado no critério ou no falsificador; borda além da régua vira limite declarado
    e evolução registrada;
  - **design** — a melhor solução para a feature no estágio atual, dentro da base estrutural; a
    escolha de padrão é decisão registrada no `DESIGN`. Cenário fora da régua não ganha mecanismo
    próprio (retry, lock, reconciliação, fila), e a estrutura deixa ponto de extensão onde há
    evolução registrada, nunca por especulação. As seções de tratamento de erro, segurança e
    observabilidade do template cobrem o que o `DEFINE` e a base exigem;
  - **gates** — o `conformance-gate` mede o desvio em relação à régua e à base; o que a régua não
    exige é observação de maturidade, não bloqueia e, aceita pelo responsável, vira evolução
    registrada;
  - **ship e produção** — limites e evoluções ficam listados no arquivamento, com a issue de cada
    um; problema observado em uso volta pelo refino e sobe a régua.

### Caminho de entrega: PRD ou tarefa simples
Feature entregue não é reaberta: mudança posterior no que ela entregou é entrega nova. O peso dessa
entrega segue o critério abaixo, aplicado por issue antes de o trabalho começar.
- **Exige PRD** (ciclo completo do AgentSpec) o trabalho que atende a pelo menos um destes:
  1. só se prova correto **executando** (teste, stack ou deploy) — ler o diff não basta;
  2. muda **comportamento em execução** do sistema ou da operação (resposta da API, tela, dado
     gravado, deploy, rollback);
  3. muda **requisito, regra de negócio ou restrição** (corrigir fato desatualizado não conta);
  4. toca **segurança, LGPD ou schema de banco**.
- **Tarefa simples** é o que não atende a nenhum: PR direto `docs`, `chore` ou `fix`, sem PRD. Em
  documento de planejamento (visão, PRD), a correção entra pelo `/refine-prd-with-the-planner`, sem
  abrir PRD novo.
- **PRD compartilhado só por resultado comum:** issues dividem um PRD quando fechar uma sem a outra
  deixa o mesmo resultado incompleto. Tocar o mesmo arquivo não basta; correções sem ligação direta
  não se juntam para aproveitar o fluxo.
- **Classificação registrada e validada:** a seção `## Delivery` da issue traz o caminho e o critério
  que o decide, com a avaliação do agente sobre o caso de fronteira (risco, reversibilidade,
  alcance). O responsável valida aplicando a label `delivery:prd` ou `delivery:simple`; sem a
  label, o trabalho não começa.

### Fluxo AgentSpec
- **Fluxo, uma feature por vez:**
  1. `/decompose-requirements-with-the-planner` com o documento de requisitos → visão + PRDs por
     épico (uma vez por plano).
  2. `/brainstorm` da feature.
  3. `/refine-prd-with-the-planner` com o brainstorm e o PRD da feature. Os passos 2 e 3 se
     repetem até o PRD ficar adequado, a critério do responsável.
  4. Ciclo do AgentSpec: **Define → Design → Build → Ship**.

  Durante o ciclo, uma decisão que muda requisito, regra ou restrição da feature volta ao PRD pelo
  `/refine-prd-with-the-planner`, com ou sem brainstorm. Feature que se revela grande demais volta
  ao `/decompose-requirements-with-the-planner` para ser reformulada em dois ou mais PRDs. O
  AgentSpec não decompõe o projeto nem cruza features: a **constituição**
  (`docs/constitution/constitution.md`) é a âncora cross-feature, aplicada pelo `conformance-gate`.
- **Quem invoca é o responsável:** as fases e as skills do projeto
  (`/decompose-requirements-with-the-planner`, `/refine-prd-with-the-planner`, `/conformance-gate`).
  Dentro do `/build` a delegação a especialistas é automática, a partir do File Manifest aprovado.
  Gate humano em dois pontos: aprovar o `DESIGN` e o `conformance-gate` antes do PR.
- **Cada comando roda pelo agente que nomeia**, nunca inline (`agentspec:workflow:<fase>-agent`; o
  `the-planner` na decomposição e no refino). O agente principal passa só entrada e postura, repassa as perguntas do
  agente da fase sem alteração, uma por vez, e revisa e reporta a saída; não decide pelo responsável.
- **Argumento de comando = só ESCOPO, nunca COMPORTAMENTO.** Diz o que mudou em requisito/negócio; o
  comando deriva a saída. Nada de "refazer só X", "não resetar", "ancorar no arquivo Y". Sem argumento
  de direcionamento a saída é neutra; foco só por argumento revisado pelo responsável.
- **Downstream é derivação — nunca editar à mão.** Código e `BUILD_REPORT` derivam do File Manifest do
  `DESIGN`; o `DESIGN` deriva do `DEFINE` + ADRs. A mudança entra pelo **topo da cadeia**:
  `/refine-prd-with-the-planner` (fonte) ou `/iterate` no `DEFINE` (requisito) ou no `DESIGN`
  (design), e cascateia até o `/build`. Entregável errado é sintoma de furo a montante; achado
  cosmético ou derivado não se mexe.
- **Escrita por comando:** `DEFINE` e `DESIGN` são **incrementais** (`/iterate` bumpa a Revision
  History e cascateia; resíduo neles não some por re-rodar, corrige-se na origem); o `/build`
  **regenera** o código e escreve o `BUILD_REPORT`; cada rodada de review **regenera** o próprio
  relatório. Não há `tasks.md`: o que já roda é medido pelo `conformance-gate` (roteiro §8.2).
- **Afirmação de mecanismo é provada antes de virar decisão.** Quando uma decisão depende de como o
  código já entregue ou uma biblioteca com estado se comporta (RLS, transação, sessão, provedor), o
  `DESIGN` cita a prova — o trecho de código (arquivo e linha) ou a execução que a mostrou; sem prova,
  a afirmação fica marcada como hipótese. O agente do `/design` tem shell para ler e provar; o do
  `/iterate` não, então no `/iterate` o agente principal prova antes de montar o argumento, que passa
  o comportamento verificado como fato. O `readiness` reprova afirmação de mecanismo sem prova citada.
- **Argumento de `/iterate` em três seções:** `Mudança:` (o que muda em requisito ou design),
  `Fato provado:` (cada afirmação de mecanismo com a prova — a execução que a mostrou ou o
  arquivo e a linha) e `Hipótese:` (o que não foi provado, ou "nenhuma"). O hook
  `.claude/hooks/check_iterate_argument.py` barra a chamada ao agente do `/iterate` sem as três.
- **Decisões em lote, uma passada por camada.** As decisões de uma rodada (gate, teste, revisão)
  entram juntas: um refino, depois um `/iterate` no `DEFINE` e um no `DESIGN`, nessa ordem e só nas
  camadas que a decisão alcança — nunca um `/iterate` por achado.

### Critérios e provas
Estas regras recaem sobre **critérios de DoD**: métricas do PRD, critérios de sucesso e testes de
aceite do DEFINE. Detalhe interno de design prova-se por teste e pelo `conformance`, sem
falsificador próprio.
- **Todo critério de DoD declara o que o falsifica.** Fecha só **visto acusando uma falha semeada** ou
  **medindo uma execução que exercitou o que ele mede** — "roda e passa" não basta. Teste: *existe um
  mundo em que o mecanismo está quebrado e o critério passa?* Se sim, conserta-se o critério
  (`/iterate` no `DEFINE`).
- **Proibição comportamental que importa vira critério de DoD** que distinga a forma vedada da
  escolhida; sem isso é preferência. Rejeição por custo ou escolha entre formas válidas não precisa
  de gate. Ao descopar um critério, varra o que ele media.
- **Atribuir um falsificador não é ter um:** escreva a violação e confira se o critério apontado
  reprova; se passa nas duas formas, a atribuição é falsa.
- **Regra normativa declara seu sujeito** — sem ele, o gate a lê contra o objeto errado.
- **O nível da prova é onde a evidência existe:** detector sobre lógica pura = unit; evidência que
  depende de dependência ou execução real = integração/validação, nunca unit. O `/design` fixa o
  nível por tipo de prova.
- **Evidência ancorada numa revisão:** prova sobre arquivo modificado ou não rastreado é NÃO-MEDIDA;
  a árvore está limpa antes da coleta.
- **DoD sobre container/imagem** fecha só com build limpo (`docker compose build --no-cache`, ou
  imagem comprovadamente construída neste run) + `docker compose ps` healthy + probe real na superfície
  do serviço, capturados. Build/teste no host prova o código, não a imagem.
- **Verificação que cruza serviços** (drift OpenAPI→client, testes com dependências, export de
  contrato) roda no host de dev ou no CI, nunca por `docker compose exec` num serviço: cada container
  monta só o próprio código (ADR-011).

### Gates (`/conformance-gate`)
- **`readiness`, antes do `/build`:** consistência DEFINE↔DESIGN e fidelidade ao upstream
  (PRD/visão/ADRs/constituição). Achado **crítico ou alto bloqueia o `/build`**; médio e baixo viram
  issue, uma por unidade que fecha sozinha.
- **Reviews, depois do `/build` e antes do `conformance`:** o responsável roda
  `/code-review high origin/qa...HEAD` (sem `--fix`) e `/security-review` sobre o commit do build,
  com a árvore limpa. O agente principal grava a saída de cada um, sem alteração, em `.claude/sdd/reports/CODE_REVIEW_{FEATURE}.md` e
  `SECURITY_REVIEW_{FEATURE}.md`, no template, e commita os dois num commit próprio. O review não
  classifica nem decide: cada achado é candidato que o `conformance` prova, filtra e classifica. O
  relatório vale enquanto o diff contra a base que ele declara for o que ele revisou (o code review
  compara com a `qa`, pelo alvo explícito; o security review, com a `master`); mudou o diff, roda-se
  de novo. O `/ship` arquiva os dois relatórios com a feature.
- **Validação que o gate não consegue repetir** (exige credencial do responsável): o responsável
  roda a execução que o `DESIGN` define, no terminal dele, sobre o commit do build e com a árvore
  limpa. O agente principal grava a saída, sem alteração, em
  `.claude/sdd/reports/VALIDATION_{FEATURE}.md`, no template, num commit próprio. O `conformance` lê
  o relatório como evidência dos critérios que a execução prova; vale enquanto o código contra a
  `qa` for o validado.
- **`conformance`, antes do PR para `qa` ou de declarar a feature pronta:** confronta artefatos↔código
  e exige evidência ao vivo. **Critério de DoD não medido ou falhando bloqueia sempre**; os demais
  achados seguem o limiar do `readiness`. Relatório de review ausente, ou cujo diff contra a base
  declarada mudou, bloqueia. É a única trava forte depois do código — obrigatório sem exceção.

## Convenções
- **Idioma — comunicação:** **pt-BR**.
- **Idioma — código:** **inglês (en-US)** em identificadores, nomes de tabelas/colunas,
  comentários e docstrings. **Exceções** (nomes próprios do domínio brasileiro): `CNPJ`, a tabela
  legada `tbcencus`, e os códigos da empresa `BR` / `PCR` / `SPC`. Conceito em pt-BR nos docs ↔
  identificador em inglês no código (ex.: Colaborador → `employee`, Contrato Jurídico →
  `legal_contract`, Departamento → `department`, Fechamento mensal → `monthly_close`).
- **Idioma — documentação:** **pt-BR é a fonte da verdade**; en-US é derivado, gerado sob demanda
  quando o documento estabiliza, só nos docs de mantenedor (README, visão geral, ADRs, constitution).
  PRDs ficam em pt-BR.
- **Idioma — issues:** **en-US** em título, corpo e labels. (O chat segue pt-BR.)
- Config de agente compartilhada em `.claude/` é versionada; segredos e configurações pessoais
  (ex.: `settings.local.json`) ficam fora.
- **Config (`.env`) por componente, nunca na raiz:** `infra/supabase/.env` (stack), `apps/api/.env`
  (backend), `apps/web/.env.local` (frontend). Versiona-se só o `.env.example` ao lado de cada um; o
  `.env` real é git-ignored. Segredos compartilhados (JWT secret, chaves, senha do Postgres) batem
  entre os arquivos.
- **Deploy nos artefatos assume ambiente-alvo sem conflitos:** o único pré-requisito é que portas e
  nomes de container do stack estejam livres no host. Nunca embutir contexto operacional transitório
  (stack legada, tear-down para liberar portas) em altitude nenhuma. (A decisão de custo "sem 2º
  stack" é legítima.)
- **Repositório agnóstico ao ambiente-alvo:** nomes de pasta/arquivo e títulos usam **papel**
  (`infra/deploy`, "host de produção"), não tecnologia do alvo. A decisão de ambiente mora no ADR
  (ADR-010), uma vez.
- **`DEPLOY.md` — foco único, autocontido:** só como fazer o deploy, com tudo que o operador precisa —
  pré-requisitos concretos, placeholders explicados, cada etapa comentada, frontmatter, fluxo visual
  onde ajudar. Sem meta-informação e sem escopo de dev (prova de mecanismo e DoD moram no `DESIGN`).
- **Runbook fecha só executado do zero em host limpo;** gate estático prova coerência, não
  executabilidade. Cada desvio necessário na execução é um achado.
- **Pipeline mora na linha principal:** `workflow_dispatch` só existe para workflow que está na branch
  default. Nunca projetar prova que dispare, de uma branch, workflow que ainda não está na `master`; o
  workflow é mergeado antes de ser exercitado.
- **Fato operacional vem do arquivo, nunca de memória:** portas e nomes de container ← composes;
  variáveis ← `.env.example` de cada componente, pelo **nome literal** e com o mapeamento
  origem→destino. Container sem `container_name` (`api`, `web`) é descrito como nome derivado pelo
  orquestrador.
- **Código diz o quê; o porquê mora nos docs de design** (`DESIGN`, visão/ADRs). Nada de racional ou
  referência de ADR em comentários, `summary`/`description`; comentar só quando agrega valor.
- **Identidade visual:** marca Italtel. O design system (`apps/web/design-system/MASTER.md`, gerado
  pelo ui-ux-pro-max) ancora nessa identidade (visão, ADR-005).

## Postura do agente
- **Verificar antes de afirmar:** distinguir fato verificado de hipótese; confirmar comportamento de
  código/biblioteca/versão na fonte; nunca usar flags, parâmetros ou APIs presumidos.
- **Crítica e risco proativos:** sinalizar riscos (ponto único de falha, race condition, segurança,
  débito, custo de reversão) e discordar de abordagem inferior **antes** de implementar.
- **Pesquisa sob incerteza:** pesquisar antes de responder (doc da versão exata) e sinalizar a
  incerteza antes, não depois.
- **Mudança de código segue o caminho validado da issue:** `delivery:prd` passa pelo fluxo do
  AgentSpec (`/build` a partir do `DESIGN`); `delivery:simple` vai em PR direto. Durante verificação
  o agente só testa e reporta (arquivo, sintoma, impacto); a correção entra pelo caminho validado
  quando o responsável decidir.
- **Artefato sem meta-informação:** o que o agente gera contém só o que serve ao leitor do artefato —
  nada de narração do caminho, "decidido nesta sessão", refs a tasks/ADR ou justificativa de existência.
- **Não narrar a própria disciplina nas respostas:** aplica-se a regra e pronto; a resposta traz o
  resultado, o achado e a decisão pendente.
