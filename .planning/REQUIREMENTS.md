# Requirements: Zsh Profile — Fedora Optimized

**Defined:** 2026-05-10
**Core Value:** Shell starts fast, stays secure, and makes daily terminal work more productive without ceremony.

## v1 Requirements

### Shell Foundation

- [ ] **SHELL-01**: User's shell prompt appears instantly via Powerlevel10k Instant Prompt (<50ms perceived startup)
- [ ] **SHELL-02**: Boot timer captures startup time from first line to last
- [ ] **SHELL-03**: PATH is deduplicated and includes ~/.local/bin, ~/bin
- [ ] **SHELL-04**: History is managed with 50K entries, deduplication, and cross-session sharing
- [ ] **SHELL-05**: Bytecode compilation of .zshrc runs in background for faster parsing

### Plugin Cache

- [ ] **CACHE-01**: Plugin cache auto-rebuilds when tool versions change (zoxide, eza, fzf)
- [ ] **CACHE-02**: Cache fingerprint uses content hash or version output, not binary path (fix silent staleness)
- [ ] **CACHE-03**: Cache loads conditionally — skips init if fingerprint matches
- [ ] **CACHE-04**: Oh My Zsh loads with git and history plugins, conditionally adds autosuggestions and syntax-highlighting

### Aliases

- [ ] **ALIAS-01**: File listing via eza with icons, group-dirs-first, git status (ls, ll, la, l, lt)
- [ ] **ALIAS-02**: Navigation aliases (home, docs, up/up2/up3/up4)
- [ ] **ALIAS-03**: Colorized grep (grep, fgrep, egrep)
- [ ] **ALIAS-04**: Distro-guarded sys-clean aliases for DNF and Flatpak (dnf-clean, flatpak-clean, sys-clean)

### Functions

- [ ] **FUNC-01**: Navigation functions (dtop, mkcd)
- [ ] **FUNC-02**: File creation function (nf)
- [ ] **FUNC-03**: Git functions (gcom, lazyg) with safety checks
- [ ] **FUNC-04**: Safe sed with timestamped backup (sedi)
- [ ] **FUNC-05**: Universal archive extractor (extract)
- [ ] **FUNC-06**: Timestamped file backup (bk)
- [ ] **FUNC-07**: Port usage checker (port)
- [ ] **FUNC-08**: Boot time display (zshrc-time)

### Security

- [ ] **SEC-01**: History filter blocks commands containing TOKEN, SECRET, PASSWORD, API_KEY, PRIVATE_KEY, CREDENTIAL
- [ ] **SEC-02**: Sudo wrapper blocks dangerous commands (rm -rf /, mkfs, dd of=, chmod -R 777 /, recursive sudo)
- [ ] **SEC-03**: Sudo !! shows warning before executing dangerous patterns

### Theme

- [ ] **THEME-01**: Powerlevel10k loads at the very end of .zshrc
- [ ] **THEME-02**: Local ~/.zshrc.local is sourced before theme for user overrides
- [ ] **THEME-03**: .p10k.zsh configuration is sourced after theme if present

## v2 Requirements

- **V2-01**: Modular directory structure (zsh/aliases/, zsh/functions/, zsh/config/) instead of monolithic .zshrc
- **V2-02**: compinit/menu select completion configuration verification
- **V2-03**: zsh-defer lazy loading with verified ordering for autosuggestions/syntax-highlighting
- **V2-04**: Bootstrap install script (symlink-based, not manual cp)
- **V2-05**: zoxide init fingerprint stabilization
- **V2-06**: Cross-distro compatibility documentation and package manager detection

## Out of Scope

| Feature | Reason |
|---------|--------|
| macOS primary support | Fedora-first, other distros secondary |
| GUI configuration tool | Terminal-driven only |
| Alternative Zsh frameworks (prezto, zim) | Oh My Zsh is the chosen framework — too costly to support multiple |
| Custom plugin manager | Plugin cache + OMZ covers all needs without another dependency |
| CI/CD pipeline | Dotfiles repo — no automated CI needed |
| Multi-user support | Single-user shell configuration |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SHELL-01 | Phase 1 | Pending |
| SHELL-02 | Phase 1 | Pending |
| SHELL-03 | Phase 1 | Pending |
| SHELL-04 | Phase 1 | Pending |
| SHELL-05 | Phase 1 | Pending |
| CACHE-01 | Phase 1 | Pending |
| CACHE-02 | Phase 1 | Pending |
| CACHE-03 | Phase 1 | Pending |
| CACHE-04 | Phase 1 | Pending |
| THEME-01 | Phase 1 | Pending |
| THEME-02 | Phase 1 | Pending |
| THEME-03 | Phase 1 | Pending |
| ALIAS-01 | Phase 2 | Pending |
| ALIAS-02 | Phase 2 | Pending |
| ALIAS-03 | Phase 2 | Pending |
| ALIAS-04 | Phase 2 | Pending |
| FUNC-01 | Phase 2 | Pending |
| FUNC-02 | Phase 2 | Pending |
| FUNC-03 | Phase 2 | Pending |
| FUNC-04 | Phase 2 | Pending |
| FUNC-05 | Phase 2 | Pending |
| FUNC-06 | Phase 2 | Pending |
| FUNC-07 | Phase 2 | Pending |
| FUNC-08 | Phase 2 | Pending |
| SEC-01 | Phase 3 | Pending |
| SEC-02 | Phase 3 | Pending |
| SEC-03 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 27 total
- Mapped to phases: 27
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-10*
*Last updated: 2026-05-10 after initial definition*
