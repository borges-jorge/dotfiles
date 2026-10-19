<!--
  ══════════════════════════════════════════════════════════════════════════════
  RELEASE NOTES — modelo

  A tag e a release saem AUTOMATICAMENTE quando a CI fecha verde na `master`. O que
  o gerador produz é um RASCUNHO: ele só tem os assuntos dos commits, e assunto de
  commit não carrega número, efeito nem justificativa. Por isso a nota gerada sai
  assinada com "Notas geradas automaticamente" no rodapé.

  Este modelo é a régua da nota CURADA. Enriquecer é REESCREVER a seção "O que
  mudou": o rascunho agrupa por tipo de commit, a nota curada agrupa por
  CAPACIDADE. Ao curar, apague a assinatura do rodapé.
  ══════════════════════════════════════════════════════════════════════════════

  TAG      v{MAJOR}.{MINOR}.{PATCH}
           SemVer em 0.x:  minor  capacidade nova, ou quebra declarada
                           patch  correção, documentação, manutenção
           Quebra declarada é a exclamação antes dos dois-pontos no assunto, em
           qualquer tipo, ou o rodapé BREAKING CHANGE no corpo. Sobe minor porque
           a v1.0.0 fica para quando a primeira feature de gestão de contratos
           (épico E3) estiver em produção.

  TÍTULO   v{X.Y.Z} — {componente}: {capacidade entregue}
           Nomeia a CAPACIDADE, não o assunto do commit que a trouxe.
           certo   v0.6.1 — Entrega: stack operado do diretório da aplicação
           errado  v0.6.1 — opera o stack do diretório da aplicação (assunto de commit)
           errado  v0.6.1 — Release de várias melhorias e correções

  ── AS CINCO REGRAS DO BULLET ────────────────────────────────────────────────

  1. PARTICÍPIO OU SUBSTANTIVO — descreve o ESTADO ENTREGUE, não a ação.
     certo   - `start_period` do storage ampliado para 60s
     errado  - amplia o start_period do storage

  2. NÚMERO, COM ANTES E DEPOIS — quando houver grandeza, ela aparece.
     certo   - `MAX_FILES_PER_BATCH` aumentado de 20 para 100
     errado  - limite de arquivos por lote expandido

  3. ARQUIVO OU SÍMBOLO REAL — o bullet aponta onde a mudança mora.
     certo   - `docker-compose.prod.yml` — healthcheck do `storage` sobreposto
     errado  - ajuste na configuração de produção

  4. O EFEITO, NÃO SÓ A MUDANÇA — o que passa a acontecer, ou deixa de acontecer.
     certo   - CEP deixa de ser lido como sequência de item: POs afetadas paravam
               de despejar centenas de linhas vazias no fluxo de correção
     errado  - corrigido falso positivo na extração

  5. VALOR ESCOLHIDO VEM COM A RAZÃO — número sem justificativa é chute.
     certo   - concurrency 8 = 4 cores × 2, pela fase de I/O do pipeline (~36s
               para 100 PDFs)
     errado  - concurrency ajustada para 8

  ── ESTRUTURA DE "O QUE MUDOU" ───────────────────────────────────────────────

  Uma subseção por CAPACIDADE ou componente tocado — nunca por tipo de commit.
  Duas a seis bullets por subseção. Lista aninhada quando o conteúdo é enumerável
  (fases rastreadas, endpoints alterados, arquivos migrados).

  Apague todos os blocos de comentário antes de publicar.
  ══════════════════════════════════════════════════════════════════════════════
-->

<!-- ABERTURA — uma frase dizendo o que esta versão passa a permitir.
     Não repita o título. Não liste. -->

{O que esta versão passa a permitir.}

## O que mudou

<!-- Subseções por capacidade. Exemplos de título de subseção que funcionam:
     "Entrega", "Provisionamento", "Verificação", "Backend", "Frontend",
     "Observabilidade", "Convenções". Apague as que não existirem nesta versão. -->

### {Capacidade ou componente}
- {estado entregue, com número, arquivo e efeito}
- {estado entregue, com número, arquivo e efeito}

### {Capacidade ou componente}
- {estado entregue}

## O que o operador precisa fazer

<!-- Ação que esta versão exige antes ou depois do deploy: migração, variável nova
     na configuração, passo de provisionamento, comando manual. É a seção lida
     durante um rollback. Escreva "Nada." quando a versão sobe sozinha — seção
     ausente não distingue "nada a fazer" de "ninguém verificou". -->

{Nada.}

## Evidência

<!-- O que sustenta a versão. Números, não adjetivos. Vale: contagem da suíte,
     id de execução, gates que fecharam verde, medição feita no host. -->

{Suíte com N testes passando. Execução `{id}` verde.}

## Ainda não entra

<!-- O que a versão deliberadamente NÃO faz, e onde isso é tratado.
     Impede que a nota prometa mais do que a tag entrega. Uma a três linhas. -->

{Fronteira desta versão.}

## PRs incluídos

<!-- Número e título de cada PR da versão, incluindo o de promoção. -->

- #{NN} {título do PR}

## Pendências registradas

<!-- Issues abertas por causa deste trabalho. Apague se não houver. -->

Issues #{NN}, #{NN}.

**Comparar:** [v{X.Y.Z-anterior}...v{X.Y.Z}](../../compare/v{X.Y.Z-anterior}...v{X.Y.Z})
