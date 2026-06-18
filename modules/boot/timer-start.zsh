# ==============================================================================
# Boot Timer — captures wall-clock startup time using EPOCHREALTIME (µs precision)
# zmodload zsh/datetime enables the $EPOCHREALTIME parameter (float, seconds.µs)
# ==============================================================================
if zmodload zsh/datetime 2>/dev/null; then
  typeset -g _zshrc_start_s=$EPOCHREALTIME
else
  typeset -g _zshrc_start_s=""
fi
