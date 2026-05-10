# Roadmap: Zsh Profile — Fedora Optimized

**Generated:** 2026-05-10
**Granularity:** Coarse (3 phases)
**Mode:** mvp

## Core Value

Shell starts fast, stays secure, and makes daily terminal work more productive without ceremony.

## Phases

- [ ] **Phase 1: Foundation & Performance** — Instant prompt, boot timer, path/history config, plugin cache with auto-rebuild, bytecode compilation, and proper Powerlevel10k theme loading
- [ ] **Phase 2: Productivity** — Eza file listing, navigation aliases/functions, colorized grep, distro-guarded sys-clean, git workflow functions, and utility functions (sedi, extract, bk, port, zshrc-time)
- [ ] **Phase 3: Security** — History filter blocking sensitive patterns (TOKEN, SECRET, PASSWORD, API_KEY, PRIVATE_KEY, CREDENTIAL), sudo wrapper blocking dangerous commands, and sudo !! warning

## Phase Details

### Phase 1: Foundation & Performance
**Goal:** Shell starts fast with instant prompt, efficient plugin caching, proper theme loading, and foundational shell configuration.
**Mode:** mvp
**Depends on:** Nothing (first phase)
**Requirements:** SHELL-01, SHELL-02, SHELL-03, SHELL-04, SHELL-05, CACHE-01, CACHE-02, CACHE-03, CACHE-04, THEME-01, THEME-02, THEME-03
**Success Criteria** (what must be TRUE):
  1. User sees prompt instantly (<50ms perceived) via Powerlevel10k Instant Prompt — no visible delay on shell start
  2. Shell boot time stays consistently under 150ms total, with color-coded feedback (green <150ms, yellow <200ms, red ≥500ms)
  3. Plugin cache auto-rebuilds when zoxide, eza, or fzf versions change (cache fingerprint uses version string or content hash, not binary path)
  4. PATH is deduplicated and includes ~/.local/bin and ~/bin — user can run locally installed tools without full paths
  5. History is preserved across sessions with 50K entries, deduplication, and cross-session sharing enabled
  6. Powerlevel10k theme loads at the very end of .zshrc, after ~/.zshrc.local overrides and .p10k.zsh configuration — prompt appears correctly with configured style
**Plans:** TBD

### Phase 2: Productivity
**Goal:** User has efficient aliases and functions for daily terminal work — file listing, navigation, git workflow, system cleanup, and utility operations.
**Mode:** mvp
**Depends on:** Phase 1
**Requirements:** ALIAS-01, ALIAS-02, ALIAS-03, ALIAS-04, FUNC-01, FUNC-02, FUNC-03, FUNC-04, FUNC-05, FUNC-06, FUNC-07, FUNC-08
**Success Criteria** (what must be TRUE):
  1. User can list files with `ls`/`ll`/`la`/`l`/`lt` using eza with icons, group-dirs-first, and git status indicators — output is colorized and scannable
  2. User can navigate quickly using `dtop` (go to Desktop), `mkcd` (create and enter directory), `up`/`up2`/`up3`/`up4` (go up N levels), `home`, `docs`
  3. User can create empty files with `nf <file>` (with confirmation), create timestamped backups with `bk <file>`, and extract any archive format with `extract <archive>`
  4. User can run safe sed with `sedi "pattern" <file>` (creates timestamped backup before modifying), check port usage with `port [num]`, and view boot time with `zshrc-time`
  5. User can commit all changes with `gcom "message"` (fails on clean repo — no empty commits) and use `lazyg "message"` for interactive commit with optional push (10s timeout)
  6. User can clean system with `dnf-clean` (remove orphaned deps + cache), `flatpak-clean` (remove unused runtimes), and `sys-clean` (both) — with distro guards preventing errors on non-Fedora systems
**Plans:** TBD

### Phase 3: Security
**Goal:** User credentials are protected from history leaks and dangerous system commands are blocked from accidental execution.
**Mode:** mvp
**Depends on:** Phase 1
**Requirements:** SEC-01, SEC-02, SEC-03
**Success Criteria** (what must be TRUE):
  1. Commands containing TOKEN, SECRET, PASSWORD, API_KEY, PRIVATE_KEY, or CREDENTIAL in any position are silently filtered from shell history
  2. Dangerous sudo commands (`rm -rf /`, `mkfs`, `dd of=`, `chmod -R 777 /`, recursive sudo) are blocked with an explanatory error message before execution
  3. User sees a prominent warning and must confirm before executing `sudo !!` when it matches dangerous patterns — accidental repeats of destructive commands are prevented
**Plans:** TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Performance | 0/0 | Not started | - |
| 2. Productivity | 0/0 | Not started | - |
| 3. Security | 0/0 | Not started | - |
