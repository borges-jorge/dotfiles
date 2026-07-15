# Guia de escrita — preenchimento humano do modelo Word

Este guia existe porque a primeira versão do preenchimento do `Voucher Legado BBIP` saiu com jargão de IA e travessões em excesso, e precisou de duas rodadas de correção. Aplicar essas regras **desde a primeira passada**, não como revisão posterior.

## Proibido

- **Travessão (`—`)**. Nunca usar, em nenhum item. Trocar por:
  - dois-pontos, quando introduz uma explicação (`Fonte: SharePoint Online, site ...`)
  - vírgula, quando é um aposto (`..., necessária para o merge que traz short_title.`)
  - ponto e reescrita em duas frases, quando a ideia é longa demais para uma vírgula
- **Jargão de relatório-de-IA**: evitar "artefatos analisados", "medida-mãe" (trocar por "medida principal"), "conforme documentação disponível" repetido em toda frase, "conforme análise realizada". Se uma informação não foi encontrada, dizer isso de forma direta ("não consta na documentação disponível" no máximo uma vez, não em cada seção).
- **Ponto e vírgula empilhando 3+ ideias na mesma frase** (`X; Y; Z.`). Preferir frases curtas separadas ou lista com marcadores quando há 3+ itens.
- **Texto corrido com `<w:br/>` manual simulando lista**. Se o conteúdo é uma sequência de itens (commits, páginas, fontes), vira lista de verdade com marcador (`•\t`) e recuo, parágrafos separados no XML — não uma parede de texto com quebras de linha.
- **Inventar dado que não está no modelo.** Sem meta numérica declarada? Dizer "sem meta numérica definida até o momento", não inventar uma meta.

## Preferido

- Frases curtas, diretas, como alguém do time escrevendo depois de olhar o modelo.
- Números e nomes de campo exatamente como aparecem no `.tmdl`/`.json` (não adaptar `item_status` para "status do item" dentro de parênteses técnicos, mas pode usar prosa fora deles).
- Verbos ativos: "Ajuda a priorizar...", "Detalha...", "Filtra..." em vez de "É responsável por priorizar...".
- Onde fizer sentido, reconhecer limitação com naturalidade: "a confirmar com a área responsável", "não há RLS configurada no modelo analisado".

## Exemplos (antes / depois)

❌ "Área Responsável: Planejamento e Governança (Plan & Gov) — Italtel BR"
✅ "Área Responsável: Planejamento e Governança (Plan & Gov) da Italtel BR"

❌ "3. $ Valor do Voucher — Medida-mãe: 23,2% do valor líquido de ICMS..."
✅ "3. $ Valor do Voucher: medida principal, 23,2% do valor líquido de ICMS..."

❌ "Frequência de Atualização: ... (a confirmar — modelo expõe timestamp do último refresh..."
✅ "Frequência de Atualização: ... (a confirmar; o modelo expõe timestamp do último refresh..."

❌ Histórico de commits como texto corrido: `01/06/2026 - commit inicial: ...\n01/06/2026 - adição da guarda...\n03/06/2026 - criação da página...` tudo dentro do mesmo parágrafo com `<w:br/>`
✅ Cada commit como parágrafo próprio, com `•\t` e recuo hanging, espaçamento entre linhas (`w:spacing`)

## Checklist antes de entregar

- [ ] Zero ocorrências de `—` no `word/document.xml` (checar com `xml.count('—') == 0`)
- [ ] Nenhuma seção terminando em "(a preencher)" que já tinha dado disponível para preencher
- [ ] Listas (commits, páginas, KPIs com 3+ itens) estão como parágrafos com marcador, não texto corrido
- [ ] Releu o item 14 e o item 16 perguntando "isso soa como um changelog gerado automaticamente?" — se sim, reescrever
