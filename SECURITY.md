# Security

This project implements in-shell security measures to protect against accidental credential leaks and destructive commands.

## Scope

The following areas are covered by this project's security features:

- **History filter**: Blocks credential patterns from being saved to `HISTFILE`. This includes environment variable assignments (`TOKEN`, `SECRET`, `PASSWORD`, `API_KEY`, `PRIVATE_KEY`, `CREDENTIAL`, `AUTH_TOKEN`, `ACCESS_KEY`, `SECRET_KEY`), URL-embedded tokens, flag-based credentials (`--token`, `--password`, `--secret`, `--api-key`, `--access-key`), SSH key material, GPG passphrase commands, and AWS credential operations.
- **sudo-last guard**: Blocks destructive patterns (`rm -rf /`, `mkfs`, `dd of=`, `chmod -R 777 /`) and requires confirmation for every `sudo` execution.
- **History deduplication**: Zsh options `HIST_IGNORE_ALL_DUPS`, `HIST_SAVE_NO_DUPS`, `HIST_EXPIRE_DUPS_FIRST`, and `HIST_REDUCE_BLANKS` minimize sensitive command proliferation.

## Reporting a Vulnerability

This is a small open-source project. To report a security issue:

1. Open a GitHub issue with the `[security]` prefix in the title
2. Describe the pattern or exposure you found
3. Include relevant context (Zsh version, OS, affected file)

There is no private reporting channel or bug bounty. Issues are reviewed and tagged for the next release.

## Best Practices

- Store machine-specific secrets in `~/.zshrc.local` — this file is in `.gitignore` and never tracked
- Avoid pasting tokens or keys directly into the terminal. Use environment variables sourced from a restricted file
- Review blocked commands in `modules/core/security.zsh` if you see commands unexpectedly missing from history

## Supported Versions

Only the latest release (tagged on GitHub) receives security fixes. Always use the latest version.

| Version | Supported |
|---------|-----------|
| Latest release | Yes |
| Older releases | No |
