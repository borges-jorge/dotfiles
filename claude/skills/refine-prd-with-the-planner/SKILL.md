---
name: refine-prd-with-the-planner
description: >-
  Refina o planejamento (visão geral + PRDs) aplicando decisões de um brainstorm/refino:
  re-invoca o the-planner em "modo update" para propagar a mudança aos artefatos pertinentes
  — a visão geral e os PRDs afetados — sem drift de formato, versionando via Changelog. Também
  desmembra, move e retira PRDs. Use quando uma decisão muda requisitos/arquitetura/escopo depois
  que a visão e os PRDs já existem, ou quando uma mudança em um PRD precisa cascatear para outros.
---

# Refinar PRDs com o the-planner

> **Princípio:** um único escritor (`the-planner`) evita drift de formato; a cascata é
> explícita pela rastreabilidade já presente nos artefatos; o Changelog é a trilha de versão.
>
> **Agnóstica:** caminhos dos artefatos, hierarquia (ex.: épicos), esquema de IDs, template de PRD,
> idioma e formato do Changelog vêm do **`AGENTS.md`** do projeto — esta skill não fixa nada
> específico de um projeto.

## Quando usar
- Após um **brainstorm** que produziu **decisões** (resolver um ponto em aberto, um
  `[hipótese]`, um conflito).
- Quando uma mudança em um PRD ou na visão precisa **cascatear** para outros artefatos.
- Quando a **decomposição** muda: desmembrar um PRD, movê-lo de agrupamento, retirá-lo do plano.

**Não** deixe o brainstorm escrever os PRDs direto — reintroduz drift. O brainstorm
**decide**; esta skill **aplica** (via the-planner).

## Pré-condições
- Já existem os artefatos de planejamento (visão geral + PRDs) definidos no `AGENTS.md`.
- As decisões a aplicar estão **escritas** como lista curta e inequívoca.
- Você está numa branch de trabalho, nunca numa branch protegida (ver `AGENTS.md`).

## Procedimento

1. **Consolide as decisões** numa lista clara (entrada do refino). Só decisões de escopo e de
   negócio — o procedimento vem desta skill, não da lista.

2. **Análise de impacto pela frase morta, não por ID.** Um refino raramente só adiciona um ID: ele
   **invalida uma afirmação** que está reescrita em prosa em várias camadas (visão → PRD → DEFINE →
   DESIGN → runbooks → código). O grafo de IDs não enxerga isso — um requisito novo não tem quem o
   referencie. Para cada decisão:
   a. escreva a **frase que deixou de ser verdadeira** (não o requisito novo);
   b. procure-a, com sinônimos, em **todas** as camadas, de cima para baixo;
   c. cada acerto é raio de alcance.

   **Ponto de entrada:** o comando de entrada é o da **camada mais alta que a frase morta alcança**,
   não o da camada onde o problema foi percebido. Acertou na visão ou em PRD → este refino
   **primeiro**, e só depois o comando da camada de baixo (ex.: `/iterate` no DEFINE). Entrar por
   baixo faz a cascata inteira rodar sobre um upstream que ainda mente, e tudo roda duas vezes.

   **Limite:** a técnica pega o que foi **invalidado**, não restrição **criada** mais abaixo — essa é
   pega pela pergunta, no fecho do design, sobre qual critério distingue a forma rejeitada.

3. **Mudança de estrutura (desmembrar, mover, retirar) — antes de invocar o the-planner.** O
   the-planner edita arquivos, mas não move nem apaga. Quem executa esta skill:
   - **move** com `git mv` o PRD que muda de agrupamento, num commit só de renomeação;
   - no **desmembramento**, o PRD de origem é movido para o nome do primeiro recorte, e o the-planner
     cria os demais e edita todos no lugar;
   - na **retirada**, o `git rm` vem **depois** do refino, quando a visão já registrou a saída.

   Regras de ID e numeração vêm do `AGENTS.md`. Na ausência delas: IDs estáveis (desmembrado ganha
   sufixo, nunca renumera o original) e **seções da visão não se renumeram** — outros artefatos
   citam os números.

4. **Invoque o subagente `the-planner`** (agentspec) em **modo update**, só com
   orquestração — sem injetar escopo do projeto (ele lê os arquivos). Prompt-base:

   > Tarefa de **refino** do planejamento (modo update).
   > Entrada: a visão geral, o diretório de PRDs (caminhos no `AGENTS.md`), a lista de
   > decisões abaixo e o raio de alcance levantado: «…».
   > Para cada decisão:
   > a. Aplique-a.
   > b. Atualize as **seções afetadas da visão** (decisões/ADRs, pontos em aberto, modelo —
   >    onde existirem), **editando no lugar, sem renumerar seções**.
   > c. **Propague** para TODOS os artefatos do raio de alcance e para os PRDs que referenciam o
   >    item afetado (referências cruzadas: decisões/ADRs, entidades, seções da visão).
   > d. **Mantenha** o template de PRD, a hierarquia e o formato da visão definidos no `AGENTS.md`
   >    — não redefina templates nem introduza agrupamentos que ele não declare (ex.: fases).
   > e. **Altitude:** PRD e visão recebem só **problema, resultado, regra de negócio e restrição**.
   >    Mecanismo (rotas, schema, policies, formato de token, nomes de tabela) não sobe — fica no
   >    design da feature. Um `[a definir]` resolvido no design fecha com **remissão** ao design,
   >    sem copiar o mecanismo.
   > f. Em desmembramento: cada requisito do PRD de origem vai para **exatamente um** recorte; o
   >    que é compartilhado tem um dono, e o outro recorte declara a dependência. Registre no
   >    Changelog de cada recorte "desmembrado de …".
   > g. Em cada PRD alterado, acrescente uma linha no rodapé **`## Changelog`** (conforme
   >    `AGENTS.md`), incrementando a versão.
   > h. Não invente além das decisões — o que continuar aberto permanece como tal.
   > Retorne um resumo: o que mudou em cada arquivo + o que ficou pendente.

5. **Verifique o diff** (não confie só no resumo do agente):
   - PRDs alterados mantêm template + Changelog atualizado, no idioma do projeto.
   - Nada inventado além das decisões.
   - Cabeçalhos de seção da visão **idênticos** antes e depois (numeração preservada).
   - Nenhum agrupamento que o `AGENTS.md` não declare foi reintroduzido.
   - Em desmembramento: cada ID de requisito da origem aparece em **exatamente um** recorte.
   - Links e remissões entre visão e PRDs resolvem para arquivo existente.
   - Nenhum mecanismo subiu ao PRD/visão (procure nomes de tabela, funções, rotas).
   - Cada acerto da frase morta (passo 2) foi tratado ou tem comando de entrada identificado.
   - **Coerência cross-feature** contra a visão (modelo / dependências / decisões) e a
     `constitution`.

6. **Commit por tema**, no fluxo de branch/PR e nas regras de mensagem do `AGENTS.md`. A renomeação
   (passo 3) fica em commit próprio, para o histórico seguir o arquivo.

## Status / maturidade
- **User-level** desde 2026-07-01 (fonte versionada no repositório de dotfiles). Executada em
  refinos reais desde 2026-07-27.
- Desmembramento e retirada de PRD: procedimento novo, ainda não exercitado.
