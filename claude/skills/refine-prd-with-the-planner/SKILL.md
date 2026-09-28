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
- As decisões a aplicar estão **escritas** como lista curta e inequívoca, fornecida pelo
  responsável (o argumento da invocação, repassado sem alteração).
- Você está numa branch de trabalho, nunca numa branch protegida (ver `AGENTS.md`).

## Papéis
- **the-planner** — faz todo o trabalho do refino: análise de impacto, plano de estrutura,
  edição da visão e dos PRDs.
- **Quem invoca a skill** — orquestra: repassa as decisões, executa as operações de arquivo que o
  the-planner não tem ferramenta para fazer (`git mv`, `git rm`), revisa o diff e reporta. Não
  analisa, não decide e não edita os artefatos; divergência encontrada na revisão volta ao
  the-planner.

## Procedimento

1. **Invoque o subagente `the-planner`** (agentspec) em **modo update — fase de análise**, só com
   orquestração — sem injetar escopo do projeto (ele lê os arquivos). Prompt-base:

   > Tarefa de **refino** do planejamento (modo update), **fase de análise — não edite nada**.
   > Entrada: a visão geral, o diretório de PRDs (caminhos no `AGENTS.md`) e a lista de decisões
   > abaixo: «…».
   > Para cada decisão:
   > a. **Frase morta:** escreva a afirmação que **deixa de ser verdadeira** com a decisão (não o
   >    requisito novo). Um refino raramente só adiciona um ID; ele invalida uma afirmação
   >    reescrita em prosa em várias camadas, e o grafo de IDs não enxerga isso.
   > b. **Raio de alcance:** procure essa frase, com sinônimos, em **todas** as camadas, de cima
   >    para baixo (visão → PRDs → artefatos por feature → runbooks → código). Liste cada acerto.
   > c. **Ponto de entrada:** indique a **camada mais alta** que a frase alcança. Se ela não
   >    alcança visão nem PRD, este refino não é a entrada — diga qual comando é.
   > d. **Estrutura:** se a decisão desmembra, move ou retira PRD, liste as operações de arquivo
   >    necessárias, segundo as regras de ID e numeração do `AGENTS.md` (na ausência delas: IDs
   >    estáveis — desmembrado ganha sufixo, o original não é renumerado). No desmembramento, o PRD
   >    de origem é renomeado para o primeiro recorte (o histórico segue o arquivo); os demais
   >    recortes são arquivos novos. Retirada é remoção **depois** da edição, quando a visão já
   >    registrou a saída.
   > Retorne: frase morta, acertos e ponto de entrada por decisão; a lista de renomeações
   > (`origem → destino`) e de remoções.

2. **Execute as renomeações** listadas pelo the-planner com `git mv`, num commit só de
   renomeação. Nada além do que ele listou.

3. **Retome o mesmo the-planner** (mesmo contexto) para a **fase de edição**. Prompt-base:

   > Fase de **edição**. As renomeações foram aplicadas. Para cada decisão:
   > a. Aplique-a.
   > b. Atualize as **seções afetadas da visão** (decisões/ADRs, pontos em aberto, modelo —
   >    onde existirem), **editando no lugar, sem renumerar seções**.
   > c. **Propague** para todos os acertos do raio de alcance que estão na visão ou em PRD, e para
   >    os PRDs que referenciam o item afetado. Acertos em camadas abaixo do PRD ficam como
   >    pendência, com o comando de entrada de cada uma.
   > d. **Mantenha** o template de PRD, a hierarquia e o formato da visão definidos no `AGENTS.md`
   >    — não redefina templates nem introduza agrupamentos que ele não declare (ex.: fases).
   > e. **Altitude:** PRD e visão recebem só **problema, resultado, regra de negócio e restrição**.
   >    Mecanismo (rotas, schema, policies, formato de token, nomes de tabela) não sobe — fica no
   >    design da feature. Um `[a definir]` resolvido no design fecha com **remissão** ao design,
   >    sem copiar o mecanismo.
   > f. Em desmembramento: cada requisito do PRD de origem vai para os recortes conforme as
   >    decisões; o que não tiver dono decidido fica marcado como pendência, não é atribuído por
   >    você. Registre no Changelog de cada recorte "desmembrado de …".
   > g. Em cada PRD alterado, acrescente uma linha no rodapé **`## Changelog`** (conforme
   >    `AGENTS.md`), incrementando a versão.
   > h. Não invente além das decisões — o que continuar aberto permanece como tal.
   > Retorne: o que mudou em cada arquivo, as pendências e as remoções que continuam valendo.

4. **Execute as remoções** confirmadas pelo the-planner com `git rm`.

5. **Revise o diff e reporte** (não confie só no resumo do agente). Divergência volta ao
   the-planner, retomado com o trecho exato — nunca correção à mão:
   - PRDs alterados mantêm template + Changelog atualizado, no idioma do projeto.
   - Nada inventado além das decisões.
   - Cabeçalhos de seção da visão **idênticos** antes e depois (numeração preservada).
   - Nenhum agrupamento que o `AGENTS.md` não declare foi reintroduzido.
   - Em desmembramento: cada objetivo, requisito funcional e métrica da origem aparece em
     **exatamente um** recorte, salvo decisão em contrário no argumento.
   - Links e remissões entre visão e PRDs resolvem para arquivo existente.
   - Nenhum mecanismo subiu ao PRD/visão (procure nomes de tabela, funções, rotas).
   - Cada acerto da frase morta foi tratado ou está na lista de pendências com comando de entrada.
   - **Coerência cross-feature** contra a visão (modelo / dependências / decisões) e a
     `constitution`.

6. **Commit por tema**, no fluxo de branch/PR e nas regras de mensagem do `AGENTS.md`. A renomeação
   (passo 2) fica em commit próprio, para o histórico seguir o arquivo.

## Limite da análise por frase morta
Pega o que foi **invalidado**, não restrição **criada** mais abaixo — essa é pega pela pergunta, no
fecho do design, sobre qual critério distingue a forma rejeitada da escolhida.

## Status / maturidade
- **User-level** desde 2026-07-01 (fonte versionada no repositório de dotfiles). Executada em
  refinos reais desde 2026-07-27.
- Análise em duas fases e desmembramento/retirada de PRD: procedimento novo, ainda não exercitado.
