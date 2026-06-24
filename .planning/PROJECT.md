# Zsh Profile — Fedora Optimized

## What This Is

Zsh configuration optimized for Fedora Linux with Oh My Zsh and Powerlevel10k. Focus on fast shell startup (<150ms), intelligent plugin caching (zoxide, eza, fzf), productivity aliases/functions, and security safeguards for history and sudo commands. Forkable and installable — not distro-locked, but Fedora-first.

## Core Value

Shell starts fast, stays secure, and makes daily terminal work more productive without ceremony.

## Requirements

### Validated (v3.0)

- [x] **PERF-01**: Boot time consistently under 150ms (Powerlevel10k instant prompt + plugin caching)
- [x] **SEC-01**: History filters sensitive patterns (TOKEN, SECRET, PASSWORD, API_KEY, URL tokens, SSH/GPG)
- [x] **SEC-02**: Sudo wrapper blocks dangerous commands (rm -rf /, mkfs, dd, chmod -R 777)
- [x] **ALIAS-01**: File listing aliases via eza (ls, ll, la, l, lt) with icons and git status
- [x] **FUNC-01**: Navigation functions (dtop, mkcd, up[n]) for directory traversal
- [x] **FUNC-02**: Git workflow functions (gcom, lazyg) with safety checks
- [x] **FUNC-03**: Utility functions (sedi, extract, bk, port, zshrc-time)
- [x] **SYSCLEAN-01**: DNF and Flatpak cleanup aliases (dnf-clean, flatpak-clean, sys-clean)
- [x] **CACHE-01**: Plugin cache auto-rebuilds when tool versions change
- [x] **COMPAT-01**: Works on Fedora, functional on other distros with package manager adaptation

### Out of Scope

- macOS primary support — Fedora-first, other distros secondary
- GUI configuration tools — terminal-driven only
- Zsh framework alternatives (prezto, zim) — Oh My Zsh is the chosen framework

## Context

- Built with AI assistance across all phases (code generation, review, docs)
- Current version: **v3.0** — modular architecture with 15 files in `modules/{boot,core,plugins,tools}/`
- Entry-point `.zshrc` is 51 lines — sources modules in strict dependency order
- Version history: v2.2 (monolithic 320-line `.zshrc`) → v3.0 (modular 15 files)
- Interactive installer via curl: `curl -fsSL https://raw.githubusercontent.com/AndersonTavares0/zsh_profile/main/install.sh | bash`
- Graphify knowledge graph available at `graphify-out/`

## Constraints

- **OS**: Fedora Linux (DNF package manager) — primary target
- **Shell**: Zsh + Oh My Zsh + Powerlevel10k — non-negotiable stack
- **Performance**: Sub-150ms boot target drives all architecture decisions
- **Security**: History and sudo protections implemented in-shell, not external tools
- **Dependencies**: eza, fzf, zoxide are optional but enable core features

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Plugin cache over OMZ plugin manager | 30-50% faster boot by caching init scripts | ✅ `modules/plugins/cache.zsh` — version-fingerprinted |
| Powerlevel10k instant prompt first | Required by P10k — must load before anything else | ✅ `modules/boot/prompt.zsh` — first sourced line |
| Fingerprint-based cache invalidation | Rebuild only when tool versions change | ✅ `cksum(tool --version \| head -1)` — detects DNF updates |
| Bytecode compilation (.zshrc.zwc) | Faster parsing on subsequent loads | ✅ `modules/boot/compile.zsh` — background via &! |
| sudo() wrapper instead of plugin | More control over dangerous patterns, no external dep | ✅ `modules/core/security.zsh` |
| Modular 15-file architecture | One concern per file, strict dependency order | ✅ v3.0 — `modules/{boot,core,plugins,tools}/` |

## Evolution

This document reflects the current v3.0 state. Future updates will track new milestones.

---
*Last updated: 2026-06-24 — synchronized with v3.0 implementation*
