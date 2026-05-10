# ==============================================================================
# Zsh Options — shell behavior
# AUTO_CD:          cd on directory name alone (no `cd` prefix needed)
# EXTENDED_GLOB:    enables #, ~, ^ glob operators for advanced pattern matching
# ==============================================================================
setopt AUTO_CD EXTENDED_GLOB

# ==============================================================================
# History Options
# INC_APPEND_HISTORY:   write each command immediately
# SHARE_HISTORY:        share history across all sessions in real-time
# HIST_IGNORE_ALL_DUPS: remove older duplicate when new one is added
# HIST_SAVE_NO_DUPS:    omit duplicates when writing HISTFILE on shell exit
# HIST_EXPIRE_DUPS_FIRST: expire oldest duplicates first when HISTSIZE limit hit
# HIST_REDUCE_BLANKS:   strip superfluous whitespace from commands before saving
# ==============================================================================
setopt INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST HIST_REDUCE_BLANKS

# ==============================================================================
# History Storage
# HISTFILE: file path — respects ZDOTDIR if set, falls back to $HOME
# HISTSIZE: entries kept in-memory per session (50K)
# SAVEHIST: entries saved to HISTFILE on disk (50K)
# ==============================================================================
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
