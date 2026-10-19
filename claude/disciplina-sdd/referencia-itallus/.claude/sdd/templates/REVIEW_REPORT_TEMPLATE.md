# {CODE | SECURITY} REVIEW: {Feature Name}

> Saída do `{/code-review high origin/qa...HEAD | /security-review}` sobre o build da feature, gravada sem alteração.
> Entrada do `/conformance-gate conformance`, que prova, filtra e classifica cada achado.

<!--
Como preencher:
- Arquivo: .claude/sdd/reports/{CODE_REVIEW | SECURITY_REVIEW}_{FEATURE}.md, um por review.
- Uma rodada regenera o arquivo inteiro; o histórico fica no git.
- Commit revisado: SHA completo do HEAD em que o review rodou (`git rev-parse HEAD`), com a
  árvore limpa. Base do diff: a referência que o review usou e o SHA do ponto de divergência
  (`git merge-base <commit revisado> <referência>`).
- Achados: só a contagem que a saída declara; zero quando ela não traz nenhum.
- Saída: a resposta final do review, inteira, dentro do bloco. Sem triagem, severidade,
  comentário ou correção de quem grava.
- O relatório entra num commit próprio, que só toca os arquivos de review.
- Apague este comentário ao gravar.
-->

## Metadata

| Attribute | Value |
|-----------|-------|
| **Feature** | {FEATURE_NAME} |
| **Review** | {`/code-review high origin/qa...HEAD` \| `/security-review`} |
| **Commit revisado** | {SHA completo} |
| **Base do diff** | {referência} @ {SHA do ponto de divergência} |
| **Date** | {YYYY-MM-DD} |
| **Achados** | {N} |

---

## Saída

````markdown
{saída do review, sem alteração}
````
