#!/usr/bin/env bash
# ==============================================================================
# Zsh Profile — Interactive Installer
#
# One command for everything:
#   curl -fsSL https://raw.githubusercontent.com/andersonbosa/zsh_profile/main/install.sh | bash
#
# The script detects piped input and presents an interactive menu via /dev/tty.
# Choose: [1] Install  [2] Uninstall  [3] Quick Install (skip prompts)  [q] Quit
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Resolve repo directory: when piped via curl, $0 is "bash", so fall back to PWD
if [[ "${BASH_SOURCE[0]:-}" != "" && "${BASH_SOURCE[0]}" != "bash" ]]; then
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  # Running via curl pipe — need to clone first for install, or use standalone for uninstall
  REPO_DIR=""
fi

# ─── Utility functions ───────────────────────────────────────────────────────

detect_pkg_manager() {
  if command -v dnf &>/dev/null; then echo "dnf"
  elif command -v apt &>/dev/null; then echo "apt"
  elif command -v pacman &>/dev/null; then echo "pacman"
  elif command -v zypper &>/dev/null; then echo "zypper"
  else echo "unknown"; fi
}

read_choice() {
  local choice
  # When piped from curl, stdin is the script, not the terminal.
  # Redirect from /dev/tty to get actual user input.
  if [[ -t 0 ]]; then
    read -r choice
  else
    read -r choice < /dev/tty
  fi
  echo "$choice"
}

# ─── Install ─────────────────────────────────────────────────────────────────

do_install_packages() {
  local pkg="$1"
  printf "${CYAN}Installing system packages...${NC}\n"
  case "$pkg" in
    dnf)    sudo dnf install -y zsh git eza fzf zoxide ;;
    apt)    sudo apt update && sudo apt install -y zsh git eza fzf zoxide ;;
    pacman) sudo pacman -S --noconfirm zsh git eza fzf zoxide ;;
    zypper) sudo zypper install -y zsh git eza fzf zoxide ;;
    *)      printf "${RED}Unknown package manager. Install manually: zsh git eza fzf zoxide${NC}\n"; return 1 ;;
  esac
  printf "${GREEN}Packages installed.${NC}\n"
}

do_install_omz() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    printf "${YELLOW}Oh My Zsh already installed.${NC}\n"; return 0
  fi
  printf "${CYAN}Installing Oh My Zsh...${NC}\n"
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

do_install_p10k() {
  local dest="$ZSH_CUSTOM/themes/powerlevel10k"
  if [[ -d "$dest" ]]; then
    printf "${YELLOW}Powerlevel10k already installed.${NC}\n"; return 0
  fi
  printf "${CYAN}Cloning Powerlevel10k...${NC}\n"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$dest"
}

do_install_plugins() {
  local base="$ZSH_CUSTOM/plugins"
  declare -A plugin_urls=(
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
    [zsh-defer]="https://github.com/romkatv/zsh-defer"
  )
  for plugin in "${!plugin_urls[@]}"; do
    if [[ -d "$base/$plugin" ]]; then
      printf "${YELLOW}$plugin already installed.${NC}\n"; continue
    fi
    printf "${CYAN}Installing $plugin...${NC}\n"
    git clone "${plugin_urls[$plugin]}" "$base/$plugin"
  done
}

do_link_config() {
  if [[ -z "$REPO_DIR" ]]; then
    printf "${RED}Cannot link: running via curl without a local repo.${NC}\n"
    printf "Clone first, then run locally:\n"
    printf "  git clone https://github.com/andersonbosa/zsh_profile.git\n"
    printf "  cd zsh_profile && ./install.sh\n"
    return 1
  fi
  printf "${CYAN}Linking config...${NC}\n"
  ln -sf "$REPO_DIR/.zshrc"       "$HOME/.zshrc"
  ln -sfn "$REPO_DIR/modules"     "$HOME/.zsh_modules"
  printf "${GREEN}~/.zshrc → repo .zshrc${NC}\n"
  printf "${GREEN}~/.zsh_modules → repo modules/${NC}\n"
}

do_set_shell() {
  if [[ "$SHELL" == *"/zsh" ]]; then
    printf "${YELLOW}Zsh already default shell.${NC}\n"; return 0
  fi
  printf "${CYAN}Setting Zsh as default shell...${NC}\n"
  chsh -s "$(command -v zsh)"
}

do_quick_install() {
  local pkg=$(detect_pkg_manager)
  printf "${CYAN}Package manager: ${BOLD}$pkg${NC}\n"
  do_install_packages "$pkg"
  do_install_omz
  do_install_p10k
  do_install_plugins
  if [[ -n "$REPO_DIR" ]]; then
    do_link_config
    do_set_shell
  fi
}

# ─── Uninstall ───────────────────────────────────────────────────────────────

do_uninstall() {
  printf "${YELLOW}Removing zsh_profile configuration...${NC}\n\n"

  local removed=0

  if [[ -L "$HOME/.zshrc" ]]; then
    rm -f "$HOME/.zshrc"
    printf "  ${GREEN}✓${NC} ~/.zshrc symlink removed\n"; ((removed++))
  fi

  if [[ -L "$HOME/.zsh_modules" ]]; then
    rm -rf "$HOME/.zsh_modules"
    printf "  ${GREEN}✓${NC} ~/.zsh_modules symlink removed\n"; ((removed++))
  fi

  if [[ -f "$HOME/.zshrc.zwc" ]]; then
    rm -f "$HOME/.zshrc.zwc"
    printf "  ${GREEN}✓${NC} ~/.zshrc.zwc bytecode removed\n"; ((removed++))
  fi

  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh_plugins_init.zsh"
  if [[ -f "$cache" ]]; then
    rm -f "$cache"
    printf "  ${GREEN}✓${NC} Plugin init cache removed\n"; ((removed++))
  fi
  if [[ -f "${cache}.zwc" ]]; then
    rm -f "${cache}.zwc"
    printf "  ${GREEN}✓${NC} Plugin cache .zwc removed\n"; ((removed++))
  fi

  local p10k_cache="${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
  if [[ -f "$p10k_cache" ]]; then
    rm -f "$p10k_cache"
    printf "  ${GREEN}✓${NC} P10k instant prompt cache removed\n"; ((removed++))
  fi

  if [[ $removed -eq 0 ]]; then
    printf "\n${YELLOW}Nothing to remove — zsh_profile was not installed.${NC}\n"
  else
    printf "\n${GREEN}Uninstall complete (${removed} items cleaned).${NC}\n"
    printf "Packages (zsh, git, eza, fzf, zoxide) and OMZ/P10k are preserved.\n"
  fi
}

# ─── Menu ────────────────────────────────────────────────────────────────────

show_menu() {
  echo ""
  printf "${BOLD}${CYAN}╔══════════════════════════════════════════╗${NC}\n"
  printf "${BOLD}${CYAN}║        Zsh Profile — Fedora v3.0        ║${NC}\n"
  printf "${BOLD}${CYAN}╠══════════════════════════════════════════╣${NC}\n"
  printf "${BOLD}${CYAN}║                                          ║${NC}\n"
  printf "${BOLD}${CYAN}║  ${GREEN}[1] Install${NC}                               ${BOLD}${CYAN}║${NC}\n"
  printf "${BOLD}${CYAN}║  ${GREEN}[2] Quick Install (auto, no prompts)${NC}      ${BOLD}${CYAN}║${NC}\n"
  printf "${BOLD}${CYAN}║  ${RED}[3] Uninstall${NC}                             ${BOLD}${CYAN}║${NC}\n"
  printf "${BOLD}${CYAN}║  [q] Quit${NC}                                  ${BOLD}${CYAN}║${NC}\n"
  printf "${BOLD}${CYAN}║                                          ║${NC}\n"
  printf "${BOLD}${CYAN}╚══════════════════════════════════════════╝${NC}\n"
  printf "\n${BOLD}Choose [1-3/q]:${NC} "
}

# ─── Main ────────────────────────────────────────────────────────────────────

main() {
  # Handle direct flags (non-interactive)
  case "${1:-}" in
    --install)
      do_quick_install
      exit 0 ;;
    --uninstall)
      do_uninstall
      exit 0 ;;
  esac

  # Interactive mode
  while true; do
    show_menu
    choice=$(read_choice)
    echo ""

    case "$choice" in
      1)
        printf "${BOLD}${GREEN}▶ Install${NC}\n\n"
        printf "This will:\n"
        printf "  • Install zsh, git, eza, fzf, zoxide (via package manager)\n"
        printf "  • Install Oh My Zsh framework\n"
        printf "  • Clone Powerlevel10k theme\n"
        printf "  • Install optional plugins (autosuggestions, syntax-highlighting, zsh-defer)\n"
        if [[ -n "$REPO_DIR" ]]; then
          printf "  • Symlink ~/.zshrc and ~/.zsh_modules\n"
        fi
        printf "\n"

        if [[ -t 0 ]]; then
          printf "${BOLD}Proceed? [Y/n]:${NC} "
          confirm=$(read_choice)
        else
          printf "${BOLD}Proceed? [Y/n]:${NC} "
          confirm=$(read_choice)
        fi

        if [[ "$confirm" =~ ^[nN] ]]; then
          printf "${YELLOW}Cancelled.${NC}\n"; continue
        fi

        echo ""
        do_quick_install

        printf "\n${GREEN}${BOLD}Done!${NC}\n"
        printf "Restart your terminal or run: ${YELLOW}source ~/.zshrc${NC}\n"
        if [[ -z "$REPO_DIR" ]]; then
          printf "${YELLOW}Note: Running via curl — symlinks not possible.${NC}\n"
          printf "Clone the repo and run locally to symlink:\n"
          printf "  git clone https://github.com/andersonbosa/zsh_profile.git ~/zsh_profile\n"
          printf "  cd ~/zsh_profile && ./install.sh --install\n"
        fi
        break
        ;;
      2)
        printf "${BOLD}${GREEN}▶ Quick Install${NC}\n\n"
        do_quick_install
        printf "\n${GREEN}${BOLD}Done!${NC} Restart your terminal or: ${YELLOW}source ~/.zshrc${NC}\n"
        if [[ -z "$REPO_DIR" ]]; then
          printf "${YELLOW}Note: Running via curl — symlinks not possible.${NC}\n"
          printf "Clone and run locally:\n"
          printf "  git clone https://github.com/andersonbosa/zsh_profile.git ~/zsh_profile\n"
          printf "  cd ~/zsh_profile && ./install.sh --install\n"
        fi
        break
        ;;
      3)
        printf "${BOLD}${RED}▶ Uninstall${NC}\n\n"
        printf "This removes symlinks, bytecode, and cache files.\n"
        printf "It does ${BOLD}NOT${NC} remove installed packages or Oh My Zsh.\n\n"

        if [[ -t 0 ]]; then
          printf "${BOLD}Proceed? [y/N]:${NC} "
          confirm=$(read_choice)
        else
          printf "${BOLD}Proceed? [y/N]:${NC} "
          confirm=$(read_choice)
        fi

        if [[ ! "$confirm" =~ ^[yY] ]]; then
          printf "${YELLOW}Cancelled.${NC}\n"; continue
        fi

        echo ""
        do_uninstall
        break
        ;;
      q|Q)
        printf "${YELLOW}Quit.${NC}\n"; break ;;
      *)
        printf "${RED}Invalid option — choose 1, 2, 3, or q${NC}\n"; sleep 1 ;;
    esac
  done
}

main "${@}"
