# Estrutura do Modelo Padrão de Documentação de Dashboard/Portal

Mapeamento dos 16 itens do template `Modelo_Padrao_Documentacao_Dashboard_Portal*.docx` para onde buscar cada informação no projeto PBIP.

| # | Seção | De onde vem | Observações |
|---|---|---|---|
| 1 | Informações Gerais | Nome = nome do `.pbip`. Área/Proprietário/Responsável Técnico: `CLAUDE.md` do projeto ou perguntar ao usuário. Versão inicial `1.0`. | **Data = data de hoje** (data de emissão do documento), não confundir com item 14 |
| 2 | Objetivo | Descrição do modelo (tabelas fato, filtros de escopo em `expressions.tmdl`/queries M), benefícios e decisões suportadas pelas medidas principais | Ler as medidas DAX para entender que decisão cada uma suporta |
| 3 | Público-Alvo | Checkboxes Diretoria/Gerência/Coordenação/Analistas/Operação/Clientes | Inferir de quem usa cada página (ver item 4); confirmar com usuário se ambíguo |
| 4 | Inventário de Páginas/Telas | `Report/definition/pages/*/page.json` (nome, ordem, visibilidade) + `pages.json` (ordem/página ativa) | Declarar páginas ocultas/legadas explicitamente, não omitir |
| 5 | Indicadores (KPIs) | Medidas da tabela `_measures` (ou equivalente), na ordem numerada se o naming já tiver prefixo numérico | Fórmula-base e responsável pela regra de negócio (área dona do dado, não "IA"). **Cada medida é um bloco**: nome em negrito como mini-heading, depois Fórmula (indentada, monoespaçada), Meta e Responsável (rótulo em negrito + valor na mesma linha) — ver `formatacao-campos.md`, nunca rótulo e valor em parágrafos separados |
| 6 | Visualizações | Tipos de visual em `visuals/*/visual.json` (`visualType`: card, tableEx, slicer, etc.) | Agrupar por tipo, não listar visual a visual |
| 7 | Filtros | Slicers identificados nos visuals + colunas usadas em `USERELATIONSHIP`/calculation groups | Ligar cada filtro à coluna real (`tabela[coluna]`) |
| 8 | Fontes de Dados | Parâmetros M em `expressions.tmdl` (URLs SharePoint, nome de arquivo/planilha, listas) | Responsável = time dono da fonte (não o time de dados), se souber |
| 9 | Regras de Negócio | Filtros de M query, condições em medidas DAX (`hoje = "SIM"`, hardcodes, contratos específicos) | Citar valores hardcoded explicitamente (ex: percentual fixo) — isso é problema conhecido, não detalhe irrelevante |
| 10 | Segurança e Acessos | Checar `roles.tmdl`/RLS no `.SemanticModel/definition/` | Se não existir RLS, dizer isso direto, não inventar perfil |
| 11 | Dependências | Fontes externas (planilha/lista SharePoint) + calculation groups/configs especiais do modelo (ex: `discourageImplicitMeasures`) que quebram se alteradas | Formato: "X — se mudar Y, quebra Z" |
| 12 | Problemas Conhecidos | Hardcodes, páginas legadas não removidas, gaps de documentação (ex: frequência de refresh não declarada) | Só o que é real e verificável no modelo, não especulação |
| 13 | Melhorias Planejadas | Perguntar ao usuário se não houver backlog explícito no projeto (`.claude/sdd/features/` se existir) | Não inventar roadmap |
| 14 | Histórico de Alterações | **Git log do projeto** — ver seção 4 da SKILL.md principal | Bloco estruturado: Versão / Data (do commit mais recente relevante) / Descrição / Commits relevantes (lista) / Responsável |
| 15 | Aprovação | Deixar em branco (`____` a preencher) | Nunca presumir nomes de aprovador |
| 16 | Resumo Executivo | Síntese de até 10 linhas cobrindo objetivo + páginas + regra de negócio principal + uso pretendido | Escrever por último, depois de ter os outros 15 itens prontos — fica mais fácil resumir com o todo na cabeça |

## Onde encontrar cada artefato no PBIP

```
<Nome>.pbip
<Nome>.SemanticModel/
  definition/
    model.tmdl                 → nome do modelo, config geral (discourageImplicitMeasures etc.)
    relationships.tmdl         → item 7 (colunas por trás dos filtros de data/dimensão)
    expressions.tmdl           → item 8 (parâmetros de conexão, fontes)
    tables/*.tmdl              → colunas reais, tipo de tabela (fato/dim/measures)
    roles.tmdl (se existir)    → item 10 (RLS)
<Nome>.Report/
  definition/
    pages/pages.json           → item 4 (ordem de páginas, página ativa)
    pages/<id>/page.json       → item 4 (nome, visibilidade da página)
    pages/<id>/visuals/*.json  → itens 5, 6, 7 (KPIs em cards, tipos de visual, slicers)
CLAUDE.md (raiz do projeto ou dentro da pasta do PBIP) → atalho para itens 1, 2, 9, 11, 12
.claude/sdd/features/ (se existir, metodologia SDD) → item 13 (melhorias planejadas / backlog)
git log (raiz do repositório) → item 14
```

## Nota sobre múltiplos projetos

Ao repetir esse preenchimento em outro projeto PBIP, refazer a leitura do zero — não reaproveitar dados do `Voucher Legado BBIP` como referência de conteúdo, só como referência de **padrão de escrita e estrutura** (ver `estilo-escrita.md`).
