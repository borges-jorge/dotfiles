#!/usr/bin/env bash
set -euo pipefail

info() { printf '\033[0;34m[INFO]\033[0m  %s\n' "$*"; }
ok()   { printf '\033[0;32m[OK]\033[0m    %s\n' "$*"; }
skip() { printf '\033[0;33m[SKIP]\033[0m  %s\n' "$*"; }
warn() { printf '\033[0;31m[WARN]\033[0m  %s\n' "$*" >&2; }

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    warn "Nao e um repositorio git. Execute dentro de um repo."
    exit 1
fi

# --- uv deps ---
if [ -f pyproject.toml ]; then
    info "pyproject.toml encontrado — adicionando ignr, commitizen, pre-commit..."
    uv add ignr commitizen pre-commit
    ok "uv deps adicionados"
else
    skip "pyproject.toml nao encontrado — pulando uv add"
fi

# --- .gitignore: append apenas entradas ausentes ---
for entry in ".idea/" "__pycache__/" ".venv/" ".env"; do
    if [ -f .gitignore ] && grep -qF "$entry" .gitignore; then
        skip ".gitignore ja contem '$entry'"
    else
        printf '%s\n' "$entry" >> .gitignore
        ok ".gitignore: '$entry' adicionado"
    fi
done

# --- .pre-commit.yaml ---
if [ -f .pre-commit.yaml ]; then
    skip ".pre-commit.yaml ja existe — nao sobrescrito"
else
    cat << 'EOF' > .pre-commit.yaml
repos: # See more at https://pre-commit.com/
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
    -   id: check-yaml
-   repo: https://github.com/psf/black
    rev: 23.12.1
    hooks:
    -   id: black
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
    -   id: check-added-large-files
        args: ['--maxkb=500']
-   repo: https://github.com/commitizen-tools/commitizen
    rev: v3.13.0
    hooks:
      - id: commitizen
        stages: [commit-msg]
EOF
    ok ".pre-commit.yaml criado"
fi

# --- .githooks/ (sempre atualiza — hooks sao seguros de sobrescrever) ---
mkdir -p .githooks

cat << 'EOF' > .githooks/pre-commit
#!/usr/bin/env bash
protected='^(master|qa)$'
branch=$(git symbolic-ref --short HEAD 2>/dev/null)

if printf '%s' "$branch" | grep -Eq "$protected"; then
    printf 'pre-commit BLOCKED: commits diretos em %s nao sao permitidos.\n' "$branch" >&2
    printf 'Crie um feature branch:  git switch -c feature/<nome>\n' >&2
    exit 1
fi
EOF

cat << 'EOF' > .githooks/pre-push
#!/usr/bin/env bash
protected='^refs/heads/(master|qa)$'
blocked=0

while read -r _local_ref _local_sha remote_ref _remote_sha; do
  if printf '%s' "$remote_ref" | grep -Eq "$protected"; then
    printf 'pre-push BLOCKED: %s e PR-only (master/qa).\n' "$remote_ref" >&2
    printf 'Abra um PR:  gh pr create --base %s\n' \
      "$(printf '%s' "$remote_ref" | sed -E 's#refs/heads/##')" >&2
    blocked=1
  fi
done

exit "$blocked"
EOF

cat << 'EOF' > .githooks/post-checkout
#!/usr/bin/env bash
[ "$3" = "1" ] || exit 0

branch=$(git symbolic-ref --short HEAD 2>/dev/null)
protected='^(master|qa)$'
convention='^(feature|fix|chore|docs|refactor|test)/.+'

if printf '%s' "$branch" | grep -Eq "$protected"; then
    printf 'AVISO: voce esta em "%s", um branch protegido. Commits diretos sao bloqueados.\n' "$branch" >&2
elif ! printf '%s' "$branch" | grep -Eq "$convention"; then
    printf 'AVISO: branch "%s" nao segue a convencao <tipo>/<nome>.\n' "$branch" >&2
    printf 'Tipos aceitos: feature, fix, chore, docs, refactor, test\n' >&2
fi
EOF

chmod +x .githooks/pre-commit .githooks/pre-push .githooks/post-checkout
git config core.hooksPath .githooks
ok ".githooks/ configurado"

# --- .github/workflows/ ---
mkdir -p .github/workflows

if [ -f .github/workflows/protect-branches.yml ]; then
    skip "protect-branches.yml ja existe"
else
    cat << 'EOF' > .github/workflows/protect-branches.yml
name: protect-branches

on:
  push:
    branches: [master, qa]

jobs:
  revert-direct-push:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2
          token: ${{ secrets.GITHUB_TOKEN }}
      - name: revert if not PR merge
        run: |
          MSG=$(git log -1 --pretty=%s)
          if ! echo "$MSG" | grep -qE '^Merge pull request #'; then
            echo "::error::Push direto detectado em $(git branch --show-current). Use um PR."
            git config user.email "github-actions[bot]@users.noreply.github.com"
            git config user.name "github-actions[bot]"
            git revert HEAD --no-edit
            git push
            exit 1
          fi
EOF
    ok "protect-branches.yml criado"
fi

if [ -f .github/workflows/check-pr-direction.yml ]; then
    skip "check-pr-direction.yml ja existe"
else
    cat << 'EOF' > .github/workflows/check-pr-direction.yml
name: check-pr-direction

on:
  pull_request:
    branches: [master, qa]

jobs:
  enforce-direction:
    runs-on: ubuntu-latest
    steps:
      - name: enforce merge direction
        run: |
          BASE="${{ github.base_ref }}"
          HEAD="${{ github.head_ref }}"

          if [ "$BASE" = "master" ] && [ "$HEAD" != "qa" ]; then
            echo "::error::PRs para master so sao aceitos de qa. Branch de origem: $HEAD"
            exit 1
          fi
EOF
    ok "check-pr-direction.yml criado"
fi

printf '\nRetrofit concluido.\n'
