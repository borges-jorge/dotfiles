# dotfiles

Configurações pessoais de desenvolvimento. Scripts e configs organizados por categoria.

## Estrutura

| Pasta | Conteúdo |
|-------|---------|
| `scripts/` | Scripts executáveis de setup |
| `git/` | Configurações globais do git |
| `shell/` | Aliases, funções e variáveis de ambiente |
| `config/` | Configurações de ferramentas diversas |

## Uso rápido

### Configurar novo repositório Python

```bash
gh repo create meu-projeto --private --clone
cd meu-projeto
curl -fsSL https://raw.githubusercontent.com/<user>/dotfiles/main/scripts/run-repo-config.sh | bash
```
