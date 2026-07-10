# Issue #16 — Documentation Consistency

## Problem Statement

README and TECHNICAL.md diverge from implemented behavior after fixes to #11, #12, #13, #14, #15:

- TECHNICAL.md says `INC_APPEND_HISTORY` used, `SHARE_HISTORY` intentionally omitted → #14 removed INC_APPEND, kept SHARE_HISTORY
- Security section describes old `sudo()` wrapper → #11 replaced with `sudo-last`
- omz.zsh section says `DISABLE_AUTO_UPDATE=true` → #14 changed to `zstyle ':omz:update' mode disabled`
- Cache section says init output from tools appended blindly → #14 added exit code validation
- Cleanup aliases listed as DNF/Flatpak only → #13 added apt/brew
- `port()` documented as `ss -tulpn` only → #13 added lsof + validation
- Compatibility table says macOS "Partial" → now fully supported
- Title says "Fedora-Optimized" → should be "Fedora-first, Linux/macOS compatible"
- Version bumped to v3.2 — docs aligned with implementation

## Goals

- [ ] README updated: title, security, cleanup, compatibility, tests section
- [ ] TECHNICAL.md updated: history options, sudo-last, zstyle, cache guard, port cross-platform, cleanup aliases
- [ ] Consistent with all implemented fixes from #11-#15

## Requirement Traceability

| ID | Story | Status |
|----|-------|--------|
| DOC-01 | README consistency | Pending |
| DOC-02 | TECHNICAL.md consistency | Pending |
