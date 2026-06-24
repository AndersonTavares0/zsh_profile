# Roadmap: Zsh Profile — Fedora Optimized

**Generated:** 2026-05-10
**Last updated:** 2026-06-24
**Granularity:** Coarse (3 phases)
**Mode:** mvp

## Core Value

Shell starts fast, stays secure, and makes daily terminal work more productive without ceremony.

## Phases

- [x] **Phase 1: Foundation & Performance** — Instant prompt, boot timer, path/history config, plugin cache with auto-rebuild, bytecode compilation, and proper Powerlevel10k theme loading
- [x] **Phase 2: Productivity** — Eza file listing, navigation aliases/functions, colorized grep, distro-guarded sys-clean, git workflow functions, and utility functions (sedi, extract, bk, port, zshrc-time)
- [x] **Phase 3: Security** — History filter blocking sensitive patterns (TOKEN, SECRET, PASSWORD, API_KEY, PRIVATE_KEY, CREDENTIAL), sudo wrapper blocking dangerous commands, and sudo !! warning

## Phase Details

### Phase 1: Foundation & Performance
**Goal:** Shell starts fast with instant prompt, efficient plugin caching, proper theme loading, and foundational shell configuration.
**Mode:** mvp
**Depends on:** Nothing (first phase)
**Requirements:** SHELL-01, SHELL-02, SHELL-03, SHELL-04, SHELL-05, CACHE-01, CACHE-02, CACHE-03, CACHE-04, THEME-01, THEME-02, THEME-03
**Status:** ✅ Complete (v3.0)

Files:
- `modules/boot/prompt.zsh` — P10k instant prompt (FIRST)
- `modules/boot/timer-start.zsh` — EPOCHREALTIME capture
- `modules/boot/timer-end.zsh` — boot time calculation + `zshrc-time()`
- `modules/boot/compile.zsh` — bytecode compilation (&!)
- `modules/boot/theme.zsh` — P10k theme (LAST)
- `modules/core/environment.zsh` — PATH, XDG vars
- `modules/core/shell.zsh` — setopt, history (50K, dedup)
- `modules/plugins/cache.zsh` — version-fingerprinted plugin cache
- `modules/plugins/omz.zsh` — Oh My Zsh framework
- `modules/plugins/lazy.zsh` — optional zsh-defer lazy loading

### Phase 2: Productivity
**Goal:** User has efficient aliases and functions for daily terminal work — file listing, navigation, git workflow, system cleanup, and utility operations.
**Mode:** mvp
**Depends on:** Phase 1
**Requirements:** ALIAS-01, ALIAS-02, ALIAS-03, ALIAS-04, FUNC-01, FUNC-02, FUNC-03, FUNC-04, FUNC-05, FUNC-06, FUNC-07, FUNC-08
**Status:** ✅ Complete (v3.0)

Files:
- `modules/tools/aliases.zsh` — eza, grep, navigation, sys-clean
- `modules/tools/functions.zsh` — up, mkcd, nf, gcom, lazyg, sedi, extract, bk, port
- `modules/tools/nvidia.zsh` — NVIDIA/CUDA helpers
- `modules/tools/local.zsh` — ~/.zshrc.local loading

### Phase 3: Security
**Goal:** User credentials are protected from history leaks and dangerous system commands are blocked from accidental execution.
**Mode:** mvp
**Depends on:** Phase 1
**Requirements:** SEC-01, SEC-02, SEC-03
**Status:** ✅ Complete (v3.0)

Files:
- `modules/core/security.zsh` — history filter + sudo wrapper

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Performance | 2/2 | ✅ Complete | v3.0 |
| 2. Productivity | — | ✅ Complete | v3.0 |
| 3. Security | — | ✅ Complete | v3.0 |

## Future Ideas (Post-v3.0)

- `.zshenv` for non-interactive shell env vars (EDITOR, XDG)
- `bat` and `ripgrep` conditional aliases
- Completion tuning (zstyle menu select)
- Cross-distro package manager detection
