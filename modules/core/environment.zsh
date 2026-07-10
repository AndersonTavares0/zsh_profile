# ==============================================================================
# Path Deduplication
# typeset -U: treats the array as a set — automatically removes duplicates
# Must run before any PATH modifications so we only expand unique entries
# ==============================================================================
typeset -U path PATH fpath FPATH ld_library_path LD_LIBRARY_PATH

# ==============================================================================
# PATH — user-local directories take priority over system paths
# ~/.opencode/bin: OpenCode AI CLI tool
# ~/.local/bin: pip install --user, local scripts
# ~/bin:         manual binary drops
# ~/.spicetify:  Spicetify CLI (Spotify customization tool)
# macOS Homebrew: /opt/homebrew/bin (ARM) or /usr/local/bin (Intel) if present
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$HOME/bin:$HOME/.spicetify:$PATH"

if [[ "$(uname -s)" == "Darwin" ]]; then
  if [[ -d /opt/homebrew/bin ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
  fi
fi

# ==============================================================================
# XDG Base Directory Specification
# Set standard XDG env vars so modern CLI tools (zoxide, fzf) auto-respect them
# XDG_CONFIG_HOME: ~/.config  (default, explicit for clarity)
# XDG_CACHE_HOME:  ~/.cache   (default, used by plugin cache system)
# XDG_DATA_HOME:   ~/.local/share (default, used by zoxide database)
# ==============================================================================
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
