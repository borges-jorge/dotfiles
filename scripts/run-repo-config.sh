#!/usr/bin/env bash
# ---
# description: >
#   Script de configuração de repositório Python com uv, hooks de qualidade
#   de código e branch protection. Deve ser executado dentro do repo já
#   criado e clonado via `gh repo create`. Requer `gh` autenticado: o
#   script abre e mergeia os PRs sozinho, sem passo manual no final —
#   termina com checkout em qa, repo pronto pra uso.
# uso: |
#   curl -fsSL https://raw.githubusercontent.com/borges-jorge/dotfiles/master/scripts/run-repo-config.sh | bash
# o_que_faz:
#   - uv init: Cria estrutura do projeto
#   - uv add: Adiciona ignr, commitizen, pre-commit
#   - ignr -n python: Gera .gitignore completo para Python
#   - .pre-commit.yaml: check-yaml, black, large-files, commitizen
#   - .githooks/pre-commit: Bloqueia commits diretos em master/qa
#   - .githooks/pre-push: Bloqueia pushes diretos em master/qa
#   - .githooks/post-checkout: Avisa ao entrar em branch protegido ou com nome fora da convenção
#   - bootstrap master/qa: commita o setup acima, envia master e qa ao
#     remoto, e só então ativa core.hooksPath
#   - protect-branches.yml + check-pr-direction.yml: adicionados numa
#     branch chore/, com PR aberto e mergeado automaticamente (--merge)
#     para qa, e depois replicado de qa para master com outro PR
# camadas_de_protecao: |
#   checkout local  ->  .githooks/post-checkout      (aviso: branch protegido ou nome inválido)
#   commit local    ->  .githooks/pre-commit          (bloqueia na origem)
#   push local      ->  .githooks/pre-push            (bloqueia antes de enviar)
#   push remoto     ->  protect-branches.yml          (reverte se bypass local)
#   PR direction    ->  check-pr-direction.yml        (bloqueia PR fora do fluxo feature->qa->master)
#
#   Os hooks locais podem ser burlados com --no-verify. O GitHub Actions é a
#   camada que não tem bypass local.
#
# ordem_de_bootstrap: |
#   1. master e qa recebem o commit inicial (uv init, .pre-commit.yaml,
#      .githooks) e são enviados ao remoto ANTES de existir qualquer
#      arquivo em .github/workflows e ANTES de core.hooksPath ser
#      configurado. Isso é garantido, não probabilístico: o GitHub só
#      avalia um workflow de `push` se o arquivo .yml existir na ref que
#      está sendo enviada — se protect-branches.yml não está no commit,
#      não há o que avaliar, ponto.
#   2. Só depois desse push os workflows são escritos, e core.hooksPath é
#      ativado — a partir daqui master/qa não aceitam mais commit/push
#      direto, nem local (hook) nem remoto (Action).
#   3. Os workflows entram numa branch chore/branch-protection-workflows,
#      via PR aberto e mergeado com `gh pr merge --merge` (nunca
#      squash/rebase: "Merge pull request #" é o único formato de
#      mensagem que o protect-branches.yml aceita sem reverter).
#   4. O mesmo conteúdo é replicado de qa para master com um segundo PR,
#      também mergeado com --merge. Os refs locais de qa e master são
#      atualizados via fast-forward após cada merge.
#   5. Termina com checkout em qa — repo pronto pra uso, sem passo manual.
# ---
set -euo pipefail

uv init

rm -f main.py

uv add ignr commitizen pre-commit

uv venv

uv sync

source .venv/bin/activate

# uv init já cria um .gitignore minimo; remove antes pra ignr nao cair no
# prompt interativo de overwrite (que quebra com EOF quando rodado via
# curl | bash, sem stdin).
rm -f .gitignore
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

# Bootstrap de master e qa: commita e envia ANTES de existir qualquer
# workflow em .github e ANTES de ativar core.hooksPath. Garantido sem
# disparo do protect-branches.yml, porque o arquivo simplesmente nao
# existe na ref enviada neste momento.
git add -A
git commit -m "chore: bootstrap project setup"
git push -u origin master

git checkout -b qa
git push -u origin qa

# A partir daqui master e qa ja existem local e remoto. So agora ativa a
# proteção local — commits/pushes diretos passam a ser bloqueados.
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

# qa ja esta protegida (core.hooksPath ativo): os workflows precisam entrar
# por uma branch chore/ + PR, igual qualquer outra mudança. O merge usa
# --merge (nunca squash/rebase) porque "Merge pull request #" e o unico
# formato de mensagem que o protect-branches.yml aceita sem reverter.
git checkout -b chore/branch-protection-workflows
git add .github
git commit -m "ci: add branch protection workflows"
git push -u origin chore/branch-protection-workflows

gh pr create --base qa --head chore/branch-protection-workflows --fill
gh pr merge chore/branch-protection-workflows --merge --delete-branch

git checkout qa
git pull --ff-only origin qa
git branch -D chore/branch-protection-workflows 2>/dev/null || true

# Propaga o mesmo conteudo (agora com os workflows) de qa para master.
gh pr create --base master --head qa --fill
gh pr merge qa --merge

git fetch origin master:master

printf '\nRepo configurado com sucesso: master e qa criados, workflows ativos, sem passos manuais pendentes.\n'
