# ==============================================================================
# Lazy Loading via zsh-defer (optional, speeds up prompt readiness)
#
# zsh-defer defers sourcing of heavy plugins until Zsh is idle (waiting for
# input). This means the prompt appears faster while autosuggestions and
# syntax highlighting load in the background.
#
# Ordering constraint (CRITICAL):
#   zsh-syntax-highlighting MUST load AFTER zsh-autosuggestions.
#   Loading in reverse causes highlighting to fail on suggestion text.
#   zsh-defer preserves this ordering by deferring each source sequentially.
#
# If zsh-defer is not installed: heavy plugins load synchronously through
# Oh My Zsh's standard plugin system (see plugins/omz.zsh).
# ==============================================================================
if [[ -f "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-defer/zsh-defer.plugin.zsh" ]]; then
  source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-defer/zsh-defer.plugin.zsh"

  # zsh-autosuggestions: grays out predicted completions based on history
  # Must load before syntax-highlighting (highlighting decorates suggestions)
  if [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions" ]]; then
    zsh-defer source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi

  # zsh-syntax-highlighting: colors commands as you type (red = invalid)
  # Must load AFTER zsh-autosuggestions and near the END of .zshrc
  if [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting" ]]; then
    zsh-defer source "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi
fi
