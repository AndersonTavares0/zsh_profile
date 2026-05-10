# Zsh Profile Agent Guide

## Essential Commands
- `zshrc-time` - Check shell load time performance
- `dtop` - Navigate to ~/Desktop
- `mkcd <dir>` - Create directory and cd into it
- `nf <file>` - Create empty file with confirmation
- `gcom "message"` - Git add all and commit (fails if clean repo)
- `lazyg "message"` - Interactive git commit with optional push (10s timeout)
- `sedi "pattern" <file>` - Safe sed with automatic timestamped backup
- `extract <archive>` - Extract .tar.gz, .zip, .rar, .7z etc.
- `bk <file>` - Create timestamped backup
- `port [num]` - Check port usage (ss -tulpn)
- `dnf-clean` - Remove orphaned deps and clean DNF cache
- `flatpak-clean` - Remove unused Flatpak runtimes
- `sys-clean` - Run both DNF and Flatpak cleanup

## Critical Execution Order
1. Powerlevel10k instant prompt MUST be first in .zshrc
2. Boot timer starts immediately after prompt
3. Path deduplication occurs early
4. Plugin cache validation happens before Oh My Zsh load
5. Oh My Zsh plugins load after cache initialization
6. Lazy loading (if enabled) happens after OMZ
7. Aliases and functions defined after plugin sourcing
8. Powerlevel10k theme loads at the very end
9. .zshrc auto-compilation to .zshrc.zwc runs in background

## Plugin Cache System
- Watches: zoxide, eza, fzf
- Rebuilds when any watched tool version changes or cache missing
- Fingerprint based on tool paths: `tool=/path/to/tool;`
- Cache location: $XDG_CACHE_HOME/zsh_plugins_init.zsh
- Rebuild triggered automatically in .zshrc

## Performance Optimizations
- Instant prompt via Powerlevel10k
- Intelligent plugin cache (30-50% faster boot)
- .zshrc bytecode compilation (.zshrc.zwc)
- Lazy loading option for heavy plugins (zsh-defer)
- Boot time tracking with classification:
  - <150ms: Excellent
  - <200ms: Good
  - <500ms: Acceptable
  - ≥500ms: Slow

## Security Features
- History filtering: Blocks commands containing TOKEN, SECRET, PASSWORD etc.
- Sudo protection: Blocks sudo rm -rf /, mkfs, dd of=, chmod -R 777 /, and recursive sudo
- All sudo !! executions show warning and require confirmation for dangerous patterns

## Important Files
- `.zshrc` - Main configuration
- `~/.zshrc.local` - Local overrides (auto-loaded if exists)
- `$XDG_CACHE_HOME/zsh_plugins_init.zsh` - Plugin cache
- `~/.zshrc.zwc` - Bytecode compiled version
- `~/.p10k.zsh` - Powerlevel10k configuration

## Verification
- Run `zshrc-time` to check performance
- Check plugin cache validity: compares fingerprint of watched tools
- Verify oh-my-zsh.sh is sourced after plugin setup
- Confirm Powerlevel10k loads last for proper theme application

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Zsh Profile — Fedora Optimized**

Zsh configuration optimized for Fedora Linux with Oh My Zsh and Powerlevel10k. Focus on fast shell startup (<150ms), intelligent plugin caching (zoxide, eza, fzf), productivity aliases/functions, and security safeguards for history and sudo commands. Forkable and installable — not distro-locked, but Fedora-first.

**Core Value:** Shell starts fast, stays secure, and makes daily terminal work more productive without ceremony.

### Constraints

- **OS**: Fedora Linux (DNF package manager) — primary target
- **Shell**: Zsh + Oh My Zsh + Powerlevel10k — non-negotiable stack
- **Performance**: Sub-150ms boot target drives all architecture decisions
- **Security**: History and sudo protections implemented in-shell, not external tools
- **Dependencies**: eza, fzf, zoxide are optional but enable core features
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core Shell
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Zsh** | 5.9 (Fedora 44) | Primary shell | Latest stable Zsh (5.9, May 2022). Fedora 44 ships 5.9-20. No newer Zsh release exists — this is the current gold standard. Required by Oh My Zsh and Powerlevel10k. |
| **Git** | 2.54.0 (Fedora 44) | Version control, OMZ updates | Required by Oh My Zsh for self-update. Also needed for plugin cloning (zsh-autosuggestions, zsh-syntax-highlighting, zsh-defer). |
### Framework & Theme
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Oh My Zsh** | Latest (rolling) | Plugin/framework manager | Most popular Zsh framework (180k+ ⭐ on GitHub). Provides `$ZSH_CUSTOM` structure, `compinit`, plugin loading infrastructure. The project has chosen OMZ as non-negotiable (see PROJECT.md). |
| **Powerlevel10k** | v1.20.0 | Theme/prompt | Gold standard Zsh theme. Instant Prompt eliminates startup lag, gitstatus daemon for real-time VCS status, configuration wizard. Only theme that supports sub-150ms boot with rich features. |
- The README states "VERY LIMITED SUPPORT" and "NO NEW FEATURES ARE IN THE WORKS" — however the theme is mature and stable. v1.20.0 is a well-tested release. Bugs are rare. This is still the correct choice.
- **Instant Prompt must be the first thing in `.zshrc`** — non-negotiable ordering requirement.
- Configuration wizard produces `~/.p10k.zsh` — must be sourced at the **end** of `.zshrc` (after all plugins, aliases, and functions).
- Recommended font: MesloLGS NF (Nerd Font patched). Required for full icon/glyph support. Install via `p10k configure` or manual download.
- Powerlevel9k: Abandoned, slower, superseded by P10k
- Starship: Cross-shell, written in Rust, but less Zsh-native. Slower IO prompt segments. Less integrated with OMZ.
- Pure: Too minimal for this project's feature requirements
- Prezto/Zim framework: Would require abandoning Oh My Zsh — violates project constraint
### Plugin Cache System
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Custom fingerprint cache** | N/A (project code) | Cache zoxide + fzf init scripts | The project's core innovation for sub-150ms boot. Caches `zoxide init zsh` output and fzf key bindings. Rebuilds only when tool binaries change (fingerprint = `tool=/path/to/tool;`). Provides 30-50% boot speed improvement. |
| **`zcompile`** | Built into Zsh 5.9 | Bytecode compilation | Compiles `.zshrc` and plugin cache to `.zwc` files. Faster Zsh parsing on subsequent loads. Runs in background (`&!`) to avoid blocking. |
### Productivity Tools (Fedora DNF)
| Technology | Version (Fedora) | Latest | Purpose | Why |
|------------|-----------------|--------|---------|-----|
| **eza** | 0.23.4-3 | v0.23.4 | Modern `ls` replacement | Community fork of exa (which is unmaintained). Icons, git status, tree view, colorized output. Fedora version matches latest GitHub release exactly — no need for manual install. 21.7k ⭐. |
| **fzf** | 0.70.0-1 | v0.72.0 | Fuzzy finder | CTRL-R history search, CTRL-T file search, **ALT-C cd** integration. Fedora version is slightly behind (0.70.0 vs 0.72.0) but functionally identical for our use case. |
| **zoxide** | 0.9.8-2 | v0.9.9 | Smarter `cd` | Replaces `cd` with frecency-based directory navigation. `z <partial>` jumps to most used matching directory. Fedora ships 0.9.8, latest is 0.9.9 — minor lag, difference is negligible. |
| **bat** | 0.26.1-1 | v0.26.1 | `cat` with syntax highlighting | Matches latest GitHub release. Useful for `bat README.md` and as `MANPAGER`. Not hard-required but recommended companion. |
| **ripgrep (rg)** | 14.1.1-4 | 15.1.0 | Ultra-fast grep | Fedora significantly behind (14.1.1 vs 15.1.0). But 14.1.1 is still fast and stable. Not hard-required. |
| **fd-find** | 10.4.2-1 | 10.4.2 | Fast `find` replacement | Matches latest stable. Companion to fzf (fzf can use `fd` for better file search). |
### OMZ Plugins (Git Clones)
| Plugin | Repository | ⭐ Stars | Purpose | Why |
|--------|-----------|----------|---------|-----|
| **zsh-autosuggestions** | zsh-users/zsh-autosuggestions | 35.5k | Fish-like autosuggestions | Suggests commands based on history as you type. Async by default in Zsh ≥ 5.0.8 (we have 5.9). Configurable strategy (history → completion → match_prev_cmd). |
| **zsh-syntax-highlighting** | zsh-users/zsh-syntax-highlighting | 22.6k | Fish-like syntax highlighting | Highlights commands as you type. Detects errors before execution. **Must be loaded near the end** of `.zshrc` (after compinit). Works via ZLE hooks in Zsh ≥ 5.8. |
| **zsh-defer** | romkatv/zsh-defer | 487 | Deferred plugin loading | ~150 lines of Zsh. Defers execution until Zsh is idle waiting for input. From same author as Powerlevel10k. Used for lazy-loading the heavy plugins above. **Optional** — only useful if boot time still exceeds target after cache system. |
- In Zsh ≥ 5.8, it uses `add-zle-hook-widget` (zle-line-pre-redraw hook)
- Must be sourced after `compinit` (which Oh My Zsh does)
- Must be the last plugin sourced before Powerlevel10k
## Alternatives Considered
| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| File listing | eza (exa fork) | exa (og) | Original exa has been **unmaintained since 2021**. eza is the community fork with active development, bug fixes, and security patches. |
| Directory nav | zoxide | `cd` + `pushd/popd` | zoxide's frecency algorithm learns your patterns. After a week of use, `z proj` jumps to your most-used project directory regardless of full path. |
| Fuzzy finder | fzf | fzy, skim | fzf has the largest ecosystem, widest terminal support, and CTRL-R/CTRL-T/ALT-C integration is the most robust. fzy is simpler but less capable. Skim (Rust) is a valid alternative but not in Fedora repos. |
| Plugin cache | Custom fingerprint cache | zinit turbo mode | zinit is powerful but complex. The custom cache approach is simpler, more transparent, and sufficient for this project's needs. Avoids adding another plugin manager to the stack. |
| zsh-defer vs. no defer | zsh-defer (optional) | Always synchronous | With Powerlevel10k Instant Prompt + plugin cache, most users won't need zsh-defer. Make it optional — auto-detect if installed and only use if present. |
| bat | bat | pygmentize, highlight | bat is in Fedora repos. Single binary. Integrates with fzf previews via `--preview 'bat --color=always {}'`. |
| ripgrep | rg | silver-searcher (ag), grep | ripgrep is the fastest. ag is unmaintained. Fedora has both. RIPGREP_CONFIG_PATH allows persistent config. |
| fd-find | fd | find, plocate | fd respects `.gitignore` by default, which is critical for fzf file searches in git repos (`fzf --preview 'bat --color=always {}'` searches don't want to include `.git/` or `node_modules/`). |
## Architecture of Plugin Loading
- Steps 11-12 are replaced with:
- These run asynchronously while the user is already at the prompt
## Security Considerations
| Layer | What It Protects | Implementation |
|-------|-----------------|----------------|
| History filter | Credentials in commands | `zshaddhistory()` hook — case-insensitive regex match on TOKEN, SECRET, PASSWORD, API_KEY, etc. |
| Sudo wrapper | Dangerous root commands | Zsh function wrapping `sudo`. Blocks recursive sudo, `rm -rf /`, `mkfs`, `dd of=`, `chmod -R 777 /`. |
| History dedup | Sensitive command proliferation | `setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS` |
## What NOT to Use and Why
| Technology | Reason to Avoid |
|------------|-----------------|
| **zinit / zi** | Powerful but complex. Adds another plugin manager on top of Oh My Zsh. The cache system provides the same performance benefit with less complexity. 2.8k ⭐ vs OMZ's 180k. |
| **antigen** | Unmaintained. Last release 2020. Abandoned by original author. |
| **antidote** | Newer but less proven. Not in Fedora repos. Would replace OMZ — violates project constraint. |
| **bash-completion** (for Zsh) | Zsh has its own completion system via `compinit`. bash-completion is for Bash only. |
| **exa** (original) | Unmaintained since 2021. No security fixes. Use `eza` (the community fork) instead. |
| **lsd** | Alternative to eza. Less popular (14k vs 21k ⭐). No git status per file. No Fedora package. |
| **MacPorts / Homebrew** | Not for Fedora Linux. Use DNF. |
## Version Summary Table
| Tool | DNF Version | Latest GitHub | Delta | Action Needed |
|------|-------------|---------------|-------|---------------|
| Zsh | 5.9-20 | 5.9 | None | Use DNF version |
| Git | 2.54.0 | 2.x | Current | Use DNF version |
| eza | 0.23.4-3 | v0.23.4 | ✅ Match | Use DNF version |
| fzf | 0.70.0-1 | v0.72.0 | ⚠️ Minor lag (<0.1) | DNF version sufficient |
| zoxide | 0.9.8-2 | v0.9.9 | ⚠️ Minor lag (<0.1) | DNF version sufficient |
| bat | 0.26.1-1 | v0.26.1 | ✅ Match | Use DNF version |
| ripgrep | 14.1.1-4 | 15.1.0 | ⚠️ Moderate lag | DNF version sufficient for needs |
| fd-find | 10.4.2-1 | 10.4.2 | ✅ Match | Use DNF version |
| Powerlevel10k | N/A | v1.20.0 | N/A | Git clone into $ZSH_CUSTOM |
| oh-my-zsh | N/A | Rolling | N/A | Curl install script |
| zsh-autosuggestions | N/A | Rolling | N/A | Git clone into plugins |
| zsh-syntax-highlighting | N/A | Rolling | N/A | Git clone into plugins |
| zsh-defer | N/A | Rolling | N/A | Git clone into plugins (optional) |
## Sources
- GitHub releases API for all tools (verified via curl)
- DNF repo queries for Fedora 44 package versions
- Official README documents:
- Existing `.zshrc` version 2.3 analysis
- PROJECT.md constraints and decisions
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
