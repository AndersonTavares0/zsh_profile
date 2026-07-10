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