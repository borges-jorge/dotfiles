#!/usr/bin/env bash
set -euo pipefail

uv init

rm -f main.py

uv add ignr commitizen pre-commit

uv venv

uv sync

source .venv/bin/activate

ignr -n python

cat << 'EOF' >> .gitignore
.idea/
EOF

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
# $1 = sha anterior, $2 = sha novo, $3 = 1 se branch checkout / 0 se file checkout
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

mkdir -p .github/workflows

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

          if [ "$BASE" = "qa" ] && [ "$HEAD" = "master" ]; then
            echo "::error::PRs para qa nao podem vir de master. Branch de origem: $HEAD"
            exit 1
          fi
EOF

printf '\nRepo configurado com sucesso.\n'
