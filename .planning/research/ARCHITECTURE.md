# Architecture Research

**Domain:** Zsh shell configuration (dotfiles) — Fedora Optimized
**Researched:** 2026-05-10
**Confidence:** HIGH

## Standard Architecture

### System Overview

Zsh configuration follows a layered architecture defined by Zsh's own startup file contract. The shell reads files in a fixed order depending on the shell type (login, interactive, or both). On top of this, the project adds Oh My Zsh as a framework layer, Powerlevel10k for theming, and a custom plugin-cache layer for performance.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ZSH STARTUP FILE CHAIN (built-in)                 │
│  Ordered by Zsh, not configurable. Each file type has a purpose.     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────┐                                                        │
│  │ .zshenv  │── Runs for ALL zsh instances (login, interactive, non- │
│  └────┬─────┘   interactive, script). Keep minimal.                  │
│       │                                                              │
│  ┌────▼──────┐                                                       │
│  │ .zprofile  │── Runs ONLY for login shells (before .zshrc)         │
│  └────┬──────┘   Use for: X11 session vars, ssh-agent                │
│       │                                                              │
│  ┌────▼─────┐                                                        │
│  │ .zshrc    │── Runs ONLY for interactive shells. MAIN FILE.        │
│  └────┬─────┘   This is where 95% of config lives.                   │
│       │                                                              │
│  ┌────▼──────┐                                                       │
│  │ .zlogin    │── Runs ONLY for login shells (after .zshrc)          │
│  └────┬──────┘   Rarely used.                                        │
│       │                                                              │
│  ┌────▼───────┐                                                      │
│  │ .zlogout    │── Runs on exit for login shells                     │
│  └────────────┘   Cleanup hooks.                                     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                   PROJECT LAYER STACK (within .zshrc)                │
│  Ordered by load sequence — each layer depends on prior layers.      │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │  LAYER 1: BOOT TRAP                                             │ │
│  │  Powerlevel10k Instant Prompt + Boot Timer                      │ │
│  ├─────────────────────────────────────────────────────────────────┤ │
│  │  ┌─────────────────────────────────────────────────────────────┐│ │
│  │  │  LAYER 2: SHELL FOUNDATION                                  ││ │
│  │  │  PATH, setopts, history config, key bindings                ││ │
│  │  └─────────────────────────────────────────────────────────────┘│ │
│  ├─────────────────────────────────────────────────────────────────┤ │
│  │  ┌─────────────────────────────────────────────────────────────┐│ │
│  │  │  LAYER 3: TOOL CACHE                                        ││ │
│  │  │  Plugin cache (zoxide, fzf) — fingerprint-validated         ││ │
│  │  └─────────────────────────────────────────────────────────────┘│ │
│  ├─────────────────────────────────────────────────────────────────┤ │
│  │  ┌─────────────────────────────────────────────────────────────┐│ │
│  │  │  LAYER 4: OH MY ZSH + PLUGINS                              ││ │
│  │  │  OMZ framework, OMZ plugins, custom plugins                 ││ │
│  │  └─────────────────────────────────────────────────────────────┘│ │
│  ├─────────────────────────────────────────────────────────────────┤ │
│  │  ┌─────────────────────────────────────────────────────────────┐│ │
│  │  │  LAYER 5: USER CONFIG                                      ││ │
│  │  │  Aliases, functions, ~/.zshrc.local overrides               ││ │
│  │  └─────────────────────────────────────────────────────────────┘│ │
│  ├─────────────────────────────────────────────────────────────────┤ │
│  │  ┌─────────────────────────────────────────────────────────────┐│ │
│  │  │  LAYER 6: THEME + COMPILATION                              ││ │
│  │  │  P10k theme (LAST), P10k config, zcompile .zwc              ││ │
│  │  └─────────────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        EXTERNAL DEPENDENCIES                         │
│  Installed via DNF (system) or git clone (user directory).           │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │ Oh My Zsh│  │Powerlevel│  │ zoxide   │  │ fzf      │            │
│  │ (git)    │  │ 10k (git)│  │ (DNF)    │  │ (DNF)    │            │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘            │
│       │              │             │              │                  │
│       └──────────────┴─────────────┴──────────────┘                  │
│                              │                                       │
│  ┌──────────────────────────▼──────────────────────────────────────┐│
│  │                     $HOME Directory                              ││
│  │  ~/.oh-my-zsh/  ~/powerlevel10k/  ~/.zshrc  ~/.p10k.zsh         ││
│  └─────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `.zshenv` | Env vars needed by ALL Zsh instances (including scripts) | PATH exports, `ZDOTDIR`, `EDITOR`, language/locale settings |
| `.zprofile` | Login-shell-only setup (X11, desktop env, ssh-agent) | `[[ -z "$DISPLAY" ]] && startx`, `ssh-add` |
| `.zshrc` | **Main interactive shell config** — everything else | Sources config modules, plugins, aliases, functions, theme |
| `.zlogin` | Post-init login tasks (rarely used) | `motd`, session logging |
| `.zlogout` | Cleanup on exit | `clear`, session log close |
| Oh My Zsh | Framework: plugin management, compinit, theme infrastructure | `$ZSH/oh-my-zsh.sh`, `$ZSH_CUSTOM/` for overrides |
| Plugin cache | Caches `zoxide init zsh` and `fzf` key binding scripts | Fingerprint-validated cache file → sourced instead of running init |
| P10k Instant Prompt | Renders prompt skeleton before plugin loading finishes | First line of `.zshrc` — sources cached prompt frame |
| P10k Theme | Full prompt rendering engine (git status, context, dir) | Must be sourced **last** in `.zshrc` |
| Custom functions | User-defined shell functions | `mkcd`, `gcom`, `lazyg`, `sedi`, `extract`, `bk`, `port`, `zshrc-time` |
| Custom aliases | Command shortcuts | `ls`→`eza`, `ll`, `la`, `dtop`, `dnf-clean`, etc. |
| Security layer | History filter + sudo wrapper | `zshaddhistory()` hook + `sudo()` function override |
| `.zshrc.local` | User-specific overrides (not in repo) | Sourced at end of `.zshrc`, before theme |
| `.zshrc.zwc` | Bytecode-compiled `.zshrc` for faster loading | Generated by `zcompile` in background on shell start |
| `.p10k.zsh` | P10k prompt configuration (generated by wizard) | Sourced after P10k theme file |

## Recommended Project Structure

The current architecture is a **single monolithic 342-line `.zshrc`**. The community standard for maintainable Zsh configs is modular with symlink-based installation. Below is the recommended structure:

```
zsh_profile/
├── .zshrc                    # ENTRY POINT — sources module files in order
├── .zshenv                   # (optional) Env for all Zsh instances
├── .zprofile                 # (optional) Login shell init
├── .p10k.zsh                 # P10k config (generated by 'p10k configure')
│
├── zsh/                      # Modular config directory
│   ├── config/               # Zsh options and settings
│   │   ├── paths.zsh         #   PATH construction and dedup
│   │   ├── options.zsh       #   setopt calls
│   │   ├── history.zsh       #   HISTFILE, HISTSIZE, SAVEHIST
│   │   ├── bindings.zsh      #   Key bindings (bindkey)
│   │   └── completion.zsh    #   Completion options
│   │
│   ├── plugins/              # Plugin loading orchestration
│   │   ├── omz.zsh           #   Oh My ZSH config: ZSH=, ZSH_THEME=, plugins=()
│   │   ├── omz-load.zsh      #   source $ZSH/oh-my-zsh.sh
│   │   ├── cache.zsh         #   Plugin cache system (fingerprint + rebuild)
│   │   ├── defer.zsh         #   zsh-defer lazy loading (conditional)
│   │   └── heavy.zsh         #   zsh-autosuggestions + zsh-syntax-highlighting
│   │
│   ├── security/             # Security safeguards
│   │   ├── history-filter.zsh #   zshaddhistory hook
│   │   └── sudo-wrapper.zsh  #   sudo() function override
│   │
│   ├── aliases/              # Alias definitions (one file per category)
│   │   ├── eza.zsh           #   File listing aliases (ls, ll, la, l, lt)
│   │   ├── navigation.zsh    #   Directory aliases (home, docs, dtop, reload)
│   │   ├── grep.zsh          #   Color grep aliases
│   │   └── sys-clean.zsh     #   Package cleanup aliases
│   │
│   ├── functions/            # Shell functions (one file per function or group)
│   │   ├── navigation.zsh    #   up(), mkcd(), nf()
│   │   ├── git.zsh           #   gcom(), lazyg()
│   │   ├── utilities.zsh     #   sedi(), extract(), bk(), port()
│   │   └── boot-timer.zsh    #   zshrc-time() and measurement variable
│   │
│   ├── theme/                # Theme loading
│   │   ├── p10k-load.zsh     #   Source P10k theme file
│   │   └── p10k-config.zsh   #   Source ~/.p10k.zsh
│   │
│   ├── completion/           # Custom completion definitions
│   │   └── my-completions    #   (future use)
│   │
│   ├── init/                 # Boot sequencing
│   │   ├── instant-prompt.zsh #   P10k instant prompt (MUST be first)
│   │   ├── boot-timer.zsh    #   Boot timer start
│   │   ├── compile.zsh       #   Background zcompile
│   │   └── boot-timer-end.zsh #   Boot timer end + load time var
│   │
│   └── local.zsh             # Equivalent of .zshrc.local loading
│
├── bin/                      # Standalone scripts (added to PATH)
│   └── (future: brew, dnf helpers, etc.)
│
├── .planning/                # GSD project planning (already exists)
├── LICENSE                   # MIT
├── readme.md                 # User-facing docs
├── docs.md                   # Technical docs
├── AGENTS.md                 # Agent workflow docs
└── bootstrap.sh              # INSTALL SCRIPT: symlinks files to $HOME
```

### Structure Rationale

- **`zsh/config/`**: Zsh options must be set *before* plugins load. Isolating them prevents ordering bugs. Each option group (path, history, completion) is a separate file for clarity.
- **`zsh/plugins/`**: Plugin loading is the most architecturally complex part — OMZ framework must source first, then cache, then OMZ plugins, then custom plugins. The loading sequence is split across files for testability and ordering control.
- **`zsh/security/`**: Security functions (history filter, sudo wrapper) are separated because they're optional features that can be disabled without affecting the rest of the config.
- **`zsh/aliases/` vs `zsh/functions/`**: Aliases and functions have different scoping rules (aliases expand in command position only; functions are full programs). Keeping them separate follows the Zsh manual's own distinction.
- **`zsh/theme/`**: Theme loading has strict ordering constraints (MUST be last). Isolating it prevents accidental reordering.
- **`zsh/init/`**: Boot sequencing is the most timing-critical part. Separating instant prompt initialization (FIRST) from the rest prevents regressions.
- **`bootstrap.sh`**: The current `cp .zshrc ~/.zshrc` install method doesn't support modular config. A bootstrap script that creates symlinks is the community standard (thoughtbot uses `rcm`, mathiasbynens uses a shell script).

### Current vs. Recommended

| Aspect | Current (v2.3) | Recommended |
|--------|---------------|-------------|
| File structure | Single 342-line `.zshrc` | Modular `zsh/` directory with symlinks |
| Install | `cp .zshrc ~/.zshrc` | `bootstrap.sh` or `rcup` (symlinks) |
| Config splitting | Sections in one file (comments as headers) | Dedicated files per concern |
| Plugin cache | Inline in `.zshrc` | `zsh/plugins/cache.zsh` |
| Security | Inline in `.zshrc` | `zsh/security/` directory |
| Boot timer | Inline in `.zshrc` | `zsh/init/boot-timer.zsh` |
| Overrides | `~/.zshrc.local` | `~/.zshrc.local` (compatible) |

## Architectural Patterns

### Pattern 1: Plugin Cache (Fingerprint-Based)

**What:** Cache the output of expensive initialization commands (`zoxide init zsh`, fzf key bindings) so they only run when tool versions change. The cache is validated by a fingerprint — a checksum of tool binary paths.

**When to use:** Any Zsh config with third-party CLI tools that have shell init scripts. The more tools, the bigger the payoff.

**Trade-offs:**
- (+) 30-50% boot time reduction for shell starts
- (+) Transparent — user doesn't need to manage cache manually
- (+) Only rebuilds when tool paths change (version upgrades, reinstall)
- (-) Adds ~30 lines of machinery to the config
- (-) Initial shell start (cache miss) is slightly slower (runs all inits)

**Example (current implementation):**
```zsh
# zsh/plugins/cache.zsh
_PLUGIN_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh_plugins_init.zsh"
_TOOLS_WATCHED=(zoxide fzf)

_zsh_gen_fingerprint() {
  local fp="" tool path_val
  for tool in "${_TOOLS_WATCHED[@]}"; do
    path_val=$(command -v "$tool" 2>/dev/null || echo "missing")
    fp+="${tool}=${path_val};"
  done
  print -n "$fp" | cksum | cut -d' ' -f1
}

_zsh_build_plugin_cache() {
  local tmp=$(mktemp) || return 1
  printf '# fingerprint: %s\n' "$(_zsh_gen_fingerprint)" > "$tmp"
  command -v zoxide &>/dev/null && zoxide init zsh >> "$tmp" 2>/dev/null
  # ... fzf bindings ...
  mv "$tmp" "$_PLUGIN_CACHE"
}

# Validation + rebuild
if [[ -f "$_PLUGIN_CACHE" ]]; then
  cached=$(sed -n '1s/# fingerprint: //p' "$_PLUGIN_CACHE")
  [[ "$(_zsh_gen_fingerprint)" != "$cached" ]] && _zsh_build_plugin_cache
else
  _zsh_build_plugin_cache
fi
source "$_PLUGIN_CACHE"
```

### Pattern 2: Instant Prompt + Boot Timer

**What:** Powerlevel10k's Instant Prompt prints a prompt skeleton before the rest of `.zshrc` finishes loading. The boot timer measures how long the full load takes and exposes it via `zshrc-time`.

**When to use:** Always, when using Powerlevel10k. Instant Prompt is the single biggest UX improvement for Zsh startup time.

**Trade-offs:**
- (+) User can start typing immediately (50-200ms saved)
- (+) Boot timer provides feedback for optimization efforts
- (-) Instant Prompt has edge cases (see PITFALLS.md) — cursor position, output from init files

**Example:**
```zsh
# zsh/init/instant-prompt.zsh — MUST BE FIRST
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# zsh/init/boot-timer.zsh — MUST BE SECOND
zmodload zsh/datetime
typeset -g _zshrc_start_s=$EPOCHREALTIME

# zsh/functions/boot-timer.zsh — at end
typeset -g _zshrc_load_ms=$(printf "%.0f" "$(( (EPOCHREALTIME - _zshrc_start_s) * 1000 ))")
unset _zshrc_start_s

zshrc-time() { ... }
```

### Pattern 3: Security Function Wrapping (sudo)

**What:** Override Zsh's `sudo` builtin with a function that checks commands against a blocklist before executing. Does NOT affect `command sudo` (used internally to bypass the wrapper).

**When to use:** Any multi-user system or production environment. Optional for personal dev machines where you trust your own muscle memory.

**Trade-offs:**
- (+) Prevents catastrophic mistakes (`rm -rf /`, `mkfs`, `dd of=/dev/sda`)
- (+) Transparent — shows what it's executing
- (-) Adds complexity to a simple builtin
- (-) `sudo !!` pattern uses `fc -ln -1` which has edge cases with multiline commands

**Example:**
```zsh
# zsh/security/sudo-wrapper.zsh
sudo() {
  if [[ "$1" == "!!" ]]; then
    local last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')
    if [[ "$last_cmd" =~ ^(sudo|rm[[:space:]]+-rf[[:space:]]+/|mkfs|dd[[:space:]]+of=) ]]; then
      printf '❌ Blocked: %s\n' "$last_cmd" >&2
      return 1
    fi
    printf 'Executing as root: %s\n' "$last_cmd"
    command sudo zsh -c "$last_cmd"
  else
    command sudo "$@"
  fi
}
```

### Pattern 4: History Filter Hook

**What:** Use the `zshaddhistory` hook to prevent commands containing sensitive patterns from being saved to the history file. The match is case-insensitive and runs before the command is added to history.

**When to use:** Always. Protects against accidentally persisting credentials in `.zsh_history` (which is plaintext and often backed up to version control).

**Trade-offs:**
- (+) Zero overhead for non-matching commands
- (+) Simple, single function
- (-) Case-insensitive regex can be overly aggressive (e.g., keyword in error message)

### Pattern 5: Bytecode Compilation

**What:** Use Zsh's `zcompile` builtin to compile `.zshrc` to `.zwc` bytecode. Zsh automatically uses the `.zwc` file if it's newer than the source.

**When to use:** Always. The compilation is backgrounded (`&!`) so it never blocks shell startup.

**Trade-offs:**
- (+) Faster parsing on subsequent shell starts
- (+) Runs asynchronously — no startup cost
- (-) Modest gain (typically 5-15ms for a 300-line config)

## Data Flow

### Shell Startup Sequence (Critical Path)

```
Terminal opens (or exec zsh)
    │
    ▼
[1] Zsh reads /etc/zshenv (system-wide, mandatory)
    │
    ▼
[2] Zsh reads ~/.zshenv (if exists) — env vars for all shells
    │
    ▼
[3] Zsh reads ~/.zprofile (login shell only) — session init
    │
    ▼
[4] Zsh reads ~/.zshrc (interactive shell only) — MAIN CONFIG
    │
    ├── 4a: P10k Instant Prompt (source cached prompt frame)
    │     └── Renders prompt immediately → user can type
    │
    ├── 4b: Boot timer start (EPOCHREALTIME capture)
    │
    ├── 4c: Path setup (dedup + additions)
    │     └── Result: typeset -U path PATH
    │
    ├── 4d: Shell options (setopt) + history config
    │     └── Result: history behavior, glob behavior
    │
    ├── 4e: Plugin cache validation
    │     ├── Fingerprint match? → Source cache (fast)
    │     └── Fingerprint mismatch? → Rebuild → Source cache (slow)
    │
    ├── 4f: Oh My Zsh framework source ($ZSH/oh-my-zsh.sh)
    │     ├── Runs compinit (completion system)
    │     ├── Loads OMZ libraries (lib/*.zsh)
    │     └── Loads OMZ plugins from $plugins array
    │
    ├── 4g: Custom plugins (autosuggestions, syntax-highlighting)
    │     ├── zsh-defer available? → defer them (async)
    │     └── No zsh-defer? → source synchronously
    │
    ├── 4h: Aliases + functions (all user-defined)
    │     └── Result: all custom commands available
    │
    ├── 4i: ~/.zshrc.local (user overrides, if exists)
    │
    ├── 4j: P10k theme source (MUST BE LAST)
    │     ├── Source ~/powerlevel10k/powerlevel10k.zsh-theme
    │     └── Source ~/.p10k.zsh (configuration)
    │
    ├── 4k: zcompile .zshrc to .zwc (background, non-blocking)
    │
    └── 4l: Boot timer end → _zshrc_load_ms variable set
    │
    ▼
[5] Zsh reads ~/.zlogin (login shell only, rarely used)
    │
    ▼
[6] PROMPT DISPLAYED — shell is ready for input
```

### Key Data Flows

1. **Plugin version change flow:** When user runs `dnf update` and `zoxide` or `fzf` is upgraded → binary path changes → fingerprint mismatch on next shell start → cache automatically rebuilds → user sees correct new behavior without manual cache invalidation.

2. **Sudo command flow:** User types `sudo !!` → `sudo()` function catches `!!` as first arg → `fc -ln -1` retrieves last command → check against blocklist → if blocked, print error and return 1; if allowed, execute via `command sudo zsh -c "$cmd"`.

3. **History credential flow:** User types `export TOKEN=abc123` → `zshaddhistory()` hook fires → regex matches `TOKEN=` → function returns `1` → command is NOT added to history file → credential never persisted to disk.

4. **Graceful degradation flow:** Tool not installed (e.g., `eza` is missing) → alias block checks `command -v eza` → returns false → `ls`, `ll`, `la`, `l`, `lt` aliases are NOT defined → system `ls` remains available → no errors, no warnings.

## Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     SECURITY BOUNDARY                        │
│                                                              │
│  ┌─────────────────────────────┐                             │
│  │  HISTORY FILTER (Layer 2)   │                             │
│  │  Intercepts ALL commands    │                             │
│  │  before they reach .zsh_    │                             │
│  │  history                    │                             │
│  │  ┌───────────────────────┐  │                             │
│  │  │ zshaddhistory() hook  │  │                             │
│  │  │ Regex: TOKEN|SECRET|  │  │                             │
│  │  │ PASSWORD|API_KEY      │  │                             │
│  │  │ Return 1 to block     │  │                             │
│  │  └───────────────────────┘  │                             │
│  └─────────────────────────────┘                             │
│                                                              │
│  ┌─────────────────────────────┐                             │
│  │  SUDO WRAPPER (Layer 3)    │                             │
│  │  Wraps ALL sudo calls       │                             │
│  │  ┌───────────────────────┐  │                             │
│  │  │ sudo() function       │  │                             │
│  │  │ Overrides builtin     │  │                             │
│  │  │ Blocklist: rm -rf /,  │  │                             │
│  │  │ mkfs, dd of=,         │  │                             │
│  │  │ chmod -R 777 /        │  │                             │
│  │  │ Escapes via:          │  │                             │
│  │  │ command sudo          │  │                             │
│  │  └───────────────────────┘  │                             │
│  └─────────────────────────────┘                             │
│                                                              │
│  ┌─────────────────────────────┐                             │
│  │  HISTORY OPTIONS (Layer 2)  │                             │
│  │  ┌───────────────────────┐  │                             │
│  │  │ setopts:              │  │                             │
│  │  │ HIST_IGNORE_ALL_DUPS  │  │                             │
│  │  │ HIST_SAVE_NO_DUPS     │  │                             │
│  │  │ HIST_REDUCE_BLANKS    │  │                             │
│  │  └───────────────────────┘  │                             │
│  └─────────────────────────────┘                             │
└─────────────────────────────────────────────────────────────┘
```

## Scaling Considerations

### User Scale (not applicable — single user)

This is a personal shell config. There is no multi-user scaling concern.

### Configuration Scale

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-50 aliases/functions | Monolithic `.zshrc` is fine (current state) |
| 50-200 aliases/functions | Modular `zsh/` directory layout recommended (this project's target) |
| 200+ aliases/functions | Consider further splitting by domain (e.g., `zsh/aliases/git.zsh`, `zsh/aliases/docker.zsh`, `zsh/functions/git.zsh`) |
| Multiple machines | Consider `~/.zshrc.local` per-machine overrides, or a hostname-conditional include pattern |

### Scaling Priorities

1. **First bottleneck:** Single `.zshrc` file becomes unmanageable past ~400 lines. The 342-line current `.zshrc` is approaching this limit. **Fix:** Modularize into `zsh/` directory (recommended above).

2. **Second bottleneck:** Too many plugins loaded synchronously increase boot time. **Fix:** Plugin cache already addresses this for zoxide/fzf. If boot time creeps up, add `zsh-defer` for autosuggestions and syntax-highlighting.

3. **Third bottleneck:** Too many `zoxide init` or `fzf` commands (if more tools are added to the cache). **Fix:** The cache system already handles this — just add the tool to `_TOOLS_WATCHED` and its init to `_zsh_build_plugin_cache`.

## Anti-Patterns

### Anti-Pattern 1: Monolithic `.zshrc`

**What people do:** Keep adding aliases, functions, and config to a single `.zshrc` file. It grows to 500+ lines with no structure.

**Why it's wrong:** Hard to maintain, hard to selectively disable parts, hard to reason about load order, impossible to test individual components. A single misplaced sourcing line can break the entire shell.

**Do this instead:** Split into `zsh/config/`, `zsh/plugins/`, `zsh/aliases/`, `zsh/functions/` directories, each loaded by a master `.zshrc` in order. The current project (342 lines) should modularize before hitting 400 lines.

### Anti-Pattern 2: Sourcing Syntax Highlighting Before compinit

**What people do:** Add `source zsh-syntax-highlighting.zsh` early in `.zshrc`, before Oh My Zsh runs `compinit`.

**Why it's wrong:** zsh-syntax-highlighting registers a `zle-line-pre-redraw` hook (Zsh ≥ 5.8). If loaded before `compinit`, completion widget wrappers are applied in the wrong order — resulting in broken completion menus or highlighting that overwrites completion output. The official README states it must be "sourced **at the end** of the `.zshrc`".

**Do this instead:** Source zsh-syntax-highlighting AFTER `source $ZSH/oh-my-zsh.sh` (which runs `compinit`). The current project does this correctly (lines 117-118 are before OMZ only to register the plugin, actual source is after OMZ at lines 133-134).

### Anti-Pattern 3: Setting ZSH_THEME Before Configuring Plugins

**What people do:** Set `ZSH_THEME="powerlevel10k/powerlevel10k"` at the top of `.zshrc` along with other OMZ config.

**Why it's wrong:** Oh My Zsh processes themes as part of `source $ZSH/oh-my-zsh.sh`, so setting `ZSH_THEME` early is fine syntactically. But it creates a false dependency — if you ever refactor to load the theme separately (as required by P10k's "must be last" constraint), you'll break the theme loading.

**Do this instead:** Set `ZSH_THEME=""` (empty) at the top with OMZ config, then source the P10k theme file explicitly at the END of `.zshrc`. The current project does this correctly.

### Anti-Pattern 4: PATH Pollution Without Dedup

**What people do:** Add to `PATH` in multiple places (`.zshenv`, `.zprofile`, `.zshrc`, tool init scripts) without deduplication.

**Why it's wrong:** `PATH` grows unboundedly with duplicates. Duplicate entries slow down command lookup (and `hash -r`). Each duplicate entry is traversed before finding the command.

**Do this instead:** Use `typeset -U path PATH` (unique array) early in `.zshrc`. The current project does this correctly.

### Anti-Pattern 5: Forgetting to Background zcompile

**What people do:** Run `zcompile ~/.zshrc` synchronously in `.zshrc`, blocking shell startup.

**Why it's wrong:** The compilation takes 10-30ms on every shell start. Since `.zwc` is only useful on *next* shell start (this one already parsed the source), there's no reason to block.

**Do this instead:** Run `zcompile ~/.zshrc &>/dev/null &!` (background + disown). The current project does this correctly.

### Anti-Pattern 6: Tight Coupling to Oh My Zsh's Plugin Paths

**What people do:** Reference `${ZSH_CUSTOM}` without falling back, or hardcode path assumptions.

**Why it's wrong:** If Oh My Zsh is installed differently (symlinked, different prefix), plugin paths break silently.

**Do this instead:** Use fallback pattern: `"${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"` everywhere. The current project does this correctly.

## Integration Points

### External Dependencies

| Service/Tool | Integration Pattern | Notes |
|-------------|-------------------|-------|
| Oh My Zsh | `source $ZSH/oh-my-zsh.sh` | Path set via `export ZSH="$HOME/.oh-my-zsh"` |
| Powerlevel10k | `source powerlevel10k.zsh-theme` | Two possible paths (see `.zshrc` lines 313-317) |
| zoxide | `zoxide init zsh` → cached | Cache system captures output; not sourced directly |
| fzf | Source key-bindings.zsh + _fzf completion | Cached with zoxide; `source /usr/share/fzf/shell/key-bindings.zsh` |
| eza | `command -v eza` → define aliases | Graceful degradation if not installed |
| zsh-autosuggestions | Plugin path in `$ZSH_CUSTOM/plugins/` | Deferred via zsh-defer when available |
| zsh-syntax-highlighting | Plugin path in `$ZSH_CUSTOM/plugins/` | Deferred; must be last sourced |
| zsh-defer | Plugin path + `zsh-defer source` | Optional performance boost |
| DNF | `sudo dnf` aliases | Distro-specific; Fedora primary |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Instant Prompt ↔ Everything | No communication — it's a cached file that was generated on a previous shell start | Instant Prompt is fully self-contained |
| Boot Timer Start ↔ Boot Timer End | Global variable `_zshrc_start_s` (EPOCHREALTIME) | Single-file boundary |
| Config ↔ OMZ | Config exports `ZSH=`, `ZSH_THEME=`, `plugins=()` → OMZ reads them | One-way: .zshrc sets, OMZ consumes |
| Cache ↔ OMZ | None — cache is loaded before OMZ but doesn't interact with it | Cache provides zoxide/fzf init; OMZ provides framework |
| OMZ Plugins ↔ zsh-defer | zsh-defer wraps plugin `source` calls | zsh-defer loaded first, then plugins are deferred |
| Aliases ↔ Functions | No direct dependency — both defined after plugins | Functions can use aliases (but aliases expand in command position) |
| Security ↔ Everything | Indirect — sudo wrapper overrides builtin, history filter hooks command execution | No module depends on security; security constrains all modules |
| P10k Theme ↔ All preceding | Theme reads state established by earlier modules (e.g., `PROMPT` from OMZ) | Must be loaded last |

### Install/Sync Integration

| Method | What It Does | When to Use |
|--------|-------------|-------------|
| `cp .zshrc ~/.zshrc` | Flat copy (current) | Quick setup, single file |
| `bootstrap.sh` | Symlink files to `~/` | Maintainable modular setup |
| `rcm` (thoughtbot's rcm) | Managed symlink dotfile manager | Multi-machine, team use |
| GNU Stow | Symlink farm manager | If already using Stow for other dotfiles |

### Cross-Distro Compatibility

| Component | Fedora | Debian/Ubuntu | Arch | macOS |
|-----------|--------|---------------|------|-------|
| DNF aliases | ✅ Native | ❌ (use apt) | ❌ (use pacman) | ❌ (use brew) |
| apt aliases | ❌ | ⚠️ Add separately | ❌ | ❌ |
| pacman aliases | ❌ | ❌ | ⚠️ Add separately | ❌ |
| brew aliases | ❌ | ❌ | ❌ | ⚠️ Add separately |
| Plugin paths | ✅ Same | ✅ Same | ✅ Same | ✅ Same |
| Tool install | `dnf install` | `apt install` | `pacman -S` | `brew install` |

The modular architecture makes distro-specific sections easy to add as conditionally-sourced files (e.g., `zsh/aliases/distro-apt.zsh`, `zsh/aliases/distro-pacman.zsh`) without touching the core config.

## Build Order Implications for Phases

The recommended implementation order follows a **bottom-up dependency approach** — each phase depends on the previous phase being complete:

| Phase | Module | Why This Order | Dependencies |
|-------|--------|---------------|--------------|
| 1 | Shell Foundation (config/) | Everything depends on PATH, options, history | None |
| 2 | Plugin Cache (plugins/cache.zsh) | Needs history config before zoxide integration | Phase 1 |
| 3 | OMZ Integration (plugins/omz*.zsh) | Needs ZSH_THEME="" and options set | Phase 1 |
| 4 | Security Layer (security/) | Independent of plugins, but needs to exist before user commands | Phase 1 |
| 5 | Aliases (aliases/) | Needs PATH (for eza detection) | Phase 1 |
| 6 | Functions (functions/) | Uses git (gcom, lazyg) — needs git in PATH | Phase 1 |
| 7 | Heavy Plugins (plugins/heavy.zsh) | Must load after OMZ's compinit | Phase 3 |
| 8 | Theme Loading (theme/) | MUST be last — depends on everything above | Phases 1-7 |
| 9 | Boot Timer + Compilation (init/) | Wraps around all other phases | Phase 8 (for final timing) |
| 10 | Bootstrap Script | Depends on final directory structure | Phase 9 |

**Parallelizable phases:**
- Security, Aliases, and Functions can be developed in parallel (Phase 4, 5, 6)
- Heavy Plugins and Boot Timer can be developed in parallel with the above (Phase 7, 9)

## Sources

- Official Zsh documentation on startup files: https://zsh.sourceforge.io/Doc/Release/Files.html (HIGH confidence)
- Powerlevel10k Instant Prompt requirements: https://github.com/romkatv/powerlevel10k (HIGH confidence — verified README)
- zsh-syntax-highlighting "must be at end" constraint: https://github.com/zsh-users/zsh-syntax-highlighting (HIGH confidence — verified README)
- thoughtbot dotfiles zsh architecture (modular `zsh/` directory + `zsh/configs/pre`/`post` pattern): https://github.com/thoughtbot/dotfiles/tree/main/zsh (MEDIUM confidence — observed structure)
- mathiasbynens dotfiles (`.aliases`, `.functions`, `.exports` split + bootstrap pattern): https://github.com/mathiasbynens/dotfiles (MEDIUM confidence — observed structure)
- Existing `.zshrc` v2.3 project analysis and current implementation patterns (HIGH confidence — code review)

---
*Architecture research for: Zsh Profile — Fedora Optimized*
*Researched: 2026-05-10*
