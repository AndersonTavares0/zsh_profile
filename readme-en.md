# Zsh Config - Fedora Optimized

![Zsh](https://img.shields.io/badge/Shell-Zsh-f15a24?logo=zsh&logoColor=white)
![Fedora](https://img.shields.io/badge/OS-Fedora-294172?logo=fedora&logoColor=white)
![Oh My Zsh](https://img.shields.io/badge/Framework-Oh%20My%20Zsh-000000?logo=github&logoColor=white)
![Powerlevel10k](https://img.shields.io/badge/Theme-Powerlevel10k-blue?logo=github&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg)

Professional Zsh configuration optimized for Fedora Linux, featuring intelligent plugin caching, system utilities, and enhanced productivity aliases.

> **📝 Note:** AI assisted in code generation, refactoring, documentation, and review of this project.

---

## 🧭 Quick Navigation

**Documentation:**
- [📚 Complete Technical Documentation →](docs-en.md)

**Sections in this document:**
- [↗️ Key Features](#key-features)
- [↗️ Compatibility](#compatibility)
- [↗️ Recommended Dependencies](#recommended-dependencies)
- [↗️ Installation](#installation)
- [↗️ Available Aliases](#available-aliases)
  - [File Listing (eza)](#file-listing-eza)
  - [Navigation](#navigation)
  - [System Cleanup (Fedora)](#system-cleanup-fedora)
  - [Colored Grep](#colored-grep)
- [↗️ Available Functions](#available-functions)
  - [Navigation & Files](#navigation--files)
  - [Git](#git)
  - [Utilities](#utilities)
- [↗️ Performance](#performance)
- [↗️ AI Usage](#ai-usage)

---

## Key Features

- ⚡ **Intelligent Plugin Caching**: Automatic cache management based on tool fingerprints
- 🚀 **Optimized Boot**: Startup time measurement and bytecode compilation
- 🛠️ **Productivity Aliases**: Shortcuts for common DNF, Flatpak, and navigation tasks
- 🔧 **Utility Functions**: Advanced functions for directory management, Git, and system operations
- 🎨 **Modern Theme**: Powerlevel10k with instant prompt support
- 🐧 **Fedora Focused**: Native integration with DNF and Flatpak package managers

---

## Compatibility

| Distribution | Support Level | Notes |
|--------------|---------------|-------|
| **Fedora** | 🟢 Primary | Full support for DNF and Flatpak |
| RHEL/CentOS | 🟡 Partial | Compatible with minor adjustments |
| Ubuntu/Debian | 🟡 Partial | Requires alias adaptation for APT |
| Arch/Manjaro | 🟡 Partial | Requires alias adaptation for Pacman |
| macOS | 🟠 Limited | Functional with Homebrew adjustments |

---

## Recommended Dependencies

Install the following packages for full functionality:

```bash
# Essential
sudo dnf install zsh git curl wget

# Enhanced file listing
sudo dnf install eza

# Fuzzy finder
sudo dnf install fzf

# Smart directory navigation
sudo dnf install zoxide

# Oh My Zsh framework
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Flatpak support (optional)
sudo dnf install flatpak
```

---

## Installation

1. **Clone or copy the configuration:**
   ```bash
   cp .zshrc ~/.zshrc
   ```

2. **Install dependencies** (see section above)

3. **Start Zsh:**
   ```bash
   zsh
   ```

4. **Configure Powerlevel10k:**
   Follow the wizard that appears on first launch

5. **Verify installation:**
   ```bash
   zshrc-time  # Check startup time
   ```

---

## Available Aliases

### File Listing (eza)

| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `eza` | Colorful file listing with icons |
| `ll` | `eza -lh` | Long format with human-readable sizes |
| `la` | `eza -lha` | Show all files including hidden |
| `l` | `eza -1` | One entry per line |
| `lt` | `eza -T` | Tree view of directories |

### Navigation

| Alias | Command | Description |
|-------|---------|-------------|
| `home` | `cd ~` | Go to home directory |
| `docs` | `cd ~/Documents` | Go to Documents folder |
| `up` | `cd ..` | Go up one level |
| `up2` | `cd ../..` | Go up two levels |
| `up3` | `cd ../../..` | Go up three levels |
| `up4` | `cd ../../../..` | Go up four levels |

### System Cleanup (Fedora)

| Alias | Command | Description |
|-------|---------|-------------|
| `dnf-clean` | `sudo dnf clean all` | Clean DNF cache |
| `flatpak-clean` | `flatpak uninstall --unused` | Remove unused Flatpak runtimes |
| `sys-clean` | Combined | Run both cleanup commands |

### Colored Grep

| Alias | Command | Description |
|-------|---------|-------------|
| `grep` | `grep --color=auto` | Colored grep output |
| `fgrep` | `fgrep --color=auto` | Fixed string grep |
| `egrep` | `egrep --color=auto` | Extended regex grep |

---

## Available Functions

### Navigation & Files

#### `dtop`
Navigate to Desktop directory.
```bash
dtop    # cd ~/Desktop
```

#### `mkcd`
Create directory and enter it in one command.
```bash
mkcd myproject    # mkdir -p myproject && cd myproject
```

#### `nf`
Create a new file and open it in the default editor.
```bash
nf script.sh    # Creates and opens script.sh
```

#### `extract`
Universal archive extractor supporting multiple formats.
```bash
extract archive.tar.gz
extract file.zip
extract file.7z
```

#### `bk`
Create timestamped backup of a file.
```bash
bk config.txt    # Creates config.txt.bak.20240115_143022
```

### Git

#### `gcom`
Quick commit with message.
```bash
gcom "Fix bug in login"    # git add . && git commit -m "Fix bug in login"
```

#### `lazyg`
Lazy Git workflow: status, add all, commit with message, push.
```bash
lazyg "Update README"    # Executes full Git workflow
```

### Utilities

#### `sudo` (`!!`)
Re-run last command with sudo.
```bash
apt update    # Permission denied
sudo          # Re-runs: sudo apt update
```

#### `sedi`
In-place sed edit with automatic backup.
```bash
sedi 's/old/new/g' file.txt    # Edits file with backup
```

#### `port`
Find process using a specific port.
```bash
port 8080    # Shows process using port 8080
```

#### `zshrc-time`
Measure Zsh startup time.
```bash
zshrc-time    # Displays boot time in milliseconds
```

---

## Performance

### Plugin Caching System

The configuration includes an intelligent caching mechanism:

- **Fingerprint-based**: Cache rebuilds only when tools change
- **Monitored Tools**: zsh, git, eza, fzf, zoxide
- **Automatic Rebuild**: Detects version changes automatically
- **Atomic Writes**: Prevents corruption during cache updates
- **Estimated Gain**: ~75ms faster startup on subsequent loads

### Boot Timer

Startup time is measured and displayed:
- First load: Baseline measurement
- Subsequent loads: Uses cached plugins for faster boot
- Command `zshrc-time`: Manual verification anytime

### Bytecode Compilation

Zsh functions are compiled to bytecode for improved performance:
```zsh
zcompile -U "$ZSH_CACHE_DIR/functions.zwc"
```

---

## AI Usage

This project was developed with AI assistance across multiple stages:

- **Code Generation**: Initial structure and function implementation
- **Refactoring**: Optimization and best practices application
- **Documentation**: Technical and user-facing documentation creation
- **Review**: Code quality and security analysis

AI was used as a productivity tool to enhance development speed and maintain high-quality standards while ensuring all code remains functional and well-documented.

---

## Quick Links

[← Back to Top](#zsh-config--fedora-optimized) | [📚 Technical Documentation →](docs-en.md)