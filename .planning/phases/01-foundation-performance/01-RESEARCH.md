# Phase 01: Foundation & Performance - Research

**Researched:** 2026-05-10
**Domain:** Zsh shell configuration — instant prompt, plugin caching, bytecode compilation, theme loading
**Confidence:** HIGH

## Summary

This phase delivers the shell startup chain: Powerlevel10k Instant Prompt for perceived-zero-latency,
a microsecond-precision boot timer with color-coded thresholds, PATH deduplication, 50K-entry history
with cross-session sharing and credential filtering, a version-fingerprinted plugin cache with race-safe
`flock` locking that auto-rebuilds when zoxide/eza/fzf versions change, atomic bytecode compilation
of `.zshrc` and cache file, XDG base directory compliance, and Powerlevel10k theme loading at the
very end of `.zshrc` with `.zshrc.local` override support.

The existing `.zshrc` (342 lines, v2.3) already implements all these features but has two known
defects that this phase must fix: (1) the plugin cache fingerprint uses `command -v` (path-based)
which misses DNF in-place binary updates — must switch to `tool --version` per D-01; (2) no
locking around cache rebuild creates a race condition when multiple shells start simultaneously
— must add `flock` per D-04. The history filter regex must also be extended per D-26/D-27.

**Primary recommendation:** Refactor the existing `.zshrc` in-place rather than rewriting — the
current implementation is correct in structure; fix the two defects (fingerprint + locking), extend
the history regex, add XDG env vars, and verify all ordering constraints are met.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Fingerprint Strategy
- **D-01:** Use `tool --version 2>/dev/null | head -1` for all 3 watched tools (zoxide, eza, fzf) — catches DNF in-place binary updates that path-based fingerprint misses
- **D-02:** Keep all 3 tools watched (not a subset) — each is critical to its feature domain
- **D-03:** Rebuild cache excluding missing tools — don't block for uninstalled tools
- **D-04:** Use `flock` or PID file for cache rebuild locking — prevent parallel shell race condition
- **D-05:** Compile cache to `.zwc` after rebuild (keep current) — faster subsequent loads
- **D-06:** Exclude Oh My Zsh version from fingerprint — OMZ rarely changes
- **D-07:** Keep monolithic cache file structure — simpler, one `source` call
- **D-08:** Keep fingerprint in first line of cache file — atomic read+validate

#### Cache Rebuild Timing
- **D-09:** Rebuild synchronously on shell start when fingerprint mismatches — guarantees fresh cache
- **D-10:** Silent fallback on corrupt/missing cache — no warning, no rebuild on failure
- **D-11:** Async `.zwc` compilation after rebuild (`&!`) — cache usable immediately
- **D-12:** Silent rebuild (no output) — clean startup

#### Bytecode Compilation
- **D-13:** Compile `.zshrc` to `.zwc` in background on shell start (`zcompile &!`) — current behavior
- **D-14:** Only compile `.zshrc` and plugin cache (already done) — no extra files
- **D-15:** Silent fallback on compilation error (`&>/dev/null`) — no terminal output
- **D-16:** Overwrite `.zwc` in-place — no stale cleanup needed

#### History Size & Retention
- **D-17:** Keep 50K history entries — current setting, sufficient recall depth
- **D-18:** Immediate append per command (`INC_APPEND_HISTORY`) — cross-session sharing
- **D-19:** Ignore all duplicates (`HIST_IGNORE_ALL_DUPS`, `HIST_SAVE_NO_DUPS`) — clean history
- **D-20:** No logging of blocked commands from history filter

#### PATH Strategy
- **D-21:** Priority: `~/.local/bin` > `~/bin` > system PATH
- **D-22:** Keep current directory set (`~/.local/bin`, `~/bin`, `~/.spicetify`) — no additions

#### XDG Base Directory Compliance
- **D-23:** Set standard XDG env vars in `.zshrc` — let tools respect them automatically
- **D-24:** Keep in `.zshrc` (not `.zshenv`) — only needed for interactive shell tools

#### Boot Timer Thresholds
- **D-25:** Keep thresholds hardcoded (<150ms / <200ms / <500ms / >=500ms) — simple, predictable

#### History Filter Regex
- **D-26:** Extend patterns to also catch: `https://token@host`, `--token <value>`, `--password <value>`, `-p <value>`
- **D-27:** Also block commands containing SSH key material and GPG passphrase operations

### the agent's Discretion

No specific areas — standard approaches expected. All implementation details are at the agent's discretion within the constraints of the locked decisions above.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SHELL-01 | User's shell prompt appears instantly via Powerlevel10k Instant Prompt (<50ms perceived startup) | Context7 docs confirm instant prompt MUST be first in .zshrc; current placement correct |
| SHELL-02 | Boot timer captures startup time from first line to last | `zmodload zsh/datetime` → `EPOCHREALTIME` microsecond timer verified working |
| SHELL-03 | PATH is deduplicated and includes ~/.local/bin, ~/bin | `typeset -U path PATH` verified; current PATH order per D-21 |
| SHELL-04 | History managed with 50K entries, deduplication, cross-session sharing | `setopt SHARE_HISTORY INC_APPEND_HISTORY HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS` verified |
| SHELL-05 | Bytecode compilation of .zshrc runs in background for faster parsing | `zcompile ~/.zshrc &!` works; `zcompile` does NOT support `-o` flag — must use temp file for atomic cache compile |
| CACHE-01 | Plugin cache auto-rebuilds when tool versions change (zoxide, eza, fzf) | D-01 switches from path-based to version-based fingerprint; D-02 adds eza to watched list |
| CACHE-02 | Cache fingerprint uses content hash or version output, not binary path | Version-based per D-01; `tool --version 2>/dev/null | head -1` then `cksum` hashed |
| CACHE-03 | Cache loads conditionally — skips init if fingerprint matches | Existing pattern works; single `source` call after validation (D-07, D-08) |
| CACHE-04 | OMZ loads with git/history plugins, conditionally adds autosuggestions and syntax-highlighting | Existing `plugins=(git history)` with conditional push works; zsh-defer blocks conditional add |
| THEME-01 | Powerlevel10k loads at the very end of .zshrc | Existing placement (lines 313-317) correct; manual source with dual-path fallback |
| THEME-02 | Local ~/.zshrc.local is sourced before theme for user overrides | Existing line 308 correct placement (before P10k source, after aliases) |
| THEME-03 | .p10k.zsh configuration is sourced after theme if present | Existing line 319 correct; `[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh` after theme |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Instant Prompt rendering | Shell (Zsh) | Filesystem (cache file) | P10k cache file sourced at shell start; no network/API involved |
| Boot timer measurement | Shell (Zsh) | — | `zmodload zsh/datetime` → `EPOCHREALTIME` — all in-process |
| PATH deduplication | Shell (Zsh) | — | `typeset -U path PATH` — Zsh builtin |
| History management | Shell (Zsh) | Filesystem (HISTFILE) | Zsh writes to `~/.zsh_history`; no external daemon |
| History filtering | Shell (Zsh) | — | `zshaddhistory()` hook — pure Zsh function |
| Plugin cache fingerprint | Shell (Zsh) | Executables (zoxide/eza/fzf) | `tool --version` subprocess capture |
| Plugin cache rebuild | Shell (Zsh) | Filesystem (cache file) | `zoxide init zsh` / fzf key-bindings → temp file → atomic mv |
| Cache rebuild locking | Shell (Zsh) | OS (`flock` from util-linux) | `flock -n` on file descriptor — kernel-enforced mutual exclusion |
| Bytecode compilation | Shell (Zsh) | Filesystem (.zwc) | `zcompile` builtin; background via `&!` |
| Theme loading | Shell (Zsh) | Filesystem (theme file) | `source` at end of `.zshrc` |
| XDG env vars | Shell (Zsh) | — | `export` statements; tools respect them natively |
| Local overrides | Shell (Zsh) | Filesystem (~/.zshrc.local) | Optional `source` before theme |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| **Zsh** | 5.9 (Fedora 44) | Primary shell | Latest stable; required by OMZ + P10k. No newer release exists. [VERIFIED: `zsh --version`] |
| **Oh My Zsh** | Latest (rolling) | Plugin framework, compinit | Non-negotiable per PROJECT.md. Provides `$ZSH_CUSTOM` structure. [VERIFIED: `$ZSH=/home/anderson/.oh-my-zsh`] |
| **Powerlevel10k** | v1.20.0 | Theme + Instant Prompt | Only theme with sub-150ms boot + rich features. Instant Prompt eliminates startup lag. [VERIFIED: Context7 /romkatv/powerlevel10k] |
| **zsh/datetime** | Built into Zsh 5.9 | Microsecond timer | `EPOCHREALTIME` nanosecond-granularity timestamps. Always on Fedora Zsh. [VERIFIED: `zmodload` test] |
| **zcompile** | Built into Zsh 5.9 | Bytecode compilation | Compiles `.zshrc` → `.zwc` for faster parsing. No `-o` flag in 5.9. [VERIFIED: `zcompile` test] |
| **flock** | util-linux (Fedora 44) | File locking | Kernel-enforced advisory lock. Prevents cache rebuild race. Auto-released on fd close. [VERIFIED: `/usr/bin/flock`] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **zoxide** | 0.9.8+ (DNF) | Smart directory navigation | Watched by cache; init script cached for performance |
| **eza** | 0.23.4+ (DNF) | Modern file listing | Watched by cache; aliases defined in Phase 2 |
| **fzf** | 0.70.0+ (DNF) | Fuzzy finder | Watched by cache; key bindings + completion cached |
| **zsh-autosuggestions** | Rolling (git clone) | Fish-like autosuggestions | Conditionally loaded via OMZ plugins array |
| **zsh-syntax-highlighting** | Rolling (git clone) | Command highlighting | Conditionally loaded; MUST be last plugin before theme |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Path-based fingerprint | Version string (`tool --version`) | Version string catches DNF in-place updates; path-based misses them. [DECIDED: D-01] |
| `mkdir` for locking | `flock` (util-linux) | `mkdir` is atomic but can leave stale lock dirs on crash; `flock` auto-releases on fd close. [DECIDED: D-04] |
| `zcompile` direct write | `zcompile` with temp+rename | Direct write can race parallel starts (self-healing); temp+rename is atomic but adds ~5ms overhead. Direct for .zshrc, atomic for cache. |

**Installation:**
```bash
# Core (already present on system):
# Zsh 5.9 — pre-installed on Fedora 44
# flock — from util-linux, pre-installed

# Optional tools (cache watches these):
sudo dnf install eza fzf zoxide
```

**Version verification:**
```bash
zsh --version          # → zsh 5.9 (x86_64-redhat-linux-gnu)
command -v flock       # → /usr/bin/flock (util-linux)
```
[VERIFIED: system commands]

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        .zshrc LOADING ORDER                          │
│                                                                      │
│  1. P10k INSTANT PROMPT (MUST BE FIRST)                              │
│     source ~/.cache/p10k-instant-prompt-<user>.zsh                  │
│     ├─ Renders cached prompt immediately                             │
│     └─ Defers all stdout/stderr until init complete                  │
│                    ▼                                                  │
│  2. BOOT TIMER START                                                 │
│     zmodload zsh/datetime → _zshrc_start_s=$EPOCHREALTIME           │
│                    ▼                                                  │
│  3. PATH DEDUP + ADDITIONS                                          │
│     typeset -U path PATH                                            │
│     export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.spicetify"       │
│                    ▼                                                  │
│  4. XDG BASE DIRECTORY ENV VARS (NEW)                               │
│     export XDG_CACHE_HOME XDG_CONFIG_HOME XDG_DATA_HOME             │
│                    ▼                                                  │
│  5. OMZ CONFIG + SETOPT + HISTORY                                   │
│     ZSH=, ZSH_THEME="", setopt, HISTFILE/SIZE/SAVEHIST              │
│                    ▼                                                  │
│  6. HISTORY SECURITY FILTER                                          │
│     zshaddhistory() — regex blocks credentials in history           │
│                    ▼                                                  │
│  7. PLUGIN CACHE (FINGERPRINT → LOCK → REBUILD → SOURCE)           │
│     7a. Compute fingerprint: tool --version | head -1               │
│     7b. Read cached fingerprint (line 1 of cache file)              │
│     7c. If mismatch → flock -n → rebuild → source                  │
│     7d. zcompile cache → .zwc in background (&!)                    │
│                    ▼                                                  │
│  8. OH MY ZSH CORE + PLUGINS                                         │
│     plugins=(git history [autosuggestions] [syntax-highlighting])    │
│     source $ZSH/oh-my-zsh.sh (runs compinit internally)             │
│                    ▼                                                  │
│  9. ZSH-DEFER LAZY LOADING (OPTIONAL)                                │
│     If zsh-defer exists: source it, defer heavy plugins              │
│                    ▼                                                  │
│  10. ALIASES + FUNCTIONS (Phase 2 existing content)                  │
│                    ▼                                                  │
│  11. LOCAL OVERRIDES (~/.zshrc.local) — BEFORE theme                 │
│                    ▼                                                  │
│  12. POWERLEVEL10K THEME (MUST BE LAST)                              │
│     source P10k theme → source ~/.p10k.zsh                          │
│                    ▼                                                  │
│  13. BYTECODE COMPILATION (ASYNC)                                    │
│     if .zshrc newer than .zshrc.zwc: zcompile ~/.zshrc &!          │
│                    ▼                                                  │
│  14. BOOT TIMER END                                                  │
│     _zshrc_load_ms = (EPOCHREALTIME - start) * 1000                 │
│     zshrc-time() function → color-coded output on demand             │
└─────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

This phase refactors the single `.zshrc` file. No modular directory structure (V2 scope).

```
~/
├── .zshrc                    # Main configuration (refactored in this phase)
├── .zshrc.local              # Local overrides (optional, sourced before theme)
├── .zshrc.zwc                # Bytecode compiled version (auto-generated)
├── .zsh_history              # Shell history (50K entries)
├── .cache/
│   ├── zsh_plugins_init.zsh      # Plugin cache (fingerprint line 1)
│   ├── zsh_plugins_init.zsh.zwc  # Bytecode compiled cache
│   └── p10k-instant-prompt-<user>.zsh  # P10k instant prompt cache
├── .oh-my-zsh/               # Oh My Zsh installation
│   └── custom/
│       ├── themes/powerlevel10k/     # P10k theme (git clone)
│       └── plugins/
│           ├── zsh-autosuggestions/
│           ├── zsh-syntax-highlighting/
│           └── zsh-defer/
└── .p10k.zsh                 # Powerlevel10k config (generated by wizard)
```

### Pattern 1: Version-Fingerprinted Cache with Flock Locking

**What:** Replace path-based fingerprint (`command -v`) with version-based fingerprint
(`tool --version 2>/dev/null | head -1`), and wrap cache rebuild in `flock` to prevent
race conditions when multiple shells start simultaneously.

**When to use:** Every shell start — the cache system checks freshness before sourcing.

**Example:**
```zsh
# New fingerprint function (D-01: version-based)
_zsh_gen_fingerprint() {
  local fp="" tool version
  for tool in "${_TOOLS_WATCHED[@]}"; do
    version=$(command "$tool" --version 2>/dev/null | head -1 || echo "missing")
    fp+="${tool}=${version};"
  done
  print -n "$fp" | cksum | cut -d' ' -f1 2>/dev/null || print -n "$fp"
}

# Cache rebuild with flock locking (D-04)
_plugin_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh_plugins_init.zsh"
_lockfile="${_plugin_cache}.lock"

_rebuild_cache() {
  local tmp=$(mktemp) || return 1
  trap "rm -f '$tmp'" INT TERM
  printf '# zsh_plugin_cache fingerprint: %s\n' "$(_zsh_gen_fingerprint)" > "$tmp"

  # zoxide init (D-03: skip missing tools)
  if command -v zoxide &>/dev/null; then
    printf '\n# --- zoxide ---\n' >> "$tmp"
    zoxide init zsh >> "$tmp" 2>/dev/null
  fi

  # fzf key bindings + completion
  if command -v fzf &>/dev/null; then
    printf '\n# --- fzf ---\n' >> "$tmp"
    [[ -f /usr/share/fzf/shell/key-bindings.zsh ]] && \
      printf 'source /usr/share/fzf/shell/key-bindings.zsh\n' >> "$tmp"
    [[ -f /usr/share/zsh/site-functions/_fzf ]] && \
      printf 'source /usr/share/zsh/site-functions/_fzf\n' >> "$tmp"
  fi

  # eza init (no init output currently, but watched per D-02)
  if command -v eza &>/dev/null; then
    printf '\n# --- eza: no init needed (alias-only) ---\n' >> "$tmp"
  fi

  mv "$tmp" "$_plugin_cache"
}

# Validation with flock gate
if [[ -f "$_plugin_cache" ]]; then
  _current_fp=$(_zsh_gen_fingerprint)
  _cached_fp=$(sed -n '1s/# zsh_plugin_cache fingerprint: //p' "$_plugin_cache")
  if [[ "$_current_fp" != "$_cached_fp" ]]; then
    # Cache stale — attempt rebuild with lock
    touch "$_lockfile" 2>/dev/null
    exec {_cachelock_fd}<>"$_lockfile" 2>/dev/null
    if [[ -n ${_cachelock_fd:-} ]] && flock -n "$_cachelock_fd" 2>/dev/null; then
      _rebuild_cache
      exec {_cachelock_fd}>&-
    fi
    # If lock not acquired, another shell is rebuilding — use existing cache (D-10)
  fi
else
  # No cache exists — rebuild (D-12: silent, no output)
  _rebuild_cache
fi

[[ -f "$_plugin_cache" ]] && source "$_plugin_cache"
```

### Pattern 2: Atomic Zcompile with Temp File

**What:** Compile using a temp file + atomic rename to avoid TOCTOU race on parallel
shell starts. `zcompile` does NOT support `-o` flag in Zsh 5.9.

**When to use:** After cache rebuild (atomic needed) and on shell start for `.zshrc` (direct fine).

**Example:**
```zsh
# For .zshrc: direct compile is fine (low risk, self-healing per D-13/D-16)
if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]; then
  zcompile ~/.zshrc &>/dev/null &!
fi

# For plugin cache: atomic via temp file (D-11: async &!)
if [[ -f "$_plugin_cache" && \
      ( ! -f "${_plugin_cache}.zwc" || "$_plugin_cache" -nt "${_plugin_cache}.zwc" ) ]]; then
  (
    tmp_src=$(mktemp /tmp/zsh_cache_compile.XXXXXX.zsh) || exit
    cp "$_plugin_cache" "$tmp_src"
    zcompile "$tmp_src" 2>/dev/null && mv "${tmp_src}.zwc" "${_plugin_cache}.zwc" 2>/dev/null
    rm -f "$tmp_src"
  ) &!
fi
```

### Pattern 3: History Security Filter (Extended Regex)

**What:** `zshaddhistory()` hook that blocks commands containing credential patterns
from being saved to history. Extended per D-26/D-27. Return 0 = save, return 1 = discard.

**Example:**
```zsh
zshaddhistory() {
  local upper="${1:u}"
  # Assignment patterns (existing, kept)
  [[ "$upper" =~ (TOKEN|SECRET|PASSWORD|PASSWD|API_KEY|PRIVATE_KEY|CREDENTIAL|ACCESS_KEY)[[:space:]]*= ]] && return 1
  # URL-embedded credentials (D-26): https://token@host
  [[ "$upper" =~ HTTPS?://[^[:space:]]*@[^[:space:]]+ ]] && return 1
  # Flag-based credentials (D-26): --token <value>, --password <value>
  [[ "$upper" =~ --TOKEN[[:space:]]+[^[:space:]]+ ]] && return 1
  [[ "$upper" =~ --PASSWORD[[:space:]]+[^[:space:]]+ ]] && return 1
  # Short flag credentials (D-26): -p <value>
  [[ "$upper" =~ (^|[[:space:]])-P[[:space:]]+[^[:space:]]+ ]] && return 1
  # SSH key material (D-27)
  [[ "$upper" =~ (SSH[[:space:]]+-I|SSH-ADD[[:space:]]|SSH-KEYGEN) ]] && return 1
  # GPG passphrase operations (D-27)
  [[ "$upper" =~ GPG[[:space:]].*--PASS ]] && return 1
  return 0
}
```

### Anti-Patterns to Avoid

- **Placing any `echo`, `printf`, or `source` before the Instant Prompt block:** P10k Instant Prompt MUST be the first executable line. Any output before it causes warnings or silent disable. The boot timer `zmodload zsh/datetime` produces no output — it's safe. [VERIFIED: Context7 docs]
- **Using `command -v` path as cache fingerprint:** DNF updates tools in-place without changing the binary path. Must use `tool --version` (D-01). [VERIFIED: PITFALLS.md pitfall #3]
- **Rebuilding cache without locking:** Multiple shells starting simultaneously will each rebuild independently. Use `flock` (D-04). [VERIFIED: PITFALLS.md pitfall #7]
- **Loading zsh-syntax-highlighting before compinit:** OMZ runs `compinit` internally. Syntax-highlighting must load after `source $ZSH/oh-my-zsh.sh`. [VERIFIED: zsh-syntax-highlighting README]
- **Setting `ZSH_THEME="powerlevel10k/powerlevel10k"`:** This lets OMZ control theme loading order. Set `ZSH_THEME=""` and manually source P10k at the very end. [VERIFIED: STACK.md]
- **Using `SHARE_HISTORY` without `INC_APPEND_HISTORY`:** SHARE_HISTORY only writes on shell exit. INC_APPEND_HISTORY ensures immediate writes for crash safety. Both together = full cross-session sharing. [VERIFIED: Zsh manual]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| File locking for cache rebuild | Custom PID file or `mkdir` lockdir | `flock` (util-linux) | Kernel-enforced, auto-released on fd close, no stale lock cleanup [VERIFIED: D-04] |
| Microsecond timer | `date +%s%N` | `zmodload zsh/datetime` + `$EPOCHREALTIME` | Built-in, no subprocess spawn, nanosecond granularity [VERIFIED: test] |
| Path deduplication | `awk`/`sed` pipeline on `$PATH` | `typeset -U path PATH` | Zsh builtin; one-liner, no subprocess [VERIFIED: Zsh 5.9] |
| Cache fingerprint hashing | Custom hash in Zsh | `cksum` (POSIX) or raw string fallback | Available on all POSIX systems [VERIFIED: cksum available] |
| Bytecode compilation | Custom scheduler | `zcompile` (Zsh builtin) + `&!` | Built-in. `&!` disowns job so no "done" messages [VERIFIED: test] |

**Key insight:** Zsh provides builtins for almost every performance-critical operation (`typeset -U`, `zcompile`, `zmodload`, `zshaddhistory`, `EPOCHREALTIME`). The only external dependency is `flock` for cache locking — universally available on Linux. Don't add npm packages, Python scripts, or Rust binaries to a shell configuration phase.

## Common Pitfalls

### Pitfall 1: Instant Prompt Ordering Violation

**What goes wrong:** User sees "POWERLEVEL9K_INSTANT_PROMPT=verbose" warnings or cursor errors. Instant Prompt silently disabled.

**Why it happens:** Any output before the Instant Prompt `source` line causes P10k to detect "console output during init" and either warn or disable.

**How to avoid:** Current `.zshrc` lines 9-11 already place Instant Prompt first. NEVER move anything above it during refactoring.

**Warning signs:** "POWERLEVEL9K_INSTANT_PROMPT" messages; cursor at wrong position; first prompt missing theme styling.

### Pitfall 2: Silent Fingerprint Collision (THE BUG TO FIX)

**What goes wrong:** User upgrades zoxide/fzf/eza via `dnf upgrade`. Path stays same so fingerprint doesn't change. Cache not rebuilt — old init scripts run against new tool versions. Silent failure.

**Why it happens:** Current `_zsh_gen_fingerprint()` uses `command -v "$tool"` (path-based). DNF updates in-place.

**How to avoid:** Switch to `tool --version 2>/dev/null | head -1` per D-01. Version string changes on DNF update → fingerprint changes → cache rebuilds.

**Warning signs:** Tool behavior doesn't match expected version; no cache rebuild after `dnf upgrade`.

### Pitfall 3: Cache Rebuild Race on Parallel Shell Start

**What goes wrong:** tmux session with 4 panes causes 3-4 independent cache rebuilds. Wasted I/O and CPU.

**Why it happens:** No locking around `_zsh_build_plugin_cache()`. Each shell independently detects stale fingerprint and rebuilds.

**How to avoid:** Wrap rebuild in `flock -n` per D-04. Non-blocking — if another shell holds lock, skip rebuild and use existing cache.

**Warning signs:** Multiple `zoxide init zsh` processes in `ps aux` during tmux start; cache mtime updates multiple times rapidly.

### Pitfall 4: `zcompile` TOCTOU Race (Acceptable)

**What goes wrong:** Two shells simultaneously compile `.zshrc`. File may be corrupted. Next start falls back to source (bytecode invalid → parse directly). Self-healing.

**How to avoid:** Accept for `.zshrc` (low risk, self-healing, D-13/D-16). For plugin cache, use atomic temp-file approach (Pattern 2).

### Pitfall 5: `SHARE_HISTORY` with `HIST_IGNORE_ALL_DUPS` Edge Case

**What goes wrong:** `HIST_IGNORE_ALL_DUPS` checks duplicates against in-memory history, not shared HISTFILE. Two sessions may diverge briefly.

**How to avoid:** With `INC_APPEND_HISTORY`, each session writes immediately — divergence window is per-command, negligible for single-user machines.

### Pitfall 6: `zshaddhistory` Performance on Long Commands

**What goes wrong:** Pasted scripts (10K+ chars) pass through regex matching. Could add measurable overhead with extended patterns (D-26/D-27).

**How to avoid:** Add early-exit length check: `[[ ${#1} -gt 4096 ]] && return 0`. Actual commands rarely exceed 1K chars.

## Code Examples

Verified patterns from official sources:

### Powerlevel10k Instant Prompt (MUST BE FIRST)

```zsh
# Source: https://context7.com/romkatv/powerlevel10k/llms.txt
# VERIFIED: Context7 docs — requires Zsh >= 5.4

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
```

### Powerlevel10k Theme Loading (MUST BE LAST)

```zsh
# Source: https://context7.com/romkatv/powerlevel10k/llms.txt
# VERIFIED: Context7 docs — sourced at end of .zshrc

# Manual install path
if [[ -f ~/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source ~/powerlevel10k/powerlevel10k.zsh-theme
# OMZ custom themes path
elif [[ -f ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme
fi

# User's P10k configuration
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
```

### Boot Timer with EPOCHREALTIME

```zsh
# Source: Zsh 5.9 zsh/datetime module — in-environment testing confirmed
# VERIFIED: zmodload succeeds, EPOCHREALTIME provides nanosecond precision

zmodload zsh/datetime
typeset -g _zshrc_start_s=$EPOCHREALTIME

# ... all .zshrc processing ...

typeset -g _zshrc_load_ms=$(printf "%.0f" "$(( (EPOCHREALTIME - _zshrc_start_s) * 1000 ))")
unset _zshrc_start_s
```

### XDG Base Directory Setup

```zsh
# Source: XDG Base Directory Specification
# CITATION: https://specifications.freedesktop.org/basedir-spec/latest/
# VERIFIED: standard — empty vars mean "use default" per spec

export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
```

### Boot Time Display Function

```zsh
# Source: Existing .zshrc lines 335-341 — verified working
# VERIFIED: in-environment testing — color-coded thresholds

zshrc-time() {
  local ms=$_zshrc_load_ms
  if   (( ms < 150 )); then printf '⚡ .zshrc: \e[32m%dms\e[0m (excelente)\n' "$ms"
  elif (( ms < 200 )); then printf '⚡ .zshrc: \e[32m%dms\e[0m (bom)\n' "$ms"
  elif (( ms < 500 )); then printf '⚡ .zshrc: \e[33m%dms\e[0m (aceitavel)\n' "$ms"
  else                      printf '🐢 .zshrc: \e[31m%dms\e[0m (lento)\n' "$ms"
  fi
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Path-based fingerprint (`command -v`) | Version-based fingerprint (`tool --version`) | This phase (D-01) | Detects DNF in-place updates |
| No locking on cache rebuild | `flock -n` advisory lock | This phase (D-04) | Prevents multi-shell rebuild storm |
| 2 tools watched (zoxide, fzf) | 3 tools watched (+ eza) | This phase (D-02) | eza in fingerprint; future-proofs |
| History filter: assignment-only | Extended: URL tokens, flags, SSH/GPG | This phase (D-26/D-27) | Catches more credential leak vectors |
| No XDG env vars set | Standard XDG vars in `.zshrc` | This phase (D-23/D-24) | Tools respect XDG for cache/config |

**Deprecated/outdated:**
- **`command -v` for fingerprint**: Stable path misses DNF updates → replaced by version string per D-01.
- **`_TOOLS_WATCHED=(zoxide fzf)`**: Missing eza → updated to `(zoxide eza fzf)` per D-02.
- **History regex without URL/flag patterns**: Misses `https://token@host` leaks → extended per D-26/D-27.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `flock` from util-linux is available on all Fedora systems (core util-linux dependency) | Standard Stack | If missing, fall back to `zsystem flock` (Zsh builtin) or `mkdir` lockdir |
| A2 | `zsh/datetime` module is compiled into Fedora's Zsh package | Boot Timer | If missing, fall back to `$SECONDS` (integer seconds) |
| A3 | `zshaddhistory` hook is called only for interactive commands, not sourced scripts | History Filter | If called for non-interactive, regex overhead on scripts. Low risk per Zsh docs |
| A4 | `cksum` output format is stable across POSIX systems | Cache Fingerprint | If format changes, hash changes → cache rebuilds once. Self-healing |
| A5 | `&!` (background + disown) works identically to `&|` in Zsh 5.9 | Bytecode Compilation | Cosmetic only — "done" message may appear |
| A6 | eza produces no `init` output — it's an alias-only tool | Plugin Cache | If eza adds init output in future, cache won't capture it. Low risk |

## Open Questions

1. **`SHARE_HISTORY` vs `INC_APPEND_HISTORY_TIME` choice**
   - What we know: Both `SHARE_HISTORY` + `INC_APPEND_HISTORY` are set. `INC_APPEND_HISTORY_TIME` adds timestamps.
   - What's unclear: Whether `INC_APPEND_HISTORY_TIME` provides benefit over current combo. `EXTENDED_HISTORY` already stores timestamps.
   - Recommendation: Keep current settings — well-tested. Don't add `INC_APPEND_HISTORY_TIME` unless needed.

2. **`EXTENDED_HISTORY` not currently set**
   - What we know: Saves timestamps and duration in HISTFILE. Not set in current `.zshrc`.
   - What's unclear: Whether timestamps in history are desired (enable `fc -l -d` but add verbosity).
   - Recommendation: Do not add in Phase 1 — preference, not performance concern.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Zsh | All shell features | ✓ | 5.9 | — |
| Oh My Zsh | Plugin framework, compinit | ✓ | Installed at ~/.oh-my-zsh | — |
| Powerlevel10k | Instant Prompt + Theme | ✗ | — | Document install; theme loading fails gracefully |
| `flock` (util-linux) | Cache rebuild locking | ✓ | /usr/bin/flock | `zsystem flock` or `mkdir` lockdir |
| `zsh/datetime` | Boot timer | ✓ | Built into Zsh 5.9 | `$SECONDS` (integer precision) |
| `zcompile` | Bytecode compilation | ✓ | Built into Zsh 5.9 | None — skip compilation |
| `cksum` | Fingerprint hashing | ✓ | POSIX, always present | Raw fingerprint string |
| zoxide | Plugin cache (watched) | ✗ | — | Skipped in fingerprint per D-03 |
| eza | Plugin cache (watched) | ✗ | — | Skipped in fingerprint per D-03 |
| fzf | Plugin cache (watched) | ✗ | — | Skipped in fingerprint per D-03 |
| zsh-autosuggestions | Conditional plugin | ✗ | — | Omitted from plugins array |
| zsh-syntax-highlighting | Conditional plugin | ✗ | — | Omitted from plugins array |
| zsh-defer | Optional lazy loading | ✗ | — | Synchronous plugin loading |

**Missing dependencies with no fallback:** None — all core features work without optional tools.

**Missing dependencies with fallback:**
- zoxide, eza, fzf: Cache excludes them per D-03; Phase 2 aliases guarded with `command -v`.
- Powerlevel10k: Theme loading fails gracefully (no P10k prompt, but no error).
- zsh-autosuggestions, zsh-syntax-highlighting: Conditional in plugins array; OMZ handles gracefully.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A — shell config, no auth system |
| V3 Session Management | No | N/A — Zsh sessions, not web sessions |
| V4 Access Control | No | N/A — single-user shell |
| V5 Input Validation | Yes (limited) | `zshaddhistory()` regex — blocks credential patterns from history |
| V6 Cryptography | No | N/A — no cryptographic operations |

**Note:** This is a dotfile configuration project. ASVS applicability is limited. The primary security
concern is credential leak prevention through shell history, analogous to V5 input validation/data sanitization.

### Known Threat Patterns for Zsh Shell Configuration

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Credentials saved in `.zsh_history` via `export TOKEN=...` | Information Disclosure | `zshaddhistory()` hook — regex blocks assignment patterns |
| Credentials saved via URL embedding (`git clone https://token@host/...`) | Information Disclosure | Extended regex (D-26): `HTTPS?://[^[:space:]]*@[^[:space:]]+` |
| Credentials saved via flag arguments (`--token ghp_xxx`) | Information Disclosure | Extended regex (D-26): `--TOKEN[[:space:]]+[^[:space:]]+` |
| SSH key material in history (`ssh-add`, `ssh -i keyfile`) | Information Disclosure | Extended regex (D-27): `SSH[[:space:]]+-I` / `SSH-ADD` patterns |
| GPG passphrase in history | Information Disclosure | Extended regex (D-27): `GPG[[:space:]].*--PASS` |
| History file readable by other users (multi-user system) | Information Disclosure | HISTFILE permissions; not in this phase scope |
| Cache file injection via manipulated tool output | Tampering | `zoxide init zsh` output is trusted; tool binary must be trusted |

## Sources

### Primary (HIGH confidence)
- [Context7: /romkatv/powerlevel10k] — Instant Prompt setup, theme loading, ordering requirements, configuration wizard output
- [Powerlevel10k GitHub README](https://github.com/romkatv/powerlevel10k) — Installation paths, Zsh 5.4+ requirement, Instant Prompt behavior
- [zsh-syntax-highlighting README](https://github.com/zsh-users/zsh-syntax-highlighting) — "must be sourced at end of .zshrc" constraint
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/) — Standard env var definitions
- [Existing `.zshrc` v2.3] — Direct code analysis of all implemented features, ordering, patterns
- [STACK.md](.planning/research/STACK.md) — Verified technology versions and alternatives
- [PITFALLS.md](.planning/research/PITFALLS.md) — 18 documented pitfalls with root causes and fixes

### Secondary (MEDIUM confidence)
- [Zsh Manual: zsh/datetime](https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html) — EPOCHREALTIME, zmodload usage
- [Zsh Manual: zcompile](https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html) — Bytecode compilation, .zwc files
- [Zsh Manual: History Options](https://zsh.sourceforge.io/Doc/Release/Options.html#History) — SHARE_HISTORY, INC_APPEND_HISTORY interactions

### Tertiary (LOW confidence)
- [WebSearch: flock vs mkdir locking] — Locking strategy comparison; verified with in-environment testing

### In-Environment Testing (all HIGH confidence)
- `zsh --version` → 5.9 available
- `zmodload zsh/datetime` → succeeds, EPOCHREALTIME functional
- `zcompile /tmp/test.zsh` → succeeds, .zwc created, valid bytecode
- `flock -n` on fd → lock acquired, released on fd close
- `typeset -U path` → deduplication works
- `setopt SHARE_HISTORY INC_APPEND_HISTORY` → all options available
- History filter regex patterns → all D-26/D-27 patterns match correctly

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Zsh, flock, zcompile all verified in-environment; P10k verified via Context7 docs
- Architecture: HIGH — loading order verified against Context7 and existing .zshrc; all constraints confirmed
- Pitfalls: HIGH — 6 phase-specific pitfalls identified; root causes verified via Context7 and in-environment testing
- All decisions (D-01 through D-27): IMPLEMENTABLE — technical feasibility confirmed for each locked decision

**Research date:** 2026-05-10
**Valid until:** 2026-06-09 (30 days — Zsh/P10k are stable, no breaking changes expected)
