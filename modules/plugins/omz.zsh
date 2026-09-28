# ==============================================================================
# Oh My Zsh — Framework Configuration
# ZSH: path to Oh My Zsh installation directory
# ZSH_THEME: preserved when the user exports it (e.g. in ~/.zshenv, which
# OMZ reads at `source oh-my-zsh.sh` time); empty string keeps the default
# behavior — Powerlevel10k loaded separately (boot/theme.zsh).
# To use a built-in or $ZSH_CUSTOM theme instead of p10k:
#   export ZSH_THEME="agnoster"   # in ~/.zshenv (before .zshrc)
# boot/theme.zsh then skips p10k automatically.
#
# Performance:
#   ZSH_DISABLE_COMPFIX=true — skips compaudit (~7ms saved per shell start).
#     compaudit checks completion directory ownership/permissions; unnecessary
#     on single-user machines. Safe to skip — completion still works.
#   zstyle ':omz:update' mode disabled — disables OMZ auto-update prompt.
#     zstyle is the recommended OMZ method (survives framework internal changes).
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"
# Preserve a user-exported theme (e.g. from ~/.zshenv); default empty → p10k.
ZSH_THEME="${ZSH_THEME:-}"
ZSH_DISABLE_COMPFIX=true
zstyle ':omz:update' mode disabled

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
