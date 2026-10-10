<!--
  ══════════════════════════════════════════════════════════════════════════════
  TÍTULO DO PR — {tipo}({escopo}): {descrição em presente do indicativo}
  ══════════════════════════════════════════════════════════════════════════════

  Ele vira o CORPO DO COMMIT DE MERGE: é o texto que sobra na mainline para sempre.
  Por isso segue exatamente as regras do assunto de commit, e o job `enforce-title`
  reprova o PR se não seguir:

    · verbo em presente do indicativo, primeiro    "adiciona", não "adicionar"
    · até 72 caracteres, contando tipo e escopo
    · sem identificador de artefato                SC-017 FR-023 T082 R39 §8
                                                   (ADR-nnn é admitido)
    · diz o que mudou, não qual comando rodou

  certo   feat(deploy): divide o provisionamento em três scripts
  errado  feat(deploy): dividir o provisionamento (T094/T095) — implement

  As regras completas estão em `.gitmessage`.
  Apague todos os blocos de comentário antes de abrir.
  ══════════════════════════════════════════════════════════════════════════════
-->

## O que entra

<!-- Uma linha por capacidade entregue, em PARTICÍPIO ou SUBSTANTIVO — descreve o
     estado que passa a existir, não a ação. Nomeie o componente e o arquivo reais.
     Três a oito linhas. Se passar disso, o PR provavelmente carrega dois assuntos.

     certo   - `reset-host.sh` — desfaz a instalação varrendo por rótulo de projeto
     errado  - mexi no script de limpeza -->

- `{caminho ou componente}` — {estado entregue}
- `{caminho ou componente}` — {estado entregue}

## Evidência

<!-- O que sustenta que funciona. Sem isto o PR é uma promessa.
     Vale: contagem da suíte, nome do job de CI que fechou, id da execução de deploy,
     medição com número. Não vale: "testei localmente", "está funcionando".

     REGRA DURA: evidência colhida no terminal — execução em host, medição manual —
     PRECISA ser colada aqui. Ela não viaja com a revisão e some depois do merge. -->

{Suíte: N testes passando. CI: jobs verdes. Execução: `{id}`.}

```text
{Cole aqui a saída que prova o que você afirma acima. Trim para as linhas relevantes.}
```

## Ainda não entra

<!-- O que este PR deliberadamente NÃO faz, e para onde vai. Impede que a revisão
     cobre o que nunca foi prometido, e que a release note prometa demais.
     Uma a três linhas. Se não houver nada, escreva "Nada — o escopo fecha aqui." -->

{Fronteira do escopo, e onde o resto é tratado.}

## Pendências

<!-- Issues abertas por causa deste trabalho. Só o número e uma frase.
     Apague a seção se não houver nenhuma. -->

- #{NN} — {uma frase}
