# ==============================================================================
# Aliases — eza (modern ls replacement with icons and git status)
# eza is the community fork of exa (exa is unmaintained since 2021)
# --icons:                  show file type icons (requires Nerd Font)
# --group-directories-first: list folders before files
# -l: long format (permissions, size, date)
# -h: human-readable sizes (1K, 234M, 2G)
# -a: show hidden files (dotfiles)
# --git: show git status indicators (modified, staged, untracked)
# -1: one entry per line
# --tree --level=2: recursive tree view, 2 levels deep
# All aliases conditionally defined — eza not required for shell to work
# ==============================================================================
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --group-directories-first --git'
  alias la='eza -lah --icons --group-directories-first --git'
  alias l='eza -1 --icons'
  alias lt='eza --tree --icons --level=2'
fi

# ==============================================================================
# Aliases — Colorized grep
# --color=auto: highlights matching patterns only when output is a terminal
# -F: fixed strings (no regex) for fgrep
# -E: extended regex for egrep
# Standard GNU grep flags, available on any Linux with grep installed
# ==============================================================================
if command -v grep &>/dev/null; then
  alias grep='grep --color=auto'
  alias fgrep='grep -F --color=auto'
  alias egrep='grep -E --color=auto'
fi

# ==============================================================================
# Aliases — Navigation shortcuts
# home:  cd ~ (home directory)
# docs:  cd ~/Documents
# dtop:  cd ~/Desktop
# reload: re-source .zshrc and confirm via stdout
# ==============================================================================
alias home='cd ~'
alias docs='cd ~/Documents'
alias dtop='cd ~/Desktop'
alias reload='source ~/.zshrc && printf "[OK] .zshrc reloaded\n"'

# ==============================================================================
# Aliases — Fedora System Cleanup
# dnf-clean:    autoremove orphaned packages, then clean DNF cache
# flatpak-clean: remove unused Flatpak runtimes
# sys-clean:    both cleanup operations in one command
# -y flag auto-confirms — safe since these only remove unused artifacts
# Package manager aliases only work when the corresponding tool is installed.
# ==============================================================================
if command -v dnf &>/dev/null; then
  alias dnf-clean='sudo dnf autoremove -y && sudo dnf clean all && printf "DNF cleaned\n"'
fi

if command -v flatpak &>/dev/null; then
  alias flatpak-clean='flatpak uninstall --unused -y && printf "Flatpak cleaned\n"'
fi

if command -v dnf &>/dev/null && command -v flatpak &>/dev/null; then
  alias sys-clean='sudo dnf autoremove -y && sudo dnf clean all && flatpak uninstall --unused -y && printf "System cleaned\n"'
elif command -v dnf &>/dev/null; then
  alias sys-clean='sudo dnf autoremove -y && sudo dnf clean all && printf "DNF cleaned\n"'
elif command -v flatpak &>/dev/null; then
  alias sys-clean='flatpak uninstall --unused -y && printf "Flatpak cleaned\n"'
fi
