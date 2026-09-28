# ==============================================================================
# Powerlevel10k Instant Prompt
# MUST be the first thing sourced — no output, no expansions before this line.
# Skipped when an Oh My Zsh theme is active ($ZSH_THEME set): the stale p10k
# cache would flash a foreign prompt before the real one renders.
# See: https://github.com/romkatv/powerlevel10k#instant-prompt
# ==============================================================================
if [[ -z "$ZSH_THEME" && -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
