# ==============================================================================
# Boot Timer — captures wall-clock startup time using EPOCHREALTIME (µs precision)
# zmodload zsh/datetime enables the $EPOCHREALTIME parameter (float, seconds.µs)
# ==============================================================================
zmodload zsh/datetime
typeset -g _zshrc_start_s=$EPOCHREALTIME
