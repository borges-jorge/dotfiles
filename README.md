# dotfiles

Configurações pessoais de desenvolvimento. Scripts e configs organizados por categoria.

## Estrutura

| Pasta | Conteúdo |
|-------|---------|
| `scripts/` | Scripts executáveis de setup |
| `git/` | Configurações globais do git |
| `shell/` | Aliases, funções e variáveis de ambiente |
| `config/` | Configurações de ferramentas diversas |
| `claude/` | Configurações globais do Claude Code (settings, hooks, skills) |

## Uso rápido

### Configurar novo repositório Python

```bash
gh repo create meu-projeto --private --clone
cd meu-projeto
curl -fsSL https://raw.githubusercontent.com/<user>/dotfiles/main/scripts/run-repo-config.sh | bash
```

### Configurar Claude Code numa nova máquina

```bash
curl -fsSL https://raw.githubusercontent.com/borges-jorge/dotfiles/master/scripts/setup-claude.sh | bash
```

Aplica `claude/settings.json`, o hook `block-ai-coauthor` e as skills em `~/.claude`.
