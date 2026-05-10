# Phase 1: Foundation & Performance - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-10
**Phase:** 1-Foundation & Performance
**Areas discussed:** Fingerprint strategy, Cache rebuild timing, Bytecode compilation timing, History size & retention, PATH strategy, XDG compliance, Boot timer thresholds, History filter regex

---

## Fingerprint Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Version output (Recommended) | Run `tool --version`, hash the output. Catches DNF in-place binary updates | ✓ |
| Binary checksum | SHA-256 of the binary. Most accurate but slower | |
| Keep path-based | Current approach — `command -v` path only. Simple but misses updates | |

**User's choice:** Version output

---

| Option | Description | Selected |
|--------|-------------|----------|
| All 3 tools (Recommended) | zoxide, eza, fzf — current set | ✓ |
| Just zoxide + fzf | eza is alias-only, dropping it reduces false rebuilds | |

**User's choice:** All 3 tools

---

| Option | Description | Selected |
|--------|-------------|----------|
| Rebuild cache excluding missing tool (Recommended) | Cache valid, just skips init for missing tool | ✓ |
| Don't rebuild | Only rebuild when version changes | |

**User's choice:** Rebuild excluding missing

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, file lock (Recommended) | `flock` or PID file to prevent parallel rebuilds | ✓ |
| No, no locking | Rare scenario, self-heals on next start | |

**User's choice:** File lock

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, keep it (Recommended) | Compile cache to .zwc after rebuild | ✓ |
| No, skip it | Simpler, slightly slower | |

**User's choice:** Keep compiling

---

| Option | Description | Selected |
|--------|-------------|----------|
| Generic: `tool --version 2>/dev/null \| head -1` (Recommended) | Works for all 3 tools with one pattern | ✓ |
| Tool-specific commands | More accurate per tool but more code | |
| Binary hash (sha256sum) | Most accurate but slower | |

**User's choice:** Generic `tool --version | head -1`

---

## Cache Rebuild Timing

| Option | Description | Selected |
|--------|-------------|----------|
| Synchronous on shell start (Recommended) | Rebuild before prompt, guarantees fresh cache | ✓ |
| Async background | Shell starts immediately with stale cache | |
| Lazy rebuild on first tool use | Rebuild on first invocation | |

**User's choice:** Synchronous

---

| Option | Description | Selected |
|--------|-------------|----------|
| Silent fallback (Recommended) | No warning, no rebuild on corrupt cache | ✓ |
| Log warning + rebuild | Print warning, trigger rebuild | |

**User's choice:** Silent fallback

---

| Option | Description | Selected |
|--------|-------------|----------|
| Async after rebuild (Recommended) | `zcompile &!` — cache usable immediately | ✓ |
| Synchronous after rebuild | Compile before rebuilding completes | |

**User's choice:** Async

---

| Option | Description | Selected |
|--------|-------------|----------|
| Silent (Recommended) | No output during rebuild | ✓ |
| Verbose once | Show progress message during rebuild | |

**User's choice:** Silent

---

## Bytecode Compilation Timing

| Option | Description | Selected |
|--------|-------------|----------|
| Background on shell start (Recommended) | `zcompile &!` — current behavior | ✓ |
| Explicit bootstrap only | Only during setup command | |
| Synchronous on shell start | Wait for compile to complete | |

**User's choice:** Background on shell start

---

| Option | Description | Selected |
|--------|-------------|----------|
| Already done — plugin cache compiles (Recommended) | Current covers both .zshrc and cache | ✓ |
| Compile all sourced .zsh files | More bytecode, more edge cases | |

**User's choice:** Keep current (plugin cache only)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Silent fallback (Recommended) | `&>/dev/null` — no terminal noise | ✓ |
| Log to file | Write errors to ~/.zsh_compile_errors.log | |
| Show warning | Print on stderr | |

**User's choice:** Silent fallback

---

| Option | Description | Selected |
|--------|-------------|----------|
| Overwrite in-place (Recommended) | zcompile replaces existing .zwc | ✓ |
| Add cleanup of stale .zwc | Remove orphaned .zwc files | |

**User's choice:** Overwrite in-place

---

## History Size & Retention

| Option | Description | Selected |
|--------|-------------|----------|
| Keep 50K (Recommended) | Current — balances recall with file size | ✓ |
| Increase to 100K | Double depth, ~4MB file | |
| Reduce to 10K | Lighter, ~400KB | |

**User's choice:** Keep 50K

---

| Option | Description | Selected |
|--------|-------------|----------|
| Immediate append (Recommended) | `INC_APPEND_HISTORY` — current | ✓ |
| At shell exit only | Write all history on exit | |

**User's choice:** Immediate append

---

| Option | Description | Selected |
|--------|-------------|----------|
| Ignore all duplicates (Recommended) | `HIST_IGNORE_ALL_DUPS` — current | ✓ |
| Ignore consecutive only | Only adjacent duplicates | |
| No dedup | Keep all entries | |

**User's choice:** Ignore all duplicates

---

| Option | Description | Selected |
|--------|-------------|----------|
| No logging (Recommended) | Silently block, no trace | ✓ |
| Log to ~/.zsh_blocked_history | Append blocked cmd with timestamp | |

**User's choice:** No logging

---

## PATH Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| ~/.local/bin > ~/bin > system (Recommended) | User-local bins take priority | ✓ |
| System > user | System packages over user installs | |

**User's choice:** User-local priority

---

| Option | Description | Selected |
|--------|-------------|----------|
| Keep current set (Recommended) | ~/.local/bin, ~/bin, ~/.spicetify | ✓ |
| Add cargo (~/.cargo/bin) | Rust toolchain | |
| Add npm global (~/node_modules/.bin) | Node.js global installs | |

**User's choice:** Keep current set

---

## XDG Compliance

| Option | Description | Selected |
|--------|-------------|----------|
| Set XDG defaults (Recommended) | Let tools respect XDG env vars automatically | ✓ |
| Force XDG per-tool | Explicit zoxide/fzf config paths | |

**User's choice:** Set XDG defaults

---

| Option | Description | Selected |
|--------|-------------|----------|
| No, .zshrc is fine (Recommended) | Interactive-only tools don't need .zshenv | ✓ |
| Yes, add to .zshenv | Ensure XDG compliance for scripts too | |

**User's choice:** Keep in .zshrc

---

## Boot Timer Thresholds

| Option | Description | Selected |
|--------|-------------|----------|
| Keep hardcoded (Recommended) | Constants in zshrc-time function | ✓ |
| Make configurable via env vars | `_ZSHRC_BOOT_EXCELLENT`, etc. | |

**User's choice:** Keep hardcoded

---

## History Filter Regex

| Option | Description | Selected |
|--------|-------------|----------|
| Add URL-embedded tokens, flag-based creds (Recommended) | `https://token@host`, `--token`, `--password` | ✓ |
| Keep current patterns | Current regex en var only | |
| Be more aggressive | Also SSH keys, JWT, base64, .env ops | |

**User's choice:** Extend to URLs and flags

---

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, add SSH/GPG patterns (Recommended) | SSH keys, GPG passphrases | ✓ |
| No, keep current scope | Env vars only | |

**User's choice:** Add SSH/GPG

---

## Deferred Ideas

None — discussion stayed within phase scope
