---
name: refine-prd-with-the-planner
description: |
  Refina o PRD de uma feature já decomposta (e a visão geral, onde a mudança alcança) invocando o
  agente the-planner: aplica as decisões do brainstorm da feature, ou uma decisão que surgiu
  durante o ciclo do AgentSpec, propaga a mudança aos artefatos afetados sem drift de formato e
  versiona via Changelog. Parte da afirmação que deixou de ser verdadeira para achar o raio de
  alcance e o ponto de entrada. Use antes do /define para levar o brainstorm ao PRD (iterando até
  o PRD ficar adequado), ou a qualquer momento do ciclo quando uma decisão muda requisito,
  regra de negócio ou restrição de uma feature. Não use para criar o plano nem para dividir um
  PRD em dois ou mais — isso é decompose-requirements-with-the-planner.
---

# Refinar o PRD de uma feature com o the-planner

> **Princípio:** um único escritor (`the-planner`) evita drift de formato; a cascata segue a
> rastreabilidade já presente nos artefatos; o Changelog é a trilha de versão.
>
> **Agnóstica:** caminhos dos artefatos, template de PRD, idioma e formato do Changelog vêm do
> **`AGENTS.md`** do projeto — esta skill não fixa nada específico de um projeto.

## Postura (invariante)

- **Executar a skill como está escrita.** Rodar esta skill = executar **todas** as etapas do
  procedimento, na ordem, sem pular nenhuma, sem juntar etapas e sem criar etapas novas.
- **Só os argumentos entram.** A entrada é o que foi passado na invocação — texto ou arquivos — e
  o que a própria skill manda ler (o `AGENTS.md` e os artefatos que ela nomeia). Nada da conversa
  anterior entra: nem análises, nem conclusões, nem decisões que não estejam nos argumentos. Um
  fato relevante que não está nos argumentos vira pergunta ao responsável, não contexto injetado.
- **Repassar ao agente só o que a skill manda.** O prompt do the-planner é o prompt-base desta
  skill preenchido com os argumentos, sem acréscimos de escopo, foco ou comportamento.

## Entradas

| Situação | Entrada |
|---|---|
| **Antes do ciclo da feature** | O brainstorm da feature + o PRD da feature |
| **Durante o ciclo** (define, design, build) | O PRD da feature + a decisão, com ou sem brainstorm |

Antes do ciclo, brainstorm e refino podem se alternar até o PRD ficar adequado, a critério do
responsável. O brainstorm **decide**; esta skill **aplica** — o brainstorm não escreve o PRD.

## Papéis

- **the-planner** — faz todo o trabalho: análise de impacto e edição.
- **Quem invoca a skill** — orquestra: repassa a entrada sem alteração, repassa as perguntas do
  agente ao responsável sem alteração (uma por vez), revisa o diff e reporta. Não analisa, não
  decide e não edita os artefatos; divergência encontrada na revisão volta ao agente.

## Pré-condições

- O PRD da feature existe (criado pela decomposição).
- A decisão está escrita — no brainstorm ou como texto curto e inequívoco.
- Branch de trabalho, nunca branch protegida (ver `AGENTS.md`).

## Procedimento

1. **Invoque o subagente `the-planner`** (agentspec) em **modo update**, só com orquestração —
   sem injetar escopo do projeto (ele lê os arquivos). Prompt-base:

   > Tarefa de **refino** do PRD de uma feature (modo update).
   > **Use só as entradas desta tarefa e os arquivos que ela nomeia; nenhum outro contexto.**
   > Entrada: o PRD «caminho», a visão geral (caminho no `AGENTS.md`) e «o brainstorm "caminho" |
   > a decisão: "…"».
   >
   > **Análise, antes de editar.** Para cada decisão:
   > a. **Frase morta:** escreva a afirmação que **deixa de ser verdadeira** com a decisão (não o
   >    requisito novo). Um refino raramente só adiciona um ID; ele invalida uma afirmação
   >    reescrita em prosa em várias camadas, e o grafo de IDs não enxerga isso.
   > b. **Raio de alcance:** procure essa frase, com sinônimos, em todas as camadas, de cima para
   >    baixo (visão → PRDs → artefatos da feature → runbooks → código).
   > c. **Ponto de entrada:** a camada mais alta que a frase alcança. Se ela não alcança visão nem
   >    PRD, este refino não é a entrada — não edite e diga qual comando é.
   > d. **Estrutura:** se a decisão faz a feature conter duas ou mais entregas que podem ir para
   >    produção separadas, não divida o PRD — pare e indique a
   >    `decompose-requirements-with-the-planner` (desmembramento).
   >
   > **Edição.** Para cada decisão:
   > e. Aplique-a ao PRD e às **seções afetadas da visão**, editando no lugar, sem renumerar
   >    seções.
   > f. **Propague** aos acertos do raio de alcance que estão na visão ou em outros PRDs. Acertos
   >    abaixo do PRD ficam como pendência, com o comando de entrada de cada uma.
   > g. **Mantenha** o template de PRD e o formato da visão do `AGENTS.md`.
   > h. **Altitude:** PRD e visão recebem só **problema, resultado, regra de negócio e
   >    restrição**. Mecanismo (rotas, schema, policies, formato de token, nomes de tabela) fica
   >    no design da feature. Um `[a definir]` resolvido no design fecha com **remissão** ao
   >    design, sem copiar o mecanismo.
   > i. Em cada PRD alterado, acrescente uma linha no **`## Changelog`**, incrementando a versão.
   > j. Não invente além das decisões: o que continuar aberto permanece marcado.
   >
   > Retorne: frase morta e raio por decisão, o que mudou em cada arquivo, as pendências e as
   > perguntas ao responsável.

2. **Perguntas.** Repasse cada pergunta ao responsável, sem alteração e uma por vez. Com as
   respostas, **retome o mesmo agente** para aplicá-las.

3. **Revise o diff e reporte** (não confie só no resumo do agente). Divergência volta ao agente,
   com o trecho exato — nunca correção à mão:
   - PRDs alterados mantêm template + Changelog atualizado, no idioma do projeto.
   - Nada inventado além das decisões.
   - Cabeçalhos de seção da visão com a mesma numeração de antes.
   - Nenhum mecanismo subiu ao PRD ou à visão (procure nomes de tabela, funções, rotas).
   - Cada acerto da frase morta foi tratado ou está nas pendências com comando de entrada.
   - **Coerência cross-feature** contra a visão (modelo, dependências, decisões) e a
     constituição, quando houver.

4. **Commit por tema**, no fluxo de branch/PR e nas regras de mensagem do `AGENTS.md`.

## Limite da análise por frase morta

Pega o que foi **invalidado**, não restrição **criada** mais abaixo — essa é pega pela pergunta, no
fecho do design, sobre qual critério distingue a forma rejeitada da escolhida.
