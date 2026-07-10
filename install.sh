#!/usr/bin/env bash
# shellcheck disable=SC2059
# ==============================================================================
# Zsh Profile — Interactive Installer
#
# One command for everything:
#   curl -fsSL https://raw.githubusercontent.com/AndersonTavares0/zsh_profile/main/install.sh | bash
#
# The script detects piped input and presents an interactive menu via /dev/tty.
# Choose: [1] Install  [2] Uninstall  [3] Quick Install (skip prompts)  [q] Quit
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh_profile"
STATE_FILE="$STATE_DIR/install.state"

# Resolve repo directory: when piped via curl, clone to ~/.zsh_profile_repo
REPO_DIR=""
REPO_URL="https://github.com/AndersonTavares0/zsh_profile.git"
REPO_CLONE_DIR="$HOME/.zsh_profile_repo"

if [[ "${BASH_SOURCE[0]:-}" != "" && "${BASH_SOURCE[0]}" != "bash" ]]; then
  REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

ensure_repo() {
  if [[ -n "$REPO_DIR" ]]; then
    return 0
  fi
  if [[ -d "$REPO_CLONE_DIR/.git" ]]; then
    printf "${CYAN}Updating existing clone...${NC}\n"
    if ! git -C "$REPO_CLONE_DIR" pull --ff-only 2>/dev/null; then
      printf "${YELLOW}Warning: could not update repo clone — using existing copy${NC}\n"
    fi
    REPO_DIR="$REPO_CLONE_DIR"
    return 0
  fi
  printf "${CYAN}Cloning repository...${NC}\n"
  git clone --depth=1 "$REPO_URL" "$REPO_CLONE_DIR"
  REPO_DIR="$REPO_CLONE_DIR"
}

# ─── Utility functions ───────────────────────────────────────────────────────

detect_pkg_manager() {
  if command -v dnf &>/dev/null; then echo "dnf"
  elif command -v apt &>/dev/null; then echo "apt"
  elif command -v pacman &>/dev/null; then echo "pacman"
  elif command -v zypper &>/dev/null; then echo "zypper"
  else echo "unknown"; fi
}

write_install_state() {
  mkdir -p "$STATE_DIR"
  printf 'installed_at=%s\n' "$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z')" > "$STATE_FILE"
  printf 'repo_dir=%s\n' "$REPO_DIR" >> "$STATE_FILE"
  if [[ -d "$REPO_DIR/.git" ]]; then
    printf 'commit=%s\n' "$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo 'unknown')" >> "$STATE_FILE"
  fi
}

remove_install_state() {
  if [[ -f "$STATE_FILE" ]]; then
    rm -f "$STATE_FILE"
    rmdir "$STATE_DIR" 2>/dev/null || true
  fi
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

do_install_required() {
  local pkg="$1"
  printf "${CYAN}Installing required packages (zsh, git)...${NC}\n"
  case "$pkg" in
    dnf)    sudo dnf install -y zsh git ;;
    apt)    sudo apt update && sudo apt install -y zsh git ;;
    pacman) sudo pacman -S --noconfirm zsh git ;;
    zypper) sudo zypper install -y zsh git ;;
    *)      printf "${RED}Unknown package manager. Install zsh and git manually.${NC}\n"; return 1 ;;
  esac
  printf "${GREEN}Required packages installed.${NC}\n"
}

do_install_optional() {
  local pkg="$1"
  local tools="eza fzf zoxide"
  printf "${CYAN}Installing optional tools (${tools})...${NC}\n"
  case "$pkg" in
    dnf)    sudo dnf install -y eza fzf zoxide || printf "${YELLOW}Warning: some optional tools could not be installed${NC}\n" ;;
    apt)    sudo apt install -y eza fzf zoxide 2>/dev/null || printf "${YELLOW}Warning: some optional tools could not be installed${NC}\n" ;;
    pacman) sudo pacman -S --noconfirm eza fzf zoxide 2>/dev/null || printf "${YELLOW}Warning: some optional tools could not be installed${NC}\n" ;;
    zypper) sudo zypper install -y eza fzf zoxide 2>/dev/null || printf "${YELLOW}Warning: some optional tools could not be installed${NC}\n" ;;
    *)      printf "${YELLOW}Unknown package manager — skipping optional tools${NC}\n" ;;
  esac
}

do_install_omz() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    printf "${YELLOW}Oh My Zsh already installed.${NC}\n"; return 0
  fi
  if ! command -v curl &>/dev/null; then
    printf "${RED}curl is required to install Oh My Zsh.${NC}\n"; return 1
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
  local plugin_names=(
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-defer
  )
  local plugin_urls=(
    "https://github.com/zsh-users/zsh-autosuggestions"
    "https://github.com/zsh-users/zsh-syntax-highlighting"
    "https://github.com/romkatv/zsh-defer"
  )
  local i
  for ((i=0; i<${#plugin_names[@]}; i++)); do
    local name="${plugin_names[i]}"
    local url="${plugin_urls[i]}"
    if [[ -d "$base/$name" ]]; then
      printf "${YELLOW}$name already installed.${NC}\n"; continue
    fi
    printf "${CYAN}Installing $name...${NC}\n"
    git clone "$url" "$base/$name"
  done
}

do_link_config() {
  ensure_repo
  printf "${CYAN}Linking config...${NC}\n"

  # Backup existing files before symlinking (never overwrite without copy)
  for f in "$HOME/.zshrc" "$HOME/.zsh_modules"; do
    if [[ -e "$f" && ! -L "$f" ]]; then
      local bak="${f}.bak.$(date +%Y%m%d_%H%M%S)"
      if cp -r "$f" "$bak" 2>/dev/null; then
        printf "  ${YELLOW}Backup: $f → $bak${NC}\n"
      else
        printf "  ${RED}Warning: could not backup $f${NC}\n"
      fi
    fi
  done

  ln -sf "$REPO_DIR/.zshrc"       "$HOME/.zshrc"
  ln -sf "$REPO_DIR/modules"     "$HOME/.zsh_modules"
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
  local pkg
  pkg=$(detect_pkg_manager)
  printf "${CYAN}Package manager: ${BOLD}$pkg${NC}\n"
  do_install_required "$pkg"
  do_install_optional "$pkg"
  do_install_omz
  do_install_p10k
  do_install_plugins
  do_link_config
  do_set_shell
  write_install_state
}

# ─── Uninstall ───────────────────────────────────────────────────────────────

do_uninstall() {
  printf "${YELLOW}Removing zsh_profile configuration...${NC}\n\n"

  local removed=0

  if [[ -L "$HOME/.zshrc" ]]; then
    rm -f "$HOME/.zshrc"
    printf "  ${GREEN}✓${NC} ~/.zshrc symlink removed\n"; removed=$((removed + 1))
  fi

  if [[ -L "$HOME/.zsh_modules" ]]; then
    rm -rf "$HOME/.zsh_modules"
    printf "  ${GREEN}✓${NC} ~/.zsh_modules symlink removed\n"; removed=$((removed + 1))
  fi

  if [[ -f "$HOME/.zshrc.zwc" ]]; then
    rm -f "$HOME/.zshrc.zwc"
    printf "  ${GREEN}✓${NC} ~/.zshrc.zwc bytecode removed\n"; removed=$((removed + 1))
  fi

  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh_plugins_init.zsh"
  if [[ -f "$cache" ]]; then
    rm -f "$cache"
    printf "  ${GREEN}✓${NC} Plugin init cache removed\n"; removed=$((removed + 1))
  fi
  if [[ -f "${cache}.zwc" ]]; then
    rm -f "${cache}.zwc"
    printf "  ${GREEN}✓${NC} Plugin cache .zwc removed\n"; removed=$((removed + 1))
  fi

  local p10k_cache="${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
  if [[ -f "$p10k_cache" ]]; then
    rm -f "$p10k_cache"
    printf "  ${GREEN}✓${NC} P10k instant prompt cache removed\n"; removed=$((removed + 1))
  fi

  if [[ $removed -eq 0 ]]; then
    printf "\n${YELLOW}Nothing to remove — zsh_profile was not installed.${NC}\n"
  else
    printf "\n${GREEN}Uninstall complete (${removed} items cleaned).${NC}\n"
    printf "Packages (zsh, git, eza, fzf, zoxide) and OMZ/P10k are preserved.\n"
    remove_install_state
  fi
}

# ─── Menu ────────────────────────────────────────────────────────────────────

show_menu() {
  echo ""
  printf "${BOLD}${CYAN}╔══════════════════════════════════════════╗${NC}\n"
  printf "${BOLD}${CYAN}║        Zsh Profile — Fedora v3.1        ║${NC}\n"
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
          printf "  • Symlink ~/.zshrc and ~/.zsh_modules\n"
        printf "\n"

        if [[ -t 0 ]]; then
          printf "%sProceed? [Y/n]:%s " "$BOLD" "$NC"
          confirm=$(read_choice)
        else
          printf "%sProceed? [Y/n]:%s " "$BOLD" "$NC"
          confirm=$(read_choice)
        fi

        if [[ "$confirm" =~ ^[nN] ]]; then
          printf "${YELLOW}Cancelled.${NC}\n"; continue
        fi

        echo ""
        do_quick_install

        printf "\n${GREEN}${BOLD}Done!${NC}\n"
        printf "Restart your terminal or run: ${YELLOW}source ~/.zshrc${NC}\n"
        break
        ;;
      2)
        printf "${BOLD}${GREEN}▶ Quick Install${NC}\n\n"
        do_quick_install
        printf "\n${GREEN}${BOLD}Done!${NC} Restart your terminal or: ${YELLOW}source ~/.zshrc${NC}\n"
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
