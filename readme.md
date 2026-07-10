# zsh_profile — Fedora-first Zsh Config

[![CI](https://github.com/AndersonTavares0/zsh_profile/actions/workflows/ci.yml/badge.svg)](https://github.com/AndersonTavares0/zsh_profile/actions/workflows/ci.yml)
[![Zsh 5.9](https://img.shields.io/badge/zsh-5.9-f15a24?logo=zsh&logoColor=white)](https://zsh.sourceforge.io/)
[![Oh My Zsh](https://img.shields.io/badge/oh--my--zsh-latest-black?logo=github)](https://ohmyz.sh/)
[![Powerlevel10k](https://img.shields.io/badge/powerlevel10k-v1.20.0-blue?logo=github)](https://github.com/romkatv/powerlevel10k)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

Fedora-first Zsh configuration — modular, secure, and productive. Fast startup (&lt;150ms), intelligent plugin caching, productive aliases and functions, NVIDIA helpers, and in-shell security safeguards. 15 self-documenting source files, tested on Linux and macOS via CI.

---

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/AndersonTavares0/zsh_profile/main/install.sh | bash
```

An interactive menu appears — even through a piped curl session. Choose:

```
╔══════════════════════════════════════════╗
║        Zsh Profile — Fedora v3.3        ║
╠══════════════════════════════════════════╣
║                                          ║
║  [1] Install                             ║
║  [2] Quick Install (auto, no prompts)    ║
║  [3] Uninstall                           ║
║  [q] Quit                                ║
║                                          ║
╚══════════════════════════════════════════╝

Choose [1-3/q]:
```

**Option 1** walks you through each step with confirmation. **Option 2** installs everything immediately. **Option 3** removes symlinks and cache without touching installed packages.

### Non-interactive flags

```bash
./install.sh --install     # Install without menu
./install.sh --uninstall   # Uninstall without menu
```

## Tests

Run every local gate with one command:

```bash
./tests/run.sh
```

The harness checks Zsh and Bash syntax, then runs ZUnit and Bats. It installs
pinned test dependencies under `${XDG_CACHE_HOME:-$HOME/.cache}`; set
`ZSH_PROFILE_TEST_DEPS` to use another directory outside the repository. The
same script supports Linux and macOS with the system Bash 3.2 or newer.

---

## Features

### Performance
- **Powerlevel10k Instant Prompt** — perceived prompt delay &lt;50ms. Must be the first line sourced.
- **Plugin Init Cache** — `zoxide init` and `fzf` key-bindings cached to `$XDG_CACHE_HOME`. Rebuilds only when tool versions change (DNF in-place upgrades detected via `tool --version` fingerprint, not binary path).
- **Bytecode Compilation** — `.zshrc` auto-compiled to `.zwc` in background via `zcompile`.
- **Boot Timer** — `zshrc-time` displays measured startup time with color-coded thresholds.

### Security
- **History Filter** (`zshaddhistory` hook) — silently blocks credential patterns from history:
  env vars (TOKEN, SECRET, PASSWORD, API_KEY, PRIVATE_KEY, CREDENTIAL, ...), URL-embedded tokens (`https://user:pass@host`),
  flag-based credentials (`--token`, `--password`, `--secret`, `--api-key`, `--access-key`), SSH key material, GPG passphrase commands, and AWS CLI credentials. Also blocks commands &gt;4096 chars.
- **Sudo Guard** (`sudo-last` function) — previews the last history command, asks for confirmation, and blocks dangerous patterns: `rm -rf /`, `mkfs`, `dd of=`, `chmod -R 777 /`. Use `--yes` to skip the prompt in scripts.

### Productivity
- **15 modular source files** — one concern per file, loaded in strict dependency order with inline documentation explaining every flag and pattern.
- **eza aliases** — `ls`, `ll`, `la`, `l`, `lt` with icons, git status, and tree view (gracefully skipped when eza is absent).
- **9 utility functions** — directory navigation (`mkcd`, `up [n]`), git workflow (`gcom`, `lazyg` with 10s push timeout), safe sed with backup (`sedi`), multi-format archive extractor (`extract`), timestamped backups (`bk`), empty file creator (`nf`), and port scanner (`port`).
- **System cleanup** — `dnf-clean`, `apt-clean`, `brew-clean`, `flatpak-clean`, `sys-clean` — platform-adaptive, defined only when the corresponding tool is installed.
- **Fedora + NVIDIA helpers** — on-demand GPU status, RPMFusion diagnostics, Akmods rebuild helper, and manual CUDA environment activation.
- **XDG compliance** — `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_DATA_HOME` exported so modern CLI tools auto-respect them.

---

## Architecture

```
~/.zshrc                     # Entry point (symlinked by installer)
~/.zsh_modules/             # Module directory (symlinked by installer)
├── boot/
│   ├── prompt.zsh          # ① P10k Instant Prompt (MUST be first)
│   ├── timer-start.zsh     # ② Wall-clock timer start (EPOCHREALTIME)
│   ├── theme.zsh           # ⑬ P10k theme (MUST be last substantive source)
│   ├── compile.zsh         # ⑭ Bytecode compilation (background)
│   └── timer-end.zsh       # ⑮ Timer end + zshrc-time display
├── core/
│   ├── environment.zsh     # ③ PATH/LD_LIBRARY_PATH dedup, user bins, XDG dirs
│   ├── shell.zsh           # ④ Zsh options, 50K history, dedup, sharing
│   └── security.zsh        # ⑤ History credential filter + sudo wrapper
├── plugins/
│   ├── cache.zsh           # ⑥ Version-fingerprint plugin init cache
│   ├── omz.zsh             # ⑦ Oh My Zsh framework, conditional plugins
│   └── lazy.zsh            # ⑧ zsh-defer deferred source (optional)
└── tools/
    ├── aliases.zsh         # ⑨ eza, grep, navigation, system cleanup
    ├── nvidia.zsh          # ⑩ NVIDIA/Fedora GPU helpers + CUDA opt-in
    ├── functions.zsh       # ⑪ up, mkcd, nf, gcom, lazyg, sedi, extract, bk, port
    └── local.zsh           # ⑫ ~/.zshrc.local overrides (pre-theme)
```

Numbers indicate load order — P10k Instant Prompt must be first, P10k theme must be last. Everything between follows the dependency chain.

For a deep dive into each module, design decisions, and extension guide, see [`docs/TECHNICAL.md`](docs/TECHNICAL.md).

---

## Requirements

| Dependency | Role | Mandatory |
|---|---|---|
| **zsh** &ge; 5.8 | Shell | Yes |
| **git** | OMZ & plugin cloning | Yes |
| **eza** | Modern `ls` with icons + git status | No (aliases skipped if absent) |
| **fzf** | Ctrl-R history, Ctrl-T files, Alt-C dirs | No |
| **zoxide** | `z` frecency-based directory jumping | No |
| **oh-my-zsh** | Plugin framework | Yes |
| **powerlevel10k** | Prompt theme | Yes |

Manual setup (Fedora):

```bash
# System packages
sudo dnf install zsh git eza fzf zoxide -y

# Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Optional plugins
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/romkatv/zsh-defer $ZSH_CUSTOM/plugins/zsh-defer
```

---

## Commands

### Shell Info

| Command | Description |
|---------|-------------|
| `zshrc-time` | Display boot time with color-coded rating |
| `sudo-last` | Execute last history command with sudo (confirmation + safety blocklist) |
| `port [num]` | List listening ports or check if a port is in use (cross-platform) |

### Navigation

| Command | Description |
|---------|-------------|
| `home` / `docs` / `dtop` | Jump to `~`, `~/Documents`, `~/Desktop` |
| `up [n]` | Go up `n` directory levels (default: 1) |
| `mkcd <dir>` | Create directory and `cd` into it |

### File Operations

| Command | Description |
|---------|-------------|
| `nf <file>` | Create empty file with confirmation |
| `bk <file>` | Timestamped backup (`file.bak.YYYYMMDD_HHMMSS`) |
| `extract <archive>` | Auto-detect format: tar.gz, zip, rar, 7z, tar.zst, etc. |
| `sedi "s/a/b/" <file>` | In-place sed with automatic timestamped backup |

### Git

| Command | Description |
|---------|-------------|
| `gcom "msg"` | Stage all + commit (fails on clean working tree) |
| `lazyg "msg"` | `gcom` + interactive push prompt (10s timeout) |

### System

| Command | Description |
|---------|-------------|
| `dnf-clean` | Autoremove orphans + clean DNF cache (Fedora) |
| `apt-clean` | Autoremove + autoclean (Debian/Ubuntu) |
| `brew-clean` | Cleanup Homebrew (macOS) |
| `flatpak-clean` | Remove unused Flatpak runtimes |
| `sys-clean` | Run cleanup for detected package manager (dnf > apt > brew) |
| `reload` | Re-source `~/.zshrc` |

### Fedora + NVIDIA

NVIDIA helpers are optional and on-demand. The module never calls `nvidia-smi` during shell startup, so GPU diagnostics do not affect the sub-150ms startup target.

| Command | Description |
|---------|-------------|
| `nvidia-ver` | GPU name, driver version, and total VRAM |
| `nvidia-stat` | CSV status: temp, utilization, power, memory, pstate |
| `nvidia-quick` | Compact temp/utilization/memory/power output |
| `nvidia-watch` | Refresh `nvidia-smi` every 2 seconds |
| `nvidia-procs` | List GPU compute processes |
| `nvidia-temp` | Print GPU temperature in Celsius |
| `nvidia-mem` | Print used/total GPU memory |
| `nvidia-power` | Print current power draw and power limit |
| `nvidia-clock` | Print graphics clock, memory clock, and pstate |
| `nvidia-persistence [on\|off]` | Show or set NVIDIA persistence mode |
| `nvidia-plimit <watts>` | Set GPU power limit via `sudo nvidia-smi -pl` |
| `nvidia-rpm` | List installed NVIDIA RPM packages |
| `nvidia-kmod` | Show loaded NVIDIA kernel modules |
| `nvidia-update-check` | Check DNF/RPMFusion NVIDIA updates |
| `nvidia-akmods` | Rebuild NVIDIA Akmods and initramfs with confirmation |

### CUDA

CUDA is not added to `PATH` automatically. Run `cuda-env` only when needed. This avoids global `LD_LIBRARY_PATH` side effects and keeps shell startup fast.

| Command | Description |
|---------|-------------|
| `cuda-env` | Add `/usr/local/cuda` and Nsight Compute paths for the current shell |
| `cuda-use <version>` | Activate a side-by-side CUDA install, such as `cuda-use 12.6` |
| `cuda-gcc13` | Set `NVCC_CCBIN=g++-13` when Fedora GCC is newer than CUDA supports |

### File Listing

| Command | Equivalent |
|---------|-----------|
| `ls` | `eza --icons --group-directories-first` |
| `ll` | `eza -lh --icons --group-directories-first --git` |
| `la` | `eza -lah --icons --group-directories-first --git` |
| `l` | `eza -1 --icons` |
| `lt` | `eza --tree --icons --level=2` |

---

## Configuration

Machine-specific overrides go in `~/.zshrc.local` — sourced automatically before the theme, never tracked in git.

Each module file is self-documenting: comments explain what every flag, option, and pattern does, not just what the code does.

---

## Compatibility

| Platform | Status |
|----------|--------|
| **Fedora Linux** | Primary target — all features tested |
| **macOS** | Supported — CI-tested, Homebrew PATH auto-detected |
| RHEL / CentOS Stream | Works (DNF-based, same packages) |
| Debian / Ubuntu | Works with `apt` (installer auto-detects) |
| Arch Linux | Works with `pacman` (installer auto-detects) |
| openSUSE / SUSE | Works with `zypper` (installer auto-detects) |

---

## License

MIT — see [LICENSE](LICENSE).
