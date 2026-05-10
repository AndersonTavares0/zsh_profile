# ==============================================================================
# Boot Timer — End Calculation
# Computes elapsed wall-clock time in milliseconds since shell start
# EPOCHREALTIME: float (seconds.µs), multiplied by 1000 → integer ms
# printf "%.0f": rounds to nearest integer for clean display
# ==============================================================================
typeset -g _zshrc_load_ms=$(printf "%.0f" "$(( (EPOCHREALTIME - _zshrc_start_s) * 1000 ))")
unset _zshrc_start_s

# ==============================================================================
# zshrc-time: display shell load time with color-coded thresholds
# \e[32m: green  (fast)
# \e[33m: yellow (acceptable)
# \e[31m: red    (slow)
# \e[0m:  reset  (return to default color)
# Thresholds: <150ms excellent | <200ms good | <500ms acceptable | >=500ms slow
# ==============================================================================
zshrc-time() {
  local ms=$_zshrc_load_ms
  if   (( ms < 150 )); then printf '\e[32m%dms\e[0m (excellent)\n' "$ms"
  elif (( ms < 200 )); then printf '\e[32m%dms\e[0m (good)\n' "$ms"
  elif (( ms < 500 )); then printf '\e[33m%dms\e[0m (acceptable)\n' "$ms"
  else                      printf '\e[31m%dms\e[0m (slow)\n' "$ms"
  fi
}
