#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ZSH_PROFILE_ROOT="$ROOT_DIR"
DEPS_ROOT="${ZSH_PROFILE_TEST_DEPS:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh-profile/test-deps}"
ZUNIT_BIN="$DEPS_ROOT/zunit-0.8.2/zunit"
BATS_BIN="$DEPS_ROOT/bats-core-1.13.0/bin/bats"
REVOLVER_DIR="$DEPS_ROOT/revolver-0.2.3"

"$ROOT_DIR/tests/bootstrap.sh"

printf '%s\n' '==> Zsh syntax'
find "$ROOT_DIR" -type f \( -name '*.zsh' -o -name '.zshrc' \) -print |
  while IFS= read -r file; do
    zsh -n "$file"
  done

printf '%s\n' '==> Bash syntax'
find "$ROOT_DIR" -type f -name '*.sh' -print |
  while IFS= read -r file; do
    bash -n "$file"
  done

printf '%s\n' '==> ZUnit'
if find "$ROOT_DIR/tests/zsh" -type f -name '*.zunit' -print -quit 2>/dev/null | grep -q .; then
  PATH="$REVOLVER_DIR:$PATH" "$ZUNIT_BIN" --tap "$ROOT_DIR/tests/zsh"
else
  printf '%s\n' 'No ZUnit tests found.'
fi

printf '%s\n' '==> Bats'
if find "$ROOT_DIR/tests/install" -type f -name '*.bats' -print -quit 2>/dev/null | grep -q .; then
  "$BATS_BIN" "$ROOT_DIR/tests/install"
else
  printf '%s\n' 'No Bats tests found.'
fi
