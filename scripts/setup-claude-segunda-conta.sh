#!/usr/bin/env bash
# ---
# description: >
#   Prepara uma segunda pasta de configuracao do Claude Code, para usar outra conta
#   em paralelo com a principal. So o login fica separado: settings, hooks, skills,
#   agentes, plugins, CLAUDE.md de usuario e a memoria dos projetos apontam (link
#   simbolico) para ~/.claude. Idempotente: nao sobrescreve arquivo real existente.
# uso: |
#   scripts/setup-claude-segunda-conta.sh [nome]            # cria ~/.claude-<nome> (padrao: conta2)
#   scripts/setup-claude-segunda-conta.sh [nome] --worktree <caminho-da-worktree> <caminho-do-repo-principal>
#     # liga a memoria do projeto da worktree a memoria do repositorio principal,
#     # nas duas pastas de configuracao, para as duas sessoes lerem a mesma memoria
#   depois: CLAUDE_CONFIG_DIR=~/.claude-<nome> claude    (ou o alias claude2 de shell/aliases)
#   e /login com a outra conta, dentro dessa sessao
# o_que_faz:
#   - cria ~/.claude-<nome> e ~/.claude-<nome>/projects
#   - liga settings.json, hooks, skills, agents, plugins e CLAUDE.md a ~/.claude
#   - liga a pasta memory de cada projeto existente em ~/.claude/projects
#   - nao copia nem liga .credentials.json nem .claude.json (login e estado ficam separados)
# limites:
#   - login de Claude Console sem API key nao se separa por pasta (fica fora dela)
#   - ANTHROPIC_API_KEY exportada no shell vale para as duas sessoes
#   - a documentacao nao diz o que acontece com duas sessoes gravando a mesma memoria
#     ao mesmo tempo; cada sessao costuma gravar arquivos diferentes
# fonte: https://code.claude.com/docs/en/authentication.md ("Log in with multiple accounts"),
#   https://code.claude.com/docs/en/env-vars.md (CLAUDE_CONFIG_DIR),
#   https://code.claude.com/docs/en/claude-directory.md
# ---
set -euo pipefail

MAIN="${HOME}/.claude"
NAME="${1:-conta2}"
[ "$#" -gt 0 ] && shift
ALT="${HOME}/.claude-${NAME}"

info() { printf '\033[0;34m[INFO]\033[0m  %s\n' "$*"; }
ok()   { printf '\033[0;32m[OK]\033[0m    %s\n' "$*"; }
warn() { printf '\033[0;33m[WARN]\033[0m  %s\n' "$*"; }

# Path of a project folder under projects/, as Claude Code names it (every / and . become -).
project_key() { printf '%s' "$1" | sed 's#[/.]#-#g'; }

# Link target -> source, keeping an existing real file untouched.
link() {
    local source="$1" target="$2"
    [ -e "$source" ] || { warn "nao existe, pulado: ${source}"; return 0; }
    if [ -L "$target" ]; then
        ln -sfn "$source" "$target"
    elif [ -e "$target" ]; then
        warn "ja existe e nao e link, mantido: ${target}"
        return 0
    else
        mkdir -p "$(dirname "$target")"
        ln -s "$source" "$target"
    fi
    ok "${target} -> ${source}"
}

mkdir -p "${ALT}/projects"
info "pasta da segunda conta: ${ALT}"

for item in settings.json hooks skills agents plugins CLAUDE.md; do
    link "${MAIN}/${item}" "${ALT}/${item}"
done

for memory in "${MAIN}"/projects/*/memory; do
    [ -d "$memory" ] || continue
    key="$(basename "$(dirname "$memory")")"
    link "$memory" "${ALT}/projects/${key}/memory"
done

if [ "${1:-}" = "--worktree" ]; then
    worktree="$(realpath "${2:?caminho da worktree}")"
    repo="$(realpath "${3:?caminho do repositorio principal}")"
    shared="${MAIN}/projects/$(project_key "$repo")/memory"
    [ -d "$shared" ] || { warn "memoria do repositorio principal nao encontrada: ${shared}"; exit 1; }
    for base in "$MAIN" "$ALT"; do
        link "$shared" "${base}/projects/$(project_key "$worktree")/memory"
    done
fi

info "pronto. Abra com: CLAUDE_CONFIG_DIR=${ALT} claude  e rode /login com a outra conta."
