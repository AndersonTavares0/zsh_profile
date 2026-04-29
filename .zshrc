# ==============================================================================
# ARQUIVO DE CONFIGURAÇÃO DO ZSH (~/.zshrc)
# Versão: 2.3 | Otimizado para Fedora + Oh My Zsh + Powerlevel10k
# ==============================================================================

# ==============================================================================
# POWERLEVEL10K — INSTANT PROMPT (deve ser a primeira coisa no arquivo)
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
# BOOT TIMER — Captura silenciosa do tempo de início
# ==============================================================================
zmodload zsh/datetime
typeset -g _zshrc_start_s=$EPOCHREALTIME

# ==============================================================================
# DEDUPLICAÇÃO DE CAMINHOS
# ==============================================================================
typeset -U path PATH fpath FPATH

# ==============================================================================
# PATH — Adiciona diretórios personalizados (antes do cache de plugins)
# ==============================================================================
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.spicetify:$PATH"

# ==============================================================================
# OH MY ZSH — CONFIGURAÇÃO BASE
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

# ==============================================================================
# OPÇÕES DO ZSH — COMPORTAMENTO E HISTÓRICO
# ==============================================================================
setopt AUTO_CD EXTENDED_GLOB
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_REDUCE_BLANKS SHARE_HISTORY

HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

# ==============================================================================
# FILTRO DE SEGURANÇA DO HISTÓRICO
# ==============================================================================
zshaddhistory() {
  local upper="${1:u}"
  [[ "$upper" =~ (TOKEN|SECRET|PASSWORD|PASSWD|API_KEY|PRIVATE_KEY|CREDENTIAL|ACCESS_KEY)[[:space:]]*= ]] && return 1
  return 0
}

# ==============================================================================
# SISTEMA DE CACHE DE PLUGINS
# ==============================================================================
_PLUGIN_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh_plugins_init.zsh"
_TOOLS_WATCHED=(zoxide fzf)

_zsh_gen_fingerprint() {
  local fp="" tool path_val
  for tool in "${_TOOLS_WATCHED[@]}"; do
    path_val=$(command -v "$tool" 2>/dev/null || echo "missing")
    fp+="${tool}=${path_val};"
  done
  print -n "$fp" | cksum | cut -d' ' -f1
}

_zsh_build_plugin_cache() {
  local tmp=$(mktemp) || return 1
  trap "rm -f '$tmp'" INT TERM
  printf '# zsh_plugin_cache fingerprint: %s\n' "$(_zsh_gen_fingerprint)" > "$tmp"

  # zoxide
  if command -v zoxide &>/dev/null; then
    printf '\n# --- zoxide ---\n' >> "$tmp"
    zoxide init zsh >> "$tmp" 2>/dev/null
  fi

  # fzf
  if command -v fzf &>/dev/null; then
    printf '\n# --- fzf ---\n' >> "$tmp"
    [[ -f /usr/share/fzf/shell/key-bindings.zsh ]] && \
      printf 'source /usr/share/fzf/shell/key-bindings.zsh\n' >> "$tmp"
    [[ -f /usr/share/zsh/site-functions/_fzf ]] && \
      printf 'source /usr/share/zsh/site-functions/_fzf\n' >> "$tmp"
  fi

  mv "$tmp" "$_PLUGIN_CACHE"
}

# Valida e reconstrói cache se necessário
if [[ -f "$_PLUGIN_CACHE" ]]; then
  _zsh_current_fp=$(_zsh_gen_fingerprint)
  _zsh_cached_fp=$(sed -n '1s/# zsh_plugin_cache fingerprint: //p' "$_PLUGIN_CACHE")
  [[ "$_zsh_current_fp" != "$_zsh_cached_fp" ]] && _zsh_build_plugin_cache
else
  _zsh_build_plugin_cache
fi

[[ -f "$_PLUGIN_CACHE" ]] && source "$_PLUGIN_CACHE"
if [[ -f "$_PLUGIN_CACHE" && ( ! -f "${_PLUGIN_CACHE}.zwc" || "$_PLUGIN_CACHE" -nt "${_PLUGIN_CACHE}.zwc" ) ]]; then
  zcompile "$_PLUGIN_CACHE" &>/dev/null &!
fi
unset _PLUGIN_CACHE _TOOLS_WATCHED _zsh_current_fp _zsh_cached_fp

# ==============================================================================
# OH MY ZSH — PLUGINS E CARREGAMENTO
# ==============================================================================
plugins=(git history)

# Se zsh-defer estiver disponível, plugins pesados serão carregados de forma diferida
if [[ ! -f "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-defer/zsh-defer.plugin.zsh" ]]; then
  [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions" ]] && \
    plugins+=(zsh-autosuggestions)
  [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting" ]] && \
    plugins+=(zsh-syntax-highlighting)
fi

source "$ZSH/oh-my-zsh.sh"

# ==============================================================================
# LAZY LOADING COM ZSH-DEFER (opcional)
# ==============================================================================
if [[ -f "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-defer/zsh-defer.plugin.zsh" ]]; then
  source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-defer/zsh-defer.plugin.zsh"
  
  if [[ -n "${plugins[(Ie)zsh-autosuggestions]}" ]]; then
    zsh-defer source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi
  
  if [[ -n "${plugins[(Ie)zsh-syntax-highlighting]}" ]]; then
    zsh-defer source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi
fi

# ==============================================================================
# ALIASES — EZA (substituto do 'ls')
# ==============================================================================
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --group-directories-first --git'
  alias la='eza -lah --icons --group-directories-first --git'
  alias l='eza -1 --icons'
  alias lt='eza --tree --icons --level=2'
fi

# ==============================================================================
# ALIASES — GREP COLORIDO
# ==============================================================================
if command -v grep &>/dev/null; then
  alias grep='grep --color=auto'
  alias fgrep='grep -F --color=auto'
  alias egrep='grep -E --color=auto'
fi

# ==============================================================================
# ALIASES — NAVEGAÇÃO
# ==============================================================================
alias home='cd ~'
alias docs='cd ~/Documents'
alias dtop='cd ~/Desktop'
alias reload='source ~/.zshrc && printf "✅ .zshrc recarregado\n"'

# ==============================================================================
# FUNÇÕES — NAVEGAÇÃO E ARQUIVOS
# ==============================================================================
up() {
  local n=${1:-1}
  local path=""
  for ((i=0; i<n; i++)); do path+="../"; done
  cd "$path" || return 1
}

mkcd() {
  [[ -z "$1" ]] && { printf '❌ Uso: mkcd <diretório>\n' >&2; return 1; }
  [[ "$1" =~ [[:cntrl:]] ]] && { printf '❌ Nome inválido\n' >&2; return 1; }
  mkdir -p -- "$1" && cd -- "$1"
}

nf() {
  [[ -z "$1" ]] && { printf '❌ Uso: nf <arquivo>\n' >&2; return 1; }
  [[ "$1" =~ [[:cntrl:]] ]] && { printf '❌ Nome inválido\n' >&2; return 1; }
  touch -- "$1" && printf '✅ Arquivo "%s" criado em %s\n' "$1" "$(pwd)"
}

# ==============================================================================
# FUNÇÕES — GIT
# ==============================================================================
gcom() {
  [[ -z "$1" ]] && { printf '❌ Uso: gcom "mensagem"\n' >&2; return 1; }
  git rev-parse --git-dir &>/dev/null || { printf '❌ Não é um repositório Git\n' >&2; return 1; }
  
  # Verifica se há mudanças pendentes
  if [[ -z $(git status --porcelain) ]]; then
    printf '⚠️ Working tree limpo. Nada para commitar.\n' >&2
    return 1
  fi
  
  git add . && git commit -m "$1"
}

lazyg() {
  [[ -z "$1" ]] && { printf '❌ Uso: lazyg "mensagem"\n' >&2; return 1; }
  
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
    printf '❌ Não é um repositório Git\n' >&2
    return 1
  }

  gcom "$1" || return 1

  [[ ! -t 0 ]] && { printf '⚠️ Sessão não interativa: push cancelado\n' >&2; return 1; }

  read -r -t 10 'confirm?🚀 Enviar para origin/'"$branch"'? [s/N] ' || {
    printf '\n⏰ Timeout: push cancelado\n' >&2
    return 1
  }

  if [[ "$confirm" =~ ^[sSyY]$ ]]; then
    git push origin "$branch" && printf '✅ Push realizado!\n'
  else
    printf '⚠️ Push cancelado. Commit local mantido.\n'
  fi
}

# ==============================================================================
# FUNÇÕES — UTILITÁRIOS
# ==============================================================================
sudo() {
  if [[ "$1" == "!!" ]]; then
    local last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')
    
    # Proteção contra comandos perigosos
    if [[ "$last_cmd" =~ ^(sudo|rm[[:space:]]+-rf[[:space:]]+/|mkfs|dd[[:space:]]+of=|chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/) ]]; then
      printf '❌ Comando bloqueado por segurança: %s\n' "$last_cmd" >&2
      return 1
    fi
    
    printf 'Executando como root: %s\n' "$last_cmd"
    command sudo zsh -c "$last_cmd"
  else
    command sudo "$@"
  fi
}

sedi() {
  [[ "$#" -ne 2 ]] && { printf 'Uso: sedi "s/old/new/g" <arquivo>\n' >&2; return 1; }
  [[ ! -f "$2" ]] && { printf '❌ Arquivo não encontrado: %s\n' "$2" >&2; return 1; }
  
  local pattern="$1" file="$2"
  local backup="${file}.bak.$(date +%Y%m%d%H%M%S)"
  local tmp=$(mktemp) || return 1
  trap "rm -f '$tmp'" INT TERM
  
  cp "$file" "$backup" && sed "$pattern" "$file" > "$tmp" && mv "$tmp" "$file" && \
    printf '✅ Modificado. Backup: %s\n' "$backup"
  trap - INT TERM
}

extract() {
  [[ -z "$1" || ! -f "$1" ]] && { printf '❌ Uso: extract <arquivo>\n' >&2; return 1; }
  
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar.zst)        tar --zstd -xf "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.xz)             unxz "$1" ;;
    *.zst)            unzstd "$1" ;;
    *.tar)            tar xf "$1" ;;
    *.zip)            unzip "$1" ;;
    *.rar)            unrar x "$1" ;;
    *.7z)             7z x "$1" ;;
    *)                printf '❌ Formato não suportado\n' >&2; return 1 ;;
  esac || { printf '❌ Falha ao extrair: %s\n' "$1" >&2; return 1; }
  
  printf '✅ Extraído: %s\n' "$1"
}

bk() {
  [[ -z "$1" || ! -f "$1" ]] && { printf '❌ Uso: bk <arquivo>\n' >&2; return 1; }
  local backup="${1}.bak.$(date +%Y%m%d_%H%M%S)"
  cp "$1" "$backup" && printf '✅ Backup: %s\n' "$backup"
}

port() {
  if [[ -n "$1" ]]; then
    ss -tulpn | grep -w ":$1" || printf '⚠️ Porta %s livre\n' "$1"
  else
    ss -tulpn
  fi
}

# ==============================================================================
# ALIASES — GERENCIAMENTO DE PACOTES
# ==============================================================================
alias dnf-clean='sudo dnf autoremove -y && sudo dnf clean all && printf "✅ DNF limpo\n"'
alias flatpak-clean='flatpak uninstall --unused -y && printf "✅ Flatpak limpo\n"'
alias sys-clean='sudo dnf autoremove -y && sudo dnf clean all && flatpak uninstall --unused -y && printf "🧹 Sistema limpo\n"'

# ==============================================================================
# CONFIGURAÇÕES LOCAIS (opcional)
# ==============================================================================
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# ==============================================================================
# POWERLEVEL10K — TEMA (deve vir no final)
# ==============================================================================
if [[ -f ~/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source ~/powerlevel10k/powerlevel10k.zsh-theme
elif [[ -f ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme
fi

[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ==============================================================================
# COMPILAÇÃO AUTOMÁTICA DO .zshrc (bytecode)
# ==============================================================================
if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  zcompile ~/.zshrc &>/dev/null &!
fi

# ==============================================================================
# BOOT TIMER — Cálculo final (exibição apenas via comando)
# ==============================================================================
typeset -g _zshrc_load_ms=$(printf "%.0f" "$(( (EPOCHREALTIME - _zshrc_start_s) * 1000 ))")
unset _zshrc_start_s

# Função para exibir tempo de carregamento (sob demanda)
zshrc-time() {
  local ms=$_zshrc_load_ms
  if   (( ms < 150 )); then printf '⚡ .zshrc: \e[32m%dms\e[0m (excelente)\n' "$ms"
  elif (( ms < 200 )); then printf '⚡ .zshrc: \e[32m%dms\e[0m (bom)\n' "$ms"
  elif (( ms < 500 )); then printf '⚡ .zshrc: \e[33m%dms\e[0m (aceitável)\n' "$ms"
  else                      printf '🐢 .zshrc: \e[31m%dms\e[0m (lento)\n' "$ms"
  fi
}
