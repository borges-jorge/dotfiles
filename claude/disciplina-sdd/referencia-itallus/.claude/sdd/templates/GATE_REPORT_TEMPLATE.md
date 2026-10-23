# {READINESS | CONFORMANCE}: {Feature Name}

> Saída de uma rodada do `/conformance-gate`, gravada sem alteração, com as respostas do
> responsável às confirmações. A sincronização da entrega lê este relatório.

<!--
Como preencher:
- Arquivo: .claude/sdd/reports/READINESS_{FEATURE}.md ou CONFORMANCE_{FEATURE}.md, conforme o modo.
- Uma nova rodada regenera o arquivo inteiro; o histórico fica no git. O gate lê o arquivo da
  rodada anterior antes de ele ser regenerado: quem grava só sobrescreve depois que o gate
  devolveu a saída.
- Rodada anterior: SHA completo do commit avaliado no relatório que este substitui; "primeira
  rodada" quando não há.
- Commit avaliado: SHA completo do HEAD em que o gate rodou, com a árvore limpa. Base do diff: a
  branch do PR e o SHA do ponto de divergência (`git merge-base <commit avaliado> origin/qa`).
- Veredito: o que a própria saída declara (PRONTO / NÃO PRONTO / AGUARDA RESPOSTA, APROVADO /
  BLOQUEADO / AGUARDA RESPOSTA).
- Saída: o relatório inteiro do gate, dentro do bloco. Sem triagem, comentário ou correção de quem
  grava.
- Respostas do responsável: uma linha por confirmação ou indeterminado respondido, com a rodada, o
  ID, o item em poucas palavras, a resposta e a data. Cumulativa: ao regenerar o relatório,
  carregar todas as linhas anteriores antes das novas. É o único campo escrito depois da gravação
  da saída.
- O relatório entra num commit próprio, que só toca o relatório; as respostas, noutro.
- Apague este comentário ao gravar.
-->

## Metadata

| Attribute | Value |
|-----------|-------|
| **Feature** | {FEATURE_NAME} |
| **Modo** | {readiness \| conformance} |
| **Commit avaliado** | {SHA completo} |
| **Base do diff** | origin/qa @ {SHA do ponto de divergência} |
| **Rodada anterior** | {SHA completo \| primeira rodada} |
| **Date** | {YYYY-MM-DD} |
| **Veredito** | {veredito declarado pela saída} |

---

## Saída

````text
{saída do gate, sem alteração}
````

---

## Respostas do responsável

| Rodada (commit avaliado) | ID | Item | Resposta | Data |
|--------------------------|----|------|----------|------|
| {SHA curto} | {ID} | {item em poucas palavras} | {resposta} | {YYYY-MM-DD} |
