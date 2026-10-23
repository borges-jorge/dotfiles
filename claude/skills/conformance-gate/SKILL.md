---
name: conformance-gate
description: >-
  Gate read-only de conformidade e DoD. Confronta a cadeia completa de artefatos de
  planejamento (fonte-upstream/ADRs/constituição ↔ PRD ↔ DEFINE/DESIGN/BUILD_REPORT ↔ CÓDIGO)
  para pegar drift de rastreabilidade, satisfação de requisito não medida e não-conformidade
  artefato↔código, contra a régua que o projeto declarou — não busca a perfeição do software.
  Bloqueia só o que põe em risco a base protegida ou o DoD da feature; divergência de texto
  entre documentos vira item de sincronização, sem bloquear. Dois modos: readiness (pré-/build) e conformance (pré-PR, exige evidência ao vivo). Agnóstico ao
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

O que o gate protege é o que não pode ser ferido: a **base protegida** (segurança, dado pessoal e
obrigação legal, integridade de dado, estrutura, contrato, ADRs) e o **DoD da feature**. A letra de
um documento não é protegida por si: quando uma camada de baixo decide uma variação do que a de cima
diz e a variação não fere a base, o texto de cima se **sincroniza** na entrega — o gate não trava o
avanço por isso.

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
  conta quando está registrada nos artefatos. Exceções: nos dois modos, a seção de **respostas do
  responsável** dos relatórios do gate (Passo 0), que é decisão registrada; no modo `conformance`,
  os relatórios que o projeto declara (Passo 0): os **de review** entram como **candidatos**, nunca como
  achados prontos — cada um é provado de novo neste run (seção Relatórios de review); os **de
  validação** entram como **evidência** de execução que o gate não consegue repetir (seção
  Relatórios de validação).
- **Não supor.** Todo destino, risco e manifestação se apoia num fato citado (artefato e local, ou
  código e linha). Quando o fato que decide não está nos artefatos nem no código, o item é
  **indeterminado** (seção Régua): o gate diz qual fato falta e faz a pergunta — nunca escolhe um
  nível por padrão, nunca preenche a lacuna com o que "provavelmente" é.
- **Read-only.** NÃO modifica nenhum arquivo. Nunca aplica correção. Se propõe remediação, é
  como **texto** — e a correção real entra **pelo fluxo** (corrige o artefato-fonte a montante e
  re-roda o comando para cascatear), NUNCA ad hoc.
- **O humano invoca; o agente assiste.** Esta skill é disparada pelo responsável. Quando um agente
  a executa, ele revisa, roda as provas de evidência, e **reporta** — não conserta o que o gate
  achou (um defeito revelado vira relatório, não edição).
- **Cobrar a régua, nunca subi-la.** O gate exige o que a base declarada e os artefatos exigem.
  Defeito possível que nenhuma afirmação em vigor exige não é achado: é observação de maturidade
  (seção Régua).
- **Proteger a base, não a letra.** Divergência de texto que não põe a base protegida nem o DoD em
  risco nunca bloqueia nem vira issue: vai para a sincronização ou, sem decisão registrada, para
  confirmação do responsável (seção Régua).
- **Sem viés de foco.** Rodar o gate = varredura neutra da taxonomia inteira; não prefaciar com um
  "foco" que vicie o resultado. O recorte é fixo: a varredura percorre todo ID rastreável do
  upstream e do DEFINE, toda cláusula de critério de DoD (Matriz de provas), todo item da base
  (Mapa da base) e todo item do File Manifest; o destino de cada coisa é decidido pelas regras da
  seção Régua e da seção Severidade, não pela escolha do agente.

## Passo 0 — Resolver contexto do projeto (a partir do AGENTS.md)

Ler o `AGENTS.md` (e/ou `CLAUDE.md`) do projeto e extrair, SEM assumir:

- **Fonte-da-verdade upstream**: onde vivem visão/arquitetura, ADRs, PRDs, constituição
  (paths + em que branch). Ex. comum: `docs/visao-geral.md` (ADRs), `docs/prds/NN-*.md` ou PRDs
  agrupados por épico (`docs/prds/E<n>-*/<id>-*.md`), `docs/constitution/constitution.md`. O
  documento de requisitos que semeou o plano (seed), quando o projeto o declara imutável, **não é
  confrontado**: divergir dele é refinamento, não achado.
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
  convenções do `AGENTS.md`, ADRs, regras de CI (onde entram segurança e obrigação legal). Separar
  a **base protegida** (o que o `AGENTS.md` declara como tal: segurança, dado pessoal e obrigação
  legal, integridade de dado, cláusulas estruturais, contrato, confiabilidade, ADRs) das
  **convenções de forma** (redação de documento, comentário, nomenclatura). Sem separação
  declarada, valem as categorias da seção Severidade, e o relatório diz que a separação não foi
  declarada.
- **Documentos vivos**: os que sobrevivem à feature e que a sincronização da entrega atualiza
  (ex.: PRDs e visão, com os ADRs), em oposição aos da feature, arquivados na entrega (ex.: DEFINE,
  DESIGN, BUILD_REPORT). Divergência num documento da feature já arquivada não gera item.
  Documento **entregue pelo build** (ex.: README, runbook de deploy) não é sincronizado: se diverge
  do código, é achado P3 (seção Severidade), corrigido no próprio ciclo.
- **Relatório do gate**: onde o projeto grava a saída de cada rodada e o template (ex.:
  `.claude/sdd/reports/READINESS_{FEATURE}.md`, `CONFORMANCE_{FEATURE}.md`). Ler a seção de
  **respostas do responsável** dos dois relatórios existentes: cada resposta é decisão registrada,
  e a pergunta respondida não se repete.
- **Decisões registradas**: só decisão **humana explícita** conta — entrada de Changelog do PRD
  (refino), entrada de Revision History do DEFINE/DESIGN feita por `/iterate` (o argumento é do
  responsável), resposta do responsável no relatório do gate, ADR e decisão da visão. O texto que
  o agente de uma fase escreveu no corpo do DEFINE, do DESIGN ou do BUILD_REPORT — escolha,
  "limite declarado", Fora de escopo acrescentado pelo agente, decisão autônoma do build — é
  **decisão de agente**, mesmo que o artefato tenha sido aprovado como um todo. Ler a lista que o
  `AGENTS.md` declara; na falta dela, vale esta.
- **Registro de evoluções**: onde o projeto registra o que fica acima da régua, com a origem e o
  gatilho (ex.: issue com label própria). O gate não lê o registro; só aponta para ele.
- **Relatórios de review**: quais reviews o projeto exige depois do build (ex.: code review e
  security review), onde ficam os relatórios, o template e a branch que recebe o PR. Sem declaração,
  o gate não exige nem lê relatório de review.
- **Relatórios de validação**: execução que o gate não consegue repetir (ex.: exige credencial do
  responsável), onde fica o relatório com a saída e o template. Sem declaração, o gate não lê
  relatório de validação.

Se o projeto **não** declarar algo, o default do AgentSpec (`.claude/sdd/`) vale só quando o arquivo
existe no caminho default; senão, o item é **indeterminado** (o que falta e a pergunta) — nunca uma
suposição.

**Árvore e refs:** antes da varredura, registrar `git status` e as refs usadas. Arquivo modificado
ou não rastreado **entre os confrontados** torna a rodada indeterminada para esse arquivo; fora
deles, registra e segue. Ref remota sem fetch nesta rodada é registrada como tal, sem inferir o
estado do remoto.

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

- **Base fixa**, desde a primeira entrega: a base declarada (Passo 0), incluída a qualidade
  estrutural que ela declara — arquitetura, princípios de design, clean code. Não varia com o
  estágio do produto. Dentro dela, a **base protegida** é o que bloqueia; as **convenções de
  forma** são cobradas sem bloquear (seção Severidade).
- **Régua que sobe com o uso**: robustez para cenário raro, escala além do uso atual, automação de
  operação rara, observabilidade profunda, cobertura exaustiva de borda. Sobe só com justificativa
  registrada — evidência de uso, obrigação nova ou decisão do responsável.
- A régua limita **quais cenários** o código trata, nunca a **qualidade da estrutura**: violação
  estrutural que a base declara é achado, não observação de maturidade.
- O que excede a régua é registrado como **evolução** no registro do projeto (Passo 0), com o
  gatilho que a justificaria.

O gate cobra a régua declarada e **nunca a sobe**:

- **Afirmação em vigor**: enunciado da base declarada ou de um artefato upstream, citável por ID ou
  por local (artefato + seção). Afirmação marcada `[a definir]`, diferida ou fora de escopo não
  exige nada da camada de baixo; resolvê-la ou implementá-la sem decisão registrada (Passo 0) vai
  para confirmação.
- **O que foi especificado** é o DoD em vigor no DEFINE — critérios de sucesso, testes de aceite e
  MUST —, lido junto com as **decisões registradas** posteriores que o alteram (Revision History do
  DEFINE e do DESIGN, Changelog do PRD, respostas do responsável no relatório do gate). Essa é a
  **variante decidida**: é ela que o DESIGN tem de realizar e que o `conformance` mede. O texto
  superado de um critério vai para a sincronização e não falha o DoD.
- **Critério realizado e provado**: um critério de DoD está realizado no `readiness` só quando
  **cada cláusula** dele tem prova **declarada** que a reprova. Cláusulas = cada falha que o
  falsificador do critério nomeia **e** cada regra ou mecanismo que o DESIGN declara para
  realizá-lo (ex.: as regras de uma Decision que o mapa de provas liga ao critério). Prova
  declarada = linha do mapa de provas / testing strategy e item do File Manifest que a executa.
  Prova que o DESIGN não declara — inspeção imaginada pelo gate, item que o mapa não liga ao
  critério — **não conta**; o gate não supre a lacuna. No `conformance`, conta a prova declarada
  executada e a validação declarada (seção Relatórios de validação).
- **Variação**: a camada de baixo diz *a* onde a de cima diz *A* — muda, restringe, troca o lado de
  uma contradição da fonte, acrescenta escopo ou deixa de lado um item. Variação não é defeito por
  si; o que decide o destino é o risco e o registro.

Cada coisa que o gate encontra vai para **um** destino:

| Destino | O que entra | Bloqueia |
|---|---|---|
| **Achado** | Risco à base protegida, ao DoD ou à qualidade do código (seção Severidade): a camada de baixo **derruba, contradiz, enfraquece, deixa ambígua** (duas leituras que mudam o que se constrói), **não realiza** ou **não prova** uma afirmação protegida ou um critério da variante decidida | pelo limiar do projeto |
| **Sincronização** | Variação **com** decisão registrada, sem risco à base protegida; divergência de texto (documento↔documento, documento↔código) sem risco; texto superado pela variante decidida | não |
| **Confirmação** | Variação **sem** decisão registrada e sem risco à base protegida: decisão de agente (Passo 0), scope creep, lado escolhido numa contradição da fonte, item da fonte deixado de lado; e **ADR contradito sem exceção registrada**, quando nenhuma outra categoria P1/P2 está em risco | não |
| **Indeterminado** | Falta, nos artefatos e no código, o fato que decide o destino, o risco ou a manifestação | só se o nível mais alto possível bloquearia (Veredito) |
| **Observação de maturidade** | Sem afirmação em vigor para citar, ou cenário **improvável** (seção Severidade) não declarado no DoD | não |
| **Decidido** | Limite aceito e registrado nos artefatos (mesmo objeto, mesmo estado esperado) | não |

- **Risco vem antes de registro.** Variação que põe a base protegida ou a variante decidida em
  risco é achado, com ou sem decisão registrada — decisão de feature não revoga a base; mudar a
  base é decisão própria, no artefato dela.
- **Sincronização** alcança só os documentos vivos (Passo 0). Cada item diz o documento, a
  afirmação antiga, o estado decidido ou entregue e o registro da decisão; a correção do texto
  acontece na entrega, pelo fluxo do projeto, não antes do avanço.
- **Confirmação** é pergunta ao responsável, não bloqueio: a resposta "sim" vira decisão registrada
  (relatório do gate) e o item segue para a sincronização; "não" faz da variação um desvio da
  variante decidida, que se corrige pelo fluxo antes de avançar. Para ADR, a pergunta é "aceita
  exceção ao ADR-xxx?": "sim" registra a exceção; "não" faz da contradição um achado P2.
  Segurança, dado pessoal, integridade de dado e cláusula estrutural da constituição nunca vão
  para confirmação: são achado direto.
- **Indeterminado** traz o fato que falta, onde ele deveria estar e uma pergunta fechada. A
  resposta, registrada no relatório do gate, decide o item sem nova rodada.
- **Observação de maturidade** nunca bloqueia e não é candidata a issue — o responsável decide se
  a registra no registro de evoluções.
- Critério de DoD que falha ou não foi medido no `conformance` segue bloqueando (Veredito).

## Taxonomia de falhas (A–E) — o backbone

Rodar as cinco classes. São ortogonais ao que os gates nativos do AgentSpec cobrem. Cada coisa
encontrada vai para o seu destino (seção Régua); a classe diz onde ela foi achada, não se bloqueia.
Um item sai **uma vez**: se cabe em mais de uma classe, fica com a classe da primeira linha da
Matriz de confronto em que aparece.

- **A. Drift de rastreabilidade (upstream → downstream).**
  Requisito/objetivo/métrica/critério/constraint/item **in-scope** da fonte que foi **dropado** ou
  **enfraquecido** downstream (ex.: um DoD "sim/não" virou uma task-esqueleto). Item **Fora de
  escopo** que **vazou** pra dentro (scope creep). Decisão de **ADR/visão** não refletida ou
  **contradita**. **Contradição latente na própria fonte** (ex.: a mesma métrica exigida numa
  seção e diferida noutra) — nunca resolver em silêncio para um lado. Destino: é **achado** quando
  o DESIGN não realiza a variante decidida do DEFINE, ou quando a variação fere a base protegida
  (ex.: requisito de dado pessoal enfraquecido); ADR contradito sem exceção registrada vai para
  confirmação (seção Régua); fora disso, variação **com** registro vai para a **sincronização** e
  **sem** registro, para **confirmação**.
- **B. Satisfação / DoD não medida.**
  No `readiness`, cada cláusula de cada critério de DoD tem prova declarada que a reprova (seção
  Régua, "Critério realizado e provado"); cláusula sem ela é achado P1. No `conformance`, cada
  critério "sim/não" ou mensurável da **variante decidida** precisa de **evidência real** de
  que passou. Cada **acceptance scenario** (Given/When/Then) exercitado por teste/verificação. Cada
  **MUST** funcional com teste que **prova** o comportamento (não só código que "deveria").
- **C. Não-conformidade artefato↔código** *(só `conformance`)*.
  Arquivos/caminhos citados nas tasks **existem**; componentes/serviços que os artefatos afirmam
  (stack, workflows, endpoints) **existem** e (quando aplicável) **rodam**; contrato = superfície
  servida; modelo de dados = schema real; rotas batem; variáveis de ambiente batem. **Detecção de
  placeholder** marcado como pronto (`echo`/`pass`/`TODO`/`FIXME`/`NotImplemented`/stub vazio onde
  a task diz "entregue"). **Integridade do `[X]`**: task marcada concluída cujo entregável é
  esqueleto. Destino: é **achado** quando o código não realiza a variante decidida ou fere a base
  protegida; código que diverge do texto do DESIGN sem esse risco vai para a **sincronização**
  quando o BUILD_REPORT ou o DESIGN registram a decisão, e para **confirmação** quando não.
- **D. Risco de interpretação.**
  Todo ponto onde um artefato deixou "a definir"/"diferido"/ambíguo e **alguém resolveu
  unilateralmente** um lado → **confirmação** (torna decisão implícita em pergunta explícita).
  Adjetivo qualitativo dado como "satisfeito" sem medida concreta. Assumption feita e **não
  registrada**. Afirmação de mecanismo — comportamento de código já entregue ou de biblioteca com
  estado — que sustenta uma decisão do DESIGN **sem prova citada** (arquivo e linha, ou a execução
  que a mostrou) nem marca de hipótese; no `readiness` confere-se, sem executar nada, que o trecho
  citado existe e **mostra o que se afirma**. A prova vale pelo conteúdo: citação com linha
  deslocada, cujo trecho vizinho sustenta a afirmação, vai para a **sincronização**; afirmação sem
  prova ou que o trecho não sustenta é **achado**.
- **E. Higiene estendida.**
  Drift de terminologia/número/enum/ordem/slug entre **todos** os artefatos **e** o código.
  Referência morta (doc cita arquivo/flag/rota que não existe mais). Destino: em documento,
  **sincronização**; no código, achado de qualidade (seção Severidade), salvo quando a forma fere
  uma afirmação protegida (ex.: contrato de API com nome divergente do servido).

## Matriz de confronto (direcional; a fonte-upstream é a verdade no topo)

| Confronto | O que procurar | Classes |
|---|---|---|
| requisitos/visão/ADRs/constituição/PRD → **DEFINE** | fidelidade: nada dropado/enfraquecido/vazado | A |
| **DEFINE** → DESIGN (arquitetura/File Manifest/ADRs inline/testing strategy) | design realiza cada requisito/critério; deferrals **explícitos e justificados**, não silenciosos | A, D |
| DEFINE + DESIGN → **File Manifest** | cobertura que **satisfaz** (não só referencia) cada requisito/critério/acceptance | A, B |
| DESIGN + DEFINE → **código + testes + BUILD_REPORT** *(conformance)* | implementado de fato; DoD **medido**; sem placeholder-marcado-pronto | B, C |
| **código** → artefatos *(conformance)* | reverso: o código bate com o que foi afirmado; divergência não-documentada | C, E |

Confrontos **direcionais** (não todos-contra-todos): a fonte-upstream manda; cada camada downstream
tem de **realizar** o que a de cima exige, lido como **variante decidida** (seção Régua). Nos
confrontos acima do DEFINE, a variação sem risco à base protegida não é achado: vai para a
sincronização ou para confirmação.

## Relatórios de review (modo `conformance`)

Os reviews procuram defeito de código e vulnerabilidade no diff, sem ancorar em afirmação dos
artefatos, sem verificar o que acham e sem régua. O gate os recebe como fonte de candidatos e aplica
a eles o mesmo critério dos próprios achados.

1. **Presença e âncora.** Para cada review que o projeto exige, o relatório existe, segue o template
   e declara o commit revisado e a base do diff (referência e ponto de divergência). O relatório
   está ancorado quando **o diff que ele revisou é o diff de hoje contra a mesma base**: a base
   declarada é a branch do PR ou a branch padrão (o diff contra esta contém o diff contra aquela), e
   o patch entre o ponto de divergência declarado e o commit revisado tem o mesmo
   `git patch-id --stable` que o patch entre `git merge-base HEAD <base declarada>` e `HEAD`,
   excluídos os relatórios de review, de validação e do gate. Cada relatório é conferido contra a própria base; qualquer
   mudança no diff contra ela quebra a âncora. Relatório ausente, sem os campos ou desancorado é achado de classe C contra a convenção
   do projeto, e o relatório não é usado.
2. **Prova.** Cada achado do relatório é re-derivado neste run: ler o código citado e, quando o
   comportamento depende de execução ou de biblioteca, reproduzir o gatilho (teste, chamada,
   leitura da fonte da biblioteca). O texto do review não é evidência. Achado que não se reproduz é
   **refutado**, com a prova.
3. **Destino.** O achado provado vai para um destino (seção Régua) como qualquer coisa que o gate
   encontra: com risco à base protegida, ao DoD ou à qualidade do código, é achado, com classe,
   risco e manifestação; coberto por decisão registrada, vai para decididos; divergência de texto
   sem risco, para a sincronização; sem afirmação em vigor, ou cenário improvável não declarado,
   vira observação de maturidade. Defeito de código provado não precisa de afirmação de feature:
   a base (correção, segurança, estrutura) é a afirmação em vigor.
4. **Disposição.** Todo achado de todo relatório sai na tabela de disposição (Saída) — nenhum some.

## Relatórios de validação (modo `conformance`)

Quando a prova de um critério exige recurso que o gate não tem, o projeto pode declarar um
relatório com a saída da execução feita pelo responsável.

1. **Presença e âncora.** O relatório segue o template e declara o comando, o commit validado e a
   base do diff. Está ancorado pela mesma regra dos relatórios de review: o código que ele validou é
   o código de hoje contra a mesma base (mesmo `git patch-id --stable`, excluídos os relatórios de
   review, de validação e do gate).
   Desancorado, não vale como evidência.
2. **Leitura.** A saída é a evidência: o critério fica `VERIFICADO(sim)` só se ela mostra o que o
   falsificador do critério exige; o que ela não mostra fica `NÃO-MEDIDO`. Saída que mostra falha
   deixa o critério `FALHOU`.
3. **Sem relatório ancorado**, vale a Regra de evidência: emitir o comando exato e marcar pendente.

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
dois, com o fato que sustenta cada um. Só **achado** tem severidade; sincronização, confirmação,
observação de maturidade e decidido não têm (seção Régua).

**Risco** — o que o achado põe em risco:

| Risco | O que está em risco |
|---|---|
| P1 — proteção | segurança (validação de entrada, menor privilégio, segredo ou dado pessoal em log, superfície de ataque); dado pessoal e obrigação legal; integridade e perda de dado; critério de DoD da variante decidida — no `readiness`, cláusula sem prova declarada que a reprove; no `conformance`, critério falhando ou não medido |
| P2 — estrutura e contrato | cláusula estrutural declarada (ex.: dependência entre camadas, ports & adapters); compatibilidade de contrato; confiabilidade declarada (ex.: prazo em chamada que sai do processo, retry só em operação idempotente); ADR contradito com exceção recusada pelo responsável; afirmação de mecanismo que sustenta decisão do DESIGN sem prova que a sustente |
| P3 — qualidade | defeito de código sem cláusula específica que o reja (correção fora do DoD, clean code, duplicação); cobertura de teste do que **não** é cláusula de critério de DoD; convenção de forma no código; documento entregue pelo build que diverge do código |

**Ordem de decisão do risco** — percorrer na ordem e parar na primeira resposta "sim":
1. Põe em risco segurança, dado pessoal, obrigação legal ou integridade de dado? → P1.
2. É cláusula de critério de DoD sem prova declarada que a reprove (readiness), ou critério falhando
   ou não medido (conformance)? → P1.
3. Fere cláusula estrutural, de contrato ou de confiabilidade declarada, ou ADR com exceção
   recusada, ou é afirmação de mecanismo sem prova que a sustente? → P2.
4. Senão → P3.

O risco é o do que pode quebrar, nunca o nível do documento que cita a afirmação: um MUST do PRD não
é P1 por ser MUST — é P1 quando o que ele protege é P1. Convenção de forma em documento não tem
risco: é sincronização. Achar um risco maior que rege o defeito encerra a escolha: não há dúvida a
resolver pelo menor.

**Manifestação** — o que precisa acontecer para a falha aparecer **no comportamento do sistema
construído**, decidido por quem controla o gatilho; nunca a presença do defeito no documento. Lacuna
de prova de critério de DoD é **certa**, porque o `conformance` a marcará NÃO-MEDIDO. O achado lista
as condições do gatilho:

| Manifestação | Teste |
|---|---|
| certa | a falha já está no texto ou no código, ou acontece em toda execução do caminho principal |
| provável | um ator a dispara quando quer — fluxo alternativo, entrada inválida, envio duplicado, chamada direta à API, inclusive repetindo até acertar uma janela de tempo —, ou ela depende de uma janela de horas ou dias (pendência, prazo) |
| improvável | depende de eventos independentes coincidirem numa janela de segundos — concorrência no mesmo objeto, mudança de estado entre dois passos, falha de infraestrutura num passo específico — ou de um estado que os dados e as restrições atuais da fonte não admitem |

Cenário declarado num critério de DoD da variante decidida, ou no falsificador dele, está exigido:
descumpri-lo é **certo**, porque a raridade já foi pesada por quem o declarou. Cenário declarado só
num documento acima do DEFINE não é exigido por si — é variação (seção Régua). Cenário improvável
não declarado no DoD é observação de maturidade, não achado.

| Risco \ Manifestação | certa | provável |
|---|---|---|
| P1 | CRITICAL | HIGH |
| P2 | HIGH | MEDIUM |
| P3 | MEDIUM | LOW |

- O nível sai da ordem de decisão e da tabela de manifestação, com o fato citado de cada resposta.
  Quando falta o fato que decide uma das perguntas, o item é **indeterminado** (seção Régua): o
  gate registra os níveis possíveis, o fato que falta e a pergunta — nunca escolhe o menor nem o
  maior por padrão.
- A constituição entra pelo risco da cláusula que rege o caso: princípio de segurança ou de dado
  pessoal é P1; cláusula estrutural, de contrato ou de confiabilidade é P2. Princípio de adequação
  ("entregar o que foi especificado") se lê contra a variante decidida — não faz de divergência de
  texto um achado.
- **Princípio genérico de qualidade** (clean code, DRY, SOLID, padrões de projeto) legitima a
  existência do pilar, não cada ocorrência. Um defeito de código só recebe P1 ou P2 quando uma
  cláusula da base rege aquele caso (ex.: a regra de dependência entre camadas); sem cláusula, é P3.

A severidade classifica; **o que bloqueia é o limiar** resolvido no Passo 0 (seção Veredito).

## Saída (read-only)

Emitir, **no idioma do projeto**, no template do relatório do gate quando o projeto declara um
(Passo 0):

### 1. Tabela de achados
`| ID | Classe (A–E) | Afirmação em vigor (ID ou local) | Risco (P1–P3, com o fato) | Manifestação (condições do gatilho) | Severidade | Onde quebrou (artefato:linha ou código:arquivo) | Lacuna de evidência | Ação de fluxo (qual upstream corrigir + re-rodar qual comando) |`

### 2. Matriz de provas do DoD
Uma linha por **cláusula** de cada critério de DoD da variante decidida (seção Régua):
`| Critério | Cláusula (falha do falsificador ou regra do DESIGN) | Origem da cláusula (artefato:linha) | Prova declarada (linha do mapa + item do manifesto) | Reprova? (sim · não · indeterminado) | Por quê (fato citado) |`
"não" gera achado P1 automaticamente; "indeterminado" vai para a seção Indeterminados. Nenhuma
célula de prova pode citar prova que o DESIGN não declara.

### 3. Mapa da base
Uma linha por princípio da constituição, por ADR e por concern cross-feature declarados:
`| Item da base | Aplica-se à feature? (sim · não, com o fato) | Onde foi conferido (artefato:linha) | Resultado (ok · achado <ID> · confirmação <ID> · indeterminado <ID>) |`

### 4. Ledger de conformidade por requisito *(o entregável central)*
Uma linha por requisito/critério/métrica rastreável, na **variante decidida**:
`| ID | Enunciado (curto) | Estado | Evidência / comando |`
onde **Estado ∈ `VERIFICADO(sim)` · `FALHOU` · `NÃO-MEDIDO` · `N/A`**. No modo `readiness`, o estado
é "coberto" só quando toda cláusula do critério tem "sim" na Matriz de provas; senão, "não coberto",
com as cláusulas que faltam; no `conformance`, exige evidência ao vivo para os "sim/não".

### 5. Métricas
Total de requisitos rastreados · % VERIFICADO(sim) · # NÃO-MEDIDO · # CRITICAL · # por classe ·
# confirmações pendentes · # indeterminados · # itens de sincronização · # decididos · # observações de maturidade ·
achados de review por disposição.

### 6. Veredito
Aplicar o **limiar do projeto** (Passo 0):
- `conformance`: **APROVADO para PR/done** só se **0 FALHOU e 0 NÃO-MEDIDO** em critérios de DoD
  (absoluto) **e** nenhum outro achado na faixa que o limiar bloqueia. Caso contrário **BLOQUEADO**,
  listando exatamente o que falta medir/corrigir.
- `readiness`: **PRONTO para /build** se nenhum achado estiver na faixa que o limiar bloqueia; senão
  **NÃO PRONTO**, listando o que reconciliar **antes** de codar (via correção do upstream + re-rodar).
- **AGUARDA RESPOSTA** no lugar de PRONTO ou APROVADO quando nenhum achado bloqueia, mas há
  indeterminado cujo nível mais alto possível bloquearia. Listar as perguntas; com as respostas
  registradas no relatório, o veredito se resolve sem nova rodada.
- **Se o projeto não declarar limiar:** o limiar é indeterminado; perguntar ao responsável, sem
  adotar um default.
- Confirmações pendentes, sincronização, decididos e observações de maturidade não entram no
  veredito, salvo o DoD absoluto do `conformance`.

### 7. Confirmações pendentes
`| ID | Variação (o que a camada de baixo decidiu) | Afirmação de cima (local) | Onde | Pergunta |`
Uma linha por variação sem registro, com uma pergunta fechada ao responsável: "sim" mantém a
variação, "não" volta à afirmação de cima. Não bloqueiam; a resposta é registrada no relatório do
gate e vale como decisão registrada nas rodadas seguintes.

### 8. Indeterminados
`| ID | Item | Níveis possíveis | Fato que falta | Onde deveria estar | Pergunta |`
Uma linha por item cujo destino, risco ou manifestação depende de fato ausente dos artefatos e do
código. Pergunta fechada; a resposta é registrada no relatório do gate.

### 9. Sincronização de documentos
`| ID | Documento vivo (local) | Afirmação antiga | Estado decidido ou entregue | Registro da decisão |`
Uma linha por divergência de texto sem risco, só em documento vivo. É a entrada da sincronização que
o projeto faz na entrega; não bloqueia e não é candidata a issue.

### 10. Achados abaixo do limiar
Listar como **candidatos a issue**, **um por unidade que fecha sozinha** (um estado esperado, um
caminho de entrega) — nunca agrupados. Cada um com: título curto, onde está, o estado esperado e o
upstream que o corrige. Só achado entra aqui — nunca item de sincronização ou confirmação. Não
bloqueiam; a abertura das issues é decisão do responsável.

### 11. Disposição dos achados de review *(conformance, quando o projeto declara reviews)*
`| Review | # | Achado (curto) | Prova | Disposição |`
onde **Disposição ∈ `refutado` · `observação` · `decidido` · `sincronização` · `finding <ID>`**, uma
linha por achado de cada relatório, na ordem do relatório. Relatório recusado no passo de presença e
âncora sai com a razão, sem linhas de achado.

### 12. Decididos
`| ID | Afirmação | Decisão registrada (artefato:seção) |`

### 13. Observações de maturidade
Uma linha cada: o que foi observado; por que não é achado (sem afirmação em vigor, ou improvável
não declarado); o gatilho que justificaria subir a régua; e o caminho mais barato se o responsável
quiser registrar (a evolução no registro do projeto, com o gatilho; o limite declarado no artefato
de origem).

### 14. Remediação (proposta, não aplicada)
Perguntar ao responsável se quer sugestões concretas de remediação para os top-N — **sem aplicá-las**.
Cada sugestão:
- aponta o **artefato-fonte a corrigir** e **qual comando re-rodar** para cascatear (nunca "editar
  o downstream à mão");
- lista primeiro a opção aceitável **mais barata** — muitas vezes declarar o limite no artefato de
  origem — e diz a classe de custo: **local** (texto de artefato existente, ou código existente sem
  estrutura nova) ou **mecanismo novo** (componente, tabela, coluna ou estado, lock, job,
  dependência, tela);
- não propõe mecanismo para cenário que a régua não exige (YAGNI/KISS), nem abre mão da base
  estrutural para baratear a correção.

## Enforcement

Esta skill **não** registra hooks próprios. O "sempre rodar antes do PR" é enforçado pelo
`AGENTS.md`/playbook do projeto (e, se/quando existir, por um hook de harness que intercepte
`gh pr create --base qa`), não por hook de ferramenta SDD.

## Done When

- [ ] Contexto do projeto resolvido a partir do AGENTS.md (paths/IDs/idioma/branch de PR/limiar,
      base protegida e convenções de forma, documentos vivos, relatório do gate e onde ficam as
      decisões registradas).
- [ ] Taxonomia A–E rodada na matriz de confronto direcional (código incluído no modo conformance),
      contra a variante decidida.
- [ ] Respostas do responsável lidas nos relatórios do gate; nenhuma pergunta respondida repetida.
- [ ] Matriz de provas do DoD com uma linha por cláusula, só com prova declarada; Mapa da base com
      todo princípio, ADR e concern declarados.
- [ ] Cada coisa encontrada num destino só e uma vez: achado (com afirmação em vigor e risco),
      sincronização, confirmação, indeterminado, observação de maturidade ou decidido.
- [ ] Severidade de cada achado pela ordem de decisão do risco × manifestação no comportamento,
      com o fato de cada resposta citado; nenhum nível escolhido por padrão.
- [ ] Relatórios de review declarados conferidos (presença, âncora pelo diff) e cada achado deles
      provado e com disposição (conformance).
- [ ] Relatórios de validação declarados conferidos (presença, âncora) e lidos contra o
      falsificador de cada critério que provam (conformance).
- [ ] Ledger de conformidade emitido; cada DoD "sim/não" com estado + evidência (conformance) ou
      cobertura (readiness).
- [ ] Veredito (APROVADO/BLOQUEADO, PRONTO/NÃO PRONTO ou AGUARDA RESPOSTA) pelo limiar do projeto, com DoD
      FALHOU/NÃO-MEDIDO explicitados.
- [ ] Confirmações pendentes com pergunta fechada; sincronização só com documento vivo.
- [ ] Achados abaixo do limiar listados como candidatos a issue, um por unidade.
- [ ] Nenhum arquivo modificado; remediação apenas proposta, a opção mais barata primeiro.
