# Formatação de campos — evitar visual "bloco de notas"

Problema real encontrado ao rodar a skill num segundo projeto (documentação de medidas DAX, item 5): cada rótulo virou parágrafo próprio, cada valor virou outro parágrafo, sem negrito, sem indentação, sem agrupamento visual. Resultado: texto plano empilhado, ilegível, sem cara de documento formal — como se tivesse sido colado de um `.txt`.

Exemplo do problema:

```
Fórmula:

CALCULATE(MAX(fato_pvi[Index]), fato_pvi[Category] = "OVERALL", ...)

Meta:

Sem meta numérica definida.

Responsável:

Partnership
```

Cada `Rótulo:` e seu valor em parágrafos separados, mesmo quando o valor é curto (`Partnership`, uma palavra). É trabalho de IA que não pensou em como o documento vai ser lido.

## Regra 1 — valor curto (uma linha, cabe ao lado do rótulo): mesma linha

`Responsável:`, `Meta:` (quando é uma frase curta), `Nome do Indicador:`, `Data:`, `Versão:` — sempre **rótulo em negrito + valor na mesma linha/parágrafo**:

```
Responsável: Partnership
```

Nunca:

```
Responsável:

Partnership
```

## Regra 2 — valor longo ou multi-linha (DAX, descrição de várias frases): rótulo em negrito na própria linha, valor logo abaixo, com indentação

Quando o valor é código (fórmula DAX) ou prosa de 2+ frases, manter o rótulo em negrito numa linha e o conteúdo na linha seguinte **recuada**, não solta no mesmo nível do resto do texto. Fórmulas DAX usam fonte monoespaçada (`Consolas` ou a que o template já usa para código, ver `styles.xml` do template — normalmente já existe um estilo tipo `Cdigo` ou run com `w:rFonts w:ascii="Consolas"`).

```
Fórmula:
    CALCULATE(MAX(fato_pvi[Index]), fato_pvi[Category] = "OVERALL", ...)
```

## Regra 3 — cada entrada (medida, página, fonte) é um bloco visualmente separado

Quando o item do template lista várias entradas do mesmo tipo (ex: item 5 "Indicadores/KPIs" com uma medida atrás da outra), cada entrada precisa:
- Nome da medida/indicador em **negrito, tamanho levemente maior** ou como um mini-heading (pode reusar um estilo de heading existente no template, tipo `Ttulo3`, se fizer sentido no nível hierárquico)
- Os campos internos (Fórmula, Meta, Responsável, Descrição) seguindo as Regras 1 e 2
- Espaçamento (`w:spacing w:before`/`w:after`) entre uma entrada e a próxima, para o olho conseguir separar onde uma medida termina e a outra começa — nunca todas coladas sem respiro

## Como implementar no XML

Usar runs com negrito (`<w:b/>`) dentro do mesmo `<w:p>` do rótulo + valor, e uma função helper específica (ver `edicao-docx-xml.md`, seção "Campo rótulo:valor com negrito") em vez de gerar tudo com `plain_para` genérico sem negrito.

## Checklist antes de entregar (adicionar ao checklist geral de `estilo-escrita.md`)

- [ ] Nenhum campo de valor curto (uma palavra ou frase curta) está em parágrafo separado do rótulo
- [ ] Rótulos estão em negrito, não em texto plano igual ao valor
- [ ] Fórmulas DAX/código têm indentação e, se o template tiver um estilo de código disponível, usam fonte monoespaçada
- [ ] Ao rolar o documento, dá pra distinguir visualmente onde uma entrada (medida, página, fonte) termina e a próxima começa, sem precisar ler o texto
- [ ] Reabrir o parágrafo gerado e perguntar: "isso parece um `.txt` colado no Word, ou um documento formatado de verdade?" — se parecer `.txt`, refazer
