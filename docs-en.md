# Technical Overview

![Zsh](https://img.shields.io/badge/Shell-Zsh-f15a24?logo=zsh&logoColor=white)
![Fedora](https://img.shields.io/badge/OS-Fedora-294172?logo=fedora&logoColor=white)
![Oh My Zsh](https://img.shields.io/badge/Framework-Oh%20My%20Zsh-000000?logo=github&logoColor=white)
![Powerlevel10k](https://img.shields.io/badge/Theme-Powerlevel10k-blue?logo=github&logoColor=white)

In-depth technical documentation for the Zsh configuration optimized for Fedora Linux.

> **📝 Note:** AI assisted in code generation, refactoring, documentation, and review of this project.

---

## 🧭 Quick Navigation

**Documentation:**
- [← Back to Main README](readme-en.md)

**Sections in this document:**
- [↗️ .zshrc Architecture](#zshrc-architecture)
- [↗️ Cache System](#cache-system)
- [↗️ Security & Robustness](#security--robustness)
- [↗️ Fedora Compatibility](#fedora-compatibility)
- [↗️ Internal Functions](#internal-functions)
- [↗️ Relevant Points Found](#relevant-points-found)
- [↗️ AI Usage](#ai-usage)

---

## .zshrc Architecture

The loading order was carefully planned to maximize performance and ensure resolved dependencies:

### 1. Boot Timer (Lines 16-17)
```zsh
zmodload zsh/datetime
typeset -g _zshrc_start_s=$EPOCHREALTIME
```
Loaded immediately after Instant Prompt to capture real start time with millisecond precision.

### 2. Instant Prompt (Lines 9-11)
```zsh
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
```
**Critical positioning:** Must be the first thing in the file to eliminate initial visual delay.

### 3. Path Deduplication (Line 22)
```zsh
typeset -U path PATH fpath FPATH
```
Prevents directory duplication in path variables using the `-U` (unique) flag.

### 4. Custom PATH (Line 27)
```zsh
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.spicetify:$PATH"
```
Added **before** the plugin cache so custom tools are available during build.

### 5. Oh My Zsh Base (Lines 32-33)
```zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
```
Theme intentionally empty — Powerlevel10k is loaded manually at the end.

### 6. Zsh Options (Lines 38-44)
```zsh
setopt AUTO_CD EXTENDED_GLOB
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_REDUCE_BLANKS SHARE_HISTORY

HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
```
- `AUTO_CD`: Navigate without typing `cd`
- `EXTENDED_GLOB`: Enable advanced glob patterns
- `HIST_IGNORE_ALL_DUPS`: Remove duplicates from history
- `HIST_SAVE_NO_DUPS`: Don't save duplicates
- `INC_APPEND_HISTORY`: Save history incrementally
- `HIST_EXPIRE_DUPS_FIRST`: Remove duplicates first when hitting HISTSIZE
- `HIST_REDUCE_BLANKS`: Remove extra spaces from commands
- `SHARE_HISTORY`: Share history between concurrent sessions

### 7. History Security Filter (Lines 49-53)
```zsh
zshaddhistory() {
  local upper="${1:u}"
  [[ "$upper" =~ (TOKEN|SECRET|PASSWORD|PASSWD|API_KEY|PRIVATE_KEY|CREDENTIAL|ACCESS_KEY)[[:space:]]*= ]] && return 1
  return 0
}
```
Hook that intercepts commands before saving to history. Converts to uppercase before comparing, ensuring case-insensitive filtering of credentials.

### 8. Plugin Cache System (Lines 57-101)
Executed **before** Oh My Zsh so plugins are ready when needed.

### 9. Oh My Zsh Plugins (Lines 104-116)
```zsh
plugins=(git history)

# If zsh-defer is available, heavy plugins are loaded deferred
if [[ ! -f "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-defer/zsh-defer.plugin.zsh" ]]; then
  [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions" ]] && \
    plugins+=(zsh-autosuggestions)
  [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting" ]] && \
    plugins+=(zsh-syntax-highlighting)
fi

source "$ZSH/oh-my-zsh.sh"
```
Conditional plugins based on directory existence. When `zsh-defer` is available, heavy plugins are excluded from the array and loaded deferred instead, preventing double-loading.

### 10. Lazy Loading (Lines 118-128)
Deferred loading via `zsh-defer` for heavy plugins (optional).

### 11. Aliases (Lines 133-155)
Divided into categories: eza, grep, navigation.

### 12. Functions (Lines 158-280)
Utility implementations for Git, files, and system.

### 13. Optional Local Configuration (Line 292)
```zsh
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```
Allows personal overrides without modifying the main `.zshrc`.

### 14. Powerlevel10k Theme (Lines 297-303)
Loaded at the **end** as per official P10K documentation.

### 15. Bytecode Compilation (Lines 308-310)
```zsh
if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  zcompile ~/.zshrc &>/dev/null &!
fi
```
Asynchronous background compilation if `.zshrc` is newer than `.zshrc.zwc`.

### 16. Boot Timer Final (Lines 315-326)
Calculation and exposure of load time via `zshrc-time` function.

---

## Cache System

### Architecture

The cache is stored at `${XDG_CACHE_HOME:-$HOME/.cache}/zsh_plugins_init.zsh`.

### Fingerprint Generation

```zsh
_zsh_gen_fingerprint() {
  local fp="" tool path_val
  for tool in "${_TOOLS_WATCHED[@]}"; do
    path_val=$(command -v "$tool" 2>/dev/null || echo "missing")
    fp+="${tool}=${path_val};"
  done
  print -n "$fp" | cksum | cut -d' ' -f1
}
```

**Monitored tools:**
- `zoxide`
- `fzf`

The fingerprint is a CKSUM hash concatenating paths of each tool. Any path change invalidates the cache.

### Atomic Build

```zsh
_zsh_build_plugin_cache() {
  local tmp=$(mktemp) || return 1
  trap "rm -f '$tmp'" INT TERM
  printf '# zsh_plugin_cache fingerprint: %s\n' "$(_zsh_gen_fingerprint)" > "$tmp"

  # Generate cache content...

  mv "$tmp" "$_PLUGIN_CACHE"
}
```

**Advantages of atomic write:**
1. `mktemp` creates file in `/tmp` (secure filesystem)
2. `trap` ensures cleanup on interruption
3. Content is fully written before moving
4. `mv` is atomic on the same filesystem
5. Prevents corrupted cache if shell is interrupted

### Validation & Rebuild

```zsh
if [[ -f "$_PLUGIN_CACHE" ]]; then
  _zsh_current_fp=$(_zsh_gen_fingerprint)
  _zsh_cached_fp=$(sed -n '1s/# zsh_plugin_cache fingerprint: //p' "$_PLUGIN_CACHE")
  [[ "$_zsh_current_fp" != "$_zsh_cached_fp" ]] && _zsh_build_plugin_cache
else
  _zsh_build_plugin_cache
fi
```

**Flow:**
1. Check cache existence
2. Extract stored fingerprint (first line)
3. Compare with current fingerprint
4. Rebuild if different or non-existent

### Generated Content

Example of generated cache:
```zsh
# zsh_plugin_cache fingerprint: 1234567890

# --- zoxide ---
__zoxide_hook() { ... }

# --- fzf ---
source /usr/share/fzf/shell/key-bindings.zsh
source /usr/share/zsh/site-functions/_fzf
```

### Performance Gain

| Operation | Without Cache | With Cache | Savings |
|-----------|--------------|------------|---------|
| `zoxide init zsh` | ~50ms | 0ms (already executed) | 50ms |
| `fzf key-bindings` | ~30ms | 0ms (already executed) | 30ms |
| **Estimated total** | **~80ms** | **~5ms** | **~75ms** |

---

## Security & Robustness

### mktemp for Temporary Files

Functions `sedi` and `_zsh_build_plugin_cache` use `mktemp` with signal traps:
```zsh
local tmp=$(mktemp) || return 1
trap "rm -f '$tmp'" INT TERM
```

**Benefits:**
- Guaranteed unique name
- Restricted permissions (600)
- Prevents race conditions
- Signal traps ensure cleanup on interruption
- Prevents accidental overwriting

### Atomic Move

```zsh
mv "$tmp" "$_PLUGIN_CACHE"
```

Ensures the cache is never in a partial state. Either complete or non-existent.

### Parameter Validation

Function `mkcd`:
```zsh
mkcd() {
  [[ -z "$1" ]] && { printf '❌ Uso: mkcd <diretório>\n' >&2; return 1; }
  [[ "$1" =~ [[:cntrl:]] ]] && { printf '❌ Nome inválido\n' >&2; return 1; }
  mkdir -p -- "$1" && cd -- "$1"
}
```

**Validations:**
1. Required parameter
2. Rejects control characters (injection prevention)
3. Uses `--` to separate options from arguments (prevents interpreting `-` as a flag)

### Command Fallback

Existence check before creating aliases:
```zsh
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  # ...
fi
```

If `eza` doesn't exist, aliases are not created and system `ls` remains.

### Use of `command sudo`

Function `sudo`:
```zsh
sudo() {
  if [[ "$1" == "!!" ]]; then
    local last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')
    # ... safety checks
    command sudo zsh -c "$last_cmd"
  else
    command sudo "$@"
  fi
}
```

**Importance of `command`:**
- Calls the original system `sudo`
- Avoids infinite recursion
- Allows functional extension while maintaining base behavior

### Dangerous Command Protection

```zsh
if [[ "$last_cmd" =~ ^(sudo|rm[[:space:]]+-rf[[:space:]]+/|mkfs|dd[[:space:]]+of=|chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/) ]]; then
  printf '❌ Comando bloqueado por segurança: %s\n' "$last_cmd" >&2
  return 1
fi
```

**Blocked patterns in `sudo !!`:**
- Recursive `sudo`
- `rm -rf /` (root deletion)
- `mkfs` (formatting)
- `dd of=` (direct disk writing)
- `chmod -R 777 /` (insecure global permission)

---

## Fedora Compatibility

### DNF as Default Manager

Cleanup aliases use `dnf`:
```zsh
alias dnf-clean='sudo dnf autoremove -y && sudo dnf clean all && printf "✅ DNF limpo\n"'
```

**Commands executed:**
1. `dnf autoremove -y`: Remove orphaned dependencies
2. `dnf clean all`: Clean metadata and package cache

### Integrated Flatpak

```zsh
alias flatpak-clean='flatpak uninstall --unused -y && printf "✅ Flatpak limpo\n"'
```

Removes Flatpak runtimes not used by any application.

### Typical Fedora Paths

FZF on Fedora is at:
```zsh
[[ -f /usr/share/fzf/shell/key-bindings.zsh ]] && \
  printf 'source /usr/share/fzf/shell/key-bindings.zsh\n' >> "$tmp"
```

Different from other distros that may use `/usr/share/doc/fzf/examples/`.

---

## Internal Functions

### `dtop`
```zsh
alias dtop='cd ~/Desktop'
```
- Quick navigation to Desktop via alias

### `up`
```zsh
up() {
  local n=${1:-1}
  local path=""
  for ((i=0; i<n; i++)); do path+="../"; done
  cd "$path" || return 1
}
```
- Parametric directory climbing
- `up` goes up 1 level, `up 3` goes up 3 levels
- Replaces the old `up/up2/up3/up4` aliases

### `mkcd`
```zsh
mkcd() {
  [[ -z "$1" ]] && { printf '❌ Uso: mkcd <diretório>\n' >&2; return 1; }
  [[ "$1" =~ [[:cntrl:]] ]] && { printf '❌ Nome inválido\n' >&2; return 1; }
  mkdir -p -- "$1" && cd -- "$1"
}
```
- Creates complete structure (`-p`)
- Validates input against injection
- Enters the directory after creation

### `nf`
```zsh
nf() {
  [[ -z "$1" ]] && { printf '❌ Uso: nf <arquivo>\n' >&2; return 1; }
  [[ "$1" =~ [[:cntrl:]] ]] && { printf '❌ Nome inválido\n' >&2; return 1; }
  touch -- "$1" && printf '✅ Arquivo "%s" criado em %s\n' "$1" "$(pwd)"
}
```
- Wrapper for `touch` with visual feedback
- Validates against control characters
- Uses `--` to separate options from arguments
- Shows absolute creation path

### `gcom`
```zsh
gcom() {
  [[ -z "$1" ]] && { printf '❌ Uso: gcom "mensagem"\n' >&2; return 1; }
  git rev-parse --git-dir &>/dev/null || { printf '❌ Não é um repositório Git\n' >&2; return 1; }

  if [[ -z $(git status --porcelain) ]]; then
    printf '⚠️ Working tree limpo. Nada para commitar.\n' >&2
    return 1
  fi

  git add . && git commit -m "$1"
}
```
- Validates Git context
- Checks for pending changes via `--porcelain` (parseable output)
- Performs atomic `add .` + `commit`

### `lazyg`
```zsh
lazyg() {
  [[ -z "$1" ]] && { printf '❌ Uso: lazyg "mensagem"\n' >&2; return 1; }

  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
    printf '❌ Não é um repositório Git\n' >&2
    return 1
  }

  gcom "$1" || return 1

  [[ ! -t 0 ]] && { printf '⚠️ Sessão não interativa: push cancelado\n' >&2; return 1; }

  read -r -t 10 'confirm?🚀 Enviar para origin/'"$branch"'? [s/N] ' || {
    printf '\n⏰ Timeout: push cancelado\n' >&2
    return 1
  }

  if [[ "$confirm" =~ ^[sSyY]$ ]]; then
    git push origin "$branch" && printf '✅ Push realizado!\n'
  else
    printf '⚠️ Push cancelado. Commit local mantido.\n'
  fi
}
```

**Detailed flow:**
1. Captures current branch
2. Executes `gcom` internally
3. Checks if stdin is a terminal (`-t 0`)
4. Reads confirmation with 10s timeout
5. Conditional push based on `[sSyY]`

### `sudo` (override)
```zsh
sudo() {
  if [[ "$1" == "!!" ]]; then
    local last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')

    if [[ "$last_cmd" =~ ^(sudo|rm[[:space:]]+-rf[[:space:]]+/|mkfs|dd[[:space:]]+of=|chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/) ]]; then
      printf '❌ Comando bloqueado por segurança: %s\n' "$last_cmd" >&2
      return 1
    fi

    printf 'Executando como root: %s\n' "$last_cmd"
    command sudo zsh -c "$last_cmd"
  else
    command sudo "$@"
  fi
}
```

**`!!` mechanism:**
- `fc -ln -1`: Last command from history
- `sed`: Removes leading spaces
- Blocking regex prevents dangerous commands
- `zsh -c`: Executes in root subshell

### `sedi`
```zsh
sedi() {
  [[ "$#" -ne 2 ]] && { printf 'Uso: sedi "s/old/new/g" <arquivo>\n' >&2; return 1; }
  [[ ! -f "$2" ]] && { printf '❌ Arquivo não encontrado: %s\n' "$2" >&2; return 1; }

  local pattern="$1" file="$2"
  local backup="${file}.bak.$(date +%Y%m%d%H%M%S)"
  local tmp=$(mktemp) || return 1
  trap "rm -f '$tmp'" INT TERM

  cp "$file" "$backup" && sed "$pattern" "$file" > "$tmp" && mv "$tmp" "$file" && \
    printf '✅ Modificado. Backup: %s\n' "$backup"
  trap - INT TERM
}
```

**Safe pipeline:**
1. Validates arguments (exactly 2)
2. Checks file existence
3. Creates timestamped backup
4. Applies `sed` to temporary file
5. Signal trap ensures temp file cleanup
6. Atomic move to replace original

### `extract`
```zsh
extract() {
  [[ -z "$1" || ! -f "$1" ]] && { printf '❌ Uso: extract <arquivo>\n' >&2; return 1; }

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
    *)                printf '❌ Formato não suportado\n' >&2; return 1 ;;
  esac || { printf '❌ Falha ao extrair: %s\n' "$1" >&2; return 1; }

  printf '✅ Extraído: %s\n' "$1"
}
```

**Technical details:**
- `xj`: tar + bzip2
- `xz`: tar + gzip
- `xJ`: tar + xz (uppercase)
- `--zstd`: tar + zstd (Fedora default format)
- Support for standalone `.xz`, `.zst`
- Checks command return value and reports failure
- Fallback for unknown format

### `bk`
```zsh
bk() {
  [[ -z "$1" || ! -f "$1" ]] && { printf '❌ Uso: bk <arquivo>\n' >&2; return 1; }
  local backup="${1}.bak.$(date +%Y%m%d_%H%M%S)"
  cp "$1" "$backup" && printf '✅ Backup: %s\n' "$backup"
}
```
- Simple backup with timestamp
- Format: `file.bak.YYYYMMDD_HHMMSS`

### `port`
```zsh
port() {
  if [[ -n "$1" ]]; then
    ss -tulpn | grep -w ":$1" || printf '⚠️ Porta %s livre\n' "$1"
  else
    ss -tulpn
  fi
}
```

**`ss` flags:**
- `-t`: TCP
- `-u`: UDP
- `-l`: Listening
- `-p`: Process
- `-n`: Numeric (no DNS)
- `grep -w`: Word match to avoid false positives (e.g., port 8 matching 80)

### `zshrc-time`
```zsh
zshrc-time() {
  local ms=$_zshrc_load_ms
  if   (( ms < 150 )); then printf '⚡ .zshrc: \e[32m%dms\e[0m (excelente)\n' "$ms"
  elif (( ms < 200 )); then printf '⚡ .zshrc: \e[32m%dms\e[0m (bom)\n' "$ms"
  elif (( ms < 500 )); then printf '⚡ .zshrc: \e[33m%dms\e[0m (aceitável)\n' "$ms"
  else                      printf '🐢 .zshrc: \e[31m%dms\e[0m (lento)\n' "$ms"
  fi
}
```

**ANSI codes:**
- `\e[32m`: Green (excellent/good)
- `\e[33m`: Yellow (acceptable)
- `\e[31m`: Red (slow)
- `\e[0m`: Reset

---

## Relevant Points Found

### ✅ Good Decisions

1. **Optimized loading order**: Instant Prompt first, theme at the end
2. **Intelligent cache with fingerprint**: Detects changes automatically
3. **Atomic writing**: Prevents cache corruption
4. **Graceful fallback**: Checks command existence before using
5. **History security**: Filters credentials automatically (case-insensitive)
6. **Asynchronous bytecode compilation**: Doesn't block shell
7. **Optional local configuration**: Allows personalization without forking
8. **Plugin double-load prevention**: zsh-defer aware plugin loading

### ⚠️ Minor Redundancies

1. **Double Git check in `lazyg`**: `gcom` already validates, but `lazyg` also captures errors separately (justifiable for specific messaging)

### 🔒 Minor Risks

1. **`gcom` uses `git add .`**: Adds **all** files, including possibly accidentally unignored ones
   - Mitigation: User should review `git status` beforehand

2. **`sedi` doesn't validate regex**: Invalid pattern could corrupt file
   - Mitigation: Backup is created before applying

3. **`sudo !!` simple parsing**: Regex may not cover all edge cases of dangerous commands
   - Mitigation: List covers the most critical cases

---

## AI Usage

This project was developed with AI assistance across multiple stages:
- **Code generation and refactoring**: Initial implementation and optimizations
- **Static code analysis**: Pattern and structure identification
- **Technical review**: Concept and implementation validation
- **Structural organization**: Logical information hierarchization
- **Explanatory clarity**: Simplification of complex concepts
- **Best practice identification**: Recognition of recommended patterns
- **Opportunity detection**: Suggestion of potential improvements

AI served as a support tool to accelerate development, improve code quality, and ensure documentation that is precise and faithful to the actual implementation.

---

[← Back to Top](#technical-overview) | [← Main README →](readme-en.md)