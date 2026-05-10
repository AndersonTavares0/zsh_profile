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