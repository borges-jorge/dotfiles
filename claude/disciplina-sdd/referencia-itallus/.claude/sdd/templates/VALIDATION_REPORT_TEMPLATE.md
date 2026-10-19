# VALIDATION: {Feature Name}

> Saída da execução feita pelo responsável, que o gate não consegue repetir, gravada sem alteração.
> Evidência do `/conformance-gate conformance` para os critérios que essa execução prova.

<!--
Como preencher:
- Arquivo: .claude/sdd/reports/VALIDATION_{FEATURE}.md.
- Uma nova execução regenera o arquivo inteiro; o histórico fica no git.
- Comando: a linha executada, sem segredo (senha e token ficam fora; cite a variável).
- Commit validado: SHA completo do HEAD em que a execução rodou, com a árvore limpa. Base do diff:
  a branch do PR e o SHA do ponto de divergência (`git merge-base <commit validado> origin/qa`).
- Resultado: o que a própria saída declara (ex.: APROVADO).
- Saída: a saída inteira, dentro do bloco. Sem triagem, comentário ou correção de quem grava.
- O relatório entra num commit próprio, que só toca o relatório.
- Apague este comentário ao gravar.
-->

## Metadata

| Attribute | Value |
|-----------|-------|
| **Feature** | {FEATURE_NAME} |
| **Comando** | `{comando sem segredo}` |
| **Commit validado** | {SHA completo} |
| **Base do diff** | origin/qa @ {SHA do ponto de divergência} |
| **Date** | {YYYY-MM-DD} |
| **Resultado** | {resultado declarado pela saída} |

---

## Saída

````text
{saída da execução, sem alteração}
````
