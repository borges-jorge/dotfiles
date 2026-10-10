#!/usr/bin/env bash
# Valida um assunto de commit ou titulo de PR contra as convencoes do repositorio.
#
#   scripts/check_subject.sh "<assunto>" [arquivo-com-a-mensagem-completa]
#
# Sai 0 se o assunto passa; 1 e explica cada regra violada.
# Usado pelo hook .githooks/commit-msg e pelo workflow check-pr-direction.yml —
# uma implementacao so, para as duas portas nao divergirem.
set -u

assunto=${1:-}
corpo_arquivo=${2:-}
tipos='feat|fix|docs|chore|refactor|test|style|ci|build|perf|revert'
erros=0

reprova() {
    printf 'REPROVADO: %s\n' "$1" >&2
    erros=1
}

if [ -z "$assunto" ]; then
    reprova "assunto vazio."
    exit 1
fi

# 1. Conventional Commits: <tipo>(<escopo>): <descricao>
if ! printf '%s' "$assunto" | grep -Eq "^($tipos)(\([a-z0-9._/-]+\))?: .+"; then
    reprova "nao segue <tipo>(<escopo>): <descricao>."
    printf '  Tipos aceitos: %s\n' "$(printf '%s' "$tipos" | tr '|' ' ')" >&2
fi

# 2. Ate 72 caracteres, para nao truncar em listagem.
tamanho=$(printf '%s' "$assunto" | wc -m)
if [ "$tamanho" -gt 72 ]; then
    reprova "tem $tamanho caracteres; o limite e 72."
fi

# 3. Sem identificador de artefato: eles sao renumerados e a mensagem passa a
#    apontar para outra coisa. ADR-nnn e admitido, por ser documento estavel.
if printf '%s' "$assunto" | grep -Eq '(SC-[0-9]|FR-[0-9]|RNF[0-9]|RF[0-9]|M[0-9]+\.[0-9]|US[0-9]|\bT[0-9]{3}\b|\bR[0-9]{1,2}\b|§)'; then
    reprova "cita identificador de artefato (SC, FR, T, R, M, RNF, US, §)."
    printf '  Diga o comportamento; o identificador, se preciso, vai no corpo.\n' >&2
fi

descricao=${assunto#*: }
primeira=$(printf '%s' "$descricao" | awk '{print tolower($1)}')

# 4. Verbo em presente do indicativo, nunca infinitivo.
if printf '%s' "$primeira" | grep -Eq '(ar|er|ir)$'; then
    reprova "\"$primeira\" esta no infinitivo; use presente do indicativo."
    printf '  Ex.: "adiciona" em vez de "adicionar".\n' >&2
fi

# 5. Sem nome de comando do fluxo no lugar do que mudou.
if printf '%s' "$descricao" | grep -Eq '^(plan|clarify|tasks|analyze|specify|implement|refino|re-tasks)\b'; then
    reprova "nomeia o comando em vez do que mudou."
    printf '  Ex.: "deriva a guarda do config" em vez de "plan - guarda do config".\n' >&2
fi

# 6. Sem co-autoria nem marca de IA, no assunto ou na mensagem inteira.
alvo=$assunto
[ -n "$corpo_arquivo" ] && [ -f "$corpo_arquivo" ] && alvo=$(cat "$corpo_arquivo")
if printf '%s' "$alvo" | grep -Eiq 'co-authored-by|generated with|🤖|\bby (claude|copilot|chatgpt|gemini)\b'; then
    reprova "menciona co-autoria ou ferramenta de IA."
fi

if [ "$erros" -ne 0 ]; then
    printf '\nRecebido: %s\n' "$assunto" >&2
    printf 'Regras completas: .gitmessage\n' >&2
    exit 1
fi
exit 0
