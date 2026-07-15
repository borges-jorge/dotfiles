---
name: pbi-word-doc
description: Preenche o Modelo Padrão de Documentação de Dashboard/Portal (.docx) a partir da leitura completa de um projeto PBIP. Use quando o usuário pedir "preenche o doc padrão desse dashboard", "documenta esse PBI no modelo Word", "gera o pbi-doc.docx", ou apontar um projeto PBIP + o "Modelo Padrão de Documentação de Dashboard/Portal.docx" pra preenchimento formal.
---

# /pbi-word-doc — Preenchimento do Modelo Padrão de Documentação (Word)

Preenche o template corporativo `Modelo_Padrao_Documentacao_Dashboard_Portal*.docx` com base na leitura integral de um projeto Power BI (PBIP). É diferente da `/pbi-doc`: aquela gera markdown + HTML técnico para o time de dados; esta preenche o **formulário Word padrão da empresa**, com tom de documento formal mas escrito por gente, não por IA.

Nasceu do preenchimento do projeto `Voucher Legado BBIP` — use esse caso como referência de qualidade e nível de detalhe esperado.

## Quando usar

- Usuário aponta uma pasta com projeto PBIP + o modelo `.docx` (ou pede pra buscar o modelo) e quer o formulário preenchido
- Repetir o mesmo preenchimento em outros projetos PBI para manter padrão entre dashboards
- Atualizar um `.docx` já preenchido depois de mudanças no modelo (nova página, nova medida, etc.)

**Não usar quando:**
- Quer documentação técnica em markdown/HTML para o time de dados → `/pbi-doc`
- Quer auditoria de qualidade do modelo → `/pbi-modelo-review`
- Não existe template `.docx` no projeto nem foi fornecido um

## Pré-requisitos

1. Projeto em formato **PBIP** (pasta com `.SemanticModel/` e `.Report/`). Se só existir `.pbix`, pedir conversão antes (`File → Save as → Power BI Project`).
2. O template `Modelo_Padrao_Documentacao_Dashboard_Portal*.docx` — geralmente na raiz do projeto, ao lado da pasta `pbip/`. Se não encontrar, perguntar onde está ou se deve criar do zero a partir da estrutura de 16 itens descrita em `references/estrutura-modelo.md`.
3. Repositório git inicializado no projeto (usado para preencher o Histórico de Alterações a partir de commits reais — ver seção 4).
4. **Sem `python-docx` disponível no ambiente** (ambiente típico não tem `pip`). A skill assume edição direta do XML interno do `.docx` — ver `references/edicao-docx-xml.md` antes de escrever qualquer código.

## Processo

### 1. Ler o projeto PBIP inteiro

Mesma varredura da `/pbi-doc`, mas o objetivo aqui não é gerar catálogo técnico — é extrair contexto de **negócio** para prosa humana:

- `CLAUDE.md` do projeto (se existir) — geralmente já resume domínio, tabelas, medidas e regras de negócio; é o atalho mais rápido
- `SemanticModel/definition/model.tmdl`, `relationships.tmdl`, `expressions.tmdl`
- Todas as tabelas em `SemanticModel/definition/tables/*.tmdl` (nomes, colunas, fonte M, filtros aplicados na query)
- Todas as medidas DAX (nome, fórmula, displayFolder, o que cada uma calcula em termos de negócio)
- `Report/definition/pages/*/page.json` — nomes de páginas, ordem, quais estão ocultas
- `Report/definition/pages/*/visuals/*/visual.json` — tipos de visual usados (card, tabela, slicer, gráfico) e o que cada página mostra
- Parâmetros de conexão (SharePoint, banco, API) em `expressions.tmdl`

Se o projeto tiver um `.pbix` de backup na raiz e/ou uma planilha-fonte, ler os metadados (nome, tamanho, data de modificação) só para contexto de dependência — não abrir o binário.

### 2. Confirmar o público e a área

Perguntar **uma vez**, só se não for óbvio pelo `CLAUDE.md` ou por contexto já dado na conversa:
> Quem é o público principal desse dashboard (diretoria, gerência, analistas...) e qual área é dona do negócio? Vi que [X] no modelo, mas confirma antes de eu preencher a seção 3.

Não perguntar sobre nada que já dá pra inferir com segurança do modelo (nomes de tabela, filtros de contrato, medidas).

### 3. Preencher os 16 itens do template

Ver `references/estrutura-modelo.md` para o mapeamento completo item a item (o que cada seção espera e de onde tirar a informação no PBIP). Regras gerais:

- **Item 1 (Informações Gerais)**: Nome do dashboard = nome do `.pbip`. Versão inicial `1.0`. Data = data de **hoje** (data em que o documento está sendo gerado/atualizado — não confundir com a data do modelo).
- **Itens 2–13**: descritivos, tirados do modelo real. Nunca inventar KPI, filtro ou fonte que não exista no `.tmdl`/`.json`. Se uma informação não existir nos artefatos (ex: periodicidade de refresh agendada), dizer isso com naturalidade ("a confirmar com a área responsável"), não fingir saber.
- **Item 14 (Histórico de Alterações)**: preencher com base em **commits reais do git**, não em suposição — ver seção 4 abaixo.
- **Item 15 (Aprovação)**: deixar em branco para assinatura manual (`____` a preencher), não presumir nomes.
- **Item 16 (Resumo Executivo)**: até 10 linhas, tom de quem conhece o dashboard, não de IA resumindo um documento.

Seguir o guia de escrita em `references/estilo-escrita.md` para todo o texto de prosa (itens 2, 9, 16 principalmente): PT-BR direto, sem travessão (`—`), sem jargão de IA, frases que soam como alguém do time escrevendo, não como resumo automático.

**Formatação dos campos (ver `references/formatacao-campos.md`)**: rótulo em negrito + valor **na mesma linha** para campos curtos (`Responsável: Partnership`, não `Responsável:` num parágrafo e `Partnership` no próximo). Isso vale principalmente para o **item 5 (Indicadores/KPIs)**, onde cada medida tem vários campos curtos (Meta, Responsável, Nome do Indicador) — errar isso faz o documento parecer um `.txt` colado no Word. Só fórmula DAX e descrições longas ficam em bloco indentado abaixo do rótulo.

### 4. Histórico de Alterações a partir do git (item 14)

1. Rodar `git log --pretty=format:"%h %ad %s" --date=format:"%d/%m/%Y %H:%M"` na raiz do projeto (ou no repo que versiona o PBIP).
2. Se o `.pbip` foi convertido de um `.pbix` que existia antes do primeiro commit, checar a data de modificação do `.pbix` de backup (`ls -la --time-style=full-iso`) para confirmar que ele é anterior ao commit inicial — e declarar no texto que **antes do commit inicial o projeto não era versionado** (existia só como arquivo solto).
3. Montar a entrada de versão como um bloco estruturado, não como texto corrido com quebras manuais:
   - `Versão: 1.0`
   - `Data:` **data do commit mais recente relevante** (não a data de hoje — a data de hoje já está no item 1; aqui é quando a versão documentada foi de fato consolidada no código)
   - `Descrição:` frase curta explicando o que essa versão cobre + a nota sobre não ser versionado antes do commit inicial, se aplicável
   - `Commits relevantes:` seguido de uma **lista com marcadores**, um commit por linha, formato `DD/MM/AAAA - resumo em uma frase do que o commit fez` (traduzir a mensagem de commit para prosa, não colar a mensagem crua se ela for técnica demais)
   - `Responsável:` nome do autor do git (ou quem o usuário indicar)
4. Ao editar o XML (ver seção 5), usar **parágrafos separados** para cada linha (Versão, Data, Descrição, "Commits relevantes:", cada bullet, Responsável) — nunca empilhar tudo num parágrafo só com `<w:br/>`. Bullets usam `<w:pPr><w:ind w:left="720" w:hanging="360"/>...` e prefixo `•\t`. Ver `references/edicao-docx-xml.md` para o snippet pronto.

### 5. Editar o .docx sem python-docx

Ler `references/edicao-docx-xml.md` **antes** de tocar em qualquer arquivo. Resumo do fluxo:

1. Extrair o `.docx` (é um zip) para uma pasta temporária no scratchpad — nunca editar in-place.
2. Mapear os `<w:t>` de cada `<w:p>` relevante com um script Python (regex) pra enxergar como o texto está fatiado entre runs, antes de decidir o que substituir.
3. Fazer substituições de string exatas e únicas em `word/document.xml` (`str.replace(old, new, 1)` com `assert` de contagem == 1 antes de aplicar), preservando os runs em itálico/código (nomes de coluna, medida, tabela) intactos.
4. Reempacotar mantendo a lista original de `namelist()` do zip, escrevendo direto no `.docx` do usuário.
5. Se der `PermissionError` ao reempacotar, o arquivo está aberto no Word (ou travado pelo OneDrive) — avisar o usuário e pedir para fechar, não insistir em loop nem usar `--force` de qualquer tipo.

### 6. Validar antes de fechar

- Rodar `python3 -c "import xml.dom.minidom as m; m.parse('word/document.xml')"` para garantir XML válido antes de reempacotar.
- Reler o parágrafo editado (extrair `<w:t>` de novo) e conferir visualmente que não sobrou texto embolado, travessão, ou placeholder tipo `(a preencher)` em campos que já foram preenchidos.
- Checar o checklist de `references/formatacao-campos.md`: nenhum rótulo curto separado do valor em parágrafos diferentes, rótulos em negrito, fórmulas/descrições longas indentadas, entradas repetidas (medidas, páginas) visualmente separadas por espaçamento.

### 7. Resumir no chat

Mensagem curta: quais itens foram preenchidos/atualizados, de onde veio cada dado-chave (ex: "histórico de alterações a partir de 3 commits do git"), e o que ficou como placeholder esperando input humano (assinatura, aprovação, algo não confirmável pelo modelo).

## Edge cases

| Cenário | O que fazer |
|---|---|
| Não existe template `.docx` no projeto | Perguntar se o usuário tem um modelo padrão pra fornecer, ou se deve gerar a estrutura completa em `.docx` do zero (usar `references/estrutura-modelo.md` como esqueleto) |
| `.docx` já preenchido, pedindo atualização | Reabrir, comparar o que já existe com o estado atual do PBIP, atualizar só o que mudou + adicionar nova entrada no Histórico de Alterações (não reescrever a versão anterior) |
| Arquivo aberto no Word / OneDrive sincronizando | Avisar e pedir para fechar; tentar de novo só depois de confirmação do usuário |
| Sem repositório git no projeto | Não inventar histórico de commits; item 14 vira só "Versão 1.0, Data de hoje, Descrição da documentação inicial", sem seção de commits |
| Informação de negócio que exige confirmação humana (público-alvo, aprovadores) | Perguntar uma vez; nunca supor silenciosamente |

## Estilo e qualidade

- Ver `references/estilo-escrita.md` — regra viva, atualizada com o feedback recebido no preenchimento do `Voucher Legado BBIP` (sem travessão, sem "artefatos analisados", listas de commit como bullets de verdade, não texto corrido).
- Antes de considerar o item 14 pronto, reler em voz alta (mentalmente): se soar a um resumo de changelog gerado por IA, reescrever.

## Idempotência e segurança

- Nunca editar o `.docx` in-place sem passar por extração pra pasta temporária primeiro.
- Não commitar o `.docx` automaticamente — deixar para o usuário decidir (regra geral do projeto: só commitar quando pedido).
- Não usar `--force`/sobrescrita agressiva em caso de lock de arquivo; sempre pedir para o usuário fechar o Word.
