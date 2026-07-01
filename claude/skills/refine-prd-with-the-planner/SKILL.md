---
name: refine-prd-with-the-planner
description: >-
  Refina o planejamento (visão geral + PRDs) aplicando decisões de um brainstorm/refino:
  re-invoca o the-planner em "modo update" para propagar a mudança aos artefatos pertinentes
  — a visão geral e os PRDs afetados — sem drift de formato, versionando via Changelog. Use
  quando uma decisão muda requisitos/arquitetura depois que a visão e os PRDs já existem, ou
  quando uma mudança em um PRD precisa cascatear para outros.
---

# Refinar PRDs com o the-planner

> **Princípio:** um único escritor (`the-planner`) evita drift de formato; a cascata é
> explícita pela rastreabilidade já presente nos artefatos; o Changelog é a trilha de versão.
>
> **Agnóstica:** caminhos dos artefatos, template de PRD, idioma e formato do Changelog vêm
> do **`AGENTS.md`** do projeto — esta skill não fixa nada específico de um projeto.

## Quando usar
- Após um **brainstorm** que produziu **decisões** (resolver um ponto em aberto, um
  `[hipótese]`, um conflito).
- Quando uma mudança em um PRD ou na visão precisa **cascatear** para outros artefatos.

**Não** deixe o brainstorm escrever os PRDs direto — reintroduz drift. O brainstorm
**decide**; esta skill **aplica** (via the-planner).

## Pré-condições
- Já existem os artefatos de planejamento (visão geral + PRDs) definidos no `AGENTS.md`.
- As decisões a aplicar estão **escritas** como lista curta e inequívoca.
- Você está numa branch de trabalho, nunca numa branch protegida (ver `AGENTS.md`).

## Procedimento
1. **Consolide as decisões** numa lista clara (entrada do refino).
2. **Invoque o subagente `the-planner`** (agentspec) em **modo update**, só com
   orquestração — sem injetar escopo do projeto (ele lê os arquivos). Prompt-base:

   > Tarefa de **refino** do planejamento (modo update).
   > Entrada: a visão geral, o diretório de PRDs (caminhos no `AGENTS.md`) e a lista de
   > decisões abaixo: «…».
   > Para cada decisão:
   > a. Aplique-a.
   > b. Atualize as **seções afetadas da visão** (decisões/ADRs, pontos em aberto, modelo —
   >    onde existirem), sem assumir numeração fixa.
   > c. **Propague** para TODOS os PRDs que referenciam o item afetado, usando a
   >    rastreabilidade existente (referências cruzadas: decisões/ADRs, entidades, seções
   >    da visão).
   > d. **Mantenha** o template de PRD e o formato da visão definidos no `AGENTS.md` — não
   >    redefina templates.
   > e. Em cada PRD alterado, acrescente uma linha no rodapé **`## Changelog`** (conforme
   >    `AGENTS.md`), incrementando a versão.
   > f. Não invente além das decisões — o que continuar aberto permanece como tal.
   > Retorne um resumo: o que mudou em cada arquivo + o que ficou pendente.

3. **Verifique o diff** (não confie só no resumo do agente):
   - PRDs alterados mantêm template + Changelog atualizado, no idioma do projeto.
   - Nada inventado além das decisões.
   - **Coerência cross-feature** contra a visão (modelo / dependências / decisões) e a
     `constitution`.
4. **Commit por tema**, no fluxo de branch/PR e nas regras de mensagem do `AGENTS.md`.

## Status / maturidade
- **Project-local, NÃO validado.** Criada 2026-06-22; ainda não executada num ciclo real.
- **Promover a cross-project** (parent dir ou `~/.claude/skills/`, como o
  `padroes-qualidade.md`) **só após validação** em ≥1 refino real. Rastreado no
  `docs/roteiro-sdd.md`.
