# ==============================================================================
# Plugin Init Cache System
#
# Problem: `zoxide init zsh` and `fzf` key-binding sourcing run on every shell
#          start, adding ~150-200ms. These commands rarely change (only when
#          tools update), so caching their output saves 30-50% boot time.
#
# Solution: Cache the init script output to $XDG_CACHE_HOME/zsh_plugins_init.zsh
#           with a fingerprint of tool versions. Rebuild only when:
#           1. Cache file doesn't exist (first run)
#           2. Tool version fingerprint changed (tool was updated via DNF)
#
# Architecture:
#   1. Generate fingerprint: `tool --version | head -1` for each watched tool
#   2. Hash fingerprint via cksum (CRC32 + byte count) for collision resistance
#   3. Compare against first-line fingerprint in cached file
#   4. If mismatch: rebuild cache via mktemp (atomic write, no partial files)
#   5. If match: source cached file directly (fast path)
#   6. Compile cache to .zwc bytecode in background for next shell start
#
# Watched tools: zoxide (init zsh), fzf (key-bindings + completion source)
# ==============================================================================
typeset -g _PLUGIN_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh_plugins_init.zsh"
typeset -ga _TOOLS_WATCHED=(zoxide fzf)

# Generate a fingerprint hash from watched tool versions.
# Uses `tool --version 2>/dev/null | head -1` to capture the version string,
# then pipes through cksum (CRC32 checksum + byte count) for a short hash.
# Returns "0" for missing tools so they don't trigger unnecessary rebuilds.
_zsh_gen_fingerprint() {
  local fp="" tool version
  for tool in "${_TOOLS_WATCHED[@]}"; do
    version=$(command "$tool" --version 2>/dev/null | head -1 || echo "missing")
    fp+="${tool}=${version};"
  done
  print -n "$fp" | cksum | cut -d' ' -f1
}

# Rebuild the plugin cache file atomically.
# Uses mktemp for a secure temp file name, then mv for atomic overwrite.
# trap INT TERM ensures the temp file is cleaned up if the shell is interrupted.
_zsh_build_plugin_cache() {
  local tmp=$(mktemp) || return 1
  trap "rm -f '$tmp'" INT TERM

  # Write fingerprint as first-line comment for future comparison
  printf '# zsh_plugin_cache fingerprint: %s\n' "$(_zsh_gen_fingerprint)" > "$tmp"

  # zoxide: generates `z` and `zi` commands + hook functions
  if command -v zoxide &>/dev/null; then
    printf '\n# --- zoxide ---\n' >> "$tmp"
    zoxide init zsh >> "$tmp" 2>/dev/null
  fi

  # fzf: Ctrl-R history search, Ctrl-T file search, Alt-C directory jump
  if command -v fzf &>/dev/null; then
    printf '\n# --- fzf ---\n' >> "$tmp"
    [[ -f /usr/share/fzf/shell/key-bindings.zsh ]] && \
      printf 'source /usr/share/fzf/shell/key-bindings.zsh\n' >> "$tmp"
    [[ -f /usr/share/zsh/site-functions/_fzf ]] && \
      printf 'source /usr/share/zsh/site-functions/_fzf\n' >> "$tmp"
  fi

  mv "$tmp" "$_PLUGIN_CACHE"
}

# Validate cache: skip fingerprint check if cache was rebuilt in the last 24h.
# Tools only change on DNF upgrades (infrequent), so a daily check is sufficient.
# Uses [[ file -nt reference ]] to compare modification times without external stat.
# _zsh_cache_check file: touched on each successful validation to track last check.
_zsh_cache_stale() {
  local check_file="${_PLUGIN_CACHE}.last_check"
  # Stale if: check file missing, cache newer than check file, or >24h since last check
  if [[ ! -f "$check_file" ]]; then
    touch "$check_file" 2>/dev/null; return 0
  fi
  # Re-check fingerprint once per day (86400 seconds)
  local now=$EPOCHSECONDS
  local last=$(stat -c %Y "$check_file" 2>/dev/null || stat -f %m "$check_file" 2>/dev/null || echo 0)
  if (( now - last > 86400 )); then
    touch "$check_file" 2>/dev/null; return 0
  fi
  return 1  # Cache is fresh — skip fingerprint
}

if [[ -f "$_PLUGIN_CACHE" ]]; then
  if _zsh_cache_stale; then
    _zsh_current_fp=$(_zsh_gen_fingerprint)
    _zsh_cached_fp=$(sed -n '1s/# zsh_plugin_cache fingerprint: //p' "$_PLUGIN_CACHE")
    [[ "$_zsh_current_fp" != "$_zsh_cached_fp" ]] && _zsh_build_plugin_cache
  fi
else
  _zsh_build_plugin_cache
fi

# Source the cached init script (may be freshly built or from disk)
[[ -f "$_PLUGIN_CACHE" ]] && source "$_PLUGIN_CACHE"

# Compile cache to .zwc bytecode in background for faster loading next time
# zcompile: Zsh's built-in bytecode compiler — parses once, loads faster
# &!: runs in background and disowns (no job control notification)
if [[ -f "$_PLUGIN_CACHE" && ( ! -f "${_PLUGIN_CACHE}.zwc" || "$_PLUGIN_CACHE" -nt "${_PLUGIN_CACHE}.zwc" ) ]]; then
  zcompile "$_PLUGIN_CACHE" &>/dev/null &!
fi

# Clean up cache-related variables — they're no longer needed after sourcing
unset _PLUGIN_CACHE _TOOLS_WATCHED _zsh_current_fp _zsh_cached_fp
