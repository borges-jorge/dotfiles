---
name: decompose-requirements-with-the-planner
description: |
  Decompõe requisitos em épicos e features invocando o agente the-planner: a partir do
  documento de requisitos base (ex.: requisitos.md, prd.md) gera a visão geral e um PRD por
  feature, agrupados em diretórios de épico; ou reformula um PRD existente que se revelou grande
  demais em dois ou mais PRDs. Aplica as regras de hierarquia, IDs estáveis, critério de feature,
  dono de requisito no corte, restrição repetida, altitude e ordem por grafo de dependência. Use
  quando o projeto começa a ser planejado a partir de um documento de requisitos, quando é preciso
  refazer a quebra em épicos e features, ou quando uma feature contém duas ou mais entregas que
  podem ir para produção separadas. Não use para refinar o conteúdo de um PRD que continua sendo
  uma feature só — isso é refine-prd-with-the-planner.
---

# Decompor requisitos com o the-planner

> **Princípio:** a estrutura do plano (épicos, features, ordem) nasce num lugar só, com um único
> escritor (`the-planner`) e um único conjunto de regras (`references/regras-de-decomposicao.md`).
>
> **Agnóstica:** caminho do documento de requisitos, da visão e do diretório de PRDs, template de
> PRD, esquema de IDs de requisito, idioma e formato do Changelog vêm do **`AGENTS.md`** do
> projeto. O método está nesta skill.

## Entradas

| Modo | Entrada | Saída |
|---|---|---|
| **Plano inteiro** | O documento de requisitos base | Visão geral + um PRD por feature, nos diretórios de épico |
| **Desmembramento** | Um PRD existente + a razão do corte (as entregas que vão para produção separadas) | Dois ou mais PRDs no lugar do original + visão atualizada |

O desmembramento aparece quando o teste de feature grande demais acusa — em geral no brainstorm,
no `/define` ou no `/design` da feature. Ver a seção 2 das regras.

## Papéis

- **the-planner** — faz todo o trabalho: lê as entradas, aplica as regras, escreve a visão e os
  PRDs, e devolve perguntas sobre o que as entradas não decidem.
- **Quem invoca a skill** — orquestra: repassa a entrada sem alteração, repassa as perguntas do
  agente ao responsável sem alteração (uma por vez), executa o que o agente não tem ferramenta para
  fazer (`git rm`), revisa o diff e reporta. Não analisa, não decide e não edita os artefatos;
  divergência encontrada na revisão volta ao agente.

## Pré-condições

- O `AGENTS.md` do projeto declara os caminhos e o template de PRD.
- Branch de trabalho, nunca branch protegida (ver `AGENTS.md`).
- **Plano inteiro:** o diretório de PRDs ainda não tem o plano (ou o responsável decidiu refazê-lo).
- **Desmembramento:** o PRD existe, e a razão do corte está escrita.

## Procedimento

1. **Invoque o subagente `the-planner`** (agentspec) só com orquestração. Passe o caminho absoluto
   de `references/regras-de-decomposicao.md` (no diretório-base desta skill). Prompt-base:

   > Tarefa de **decomposição** do planejamento.
   > Leia as regras em «caminho absoluto de regras-de-decomposicao.md» e o `AGENTS.md` do projeto
   > (caminhos, template de PRD, esquema de IDs, idioma, Changelog). Aplique as regras à entrada:
   >
   > — **Plano inteiro:** documento de requisitos em «caminho». Gere a visão geral e um PRD por
   > feature, nos diretórios de épico, conforme a seção 9 das regras.
   >
   > — **Desmembramento:** PRD em «caminho»; razão do corte: «…». Reformule-o em dois ou mais PRDs
   > (IDs com letra, arquivos novos no diretório do épico), atualize a visão (tabela, grafo, épico)
   > e as remissões dos outros PRDs ao ID de origem. Edite a visão no lugar, sem renumerar seções.
   >
   > Onde a entrada não decide (dono de requisito no corte, objetivo ou critério de épico,
   > conceito sem feature), **não escolha**: marque `[a definir]` e liste como pergunta.
   > Retorne: arquivos criados e alterados, perguntas ao responsável, e os arquivos a remover.

2. **Perguntas.** Repasse cada pergunta ao responsável, sem alteração e uma por vez. Com as
   respostas, **retome o mesmo agente** para aplicá-las.

3. **Remoções.** No desmembramento, o PRD de origem sai com `git rm` depois que os recortes
   existem e a visão aponta para eles. O histórico do corte fica no Changelog de cada recorte
   ("desmembrado de …").

4. **Revise o diff e reporte.** Divergência volta ao agente, com o trecho exato:
   - Todo PRD no template do `AGENTS.md`, com o épico no cabeçalho e o Changelog.
   - Nenhuma "fase" ou agrupamento que as regras e o `AGENTS.md` não declarem.
   - Cada objetivo, requisito funcional e métrica aparece em **exatamente um** PRD, salvo divisão
     decidida pelo responsável; restrições repetidas com o mesmo ID.
   - Nenhum requisito do documento de requisitos (ou do PRD de origem) sumiu sem decisão.
   - Toda feature passa no teste de feature grande demais.
   - Links e remissões entre visão e PRDs resolvem para arquivo existente.
   - Nenhum mecanismo em PRD ou visão (rotas, nomes de tabela, policies).
   - Nenhum objetivo, critério ou dono preenchido sem lastro; o que falta está `[a definir]`.
   - Desmembramento: cabeçalhos de seção da visão com a mesma numeração de antes.

5. **Commit** no fluxo de branch/PR e nas regras de mensagem do `AGENTS.md`.

## Depois da decomposição

O conteúdo de cada feature é refinado antes do ciclo dela pela `refine-prd-with-the-planner`
(a partir do brainstorm da feature ou de uma decisão). Esta skill volta a ser usada só quando a
estrutura muda: um PRD que precisa virar dois ou mais, ou um plano refeito.
