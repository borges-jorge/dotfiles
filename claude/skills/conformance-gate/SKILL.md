---
name: conformance-gate
description: >-
  Gate read-only de conformidade e DoD. Confronta a cadeia completa de artefatos de
  planejamento (fonte-upstream/ADRs/constituição ↔ PRD ↔ spec/plan/research/data-model/
  contracts/quickstart/tasks ↔ CÓDIGO) para pegar drift de rastreabilidade, satisfação de
  requisito não medida e não-conformidade artefato↔código. Dois modos: readiness
  (pré-/implement) e conformance (pré-PR, exige evidência ao vivo). Agnóstico ao projeto —
  caminhos/IDs/idioma/nomes de artefato vêm do AGENTS.md. NÃO substitui /speckit-analyze — complementa.
argument-hint: "readiness | conformance (default: conformance)"
compatibility: "Spec-kit project (.specify/); artifact paths/IDs/idioma resolvidos via AGENTS.md"
user-invocable: true
disable-model-invocation: false
---

# Conformance / DoD Gate

Gate **read-only** que preenche o buraco estrutural dos gates de fluxo (ex.: `/speckit-analyze`):
eles verificam **consistência interna** e **presença de cobertura** entre `spec`/`plan`/`tasks`,
mas **não** verificam três eixos:

1. **Fidelidade upstream** — o que a fonte-da-verdade (requisitos/visão/ADRs/constituição/PRD)
   exige chegou **íntegro** (não caiu, não enfraqueceu, não vazou escopo) até os artefatos
   downstream.
2. **Satisfação de requisito / DoD** — os gates "sim/não" e critérios mensuráveis foram
   **medidos ao vivo** e deram **sim** (existir uma task ≠ o gate estar satisfeito).
3. **Conformidade com o código** — o que os artefatos **afirmam** existe de fato no repositório
   e/ou **rodando** (o fluxo de spec nunca olha o código).

Esta skill é **agnóstica ao projeto**: não hardcoda caminhos, esquemas de ID nem idioma —
resolve tudo lendo o `AGENTS.md` do projeto onde roda. Opera por **classes de falha** e por uma
**matriz de confronto direcional**, não por casos específicos.

## Postura (INVARIANTE)

- **Aplicar a skill LITERALMENTE — ignorar o contexto externo.** Rodar esta skill = executar
  **exatamente** os passos abaixo, sobre os **artefatos e o código**, e nada mais. O agente
  **NÃO** traz comportamento, julgamento, conclusão, severidade nem veredito da conversa que
  precede a invocação — nem que ele mesmo tenha acabado de "achar" algo. O que já foi dito no
  chat (análises anteriores, `/analyze`, hipóteses, o que "parece" ok/quebrado) **não é entrada**:
  não confirma, não dispensa e não pré-classifica nada. Cada finding renasce **só** da evidência
  que ESTE run coletar. A **única** entrada externa admitida é o **argumento objetivamente
  injetado** na invocação (`readiness`/`conformance` + escopo explícito, quando houver); ausente o
  argumento, a varredura é neutra e completa. Se um fato do contexto for relevante, ele **tem de
  ser re-derivado do artefato/código aqui** para contar — citação de memória do chat não é prova.
- **Read-only.** NÃO modifica nenhum arquivo. Nunca aplica correção. Se propõe remediação, é
  como **texto** — e a correção real entra **pelo fluxo** (corrige o artefato-fonte a montante e
  re-roda o comando para cascatear), NUNCA ad hoc.
- **O humano invoca; o agente assiste.** Esta skill é disparada pelo responsável. Quando um agente
  a executa, ele revisa, roda as provas de evidência, e **reporta** — não conserta o que o gate
  achou (um defeito revelado vira relatório, não edição).
- **Sem viés de foco.** Rodar o gate = varredura neutra da taxonomia inteira; não prefaciar com um
  "foco" que vicie o resultado.

## Passo 0 — Resolver contexto do projeto (a partir do AGENTS.md)

Ler o `AGENTS.md` (e/ou `CLAUDE.md`) do projeto e extrair, SEM assumir:

- **Fonte-da-verdade upstream**: onde vivem requisitos, visão/arquitetura, ADRs, PRDs, constituição
  (paths + em que branch). Ex. comum: `docs/requisitos.md`, `docs/visao-geral.md` (ADRs),
  `docs/prds/NN-*.md`, `.specify/memory/constitution.md`.
- **Artefatos por-feature (Spec Kit)**: rodar
  `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` da raiz e
  parsear `FEATURE_DIR` + `AVAILABLE_DOCS` (`spec.md`, `plan.md`, `research.md`, `data-model.md`,
  `contracts/`, `quickstart.md`, `tasks.md`, `checklists/`). Se o script não existir, usar os
  caminhos que o `AGENTS.md` declarar.
- **Esquema de IDs**: como requisitos/objetivos/métricas/critérios são numerados no PRD vs. no spec
  (ex.: PRD `O0.x`/`RF0.x`/`RNF0.x`/`M0.x` + `ADR-xxx` → spec `FR-xxx`/`SC-xxx` → tasks `T0xx`).
  Derivar o cross-map a partir do que se lê, não de um esquema fixo.
- **Convenções de fluxo/branch/PR**: qual branch recebe o merge (ex.: `qa`), como o PR é aberto,
  quais gates de CI existem. Usar isso para saber **quando** o gate `conformance` é obrigatório.
- **Idioma do relatório**: seguir o idioma de comunicação declarado no `AGENTS.md`.

Se o projeto **não** declarar algo, cair nos defaults do Spec Kit e **registrar a suposição** no
relatório (classe D).

## Modos

Argumento: `readiness` ou `conformance` (default `conformance`).

- **`readiness`** — roda **após `/tasks`, antes de `/implement`**. Confronta **só documentos**
  (upstream → spec → plan/research/data-model/contracts → tasks). Pega drift/enfraquecimento/
  scope-creep/pontos de interpretação/contradição-na-fonte **antes** de codar. **Não** executa
  código (pode não existir ainda) e **não** exige evidência ao vivo.
- **`conformance`** — roda **após `/implement`, antes de PR / de declarar "done"**. Faz tudo do
  `readiness` **+ artefato↔código + satisfação de DoD com evidência ao vivo**. Pega
  placeholder-marcado-pronto, `[X]` sem entregável real, serviço/arquivo/rota faltando, e gate
  "sim/não" **não medido**.

## Taxonomia de falhas (A–E) — o backbone

Rodar as cinco classes. São ortogonais ao que o `/analyze` cobre.

- **A. Drift de rastreabilidade (upstream → downstream).**
  Requisito/objetivo/métrica/critério/constraint/item **in-scope** da fonte que foi **dropado** ou
  **enfraquecido** downstream (ex.: um DoD "sim/não" virou uma task-esqueleto). Item **Fora de
  escopo** que **vazou** pra dentro (scope creep). Decisão de **ADR/visão** não refletida ou
  **contradita**. **Contradição latente na própria fonte** (ex.: a mesma métrica exigida numa
  seção e diferida noutra) — **sinalizar** para decisão humana, nunca resolver em silêncio para um
  lado.
- **B. Satisfação / DoD não medida.**
  Cada critério "sim/não" ou mensurável precisa de **evidência real** de que passou. Cada
  **acceptance scenario** (Given/When/Then) exercitado por teste/verificação. Cada **MUST**
  funcional com teste que **prova** o comportamento (não só código que "deveria").
- **C. Não-conformidade artefato↔código** *(só `conformance`)*.
  Arquivos/caminhos citados nas tasks **existem**; componentes/serviços que os artefatos afirmam
  (stack, workflows, endpoints) **existem** e (quando aplicável) **rodam**; contrato = superfície
  servida; modelo de dados = schema real; rotas batem; variáveis de ambiente batem. **Detecção de
  placeholder** marcado como pronto (`echo`/`pass`/`TODO`/`FIXME`/`NotImplemented`/stub vazio onde
  a task diz "entregue"). **Integridade do `[X]`**: task marcada concluída cujo entregável é
  esqueleto.
- **D. Risco de interpretação.**
  Todo ponto onde um artefato deixou "a definir"/"diferido"/ambíguo e **alguém resolveu
  unilateralmente** um lado → listar para **confirmação humana** (torna decisão implícita em gate
  explícito). Adjetivo qualitativo dado como "satisfeito" sem medida concreta. Assumption feita e
  **não registrada**.
- **E. Higiene estendida.**
  Drift de terminologia/número/enum/ordem/slug entre **todos** os artefatos **e** o código.
  Referência morta (doc cita arquivo/flag/rota que não existe mais).

## Matriz de confronto (direcional; a fonte-upstream é a verdade no topo)

| Confronto | O que procurar | Classes |
|---|---|---|
| requisitos/visão/ADRs/constituição/PRD → **spec** | fidelidade: nada dropado/enfraquecido/vazado | A |
| **spec** → plan/research/data-model/contracts | design realiza cada requisito/critério; deferrals **explícitos e justificados**, não silenciosos | A, D |
| spec + plan → **tasks** | cobertura que **satisfaz** (não só referencia) cada requisito/critério/acceptance | A, B |
| tasks + spec → **código + testes** *(conformance)* | implementado de fato; DoD **medido**; sem placeholder-marcado-pronto | B, C |
| **código** → artefatos *(conformance)* | reverso: o código bate com o que foi afirmado; divergência não-documentada | C, E |

Confrontos **direcionais** (não todos-contra-todos): a fonte-upstream manda; cada camada downstream
tem de **realizar** o que a de cima exige.

## Regra de evidência (modo `conformance`) — o coração do gate

Para **cada** critério/métrica/gate "sim/não" e cada acceptance scenario:

1. Derivar dos artefatos **como se prova** (o comando/observação que torna o critério verdadeiro).
   Nunca hardcodar; ler do quickstart/plan/tasks/CI o que o próprio projeto define como prova.
2. **Rodar a prova** (ou, se exigir recurso indisponível, emitir o **comando exato** e marcar
   pendente com a razão). Capturar a saída como evidência.
3. Classificar o resultado no **ledger** (abaixo). Só marca **VERIFICADO(sim)** com **evidência
   real** anexada. Ausência de evidência ⇒ **NÃO-MEDIDO** (não é "provavelmente ok").

Formas típicas de prova ao vivo (derivadas, não fixas): subir o ambiente e conferir serviços/health;
aplicar o schema do zero; rodar a suíte de testes/gates de CI; medir uma meta de performance; dirigir
a UI headless (ex.: Playwright) para os acceptance scenarios; comparar contrato gerado vs. servido.

## Severidade

Seguir o padrão do `/speckit-analyze` e endurecer no eixo de DoD:

- **CRITICAL** — DoD/critério "sim/não" **não satisfeito** ou **NÃO-MEDIDO**; MUST funcional sem
  prova; requisito in-scope **dropado/enfraquecido**; placeholder marcado como pronto; violação de
  princípio da constituição (constituição = CRITICAL automático). **Bloqueia "done"/PR.**
- **HIGH** — requisito conflitante/ambíguo em atributo crítico; acceptance não exercitado; deferral
  sem justificativa explícita.
- **MEDIUM** — drift de terminologia/enum/ordem; cobertura não-funcional faltando; edge case
  subespecificado.
- **LOW** — redação/estilo; redundância menor; referência morta cosmética.

## Saída (read-only)

Emitir, **no idioma do projeto**:

### 1. Tabela de findings
`| ID | Classe (A–E) | Severidade | Origem (requisito/ID) | Onde quebrou (artefato:linha ou código:arquivo) | Lacuna de evidência | Ação de fluxo (qual upstream corrigir + re-rodar qual comando) |`

### 2. Ledger de conformidade por requisito *(o entregável central)*
Uma linha por requisito/critério/métrica rastreável:
`| ID | Enunciado (curto) | Estado | Evidência / comando |`
onde **Estado ∈ `VERIFICADO(sim)` · `FALHOU` · `NÃO-MEDIDO` · `N/A`**. No modo `readiness`, o estado
máximo possível é "coberto por task adequada"/"não coberto" (sem execução); no `conformance`, exige
evidência ao vivo para os "sim/não".

### 3. Métricas
Total de requisitos rastreados · % VERIFICADO(sim) · # NÃO-MEDIDO · # CRITICAL · # por classe.

### 4. Veredito
- `conformance`: **APROVADO para PR/done** só se **0 CRITICAL e 0 NÃO-MEDIDO** em requisitos de DoD.
  Caso contrário **BLOQUEADO**, listando exatamente o que falta medir/corrigir.
- `readiness`: **PRONTO para /implement** se não houver drift/enfraquecimento/contradição-na-fonte
  pendente; senão, listar o que reconciliar **antes** de codar (via correção do upstream + re-rodar).

### 5. Remediação (proposta, não aplicada)
Perguntar ao responsável se quer sugestões concretas de remediação para os top-N — **sem aplicá-las**.
Cada sugestão aponta o **artefato-fonte a corrigir** e **qual comando re-rodar** para cascatear
(nunca "editar o downstream à mão").

## Hooks de extensão

Se o projeto tem `.specify/extensions.yml`, emitir os blocos before/after como as demais skills do
fluxo (mesma mecânica de mapear `command` com pontos → slash com hífens, respeitar `enabled`/`optional`,
não avaliar `condition`). Esta skill **não** registra hooks próprios — o Spec Kit só suporta hooks das
extensões instaladas; o "sempre rodar" é enforçado pelo `AGENTS.md`/playbook do projeto, não por hook.

## Done When

- [ ] Contexto do projeto resolvido a partir do AGENTS.md (paths/IDs/idioma/branch de PR).
- [ ] Taxonomia A–E rodada na matriz de confronto direcional (código incluído no modo conformance).
- [ ] Ledger de conformidade emitido; cada DoD "sim/não" com estado + evidência (conformance) ou
      cobertura (readiness).
- [ ] Veredito (APROVADO/BLOQUEADO ou PRONTO) com CRITICAL/NÃO-MEDIDO explicitados.
- [ ] Nenhum arquivo modificado; remediação apenas proposta.
