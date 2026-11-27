# VISUAL AUDIT: {Feature Name}

> Execução, no stack de dev, de cada caminho listado em `Caminhos:` nos argumentos da rodada, gravada
> e conferida quadro a quadro pelo agente principal antes da inspeção do responsável.
> Evidência do `/conformance-gate conformance` para o comportamento de tela da rodada.

<!--
Como preencher:
- Arquivo: .claude/sdd/reports/VISUAL_AUDIT_{FEATURE}.md. Cada rodada regenera o arquivo; o histórico fica no git.
- Commit auditado: SHA completo do HEAD do build, com a árvore limpa.
- Uma linha por caminho de cada argumento da rodada, na ordem do argumento.
- Esperado: o comportamento pedido, nas palavras do argumento. Proibido: o que não pode aparecer
  (volta à origem, piscada, pulo, rolagem não pedida, outro caminho com comportamento diferente).
- Resultado: OK ou DEFEITO. Evidência: o vídeo gravado e o instante, ou os quadros, com o que se vê.
- Caminho com DEFEITO volta pelo /iterate antes da inspeção do responsável.
- O relatório entra num commit próprio, que só toca o relatório.
- Apague este comentário ao gravar.
-->

## Metadata

| Attribute | Value |
|-----------|-------|
| **Feature** | {FEATURE_NAME} |
| **Commit auditado** | {SHA completo} |
| **Stack** | {endereço e massa de dados usados} |
| **Date** | {YYYY-MM-DD} |
| **Resultado** | {N caminhos: X OK, Y DEFEITO} |

---

## Caminhos

| # | Comportamento | Caminho | Esperado | Proibido | Resultado | Evidência |
|---|---------------|---------|----------|----------|-----------|-----------|
| 1 | {comportamento do argumento} | {caminho} | {esperado} | {proibido} | {OK \| DEFEITO} | {vídeo e instante, ou quadros} |
