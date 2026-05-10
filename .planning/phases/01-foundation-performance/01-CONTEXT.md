# Phase 1: Foundation & Performance - Context

**Gathered:** 2026-05-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a fast, secure, and reliable shell startup chain: Powerlevel10k instant prompt, boot timer with color-coded feedback, PATH/history configuration, intelligent plugin cache with auto-rebuild and race-safe locking, bytecode compilation for faster parsing, and proper Powerlevel10k theme loading at the end of .zshrc.

</domain>

<decisions>
## Implementation Decisions

### Fingerprint Strategy
- **D-01:** Use `tool --version 2>/dev/null | head -1` for all 3 watched tools (zoxide, eza, fzf) — catches DNF in-place binary updates that path-based fingerprint misses
- **D-02:** Keep all 3 tools watched (not a subset) — each is critical to its feature domain
- **D-03:** Rebuild cache excluding missing tools — don't block for uninstalled tools
- **D-04:** Use `flock` or PID file for cache rebuild locking — prevent parallel shell race condition
- **D-05:** Compile cache to `.zwc` after rebuild (keep current) — faster subsequent loads
- **D-06:** Exclude Oh My Zsh version from fingerprint — OMZ rarely changes
- **D-07:** Keep monolithic cache file structure — simpler, one `source` call
- **D-08:** Keep fingerprint in first line of cache file — atomic read+validate

### Cache Rebuild Timing
- **D-09:** Rebuild synchronously on shell start when fingerprint mismatches — guarantees fresh cache
- **D-10:** Silent fallback on corrupt/missing cache — no warning, no rebuild on failure
- **D-11:** Async `.zwc` compilation after rebuild (`&!`) — cache usable immediately
- **D-12:** Silent rebuild (no output) — clean startup

### Bytecode Compilation
- **D-13:** Compile `.zshrc` to `.zwc` in background on shell start (`zcompile &!`) — current behavior
- **D-14:** Only compile `.zshrc` and plugin cache (already done) — no extra files
- **D-15:** Silent fallback on compilation error (`&>/dev/null`) — no terminal output
- **D-16:** Overwrite `.zwc` in-place — no stale cleanup needed

### History Size & Retention
- **D-17:** Keep 50K history entries — current setting, sufficient recall depth
- **D-18:** Immediate append per command (`INC_APPEND_HISTORY`) — cross-session sharing
- **D-19:** Ignore all duplicates (`HIST_IGNORE_ALL_DUPS`, `HIST_SAVE_NO_DUPS`) — clean history
- **D-20:** No logging of blocked commands from history filter

### PATH Strategy
- **D-21:** Priority: `~/.local/bin` > `~/bin` > system PATH
- **D-22:** Keep current directory set (`~/.local/bin`, `~/bin`, `~/.spicetify`) — no additions

### XDG Base Directory Compliance
- **D-23:** Set standard XDG env vars in `.zshrc` — let tools respect them automatically
- **D-24:** Keep in `.zshrc` (not `.zshenv`) — only needed for interactive shell tools

### Boot Timer Thresholds
- **D-25:** Keep thresholds hardcoded (<150ms / <200ms / <500ms / >=500ms) — simple, predictable

### History Filter Regex
- **D-26:** Extend patterns to also catch: `https://token@host`, `--token <value>`, `--password <value>`, `-p <value>`
- **D-27:** Also block commands containing SSH key material and GPG passphrase operations

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Definition
- `.planning/PROJECT.md` — Core value, constraints, active requirements
- `.planning/REQUIREMENTS.md` — Full requirement list with REQ-IDs and traceability

### Phase Scope
- `.planning/ROADMAP.md` §Phase 1 — Success criteria, requirement mappings

### Existing Configuration
- `.zshrc` — Current implementation of all features (320 lines, structured in 10 sections)
- `AGENTS.md` — GSD workflow guidance and project conventions

### Research
- `.planning/research/STACK.md` — Verified technology stack (HIGH confidence)
- `.planning/research/PITFALLS.md` — Fingerprint collision bug, history regex gaps

No external specs — requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Plugin cache system** (`.zshrc` lines 51-106): `_zsh_gen_fingerprint`, `_zsh_build_plugin_cache`, fingerprint validation logic — refactor to version-based fingerprint
- **Boot timer** (`.zshrc` lines 16-17, 331-343): `_zshrc_start_s`, `_zshrc_load_ms`, `zshrc-time()` function — keep, just needs threshold verification
- **Bytecode compilation** (`.zshrc` lines 324-326): `zcompile ~/.zshrc &!` — keep background behavior
- **History security filter** (`.zshrc` lines 49-51): `zshaddhistory()` hook — extend regex patterns

### Established Patterns
- **Guard-based loading**: `.zshrc` checks `command -v` before enabling any tool-specific feature — apply to all new additions
- **Silent by default**: Non-error output only via explicit commands (e.g., `zshrc-time`) — no startup noise

### Integration Points
- All changes go into `.zshrc` — no modular directory structure yet (v2 scope)
- `zshaddhistory` hook at line 49 — extend pattern list here
- Plugin cache functions at lines 55-106 — refactor fingerprint logic in-place

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 1-Foundation & Performance*
*Context gathered: 2026-05-10*
