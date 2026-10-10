#!/usr/bin/env bash
# Valida o corpo de um PR, issue ou release contra o template correspondente.
#
#   scripts/check_body.sh <pr|issue|release> <arquivo-com-o-corpo>
#
# Confere duas coisas objetivas:
#   1. as secoes obrigatorias do template existem;
#   2. nenhum placeholder {…} nem bloco de instrucao <!-- --> sobreviveu.
# Qualidade do conteudo continua sendo revisao humana.
set -u

tipo=${1:-}
arquivo=${2:-}
erros=0

reprova() {
    printf 'REPROVADO: %s\n' "$1" >&2
    erros=1
}

if [ ! -f "$arquivo" ]; then
    printf 'uso: %s <pr|issue|release> <arquivo>\n' "$0" >&2
    exit 2
fi

corpo=$(cat "$arquivo")

if [ -z "${corpo//[[:space:]]/}" ]; then
    reprova "corpo vazio; use o template."
    exit 1
fi

case "$tipo" in
    pr)      obrigatorias="## O que entra|## Evidência|## Ainda não entra"
             modelo=".github/PULL_REQUEST_TEMPLATE.md" ;;
    issue)   obrigatorias="## Context|## Expected"
             modelo=".github/ISSUE_TEMPLATE/" ;;
    # A release nasce da CI assinada pelo gerador, e dela so se pode exigir o que
    # ele produz. A nota enriquecida a mao perde a assinatura e passa a responder
    # pela estrutura inteira do modelo.
    release) if printf '%s' "$corpo" | grep -qF 'Notas geradas automaticamente'; then
                 obrigatorias="## O que mudou"
             else
                 obrigatorias="## O que mudou|## O que o operador precisa fazer|## Evidência|## Ainda não entra"
             fi
             modelo=".github/RELEASE_TEMPLATE/release-notes.md" ;;
    *)       printf 'tipo desconhecido: %s (use pr, issue ou release)\n' "$tipo" >&2
             exit 2 ;;
esac

# 1. Secoes obrigatorias.
IFS='|' read -ra secoes <<< "$obrigatorias"
for s in "${secoes[@]}"; do
    printf '%s' "$corpo" | grep -qF "$s" || reprova "falta a seção \"$s\"."
done

# 2. Placeholder por preencher. O padrao {…} e do template; um par de chaves
#    dentro de bloco de codigo e legitimo, entao a busca ignora o que estiver
#    entre cercas de crase.
fora_de_codigo=$(printf '%s\n' "$corpo" | awk '/^[[:space:]]*```/{dentro=!dentro; next} !dentro')
achados=$(printf '%s' "$fora_de_codigo" | grep -oE '\{[^{}]{2,}\}' | head -3)
if [ -n "$achados" ]; then
    reprova "placeholder do template não foi preenchido:"
    printf '%s\n' "$achados" | sed 's/^/    /' >&2
fi

# 3. Bloco de instrucao do template deixado no corpo.
if printf '%s' "$corpo" | grep -q '<!--'; then
    reprova "bloco de instrução <!-- --> do template não foi removido."
fi

if [ "$erros" -ne 0 ]; then
    printf '\nModelo: %s\n' "$modelo" >&2
    exit 1
fi
exit 0
