# Requirements: Zsh Profile — Fedora Optimized

**Defined:** 2026-05-10
**Last updated:** 2026-06-24
**Core Value:** Shell starts fast, stays secure, and makes daily terminal work more productive without ceremony.

## v1 Requirements (all implemented in v3.0)

### Shell Foundation

- [x] **SHELL-01**: User's shell prompt appears instantly via Powerlevel10k Instant Prompt (<50ms perceived startup)
- [x] **SHELL-02**: Boot timer captures startup time from first line to last
- [x] **SHELL-03**: PATH is deduplicated and includes ~/.local/bin, ~/bin
- [x] **SHELL-04**: History is managed with 50K entries, deduplication, and cross-session sharing
- [x] **SHELL-05**: Bytecode compilation of .zshrc runs in background for faster parsing

### Plugin Cache

- [x] **CACHE-01**: Plugin cache auto-rebuilds when tool versions change (zoxide, eza, fzf)
- [x] **CACHE-02**: Cache fingerprint uses content hash or version output, not binary path (fix silent staleness)
- [x] **CACHE-03**: Cache loads conditionally — skips init if fingerprint matches
- [x] **CACHE-04**: Oh My Zsh loads with git and history plugins, conditionally adds autosuggestions and syntax-highlighting

### Aliases

- [x] **ALIAS-01**: File listing via eza with icons, group-dirs-first, git status (ls, ll, la, l, lt)
- [x] **ALIAS-02**: Navigation aliases (home, docs, up/up2/up3/up4)
- [x] **ALIAS-03**: Colorized grep (grep, fgrep, egrep)
- [x] **ALIAS-04**: Distro-guarded sys-clean aliases for DNF and Flatpak (dnf-clean, flatpak-clean, sys-clean)

### Functions

- [x] **FUNC-01**: Navigation functions (dtop, mkcd)
- [x] **FUNC-02**: File creation function (nf)
- [x] **FUNC-03**: Git functions (gcom, lazyg) with safety checks
- [x] **FUNC-04**: Safe sed with timestamped backup (sedi)
- [x] **FUNC-05**: Universal archive extractor (extract)
- [x] **FUNC-06**: Timestamped file backup (bk)
- [x] **FUNC-07**: Port usage checker (port)
- [x] **FUNC-08**: Boot time display (zshrc-time)

### Security

- [x] **SEC-01**: History filter blocks commands containing TOKEN, SECRET, PASSWORD, API_KEY, PRIVATE_KEY, CREDENTIAL (plus URL tokens, flag-based, SSH, GPG)
- [x] **SEC-02**: Sudo wrapper blocks dangerous commands (rm -rf /, mkfs, dd of=, chmod -R 777 /, recursive sudo)
- [x] **SEC-03**: Sudo !! shows warning before executing dangerous patterns

### Theme

- [x] **THEME-01**: Powerlevel10k loads at the very end of .zshrc
- [x] **THEME-02**: Local ~/.zshrc.local is sourced before theme for user overrides
- [x] **THEME-03**: .p10k.zsh configuration is sourced after theme if present

## v2 Requirements (deferred)

- **V2-01**: Modular directory structure — ✅ **Implemented** in v3.0 (`modules/{boot,core,plugins,tools}/`)
- **V2-02**: compinit/menu select completion configuration verification — Pending
- **V2-03**: zsh-defer lazy loading with verified ordering — ✅ **Implemented** (`modules/plugins/lazy.zsh`)
- **V2-04**: Bootstrap install script — ✅ **Implemented** (`install.sh` with interactive menu, symlinks, backup)
- **V2-05**: zoxide init fingerprint stabilization — ✅ **Implemented** (version-based fingerprint)
- **V2-06**: Cross-distro compatibility documentation and package manager detection — Pending

## Out of Scope

| Feature | Reason |
|---------|--------|
| macOS primary support | Fedora-first, other distros secondary |
| GUI configuration tool | Terminal-driven only |
| Alternative Zsh frameworks (prezto, zim) | Oh My Zsh is the chosen framework — too costly to support multiple |
| Custom plugin manager | Plugin cache + OMZ covers all needs without another dependency |
| CI/CD pipeline | Dotfiles repo — no automated CI needed |
| Multi-user support | Single-user shell configuration |

## Implementation

All 27 v1 requirements implemented in v3.0. See:
- `modules/boot/` — prompt, timer, theme, compile
- `modules/core/` — PATH, shell options, security
- `modules/plugins/` — cache, OMZ, lazy loading
- `modules/tools/` — aliases, functions, NVIDIA, local overrides

---
*Last updated: 2026-06-24 — synchronized with v3.0 release*
