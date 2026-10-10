---
name: conformance-gate
description: >-
  Gate read-only de conformidade e DoD. Confronta a cadeia completa de artefatos de
  planejamento (fonte-upstream/ADRs/constituição ↔ PRD ↔ DEFINE/DESIGN/BUILD_REPORT ↔ CÓDIGO)
  para pegar drift de rastreabilidade, satisfação de requisito não medida e não-conformidade
  artefato↔código, contra a régua que o projeto declarou — não busca a perfeição do software.
  Dois modos: readiness (pré-/build) e conformance (pré-PR, exige evidência ao vivo). Agnóstico ao
  projeto — caminhos/IDs/idioma/nomes de artefato vêm do AGENTS.md. Complementa os gates fracos do
  fluxo SDD (no AgentSpec não há gate de consistência cross-artefato nativo).
argument-hint: "readiness | conformance (default: conformance)"
compatibility: "AgentSpec project (.claude/sdd/); artifact paths/IDs/idioma resolvidos via AGENTS.md"
user-invocable: true
disable-model-invocation: false
---

# Conformance / DoD Gate

Gate **read-only** que preenche o buraco estrutural dos gates de fluxo SDD (no AgentSpec: Clarity
Score, "testes passam" — fracos; e **sem** gate de consistência cross-artefato). Esses gates
verificam no máximo **consistência interna** e **presença de cobertura** entre `DEFINE`/`DESIGN`,
mas **não** verificam três eixos:

1. **Fidelidade upstream** — o que a fonte-da-verdade (requisitos/visão/ADRs/constituição/PRD)
   exige chegou **íntegro** (não caiu, não enfraqueceu, não vazou escopo) até os artefatos
   downstream.
2. **Satisfação de requisito / DoD** — os gates "sim/não" e critérios mensuráveis foram
   **medidos ao vivo** e deram **sim** (existir uma task ≠ o gate estar satisfeito).
3. **Conformidade com o código** — o que os artefatos **afirmam** existe de fato no repositório
   e/ou **rodando** (o fluxo de spec nunca olha o código).

O gate mede esses três eixos **contra a régua que o projeto declarou** — não procura todo defeito
que o software poderia ter. Uma feature vai para produção na régua do estágio em que o produto
está e é refinada pelo uso; a régua é decidida no planejamento, e o gate a cobra sem subi-la
(seção Régua).

Esta skill é **agnóstica ao projeto**: não hardcoda caminhos, esquemas de ID nem idioma —
resolve tudo lendo o `AGENTS.md` do projeto onde roda. Opera por **classes de falha** e por uma
**matriz de confronto direcional**, não por casos específicos.

## Postura (INVARIANTE)

- **Aplicar a skill LITERALMENTE — ignorar o contexto externo.** Rodar esta skill = executar
  **exatamente** os passos abaixo, sobre os **artefatos e o código**, e nada mais. O agente
  **NÃO** traz comportamento, julgamento, conclusão, severidade nem veredito da conversa que
  precede a invocação — nem que ele mesmo tenha acabado de "achar" algo. O que já foi dito no
  chat (análises anteriores, gates prévios, hipóteses, o que "parece" ok/quebrado) **não é entrada**:
  não confirma, não dispensa e não pré-classifica nada. Cada finding renasce **só** da evidência
  que ESTE run coletar. A **única** entrada externa admitida é o **argumento objetivamente
  injetado** na invocação (`readiness`/`conformance` + escopo explícito, quando houver); ausente o
  argumento, a varredura é neutra e completa. Se um fato do contexto for relevante, ele **tem de
  ser re-derivado do artefato/código aqui** para contar — citação de memória do chat não é prova.
  Issues, PRs e relatórios de gates anteriores **não** são entrada: uma decisão do responsável
  conta quando está registrada nos artefatos.
- **Read-only.** NÃO modifica nenhum arquivo. Nunca aplica correção. Se propõe remediação, é
  como **texto** — e a correção real entra **pelo fluxo** (corrige o artefato-fonte a montante e
  re-roda o comando para cascatear), NUNCA ad hoc.
- **O humano invoca; o agente assiste.** Esta skill é disparada pelo responsável. Quando um agente
  a executa, ele revisa, roda as provas de evidência, e **reporta** — não conserta o que o gate
  achou (um defeito revelado vira relatório, não edição).
- **Cobrar a régua, nunca subi-la.** O gate exige o que a base declarada e os artefatos exigem.
  Defeito possível que nenhuma afirmação em vigor exige não é achado: é observação de maturidade
  (seção Régua).
- **Sem viés de foco.** Rodar o gate = varredura neutra da taxonomia inteira; não prefaciar com um
  "foco" que vicie o resultado. O recorte é fixo: a varredura percorre todo ID rastreável do
  upstream e do DEFINE e todo item do File Manifest; o que vira achado é decidido pelo filtro de
  admissão, não pela escolha do agente.

## Passo 0 — Resolver contexto do projeto (a partir do AGENTS.md)

Ler o `AGENTS.md` (e/ou `CLAUDE.md`) do projeto e extrair, SEM assumir:

- **Fonte-da-verdade upstream**: onde vivem requisitos, visão/arquitetura, ADRs, PRDs, constituição
  (paths + em que branch). Ex. comum: `docs/requisitos.md`, `docs/visao-geral.md` (ADRs),
  `docs/prds/NN-*.md` ou PRDs agrupados por épico (`docs/prds/E<n>-*/<id>-*.md`),
  `docs/constitution/constitution.md`.
- **Artefatos por-feature (AgentSpec)**: em `.claude/sdd/features/` (`DEFINE_{FEATURE}.md`,
  `DESIGN_{FEATURE}.md` — inclui File Manifest, ADRs inline, testing strategy) e
  `.claude/sdd/reports/` (`BUILD_REPORT_{FEATURE}.md`). Resolver a feature ativa pelo bloco
  AGENTSPEC do `CLAUDE.md` / pelo DEFINE mais recente. Usar sempre os caminhos que o `AGENTS.md`
  declarar quando divergirem.
- **Esquema de IDs**: como requisitos/objetivos/métricas/critérios são numerados no PRD vs. no
  DEFINE/DESIGN (ex.: PRD `O0.x`/`RF0.x`/`RNF0.x`/`M0.x` + `ADR-xxx` → DEFINE goals/success/
  acceptance → DESIGN File Manifest). Derivar o cross-map a partir do que se lê, não de um esquema fixo.
- **Convenções de fluxo/branch/PR**: qual branch recebe o merge (ex.: `qa`), como o PR é aberto,
  quais gates de CI existem. Usar isso para saber **quando** o gate `conformance` é obrigatório.
- **Idioma do relatório**: seguir o idioma de comunicação declarado no `AGENTS.md`.
- **Limiar de bloqueio**: que severidades bloqueiam o `/build` (modo `readiness`) e o PR/"done"
  (modo `conformance`), e o que acontece com os achados abaixo dele (ex.: "crítico e alto bloqueiam;
  médio e baixo viram issue"). Critério de DoD **não medido ou falhando bloqueia sempre** no
  `conformance`, qualquer que seja o limiar. Sem limiar declarado, vale o default da seção Veredito.
- **Base declarada**: o que o projeto fixa como padrão desde a primeira entrega — constituição,
  convenções do `AGENTS.md`, ADRs, regras de CI (onde entram segurança e obrigação legal).
- **Decisões registradas**: onde os artefatos guardam decisão do responsável — Open Questions e
  Revision History do DEFINE/DESIGN, limites declarados, Fora de escopo, Changelog do PRD, ADRs.

Se o projeto **não** declarar algo, cair nos defaults do AgentSpec (`.claude/sdd/`) e **registrar a
suposição** no relatório (classe D).

## Modos

Argumento: `readiness` ou `conformance` (default `conformance`).

- **`readiness`** — roda **após `/design`, antes de `/build`**. Confronta **só documentos**
  (upstream → DEFINE → DESIGN). **Absorve a consistência interna** (DEFINE↔DESIGN — o que o
  `/analyze` do Spec Kit fazia) **e** pega drift/enfraquecimento/scope-creep/pontos de
  interpretação/contradição-na-fonte **antes** de codar. **Não** executa código (pode não existir
  ainda) e **não** exige evidência ao vivo.
- **`conformance`** — roda **após `/build`, antes de PR / de declarar "done"**. Faz tudo do
  `readiness` **+ artefato↔código + satisfação de DoD com evidência ao vivo**. Pega
  placeholder-marcado-pronto, entregável esqueleto, serviço/arquivo/rota faltando, e gate
  "sim/não" **não medido**. Como a delegação do `/build` é automática, é **a única trava forte**
  e roda depois do código — obrigatório **sem exceção**.

## Régua — o que o gate cobra

A régua é decidida no planejamento, não no gate:

- **Base fixa**, desde a primeira entrega: a base declarada (Passo 0). Não varia com o estágio do
  produto.
- **Régua que sobe com o uso**: robustez para cenário raro, escala além do uso atual, automação de
  operação rara, observabilidade profunda, cobertura exaustiva de borda. Sobe só com justificativa
  registrada — evidência de uso, obrigação nova ou decisão do responsável.
- O que excede a régua é registrado como **evolução**, com o gatilho que a justificaria.

O gate cobra a régua declarada e **nunca a sobe**:

- **Afirmação em vigor**: enunciado da base declarada ou de um artefato upstream, citável por ID ou
  por local (artefato + seção). Afirmação marcada `[a definir]`, diferida ou fora de escopo não
  exige nada da camada de baixo; resolvê-la ou implementá-la sem decisão registrada é achado
  (classes A e D).
- **Filtro de admissão**: só é achado o que cita uma afirmação em vigor que a camada de baixo
  **derruba, contradiz, enfraquece, deixa ambígua** (duas leituras que mudam o que se constrói),
  **não realiza** ou **não prova**.
- **Observação de maturidade**: o que não tem afirmação em vigor para citar, e o cenário
  **improvável** (seção Severidade) que nenhum artefato declara. Sem severidade, nunca bloqueia e
  não é candidata a issue — o responsável decide se a registra.
- **Decidido**: achado coberto por decisão registrada nos artefatos (mesmo objeto, mesmo estado
  esperado) é listado como decidido, com a referência; não conta como achado novo e não bloqueia.
  Critério de DoD que falha ou não foi medido no `conformance` segue bloqueando (Veredito).

## Taxonomia de falhas (A–E) — o backbone

Rodar as cinco classes. São ortogonais ao que os gates nativos do AgentSpec cobrem. Cada classe
passa pelo filtro de admissão (seção Régua).

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
| requisitos/visão/ADRs/constituição/PRD → **DEFINE** | fidelidade: nada dropado/enfraquecido/vazado | A |
| **DEFINE** → DESIGN (arquitetura/File Manifest/ADRs inline/testing strategy) | design realiza cada requisito/critério; deferrals **explícitos e justificados**, não silenciosos | A, D |
| DEFINE + DESIGN → **File Manifest** | cobertura que **satisfaz** (não só referencia) cada requisito/critério/acceptance | A, B |
| DESIGN + DEFINE → **código + testes + BUILD_REPORT** *(conformance)* | implementado de fato; DoD **medido**; sem placeholder-marcado-pronto | B, C |
| **código** → artefatos *(conformance)* | reverso: o código bate com o que foi afirmado; divergência não-documentada | C, E |

Confrontos **direcionais** (não todos-contra-todos): a fonte-upstream manda; cada camada downstream
tem de **realizar** o que a de cima exige.

## Regra de evidência (modo `conformance`) — o coração do gate

Para **cada** critério/métrica/gate "sim/não" e cada acceptance scenario:

1. Derivar dos artefatos **como se prova** (o comando/observação que torna o critério verdadeiro).
   Nunca hardcodar; ler do DEFINE (acceptance)/DESIGN (testing strategy)/CI o que o próprio projeto
   define como prova. A prova cobre os cenários que o critério declara — o falsificador dele diz
   quais são; cenário que o critério não declara não entra na prova.
2. **Rodar a prova** (ou, se exigir recurso indisponível, emitir o **comando exato** e marcar
   pendente com a razão). Capturar a saída como evidência.
3. Classificar o resultado no **ledger** (abaixo). Só marca **VERIFICADO(sim)** com **evidência
   real** anexada. Ausência de evidência ⇒ **NÃO-MEDIDO** (não é "provavelmente ok").

Formas típicas de prova ao vivo (derivadas, não fixas): subir o ambiente e conferir serviços/health;
aplicar o schema do zero; rodar a suíte de testes/gates de CI; medir uma meta de performance; dirigir
a UI headless (ex.: Playwright) para os acceptance scenarios; comparar contrato gerado vs. servido.

## Severidade

A severidade sai de dois fatos verificáveis, nunca de julgamento livre. Cada achado registra os
dois, com o fato que sustenta cada um.

**Peso** — o nível da afirmação em vigor que o achado cita:

| Peso | Afirmação atingida |
|---|---|
| 1 | princípio da constituição, critério de DoD (métrica do PRD, critério de sucesso, teste de aceite) ou MUST |
| 2 | outro requisito, regra ou restrição do upstream; decisão de ADR; convenção declarada |
| 3 | decisão interna do DESIGN; cobertura não funcional fora do DoD |
| 4 | só a forma: terminologia, enum, ordem, slug, referência morta, redação |

**Manifestação** — o que precisa acontecer para a falha aparecer, decidido por quem controla o
gatilho. O achado lista as condições do gatilho:

| Manifestação | Teste |
|---|---|
| certa | a falha já está no texto ou no código, ou acontece em toda execução do caminho principal |
| provável | um ator a dispara quando quer — fluxo alternativo, entrada inválida, envio duplicado, chamada direta à API, inclusive repetindo até acertar uma janela de tempo —, ou ela depende de uma janela de horas ou dias (pendência, prazo) |
| improvável | depende de eventos independentes coincidirem numa janela de segundos — concorrência no mesmo objeto, mudança de estado entre dois passos, falha de infraestrutura num passo específico |

Cenário declarado num critério ou falsificador está exigido: descumpri-lo é **certo**, porque a
raridade já foi pesada por quem o declarou. Cenário improvável não declarado é observação de
maturidade, não achado.

| Peso \ Manifestação | certa | provável |
|---|---|---|
| 1 | CRITICAL | HIGH |
| 2 | HIGH | MEDIUM |
| 3 | MEDIUM | LOW |
| 4 | LOW | LOW |

- Na dúvida entre dois níveis, de peso ou de manifestação, vale o **menor** que um fato citado
  sustente.
- A constituição entra no peso 1 e segue a manifestação, como qualquer afirmação.

A severidade classifica; **o que bloqueia é o limiar** resolvido no Passo 0 (seção Veredito).

## Saída (read-only)

Emitir, **no idioma do projeto**:

### 1. Tabela de findings
`| ID | Classe (A–E) | Afirmação em vigor (ID ou local) | Peso | Manifestação (condições do gatilho) | Severidade | Onde quebrou (artefato:linha ou código:arquivo) | Lacuna de evidência | Ação de fluxo (qual upstream corrigir + re-rodar qual comando) |`

### 2. Ledger de conformidade por requisito *(o entregável central)*
Uma linha por requisito/critério/métrica rastreável:
`| ID | Enunciado (curto) | Estado | Evidência / comando |`
onde **Estado ∈ `VERIFICADO(sim)` · `FALHOU` · `NÃO-MEDIDO` · `N/A`**. No modo `readiness`, o estado
máximo possível é "coberto por task adequada"/"não coberto" (sem execução); no `conformance`, exige
evidência ao vivo para os "sim/não".

### 3. Métricas
Total de requisitos rastreados · % VERIFICADO(sim) · # NÃO-MEDIDO · # CRITICAL · # por classe ·
# decididos · # observações de maturidade.

### 4. Veredito
Aplicar o **limiar do projeto** (Passo 0):
- `conformance`: **APROVADO para PR/done** só se **0 FALHOU e 0 NÃO-MEDIDO** em critérios de DoD
  (absoluto) **e** nenhum outro achado na faixa que o limiar bloqueia. Caso contrário **BLOQUEADO**,
  listando exatamente o que falta medir/corrigir.
- `readiness`: **PRONTO para /build** se nenhum achado estiver na faixa que o limiar bloqueia; senão
  **NÃO PRONTO**, listando o que reconciliar **antes** de codar (via correção do upstream + re-rodar).
- **Default, se o projeto não declarar limiar:** `conformance` bloqueia com qualquer CRITICAL;
  `readiness` bloqueia com qualquer drift/enfraquecimento/contradição-na-fonte pendente. Registrar a
  suposição (classe D).
- Decididos e observações de maturidade não entram no veredito, salvo o DoD absoluto do
  `conformance`.

### 5. Achados abaixo do limiar
Listar como **candidatos a issue**, **um por unidade que fecha sozinha** (um estado esperado, um
caminho de entrega) — nunca agrupados. Cada um com: título curto, onde está, o estado esperado e o
upstream que o corrige. Não bloqueiam; a abertura das issues é decisão do responsável.

### 6. Decididos
`| ID | Afirmação | Decisão registrada (artefato:seção) |`

### 7. Observações de maturidade
Uma linha cada: o que foi observado; por que não é achado (sem afirmação em vigor, ou improvável
não declarado); o gatilho que justificaria subir a régua; e o caminho mais barato se o responsável
quiser registrar (declarar o limite ou a evolução no artefato de origem).

### 8. Remediação (proposta, não aplicada)
Perguntar ao responsável se quer sugestões concretas de remediação para os top-N — **sem aplicá-las**.
Cada sugestão:
- aponta o **artefato-fonte a corrigir** e **qual comando re-rodar** para cascatear (nunca "editar
  o downstream à mão");
- lista primeiro a opção aceitável **mais barata** — muitas vezes declarar o limite no artefato de
  origem — e diz a classe de custo: **local** (texto de artefato existente, ou código existente sem
  estrutura nova) ou **mecanismo novo** (componente, tabela, coluna ou estado, lock, job,
  dependência, tela);
- não propõe mecanismo para cenário que a régua não exige (YAGNI/KISS).

## Enforcement

Esta skill **não** registra hooks próprios. O "sempre rodar antes do PR" é enforçado pelo
`AGENTS.md`/playbook do projeto (e, se/quando existir, por um hook de harness que intercepte
`gh pr create --base qa`), não por hook de ferramenta SDD.

## Done When

- [ ] Contexto do projeto resolvido a partir do AGENTS.md (paths/IDs/idioma/branch de PR/limiar,
      base declarada e onde ficam as decisões registradas).
- [ ] Taxonomia A–E rodada na matriz de confronto direcional (código incluído no modo conformance).
- [ ] Filtro de admissão aplicado: todo achado cita uma afirmação em vigor; o resto está em
      decididos ou em observações de maturidade.
- [ ] Severidade de cada achado por peso × manifestação, com o fato de cada um citado.
- [ ] Ledger de conformidade emitido; cada DoD "sim/não" com estado + evidência (conformance) ou
      cobertura (readiness).
- [ ] Veredito (APROVADO/BLOQUEADO ou PRONTO/NÃO PRONTO) pelo limiar do projeto, com DoD
      FALHOU/NÃO-MEDIDO explicitados.
- [ ] Achados abaixo do limiar listados como candidatos a issue, um por unidade.
- [ ] Nenhum arquivo modificado; remediação apenas proposta, a opção mais barata primeiro.
