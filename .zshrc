# ==============================================================================
# Zsh Configuration — Fedora Optimized
# Version: 3.1 | Modular | Oh My Zsh + Powerlevel10k
#
# Sources modular configs in strict dependency order from subdirectories:
#   boot/    — startup chain (prompt, timer, theme, compile)
#   core/    — shell foundation (paths, options, security)
#   plugins/ — plugin loading (cache, omz, lazy)
#   tools/   — user productivity (aliases, functions, local overrides)
# ==============================================================================

# Resolve module directory (installer symlink → repo-relative → git root fallback)
if [[ -d "$HOME/.zsh_modules" ]]; then
  _M="$HOME/.zsh_modules"
elif [[ -d "${0:A:h}/modules" ]]; then
  _M="${0:A:h}/modules"
elif repo_root=$(git -C "${0:A:h}" rev-parse --show-toplevel 2>/dev/null) && [[ -d "$repo_root/modules" ]]; then
  _M="$repo_root/modules"
else
  echo ".zshrc: modules not found — clone repo or use install.sh" >&2
  _M=""
fi

if [[ -n "$_M" ]]; then
  # === BOOT: startup chain (order critical — do not reorder) ===
  source "$_M/boot/prompt.zsh"       # ① P10k instant prompt (MUST be FIRST, zero output before this)
  source "$_M/boot/timer-start.zsh"  # ② Wall-clock timer start (EPOCHREALTIME)

  # === CORE: shell foundation ===
  source "$_M/core/environment.zsh"  # ③ PATH dedup, user bins, XDG base directories
  source "$_M/core/shell.zsh"        # ④ Zsh options, 50K history, dedup, sharing
  source "$_M/core/security.zsh"     # ⑤ History credential filter + sudo wrapper

  # === PLUGINS: framework & performance ===
  source "$_M/plugins/cache.zsh"     # ⑥ Version-fingerprint plugin init cache (30-50% faster)
  source "$_M/plugins/omz.zsh"       # ⑦ Oh My Zsh framework + conditional plugins
  source "$_M/plugins/lazy.zsh"      # ⑧ zsh-defer deferred source (optional, prompt-ready sooner)

  # === TOOLS: user productivity ===
  source "$_M/tools/aliases.zsh"     # ⑨ eza, grep, navigation, system cleanup
  source "$_M/tools/nvidia.zsh"      # ⑩ NVIDIA/Fedora GPU helpers + CUDA opt-in
  source "$_M/tools/functions.zsh"   # ⑪ up, mkcd, nf, gcom, lazyg, sedi, extract, bk, port
  source "$_M/tools/local.zsh"       # ⑫ ~/.zshrc.local overrides (pre-theme, machine-specific)

  # === BOOT: finalization ===
  source "$_M/boot/theme.zsh"        # ⑬ P10k theme (MUST be last substantive source)
  source "$_M/boot/compile.zsh"      # ⑭ Bytecode compilation (background via zcompile &!)
  source "$_M/boot/timer-end.zsh"    # ⑮ Timer end calculation + zshrc-time display command
fi

unset _M
