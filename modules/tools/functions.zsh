# ==============================================================================
# Navigation & File Functions
# ==============================================================================

# up [n]: go up n directory levels (default: 1)
# up 3 = cd ../../..  (one call, no chaining needed)
up() {
  local n=${1:-1}
  local path=""
  for ((i=0; i<n; i++)); do path+="../"; done
  cd "$path" || return 1
}

# mkcd <dir>: create directory and cd into it atomically
# mkdir -p: create parent directories if they don't exist
# --: end option parsing (safe with directory names starting with -)
# [[:cntrl:]] regex blocks control characters in directory names
mkcd() {
  [[ -z "$1" ]] && { printf 'Usage: mkcd <directory>\n' >&2; return 1; }
  [[ "$1" =~ [[:cntrl:]] ]] && { printf 'Invalid name\n' >&2; return 1; }
  mkdir -p -- "$1" && cd -- "$1"
}

# nf <file>: create an empty file and confirm via stdout
# touch --: safe with filenames starting with -
# Validates file name has no control characters before touching
nf() {
  [[ -z "$1" ]] && { printf 'Usage: nf <file>\n' >&2; return 1; }
  [[ "$1" =~ [[:cntrl:]] ]] && { printf 'Invalid name\n' >&2; return 1; }
  touch -- "$1" && printf 'Created "%s" in %s\n' "$1" "$(pwd)"
}

# ==============================================================================
# Git Functions
# ==============================================================================

# gcom "message": stage all changes and commit with message
# git rev-parse --git-dir: checks if we're inside a git repo
# git status --porcelain: returns empty string if working tree is clean
# Fails on clean repo (no empty commits) — requires changes to exist
gcom() {
  [[ -z "$1" ]] && { printf 'Usage: gcom "message"\n' >&2; return 1; }
  git rev-parse --git-dir &>/dev/null || { printf 'Not a Git repository\n' >&2; return 1; }

  if [[ -z $(git status --porcelain) ]]; then
    printf 'Working tree clean — nothing to commit.\n' >&2
    return 1
  fi

  git add . && git commit -m "$1"
}

# lazyg "message": commit all changes, then optionally push to origin
# Flow: gcom → prompt for push confirmation with 10s timeout
# read -t 10: timeout after 10 seconds (no push if idle)
# read -r: don't interpret backslashes as escape sequences
# Non-interactive sessions (piped stdin): automatically skip push
lazyg() {
  [[ -z "$1" ]] && { printf 'Usage: lazyg "message"\n' >&2; return 1; }

  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
    printf 'Not a Git repository\n' >&2
    return 1
  }

  if [[ "$branch" == "HEAD" ]]; then
    printf 'Detached HEAD — push skipped. Create or switch to a branch first.\n' >&2
    return 1
  fi

  gcom "$1" || return 1

  [[ ! -t 0 ]] && { printf 'Non-interactive session: push skipped\n' >&2; return 1; }

  read -r -t 10 'confirm?Push to origin/'"$branch"'? [y/N] ' || {
    printf '\nTimeout: push skipped\n' >&2
    return 1
  }

  if [[ "$confirm" =~ ^[sSyY]$ ]]; then
    git push origin "$branch" && printf 'Pushed!\n'
  else
    printf 'Push skipped — commit kept locally.\n'
  fi
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# sedi "s/old/new/g" <file>: safe sed with automatic timestamped backup
# mktemp: secure temp file (avoids predictable names in shared /tmp)
# trap INT TERM: cleanup temp file on Ctrl+C or kill signal
# cp + sed + mv: atomic pattern — backup first, then replace via temp file
# trap - INT TERM: reset trap after successful operation
sedi() {
  [[ "$#" -ne 2 ]] && { printf 'Usage: sedi "s/old/new/g" <file>\n' >&2; return 1; }
  [[ ! -f "$2" ]] && { printf 'File not found: %s\n' "$2" >&2; return 1; }

  local pattern="$1" file="$2"
  local backup="${file}.bak.$(date +%Y%m%d%H%M%S)"
  local tmp=$(mktemp) || return 1
  trap "rm -f '$tmp'" INT TERM

  cp "$file" "$backup" && sed "$pattern" "$file" > "$tmp" && mv "$tmp" "$file"
  local rc=$?
  trap - INT TERM

  [[ $rc -eq 0 ]] && printf 'Modified. Backup: %s\n' "$backup"
  return $rc
}

# extract <archive>: auto-detect archive format and extract
# Supports: tar.bz2, tar.gz, tar.xz, tar.zst, bz2, gz, xz, zst, tar, zip, rar, 7z
# Uses case/esac pattern matching on file extension
# Each extraction command runs natively (no external flags needed)
extract() {
  [[ -z "$1" || ! -f "$1" ]] && { printf 'Usage: extract <archive>\n' >&2; return 1; }

  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar.zst)        tar --zstd -xf "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.xz)             unxz "$1" ;;
    *.zst)            unzstd "$1" ;;
    *.tar)            tar xf "$1" ;;
    *.zip)            unzip "$1" ;;
    *.rar)            unrar x "$1" ;;
    *.7z)             7z x "$1" ;;
    *)                printf 'Unsupported format: %s\n' "$1" >&2; return 1 ;;
  esac || { printf 'Extraction failed: %s\n' "$1" >&2; return 1; }

  printf 'Extracted: %s\n' "$1"
}

# bk <file>: create a timestamped backup of a file
# Backup format: <filename>.bak.YYYYMMDD_HHMMSS
# Only works on regular files (validates with [[ -f ]])
bk() {
  [[ -z "$1" || ! -f "$1" ]] && { printf 'Usage: bk <file>\n' >&2; return 1; }
  local backup="${1}.bak.$(date +%Y%m%d_%H%M%S)"
  cp "$1" "$backup" && printf 'Backup: %s\n' "$backup"
}

# port [number]: check which process is using a port (or list all)
# ss -tulpn: t=tcp, u=udp, l=listening, p=process, n=numeric (no DNS lookup)
# grep -w: word-boundary match — "80" won't match "8080"
# Without arguments: shows full ss -tulpn output
port() {
  if [[ -n "$1" ]]; then
    ss -tulpn | grep -w ":$1" || printf 'Port %s is free\n' "$1"
  else
    ss -tulpn
  fi
}
