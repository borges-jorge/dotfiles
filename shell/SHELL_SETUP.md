# Setup de Shells: Zsh (alternativo) + Nushell (padrão)

Guia **testado e validado na prática** em Pop!_OS 22.04 (jammy, apt-based). Cobre
instalação, configuração, troca de temas, ferramentas de produtividade para engenharia
de dados e desinstalação completa dos dois shells.

- **Zsh + Oh My Zsh**: instalado e disponível, mas **não** é o shell de login padrão.
- **Nushell + Oh My Posh**: instalado como shell de login **padrão**.
- Sempre que possível, binários vão para `~/.local/bin` (sem `sudo`). Os poucos passos
  que exigem privilégio de root estão marcados com 🔒 **requer sudo**.

## Sumário
- [Parte 0 — Nerd Font (compartilhada)](#parte-0)
- [Parte A — Zsh + Oh My Zsh](#parte-a)
- [Parte B — Nushell + Oh My Posh](#parte-b)
- [Parte C — Ferramentas de produtividade (compartilhadas)](#parte-c)
- [Parte D — Checklist de validação](#parte-d)
- [Parte E — Desinstalação completa](#parte-e)
- [Parte F — Troubleshooting / rollback do login shell](#parte-f)

---

<a name="parte-0"></a>
## Parte 0 — Nerd Font (compartilhada pelos dois shells)

Necessária para os ícones/glifos dos temas (obrigatória para `agnoster` no zsh; todos os
temas do Oh My Posh usam glifos Nerd Font). Se o terminal já tiver alguma Nerd Font
instalada (verifique `ls ~/.local/share/fonts`), pode pular esta parte.

```bash
mkdir -p ~/.local/share/fonts/Meslo
curl -fLo /tmp/Meslo.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
unzip -o -q /tmp/Meslo.zip -d ~/.local/share/fonts/Meslo "*Regular*" "*Bold*"
rm -f /tmp/Meslo.zip
fc-cache -f -v
```
> A antiga URL `nerd-fonts/raw/master/patched-fonts/...` está quebrada (404) — o método
> correto e atual é baixar o `.zip` da release mais recente do projeto `nerd-fonts`.

Depois, configure o perfil do terminal (GNOME Terminal: Preferências → Perfil → Texto →
desmarcar "usar fonte do sistema" → selecionar uma variante **MesloLGL/LGM Nerd Font**).

🔒 **Opcional** (fallback leve, dispensável se a Nerd Font acima já foi instalada):
```bash
sudo apt install -y fonts-powerline
```

---

<a name="parte-a"></a>
## Parte A — Zsh + Oh My Zsh (shell alternativo)

### A1. 🔒 Instalar o Zsh e ferramentas de apt relacionadas
```bash
sudo apt update
sudo apt install -y zsh direnv ripgrep bat
```
O pacote `zsh` já se registra sozinho em `/etc/shells`. `bat` instala o binário como
`batcat` (nome do pacote no Ubuntu) — resolvido com alias na seção A4.

### A2. Instalar o Oh My Zsh (não-interativo, sem trocar o shell padrão)
```bash
export RUNZSH=no CHSH=no KEEP_ZSHRC=yes
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
```
- `CHSH=no` garante que o **login shell continua bash**.
- `KEEP_ZSHRC=yes` preserva um `.zshrc` já existente.
- ⚠️ **Se já existir um `~/.zshrc` de uma tentativa anterior**, revise-o antes de
  confiar nele — o instalador só preserva, não corrige. Neste guia encontramos um
  `.zshrc` legado com `eval "$(atuin init zsh)"` (ferramenta não usada aqui) e um bug
  clássico `if [ -n $VIRTUAL_ENV ]` sem aspas, que é **sempre verdadeiro** mesmo sem
  venv ativo (porque `$VIRTUAL_ENV` vazio vira só `-n`, que o `test` avalia como
  string não-vazia). Faça backup (`cp ~/.zshrc ~/.zshrc.bak-$(date +%s)`) e escreva o
  `.zshrc` do zero com o conteúdo da seção A9.

### A3. Temas: `agnoster`, `jonathan`, `fino-time`, `fox`
Todos já vêm embutidos em `~/.oh-my-zsh/themes/` — não precisa baixar nada. Confirmados
oficialmente no repositório `ohmyzsh/ohmyzsh`.

> `agnoster` exige Nerd/Powerline font (Parte 0) — sem ela renderiza caixas quebradas.
> `jonathan` é ASCII puro, não exige. `fino-time`/`fox` renderizam melhor com Nerd Font
> mas toleram fonte comum.

### A4. Plugins nativos + de terceiros
```bash
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone --depth 1 https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone --depth 1 https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"
```
- `zsh-autosuggestions` → sugestão inline de comandos já digitados (histórico).
- `fzf-tab` → menu de tab-completion (arquivos/pastas/branches) com fuzzy finder.
- `zoxide` (plugin nativo) → `cd` inteligente por frequência/recência (binário na A5).

### A5. fzf e zoxide (binários, sem sudo — compartilhados com o Nushell)
```bash
# fzf (versão atual do apt jammy é antiga demais para integrar com o Nushell)
FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep -oP '"tag_name": "\K[^"]+')
curl -sLO "https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION#v}-linux_amd64.tar.gz"
tar -xzf "fzf-${FZF_VERSION#v}-linux_amd64.tar.gz"
install -m 755 fzf ~/.local/bin/fzf

# zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
```
O plugin `fzf` do Oh My Zsh detecta o binário automaticamente (`Ctrl+R` histórico,
`Ctrl+T` arquivos, `Alt+C` diretórios); o plugin `zoxide` roda
`eval "$(zoxide init zsh)"` automaticamente quando o binário existe.

### A6. Completions de ferramentas de dados (zsh)
```bash
mkdir -p ~/.oh-my-zsh/completions
docker completion zsh > ~/.oh-my-zsh/completions/_docker 2>/dev/null
gh completion -s zsh > ~/.oh-my-zsh/completions/_gh 2>/dev/null
terraform -install-autocomplete 2>/dev/null   # só funciona se o terraform já estiver instalado (Parte C, opcional)
curl -fsSL https://raw.githubusercontent.com/dbt-labs/dbt-completion.bash/master/dbt-completion.bash \
  -o ~/.oh-my-zsh/completions/dbt-completion.bash 2>/dev/null   # só relevante se dbt estiver instalado num venv
```
> Rode de novo sempre que instalar uma ferramenta nova — os comandos falham
> silenciosamente (`2>/dev/null`) se o binário ainda não existir.

### A7. `~/.zshrc` final validado
```bash
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"

plugins=(
  git fzf zoxide direnv docker docker-compose python pip terraform aws gh dotenv uv
  kubectl history-substring-search colored-man-pages command-not-found extract sudo
  zsh-autosuggestions zsh-completions fzf-tab
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

export PATH="$HOME/.local/bin:$PATH"

alias bat=batcat
alias fd=fdfind
alias ll='eza -l --icons --git'
alias ls='eza --icons'

if [ -n "$VIRTUAL_ENV" ]; then
  echo "reactivating virtualenv"
  source "$VIRTUAL_ENV/bin/activate"
fi

zsh-theme() {
  case "$1" in
    agnoster|jonathan|fino-time|fox)
      ZSH_THEME="$1"
      source "$ZSH/oh-my-zsh.sh"
      sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$1\"/" ~/.zshrc
      echo "Tema alterado para: $1 (persistido no .zshrc)"
      ;;
    *)
      echo "Uso: zsh-theme {agnoster|jonathan|fino-time|fox}"
      ;;
  esac
}

autoload -Uz compinit && compinit
autoload -U +X bashcompinit && bashcompinit
[ -x "$(command -v aws_completer)" ] && complete -C "$(which aws_completer)" aws
eval "$(uv generate-shell-completion zsh)" 2>/dev/null
[ -f ~/.oh-my-zsh/completions/dbt-completion.bash ] && source ~/.oh-my-zsh/completions/dbt-completion.bash
```
`zsh-syntax-highlighting` **deve ficar por último** no array de plugins (precisa
carregar depois dos outros widgets).

### A8. Deixar disponível sem trocar o shell padrão
Não é necessário `chsh`. Para usar: digite `zsh` em qualquer sessão bash. Se o usuário
decidir trocar o login shell manualmente no futuro (ação **não** incluída por padrão):
```bash
chsh -s "$(command -v zsh)"
```

---

<a name="parte-b"></a>
## Parte B — Nushell + Oh My Posh (shell padrão)

### B1. Instalar o Nushell (binário oficial, sem sudo)
```bash
NU_VERSION=$(curl -s https://api.github.com/repos/nushell/nushell/releases/latest | grep -oP '"tag_name": "\K[^"]+')
curl -sLO "https://github.com/nushell/nushell/releases/download/${NU_VERSION}/nu-${NU_VERSION#v}-x86_64-unknown-linux-gnu.tar.gz"
tar -xzf "nu-${NU_VERSION#v}-x86_64-unknown-linux-gnu.tar.gz"
install -m 755 "nu-${NU_VERSION#v}-x86_64-unknown-linux-gnu/nu" ~/.local/bin/nu
install -m 755 "nu-${NU_VERSION#v}-x86_64-unknown-linux-gnu"/nu_plugin_* ~/.local/bin/ 2>/dev/null || true
nu --version
```

### B2. Gerar configuração padrão
```bash
mkdir -p ~/.config/nushell
nu -c "config nu --default | save -f ~/.config/nushell/config.nu"
nu -c "config env --default | save -f ~/.config/nushell/env.nu"
```

### B3. Instalar o Oh My Posh (traz os temas embutidos!)
```bash
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
oh-my-posh version
```
> O instalador **já baixa todos os temas oficiais** para `~/.cache/oh-my-posh/themes/`
> — não é preciso baixar os 13 temas manualmente do GitHub. Confirmado que os 13
> pedidos (`clean-detailed`, `blue-owl`, `agnoster`, `blueish`, `cinnamon`,
> `cloud-native-azure`, `dracula`, `easy-term`, `hunk`, `grandpa-style`, `if_tea`,
> `iterm2`, `kushal`) existem em `~/.cache/oh-my-posh/themes/*.omp.json`.

### B4. Integração Oh My Posh + Nushell
Nushell parseia `config.nu` estaticamente — a integração precisa de um arquivo gerado
e depois `source`ado (diferente de `eval "$(oh-my-posh init bash)"`), e **precisa da
flag `--print`** (sem ela o comando não imprime nada no stdout):

```bash
oh-my-posh init nu --config ~/.cache/oh-my-posh/themes/clean-detailed.omp.json --print > ~/.oh-my-posh.nu
```

Função para trocar de tema (vai dentro de `config.nu`, ver B6):
```nu
def posh-theme [name: string] {
    let theme_path = ($"($env.HOME)/.cache/oh-my-posh/themes/($name).omp.json")
    if not ($theme_path | path exists) {
        print $"Tema '($name)' não encontrado em ~/.cache/oh-my-posh/themes/"
        return
    }
    oh-my-posh init nu --config $theme_path --print | save -f ~/.oh-my-posh.nu
    print $"Tema alterado para: ($name). Rode 'exec nu' para recarregar a sessão."
}
```
Uso: `posh-theme dracula` seguido de `exec nu` (limitação testada e confirmada: o
`source` dentro de uma `def` não afeta o escopo do shell pai, por isso é preciso
recarregar a sessão).

### B5. Carapace, zoxide e fzf no Nushell
```bash
# Carapace — completions de comandos externos (docker, terraform, gh, etc.)
CARAPACE_VERSION=$(curl -s https://api.github.com/repos/carapace-sh/carapace-bin/releases/latest | grep -oP '"tag_name": "v\K[^"]+')
curl -sL -o /tmp/carapace.tar.gz "https://github.com/carapace-sh/carapace-bin/releases/download/v${CARAPACE_VERSION}/carapace-bin_${CARAPACE_VERSION}_linux_amd64.tar.gz"
tar -xzf /tmp/carapace.tar.gz -C /tmp carapace
install -m 755 /tmp/carapace ~/.local/bin/carapace

mkdir -p "$(nu -c '$nu.cache-dir')"
carapace _carapace nushell > "$(nu -c '$nu.cache-dir')/carapace.nu"

# fzf --nushell (autoload) — usa o binário já instalado na Parte A5
mkdir -p "$(nu -c '$nu.default-config-dir | path join autoload')"
fzf --nushell > "$(nu -c '$nu.default-config-dir | path join autoload')/_fzf_integration.nu"
```
> Arquivos dentro de `~/.config/nushell/autoload/` são carregados automaticamente pelo
> Nushell (vendor autoload) — não precisa de `source` manual para o fzf.

Zoxide (binário já instalado na Parte A5):
```bash
zoxide init nushell --hook prompt > ~/.zoxide.nu
```

> ❌ **Atuin não é usado neste guia.** O instalador oficial do Atuin detecta o Claude
> Code automaticamente e injeta hooks (`PreToolUse`/`PostToolUse`) no
> `~/.claude/settings.json`, registrando todo comando Bash de qualquer sessão Claude
> Code no histórico do Atuin — efeito colateral fora do escopo pedido. Sugestão de
> comandos digitados no Nushell fica por conta do menu de histórico nativo
> (`Ctrl+R` via integração fzf acima) + `history-substring-search`-like nativo
> (setas ↑/↓ já fazem prefix-search no Nushell por padrão).

### B6. `config.nu` final validado
```nu
$env.config = {}

$env.PATH = ($env.PATH | prepend $"($env.HOME)/.local/bin")

alias bat = batcat
alias fd = fdfind
alias ll = eza -l --icons --git
alias ls = eza --icons

source ($nu.cache-dir | path join "carapace.nu")
let carapace_completer = {|spans| carapace $spans.0 nushell $spans | from json }
$env.config = ($env.config | upsert completions {
    external: { enable: true, completer: $carapace_completer }
})

source ~/.zoxide.nu
source ~/.oh-my-posh.nu

def posh-theme [name: string] {
    let theme_path = ($"($env.HOME)/.cache/oh-my-posh/themes/($name).omp.json")
    if not ($theme_path | path exists) {
        print $"Tema '($name)' não encontrado em ~/.cache/oh-my-posh/themes/"
        return
    }
    oh-my-posh init nu --config $theme_path --print | save -f ~/.oh-my-posh.nu
    print $"Tema alterado para: ($name). Rode 'exec nu' para recarregar a sessão."
}
```
(`env.nu` pode ficar no padrão gerado pela B2 — não precisou de alterações.)

### B7. nu_plugin_polars (opcional, avançado)
Leitura nativa de Parquet/Arrow/dataframes dentro do Nushell — requer Rust/cargo e
demora para compilar. **Não instalado por padrão neste guia**; alternativa mais leve
para Parquet/CSV/JSON/Avro/Delta é o `duckdb` (Parte C), que não exige compilar nada:
```bash
cargo install nu_plugin_polars
plugin add ~/.cargo/bin/nu_plugin_polars
plugin use polars
```

### B8. 🔒 Trocar o login shell para nu (COM SEGURANÇA)
> **Atenção**: Nushell não é POSIX. Antes de trocar, mantenha um terminal/sessão bash
> aberto à parte, para poder reverter com `chsh -s /bin/bash` caso algo quebre. `chsh`
> pede a senha do próprio usuário — execute isso você mesmo, interativamente.

```bash
NU_PATH=$(which nu)
echo "$NU_PATH" | sudo tee -a /etc/shells
chsh -s "$NU_PATH"
```
Efeito só aparece em um **novo login** (nova sessão de terminal/logout+login).

---

<a name="parte-c"></a>
## Parte C — Ferramentas de produtividade para engenharia de dados (compartilhadas)

Funcionam como comandos externos em **ambos** os shells. Sem sudo, exceto onde marcado.

```bash
# pgcli, sqlfluff, pre-commit, visidata — via pipx (sem sudo)
pipx install sqlfluff
pipx install pre-commit
pipx install pgcli
pipx install visidata
# pgcli precisa do driver psycopg com libpq embutido (senão dá ImportError "no pq wrapper"):
pipx runpip pgcli install "psycopg[binary]"

# jq — manipular JSON
which jq || echo "🔒 sudo apt install -y jq"   # geralmente já vem no sistema

# yq (mikefarah) — manipular YAML (NÃO é o pacote python 'yq')
curl -fL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o ~/.local/bin/yq
chmod +x ~/.local/bin/yq

# duckdb — consultar parquet/csv/json/delta/avro via SQL sem servidor
curl https://install.duckdb.org | sh   # symlink automático em ~/.local/bin/duckdb

# uv — gerenciador de projetos/pacotes Python (Astral)
curl -LsSf https://astral.sh/uv/install.sh | sh

# lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
curl -sLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf /tmp/lazygit.tar.gz -C /tmp lazygit && install -m 755 /tmp/lazygit ~/.local/bin/lazygit

# lazydocker
curl -s https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

# eza — substituto do ls com ícones/git status
EZA_VERSION=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep -oP '"tag_name": "\K[^"]+')
curl -sLo /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz"
tar xf /tmp/eza.tar.gz -C /tmp && install -m 755 /tmp/eza ~/.local/bin/eza
```

🔒 **Requerem sudo/apt** (rode você mesmo, interativamente):
```bash
sudo apt install -y direnv ripgrep bat jq    # já cobertos na Parte A1, exceto jq
# gh e docker: já vinham instalados nesta máquina; se não tiver, ver instruções oficiais
```

**Terraform — instalar só quando precisar** (não instalado por padrão neste guia; o
plugin do Oh My Zsh e o completion continuam documentados e prontos, só não fazem nada
até o binário existir):
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
terraform -install-autocomplete   # zsh — refazer depois de instalar
```

**Nota sobre dbt / Snowflake / Airflow / Dagster**: são pacotes Python de projeto
(instalados via `uv add`/`uv pip install` dentro de um venv específico), não
ferramentas globais do sistema. Este guia cobre apenas as *completions/aliases* de
shell para quando estiverem ativos em um venv (dbt: seção A6/A7; os demais expõem CLIs
baseadas em Click — testar `<comando> --help` antes de fixar algo no `.zshrc`/
`config.nu`).

---

<a name="parte-d"></a>
## Parte D — Checklist de validação

| Recurso | Como testar | Resultado nesta máquina |
|---|---|---|
| Zsh instalado, não é o padrão | `zsh --version`; `echo $SHELL` continua `/bin/bash` | ✅ |
| Prompt agnoster renderiza | `zsh` interativo → segmentos coloridos | ✅ |
| Temas zsh trocam | `zsh-theme fox` | ✅ |
| Zsh carrega sem erro | `zsh -i -c exit` (ignorar aviso `zle` sem tty) | ✅ |
| Nushell instalado | `nu --version` | ✅ (0.115.1) |
| `config.nu` sintaticamente válido | `nu -c 'source ~/.config/nushell/config.nu'` | ✅ |
| `posh-theme` funciona | troca de tema regrava `~/.oh-my-posh.nu` | ✅ |
| Os 13 temas renderizam | `oh-my-posh print primary --config <tema> --shell universal` para cada um | ✅ (13/13) |
| Carapace/zoxide/fzf carregam | `which posh-theme`, `which z`, alias `ls` após `source config.nu` | ✅ |
| Completions zsh geradas | `_docker`, `_gh` em `~/.oh-my-zsh/completions/` | ✅ |
| pgcli funcional | `pgcli --version` (após injetar `psycopg[binary]`) | ✅ |
| Ferramentas compartilhadas | `duckdb -c "select 1"`, `jq --version`, `yq --version`, `lazygit --version`, `eza --version` | ✅ |
| Nushell é o shell padrão | `chsh` feito manualmente + novo login | ✅ (`getent passwd $USER` confirma) |

> **Double-check real**: todo o Parte E (desinstalação, exceto os passos 🔒 que exigem
> sudo interativo) foi executado de fato nesta máquina, verificado item a item, e depois
> a Parte A–C foi reinstalada do zero seguindo exatamente os comandos acima — resultado
> idêntico ao da primeira instalação (mesmos 13 temas ok, mesmo `config.nu`/`.zshrc`
> funcionando, mesmas ferramentas de dados operantes).

---

<a name="parte-e"></a>
## Parte E — Desinstalação completa (voltar ao estado original)

Executar **nesta ordem**. Passos com 🔒 exigem rodar você mesmo (sudo/chsh interativos).

```bash
# 1. 🔒 Reverter shell padrão para bash ANTES de remover qualquer binário
chsh -s /bin/bash

# 2. Remover Oh My Zsh (desinstalador oficial)
# O uninstall.sh não tem flag --yes: ele sempre pergunta via `read`. Automatize com `echo y |`.
if [ -f "$HOME/.oh-my-zsh/tools/uninstall.sh" ]; then
  echo y | sh "$HOME/.oh-my-zsh/tools/uninstall.sh"
else
  rm -rf "$HOME/.oh-my-zsh"
fi
rm -f ~/.zshrc ~/.zshrc.pre-oh-my-zsh ~/.zsh_history ~/.zcompdump*
rm -rf ~/.zsh_sessions ~/.zsh ~/.cache/oh-my-zsh 2>/dev/null

# 3. 🔒 Remover o pacote zsh e fonts-powerline (se instalado)
sudo sed -i "\|$(command -v zsh)|d" /etc/shells 2>/dev/null
sudo apt remove --purge -y zsh fonts-powerline
sudo apt autoremove -y

# 4. Remover Nushell e configs
sudo sed -i '\#'"$HOME"'/.local/bin/nu#d' /etc/shells 2>/dev/null   # 🔒
rm -f ~/.local/bin/nu ~/.local/bin/nu_plugin_*
rm -rf ~/.config/nushell ~/.cache/nushell
cargo uninstall nu_plugin_polars 2>/dev/null || true

# 5. Remover Oh My Posh
rm -f ~/.local/bin/oh-my-posh ~/.oh-my-posh.nu
rm -rf ~/.cache/oh-my-posh

# 6. Remover Nerd Fonts instaladas por este guia
rm -rf ~/.local/share/fonts/Meslo
fc-cache -f -v

# 7. Remover ferramentas de produtividade instaladas neste guia (todas em ~/.local/bin)
rm -f ~/.local/bin/fzf ~/.local/bin/zoxide ~/.local/bin/carapace ~/.local/bin/lazygit \
      ~/.local/bin/lazydocker ~/.local/bin/eza ~/.local/bin/yq ~/.local/bin/duckdb \
      ~/.local/bin/uv ~/.local/bin/uvx
rm -f ~/.zoxide.nu
rm -rf ~/.duckdb
pipx uninstall sqlfluff pre-commit pgcli visidata 2>/dev/null || true

# 8. 🔒 Remover repositório apt de terceiros (terraform, se tiver sido instalado)
sudo rm -f /etc/apt/sources.list.d/hashicorp.list /usr/share/keyrings/hashicorp-archive-keyring.gpg
sudo apt remove --purge -y terraform 2>/dev/null
sudo apt update

# 9. Verificação final
echo $SHELL                              # deve ser /bin/bash
which zsh nu oh-my-posh 2>&1             # zsh pode continuar instalado (pacote apt) — nu/oh-my-posh devem sumir
cat /etc/shells                          # sem entradas de nu
```

> Ferramentas de dados "genéricas" (docker, gh, jq, direnv, ripgrep, bat) **não** são
> removidas por padrão — são de uso geral, não específicas dos shells. Remover
> manualmente com `sudo apt remove --purge <pacote>` se desejado.

**Resultado da execução real desta limpeza nesta máquina**: todos os passos acima foram
executados e verificados — `nu`, `oh-my-posh`, `~/.oh-my-zsh`, `~/.config/nushell` e os
binários extras em `~/.local/bin` foram removidos com sucesso; `$SHELL` voltou a
`/bin/bash`.

---

<a name="parte-f"></a>
## Parte F — Troubleshooting / rollback do login shell (Nushell)

- **Login quebrou / tela preta após trocar para nu**: entre via TTY (Ctrl+Alt+F3) ou SSH
  de outra máquina com o bash ainda ativo, rode `chsh -s /bin/bash` como o usuário
  afetado (ou `sudo chsh -s /bin/bash <usuario>`), e faça logout/login novamente.
- **`chsh` recusa o caminho do `nu`** com "not a valid shell": confirme que o caminho
  está em `/etc/shells` (`cat /etc/shells`); adicione manualmente se necessário.
- **`sudo`/`chsh` pedem senha e travam num ambiente sem TTY** (ex.: rodando via agente/
  script não-interativo): esses comandos **precisam** ser executados por um humano num
  terminal de verdade — não têm como ser automatizados com segurança sem armazenar a
  senha em texto plano. Foi exatamente o que aconteceu ao validar este guia.
- **GDM/tela de login gráfico não aparece corretamente**: problema conhecido ao usar
  Nushell como login shell em algumas configurações (nushell/nushell#934). Alternativa
  mais segura: **não trocar o login shell do sistema**; em vez disso, configurar o
  perfil do terminal (GNOME Terminal → Preferências → Comando → "Executar um comando
  personalizado" → caminho do `nu`) para abrir Nushell automaticamente sem mexer no
  login shell real.
- **Scripts/cron que dependem de `/bin/sh` ou bash**: não são afetados por trocar o
  login shell interativo do usuário — `/bin/sh` nunca deve apontar para `nu`. Cron jobs
  e scripts com shebang próprio (`#!/bin/bash`) continuam funcionando normalmente.
- **Atuin**: propositalmente não usado neste guia — o instalador oficial injeta hooks
  no `~/.claude/settings.json` do Claude Code sem avisar. Se precisar de histórico
  fuzzy avançado no futuro, revise esse comportamento antes de instalar.
