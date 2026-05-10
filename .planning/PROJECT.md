# Zsh Profile — Fedora Optimized

## What This Is

Zsh configuration optimized for Fedora Linux with Oh My Zsh and Powerlevel10k. Focus on fast shell startup (<150ms), intelligent plugin caching (zoxide, eza, fzf), productivity aliases/functions, and security safeguards for history and sudo commands. Forkable and installable — not distro-locked, but Fedora-first.

## Core Value

Shell starts fast, stays secure, and makes daily terminal work more productive without ceremony.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] **PERF-01**: Boot time consistently under 150ms (Powerlevel10k instant prompt + plugin caching)
- [ ] **SEC-01**: History filters sensitive patterns (TOKEN, SECRET, PASSWORD, API_KEY)
- [ ] **SEC-02**: Sudo wrapper blocks dangerous commands (rm -rf /, mkfs, dd, chmod -R 777)
- [ ] **ALIAS-01**: File listing aliases via eza (ls, ll, la, l, lt) with icons and git status
- [ ] **FUNC-01**: Navigation functions (dtop, mkcd, up[n]) for directory traversal
- [ ] **FUNC-02**: Git workflow functions (gcom, lazyg) with safety checks
- [ ] **FUNC-03**: Utility functions (sedi, extract, bk, port, zshrc-time)
- [ ] **SYSCLEAN-01**: DNF and Flatpak cleanup aliases (dnf-clean, flatpak-clean, sys-clean)
- [ ] **CACHE-01**: Plugin cache auto-rebuilds when tool versions change
- [ ] **COMPAT-01**: Works on Fedora, functional on other distros with package manager adaptation

### Out of Scope

- macOS primary support — Fedora-first, other distros secondary
- GUI configuration tools — terminal-driven only
- Zsh framework alternatives (prezto, zim) — Oh My Zsh is the chosen framework

## Context

- Built with AI assistance across all phases (code generation, review, docs)
- Existing `.zshrc` at version 2.2 with 320 lines, bilingual docs (pt-BR + en)
- Graphify knowledge graph built — reveals 264 nodes, 16 communities, arquitetura do .zshrc as central hub (17 edges)
- Installed via `cp .zshrc ~/.zshrc` — no package manager, no init system integration

## Constraints

- **OS**: Fedora Linux (DNF package manager) — primary target
- **Shell**: Zsh + Oh My Zsh + Powerlevel10k — non-negotiable stack
- **Performance**: Sub-150ms boot target drives all architecture decisions
- **Security**: History and sudo protections implemented in-shell, not external tools
- **Dependencies**: eza, fzf, zoxide are optional but enable core features

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Plugin cache over OMZ plugin manager | 30-50% faster boot by caching init scripts | — Pending |
| Powerlevel10k instant prompt first | Required by P10k — must load before anything else | — Pending |
| Fingerprint-based cache invalidation | Rebuild only when tool versions change, not on every shell start | — Pending |
| Bytecode compilation (.zshrc.zwc) | Faster parsing on subsequent loads | — Pending |
| sudo() wrapper instead of plugin | More control over dangerous patterns, no external dep | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? — Move to Out of Scope with reason
2. Requirements validated? — Move to Validated with phase reference
3. New requirements emerged? — Add to Active
4. Decisions to log? — Add to Key Decisions
5. "What This Is" still accurate? — Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-10 after initialization*
