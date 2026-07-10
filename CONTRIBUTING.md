# Contributing

Thanks for considering contributing to Zsh Profile. This guide covers the project conventions and workflow so you can get started quickly.

## Development Setup

Clone the repo and run the installer:

```bash
git clone https://github.com/AndersonTavares0/zsh_profile.git ~/.zsh_profile_repo
~/.zsh_profile_repo/install.sh --install
```

To test changes without reinstalling, make a symlink for rapid iteration:

```bash
ln -sf "$(pwd)/modules" ~/.zsh_modules
ln -sf "$(pwd)/.zshrc" ~/.zshrc
```

Then reload with `exec zsh` or `source ~/.zshrc`.

## Module Structure

The configuration has 15 source files across 4 layers, loaded in strict order:

| Layer | Directory | Purpose |
|-------|-----------|---------|
| Boot | `modules/boot/` | Startup chain: prompt, timer, theme, compile |
| Core | `modules/core/` | Shell foundation: paths, options, security |
| Plugins | `modules/plugins/` | Framework and plugin loading |
| Tools | `modules/tools/` | User-facing aliases, functions, NVIDIA helpers |

Load order is encoded in `.zshrc` (lines 26-48). Do not reorder source calls without understanding the dependency chain:

1. Powerlevel10k Instant Prompt must be the first I/O operation
2. Oh My Zsh must load after cache initialization
3. Theme must load after all plugins, aliases, and functions

## Coding Standards

- **Guard optional commands** with `command -v`. Never assume a tool is installed. Example:

  ```zsh
  if command -v eza &>/dev/null; then
    alias ls='eza --icons --group-directories-first'
  fi
  ```

- **Self-documenting code**: Explain why a pattern exists, not what the code does. The code already says what it does.

  ```zsh
  # Bad — states the obvious
  # Increment counter
  ((count++))

  # Good — explains the rationale
  # Increment only on the second pass to avoid a race with cache.zsh
  ```

- **Global variables**: Use `typeset -g` for cross-module globals. Use the `_` prefix for internal module variables.

- **Fail gracefully**: When a dependency is missing, skip functionality instead of erroring. Example: `prompt.zsh` checks if the instant-prompt file exists before sourcing it.

- **Avoid startup overhead**: Never run expensive commands during shell startup. Commands like `nvidia-smi`, `zoxide init`, and `fzf` key-bindings should be cached or deferred.

- **Use the atomic write pattern** for file operations (temp file, then `mv`):

  ```zsh
  tmp=$(mktemp) || return 1
  trap "rm -f '$tmp'" INT TERM
  # write content to tmp
  mv "$tmp" "$target"
  trap - INT TERM
  ```

## Naming Conventions

- Module files go in `modules/<layer>/<name>.zsh`
- Use lowercase letters and hyphens for filenames: `timer-start.zsh`, `zshrc-time`
- Aliases are lowercase: `dnf-clean`, `nvidia-ver`
- Functions use kebab-case: `sudo-last`, `cuda-env`, `nvidia-plimit`

## Git Workflow

1. Create a branch from `main` with a descriptive prefix:
   - `fix/` for bug fixes
   - `feat/` for new features
   - `docs/` for documentation changes
   - `test/` for test-only changes
   - `chore/` for tooling and maintenance

2. Keep commits focused on one concern. Use conventional commit format:

   ```
   <type>(<scope>): <description>
   
   Examples:
   feat(installer): add state tracking in XDG_STATE_HOME
   fix(shell): validate up argument as positive integer
   docs: update SECURITY.md with reporting process
   ```

3. Before opening a PR, rebase onto `main` and verify:

   ```bash
   git rebase main
   ./tests/run.sh
   zsh -n .zshrc
   ```

4. The PR template (`.github/pull_request_template.md`) has a checklist. Fill it out so reviewers can verify changes don't break startup order or performance.

## Testing

Run all local gates with one command:

```bash
./tests/run.sh
```

The harness checks Zsh and Bash syntax, then runs ZUnit (Zsh unit tests) and Bats (installer tests). It installs pinned test dependencies under `${XDG_CACHE_HOME:-$HOME/.cache}`.

Syntax checks alone (faster, no test dependencies):

```bash
find . -name '*.zsh' -o -name '.zshrc' | xargs zsh -n
find . -name '*.sh' | xargs bash -n
```

## Performance Rules

- Keep shell startup under 150ms. Run `zshrc-time` after your changes.
- Never add output before `boot/prompt.zsh` (breaks Powerlevel10k Instant Prompt).
- Cache expensive init output (`zoxide init`, fzf key-bindings) instead of running it on every shell start.
- Add new features as deferred or on-demand functions, not startup-time overhead.

## Security Checklist

Before submitting a PR, confirm:

- [ ] History filter patterns in `security.zsh` still cover all credential types
- [ ] `sudo-last` blocklist still matches destructive patterns
- [ ] No new secrets are exposed through the shell startup
- [ ] Local overrides (`~/.zshrc.local`) remain optional and machine-specific

## Questions

Open a GitHub issue for questions, bug reports, or feature requests. Every issue helps improve the project.
