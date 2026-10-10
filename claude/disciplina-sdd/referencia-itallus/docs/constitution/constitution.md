<!--
SYNC IMPACT REPORT — constituição v2.2.0 (emenda 2026-10-10)
- Mudança de versão: 2.1.0 → 2.2.0 (MINOR — expansão material de guidance no princípio VI)
- Motivação: a qualidade estrutural passa a ser base desde a primeira entrega, separada da
  régua de exigência por estágio do produto, que limita quais cenários o código trata e nunca
  a estrutura.
- Princípio MODIFICADO: VI. Manutenibilidade — acrescenta (a) estrutura em Clean Architecture,
  SOLID, clean code e padrões de projeto consagrados desde a primeira entrega; (b) dependência
  entre camadas só para dentro: o domínio não importa aplicação, adapter, framework nem
  biblioteca de I/O, e a aplicação depende de portas, nunca de adapters.
- Endurecimento indicativo → imperativo (registrado): o seed descreve a arquitetura "dentro das
  boas práticas" (Clean Code, SOLID, design patterns) e a visão fixa Clean Architecture e
  ports & adapters (ADR-004; plugabilidade com portas no domínio). A conversão para DEVE é
  decisão do responsável em 2026-10-10 (issue #239).
- Lastro: `docs/requisitos.md` §3 (Arquitetura); `docs/visao-geral.md` — organização do código
  (ADR-004) e plugabilidade (ports & adapters); decisão do responsável de 2026-10-10.
- Verificação na emenda: o domínio de `apps/api` importa só a biblioteca padrão e o próprio
  domínio; aplicação e portas não importam adapter nem framework — a cláusula (b) nasce
  satisfeita.
- Enforcement: `conformance-gate` contra esta constituição. Ainda não há verificação
  automática na CI de complexidade, aninhamento ou fronteira entre camadas.
- Seções inalteradas: demais princípios, restrições, fluxo de desenvolvimento e governança.
- Datas: ratificação original preservada (2026-06-24); emendas: 2026-07-13 (v2.0.0),
  2026-09-21 (v2.1.0), 2026-10-10 (v2.2.0).

--- histórico (emenda v2.1.0, 2026-09-21) ---
- Mudança de versão: 2.0.0 → 2.1.0 (MINOR — troca de mecanismo de enforcement e do fluxo de
  desenvolvimento por migração de ferramenta SDD; correção da faixa vinculante de ADRs)
- Motivação: o projeto migrou a disciplina SDD do GitHub Spec Kit para o AgentSpec. A
  constituição é o único ativo genuinamente nativo do Spec Kit que se mantém; suas cláusulas de
  enforcement (que citavam `/speckit.analyze` e o ciclo `/specify→/plan→/tasks→/implement`) são
  re-apontadas para o ciclo do AgentSpec e para o gate próprio do projeto (`conformance-gate`).
- Local do arquivo: movido de `.specify/memory/constitution.md` para `docs/constitution/constitution.md`
  (a árvore `.specify/` foi retirada na migração).
- Princípios: INALTERADOS (I..IX preservados verbatim da v2.0.0).
- Seções MODIFICADAS:
  • Restrições e Âncora Cross-Feature — enforcement agora via `conformance-gate readiness`
    (confronta DEFINE/DESIGN contra esta constituição + upstream), não `/speckit.analyze`;
    faixa vinculante corrigida ADR-001..012 → **ADR-001..011** (o ADR-012 foi criado e
    **revertido** em 2026-07-13 — a constitution IV v2.0.0 tornou "prazo em toda chamada que sai
    do processo" invariante de todas as features, dispensando o ADR de alocação)
  • Fluxo de Desenvolvimento — ciclo por feature agora **AgentSpec** (Brainstorm→Define→Design→
    Build→Ship); o gate de conformidade/DoD é o `conformance-gate`
  • Governança — Conformidade re-apontada de `/speckit.analyze` para `conformance-gate readiness`
- Datas: ratificação original preservada (2026-06-24); emendas: 2026-07-13 (v2.0.0), 2026-09-21 (v2.1.0).

--- histórico (emenda v2.0.0, 2026-07-13) ---
- MAJOR 1.0.0 → 2.0.0: redefinições/remoções de princípio, alinhando ao lastro humano registrado.
  II remove "cada componente DEVE ter alvo"; IV vira invariante comportamental (prazo em toda
  chamada que sai do processo; retry só idempotente); V remove cripto cega; VII paridade de
  configuração; IX remove cláusulas inaplicáveis. I, III, VI, VIII inalterados. Faixa vinculante
  ampliada (à época) e regra de Rastreabilidade de requisito adicionada à Governança.
-->

# Constituição do Itallus

## Princípios Fundamentais

### I. Adequação e Experiência *(ISO/IEC 25010)*
O sistema DEVE entregar o que foi especificado — completo, correto e cobrindo edge
cases (nulos, limites, entradas inesperadas) — de forma **usável**: erros acionáveis,
API/UX consistente e previsível, e documentação suficiente para operar sem suporte.
**Racional:** fazer a coisa certa e fazê-la de forma compreensível são faces da mesma
entrega; software correto porém inusável (ou o inverso) falha com o usuário.

### II. Eficiência de Performance *(ISO/IEC 25010)*
O sistema NÃO DEVE introduzir custo oculto (N+1, full scan, O(n²)); operações pesadas
são assíncronas quando faz sentido e o caminho escala com o volume previsto. Onde o uso
justifica, o **caminho crítico** DEVE ter um alvo de latência/throughput **explícito e
controlável**, derivado de uma **decisão registrada** — não de um número inventado para
satisfazer o gate.
**Racional:** performance precisa ser projetada contra um alvo real; um alvo fabricado só
para passar no gate não mede nada.

### III. Compatibilidade *(ISO/IEC 25010)*
Contratos de API DEVEM ser bem definidos, versionados e estáveis; mudanças NÃO DEVEM
quebrar consumidores existentes sem um processo explícito de breaking change.
**Racional:** integrações silenciosamente quebradas propagam falhas entre features e
serviços.

### IV. Confiabilidade *(ISO/IEC 25010)*
Toda chamada que **sai do processo** (banco, gateway, integração) DEVE ter **prazo**
(timeout/deadline); **retry** aplica-se **apenas a operação idempotente**, com backoff e
teto; o sistema DEVE degradar graciosamente quando uma dependência falha, ser idempotente
onde precisa e recuperar-se **sem intervenção manual**. Circuit breaker é mecanismo
distinto e fica para quando a maturidade exigir — **não** coberto por este princípio agora.
**Racional:** falhas são inevitáveis; o que diferencia é a recuperação sem perda de dados
nem operador. "Chamada externa" é ambíguo — o que importa é **sair do processo** e poder
pendurar.

### V. Segurança *(ISO/IEC 25010)*
Entrada DEVE ser validada em todas as fronteiras; aplica-se o princípio do **menor
privilégio**; NUNCA segredos nem PII em log. Proteção criptográfica (em trânsito/em
repouso) entra quando um **requisito concreto a exigir** — não como mandato cego; no
alvo on-prem acessível só por VPN, sem ingress, o transporte é tratado na camada de rede.
**Racional:** superfície de ataque é introduzida a cada decisão; segurança não é retrofit
— mas um MUST que ninguém implementa não protege nada, só mascara o gate.

### VI. Manutenibilidade *(ISO/IEC 25010)*
Código DEVE ser modular e testável (dependências injetadas, lógica de negócio isolada de
I/O e frameworks), com observabilidade suficiente para diagnosticar um problema em
produção só pelos logs. A estrutura DEVE seguir Clean Architecture, SOLID, clean code e
padrões de projeto consagrados desde a primeira entrega, e a dependência entre camadas
aponta só para dentro: o domínio não importa aplicação, adapter, framework nem biblioteca
de I/O, e a aplicação depende de portas, nunca de adapters.
**Racional:** a maior parte do custo de software é mudança posterior; código opaco trava
a evolução. A qualidade da estrutura é o que torna barato tratar depois o cenário que a
entrega atual deixou de fora.

### VII. Portabilidade *(ISO/IEC 25010)*
Configuração DEVE ser 100% externalizada (sem hardcode por ambiente; **nenhum valor de
ambiente embutido na imagem**). A imagem validada é **promovida sem rebuild**; dev e
produção diferem **só no empacotamento** (dev constrói e monta a fonte; produção roda a
imagem versionada), **não** na configuração.
**Racional:** "funciona na minha máquina" é sintoma de acoplamento ao ambiente.

### VIII. Conformidade (LGPD) *(extensão pragmática)*
Aplicável — o sistema trata dados pessoais (colaboradores). Dados pessoais DEVEM ter base
legal definida; os direitos do titular (acesso, correção, exclusão) são atendíveis; a
retenção é mínima; operações sensíveis são auditadas.
**Racional:** conformidade ignorada vira passivo legal e risco de incidente com prazo de
notificação.

### IX. Custo *(extensão pragmática)*
Decisões arquiteturais DEVEM considerar o custo operacional: **recursos não
superdimensionados**, **um único stack** (sem ambiente always-on redundante), **storage
limpo**; evita-se **over-engineering** — abstração só onde há troca plausível.
**Racional:** custo que não é decisão explícita vira surpresa na fatura e limita a
viabilidade.

## Restrições e Âncora Cross-Feature

Os princípios acima materializam-se em **concerns cross-feature de cumprimento
obrigatório** — acesso por departamento, LGPD, correção monetária (`Decimal`/`NUMERIC`,
**nunca** `float`), plugabilidade (ports & adapters), observabilidade (structlog),
configuração externalizada, compatibilidade de contrato e histórico/auditoria. A
especificação **canônica** desses concerns e das decisões que os fixam está em
`docs/visao-geral.md` (§8 concerns + §9 ADR-001..011); esta constituição os torna
**vinculantes** e **não os duplica**. Toda feature DEVE declarar como satisfaz os
concerns aplicáveis; o **`conformance-gate readiness`** confronta os artefatos da feature
(DEFINE/DESIGN) contra esta constituição e contra o upstream (visão/PRD/ADRs).

## Fluxo de Desenvolvimento

- **Uma feature = um PRD = ponta a ponta** (backend + frontend), implementada pelo ciclo
  **AgentSpec** — Brainstorm → Define → Design → Build → Ship —, **uma de cada vez** (ver
  `docs/roteiro-sdd.md`).
- **Branches protegidas** `master` e `qa`; trabalho em `<tipo>/<nome>`; fluxo
  `<tipo>/* → qa → master` **sempre via Pull Request** (ver `AGENTS.md`).
- **Gates de CI em PR:** lint + testes (api) + build (web) + **gate de drift** do contrato
  OpenAPI→orval + **RLS via testcontainers** (ADR-007/010).
- **Gate de conformidade/DoD:** o **`conformance-gate`** (modos `readiness` antes do Build e
  `conformance` antes do PR para `qa`) — verifica fidelidade ao upstream e satisfação de DoD
  medida ao vivo; é **obrigatório** antes de declarar a feature "done".
- **Idioma:** comunicação e documentação em **pt-BR** (fonte da verdade); identificadores
  de código em **en-US** (ver `AGENTS.md`).

## Governança

Esta constituição **prevalece** sobre outras práticas de desenvolvimento.

- **Emendas:** propostas via PR no fluxo `<tipo>/* → qa → master`, com justificativa e
  atualização do *Sync Impact Report*; entram em vigor no merge à `master`.
- **Versionamento (semver):** **MAJOR** = remoção/redefinição incompatível de princípio
  ou governança; **MINOR** = novo princípio/seção ou expansão material de guidance;
  **PATCH** = clarificação, redação, correção não-semântica.
- **Conformidade:** todo PR e revisão DEVE verificar aderência aos princípios; o
  **`conformance-gate readiness`** confronta os artefatos da feature (DEFINE/DESIGN) contra
  esta constituição e o upstream; complexidade que viole um princípio DEVE ser justificada
  no registro de decisões (ADR inline do DESIGN).
- **Rastreabilidade de requisito:** todo requisito normativo (MUST/DEVE) DEVE rastrear a
  uma **decisão humana registrada** — o seed de requisitos (`docs/requisitos.md`) **ou**
  uma decisão logada (Revision History/Open Questions do DEFINE, Changelog de PRD, ADR de
  refino). Requisito sem esse lastro **não** é MUST. Um princípio genérico ("qualidade tipo
  ISO") legitima a **existência** dos pilares, **não** uma cláusula específica derivada deles.
- **Guia operacional de runtime:** `AGENTS.md` (canônico; `CLAUDE.md` o espelha).

**Versão**: 2.2.0 | **Ratificada**: 2026-06-24 | **Última emenda**: 2026-10-10
