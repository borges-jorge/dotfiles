# Referência: disciplina SDD do itallus

Cópia dos artefatos de processo do itallus (`borgesj-itl/itallus`, branch `qa`, commit `0cea676`),
usada como referência para reformular a disciplina e empacotá-la (issue #10). Ao executar o plano, o
que é específico do itallus sai ou vira parâmetro do projeto.

| Arquivo | O que é |
|---|---|
| `AGENTS.md`, `CLAUDE.md` | regras do projeto e do processo; o `CLAUDE.md` importa o `AGENTS.md` |
| `docs/constitution/principios.md` | princípios de qualidade da aplicação, padrão da disciplina; alimentam a constituição |
| `docs/constitution/constitution.md` | constituição v2.2.0: princípios, governança e Sync Impact Report |
| `docs/requisitos.md` | exemplo de entrada da decomposição: os PRDs e a visão do itallus saíram dele |
| `docs/visao-geral.md` | exemplo de visão gerada pela decomposição |
| `docs/prds/E0-fundacao/00-fundacao-auth-shell.md` | exemplo do modelo de PRD: 8 seções e Changelog |
| `docs/roteiro-sdd.md` | playbook e racional da disciplina, incluindo como escrever e emendar a constituição (§6) |
| `padroes-qualidade.md` | referência de qualidade por pilar, mantida fora do repositório do itallus |
| `.gitmessage`, `.githooks/` | modelo de commit e hooks locais: guarda de branch e validação do assunto |
| `scripts/check_subject.sh`, `scripts/check_body.sh` | validadores de assunto e de corpo de commit, PR, issue e release |
| `scripts/next_version.sh` | versão automática a partir dos tipos de commit |
| `.github/PULL_REQUEST_TEMPLATE.md`, `.github/ISSUE_TEMPLATE/`, `.github/RELEASE_TEMPLATE/` | modelos de PR, de issue (bug, chore, tech-debt/deferred com Trigger) e de release |
| `.github/workflows/check-*.yml`, `.github/workflows/protect-branches.yml` | cobrança dos modelos e proteção de `qa` e `master` |
| `.github/workflows/ci.yml` | CI do itallus: o job `release` é da disciplina; os demais são do projeto |
| `.pre-commit.yaml` | configuração de pre-commit, inativa no itallus |
