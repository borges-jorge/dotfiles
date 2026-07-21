#!/usr/bin/env bash
# ---
# description: >
#   Retrofit idempotente: aplica a um repositório Python já existente o MESMO
#   setup do run-repo-config.sh (uv, .gitignore, pre-commit, .githooks,
#   branches master/qa e workflows de branch protection). A diferença é que
#   só cria o que ainda não existe — nada presente é sobrescrito — e ao final
#   lista tudo que foi pulado por já existir.
# uso: |
#   cd meu-repo-existente
#   curl -fsSL https://raw.githubusercontent.com/borges-jorge/dotfiles/master/scripts/retrofit-repo.sh | bash
# o_que_faz:
#   - uv init: Cria estrutura do projeto (só se não houver pyproject.toml)
#   - uv add: Adiciona ignr, commitizen, pre-commit (só os que faltarem)
#   - uv venv + uv sync: Cria o ambiente (só se .venv não existir)
#   - .gitignore: Gera via ignr -n python se ausente; garante .idea/ .venv
#     __pycache__/ .env (adiciona só as entradas que faltarem)
#   - .pre-commit.yaml: Criado se não existir
#   - .githooks/pre-commit, pre-push, post-checkout: cada um criado se faltar
#   - commit + push master: versiona o que foi adicionado (antes de ativar
#     core.hooksPath, para os hooks não bloquearem o próprio bootstrap)
#   - branch qa: criada e enviada se ainda não existir
#   - core.hooksPath: ativado se ainda não apontar para .githooks
#   - protect-branches.yml + check-pr-direction.yml: criados se faltarem e,
#     quando novos, adicionados via PR (chore/branch-protection-workflows ->
#     qa -> master) com merge automático via gh
#   - Ao final: imprime tudo que foi pulado (já existia)
# camadas_de_protecao: |
#   checkout local  ->  .githooks/post-checkout      (aviso: branch protegido ou nome inválido)
#   commit local    ->  .githooks/pre-commit          (bloqueia na origem)
#   push local      ->  .githooks/pre-push            (bloqueia antes de enviar)
#   push remoto     ->  protect-branches.yml          (reverte se bypass local)
#   PR direction    ->  check-pr-direction.yml        (bloqueia PR fora do fluxo feature->qa->master)
#
#   Os hooks locais podem ser burlados com --no-verify. O GitHub Actions é a
#   camada que não tem bypass local.
# ---
set -euo pipefail

info() { printf '\033[0;34m[INFO]\033[0m  %s\n' "$*"; }
ok()   { printf '\033[0;32m[OK]\033[0m    %s\n' "$*"; }
skip() { printf '\033[0;33m[SKIP]\033[0m  %s\n' "$*"; }
warn() { printf '\033[0;31m[WARN]\033[0m  %s\n' "$*" >&2; }

# Acumula o que foi pulado para o resumo final.
SKIPPED=()
record_skip() { SKIPPED+=("$1"); skip "$1"; }

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    warn "Nao e um repositorio git. Execute dentro de um repo."
    exit 1
fi

tem_remoto() { git remote get-url origin > /dev/null 2>&1; }

branch_base=$(git symbolic-ref --short HEAD 2>/dev/null || echo "master")
if [ "$branch_base" != "master" ]; then
    warn "Branch atual e '$branch_base' (esperado 'master'). O esquema assume master/qa."
fi

# --- 1. Projeto uv --------------------------------------------------------
if [ -f pyproject.toml ]; then
    record_skip "pyproject.toml (projeto uv ja iniciado)"
else
    info "uv init..."
    uv init
    rm -f main.py
    ok "uv init"
fi

# --- 2. Dependencias (so as que faltarem) --------------------------------
for dep in ignr commitizen pre-commit; do
    if grep -qi "$dep" pyproject.toml 2>/dev/null; then
        record_skip "dependencia $dep"
    else
        info "uv add $dep..."
        uv add "$dep"
        ok "dependencia $dep adicionada"
    fi
done

# --- 3. Ambiente virtual --------------------------------------------------
if [ -d .venv ]; then
    record_skip ".venv (ambiente virtual)"
else
    info "uv venv..."
    uv venv
    ok ".venv criado"
fi
uv sync

# --- 4. .gitignore --------------------------------------------------------
if [ -f .gitignore ]; then
    record_skip ".gitignore (mantido; nao regenerado)"
else
    info "gerando .gitignore (ignr -n python)..."
    uv run ignr -n python
    ok ".gitignore criado"
fi
# Garante as entradas essenciais (impede que git add -A versione o .venv).
for entry in ".idea/" ".venv" "__pycache__/" ".env"; do
    if grep -qxF "$entry" .gitignore 2>/dev/null; then
        record_skip ".gitignore entrada '$entry'"
    else
        printf '%s\n' "$entry" >> .gitignore
        ok ".gitignore: '$entry' adicionado"
    fi
done

# --- 5. .pre-commit.yaml --------------------------------------------------
if [ -f .pre-commit.yaml ]; then
    record_skip ".pre-commit.yaml"
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

# --- 6. .githooks/ (cada hook so se faltar) ------------------------------
mkdir -p .githooks

if [ -f .githooks/pre-commit ]; then
    record_skip ".githooks/pre-commit"
else
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
    ok ".githooks/pre-commit criado"
fi

if [ -f .githooks/pre-push ]; then
    record_skip ".githooks/pre-push"
else
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
    ok ".githooks/pre-push criado"
fi

if [ -f .githooks/post-checkout ]; then
    record_skip ".githooks/post-checkout"
else
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
    ok ".githooks/post-checkout criado"
fi

chmod +x .githooks/pre-commit .githooks/pre-push .githooks/post-checkout 2>/dev/null || true

# --- 7. Commit + push do que foi adicionado (antes do hooksPath) ---------
git add -A
if git diff --cached --quiet; then
    record_skip "commit (nada novo para versionar)"
else
    git commit -m "chore: retrofit uv + branch protection config"
    ok "mudancas commitadas"
    if tem_remoto; then
        git push -u origin "$branch_base" \
            || warn "push em $branch_base falhou (protecao ja ativa?); envie via PR."
    fi
fi

# --- 8. Branch qa ---------------------------------------------------------
if git show-ref --verify --quiet refs/heads/qa \
   || ( tem_remoto && git ls-remote --exit-code --heads origin qa > /dev/null 2>&1 ); then
    record_skip "branch qa"
else
    git checkout -b qa
    tem_remoto && git push -u origin qa || true
    git checkout "$branch_base"
    ok "branch qa criada"
fi

# --- 9. core.hooksPath ----------------------------------------------------
if [ "$(git config --local core.hooksPath 2>/dev/null || true)" = ".githooks" ]; then
    record_skip "core.hooksPath (ja aponta para .githooks)"
else
    git config core.hooksPath .githooks
    ok "core.hooksPath ativado"
fi

# --- 10. Workflows (criados se faltarem; landados via PR se novos) --------
mkdir -p .github/workflows
wf_novo=0

if [ -f .github/workflows/protect-branches.yml ]; then
    record_skip ".github/workflows/protect-branches.yml"
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
    wf_novo=1
    ok "protect-branches.yml criado"
fi

if [ -f .github/workflows/check-pr-direction.yml ]; then
    record_skip ".github/workflows/check-pr-direction.yml"
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

          if [ "$BASE" = "qa" ] && [ "$HEAD" = "master" ]; then
            echo "::error::PRs para qa nao podem vir de master. Branch de origem: $HEAD"
            exit 1
          fi
EOF
    wf_novo=1
    ok "check-pr-direction.yml criado"
fi

# --- 10b. Issue template (tech-debt) -------------------------------------
mkdir -p .github/ISSUE_TEMPLATE
if [ -f .github/ISSUE_TEMPLATE/tech-debt.md ]; then
    record_skip ".github/ISSUE_TEMPLATE/tech-debt.md"
else
    cat << 'EOF' > .github/ISSUE_TEMPLATE/tech-debt.md
---
name: Tech-debt / deferred item
about: A defect or improvement found and postponed to a later feature or pass
labels: [tech-debt, deferred]
---

## Context
Where it comes from (feature/area) and how it surfaced.

## Problem
What happens today — with evidence (measurement, screenshot, log).

## Expected
What should happen.

## Proposal (optional)
Suggested approach, if any.

## References (optional)
Links: spec/ADR/commit/screenshot.
EOF
    wf_novo=1
    ok "tech-debt.md (ISSUE_TEMPLATE) criado"
fi

if [ "$wf_novo" = "1" ] && tem_remoto; then
    # qa esta protegida: os workflows entram por uma branch chore/ + PR.
    # Merge com --merge (nunca squash/rebase): "Merge pull request #" e o
    # formato que o protect-branches.yml aceita sem reverter.
    info "adicionando workflows via PR (chore -> qa -> master)..."
    git checkout -b chore/branch-protection-workflows
    git add .github
    git commit -m "ci: add branch protection workflows"
    git push -u origin chore/branch-protection-workflows
    gh pr create --base qa --head chore/branch-protection-workflows --fill \
        || warn "gh pr create (->qa) falhou (PR ja existe?)"
    gh pr merge chore/branch-protection-workflows --merge --delete-branch \
        || warn "gh pr merge (chore->qa) falhou"
    git checkout qa
    git pull --ff-only origin qa
    git branch -D chore/branch-protection-workflows 2>/dev/null || true
    gh pr create --base master --head qa --fill \
        || warn "gh pr create (->master) falhou (PR ja existe?)"
    gh pr merge qa --merge || warn "gh pr merge (qa->master) falhou"
    git fetch origin master:master
    git checkout "$branch_base" 2>/dev/null || true
    ok "workflows adicionados via PR"
elif [ "$wf_novo" = "0" ]; then
    record_skip "fluxo de PR dos workflows (workflows ja presentes)"
fi

# --- Resumo ---------------------------------------------------------------
printf '\nRetrofit concluido.\n'
if [ "${#SKIPPED[@]}" -eq 0 ]; then
    printf 'Nada foi pulado — tudo foi criado do zero.\n'
else
    printf '\nNao criado (ja existia):\n'
    for item in "${SKIPPED[@]}"; do
        printf '  - %s\n' "$item"
    done
fi
