# ==============================================================================
# ARQUIVO DE CONFIGURAÇÃO DO ZSH (~/.zshrc)
# Otimizado para velocidade com Powerlevel10k, Oh My Zsh e cache de plugins.
# ==============================================================================

# ==============================================================================
# BOOT TIMER — Captura o tempo de início para medição.
# A impressão é feita sob demanda com o comando `zshrc-time`.
# ==============================================================================
zmodload zsh/datetime
typeset -g _zshrc_start_s=$EPOCHREALTIME

# ==============================================================================
# POWERLEVEL10K — INSTANT PROMPT
# Essencial para uma inicialização rápida. Deve permanecer no topo do arquivo.
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
# OH MY ZSH — CONFIGURAÇÃO BASE
# O tema é desativado (ZSH_THEME="") pois o Powerlevel10k é carregado manualmente.
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  history
)

source "$ZSH/oh-my-zsh.sh"

# ==============================================================================
# SISTEMA DE CACHE DE PLUGINS
# Acelera o carregamento do shell ao inicializar plugins (zoxide, fzf)
# apenas quando as ferramentas mudam de versão ou são instaladas/removidas.
# ==============================================================================
_PLUGIN_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh_plugins_init.zsh"
_TOOLS_WATCHED=(zoxide eza fzf) # Ferramentas monitoradas

# Gera um "fingerprint" (hash) das versões das ferramentas
_zsh_gen_fingerprint() {
  local fp=""
  local tool path_val
  for tool in "${_TOOLS_WATCHED[@]}"; do
    path_val=$(command -v "$tool" 2>/dev/null || echo "missing")
    fp+="${tool}=${path_val};"
  done
  # Usar md5sum ou md5 dependendo do que estiver disponível
  if command -v md5sum &>/dev/null; then
    printf '%s' "$fp" | md5sum | cut -d' ' -f1
  elif command -v md5 &>/dev/null; then
    printf '%s' "$fp" | md5
  fi
}

# Constrói o arquivo de cache com a inicialização dos plugins
_zsh_build_plugin_cache() {
  local tmp
  tmp=$(mktemp) || return 1

  # Cabeçalho com fingerprint para validação futura
  printf '# zsh_plugin_cache fingerprint: %s\n' "$(_zsh_gen_fingerprint)" > "$tmp"

  # --- zoxide: Navegação inteligente de diretórios
  if command -v zoxide &>/dev/null; then
    printf '\n# --- zoxide ---\n' >> "$tmp"
    zoxide init zsh >> "$tmp" 2>/dev/null
  fi

  # --- fzf: Busca fuzzy interativa
  if command -v fzf &>/dev/null; then
    printf '\n# --- fzf ---\n' >> "$tmp"
    [[ -f /usr/share/fzf/shell/key-bindings.zsh ]] && \
      printf 'source /usr/share/fzf/shell/key-bindings.zsh\n' >> "$tmp"
    [[ -f /usr/share/zsh/site-functions/_fzf ]] && \
      printf 'source /usr/share/zsh/site-functions/_fzf\n' >> "$tmp"
  fi

  # Escrita atômica: move o arquivo temporário apenas se a construção foi bem-sucedida
  mv "$tmp" "$_PLUGIN_CACHE"
}

# Valida o cache e o reconstrói se necessário
if [[ -f "$_PLUGIN_CACHE" ]]; then
  _zsh_current_fp=$(_zsh_gen_fingerprint)
  _zsh_cached_fp=$(sed -n '1s/# zsh_plugin_cache fingerprint: //p' "$_PLUGIN_CACHE")
  [[ "$_zsh_current_fp" != "$_zsh_cached_fp" ]] && _zsh_build_plugin_cache
else
  _zsh_build_plugin_cache
fi

# Carrega o cache e limpa as variáveis temporárias
[[ -f "$_PLUGIN_CACHE" ]] && source "$_PLUGIN_CACHE"
unset _PLUGIN_CACHE _TOOLS_WATCHED _zsh_current_fp _zsh_cached_fp

# ==============================================================================
# ALIASES: EZA (substituto moderno do 'ls')
# ==============================================================================
if command -v eza &>/dev/null; then
  unalias ls 2>/dev/null || true
  unalias ll 2>/dev/null || true
  unalias la 2>/dev/null || true
  unalias l 2>/dev/null || true
  unalias lt 2>/dev/null || true

  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --group-directories-first --git'
  alias la='eza -lah --icons --group-directories-first --git'
  alias l='eza -1 --icons'
  alias lt='eza --tree --icons --level=2'
fi

# ==============================================================================
# ALIASES: NAVEGAÇÃO E ATALHOS
# ==============================================================================
alias home='cd ~'
alias docs='cd ~/Documents'
alias up='cd ..'
alias up2='cd ../..'

# Atalho para a área de trabalho
unalias dtop 2>/dev/null || true
dtop() {
  cd ~/Desktop || return 1
}

# Cria e entra no diretório em um só comando
mkcd() {
  if [[ -z "$1" ]]; then
    echo "Uso: mkcd <diretório>" >&2
    return 1
  fi
  mkdir -p "$1" && cd "$1"
}

# Cria um novo arquivo vazio e confirma
nf() {
  if [[ -z "$1" ]]; then
    echo "Uso: nf <nome-do-arquivo>" >&2
    return 1
  fi
  touch "$1" && echo "✅ Arquivo '$1' criado em $(pwd)"
}

# ==============================================================================
# FUNÇÕES: GIT (ergonomia)
# ==============================================================================
# git add . + commit com validação
gcom() {
  if [[ -z "$1" ]]; then
    echo "❌ Uso: gcom \"mensagem do commit\"" >&2
    return 1
  fi
  if ! git rev-parse --git-dir &>/dev/null; then
    echo "❌ Não é um repositório Git." >&2
    return 1
  fi
  git add . && git commit -m "$1" || {
    echo "❌ Commit falhou. Verifique o status com 'git status'." >&2
    return 1
  }
}

# Fluxo completo: commit + push com confirmação
lazyg() {
  if [[ -z "$1" ]]; then
    echo "❌ Uso: lazyg \"mensagem do commit\"" >&2
    return 1
  fi

  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
    echo "❌ Não é um repositório Git." >&2
    return 1
  }

  gcom "$1" || return 1

  # Pergunta antes de fazer o push
  read -r 'confirm?🚀 Enviar para origin/'"$branch"'? [s/N] '
  if [[ "$confirm" =~ ^[sSyY]$ ]]; then
    git push origin "$branch" && echo "✅ Push realizado com sucesso!" || {
      echo "❌ Push falhou. Verifique as permissões ou conexão." >&2
      return 1
    }
  else
    echo "⚠️ Push cancelado. Commit local mantido."
  fi
}

# ==============================================================================
# FUNÇÕES: ADMINISTRAÇÃO E UTILITÁRIOS
# ==============================================================================
# Executa o último comando como root com 'sudo !!'
unalias sudo 2>/dev/null || true
sudo() {
  if [[ "$1" == "!!" ]]; then
    local last_cmd
    last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')
    echo "Executando como root: ${last_cmd}"
    command sudo zsh -c "$last_cmd"
  else
    command sudo "$@"
  fi
}

# 'sed' com escrita atômica para evitar corrupção de arquivos
sedi() {
  if [[ "$#" -ne 2 ]]; then
    echo "Uso: sedi 's/antigo/novo/g' <arquivo>" >&2
    return 1
  fi
  local pattern="$1" file="$2" tmp
  [[ ! -f "$file" ]] && { echo "❌ Arquivo não encontrado: ${file}"; return 1; }
  tmp=$(mktemp) && sed "$pattern" "$file" > "$tmp" && mv "$tmp" "$file"
}

# ==============================================================================
# ALIASES: GERENCIAMENTO DE PACOTES (limpeza)
# ==============================================================================
# Limpeza do DNF (Fedora/CentOS)
alias dnf-clean='sudo dnf autoremove -y && sudo dnf clean all && echo "✅ DNF limpo."'

# Limpeza do Flatpak
alias flatpak-clean='flatpak uninstall --unused -y && echo "✅ Flatpak limpo."'

# Limpeza completa do sistema
alias sys-clean='sudo dnf autoremove -y && sudo dnf clean all && flatpak uninstall --unused -y && echo "🧹 Sistema totalmente limpo!"'

# ==============================================================================
# PATH — Adiciona diretórios personalizados ao PATH
# ==============================================================================
export PATH="$PATH:$HOME/.local/bin:$HOME/bin:$HOME/.spicetify"

# ==============================================================================
# POWERLEVEL10K — CARREGAMENTO DO TEMA
# Deve ser carregado no final para garantir que todas as funções e aliases
# estejam disponíveis para o tema.
# ==============================================================================
[[ -f ~/powerlevel10k/powerlevel10k.zsh-theme ]] && source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ==============================================================================
# BOOT TIMER — CÁLCULO FINAL E FUNÇÃO DE EXIBIÇÃO
# ==============================================================================
typeset -g ZSHRC_LOAD_MS
ZSHRC_LOAD_MS=$(printf "%.0f" "$(( (EPOCHREALTIME - _zshrc_start_s) * 1000 ))")
unset _zshrc_start_s

# Função para exibir o tempo de carregamento sem causar warnings na inicialização.
# Basta digitar `zshrc-time` no terminal.
zshrc-time() {
  local load_ms=$ZSHRC_LOAD_MS
  if (( load_ms < 200 )); then
    printf '⚡ .zshrc carregado em \e[32m%dms\e[0m\n' "$load_ms"
  elif (( load_ms < 500 )); then
    printf '⚡ .zshrc carregado em \e[33m%dms\e[0m\n' "$load_ms"
  else
    printf '🐢 .zshrc carregado em \e[31m%dms\e[0m — verifique os plugins\n' "$load_ms"
  fi
}