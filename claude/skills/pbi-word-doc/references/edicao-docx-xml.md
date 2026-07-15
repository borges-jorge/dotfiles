# Editando .docx sem python-docx

Ambiente típico não tem `pip`/`python-docx` instalado (`ModuleNotFoundError: No module named 'docx'`, `pip: command not found`). Não perder tempo tentando instalar — editar o XML interno diretamente. Um `.docx` é um zip com `word/document.xml` como conteúdo principal.

## 1. Extrair

```bash
python3 -c "
import zipfile
zipfile.ZipFile('/caminho/para/arquivo.docx').extractall('/tmp/claude-.../scratch_docx')
"
```

Nunca editar o `.docx` original diretamente. Sempre extrair para o scratchpad, editar lá, reempacotar de volta pro caminho original só no final.

## 2. Entender como o texto está fatiado em runs

Um parágrafo de prosa quase sempre tem **múltiplos `<w:t>`** por causa de formatação (itálico em nomes de campo, correção ortográfica automática do Word via `<w:proofErr>`, etc.). Antes de editar, sempre mapear:

```python
import re
xml = open('/tmp/.../word/document.xml', encoding='utf-8').read()
paras = re.findall(r'<w:p[ >].*?</w:p>', xml, re.S)
for i, p in enumerate(paras):
    texts = re.findall(r'<w:t[^>]*>(.*?)</w:t>', p, re.S)
    if texts:
        print(i, texts)
```

Isso evita substituir uma string que na verdade está partida em 2-3 runs (a substituição direta falharia silenciosamente ou pegaria o lugar errado).

## 3. Substituir com segurança

Sempre validar unicidade antes de aplicar:

```python
def rep(old, new, xml, n=1):
    c = xml.count(old)
    assert c >= n, f"NOT FOUND ({c}x): {old!r}"
    return xml.replace(old, new, n)
```

Preferir strings de contexto suficientemente longas para serem únicas no documento (frases inteiras, não palavras soltas).

## 4. Preencher campos "a preencher"

Buscar o padrão literal do template, geralmente `Campo: __________ (a preencher)` ou `Campo: ____________________________ (a preencher)`. Substituir só o valor, mantendo o resto do run intacto (`xml:space="preserve"` deve ser preservado se já existir).

## 5. Transformar texto corrido em lista com marcadores

Quando o conteúdo é uma sequência de itens (histórico de commits, lista de páginas, fontes de dados), **não** empilhar com `<w:br/>` dentro de um único `<w:p>`. Gerar parágrafos separados:

```python
RPR = '<w:rPr><w:lang w:val="pt-BR"/></w:rPr>'

def plain_para(text, spacing_after=True):
    sp = '<w:spacing w:after="160"/>' if spacing_after else '<w:spacing w:after="0"/>'
    return (f'<w:p w:rsidR="001B5B53" w:rsidRPr="007639EA" w:rsidRDefault="00000000">'
            f'<w:pPr>{sp}<w:rPr><w:lang w:val="pt-BR"/></w:rPr></w:pPr>'
            f'<w:r w:rsidRPr="007639EA">{RPR}<w:t xml:space="preserve">{text}</w:t></w:r></w:p>')

def bullet_para(text, last=False):
    sp = '<w:spacing w:after="160"/>' if last else '<w:spacing w:after="40"/>'
    return (f'<w:p w:rsidR="001B5B53" w:rsidRPr="007639EA" w:rsidRDefault="00000000">'
            f'<w:pPr><w:ind w:left="720" w:hanging="360"/>{sp}<w:rPr><w:lang w:val="pt-BR"/></w:rPr></w:pPr>'
            f'<w:r w:rsidRPr="007639EA">{RPR}<w:t xml:space="preserve">•\t{text}</w:t></w:r></w:p>')
```

Montar a lista de parágrafos (`plain_para` para Versão/Data/Descrição/Responsável, `bullet_para` para cada commit) e substituir o `<w:p>...</w:p>` inteiro original por `''.join(paragrafos)`. Reaproveitar o `w14:paraId` original só no primeiro parágrafo novo não é necessário — o Word regenera esses IDs sem problema.

Isso evita usar `numbering.xml` (bullet list "de verdade" com `numPr`), que exige mapear `abstractNumId`/`numId` existentes no template e é mais frágil de mexer sem `python-docx`. O truque `•\t` + `w:ind hanging` renderiza visualmente como lista e é seguro de gerar via regex.

## 5b. Campo rótulo:valor com negrito (ver `formatacao-campos.md`)

**Nunca** gerar um `<w:p>` só com "Rótulo:" e outro `<w:p>` só com o valor quando o valor é curto — isso é o erro que produz visual de bloco de notas. Rótulo em negrito e valor normal **no mesmo parágrafo**:

```python
def campo_linha(label, value, spacing_after=True):
    sp = '<w:spacing w:after="160"/>' if spacing_after else '<w:spacing w:after="0"/>'
    return (f'<w:p w:rsidR="001B5B53" w:rsidRPr="007639EA" w:rsidRDefault="00000000">'
            f'<w:pPr>{sp}<w:rPr><w:lang w:val="pt-BR"/></w:rPr></w:pPr>'
            f'<w:r w:rsidRPr="007639EA"><w:rPr><w:b/><w:lang w:val="pt-BR"/></w:rPr>'
            f'<w:t xml:space="preserve">{label}: </w:t></w:r>'
            f'<w:r w:rsidRPr="007639EA"><w:rPr><w:lang w:val="pt-BR"/></w:rPr>'
            f'<w:t xml:space="preserve">{value}</w:t></w:r></w:p>')
```

`campo_linha('Responsável', 'Partnership')` → um parágrafo, `Responsável:` em negrito seguido de `Partnership` normal, tudo na mesma linha.

Para valor longo/multi-linha (fórmula DAX, descrição de várias frases): rótulo em negrito num parágrafo próprio, valor **indentado** no parágrafo seguinte (código em fonte monoespaçada se o template tiver o estilo disponível):

```python
def campo_bloco(label, value, monoespaçado=False):
    rpr_valor = '<w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:lang w:val="pt-BR"/>' if monoespaçado else '<w:lang w:val="pt-BR"/>'
    return (
        f'<w:p w:rsidR="001B5B53" w:rsidRPr="007639EA" w:rsidRDefault="00000000">'
        f'<w:pPr><w:spacing w:after="40"/><w:rPr><w:lang w:val="pt-BR"/></w:rPr></w:pPr>'
        f'<w:r w:rsidRPr="007639EA"><w:rPr><w:b/><w:lang w:val="pt-BR"/></w:rPr>'
        f'<w:t xml:space="preserve">{label}:</w:t></w:r></w:p>'
        f'<w:p w:rsidR="001B5B53" w:rsidRPr="007639EA" w:rsidRDefault="00000000">'
        f'<w:pPr><w:ind w:left="360"/><w:spacing w:after="160"/><w:rPr>{rpr_valor}</w:rPr></w:pPr>'
        f'<w:r w:rsidRPr="007639EA"><w:rPr>{rpr_valor}</w:rPr>'
        f'<w:t xml:space="preserve">{value}</w:t></w:r></w:p>'
    )
```

Para blocos repetidos (uma entrada por medida/página/fonte, item 5 do template por exemplo), colocar o nome da entrada em negrito como mini-heading antes dos campos internos, e usar `w:spacing w:before` generoso no primeiro parágrafo de cada entrada nova para separar visualmente uma da outra.

## 6. Validar XML antes de reempacotar

```bash
python3 -c "import xml.dom.minidom as m; m.parse('/tmp/.../word/document.xml'); print('ok')"
```

Se falhar, algum `<w:t>`/`<w:p>` ficou malformado na substituição — não prosseguir para o reempacotamento.

## 7. Reempacotar preservando a lista original de entradas do zip

```python
import zipfile, os
src = '/caminho/original/arquivo.docx'
zin = zipfile.ZipFile(src)
names = zin.namelist()
zin.close()
with zipfile.ZipFile(src, 'w', zipfile.ZIP_DEFLATED) as zout:
    for name in names:
        zout.write(os.path.join('/tmp/.../scratch_docx', name), name)
```

Importante: usar `zin.namelist()` do arquivo original para garantir que nenhuma entrada (relationships, styles, fontTable, tema) fique de fora — escrever só `word/document.xml` sozinho corrompe o pacote.

## 8. Arquivo travado (Word aberto / OneDrive sincronizando)

`PermissionError: [Errno 13] Permission denied` ao reempacotar quase sempre significa que o `.docx` está aberto no Word (ou o OneDrive está com lock ativo). Não ficar tentando em loop com `time.sleep` — avisar o usuário e pedir para fechar o arquivo, tentar de novo só depois da confirmação.
