# Project Research Summary

**Project:** Zsh Profile — Fedora Optimized
**Domain:** Zsh shell configuration (dotfiles) for Linux terminal productivity
**Researched:** 2026-05-10
**Confidence:** HIGH

## Executive Summary

This project is a personal Zsh shell configuration optimized for Fedora Linux — a dotfiles repository focused on fast startup (<150ms), productivity aliases/functions, and in-shell security safeguards. The ecosystem is mature and well-documented: Zsh 5.9 + Oh My Zsh (180k★) + Powerlevel10k theming is the gold-standard combination for serious shell setups, and Fedora 44's DNF repos provide all supporting CLI tools (eza, fzf, zoxide, bat, ripgrep, fd-find) at versions that match or trivially lag behind latest releases.

**The project is in strong shape** — the existing `.zshrc` (v2.3, 342 lines) already implements 12 table-stakes features and 11 differentiators including the fingerprint-based plugin cache, boot timer instrumentation, bytecode compilation, lazy loading via zsh-defer, sudo protection, and a history security filter. The research confirms the stack choices, loading order, and architecture patterns are all correct with HIGH confidence across all four research files.

**The critical path forward is modularization.** The monolithic `.zshrc` at 342 lines is approaching the 400-line maintainability cliff that community practices identify as the threshold for splitting into a modular `zsh/` directory structure. Two technical fixes deserve priority: (1) the plugin cache fingerprint currently uses binary path (`command -v`) instead of version/content hash, so DNF in-place upgrades won't trigger a cache rebuild; (2) the security layer's regex patterns miss common leak vectors like URL-embedded tokens (`git clone https://token@github.com/...`). Both have straightforward mitigations documented in the pitfalls research. All other risks are low-severity with self-healing recovery strategies.

## Key Findings

### Recommended Stack

The stack is non-negotiable per PROJECT.md constraints and verified as the gold standard by all research:

**Core shell:** Zsh 5.9 (Fedora 44) — current gold standard, no newer release exists. Oh My Zsh as framework (180k★). Powerlevel10k v1.20.0 for theming with Instant Prompt.

**CLI tools (all via DNF):** eza 0.23.4 (ls replacement with icons/git status), fzf 0.70.0 (fuzzy finder), zoxide 0.9.8 (smart cd), bat 0.26.1 (syntax-highlighted cat), ripgrep 14.1.1 (fast grep), fd-find 10.4.2 (fast find). All match or trivially lag behind latest GitHub releases.

**Custom machinery:** Fingerprint-based plugin cache (caches `zoxide init zsh` + fzf key bindings, rebuilds only on tool version changes), bytecode compilation via `zcompile` (background `.zwc` generation), and optional `zsh-defer` for lazy loading of heavy plugins.

**Loading order is critical and locked in:** P10k Instant Prompt → Boot Timer → Path/Options → Plugin Cache → OMZ core → Heavy plugins → Aliases/Functions → `.zshrc.local` → P10k Theme → `.p10k.zsh` → Boot Timer End → `.zwc` compilation (background).

### Expected Features

**Must have (table stakes)** — 12 features that any serious Zsh config provides:
- Powerlevel10k prompt with Instant Prompt (✅ done)
- Oh My Zsh plugin framework (✅ done) 
- Completion system via `compinit` (⚠️ **gap** — need to verify OMZ's default loading works)
- History management with 50K entries, dedup, sharing (✅ done)
- Syntax highlighting + autosuggestions (✅ done, both via lazy loading)
- File listing aliases via eza with icons/git status (✅ done)
- Navigation shortcuts — mkcd, nf, zoxide integration (✅ done)
- Git integration — gcom, lazyg with safety checks (✅ done)
- Colored grep, PATH dedup, local override file (✅ all done)

**Should have (differentiators)** — 11 features that set this config apart:
- Fingerprint-based plugin cache (30-50% boot improvement) — ⭐ genuinely differentiating
- Boot time instrumentation with color-coded thresholds (✅ done)
- Bytecode compilation of `.zshrc` (✅ done, backgrounded)
- Lazy loading with zsh-defer (✅ done, conditional on plugin presence)
- In-shell sudo wrapper blocking `rm -rf /`, `mkfs`, `dd of=`, etc. (✅ done)
- History security filter blocking TOKEN/SECRET/PASSWORD from history (✅ done)
- `extract` function supporting 12 archive formats (✅ done)
- `sedi` with timestamped automatic backups (✅ done)
- Fedora-specific system cleanup (dnf-clean, flatpak-clean, sys-clean) (✅ done)
- Path-aware git commit workflow (lazyg with timeout + push confirmation) (✅ done)
- Bilingual docs (pt-BR + en) (✅ done)

**Defer (v2+):** zsh-completions (OMZ ships sufficient defaults), custom theme tuning (P10k wizard handles this), plugin additions (add only when workflow need emerges), distro-adaptation layer (Fedora-first per scope).

### Architecture Approach

The architecture follows Zsh's built-in startup file chain (`.zshenv` → `.zprofile` → `.zshrc` → `.zlogin` → `.zlogout`) with a 6-layer project stack within `.zshrc`: Boot Trap → Shell Foundation → Tool Cache → OMZ + Plugins → User Config → Theme + Compilation. Each layer depends strictly on prior layers, and loading order is enforced by the single `.zshrc` file.

**Recommended move to modular structure:** The community standard for maintainable Zsh configs (thoughtbot, mathiasbynens) is a `zsh/` directory with subdirectories per concern:
1. **`zsh/config/`** — paths, options, history, bindings, completion
2. **`zsh/plugins/`** — OMZ integration, plugin cache, zsh-defer, heavy plugins
3. **`zsh/security/`** — history filter, sudo wrapper
4. **`zsh/aliases/`** — eza, navigation, grep, sys-clean
5. **`zsh/functions/`** — navigation, git, utilities, boot timer
6. **`zsh/theme/`** — P10k loading + config
7. **`zsh/init/`** — instant prompt, boot timer, compilation
8. **`bootstrap.sh`** — symlink-based install (replacing `cp .zshrc ~/.zshrc`)

Key patterns: graceful degradation (tools guarded with `command -v`), fingerprint-validated caching, security via Zsh hooks, and background compilation.

### Critical Pitfalls

1. **P10k Instant Prompt ordering violation** — The instant prompt source must be the **very first line** in `.zshrc`. Any output before it (echo, printf, source) causes P10k to disable instant prompt, eliminating the perceived-speed benefit. Must verify path resolution works when `$XDG_CACHE_HOME` is unset (container/SSH edge case). [Phase 1]

2. **Plugin cache fingerprint collision** — The fingerprint uses `command -v <tool>` which returns the binary path, not the version/content hash. On Fedora, DNF updates tools in-place (`/usr/bin/zoxide`) without changing the path. After `dnf upgrade zoxide`, the cache won't rebuild, and stale init scripts may run against new binary versions. Fix: use `zoxide --version` or `cksum $(command -v zoxide)`. [Phase 2]

3. **zsh-syntax-highlighting sourced before compinit** — If loaded before `source $ZSH/oh-my-zsh.sh` (which runs compinit), ZLE hooks conflict — tab completion breaks or highlighting overwrites completion output. The current code correctly sources it after OMZ, but this constraint must be documented and preserved during refactoring. [Phase 3/7]

4. **History filter regex evasion** — The current regex only catches `TOKEN=value` assignments. It misses URL-embedded tokens (`git clone https://token@github.com/...`), flag-based credentials (`--token`, `--password`), and common env vars (`GH_TOKEN`, `GITHUB_TOKEN`, `AWS_ACCESS_KEY_ID`). Acceptable as defense-in-depth but must document limitations. [Phase 4]

5. **Monolithic `.zshrc` approaching maintainability cliff** — At 342 lines, the file is approaching the 400-line threshold where modularization becomes necessary. Comments are already the primary navigation mechanism. Every new feature before modularization adds to technical debt. [Phase 0 — address before adding features]

## Implications for Roadmap

Based on research, the recommended phase structure follows a **bottom-up dependency approach** derived from ARCHITECTURE.md's loading order analysis. The first phase (Phase 0) is a critical modularization prerequisite that enables parallel development in later phases.

### Phase 0: Modularization — Split Monolithic `.zshrc` into `zsh/` Directory Structure
**Rationale:** Every other phase benefits from splitting the 342-line `.zshrc` into a modular structure. The modular `zsh/` directory enables concurrent development, isolated testing, and prevents ordering bugs as new features are added. This addresses PITFALLS.md's #1 structural risk (monolithic file approaching maintainability cliff).
**Delivers:** Functionally identical config but organized into `zsh/config/`, `zsh/plugins/`, `zsh/security/`, `zsh/aliases/`, `zsh/functions/`, `zsh/theme/`, `zsh/init/` directories. Entry point `.zshrc` reduced to <100 lines.
**Addresses:** Foundation for all features from FEATURES.md; architectural pattern from ARCHITECTURE.md.
**Avoids:** Pitfall 9 (monolithic `.zshrc`), Pitfall 1 (ordering violations via clearer structure).
**Research flag:** Standard pattern — modular Zsh configs are well-documented (thoughtbot, mathiasbynens). Skip research-phase.

### Phase 1: Shell Foundation — PATH, Options, History, Key Bindings
**Rationale:** Everything depends on PATH dedup, setopts, and history config being established first. Already implemented in current `.zshrc` — this is primarily a verification and extraction phase.
**Delivers:** `zsh/config/paths.zsh`, `zsh/config/options.zsh`, `zsh/config/history.zsh`, `zsh/config/bindings.zsh`, `zsh/config/completion.zsh`.
**Addresses:** FEATURES.md TS-4 (history), TS-11 (env vars), TS-3 (completions — **verify compinit**).
**Avoids:** Pitfall 13 (boot timer silent failure — add `zmodload` error handling).
**Research flag:** Standard patterns, skip research-phase.

### Phase 2: Plugin Cache — Fix Fingerprint + Add Locking
**Rationale:** The cache is the project's core performance differentiator. The fingerprint currently uses binary path which doesn't detect DNF in-place updates — this is a confirmed bug per PITFALLS.md Pitfall 3. Fix before users experience stale cache after tool upgrades.
**Delivers:** `zsh/plugins/cache.zsh` with version-based or content-hash fingerprint, atomic rebuild locking, `cksum` fallback for minimal systems.
**Addresses:** FEATURES.md DF-1 (cache system), PROJECT.md CACHE-01 (auto-rebuild on version change).
**Avoids:** Pitfall 3 (fingerprint collision), Pitfall 7 (cache rebuild race), Pitfall 18 (cksum not available).
**Research flag:** Standard pattern with known fix — implement directly, skip research-phase.

### Phase 3: Oh My Zsh Integration — Framework Loading + Completion Verification
**Rationale:** OMZ is the framework that everything else builds on. This phase extracts OMZ loading into its own module, verifies compinit runs correctly (a known gap in FEATURES.md), and establishes the correct plugin array structure.
**Delivers:** `zsh/plugins/omz.zsh` (config), `zsh/plugins/omz-load.zsh` (framework source).
**Addresses:** FEATURES.md TS-1 (prompt), TS-2 (plugin framework), TS-3 (compinit verification).
**Avoids:** Pitfall 2 (syntax-highlighting before compinit — document ordering constraint).
**Research flag:** Standard patterns — skip research-phase.

### Phase 4: Security Layer — History Filter + Sudo Wrapper
**Rationale:** Independent of plugins and OMZ. Can be developed in parallel with Phases 2, 3, and 5-7. The history filter needs regex expansion for URL tokens (Pitfall 5). The sudo wrapper needs limitation documentation (Pitfall 4).
**Delivers:** `zsh/security/history-filter.zsh`, `zsh/security/sudo-wrapper.zsh`.
**Addresses:** FEATURES.md DF-5 (sudo), DF-6 (history filter), PROJECT.md SEC-01, SEC-02.
**Avoids:** Pitfall 4 (document sudo wrapper bypass), Pitfall 5 (extend regex patterns), Pitfall 11 (document `sudo !!` multi-line limitations).
**Research flag:** Standard security patterns — skip research-phase.

### Phase 5: Aliases — With Distro Guards
**Rationale:** Can be parallelized with Phases 4, 6, 7. The main fix is adding `command -v` guards to distro-specific aliases (Pitfall 12) so they don't error on Debian/macOS.
**Delivers:** `zsh/aliases/eza.zsh`, `zsh/aliases/navigation.zsh`, `zsh/aliases/grep.zsh`, `zsh/aliases/sys-clean.zsh`.
**Addresses:** FEATURES.md TS-7 (file listing), TS-8 (navigation), TS-10 (colored grep), DF-9 (Fedora cleanup).
**Avoids:** Pitfall 12 (cross-distro alias errors — add command-v guards).
**Research flag:** Standard patterns — skip research-phase.

### Phase 6: Functions — Git Workflow + Utilities
**Rationale:** Can be parallelized with Phases 4, 5, 7. Contains the most complex user-facing functions (lazyg, sedi). Fixes needed for sedi trap cleanup (Pitfall 15) and lazyg detached HEAD detection (Pitfall 16).
**Delivers:** `zsh/functions/navigation.zsh`, `zsh/functions/git.zsh`, `zsh/functions/utilities.zsh`.
**Addresses:** FEATURES.md DF-7 (extract), DF-8 (sedi), DF-10 (lazyg), PROJECT.md FUNC-01, FUNC-02, FUNC-03.
**Avoids:** Pitfall 15 (sedi trap cleanup ordering), Pitfall 16 (lazyg detached HEAD).
**Research flag:** Standard patterns — skip research-phase.

### Phase 7: Heavy Plugins — zsh-autosuggestions + zsh-syntax-highlighting
**Rationale:** Depends on Phase 3 (OMZ compinit must be loaded first). Tests the zsh-defer lazy loading path with non-deterministic timing (Pitfall 8). Can overlap with Phases 4-6.
**Delivers:** `zsh/plugins/defer.zsh`, `zsh/plugins/heavy.zsh`.
**Addresses:** FEATURES.md TS-5 (highlighting), TS-6 (autosuggestions), DF-4 (lazy loading).
**Avoids:** Pitfall 8 (zsh-defer + highlighting interaction — add delay or don't defer highlighting), Pitfall 14 (lazy loading race with first command — document expectations).
**Research flag:** Standard patterns but needs careful testing of deferred loading order — skip research-phase but add explicit verification step.

### Phase 8: Theme Loading — Powerlevel10k
**Rationale:** MUST be loaded last, after everything else. Verifies P10k path resolution works for the two standard install methods (Pitfall 10). This is the simplest phase but the most brittle if ordering is wrong.
**Delivers:** `zsh/theme/p10k-load.zsh`, `zsh/theme/p10k-config.zsh`.
**Addresses:** FEATURES.md TS-1 (prompt framework — the actual theme rendering).
**Avoids:** Pitfall 10 (P10k path resolution — test both install paths), Pitfall 1 (re-verify instant prompt ordering after modularization).
**Research flag:** Well-documented — skip research-phase.

### Phase 9: Boot Timer + Bytecode Compilation
**Rationale:** Wraps around all other phases — boot timer starts at the beginning and measures the full load. `.zwc` compilation runs in background at the end. Fixes needed for `zcompile` race (Pitfall 6) and `zmodload` error handling (Pitfall 13).
**Delivers:** `zsh/init/instant-prompt.zsh`, `zsh/init/boot-timer.zsh`, `zsh/init/compile.zsh`, `zsh/init/boot-timer-end.zsh`.
**Addresses:** FEATURES.md DF-2 (boot timer), DF-3 (bytecode compilation), PROJECT.md PERF-01 (<150ms boot).
**Avoids:** Pitfall 6 (zcompile race — add atomic rename), Pitfall 13 (boot timer silent failure — add zmodload guard).
**Research flag:** Standard patterns — skip research-phase.

### Phase 10: Bootstrap Script + Installation Experience
**Rationale:** Depends on finalized directory structure from Phases 0-9. Converts `cp .zshrc ~/.zshrc` to symlink-based install via `bootstrap.sh`.
**Delivers:** `bootstrap.sh` that creates symlinks from `zsh/` directory to `~/.config/zsh/` or `~/` equivalents.
**Addresses:** ARCHITECTURE.md's install/sync integration section, FEATURES.md AF-8 (no built-in update — documented update process).
**Avoids:** Pitfall 9 (future monolithic regressions — bootstrap.sh enforces modular structure).
**Research flag:** Standard bootstrap patterns (thoughtbot rcm, mathiasbynens shell script) — skip research-phase.

### Phase Ordering Rationale

- **Phase 0 MUST be first** — modularization is the foundation that enables safe, parallel development of all subsequent phases. Without it, the monolithic `.zshrc` grows with each phase, making ordering bugs harder to debug and features harder to find.
- **Phase 1 (Foundation) comes next** — PATH, options, and history are dependencies for everything else.
- **Phases 2-3 (Cache + OMZ)** follow — these are the two core architectural layers (tool caching and framework loading). Both depend on Phase 1 but are independent of each other.
- **Phases 4-7 (Security, Aliases, Functions, Heavy Plugins)** are parallelizable — they share no dependencies beyond Phase 1. The research recommends developing them concurrently for efficiency.
- **Phase 8 (Theme) must be last** — Powerlevel10k requires every other layer to be loaded first. This is a hard architectural constraint from P10k's README.
- **Phase 9 (Boot Timer + Compilation)** wraps the entire load sequence and can be done alongside Phase 8.
- **Phase 10 (Bootstrap Script)** is naturally last since it depends on the final directory structure.

### Research Flags

**Needs deeper research during planning:**
- **None.** All 11 phases follow well-documented, standard patterns for Zsh configuration. The research is uniformly HIGH confidence across all areas. No phase requires additional /gsd-research-phase calls.

**Standard patterns (skip research-phase):**
- All phases. The Zsh dotfiles ecosystem is mature, the project's existing `.zshrc` already implements the correct patterns, and the pitfalls research provides clear mitigation strategies for every identified risk.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All versions verified via DNF repo queries and GitHub API. Fedora 44 ships current or near-current versions of all tools. Powerlevel10k v1.20.0 confirmed stable despite "limited support" notice. |
| Features | HIGH | Verified against 5 authoritative sources (ohmyzsh, prezto, zimfw, mathiasbynens, ArchWiki). 12 table-stakes and 11 differentiators mapped. Current `.zshrc` implements all table stakes and most differentiators. One gap: compinit verification needed. |
| Architecture | HIGH | Loading order derived from Zsh manual, P10k README, and oh-my-zsh source. Modularization pattern validated against thoughtbot and mathiasbynens dotfiles. All patterns verified against current `.zshrc` implementation. |
| Pitfalls | HIGH | 18 identified pitfalls with 5 critical. Each has prevention strategy, warning signs, and phase mapping. Recovery strategies documented for all. Fingerprint collision is the only confirmed bug (not theoretical). Race conditions are self-healing. |

**Overall confidence:** HIGH

### Gaps to Address

1. **Compinit verification (Phase 3):** FEATURES.md identifies a gap — the completion system's status is uncertain under OMZ's default loading. Need to verify `compinit` runs correctly and `zstyle ':completion:*' menu select` is effective. Quick validation: open a fresh shell, type `git <TAB><TAB>`, verify completions appear.

2. **Plugin cache fingerprint (Phase 2):** The current `command -v`-based fingerprint won't detect DNF in-place binary updates. Must switch to version string (`tool --version`) or content hash (`cksum $(command -v tool)`). This is the highest-impact fix from the research.

3. **History filter regex completeness (Phase 4):** The current filter catches keyword-based assignments but misses URL-embedded tokens and flag-based credentials. Add patterns for `https?://[^@]+@`, `--token`, `--password`, and common env vars (GH_TOKEN, GITHUB_TOKEN, AWS_ACCESS_KEY_ID, NPM_TOKEN).

4. **Cross-platform testing (Phase 5):** The DNF aliases lack `command -v` guards. Need to test `.zshrc` sourcing on a Debian/Ubuntu container to verify graceful degradation. This will surface any additional distro-specific assumptions.

5. **`lazyg` detached HEAD (Phase 6):** `git rev-parse --abbrev-ref HEAD` returns `"HEAD"` in detached state, causing `lazyg` to push to the default branch instead of warning. Needs a guard check.

6. **`sedi` trap cleanup (Phase 6):** The trap `- INT TERM` runs before `mv`, leaving temp files on Ctrl+C if interrupted during the rename. Move trap removal after the `mv` command.

## Sources

### Primary (HIGH confidence)
- GitHub releases API for all tools (verified via direct API calls)
- DNF repo queries for Fedora 44 package versions
- Official README: Powerlevel10k (GitHub) — Instant Prompt ordering, theme loading constraints
- Official README: zsh-syntax-highlighting (GitHub) — "must be sourced at end of .zshrc" constraint
- Zsh manual (zsh.sourceforge.io) — startup files, `zcompile`, `.zwc` files
- Oh My Zsh wiki (GitHub) — plugin/theme architecture
- Repo's existing `.zshrc` v2.3 — direct code analysis of all implemented features
- ArchWiki Zsh page — common pitfalls and best practices
- PROJECT.md constraints and decisions

### Secondary (MEDIUM confidence)
- thoughtbot dotfiles — modular `zsh/` directory structure (observed pattern)
- mathiasbynens dotfiles — `.aliases`/`.functions`/`.exports` split + bootstrap pattern (observed pattern)
- zsh-bench by romkatv — Instant Prompt and startup measurement methodology
- Prezto README — module architecture comparison
- Zimfw README — plugin manager patterns, speed comparison
- Fedora 44 package management behavior — DNF in-place binary updates confirmation

### Tertiary (LOW confidence)
- None — all research was verified against primary or authoritative secondary sources.

---

*Research completed: 2026-05-10*
*Ready for roadmap: yes*
