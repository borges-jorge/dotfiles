#!/usr/bin/env bash
# Calcula a proxima versao a partir dos commits desde a ultima tag e monta as
# notas da release.
#
#   scripts/next_version.sh <ref>       imprime a versao (ex.: v0.5.4)
#   scripts/next_version.sh <ref> notas  imprime o corpo da release
#
# Regra, com o projeto em 0.x:
#   feat        -> minor          (0.5.3 -> 0.6.0)
#   demais      -> patch          (0.5.3 -> 0.5.4)
#   quebra      -> minor tambem, porque major fica reservado para a v1.0.0
#                  (exclamacao antes dos dois-pontos, em qualquer tipo, ou o
#                  rodape BREAKING CHANGE no corpo)
# Sem commit novo desde a ultima tag, sai 1 e nao imprime nada.
set -euo pipefail

ref=${1:-HEAD}
modo=${2:-versao}

# A tag base e a ultima ALCANCAVEL a partir da referencia, nao a maior do
# repositorio: uma tag fora da linha principal nao pode virar base de um
# intervalo que nao a contem.
anterior=$(git describe --tags --abbrev=0 --match 'v*' "$ref" 2>/dev/null || true)
[ -n "$anterior" ] || anterior="v0.0.0"

intervalo="$anterior..$ref"
assuntos=$(git log --no-merges --format='%s' "$intervalo")
[ -n "$assuntos" ] || exit 1

maior="patch"
if printf '%s\n' "$assuntos" | grep -qE '^feat(\([^)]*\))?!?:'; then
    maior=minor
fi
# Quebra declarada pela exclamacao antes dos dois-pontos, valida em qualquer tipo.
if printf '%s\n' "$assuntos" | grep -qE '^[a-z]+(\([^)]*\))?!:'; then
    maior=minor
fi
if git log --format='%B' "$intervalo" | grep -q 'BREAKING CHANGE'; then
    maior=minor
fi

IFS=. read -r x y z <<< "${anterior#v}"
case "$maior" in
    minor) y=$((y + 1)); z=0 ;;
    patch) z=$((z + 1)) ;;
esac
versao="v$x.$y.$z"

if [ "$modo" != "notas" ]; then
    printf '%s\n' "$versao"
    exit 0
fi

# Notas: assuntos agrupados por tipo, na ordem em que interessam a quem le. Isto e um
# RASCUNHO — assunto de commit nao carrega numero, efeito nem justificativa, que e o que
# o modelo em .github/RELEASE_TEMPLATE/ exige da nota curada. Curar reescreve esta secao,
# reagrupando por CAPACIDADE; a assinatura no rodape marca o que ainda nao foi curado.
secao() {
    local padrao=$1 titulo=$2 linhas
    linhas=$(printf '%s\n' "$assuntos" | grep -E "^($padrao)(\(|:)" || true)
    [ -n "$linhas" ] || return 0
    printf '### %s\n' "$titulo"
    printf '%s\n' "$linhas" | sed -E 's/^[a-z]+(\([^)]*\))?: /- /; s/^- (.)/- \1/'
    printf '\n'
}

n=$(printf '%s\n' "$assuntos" | wc -l)
if [ "$n" -eq 1 ]; then printf 'Um commit desde a %s.\n\n' "$anterior"; else printf 'Reúne %s commits desde a %s.\n\n' "$n" "$anterior"; fi
printf '## O que mudou\n\n'
secao 'feat'            'Novidades'
secao 'fix'             'Correções'
secao 'perf'            'Desempenho'
secao 'refactor'        'Refatoração'
secao 'docs'            'Documentação'
secao 'test'            'Testes'
secao 'ci|build'        'Pipeline'
secao 'chore|style|revert' 'Manutenção'
printf '**Comparar:** [%s...%s](../../compare/%s...%s)\n' "$anterior" "$versao" "$anterior" "$versao"

# Assinatura: separa a nota gerada da enriquecida a mao. Quem enriquece apaga a
# linha, e e por ela que a validacao das notas sabe qual regua aplicar.
printf '\n_Notas geradas automaticamente a partir dos commits — rascunho, ainda nao curado._\n'
