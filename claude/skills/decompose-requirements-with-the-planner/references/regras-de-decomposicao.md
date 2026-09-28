# Regras de decomposição

Regras que o the-planner aplica ao quebrar requisitos em épicos e features. Caminhos, template de
PRD, idioma e formato do Changelog vêm do `AGENTS.md` do projeto; o método está aqui.

## Índice
1. Hierarquia
2. O que é uma feature (e quando é grande demais)
3. Identificadores
4. Épicos: objetivo, critério de pronto, departamento
5. Ordem de entrega
6. Corte: quem fica com cada requisito
7. Altitude
8. Lastro: nada sem decisão humana
9. Saída

---

## 1. Hierarquia

| Nível | O que é | Onde mora |
|---|---|---|
| **Épico** | Iniciativa com objetivo e critério de pronto | Diretório `E<n>-<slug>/` no diretório de PRDs; objetivo e critério na visão |
| **Feature** | Uma entrega; **1 PRD = 1 ciclo de implementação** | `<id>-<slug>.md` dentro do diretório do épico |
| **Cenário** | Story da feature | No DEFINE da feature (acceptance tests), não no PRD |

**Épico não é departamento nem domínio.** Um departamento pode ter vários épicos, e um épico pode
atender mais de um departamento. O departamento atendido fica registrado na visão, ao lado da
feature. Departamento sem escopo concreto fica registrado na visão **sem épico** — não se cria
épico vazio para ele.

A feature é **ponta a ponta** (backend e frontend juntos), não uma camada.

## 2. O que é uma feature (e quando é grande demais)

Uma feature é uma entrega que vai para produção e é usada sozinha, com valor próprio.

**Grande demais** = contém **duas ou mais entregas que podem ir para produção separadas, cada uma
com valor próprio**. O teste: *uma parte pode ser entregue e usada sem a outra?* Se sim, são duas
features.

- Importação de clientes + importação do catálogo de produtos → duas features (cada uma vai
  sozinha).
- Cadastro de funcionários + desativação de usuários → duas features.
- Cadastro de pedido + orçamento do pedido: o orçamento não existe sem o pedido, mas o pedido
  sozinho já tem valor → duas features, a do orçamento dependendo da do pedido.

Os dois vícios que produzem feature grande demais:
- **Seguir o roadmap do documento de requisitos**: uma "fase" do roadmap vira um PRD e esconde um
  épico inteiro executado como um ciclo só.
- **Seguir as entidades do domínio**: "funcionários e competências", "descontos e licenças" — um
  PRD por entidade junta entregas independentes.

O corte segue **fatias verticais** entregáveis, não camadas nem entidades.

## 3. Identificadores

- **Épico:** `E<n>`, numerado a partir de `E0`.
- **Feature:** número de dois dígitos. Na decomposição inicial, numere na ordem em que as features
  aparecem no grafo de dependência (a fundação primeiro).
- **ID estável:** a feature mantém o número por toda a vida. Mudar de épico **não** muda o ID.
- **Feature desmembrada** ganha letra: `06` vira `06a`, `06b`, … O número original não volta a ser
  usado sozinho.
- **Feature nova** depois da decomposição recebe o próximo número livre.
- **Requisitos dentro do PRD** (objetivos, requisitos funcionais e não funcionais, métricas) seguem
  o esquema de IDs do `AGENTS.md`. No desmembramento, cada requisito **mantém o ID** no recorte que
  o recebe.

Renumerar faz toda referência já registrada (histórico, issues, commits) mudar de sentido. Por
isso nada se renumera — nem features, nem seções da visão.

## 4. Épicos: objetivo, critério de pronto, departamento

Cada épico tem, na visão:
- **objetivo** — o resultado que a iniciativa entrega;
- **critério de pronto** — como se sabe que o épico terminou;
- **features** que o compõem;
- **departamentos** atendidos.

Objetivo ou critério que o documento de requisitos não sustenta fica **`[a definir]`**, como
pergunta ao responsável. Não se preenche com um "default razoável".

## 5. Ordem de entrega

- **Não há fases.** Fase agrupa por calendário e concorre com o épico como segundo agrupamento.
- A ordem vem do **grafo de dependência entre features**, na visão: cada feature declara de quais
  depende (dura) e, quando for o caso, de quais depende de forma recomendada (soft).
- A visão destaca o **caminho principal** (a cadeia que entrega o núcleo de valor) e o que pode
  correr **em paralelo**.

## 6. Corte: quem fica com cada requisito

Vale na decomposição inicial e no desmembramento de uma feature existente.

- **Entrega tem um dono só.** Cada objetivo, requisito funcional e métrica vai para **exatamente
  uma** feature; a outra declara dependência dela. O dono de um requisito que serve às duas é
  **decisão do responsável**: sem decisão, vira pergunta — o the-planner não escolhe.
- **Métrica que mede os dois lados** (ex.: "zero clientes e zero produtos duplicados") se divide
  por recorte, quando o responsável decidir assim.
- **Restrição se repete.** Requisito não funcional que restringe os dois lados (tipo numérico de
  valores, acesso por departamento, auditoria de dados pessoais) aparece **em cada recorte que ele
  restringe, com o mesmo ID**. Restrição não é entrega; repeti-la não cria dono duplo.
- **Acoplamento que atravessa o corte** vira aresta no grafo (dependência explícita).
- Cada recorte de um desmembramento registra no Changelog: "desmembrado de <ID de origem>".

## 7. Altitude

PRD e visão carregam **problema, resultado, regra de negócio e restrição**.

Não carregam **mecanismo**: rotas, schema, nomes de tabela, policies, formato de token, sequência
de chamadas. Isso mora no design da feature. Um ADR na visão registra a **decisão**, não a
implementação.

Mecanismo no PRD vira critério a auditar em todo artefato abaixo dele; é o caminho pelo qual
planos incham sem que o produto avance.

## 8. Lastro: nada sem decisão humana

- Todo requisito normativo (MUST) rastreia a uma decisão humana registrada: o documento de
  requisitos ou uma decisão posterior do responsável.
- Um princípio genérico ("qualidade tipo ISO") legitima a existência de um pilar, não uma cláusula
  específica derivada dele.
- Item em aberto fica marcado `[a definir]` ou vira pergunta. Nunca vira default.
- Conceito do documento de requisitos que não cabe em nenhuma feature é **pergunta**, não omissão.

## 9. Saída

**Visão geral** (caminho no `AGENTS.md`), com pelo menos:
- visão geral do sistema e escopo (áreas e departamentos);
- tabela de features: ID, nome, épico, departamento atendido, dependências, link para o PRD;
- grafo de dependência, caminho principal e o que corre em paralelo;
- épicos: objetivo, critério de pronto, features;
- departamentos sem épico;
- pontos em aberto (`[a definir]` e perguntas).

**Um PRD por feature**, no template do `AGENTS.md`, dentro do diretório do épico, com o épico no
cabeçalho e o Changelog iniciado.
