#!/usr/bin/env bats

setup() {
  TEST_HOME=$(mktemp -d)
  export HOME="$TEST_HOME"
  export XDG_CACHE_HOME="$TEST_HOME/.cache"
  mkdir -p "$XDG_CACHE_HOME"
}

teardown() {
  rm -rf "$TEST_HOME"
}

@test 'install.sh passes bash syntax check' {
  run bash -n "$ZSH_PROFILE_ROOT/install.sh"

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test 'uninstall with no zsh_profile artifacts exits successfully' {
  run bash "$ZSH_PROFILE_ROOT/install.sh" --uninstall

  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing to remove"* ]]
}

@test 'uninstall removes symlinks and caches without premature exit' {
  ln -s "$ZSH_PROFILE_ROOT/.zshrc" "$HOME/.zshrc"
  ln -sf "$ZSH_PROFILE_ROOT/modules" "$HOME/.zsh_modules"
  touch "$HOME/.zshrc.zwc"
  touch "$XDG_CACHE_HOME/zsh_plugins_init.zsh"
  touch "$XDG_CACHE_HOME/zsh_plugins_init.zsh.zwc"
  touch "$XDG_CACHE_HOME/p10k-instant-prompt-${USER}.zsh"

  run bash "$ZSH_PROFILE_ROOT/install.sh" --uninstall

  [ "$status" -eq 0 ]
  [[ "$output" == *"Uninstall complete"* ]]
  [[ "$output" == *"~/.zshrc symlink removed"* ]]
  [[ "$output" == *"~/.zsh_modules symlink removed"* ]]

  run test -L "$HOME/.zshrc"
  [ "$status" -ne 0 ]
  run test -L "$HOME/.zsh_modules"
  [ "$status" -ne 0 ]
}

@test 'uninstall removes install state file if present' {
  state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh_profile"
  mkdir -p "$state_dir"
  printf 'installed_at=2024-01-01\n' > "$state_dir/install.state"

  ln -s "$ZSH_PROFILE_ROOT/.zshrc" "$HOME/.zshrc"

  run bash "$ZSH_PROFILE_ROOT/install.sh" --uninstall

  [ "$status" -eq 0 ]
  [[ "$output" == *"Uninstall complete"* ]]

  run test -f "$state_dir/install.state"
  [ "$status" -ne 0 ]
}