# Pitfalls Research

**Domain:** Zsh shell configuration for Fedora Linux terminal productivity
**Researched:** 2026-05-10
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Powerlevel10k Instant Prompt Ordering Violation

**What goes wrong:**
The shell appears garbled on startup — cursor positioned wrong, prompt text printed as regular output,
or the user sees `"POWERLEVEL9K_INSTANT_PROMPT=verbose"` warnings on every shell start. In the worst case,
Powerlevel10k disables Instant Prompt entirely, eliminating the perceived-speed benefit.

**Why it happens:**
Powerlevel10k's Instant Prompt **must be the very first thing sourced in `.zshrc`**, before any output
(including `printf`, `echo`, `source`, or external command execution). Any output before the instant
prompt file causes P10k to print a warning or abort instant prompt for that session. The instant prompt
file path uses `XDG_CACHE_HOME` with a username expression that can fail if `$HOME` isn't set yet.

**Current project risk:**
The `.zshrc` (line 9-11) correctly sources instant prompt first, but the path depends on
`${XDG_CACHE_HOME:-$HOME/.cache}` and `${(%):-%n}` (username expansion). If `$XDG_CACHE_HOME` or
`$HOME` is unset (edge case on some container/SSH setups), the path resolves incorrectly and the
file won't be found — Instant Prompt silently disabled.

**How to avoid:**
- Verify the instant prompt source is always the **first executable line** in `.zshrc`
- Keep nothing — not even comments with special characters — before the instant prompt block
- Test in a container/minimal environment where `$XDG_CACHE_HOME` may not be set
- Document that any `echo`, `printf`, or `source` before this line breaks it

**Warning signs:**
- `"POWERLEVEL9K_INSTANT_PROMPT=verbose"` messages at shell start
- Cursor appears at wrong vertical position
- The first prompt looks correct but second+ prompts are broken
- `zshrc-time` reports <50ms but prompt looks "off"

**Phase to address:**
Phase 1 (Foundation) — verify ordering. Phase 9 (Boot Timer + Compilation) — verify no regressions.

---

### Pitfall 2: zsh-syntax-highlighting Sourced Before compinit

**What goes wrong:**
Tab completion shows wrong results or is entirely broken. Highlighting overwrites completion menu
output. Command suggestions are highlighted incorrectly. The user can't use Zsh's most-valued feature
(completions) because the highlighting widget hooks into ZLE before `compinit` establishes widget order.

**Why it happens:**
zsh-syntax-highlighting (zsh ≥ 5.8) uses `add-zle-hook-widget` for `zle-line-pre-redraw`. If loaded
before `compinit` (which also registers ZLE widgets), the hooks run in the wrong order. The official
README states: *"zsh-syntax-highlighting must be sourced at the end of the .zshrc file."*

**Current project risk:**
The `.zshrc` (lines 114-118) adds zsh-syntax-highlighting to the `plugins` array before `source $ZSH/oh-my-zsh.sh`.
This is NOT sourcing it early — the actual source happens via OMZ's plugin loader (which runs after
OMZ loads, so after compinit). This is correct.
HOWEVER: When zsh-defer is active (lines 126-135), the deferred source of zsh-syntax-highlighting
must still happen AFTER autosuggestions. The current ordering is correct (autosuggestions deferred at
line 131, syntax-highlighting at line 134), but this is a fragile ordering dependency.

**How to avoid:**
- Always source syntax-highlighting AFTER `source $ZSH/oh-my-zsh.sh`
- When using zsh-defer, source autosuggestions first, then syntax-highlighting
- Document this constraint explicitly so refactoring doesn't break it
- Add a comment near the syntax-highlighting source: "MUST be last plugin sourced"
- Test completion behavior after changing any plugin loading order

**Warning signs:**
- Tab completions don't show expected menus
- Highlighting flickers or disappears when tab-completing
- Completion selections revert/highlight incorrectly
- Error messages about ZLE widgets in terminal output

**Phase to address:**
Phase 3 (OMZ Integration) — verify loading order during implementation.
Phase 7 (Heavy Plugins) — explicitly test the zsh-defer path.

---

### Pitfall 3: Plugin Cache Fingerprint Collision

**What goes wrong:**
The plugin cache silently uses stale tool initialization scripts. User upgrades `zoxide` or `fzf`
via `dnf upgrade`, the binary path stays the same (in-place update), but the init script changes.
The fingerprint doesn't detect the change, and old cached init code runs against the new tool version.
Symptoms range from silent (zoxide works but with old defaults) to catastrophic (zoxide init emits
errors that are cached invisibly and replayed on every shell start).

**Why it happens:**
The fingerprint is based on `command -v <tool>` which returns the binary **path**, not the **version**
or **content hash**. On Fedora, DNF updates tools in-place (`/usr/bin/zoxide`) without changing the
path. So the fingerprint stays identical even though the binary changed.

**Current project risk:**
The `_zsh_gen_fingerprint()` function (lines 61-68) uses `command -v zoxide` → `/usr/bin/zoxide` for
the fingerprint. A `dnf upgrade zoxide` from 0.9.8 to 0.9.9 doesn't change this path. The cache won't
rebuild, and if `zoxide init zsh` output changed between versions, the cached version is stale.

**How to avoid:**
- Add version string to fingerprint: `zoxide --version` instead of just `command -v`
- Or hash the tool binary: `cksum $(command -v zoxide)` for content-based detection
- Or set explicit cache TTL (e.g., rebuild daily via a timestamp)
- Or document that users should `rm ~/.cache/zsh_plugins_init.zsh` after tool upgrades

**Warning signs:**
- zoxide/fzf behavior doesn't match expected version's behavior
- No cache rebuild notice after `dnf upgrade`
- Shell startup unchanged after tool version upgrades

**Phase to address:**
Phase 2 (Plugin Cache) — fix fingerprint to include version string or binary content hash.

---

### Pitfall 4: Sudo Wrapper Bypass via `command sudo`

**What goes wrong:**
The `sudo()` function override (lines 231-246) protects against `sudo !!` with dangerous commands.
But the protection is trivially bypassable — any user can type `command sudo rm -rf /` and the
wrapper is completely skipped because `command` tells Zsh to use the builtin/command, not the function.

**Why it happens:**
The `sudo()` function only overrides bare `sudo` calls. Using `command sudo` bypasses function lookup.
This is by design (it's how `command sudo zsh -c "$cmd"` inside the wrapper works), but it means the
protection is advisory, not a security boundary.

**Acceptance:** This is acceptable for a personal shell configuration — the sudo wrapper is a
muscle-memory safety net, not an access control system. Document this limitation.

**How to avoid (if stronger protection is needed):**
- Add `alias sudo='sudo '` (trailing space enables alias expansion after sudo, allowing function override)
- However, this is fragile and may break tools that exec sudo directly

**Warning signs:**
- User can still type `command sudo rm -rf /` and bypass all checks
- False sense of security in the readme documentation

**Phase to address:**
Phase 4 (Security Layer) — explicitly document the limitation in comments and readme.

---

### Pitfall 5: History Filter Regex Evasion

**What goes wrong:**
Commands containing sensitive data still end up in `.zsh_history`. The regex only matches
`TOKEN=value` and `SECRET=value` patterns, but misses:
- Quoted patterns: `TOKEN="abc123"` (regex matches `=` after the keyword)
- Base64-encoded tokens: `export TOKEN=YWJjMTIz` looks like a token to the user but the filter based on keyword still catches it
- Multi-line commands where token is on second line
- Commands using different patterns like `--token` flags: `gh auth login --with-token <<< ghp_xxxx`
- Environment files: `source .env` (leaks everything from the file)
- Piped secrets: `echo "password123" | pass insert ...`
- Tokens in URLs: `git clone https://token@github.com/org/repo.git`

**Why it happens:**
The regex is simple: `(TOKEN|SECRET|PASSWORD|...)\s*=`. It only catches assignments. Many real-world
leak patterns use command flags, file sourcing, or URL embedding. A comprehensive filter would be
much more complex and risk blocking legitimate commands.

**Current project risk:**
The filter (lines 49-53) catches a subset of credential exposures. Users may have a false sense of
complete protection. The most common real leak — `git clone https://token@github.com/...` — is NOT
blocked.

**How to avoid:**
- Add URL credential pattern: `https?://[^@]+@` (catches tokens in clone URLs)
- Add `--token`, `--password`, `--key` flag matching
- Add `GH_TOKEN`, `GITHUB_TOKEN`, `AWS_ACCESS_KEY_ID`, `TOKEN=` (no space) patterns
- Accept that this is a defense-in-depth measure, not a complete solution
- Document that users should still run `history -c` after sensitive sessions

**Warning signs:**
- `grep -i 'token\|secret\|password' ~/.zsh_history` returns entries (a manual audit)
- User finds saved credentials in history after trusting the filter

**Phase to address:**
Phase 4 (Security Layer) — expand regex patterns to cover more leak vectors.

---

### Pitfall 6: Race Condition in Background `zcompile`

**What goes wrong:**
When multiple shell instances start simultaneously (e.g., tmux session with 4 panes, or a script
spawning background shells), all instances check `if [[ ! -f ~/.zshrc.zwc || ~/.zshrc -nt ~/.zshrc.zwc ]]`
simultaneously, and all try to `zcompile ~/.zshrc &!` at the same time. The first one succeeds,
the others write a partially-compiled `.zwc` that may be corrupt or may miss the latest simultaneous
`.zshrc` modifications.

In practice, the compilation runs in the background and finishes after shell startup, so a corrupted
`.zwc` will be used on the NEXT shell start — which means the corruption is both rare and
self-healing (the next start will recompile).

**Why it happens:**
No file locking around the `zcompile` call. The race window is small (compilation takes 10-30ms)
but real when opening terminal multiplexers.

**Current project risk:**
Low. The `.zwc` file is advisory (Zsh falls back to source if `.zwc` is missing or corrupt).
But the existing compilation check has a TOCTOU (time-of-check-time-of-use) race:
line 324 checks freshness, line 325 compiles without locking.

**How to avoid:**
- Add a lock file: check for `~/.zshrc.zwc.lock` before compiling
- Or use `zcompile` with a temp file + atomic rename: `zcompile /tmp/zshrc.zwc && mv /tmp/zshrc.zwc ~/.zshrc.zwc`
- Or simply accept the race (it's self-healing and extremely rare in practice)

**Warning signs:**
- Occasional "bad file descriptor" or "parse error" messages from Zsh on startup
- `.zwc` file smaller than expected (partial compilation)

**Phase to address:**
Phase 9 (Boot Timer + Compilation) — add atomic rename pattern for `zcompile`.

---

### Pitfall 7: Plugin Cache Race Condition During Build

**What goes wrong:**
Similar to Pitfall 6, but affects the plugin cache file. When the fingerprint doesn't match,
`_zsh_build_plugin_cache()` writes to a temp file and atomically renames — which is correct.
The race happens on the **fingerprint check**: if Shell A rebuilds the cache while Shell B is
simultaneously checking the fingerprint, Shell B sees a new fingerprint (from the rebuilt cache)
that doesn't match its cached copy, triggering ANOTHER rebuild. In a terminal multiplexer opening
6 panes, this can cause 3-4 sequential rebuilds before stabilizing.

**Why it happens:**
No distributed locking around the fingerprint-check → rebuild cycle. Each shell rebuilds independently.

**How to avoid:**
- Add a lock file mechanism using `mkdir` (which is atomic on Linux):
  ```zsh
  if mkdir "$_PLUGIN_CACHE.lock" 2>/dev/null; then
    # We hold the lock — rebuild
    _zsh_build_plugin_cache
    rmdir "$_PLUGIN_CACHE.lock"
  else
    # Another shell is rebuilding — wait briefly, then use if available
    sleep 0.5 && [[ -f "$_PLUGIN_CACHE" ]] && source "$_PLUGIN_CACHE"
  fi
  ```
- Or accept the race (each rebuild is idempotent, just wasted cycles)

**Warning signs:**
- `dmesg | tail` shows nothing, but shell startup feels slow (multiple rebuilds)
- `$_PLUGIN_CACHE` modification time updates multiple times in quick succession

**Phase to address:**
Phase 2 (Plugin Cache) — add advisory locking for rebuild.

---

### Pitfall 8: zsh-defer + zsh-autosuggestions Interaction Breaking Highlighting

**What goes wrong:**
When zsh-defer loads autosuggestions and syntax-highlighting deferred, the order of execution
after the prompt appears is: zsh-defer first loads autosuggestions, then syntax-highlighting.
If autosuggestions registers ZLE widgets that conflict with syntax-highlighting's hooks, the
highlighting can be permanently broken until the next shell restart.

In the worst case, autosuggestions' async suggestion fetch fires before syntax-highlighting's
hook registers, resulting in suggestions without proper highlighting until the next keystroke.

**Why it happens:**
The deferred loading defers both plugins until the shell is idle. But "idle" means the first idle
event — both plugins execute in the same event loop iteration. The order is: `zsh-defer emit`
→ autosuggestions source → syntax-highlighting source. If autosuggestions modifies the buffer
during its init, syntax-highlighting may not be active yet to color it.

**Current project risk:**
The existing code sources autosuggestions first (line 131) then syntax-highlighting (line 134),
which is the correct order. But the interaction timing is inherently non-deterministic due to
async loading.

**How to avoid:**
- Add a small delay between deferred sources: `zsh-defer -t 0.01 source ...` for syntax-highlighting
- Or wrap the deferred syntax-highlighting source with an explicit `_zsh_highlight` refresh:
  ```zsh
  zsh-defer source ...syntax-highlighting.zsh && _zsh_highlight
  ```
- Or don't defer syntax-highlighting at all (it uses ZLE hooks which are fast)
- Default: only defer autosuggestions, load syntax-highlighting synchronously after OMZ

**Warning signs:**
- First keystroke after shell start shows unhighlighted command
- Highlighting appears one keystroke delayed
- Autosuggestions appear but without highlighting on the suggested portion

**Phase to address:**
Phase 7 (Heavy Plugins) — test and stabilize deferred loading order.

---

### Pitfall 9: `.zshrc` Becomes Unmaintainable Monolith

**What goes wrong:**
As more aliases, functions, and experimental features accumulate, the single `.zshrc` file grows
past 500, 800, or 1000 lines. Adding a new feature requires understanding the entire file.
Disabling features requires commenting out hard-to-find lines. Load ordering bugs become
impossible to reason about. The file becomes "append-only" — nobody refactors it.

**Why it happens:**
The `.zshrc` is the "easy" place to add things. Creating separate files requires a loading
mechanism, sourcing order, and directory structure. The activation energy for modularization
is higher than appending to `.zshrc`.

**Current project risk:**
At 342 lines, the `.zshrc` is approaching the maintainability cliff. The ARCHITECTURE.md
research recommends modularization past 400 lines. Every new feature pushes closer to this.

**How to avoid:**
- Before adding anything new, consider: "Does this belong in its own file under `zsh/`?"
- Modularize early (now, at 342 lines) before the file grows
- Follow the recommended structure from ARCHITECTURE.md (zsh/config/, zsh/plugins/, etc.)
- Set a hard limit: `.zshrc` stays under 100 lines as an entry point; all logic lives in modules

**Warning signs:**
- `.zshrc` exceeds 400 lines
- Comments are the primary navigation mechanism
- "Where is X defined?" requires searching the whole file
- New contributors (future self included) find it intimidating

**Phase to address:**
Phase 0 or dedicated refactoring phase — modularize `.zshrc` before adding features.

---

## Moderate Pitfalls

### Pitfall 10: P10k Path Resolution Failure

**What goes wrong:**
Powerlevel10k theme file can't be found, and the user gets a default Zsh prompt (ugly, no git status,
no icons). The `.zshrc` tries two paths but both may fail if P10k is installed in an unusual location
or via a package manager.

**Current project risk:**
Lines 313-317 try `~/powerlevel10k/` first, then `${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/`.
This covers the two most common install methods (manual clone to home, OMZ clone to custom dir).
But it does NOT handle:
- System-wide install via `dnf install powerlevel10k` (not available)
- Arch Linux AUR package (`/usr/share/zsh-theme-powerlevel10k/`)
- Homebrew (`$(brew --prefix)/share/powerlevel10k/`)

**How to avoid:**
- Test the two current paths work on Fedora (they should for the recommended install)
- Document that users must install P10k via git clone into one of these two paths
- Add a fallback resolution mechanism if P10k is installed elsewhere

**Warning signs:**
- No P10k prompt visible (bare Zsh prompt)
- `echo $ZSH_THEME` returns empty
- Error message about file not found on shell start

**Phase to address:**
Phase 8 (Theme Loading) — verify all install paths work; document install requirements clearly.

---

### Pitfall 11: `sudo !!` Fails on Multi-line or Complex Commands

**What goes wrong:**
`sudo !!` returns the wrong command or fails silently. The `fc -ln -1` history extraction only
returns the last command in history, which may be a truncated version of a multi-line command,
a `while` loop, or a pipeline spanning multiple history entries.

**Why it happens:**
Zsh's history system stores multi-line commands as single entries only with specific options
(SHARE_HISTORY can break them). `fc -ln -1` returns the **last entry**, which for a multi-line
pipeline like `cat file.txt | grep pattern | sort -u` is the whole thing. But for a `for` loop
spanning multiple lines, `fc` may only return the last line.

**Current project risk:**
The `sudo !!` pattern (line 233) uses `fc -ln -1` which returns the most recent command. For
simple commands this works. For complex constructs like `while read line; do echo $line; done < file`,
the result is unpredictable. The command is then passed to `command sudo zsh -c "$cmd"`, which
re-parses it — potentially splitting incorrectly.

**How to avoid:**
- Document that `sudo !!` works best for single-line, simple commands
- For complex commands, suggest using `sudo -s` (interactive root shell) instead
- Avoid using in scripts or automated contexts
- Test with known multi-line patterns

**Warning signs:**
- `sudo !!` says "blocked" for a command that doesn't match the blocklist
- `sudo !!` runs a different command than expected
- Error about unterminated quote or unexpected token

**Phase to address:**
Phase 4 (Security Layer) — document limitations and edge cases.

---

### Pitfall 12: Cross-Distro Aliases Cause Errors

**What goes wrong:**
A user on Ubuntu or macOS sources the config. `dnf-clean` runs `sudo dnf autoremove` which
fails with "command not found: dnf". The alias definition itself doesn't fail (it's just a string),
but when the user types `dnf-clean` they get an error. More subtly, if they're on a system without
`flatpak`, `flatpak-clean` fails similarly.

**Current project risk:**
The aliases (lines 301-303) are unconditional — they always define, even if `dnf` or `flatpak`
don't exist. This means:
- On Debian: `dnf-clean` → `command not found: dnf`
- On macOS: both DNF and Flatpak aliases fail
- The error message is confusing (user doesn't know why `dnf-clean` exists)

**How to avoid:**
- Guard system aliases with `command -v` checks, like eza aliases are guarded:
  ```zsh
  command -v dnf &>/dev/null && alias dnf-clean='sudo dnf autoremove -y && sudo dnf clean all'
  ```
- Or document clearly which aliases are Fedora-specific
- Or provide fallback implementations for common distros

**Warning signs:**
- `command not found: dnf` on a non-Fedora system
- User confused about why Fedora-specific aliases exist in their config

**Phase to address:**
Phase 5 (Aliases) — add `command -v` guards to all distro-specific aliases.

---

### Pitfall 13: Boot Timer Silent Failure

**What goes wrong:**
`_zshrc_load_ms` is always empty or zero. The `zshrc-time` function shows no output or
incorrect values. User can't track boot performance.

**Why it happens:**
`zmodload zsh/datetime` (line 16) may fail if the `zsh/datetime` module is not available
(e.g., minimal Zsh install, container environment, very old Zsh). The `zmodload` call doesn't
check the return value, so `$EPOCHREALTIME` remains empty. The calculation:
`printf "%.0f" "$(( (EPOCHREALTIME - _zshrc_start_s) * 1000 ))"` then produces nonsense.

**Current project risk:**
Line 16 loads `zsh/datetime` without error checking. A Fedora 44 system has this module, but
if someone copies this config to a distro where it's not compiled in, the timer fails silently.

**How to avoid:**
- Check `zmodload` return value:
  ```zsh
  zmodload zsh/datetime 2>/dev/null || { typeset -g _zshrc_load_ms=-1; }
  ```
- Guard all timer math: `if (( _zshrc_start_s > 0 )); then ... calculate ...`
- Add a fallback timer using `SECONDS` (always available) instead of `EPOCHREALTIME`

**Warning signs:**
- `zshrc-time` shows 0ms or NaN
- `echo $_zshrc_load_ms` is empty
- `zshrc-time` outputs nothing or error

**Phase to address:**
Phase 9 (Boot Timer + Compilation) — add error handling for `zmodload`.

---

### Pitfall 14: Lazy Loading Race with First Command

**What goes wrong:**
User opens terminal, immediately types a command (before prompt is fully rendered), and the
deferred plugin sources (autosuggestions, syntax-highlighting) load in the middle of their
typing. The first few characters have no highlighting; then suddenly the highlighting kicks in
mid-command, causing a visible flash.

**Why it happens:**
zsh-defer defers execution until the first idle event. If the user types fast enough, they can
"beat" the deferred loading. The prompt fires `zle-line-pre-redraw` on each keystroke, and
until syntax-highlighting loads, no highlighting happens.

**How to avoid:**
- Accept that deferred loading has a brief window without highlighting
- Set `zsh-defer` to load after a wind-down period: `zsh-defer -t 0.5 source ...`
- Document that the first few keystrokes may not have highlighting
- Consider not deferring syntax-highlighting (it's fast enough to load synchronously)

**Warning signs:**
- First 1-3 keystrokes show no highlighting
- Autosuggestions first appear after typing has started

**Phase to address:**
Phase 7 (Heavy Plugins) — document and set expectations for deferred loading behavior.

---

## Minor Pitfalls

### Pitfall 15: `sedi` Trap Cleanup Leaves Temp Files

**What goes wrong:**
If `sedi` is interrupted (Ctrl+C) during `sed "$pattern" "$file" > "$tmp"`, the trap handler
`rm -f "$tmp"` runs and cleans up. But the trap is explicitly removed at line 259: `trap - INT TERM`.
If `mv "$tmp" "$file"` is interrupted AFTER the trap removal, a temporary file is left in `/tmp`.

**How to avoid:**
- Use `&&` chaining correctly (current implementation) — the mv only runs if sed succeeds
- Keep trap active until the final rename: move `trap - INT TERM` AFTER the `mv` command
- Or use `zsystem flock` for safer file operations (Zsh ≥ 5.3)

**Phase to address:**
Phase 6 (Functions) — fix trap cleanup ordering.

---

### Pitfall 16: `lazyg` Push Shows Wrong Branch

**What goes wrong:**
After a `git checkout` or `git switch`, `lazyg "message"` correctly detects the current branch
(line 207). But if the remote has a differently-named upstream, or the repo is in detached HEAD
state, `git rev-parse --abbrev-ref HEAD` returns `"HEAD"` and the push command
`git push origin "HEAD"` pushes to the default branch (main/master) — not what the user expects.

**How to avoid:**
- Check for detached HEAD and warn: `if [[ "$branch" == "HEAD" ]]; then printf '⚠️ Detached HEAD\n'; return 1; fi`
- Use `git rev-parse --symbolic-full-name --abbrev-ref @{upstream}` to detect upstream branch

**Phase to address:**
Phase 6 (Functions) — add detached HEAD detection to `lazyg`.

---

### Pitfall 17: Emojis in Output Fail on Minimal Terminals

**What goes wrong:**
The `.zshrc` uses emoji for success/error indicators (✅, ❌, ⚠️). On terminals without emoji
font support (TTY consoles, some SSH clients, CI logs), these show as missing glyph boxes ☐ or
not at all.

**How to avoid:**
- Keep emoji in prompts as user choice (P10k config handles this)
- For function output, consider using ASCII alternatives with a preference for LANG-based selection
- Accept that this is a cosmetic issue on minimal terminals (function output is still readable)

**Phase to address:**
Phase 6 (Functions) — consider ASCII fallbacks for function output messages.

---

### Pitfall 18: `cksum` Not Available on Minimal Systems

**What goes wrong:**
The fingerprint function (line 67) uses `cksum | cut -d' ' -f1`. On extremely minimal systems
(Docker containers, BusyBox-based environments), `cksum` may not be available, causing the
fingerprint to be empty, which causes cache rebuild on every shell start.

**How to avoid:**
- Add a fallback: use `md5sum` or `sha256sum` if `cksum` is missing, or just use `date +%s`
- Or embed the fingerprint differently: `print -n "$fp" | command -v cksum &>/dev/null && cksum || echo "$fp"`

**Phase to address:**
Phase 2 (Plugin Cache) — add `cksum` fallback.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Monolithic `.zshrc` (single file) | Easy to add, no structure to learn | Hard to maintain past 400 lines, ordering bugs, "append-only" pattern | Only < 400 lines. Current (342) is borderline. |
| Function instead of script for `extract` | One file, no PATH management | Pollutes shell namespace, can't be used by other shells or scripts | For personal shell functions — never for reusable tools |
| `&!` background compile without lock | Zero startup cost | Race condition on parallel shell starts | Acceptable — self-healing (corrupt .zwc is recompiled next start) |
| Hardcoded `$HOME/.oh-my-zsh/custom` paths | Simple, works for Fedora-only | Fails if OMZ is installed elsewhere (KDE/Zsh integration, container) | Never — always use `${ZSH_CUSTOM:-...}` fallback pattern |
| DNF-only aliases without `command -v` guard | Fedora users get aliases immediately | Non-Fedora users get confusing errors | Acceptable if documented as Fedora-only — but add `command -v` guard for better UX |
| History filter as simple regex | Catches common credential leaks | Misses URL tokens, flag-based credentials, multi-line leaks | Acceptable as defense-in-depth — but document limitations |
| Emoji in function output | Visual feedback | Unreadable on TTY/minimal terminals | Acceptable if there's ASCII alternative — current has none |
| `trap` removal before cleanup in `sedi` | (Bug, not shortcut) | Temp file leak on interrupt | Never — this is a bug, not a shortcut |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| **Powerlevel10k + OMZ** | Setting `ZSH_THEME="powerlevel10k/powerlevel10k"` and letting OMZ handle theme loading | Set `ZSH_THEME=""` and source P10k theme manually at the END of `.zshrc` |
| **zsh-syntax-highlighting + compinit** | Sourcing syntax-highlighting before `source $ZSH/oh-my-zsh.sh` (which runs compinit) | Source syntax-highlighting AFTER OMZ loads, at the very end of plugin loading |
| **zsh-autosuggestions + zsh-syntax-highlighting** | Loading syntax-highlighting BEFORE autosuggestions | Always load autosuggestions first, then syntax-highlighting |
| **zsh-defer + heavy plugins** | Deferring syntax-highlighting with the same timer as autosuggestions | Defer autosuggestions first, then syntax-highlighting; consider a small delay between them |
| **Plugin cache + DNF updates** | Using `command -v` path as fingerprint — doesn't detect in-place binary updates | Use version string (`tool --version`) or content hash as fingerprint |
| **sudo wrapper + OMZ sudo plugin** | Enabling OMZ's `sudo` plugin (plugs `sudo` with `sudo -e` or other behavior) with custom `sudo()` function | OMZ sudo plugin disables — the custom `sudo()` handles `!!` expansion differently. Either disable OMZ sudo plugin or don't use `sudo()` override. |
| **P10k instant prompt + background jobs** | Having init code that spawns background processes before P10k instant prompt loads | P10k instant prompt MUST be first. Any background jobs started after that are fine. |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| **Too many synchronous plugins** | Boot time > 500ms | Use plugin cache for zoxide/fzf, defer heavy plugins with zsh-defer | With 4+ synchronous plugins that have expensive init |
| **`eval "$(tool init)"` in .zshrc** | Slow startup, runs tool init on every shell | Cache init output via fingerprint cache (current project does this for zoxide/fzf) | Whenever the tool init does I/O (env detection, shell detection) |
| **Incremental .zshrc growth** | Gradual boot time increase (hard to notice) | Boot timer (`zshrc-time`) + set a 150ms budget | Every 10-20 new lines of init code adds ~2-5ms |
| **Unconditional compinit rebuild** | Each shell start regenerates completion cache | OMZ handles `compinit -C` (skip cache rebuild) — verify this is happening | Every shell start if `compinit` runs without `-C` |
| **Many git status calls** | P10k prompt is slow in large git repos | P10k's `gitstatus` daemon handles this — verify it's running | Repos with 50k+ files without gitstatus |
| **NFS/home directory on network mount** | Shell startup takes seconds, `stat` calls are slow | Move cache files to local disk (`$XDG_CACHE_HOME` on local SSD) | When `$HOME` is on NFS (corp laptops, thin clients) |
| **XDG_* vars pointing to slow FS** | All cache operations slow | Set `$XDG_CACHE_HOME` explicitly to a local path in `.zshenv` | When defaults point to NFS or CIFS mounts |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| **History filter regex misses URL tokens** | Token in `git clone https://token@github.com/...` saved to `.zsh_history` | Add URL credential pattern: `https?://[^@]+@` |
| **`command sudo` bypasses sudo wrapper** | `command sudo rm -rf /` executes without block | Document limitation; accept for personal use; don't claim "security protection" |
| **History filter is case-**insensitive** but keyword list is short** | `MY_TOKEN=xxx` is blocked (case-insensitive), but `GH_PAT=xxx` or `NPM_TOKEN=xxx` passes | Expand keyword list: GH_TOKEN, GITHUB_TOKEN, API_KEY, PAT, NPM_TOKEN, etc. |
| **History on shared machine** | Multi-user system — other users can read `~/.zsh_history` | Set `HISTFILE` to `$XDG_DATA_HOME/zsh/history` with 600 permissions; or use encrypted $HOME |
| **`sharing_history` saves commands across sessions** | Command from one terminal session immediately visible in another — sensitive commands may be seen | Use `SHARE_HISTORY` carefully on shared machines; on single-user personal machine it's a feature |
| **Environment files sourced in .zshrc** | `source .env` in .zshrc leaks all env vars to history (not directly — sourced files aren't in history, but the `source .env` command is) | Never `source .env` from shell config; use `direnv` or per-directory loading |
| **Background forked processes inherit environment** | Token in env var can leak to background process output | Use `local` for temporary secrets; unset env vars after use |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| **Lazy loading delay on first keystrokes** | No highlighting for first 1-3 characters | Document clearly; consider synchronous loading for syntax-highlighting |
| **DNF aliases on non-Fedora systems** | `command not found: dnf` on first use | Guard with `command -v dnf` check, or provide helpful message: "This alias requires DNF (Fedora)" |
| **`sudo !!` blocks unexpected commands** | User's legitimate command blocked by overly broad regex | Make blocklist explicit and documented; error message should show what was blocked and why |
| **Boot timer shows only in English** | Non-English terminal users see broken emoji | Use ASCII indicators as primary, emoji as enhancement |
| **No keyboard shortcut documentation** | User doesn't know about Ctrl+R (fzf), Alt+C (zoxide), Ctrl+T (fzf file search) | Add a `zsh-help` or `zsh-keys` command that prints available shortcuts |
| **Long PATH with duplicates** | Slow command resolution, confusing `which` output | `typeset -U path PATH` handles this; but also audit PATH additions for stale entries |
| **Installation instructions are `cp .zshrc ~/.zshrc`** | Overwrites existing `.zshrc` without backup | Use `bootstrap.sh` that backs up existing files before symlinking |

---

## "Looks Done But Isn't" Checklist

- [ ] **Powerlevel10k Instant Prompt:** Sourced first in `.zshrc`? Verify the path resolves correctly when `$XDG_CACHE_HOME` is unset. Run `[[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]` and confirm it returns 0 in a fresh shell.
- [ ] **History security filter:** Test with `export TOKEN=test123` — confirm it doesn't appear in `history`. Test with `git clone https://token@github.com/repo.git` — verify if this leak is caught or documented as unblocked.
- [ ] **Sudo wrapper:** Test `sudo !!` with a harmless command after `touch /tmp/test`. Test `command sudo rm -rf /` — confirm bypass works (so documentation is accurate).
- [ ] **Plugin cache rebuild:** Run `dnf upgrade zoxide -y`, restart shell — verify cache rebuilds. The fingerprint needs to detect in-place binary updates.
- [ ] **compinit:** Open a fresh shell, type `git <TAB><TAB>` — verify completions work. If not, OMZ's compinit is broken.
- [ ] **zsh-autosuggestions:** Type a previously-used command — verify gray suggestion text appears. If not, the plugin isn't loading.
- [ ] **zsh-syntax-highlighting:** Type `ls -la /nonexistent` — verify the path is highlighted in red (error color). If all text is same color, highlighting isn't active.
- [ ] **Lazy loading:** When zsh-defer is installed, run `ps aux | grep zsh` after shell start — verify zsh-defer processes exist. Run `zshrc-time` — confirm defer reduces boot time vs. synchronous loading.
- [ ] **.zshrc.zwc compilation:** Check `~/.zshrc.zwc` exists and is newer than `.zshrc`. Run `zcompile -t ~/.zshrc.zwc` to verify it's valid bytecode.
- [ ] **Cross-distro test:** Source the `.zshrc` on a Debian/Ubuntu container. Verify it doesn't error out (system aliases gracefully degrade).
- [ ] **Interrupt safety:** Start `sedi s/foo/bar/g somefile` and press Ctrl+C mid-operation. Verify no temp files remain in `/tmp` and the original file is unmodified.
- [ ] **Detached HEAD in lazyg:** Checkout a commit directly (`git checkout HEAD~1`), run `lazyg "test"` — verify it warns about detached HEAD instead of pushing to default branch.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Instant Prompt broken | LOW — remove `source` line for instant prompt, restart shell | Comment out or remove the instant prompt source block; re-run `p10k configure` to regenerate |
| Stale plugin cache | LOW — delete cache file | `rm -f ~/.cache/zsh_plugins_init.zsh ~/.cache/zsh_plugins_init.zsh.zwc` → restart shell |
| Corrupt `.zwc` file | LOW — delete and recompile | `rm -f ~/.zshrc.zwc` → restart shell (recompiles automatically) |
| Broken sudo function | MEDIUM — temporarily remove function override | Comment out `sudo()` function block, restart shell; use `/usr/bin/sudo` directly until fixed |
| zsh-syntax-highlighting breaks completions | MEDIUM — comment out highlighting plugin | Remove syntax-highlighting from `plugins+=()` or comment out the zsh-defer source; restart shell |
| `.zshrc` unparseable (syntax error) | HIGH — cannot source to fix itself | Open a new terminal (uses default shell), edit `.zshrc` with a basic `$EDITOR .zshrc` command; or boot into rescue shell with `zsh -f` |
| zsh-defer breaks prompt | LOW — remove zsh-defer plugin directory | `rm -rf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-defer` → restart shell (falls back to synchronous loading) |
| Boot timer error floods output | LOW — disable timer | Set `typeset -g _zshrc_load_ms=-1` and comment out `zmodload zsh/datetime`; or just the `zshrc-time()` function |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Instant Prompt ordering violation | Phase 1 / Phase 9 | Test in container with unset `$XDG_CACHE_HOME` |
| zsh-syntax-highlighting before compinit | Phase 3 (OMZ) / Phase 7 (Heavy) | Test tab completion with highlighting active |
| Cache fingerprint collision | Phase 2 (Plugin Cache) | Upgrade zoxide via DNF, verify cache rebuilds |
| Sudo wrapper bypass | Phase 4 (Security) | Try `command sudo rm -rf /` — should succeed (documented bypass) |
| History filter regex evasion | Phase 4 (Security) | Audit `~/.zsh_history` for sensitive entries after a week of use |
| `zcompile` race condition | Phase 9 (Boot Timer) | Open 4 panes simultaneously, verify `.zwc` is valid |
| Plugin cache race condition | Phase 2 (Plugin Cache) | Opens 6 panes simultaneously, verify single rebuild |
| zsh-defer interaction with highlighting | Phase 7 (Heavy Plugins) | Type immediately after shell start, verify highlighting is correct |
| Monolithic `.zshrc` | Phase 0 (Modularization) | Count lines; if > 400, must modularize |
| P10k path resolution | Phase 8 (Theme Loading) | Install P10k in non-standard location, verify prompt loads |
| `sudo !!` multi-line failure | Phase 4 (Security) | Test with `echo "line1" && echo "line2"` |
| Cross-distro alias errors | Phase 5 (Aliases) | Source `.zshrc` on Debian container, verify no errors |
| Boot timer silent failure | Phase 9 (Boot Timer) | Remove `zsh/datetime` module (test env), verify graceful fallback |
| Lazy loading race with first command | Phase 7 (Heavy Plugins) | Type immediately after shell opens, check first 3 keystrokes |
| `sedi` trap cleanup leaves temp files | Phase 6 (Functions) | Interrupt `sedi` with Ctrl+C, check `/tmp` for leftover files |
| `lazyg` push shows wrong branch | Phase 6 (Functions) | Test with detached HEAD, verify warning is shown |
| Emoji display on minimal terminals | Phase 6 (Functions) | Test via `ssh localhost` or `script /dev/null` |
| `cksum` not available | Phase 2 (Plugin Cache) | Test in BusyBox container |

---

## Sources

- Powerlevel10k official README (GitHub) — Instant Prompt ordering requirement: https://github.com/romkatv/powerlevel10k (HIGH confidence)
- zsh-syntax-highlighting FAQ — "must be sourced at end of .zshrc": https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/README.md (HIGH confidence)
- Zsh manual — Startup/shutdown files: https://zsh.sourceforge.io/Doc/Release/Files.html (HIGH confidence)
- Zsh manual — `zcompile` and `.zwc` files: https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html (HIGH confidence)
- ArchWiki Zsh page — Common pitfalls and best practices: https://wiki.archlinux.org/title/Zsh (HIGH confidence)
- zsh-bench by romkatv — Instant Prompt and startup measurement: https://github.com/romkatv/zsh-bench (MEDIUM confidence)
- Existing `.zshrc` v2.3 code analysis — direct examination of implemented patterns and edge cases (HIGH confidence)
- Common dotfiles community patterns — mathiasbynens, thoughtbot, ohmyzsh wiki (MEDIUM confidence)
- Fedora 44 package management behavior — DNF in-place binary updates vs fingerprint detection (HIGH confidence — confirmed via `rpm -q --changelog` verification)

---

*Pitfalls research for: Zsh Profile — Fedora Optimized*
*Researched: 2026-05-10*
