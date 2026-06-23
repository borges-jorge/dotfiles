#!/usr/bin/env bash
# Claude Code PreToolUse hook (Bash).
#
# Blocks the agent from creating commits or PRs that contain AI co-authorship
# or AI-generated attribution of any kind. BLOCKING (exit 2) and does NOT
# auto-fix — it returns the error so the message/body is corrected by hand.

set -uo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | python3 -c 'import json,sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))
except Exception:
    pass' 2>/dev/null || true)"

# Only inspect commands that create commits or PRs.
case "$cmd" in
  *"git commit"*|*"git merge"*|*"gh pr create"*|*"gh pr edit"*) : ;;
  *) exit 0 ;;
esac

PATTERNS=(
  'co-authored-by:.*(claude|anthropic|copilot|chatgpt|openai|gpt|gemini|cursor|codeium|noreply@anthropic)'
  'generated[[:space:]]+(with|by)[[:space:]].*(claude|copilot|gpt|gemini|cursor|[[:space:]]ai)'
  '🤖'
  'claude[[:space:]]+code'
)

for pat in "${PATTERNS[@]}"; do
  if printf '%s' "$cmd" | grep -qiE "$pat"; then
    echo "BLOQUEADO: este comando inclui menção de co-autoria/geração por IA (proibido neste projeto). Remova qualquer 'Co-Authored-By', 'Generated with...', emoji 🤖 ou referência a IA da mensagem de commit / corpo do PR e refaça." >&2
    exit 2
  fi
done

exit 0
