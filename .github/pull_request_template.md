## Summary

- 

## Changes

- [ ] Shell startup/order changed
- [ ] Module added or updated
- [ ] Alias/function behavior changed
- [ ] Installer changed
- [ ] Documentation updated

## Verification

- [ ] `zsh -n .zshrc`
- [ ] `zsh -n modules/boot/*.zsh modules/core/*.zsh modules/plugins/*.zsh modules/tools/*.zsh`
- [ ] `zsh -i -c 'zshrc-time'`
- [ ] Relevant aliases/functions tested manually

## Performance Notes

- Startup time before:
- Startup time after:
- Any command executed during shell startup:

## Fedora/NVIDIA Notes

- [ ] NVIDIA helpers do not execute `nvidia-smi` during startup
- [ ] CUDA setup remains opt-in/on-demand
- [ ] Fedora-specific commands are guarded with `command -v`
- [ ] Non-Fedora behavior considered

## Risk / Rollback

- Risk level: Low / Medium / High
- Rollback notes:
