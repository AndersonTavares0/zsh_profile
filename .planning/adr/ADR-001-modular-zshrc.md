# ADR-001: Modular .zshrc Architecture

**Status:** Accepted
**Date:** 2026-05-10
**Deciders:** AndersonTavares0

## Context

The `.zshrc` had grown into a 342-line monolithic file with 10 loosely-delimited sections. Adding features meant inserting lines between existing blocks, making it hard to verify load order, find specific config, or contribute. The file had no formal structure beyond `# === SEPARATOR ===` comments.

## Decision

Split `.zshrc` into 14 self-documenting module files organized in 4 functional directories, sourced in strict dependency order by a thin entry-point `.zshrc`.

### Module Directory Structure

```
modules/
├── boot/                  # Startup chain (order-critical)
│   ├── prompt.zsh         # ① P10k instant prompt (first line sourced)
│   ├── timer-start.zsh    # ② Wall-clock timer init (EPOCHREALTIME)
│   ├── theme.zsh          # ⑫ P10k theme loading (last substantive source)
│   ├── compile.zsh        # ⑬ Bytecode compilation (background, no output)
│   └── timer-end.zsh      # ⑭ Timer calculation + zshrc-time command
│
├── core/                  # Shell foundation (no external deps)
│   ├── environment.zsh    # ③ PATH dedup, user bins, XDG base directories
│   ├── shell.zsh          # ④ Zsh options, 50K history, dedup, sharing
│   └── security.zsh       # ⑤ History credential filter + sudo wrapper
│
├── plugins/               # Framework & plugin loading
│   ├── cache.zsh          # ⑥ Version-fingerprint plugin init cache
│   ├── omz.zsh            # ⑦ Oh My Zsh framework + conditional plugins
│   └── lazy.zsh           # ⑧ zsh-defer deferred source (optional)
│
└── tools/                 # User-facing productivity
    ├── aliases.zsh        # ⑨ eza, grep, navigation, system cleanup
    ├── functions.zsh      # ⑩ up, mkcd, nf, gcom, lazyg, sedi, extract, bk, port
    └── local.zsh          # ⑪ ~/.zshrc.local overrides (machine-specific)
```

### Entry-point `.zshrc`

44 lines. Two concerns:
1. Resolve module directory (`$HOME/.zsh_modules` symlink → repo-relative fallback)
2. Source all modules in numbered order with inline rationale comments

### Loading Order Contract

| # | File | Phase | Constraint |
|---|------|-------|-----------|
| ① | boot/prompt.zsh | Boot | **MUST be first** — P10k Instant Prompt requires zero output before it |
| ② | boot/timer-start.zsh | Boot | Must start before any computation |
| ③-⑤ | core/*.zsh | Core | No dependencies between these three files |
| ⑥-⑧ | plugins/*.zsh | Plugins | `cache.zsh` before `omz.zsh` (fingerprint must validate first) |
| ⑨-⑪ | tools/*.zsh | Tools | Must load after plugins (aliases may reference plugin features) |
| ⑫ | boot/theme.zsh | Boot | **MUST be last substantive source** — P10k theme contract |
| ⑬ | boot/compile.zsh | Boot | After theme (no stdout after prompt rendering) |
| ⑭ | boot/timer-end.zsh | Boot | After everything (measures total elapsed time) |

## Consequences

### Positive
- **Discoverability**: Module name communicates its purpose; directory communicates its architectural layer
- **Testability**: Individual modules can be sourced independently for testing (`zsh -n modules/boot/prompt.zsh`)
- **Contribution safety**: Adding a new alias touches only `tools/aliases.zsh` — no risk of breaking security or theme loading
- **Documentation proximity**: Each module contains its own rationale comments; no need to cross-reference a separate docs file
- **15→598 LOC growth is documentation, not complexity**: Average module is 39 lines including full explanatory comments

### Negative
- **14 `source` calls** add ~1-3ms to boot time (mitigated by `.zwc` bytecode compilation)
- **Inter-module coupling** via global variables (`_zshrc_start_s`, `_PLUGIN_CACHE`) must be maintained
- **New contributor learning curve**: Must understand the loading order contract before modifying

### Neutral
- Variable naming convention: internal globals prefixed with `_zsh_` or `_ZSHRC_`; Zsh special parameters (`HISTFILE`, `HISTSIZE`, `plugins`) use bare assignment (language standard)
- `typeset -g` used for explicitly global variables that cross module boundaries; function-local variables use `local`

## Alternatives Considered

### Single monolithic .zshrc (status quo ante)
**Rejected.** 342 lines with implicit section boundaries. Adding any feature required reading the entire file to understand ordering constraints. Boot-time ordering violations were easy to introduce (e.g., placing output before P10k Instant Prompt).

### Oh My Zsh `custom/` plugin-per-feature
**Rejected.** Would require OMZ plugin boilerplate (`*.plugin.zsh` naming, `plugins=(...)` registration). Over-engineering for what are simple `source` statements. Also couples the config to OMZ's directory structure.

### Single `zsh/` directory with numbered files (v1 modularization)
**Evolved.** The flat numbered-prefix approach (`01-prompt.zsh` through `14-boot-end.zsh`) was functional but:
- Numbers in filenames communicate order but not purpose
- Adding a file between 07 and 08 requires renumbering
- Users scanning the directory don't know which files are "core" vs "plugins" vs "tools"

The 4-subdirectory structure was chosen as the v2 improvement: directories communicate architectural layers, filenames communicate purpose, and the entry-point `.zshrc` communicates order.

## Distilled Principles

From the codebase analysis, these cross-cutting principles govern the modular architecture:

| # | Principle | Applied In |
|---|-----------|-----------|
| P1 | Zero output before P10k Instant Prompt — no echo, printf, or command substitution before `boot/prompt.zsh` | boot/prompt.zsh |
| P2 | Internal globals use `_` prefix; cross-module globals use `typeset -g` | timer-start.zsh, cache.zsh |
| P3 | Clean up internal state after use (`unset` private vars, `trap -` reset) | cache.zsh:88, timer-end.zsh:8, functions.zsh:100 |
| P4 | One concern per file — aliases ≠ functions ≠ security ≠ cache | All 14 modules |
| P5 | Fail gracefully on missing dependencies (`command -v` guards, `|| return 1`) | aliases.zsh, cache.zsh, omz.zsh, lazy.zsh |
| P6 | Atomic write pattern (`mktemp → write → mv`) for all cache/backup operations | cache.zsh:43-56, functions.zsh:95-100 |
| P7 | Self-documenting: why not what — comments explain flags, patterns, and rationale | All modules |

## Related

- `AGENTS.md` — Agent workflow guide, GSD project context
- `.planning/PROJECT.md` — Core value and constraints
- `readme.md` — User-facing documentation with architecture diagram
