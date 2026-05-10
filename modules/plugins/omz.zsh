# ==============================================================================
# Oh My Zsh — Framework Configuration
# ZSH: path to Oh My Zsh installation directory
# ZSH_THEME: empty string — Powerlevel10k is loaded separately (boot/theme.zsh)
#
# Performance:
#   ZSH_DISABLE_COMPFIX=true — skips compaudit (~7ms saved per shell start).
#     compaudit checks completion directory ownership/permissions; unnecessary
#     on single-user machines. Safe to skip — completion still works.
#   DISABLE_AUTO_UPDATE=true — skips OMZ auto-update check on shell start.
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
ZSH_DISABLE_COMPFIX=true
DISABLE_AUTO_UPDATE=true

# ==============================================================================
# OMZ Plugins
# Core plugins: git (aliases, branch info), history (history-related aliases)
# Conditional plugins: zsh-autosuggestions and zsh-syntax-highlighting are
# added to the OMZ plugin list ONLY when zsh-defer is NOT available (zsh-defer
# handles them via lazy loading instead — see plugins/lazy.zsh for that path).
# ==============================================================================
plugins=(git history)

# When zsh-defer is absent, load heavy plugins through Oh My Zsh normally
if [[ ! -f "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-defer/zsh-defer.plugin.zsh" ]]; then
  [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions" ]] && \
    plugins+=(zsh-autosuggestions)
  [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting" ]] && \
    plugins+=(zsh-syntax-highlighting)
fi

# Source Oh My Zsh — loads lib/, plugins/, and sets up completions (compinit)
source "$ZSH/oh-my-zsh.sh"
