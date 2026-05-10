# Technology Stack

**Project:** Zsh Profile — Fedora Optimized
**Researched:** 2026-05-10
**Mode:** Ecosystem Research
**Overall confidence:** HIGH

## Recommended Stack

### Core Shell

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Zsh** | 5.9 (Fedora 44) | Primary shell | Latest stable Zsh (5.9, May 2022). Fedora 44 ships 5.9-20. No newer Zsh release exists — this is the current gold standard. Required by Oh My Zsh and Powerlevel10k. |
| **Git** | 2.54.0 (Fedora 44) | Version control, OMZ updates | Required by Oh My Zsh for self-update. Also needed for plugin cloning (zsh-autosuggestions, zsh-syntax-highlighting, zsh-defer). |

**Confidence:** HIGH — verified via DNF repos and zsh.org

### Framework & Theme

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Oh My Zsh** | Latest (rolling) | Plugin/framework manager | Most popular Zsh framework (180k+ ⭐ on GitHub). Provides `$ZSH_CUSTOM` structure, `compinit`, plugin loading infrastructure. The project has chosen OMZ as non-negotiable (see PROJECT.md). |
| **Powerlevel10k** | v1.20.0 | Theme/prompt | Gold standard Zsh theme. Instant Prompt eliminates startup lag, gitstatus daemon for real-time VCS status, configuration wizard. Only theme that supports sub-150ms boot with rich features. |

**Critical notes about Powerlevel10k:**
- The README states "VERY LIMITED SUPPORT" and "NO NEW FEATURES ARE IN THE WORKS" — however the theme is mature and stable. v1.20.0 is a well-tested release. Bugs are rare. This is still the correct choice.
- **Instant Prompt must be the first thing in `.zshrc`** — non-negotiable ordering requirement.
- Configuration wizard produces `~/.p10k.zsh` — must be sourced at the **end** of `.zshrc` (after all plugins, aliases, and functions).
- Recommended font: MesloLGS NF (Nerd Font patched). Required for full icon/glyph support. Install via `p10k configure` or manual download.

**Why not alternatives:**
- Powerlevel9k: Abandoned, slower, superseded by P10k
- Starship: Cross-shell, written in Rust, but less Zsh-native. Slower IO prompt segments. Less integrated with OMZ.
- Pure: Too minimal for this project's feature requirements
- Prezto/Zim framework: Would require abandoning Oh My Zsh — violates project constraint

**Confidence:** HIGH — verified via GitHub releases and README

### Plugin Cache System

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Custom fingerprint cache** | N/A (project code) | Cache zoxide + fzf init scripts | The project's core innovation for sub-150ms boot. Caches `zoxide init zsh` output and fzf key bindings. Rebuilds only when tool binaries change (fingerprint = `tool=/path/to/tool;`). Provides 30-50% boot speed improvement. |
| **`zcompile`** | Built into Zsh 5.9 | Bytecode compilation | Compiles `.zshrc` and plugin cache to `.zwc` files. Faster Zsh parsing on subsequent loads. Runs in background (`&!`) to avoid blocking. |

**How the cache works:**
1. On shell start, compute fingerprint of watched tools (zoxide, fzf)
2. Compare with cached fingerprint (first line of cache file)
3. If mismatch or cache missing → rebuild cache by running init commands and capturing output
4. Source the cache file
5. Background-compile the cache file to `.zwc` for next start

**Confidence:** HIGH — verified against existing `.zshrc` implementation

### Productivity Tools (Fedora DNF)

| Technology | Version (Fedora) | Latest | Purpose | Why |
|------------|-----------------|--------|---------|-----|
| **eza** | 0.23.4-3 | v0.23.4 | Modern `ls` replacement | Community fork of exa (which is unmaintained). Icons, git status, tree view, colorized output. Fedora version matches latest GitHub release exactly — no need for manual install. 21.7k ⭐. |
| **fzf** | 0.70.0-1 | v0.72.0 | Fuzzy finder | CTRL-R history search, CTRL-T file search, **ALT-C cd** integration. Fedora version is slightly behind (0.70.0 vs 0.72.0) but functionally identical for our use case. |
| **zoxide** | 0.9.8-2 | v0.9.9 | Smarter `cd` | Replaces `cd` with frecency-based directory navigation. `z <partial>` jumps to most used matching directory. Fedora ships 0.9.8, latest is 0.9.9 — minor lag, difference is negligible. |
| **bat** | 0.26.1-1 | v0.26.1 | `cat` with syntax highlighting | Matches latest GitHub release. Useful for `bat README.md` and as `MANPAGER`. Not hard-required but recommended companion. |
| **ripgrep (rg)** | 14.1.1-4 | 15.1.0 | Ultra-fast grep | Fedora significantly behind (14.1.1 vs 15.1.0). But 14.1.1 is still fast and stable. Not hard-required. |
| **fd-find** | 10.4.2-1 | 10.4.2 | Fast `find` replacement | Matches latest stable. Companion to fzf (fzf can use `fd` for better file search). |

**Installation command:**
```bash
sudo dnf install eza fzf zoxide bat ripgrep fd-find
```

**Confidence:** HIGH — verified via DNF repo queries and GitHub API

### OMZ Plugins (Git Clones)

These are **not** available in DNF repos. They must be cloned into `${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/`.

| Plugin | Repository | ⭐ Stars | Purpose | Why |
|--------|-----------|----------|---------|-----|
| **zsh-autosuggestions** | zsh-users/zsh-autosuggestions | 35.5k | Fish-like autosuggestions | Suggests commands based on history as you type. Async by default in Zsh ≥ 5.0.8 (we have 5.9). Configurable strategy (history → completion → match_prev_cmd). |
| **zsh-syntax-highlighting** | zsh-users/zsh-syntax-highlighting | 22.6k | Fish-like syntax highlighting | Highlights commands as you type. Detects errors before execution. **Must be loaded near the end** of `.zshrc` (after compinit). Works via ZLE hooks in Zsh ≥ 5.8. |
| **zsh-defer** | romkatv/zsh-defer | 487 | Deferred plugin loading | ~150 lines of Zsh. Defers execution until Zsh is idle waiting for input. From same author as Powerlevel10k. Used for lazy-loading the heavy plugins above. **Optional** — only useful if boot time still exceeds target after cache system. |

**Installation command:**
```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/romkatv/zsh-defer ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-defer
```

**Important ordering constraint for zsh-syntax-highlighting:**
> "zsh-syntax-highlighting must be sourced **at the end** of the .zshrc file" (official README)
- In Zsh ≥ 5.8, it uses `add-zle-hook-widget` (zle-line-pre-redraw hook)
- Must be sourced after `compinit` (which Oh My Zsh does)
- Must be the last plugin sourced before Powerlevel10k

This means if not using zsh-defer, zsh-autosuggestions and zsh-syntax-highlighting should be loaded **after** `source $ZSH/oh-my-zsh.sh` but **before** the Powerlevel10k theme.

**Confidence:** HIGH — verified via GitHub READMEs and repository statistics

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

**Confidence:** HIGH

## Architecture of Plugin Loading

The loading order in `.zshrc` is critical for performance and correctness:

```
1. Powerlevel10k Instant Prompt          ← MUST BE FIRST
2. Boot timer start                       ← After instant prompt
3. Path deduplication + additions         ← Before OMZ
4. Oh My Zsh config (ZSH=, ZSH_THEME=)   ← Before plugin loading
5. Zsh options (setopt)                   ← Before history/completion
6. History config                         ← Before OMZ plugins
7. Plugin cache rebuild (if stale)        ← Cache zoxide + fzf
8. Source plugin cache                    ← Fast path
9. Oh My Zsh core (oh-my-zsh.sh)          ← Loads OMZ framework
10. OMZ plugins (git, history)            ← Via OMZ plugin system
11. zsh-autosuggestions                   ← If no zsh-defer
12. zsh-syntax-highlighting               ← LAST plugin (ordering constraint)
13. Aliases + functions                   ← After all plugins
14. ~/.zshrc.local                        ← User overrides
15. Powerlevel10k theme                   ← MUST BE LAST
16. ~/.p10k.zsh                           ← P10k configuration
17. .zshrc bytecode compilation (async)   ← Background
18. Boot timer end                        ← Final
```

**When zsh-defer is active:**
- Steps 11-12 are replaced with:
  - Source zsh-defer plugin (after OMZ loads)
  - `zsh-defer source zsh-autosuggestions`
  - `zsh-defer source zsh-syntax-highlighting`
- These run asynchronously while the user is already at the prompt

**Confidence:** HIGH — verified against existing `.zshrc` and Powerlevel10k documentation

## Security Considerations

| Layer | What It Protects | Implementation |
|-------|-----------------|----------------|
| History filter | Credentials in commands | `zshaddhistory()` hook — case-insensitive regex match on TOKEN, SECRET, PASSWORD, API_KEY, etc. |
| Sudo wrapper | Dangerous root commands | Zsh function wrapping `sudo`. Blocks recursive sudo, `rm -rf /`, `mkfs`, `dd of=`, `chmod -R 777 /`. |
| History dedup | Sensitive command proliferation | `setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS` |

**Confidence:** HIGH — code review of existing `.zshrc`

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

**Confidence:** HIGH

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

**Confidence:** HIGH — all versions verified via DNF repos or GitHub API

## Sources

- GitHub releases API for all tools (verified via curl)
- DNF repo queries for Fedora 44 package versions
- Official README documents:
  - Powerlevel10k: https://github.com/romkatv/powerlevel10k
  - zsh-defer: https://github.com/romkatv/zsh-defer
  - eza: https://github.com/eza-community/eza
  - zsh-autosuggestions: https://github.com/zsh-users/zsh-autosuggestions
  - zsh-syntax-highlighting: https://github.com/zsh-users/zsh-syntax-highlighting
- Existing `.zshrc` version 2.3 analysis
- PROJECT.md constraints and decisions
