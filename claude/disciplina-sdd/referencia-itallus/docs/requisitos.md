# itallus — Requisitos iniciais

## 1. Visão geral
**itallus** é o sistema interno da **diretoria de planejamento** para automatizar e
sistematizar os processos da diretoria. Um **único sistema** abarcando várias áreas:
**Planejamento, Faturamento, Logística, Importação, BID e Parcerias** (outras podem ser
adicionadas depois; **Compras** provavelmente fica fora).

É majoritariamente uma ferramenta de **pós-venda** — gestão do **contrato** do início ao
fim, depois que o projeto é vendido. Exceção: o **BID**, que é pré-venda.

Abordagem **incremental**: começar pelos processos mais críticos/maduros; alguns entram
primeiro só como **pequenos serviços/automações** (quick wins), outros amadurecem depois.

## 2. Áreas e controle de acesso
- Acesso **por área**: cada usuário enxerga as funções/processos da sua área (ex.: um
  colaborador de logística vê só logística).
- Um usuário pode ter acesso a **mais de uma área**, conforme suas permissões.
- Configuração de acesso **a nível de usuário** (quais módulos/áreas ele acessa).

## 3. Infraestrutura e stack
- **On-premises**: servidor local, acessível **apenas via VPN** na rede interna (sem
  acesso externo de entrada; só de dentro para fora). **VM dedicada** para o itallus
  (área de planejamento).
- **Backend:** Python.
- **Supabase (self-hosted):** autenticação, banco de dados e demais funções (logs,
  backup) sobre a infra do Supabase.
- **Banco:** PostgreSQL (via Supabase).
- **Frontend:** React + Tailwind + shadcn. Framework JS **(a definir)** — Next.js é uma
  opção; trazer alternativas para o brainstorm.
- **Arquitetura** dentro das boas práticas de mercado/literatura: **Clean Code, SOLID,
  design patterns** e padrões de qualidade de software (tipo ISO).
- **Plugabilidade:** os **componentes em geral** devem ser substituíveis com baixo esforço
  (não só autenticação e banco — ex.: trocar o auth do Supabase, migrar o banco para
  nuvem gerenciada / outro banco local). **Avaliar a complexidade** dessa generalização.

## 4. Requisitos não-funcionais
- **LGPD (desde a v1):** mapeamento de dados sensíveis, direito ao apagamento,
  anonimização, privacidade, **políticas de retenção** com prazos.
- **Posterior** (não exigido na v1):
  - **Backup e disaster recovery**.
  - **Circuit breaker** e **middlewares** (autenticação e outros necessários).
  - **Microsserviços** para atividades específicas (ex.: subir uma planilha, processar e
    devolver outra) — provavelmente **stateless**.

## 5. Integração com o NetCorp
**NetCorp**: sistema legado (20+ anos, sem atualização/manutenção, pouca documentação),
mas é o **core de informação** da empresa. Objetivo: extrair as informações principais
para o itallus, evitando **duplicidade** e garantindo **unicidade** da informação.
- **Origem:** Microsoft SQL Server (infra interna), consultado via **SQL**.
- Tabelas a integrar inicialmente (servem a **todo** o sistema):
  1. **Clientes** — cada cliente é um **CNPJ**; CNPJs são agrupados em **grupos de
     cliente**. Um CNPJ é o **principal** (identifica o grupo): cada linha de CNPJ aponta
     o CNPJ principal do seu grupo. A consulta traz **CNPJ, nome do cliente e grupo**.
  2. **Centro de resultado (BR / projeto)** — cada centro = uma conta de faturamento.
     Há **centros internos** (um por área: compras, RH, comercial, logística,
     faturamento, planejamento — com padrão de código) e **centros de projeto**. **BR =
     projeto = centro de resultado**, integrado do NetCorp **depois** que o BR vira
     projeto (após a venda).

## 6. Colaboradores (tabela nativa do itallus)
- **Preenchimento manual** no itallus (não integrada de sistema externo, por enquanto).
  A princípio só colaboradores **internos** (externos depois — custo externo é disputa
  de compras).
- **Link colaborador ↔ usuário** (usuários do Supabase): são coisas distintas. Um usuário
  (diretor/gerente) pode existir sem ser colaborador; um colaborador pode ter usuário. O
  link deve existir de modo que, ao **bloquear/excluir (soft) um usuário**, o registro de
  **colaborador seja preservado**.

## 7. Gestão de contratos (processo principal — Planejamento)
Primeiro grande processo. Estrutura inspirada no **SAP** (usado pelos **2 maiores
clientes**), mas **generalizada** para todos os clientes/projetos (não é recriar o SAP).

- **Contrato Jurídico** (guarda-chuva / nível principal)
  - Campos (lista **não exaustiva**, **a definir**): nome, data início/término, data de
    assinatura, **valor (R$)**, riscos, penalidades, restrições (informações jurídicas).
  - **Código interno** único (gerado pelo itallus) + **código externo** (vem do cliente;
    se não houver, **externo = interno**).
- **Contrato Operacional** (um ou mais por jurídico)
  - É o que de fato gera **entregas/demandas**; sempre **linkado** a um jurídico.
  - Mesma estrutura: **código interno + externo** (mesma regra), datas, valor, descrições
    (podem diferir do jurídico).
- **BR / Projeto** (um ou mais por operacional)
  - **BR = projeto = centro de resultado** (integrado do NetCorp após a venda).
  - Tem o **PCR** (planilha de custos do projeto): 4 informações principais — **valor de
    invoice** (faturamento), **valor de receita (revenue)** (normalmente igual ao invoice,
    às vezes diferente), **% 1ª margem**, **% 2ª margem**. Além de outras infos
    (faturamento, alocação de horas, classificação do projeto/tecnologia etc.).

## 8. Alocação de esforço e custeio
- Colaboradores atuam nos **BRs/projetos**; um colaborador pode atuar em **1+ projetos**,
  distribuindo seu **esforço mensal**.
- Mensalmente, **Operações** envia uma **planilha de alocação de esforço**: uma **linha
  por colaborador×BR**, com **12 colunas de mês**; cada célula = esforço em **dias**
  naquele projeto/mês. A **soma por mês** totaliza a capacidade do colaborador no mês.
  Inclui férias/licença/treinamento — lançados no **centro de custo interno** do
  colaborador. A planilha cobre **mês corrente + 3 meses** (4 meses de forecast).
- **Skill:** cada colaborador tem uma **skill** (classificação que agrupa habilidades num
  **padrão de preço** — colaboradores com custo real diferente podem ter o **mesmo custo
  padrão**). Identificada por um **código** **(formato a definir)**.
- **SPC (Standard Price Cost):** planilha que mapeia **skill → valor/hora**. Atualizada
  ~**2×/ano**. **Histórico obrigatório** dos valores.
- **Fechamento mensal:** ao fechar o mês, pega-se a coluna do mês, identifica a skill de
  cada colaborador, converte **dias → horas** e multiplica pelo valor da skill (SPC) →
  **custo em reais** efetivo do mês.
- **Departamentos de Operações:** SDC, TOC, PMO (entre outros). Um colaborador pode
  **migrar de departamento** (o que muda também sua skill).
- O **SPC** (custo padrão por skill) vale para custo **interno e externo**.

## 9. Históricos obrigatórios (3)
1. **Departamento** (= centro de resultado interno, que o identifica) de cada colaborador
   ao longo do tempo.
2. **Skill** de cada colaborador ao longo do tempo.
3. **Valor de cada skill** (SPC) ao longo do tempo.

## 10. Demais áreas/fluxos (na ordem do processo)
- **BID** (pré-venda / início): apoia o comercial. Área técnica define o **escopo técnico**
  (equipamentos, arquitetura — projetos de telecom/TI); o BID faz a **precificação**,
  negocia descontos com fornecedores e define margens. Quando o cliente compra → **handoff**:
  BID passa a oportunidade para **Operações** (entra a pós-venda; gera-se o contrato). No
  itallus, a princípio: **criação de BR** (estrutura simples, ~5–8 colunas, com info da
  oportunidade — custo, preço). O BR é cadastrado no NetCorp no **handoff**. Possivelmente
  também o **fluxo do BID**.
- **Faturamento**: conforme o cliente solicita atividades dentro do projeto, cada atividade
  consome equipamento/serviço/material e gera faturamento do seu escopo. Fluxo de **PO
  (Purchase Order)** — cada PO relaciona um grupo de equipamentos/serviços/materiais
  vendidos; **BOQ** = lista de material. Processo **pouco claro**; entra como pequenas
  demandas avulsas, **não** como processo principal ainda.
- **Logística e Importação**: importação (aduaneiro, liberação no porto, nacionalização) e
  logística (store/galpão, transporte). Ainda **obscuro — não entra agora**.
- **Parcerias**: fluxo paralelo de **rebate** (incentivo/cashback — fornecedor paga % sobre
  vendas; direto ou via distribuidor, com % diferentes). itallus, a princípio: **controle
  de rebate** + **controle de renovação de licenças/software**.
- **Compras**: do grupo, mas **provavelmente fora** do itallus (sistema à parte).

## 11. Fora de escopo (deste projeto)
- **Cruzamento consumo × contrato**: os lançamentos/consumo do contrato ocorrem no NetCorp;
  o cruzamento será feito numa **plataforma de dados externa** (datalake / data warehouse
  on-prem) — **fora do escopo**.
- **Compras** (provável), **custo externo** de colaboradores (depois), **escopo técnico** e
  **comercial/pré-venda** (exceto o fluxo do BID).

## 12. Roadmap / ordem de implementação
0. **v1 operacional em produção**: login/autenticação + página inicial com a estrutura de
   todas as áreas (mesmo com páginas em branco).
1. Integrar com a **tabela de Clientes** do NetCorp.
2. Criar a estrutura de **Contratos** — ao menos o **Jurídico**; depois **Operacionais**;
   depois **BRs**.
3. Cadastrar **Colaboradores**.
4. Área para **importar a planilha de Operações** (alocação, mês + 3).
5. **Cálculo de custo do mês** (fechamento).
6. Fluxo do **BID** (criação de BR).
7. **Parcerias**: controle de rebate + renovação de licenças/software.
8. Fluxos avulsos de **Faturamento**.
9. Logística/Importação: **depois**.
> Foco inicial: **Gestão de Contratos** (processo principal de Planejamento).

## 13. Método de desenvolvimento
- Ferramenta: **Spec Kit (GitHub)** para **SDD** (trabalha por ciclos/feature).
- O **brainstorm** estuda e planeja a arquitetura e as regras e produz: um **PRD principal**
  (com tudo) + **um PRD por feature**, além de um **plano de implementação
  feature-a-feature** para o Spec Kit executar.
- O **PRD é saída** do brainstorm, não entrada.

## 14. Pontos em aberto (a definir/confirmar no brainstorm)
- Formato real do **código de skill**.
- **Framework JS** do frontend (Next.js? outro?).
- Detalhamento das demais informações do **PCR** e do contrato operacional.
- Campos do **contrato jurídico** (lista não exaustiva).
- Até onde vai a **plugabilidade** de componentes (e sua complexidade).
- Magnitude dos **valores ilustrativos** (ex.: projeto de R$150 mi, atividade de R$5 mi).
- Se o **fluxo do BID** (além da criação de BR) entra agora.
