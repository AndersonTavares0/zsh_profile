# Walking Skeleton — Zsh Profile (Fedora Optimized)

**Phase:** 01 — Foundation & Performance
**Generated:** 2026-05-10

## Capability Proven End-to-End

> A user starts a new Zsh shell and immediately sees a styled prompt (Powerlevel10k Instant Prompt), with plugin integrations (zoxide, fzf, eza) loading from a version-fingerprinted cache that auto-rebuilds when tools update, and all credential-containing commands are silently filtered from shell history.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Shell | Zsh 5.9 (Fedora 44) | Latest stable; required by OMZ + P10k. No newer release exists. Pre-installed on Fedora. |
| Framework | Oh My Zsh (rolling) | Non-negotiable per PROJECT.md. Provides `$ZSH_CUSTOM` structure, `compinit`, plugin loading. 180k+ GitHub stars. |
| Theme | Powerlevel10k v1.20.0 | Only theme with sub-150ms boot + Instant Prompt + rich features. Instant Prompt MUST be first line in `.zshrc`. Sourced at very end. |
| Plugin cache strategy | Monolithic file with version-fingerprint | Single `source` call (D-07). Fingerprint = `cksum(tool --version | head -1)` for zoxide, eza, fzf (D-01). First line of cache file holds fingerprint for atomic read+validate (D-08). |
| Cache rebuild locking | `flock -n` (util-linux) + `zsystem flock` fallback | Kernel-enforced mutual exclusion. Non-blocking: if another shell holds lock, use existing cache (D-04, D-10). Auto-released on fd close. |
| PATH management | `typeset -U path PATH` (Zsh builtin) | Deduplication without subprocess. Priority: `~/.local/bin` > `~/bin` > system (D-21). |
| History | 50K entries, immediate append, dedup, cross-session sharing | `SHARE_HISTORY` + `INC_APPEND_HISTORY` for crash-safe cross-session sharing. `HIST_IGNORE_ALL_DUPS` + `HIST_SAVE_NO_DUPS` for dedup (D-17 through D-19). |
| History security | `zshaddhistory()` hook with extended regex | Blocks: assignment (`TOKEN=...`), URL-embedded (`https://token@host`), flag-based (`--token`, `--password`, `-p`), SSH key material (`ssh -i`, `ssh-add`, `ssh-keygen`), GPG passphrase (`gpg --passphrase`) (D-26, D-27). Early-exit at 4,096 chars for performance (Pitfall 6). |
| Bytecode compilation | `zcompile` (Zsh builtin) in background (`&!`) | Compiles `.zshrc` → `.zshrc.zwc` for faster parsing. Cache compile uses atomic temp+rename pattern (D-05, D-11, D-13). |
| Boot timer | `zmodload zsh/datetime` → `EPOCHREALTIME` | Microsecond precision, no subprocess. Color-coded thresholds: green <150ms, green <200ms, yellow <500ms, red ≥500ms (D-25). |
| XDG compliance | `XDG_CACHE_HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME` in `.zshrc` | Set before plugin cache init (D-23, D-24). Fallback to defaults if unset. |
| Local overrides | `~/.zshrc.local` sourced before theme | Optional file for per-machine customizations without editing `.zshrc` (THEME-02). |
| Directory layout | Monolithic `.zshrc` (342 lines, 14 sections) | v1 scope — modular directory structure deferred to v2 (V2-01). |
| Deployment | Manual copy/symlink of `zsh/.zshrc` → `~/.zshrc` | Bootstrap install script deferred to v2 (V2-04). |

## Stack Touched in Phase 1

- [x] Project scaffold — `zsh/.zshrc` (342 lines, 14 sections, refactored in-place)
- [x] Instant prompt — Powerlevel10k cache file sourced at line 9 (SHELL-01)
- [x] Boot timer — `EPOCHREALTIME` start/stop with `zshrc-time()` display function (SHELL-02)
- [x] PATH deduplication — `typeset -U path PATH` with user dirs prepended (SHELL-03)
- [x] History — 50K entries, dedup, cross-session sharing via `SHARE_HISTORY` + `INC_APPEND_HISTORY` (SHELL-04)
- [x] Bytecode compilation — `zcompile ~/.zshrc &!` at end of file (SHELL-05)
- [x] Plugin cache — version-fingerprint with flock locking, watches zoxide/eza/fzf (CACHE-01 through CACHE-04)
- [x] Theme — P10k sourced last, `.zshrc.local` before, `.p10k.zsh` after (THEME-01 through THEME-03)
- [x] Deployment — manual `cp` or `ln -s` from `zsh/.zshrc` to `~/.zshrc`

## Out of Scope (Deferred to Later Slices)

- Modular directory structure (`zsh/aliases/`, `zsh/functions/`, `zsh/config/`) — v2 (V2-01)
- compinit/menu select completion configuration — v2 (V2-02)
- zsh-defer lazy loading verification — v2 (V2-03)
- Bootstrap install script — v2 (V2-04)
- Cross-distro compatibility docs — v2 (V2-06)
- History filter: URL-embedded tokens with flag-based credentials edge case (Phase 3)
- Sudo protection and sudo !! warning (Phase 3)
- Productivity aliases (eza, grep, navigation) and functions (gcom, lazyg, sedi, extract, bk, port) — Phase 2

## Subsequent Slice Plan

Each later phase adds one vertical slice on top of this skeleton without altering its architectural decisions:

- **Phase 2: Productivity** — User has efficient aliases (eza, grep, navigation, sys-clean) and functions (git, sedi, extract, bk, port, zshrc-time) for daily terminal work.
- **Phase 3: Security** — User credentials are protected from history leaks (extended filter) and dangerous sudo commands are blocked from accidental execution.

## Plugin Cache Details

### Watched Tools
| Tool | Version Detection | Cache Content |
|------|-------------------|---------------|
| zoxide | `zoxide --version 2>/dev/null \| head -1` | Full `zoxide init zsh` output |
| eza | `eza --version 2>/dev/null \| head -1` | No init needed (alias-only tool) |
| fzf | `fzf --version 2>/dev/null \| head -1` | Key bindings + completion sources |

### Cache Lifecycle
1. On shell start: compute fingerprint from tool versions → hash with `cksum`
2. Read cached fingerprint from line 1 of `$XDG_CACHE_HOME/zsh_plugins_init.zsh`
3. If mismatch: attempt `flock -n` on lockfile → rebuild cache atomically → compile to `.zwc`
4. If lock held: use existing cache (may be slightly stale — acceptable)
5. Source cache file (single `source` call for all tools)

### Cache File Structure
```
# zsh_plugin_cache fingerprint: <cksum hash>
# --- zoxide ---
<zoxide init zsh output>
# --- fzf ---
source /usr/share/fzf/shell/key-bindings.zsh
source /usr/share/zsh/site-functions/_fzf
# --- eza: sem init necessário (alias-only) ---
```

## .zshrc Loading Order (Enforced)

```
 1. P10k INSTANT PROMPT (MUST BE FIRST — line 9)
 2. BOOT TIMER START (zmodload zsh/datetime)
 3. PATH DEDUP (typeset -U path PATH)
 4. PATH ADDITIONS (~/.local/bin, ~/bin, ~/.spicetify)
 5. XDG BASE DIRECTORY ENV VARS (XDG_CACHE/CONFIG/DATA_HOME)
 6. OMZ CONFIG (ZSH=, ZSH_THEME="")
 7. SETOPT + HISTORY (50K entries, dedup, sharing)
 8. HISTORY SECURITY FILTER (zshaddhistory hook)
 9. PLUGIN CACHE (fingerprint → lock → rebuild → source)
10. ZCOMPILE CACHE (async &!)
11. OMZ PLUGINS (git, history, conditional autosuggestions/syntax-highlighting)
12. source $ZSH/oh-my-zsh.sh (runs compinit internally)
13. ZSH-DEFER LAZY LOADING (optional, if installed)
14. ALIASES + FUNCTIONS (Phase 2 content)
15. LOCAL OVERRIDES (~/.zshrc.local)
16. POWERLEVEL10K THEME (MUST BE LAST)
17. ~/.p10k.zsh CONFIG (after theme)
18. BYTECODE COMPILATION (~/.zshrc → .zwc, async &!)
19. BOOT TIMER END (calculate _zshrc_load_ms)
```

Any deviation from this order causes: Instant Prompt warnings/disable, missing theme styling, broken plugin loading, or incorrect boot time measurements.
