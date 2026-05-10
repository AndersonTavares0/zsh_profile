# ==============================================================================
# Powerlevel10k Instant Prompt
# MUST be the first thing sourced — no output, no expansions before this line.
# See: https://github.com/romkatv/powerlevel10k#instant-prompt
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
