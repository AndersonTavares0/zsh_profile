# ==============================================================================
# Bytecode Compilation
# Compiles .zshrc and all modules to .zwc for faster parsing on subsequent starts.
# zcompile: Zsh's built-in bytecode compiler — tokenizes once, loads near-instantly.
# -U: skip alias expansion (safety — no alias side effects during compilation)
# &!: background + disown — never blocks the current shell from starting.
#
# Only recompiles when source files are newer than their .zwc counterparts.
# ==============================================================================
_zsh_compile_all() {
  # Compile entry-point
  if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
    zcompile -U ~/.zshrc &>/dev/null &!
  fi

  # Batch-compile all modules if the directory changed
  local mod_dir="$HOME/.zsh_modules"
  [[ -z "$mod_dir" || ! -d "$mod_dir" ]] && return

  # Compile each module individually for granular cache invalidation
  for src in "$mod_dir"/**/*.zsh(.N); do
    local zwc="${src}.zwc"
    [[ ! -f "$zwc" || "$src" -nt "$zwc" ]] && zcompile -U "$src" &>/dev/null &!
  done
}

_zsh_compile_all
unset -f _zsh_compile_all
