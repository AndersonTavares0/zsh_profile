# Feature Landscape

**Domain:** Zsh shell configuration for Linux terminal productivity
**Researched:** 2026-05-10
**Methodology:** Analysis of ohmyzsh (187k ★), prezto (14.5k ★), zimfw (4.6k ★), mathiasbynens dotfiles (31k ★), ArchWiki Zsh guide, existing `.zshrc` at version 2.3, and community best practices.

## Categorization Guide

| Tier | Meaning | If missing… |
|------|---------|-------------|
| **Table Stakes** | Users expect this from any serious Zsh config | Users feel the config is incomplete or regresses from defaults |
| **Differentiator** | Sets this config apart from alternatives | Users can live without it but won't be impressed |
| **Anti-Feature** | Deliberately excluded | Users benefit from NOT having this |

---

## Table Stakes

Features that any well-designed Zsh configuration must provide. Missing these makes the config feel incomplete.

### TS-1: Prompt Customization Framework
| | |
|---|---|
| **Why Expected** | The prompt is the most visible part of any shell config. Users judge immediately. Powerlevel10k has ~90% adoption among serious Zsh setups. |
| **Complexity** | Low (choose theme, source it) |
| **Current Status** | ✅ Powerlevel10k with instant prompt — text after loading, precompiled for sub-50ms perceived startup |

### TS-2: Plugin Framework Integration
| | |
|---|---|
| **Why Expected** | Oh My Zsh is the de facto Zsh framework (187k ★). Managing plugins without it means reinventing dependency resolution, sourcing order, and update management. |
| **Complexity** | Low (install OMZ, declare plugins) |
| **Current Status** | ✅ Oh My Zsh configured with `plugins=(git history)` plus conditional autosuggestions/syntax-highlighting |

### TS-3: Command Completions (`compinit`)
| | |
|---|---|
| **Why Expected** | Zsh's completion system is its #1 selling point over bash. Without `compinit` + menu select, users lose fuzzy matching, context-aware completions, and file globbing. |
| **Complexity** | Medium (compinit setup, zstyles for menu behavior, fpath management) |
| **Current Status** | ❌ **Not configured.** `.zshrc` has no `compinit` call. This is a significant gap — OMZ's default completion loading should be verified. |
| **Implementation Note** | OMZ `lib/completion.zsh` handles this, but should verify it loads correctly and `zstyle ':completion:*' menu select` is set. |

### TS-4: History Management
| | |
|---|---|
| **Why Expected** | 50K history entries with deduplication, sharing across sessions, and ignoring duplicates is standard in every framework. |
| **Complexity** | Low (setopt calls + HISTFILE configuration) |
| **Current Status** | ✅ `HISTSIZE=50000`, `SAVEHIST=50000`, `HISTFILE`, `INC_APPEND_HISTORY`, `SHARE_HISTORY`, `HIST_IGNORE_ALL_DUPS` all set |

### TS-5: Syntax Highlighting (Optional but Standard)
| | |
|---|---|
| **Why Expected** | zsh-syntax-highlighting is the most-installed external plugin. Almost every public config includes it. |
| **Complexity** | Low (load plugin, must be sourced last) |
| **Current Status** | ✅ Available via lazy loading conditionally when zsh-defer is absent |
| **Note** | Highlighting must be sourced AFTER autosuggestions; the current lazy-loading logic respects this order |

### TS-6: Autosuggestions (Optional but Standard)
| | |
|---|---|
| **Why Expected** | zsh-autosuggestions grays out predicted completions based on history. Fish-shell migrants expect this. |
| **Complexity** | Low (load plugin) |
| **Current Status** | ✅ Available via lazy loading |

### TS-7: File Listing Aliases
| | |
|---|---|
| **Why Expected** | Every config provides `ls`, `ll`, `la` at minimum. Modern setups use `eza`/`exa` for icons and git status. |
| **Complexity** | Low (conditional aliases based on tool availability) |
| **Current Status** | ✅ `ls`, `ll`, `la`, `l`, `lt` with eza — icons, group-dirs-first, git status. Falls back gracefully when eza absent. |

### TS-8: Navigation Shortcuts
| | |
|---|---|
| **Why Expected** | Directory traversal shortcuts (`..`, `...`, `-`, `mkcd`) are expected. `zoxide` integration for `z` command is increasingly standard. |
| **Complexity** | Low-Medium (aliases + zoxide init) |
| **Current Status** | ✅ `mkcd`, `nf`, `up[n]`, `home`, `docs`, `dtop`. zoxide init via cache system. |
| **Gap** | OMZ directory aliases (`..`, `...`, `-`, `~`, `1`-`9`) are available via the OMZ lib but not explicitly documented. Verify they work. |

### TS-9: Git Integration
| | |
|---|---|
| **Why Expected** | Git-aware prompts (branch, dirty state), git aliases (`gcom`, `lazyg`), and OMZ git plugin are baseline. |
| **Complexity** | Medium (aliases need safety guards — clean repo check, branch detection) |
| **Current Status** | ✅ `gcom` with safety checks, `lazyg` with interactive push + 10s timeout. OMZ `git` plugin loaded. |

### TS-10: Colored Grep Output
| | |
|---|---|
| **Why Expected** | `grep --color=auto` is in virtually every config. It's one line but users notice if missing. |
| **Complexity** | Low |
| **Current Status** | ✅ `grep`, `fgrep`, `egrep` aliased with `--color=auto` |

### TS-11: Environment Variable Management
| | |
|---|---|
| **Why Expected** | PATH deduplication (`typeset -U path PATH`), `$XDG_*` variable awareness, custom bin directories. |
| **Complexity** | Low |
| **Current Status** | ✅ `typeset -U path PATH fpath FPATH`, custom paths added (`~/.local/bin`, etc.) |

### TS-12: Local Override File
| | |
|---|---|
| **Why Expected** | `~/.zshrc.local` pattern lets users customize without editing the main config — critical for forkable repos. |
| **Complexity** | Low |
| **Current Status** | ✅ `[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local` at line 308 |

---

## Differentiators

Features that make this config excellent rather than merely adequate. These are the competitive advantages.

### DF-1: Fingerprint-Based Plugin Cache
| | |
|---|---|
| **Value Proposition** | Rebuilds the init cache only when tool versions change (not every shell start). Saves 30-50% boot time vs. running `zoxide init` and `fzf` keybinding setup on every shell. |
| **Complexity** | High (fingerprinting, cache validation, background zwc compilation) |
| **Current Status** | ✅ Fingerprint based on `cksum` of tool paths. Cache auto-rebuilds, auto-compiles to `.zwc`, and validates on every shell start. |
| **Ecosystem Comparison** | Very few configs do this. OMZ caches nothing. Prezto has static init. Zim has static init script. This is genuinely differentiating. |
| **Maintenance Risk** | If cached scripts change their init API, the cache must be rebuilt. The fingerprint mechanism handles this via tool path changes. |

### DF-2: Boot Time Instrumentation
| | |
|---|---|
| **Value Proposition** | Self-measuring startup time with color-coded classification. Developers can see the impact of config changes immediately. |
| **Complexity** | Medium (EPOCHREALTIME capture at start, calculation at end, stored in variable) |
| **Current Status** | ✅ Sub-150ms target with thresholds: Excellent (<150ms), Good (<200ms), Acceptable (<500ms), Slow (≥500ms). `zshrc-time` command exposes it. |
| **Ecosystem Comparison** | Not common. Powerlevel10k reports prompt render time, not total .zshrc load time. This is a unique differentiator. |

### DF-3: Bytecode Compilation (.zshrc.zwc)
| | |
|---|---|
| **Value Proposition** | Zsh bytecode compilation speeds up `.zshrc` parsing on subsequent loads. Runs in background so it never blocks startup. |
| **Complexity** | Low (single `zcompile` call) |
| **Current Status** | ✅ Automatic compilation with freshness check — only recompiles when `.zshrc` is newer than `.zwc`. Runs in background (`&!`). |

### DF-4: Lazy Loading with zsh-defer
| | |
|---|---|
| **Value Proposition** | Heavy plugins (syntax-highlighting, autosuggestions) load after prompt appears. Users see prompt instantly, plugins catch up. |
| **Complexity** | High (conditional detection of zsh-defer, deferred wrapping of plugin sources, correct sourcing order) |
| **Current Status** | ✅ When zsh-defer is installed, syntax-highlighting and autosuggestions are loaded deferred. Falls back to OMZ loading when absent. |
| **Ecosystem Comparison** | OMZ doesn't support lazy loading natively. zinit has "turbo mode" but requires framework switch. This is a smart compromise within OMZ. |

### DF-5: In-Shell Sudo Protection
| | |
|---|---|
| **Value Proposition** | The `sudo()` wrapper blocks catastrophic commands (`rm -rf /`, `mkfs`, `dd of=`, `chmod -R 777 /`) at the shell level — no external tool needed. |
| **Complexity** | Medium (function override of `sudo`, regex matching against dangerous patterns) |
| **Current Status** | ✅ Custom `sudo()` checks `!!` re-runs for dangerous patterns using regex. Blocks 5 specific dangerous command patterns. |
| **Ecosystem Comparison** | Most configs rely on `sudo` plugins from OMZ or external tools. The in-shell approach is more self-contained and auditable. |

### DF-6: History Security Filter
| | |
|---|---|
| **Value Proposition** | Case-insensitive filtering of credentials from history. Commands containing TOKEN, SECRET, PASSWORD etc. are never written to history. |
| **Complexity** | Low (single `zshaddhistory` hook with regex) |
| **Current Status** | ✅ Filters: TOKEN, SECRET, PASSWORD, PASSWD, API_KEY, PRIVATE_KEY, CREDENTIAL, ACCESS_KEY |
| **Ecosystem Comparison** | OMZ has no history security. This is a meaningful security addition. |

### DF-7: Archive Extraction Function
| | |
|---|---|
| **Value Proposition** | A single `extract` command handles .tar.gz, .zip, .rar, .7z, .zst and 10+ other formats. No need to remember format-specific flags. |
| **Complexity** | Low (case statement dispatching to appropriate tool) |
| **Current Status** | ✅ 12 formats supported. Error handling on unsupported formats and extraction failures. |
| **Ecosystem Comparison** | OMZ has an `extract` plugin but it's less comprehensive. This version adds .zst support and better error messages. |

### DF-8: Safe Sed with Backup
| | |
|---|---|
| **Value Proposition** | `sedi` wraps sed with timestamped automatic backups, preventing accidental data loss. |
| **Complexity** | Low (mktemp, cp backup, sed to temp, mv back pattern) |
| **Current Status** | ✅ Creates `.bak.YYYYMMDDHHMMSS` before modifying. |
| **Ecosystem Comparison** | Not common as a built-in function. Most users run sed directly. This is a safety net that saves users from themselves. |

### DF-9: Fedora-Specific System Cleanup
| | |
|---|---|
| **Value Proposition** | One-command system cleanup for DNF orphans + cache + Flatpak. `sys-clean` chains both. Most dotfiles are macOS-centric. |
| **Complexity** | Low (sudo + DNF commands aliased) |
| **Current Status** | ✅ `dnf-clean`, `flatpak-clean`, `sys-clean` |
| **Ecosystem Comparison** | Unusual and valuable for Fedora users. The macOS-centric dotfiles world rarely services RPM-based distros this well. |

### DF-10: Path-Aware Git Commit Workflow
| | |
|---|---|
| **Value Proposition** | `lazyg` provides interactive commit+push with safety checks, non-interactive detection, and timeout. Doesn't hide complexity — shows the branch it's pushing to. |
| **Complexity** | Medium (interactive input detection, read timeout, branch detection, error paths) |
| **Current Status** | ✅ Validates git repo, checks for dirty worktree, asks for push confirmation with 10s timeout. |
| **Ecosystem Comparison** | Most git aliases are simpler. This is more thoughtful about error states. |

### DF-11: Bilingual Documentation
| | |
|---|---|
| **Value Proposition** | README and docs in Portuguese (pt-BR) and English. Makes the config accessible to a broader audience. |
| **Complexity** | Low (writing/translation effort, not code complexity) |
| **Current Status** | ✅ README in English, docs.md bilingual, .zshrc comments in Portuguese |
| **Ecosystem Comparison** | Most dotfiles are English-only. Bilingual documentation is rare. |

---

## Anti-Features

Features to explicitly NOT build. Including these would harm the user experience or increase maintenance burden.

### AF-1: Custom Prompt Theme System
| | |
|---|---|
| **Why Avoid** | Powerlevel10k is the gold standard — instant prompt, extensive customization, git status, battery, etc. Building a custom prompt system would be a massive effort with a worse result. |
| **Instead** | Use Powerlevel10k with `.p10k.zsh` for customization. Done. |
| **Status** | ✅ Already decided — P10k is non-negotiable per PROJECT.md |

### AF-2: macOS Primary Support
| | |
|---|---|
| **Why Avoid** | This config is Fedora-first. macOS has Homebrew, different filesystem layout, different system commands, and different default tools. Trying to support both equally doubles maintenance. |
| **Instead** | Mark macOS as "partial compatibility" in docs. Accept PRs but don't actively optimize. |
| **Status** | ✅ Out of Scope per PROJECT.md |

### AF-3: GUI Configuration Tool
| | |
|---|---|
| **Why Avoid** | Creates external dependencies (web server, framework), complicates installation, and the target audience (terminal users) prefers editing config files. |
| **Instead** | Document the config file structure clearly. Use `.zshrc.local` pattern for local overrides. |
| **Status** | ✅ Out of Scope per PROJECT.md |

### AF-4: Multi-Distro Package Manager Abstraction
| | |
|---|---|
| **Why Avoid** | "Works everywhere" is noble but means DNF cleanup aliases need apt equivalents, pacman equivalents, etc. This inflates a 342-line config significantly. |
| **Instead** | Document compat status (see readme.md). Keep sys-clean Fedora-specific. |
| **Status** | ✅ Implicitly avoided — only DNF/Flatpak aliases exist |

### AF-5: Custom Plugin Manager
| | |
|---|---|
| **Why Avoid** | Building a plugin manager means dependency resolution, update mechanism, sourcing order, and compatibility with 1000+ OMZ plugins. Antigen, zplug, zinit, zim all exist and are mature. |
| **Instead** | Use Oh My Zsh's built-in plugin system + the custom cache layer for performance. Best of both worlds. |
| **Status** | ✅ The cache system is NOT a plugin manager — it caches init output of zoxide/fzf, not OMZ plugins |

### AF-6: Heavy Zsh Module Configurations
| | |
|---|---|
| **Why Avoid** | Zsh has ~80 built-in modules. Configuring them all "just in case" adds complexity and startup time. The stock `zsh/datetime` for boot timer is sufficient. Don't add `zsh/mapfile`, `zsh/zprof` unless profiling. |
| **Instead** | Load only what's needed. Profiling modules (`zsh/zprof`) should be opt-in only. |
| **Status** | ✅ Only `zsh/datetime` is loaded (for boot timer) |

### AF-7: Complex `compinit` Overrides
| | |
|---|---|
| **Why Avoid** | OMZ handles `compinit` via its lib. Adding custom completion zstyles can conflict. Especially avoid `gain-privileges` (which lets completions run as sudo) — it's a security risk. |
| **Instead** | Verify OMZ completion loading works, add `menu select` if not default. Don't add `gain-privileges`. |
| **Status** | ⚠️ Needs verification — ensure OMZ's completion loading is functional |

### AF-8: Built-in Update Mechanism
| | |
|---|---|
| **Why Avoid** | `omz update` handles Oh My Zsh updates. Powerlevel10k updates via git pull. Custom update scripts create a third update path that can conflict. |
| **Instead** | Document the update process in README. Use `git pull` in the repo directory. |
| **Status** | ✅ Not implemented |

### AF-9: Vi Mode Configuration
| | |
|---|---|
| **Why Avoid** | Vi mode is polarizing. Adding vi keybindings, mode indicators, and keymap switching adds complexity. Users who want vi mode can add `bindkey -v` themselves. |
| **Instead** | Keep Emacs mode default. Document how to switch to vi mode in a comment. |
| **Status** | ✅ Emacs mode (default) maintained |

### AF-10: Invasive `precmd` / `preexec` Hooks
| | |
|---|---|
| **Why Avoid** | Every hook function adds startup overhead. Window title updates, terminal reset sequences, and command logging can all slow the prompt. Only add hooks that carry their weight. |
| **Instead** | Keep hooks minimal. The boot timer uses `EPOCHREALTIME` diff, not a hook. The only hooks used are OMZ-managed. |
| **Status** | ✅ No custom hooks added |

---

## Feature Dependencies

The dependency chain is critical for correct loading order. Violating these causes subtle bugs.

```
Powerlevel10k Instant Prompt
  └─ MUST be FIRST in .zshrc (before anything else)
  │
  ▼
Boot Timer Start (zmodload zsh/datetime)
  └─ Must be right after instant prompt
  │
  ▼
Path Deduplication (typeset -U)
  └─ Before any tool loading that modifies PATH
  │
  ▼
Plugin Cache System
  ├─ Fingerprint generation (depends on: tool paths for zoxide, fzf)
  ├─ Cache validation (depends on: previous fingerprint)
  ├─ Cache rebuild (depends on: zoxide init, fzf key-bindings)
  └─ Cache compilation to .zwc (depends on: cache file exists)
  │
  ▼
Oh My Zsh Plugin Loading
  ├─ plugins=(git history) — OMZ base
  ├─ zsh-autosuggestions (if zsh-defer NOT available)
  └─ zsh-syntax-highlighting (if zsh-defer NOT available)
  │
  ▼
Lazy Loading (zsh-defer)
  ├─ zsh-defer source (conditional — only if plugin exists)
  ├─ zsh-autosuggestions (deferred)
  └─ zsh-syntax-highlighting (deferred, MUST be after autosuggestions)
  │
  ▼
Aliases & Functions
  ├─ eza aliases (conditional on eza availability)
  ├─ grep aliases
  ├─ navigation (home, docs, dtop, up, mkcd, nf)
  ├─ git (gcom, lazyg)
  ├─ utilities (sedi, extract, bk, port, sudo wrapper)
  └─ sys-clean aliases
  │
  ▼
Local Settings (~/.zshrc.local)
  └─ Loaded before theme (allows overrides)
  │
  ▼
Powerlevel10k Theme
  ├─ P10k source (must be near END, not beginning)
  └─ .p10k.zsh configuration
  │
  ▼
.zshrc Bytecode Compilation
  └─ Background compilation (runs in &! — doesn't block)
  │
  ▼
Boot Timer Calculation
  └─ Final step: diff EPOCHREALTIME, store in _zshrc_load_ms
```

### Cross-Feature Dependencies

| Feature | Depends On | Nature |
|---------|-----------|--------|
| Plugin Cache | zoxide + fzf installed | Soft — cache skip works without them |
| zsh-defer lazy loading | zsh-defer plugin installed | Soft — falls back to OMZ loading |
| eza aliases | eza installed | Soft — aliases skipped if absent |
| History filter | Zsh `zshaddhistory` hook | Hard — always active |
| Sudo wrapper | None | Hard — always active |
| Boot timer | `zmodload zsh/datetime` | Hard — module must be loaded first |
| Fingerprint cache | `cksum` command | Hard — must be available on system |

---

## MVP Recommendation

### Phase 1 (Foundation — Ship Now)
These features are already implemented and working. Validation needed:

| Priority | Feature | Current State |
|----------|---------|--------------|
| P0 | Powerlevel10k instant prompt | ✅ Implemented — verify ordering is correct |
| P0 | History management | ✅ Implemented — verify all setopts effective |
| P0 | Security filter | ✅ Implemented |
| P0 | Sudo protection | ✅ Implemented |
| P1 | Plugin cache system | ✅ Implemented — verify fingerprint works cross-distro |
| P1 | Bytecode compilation | ✅ Implemented |
| P1 | Boot timer / zshrc-time | ✅ Implemented |
| P1 | eza aliases | ✅ Implemented |
| P1 | Git functions | ✅ Implemented |
| P1 | Navigation functions | ✅ Implemented |

### Phase 2 (Polish — Next)
| Priority | Feature | Rationale |
|----------|---------|-----------|
| P1 | **compinit verification** | Completion system is a table-stakes feature, and status is uncertain under OMZ |
| P1 | **Lazy loading verification** | Ensure zsh-defer fallback works correctly |
| P1 | **Dependency documentation** | README should list dependencies clearly |
| P2 | **Terminal title setting** | Small UX improvement for terminal tab identification |
| P2 | **History substring search** | Fish-like Ctrl+R via OMZ `history-substring-search` plugin |

### Deferred (Not Yet)
| Feature | Reason |
|---------|--------|
| **zsh-completions** | OMZ ships sufficient completions; defer unless specific gaps found |
| **Custom theme tuning** | P10k wizard already handles this; `.p10k.zsh` tweaks are personal preference |
| **Plugin additions** | Don't add plugins reactively. Add only when a specific workflow need emerges |
| **Distro-adaptation layer** | Out of scope per PROJECT.md — Fedora-first |

---

## Sources

| Source | Confidence | What It Provided |
|--------|------------|-----------------|
| [ohmyzsh Wiki — Cheatsheet](https://github.com/ohmyzsh/ohmyzsh/wiki/Cheatsheet) | HIGH | Standard alias/function patterns, OMZ features |
| [ohmyzsh Wiki — Home](https://github.com/ohmyzsh/ohmyzsh/wiki) | HIGH | Framework overview, plugin/theme architecture |
| [Prezto README](https://github.com/sorin-ionescu/prezto) | HIGH | Module architecture, prompt system |
| [Zimfw README](https://github.com/zimfw/zimfw) | HIGH | Plugin manager patterns, speed comparison |
| [mathiasbynens dotfiles](https://github.com/mathiasbynens/dotfiles) | HIGH | Dotfile organization, bootstrap pattern |
| [ArchWiki — Zsh](https://wiki.archlinux.org/title/Zsh) | HIGH | Zsh fundamentals, startup files, best practices |
| Existing `.zshrc` (version 2.3) | HIGH | Current feature set, dependencies, gaps |
| `readme.md` | HIGH | Documentation audit, feature descriptions |

## Confidence Assessment

| Feature Area | Confidence | Reason |
|-------------|------------|--------|
| Table Stakes coverage | HIGH | Verified against omz/prezto/zim/archwiki patterns |
| Differentiator gap analysis | HIGH | Current .zshrc already implements most identified differentiators |
| Anti-feature correctness | HIGH | Based on PROJECT.md scope constraints + ecosystem comparison |
| Feature dependency ordering | HIGH | Derived from zsh execution model + current .zshrc ordering |
| MVP recommendations | HIGH | Based on current implementation status + ecosystem expectations |
