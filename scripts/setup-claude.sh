#!/usr/bin/env bash
# ---
# description: >
#   Aplica as configuracoes globais do Claude Code (settings.json, hook
#   block-ai-coauthor e skills personalizadas) em ~/.claude. Idempotente:
#   faz backup do settings.json existente antes de sobrescrever.
# uso: |
#   curl -fsSL https://raw.githubusercontent.com/borges-jorge/dotfiles/master/scripts/setup-claude.sh | bash
# o_que_faz:
#   - clona dotfiles (depth 1) num diretorio temporario
#   - backup de ~/.claude/settings.json -> settings.json.bak.<timestamp> (se existir)
#   - copia claude/settings.json -> ~/.claude/settings.json
#   - copia claude/hooks/block-ai-coauthor.sh -> ~/.claude/hooks (chmod +x)
#   - copia claude/skills/* -> ~/.claude/skills (pbi-dax-create, pbi-doc, pbi-modelo-review)
#   - remove o diretorio temporario
# ---
set -euo pipefail

REPO="https://github.com/borges-jorge/dotfiles"
CLAUDE_DIR="${HOME}/.claude"

info() { printf '\033[0;34m[INFO]\033[0m  %s\n' "$*"; }
ok()   { printf '\033[0;32m[OK]\033[0m    %s\n' "$*"; }

mkdir -p "${CLAUDE_DIR}/hooks" "${CLAUDE_DIR}/skills"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

info "clonando dotfiles..."
git clone --depth 1 "$REPO" "$tmp/df" >/dev/null 2>&1
ok "dotfiles clonado"

if [ -f "${CLAUDE_DIR}/settings.json" ]; then
    bak="${CLAUDE_DIR}/settings.json.bak.$(date +%Y%m%d%H%M%S)"
    cp "${CLAUDE_DIR}/settings.json" "$bak"
    ok "backup do settings.json existente -> ${bak##*/}"
fi

cp "$tmp/df/claude/settings.json" "${CLAUDE_DIR}/settings.json"
ok "settings.json aplicado"

cp "$tmp/df/claude/hooks/block-ai-coauthor.sh" "${CLAUDE_DIR}/hooks/"
chmod +x "${CLAUDE_DIR}/hooks/block-ai-coauthor.sh"
ok "hook block-ai-coauthor.sh aplicado"

cp -r "$tmp/df/claude/skills/." "${CLAUDE_DIR}/skills/"
ok "skills aplicadas (pbi-dax-create, pbi-doc, pbi-modelo-review)"

printf '\nClaude Code configurado em %s\n' "$CLAUDE_DIR"
printf 'Abra o Claude e rode /hooks (ou reinicie) para recarregar a config.\n'
