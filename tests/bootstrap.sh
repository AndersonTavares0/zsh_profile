#!/usr/bin/env bash
set -euo pipefail

ZUNIT_VERSION="0.8.2"
ZUNIT_REVISION="bce183c39a3b51a3dd838835516a37222aad921f"
REVOLVER_VERSION="0.2.3"
REVOLVER_REVISION="13e7af7ee037b6db0a598a4e54242dd9c63a4c45"
BATS_VERSION="1.13.0"
BATS_REVISION="3bca150ec86275d6d9d5a4fd7d48ab8b6c6f3d87"

DEPS_ROOT="${ZSH_PROFILE_TEST_DEPS:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh-profile/test-deps}"

install_repo() {
  name="$1"
  version="$2"
  revision="$3"
  url="$4"
  destination="$DEPS_ROOT/$name-$version"

  if [[ -d "$destination/.git" ]] &&
     [[ "$(git -C "$destination" rev-parse HEAD 2>/dev/null)" = "$revision" ]]; then
    return 0
  fi

  if [[ -e "$destination" ]]; then
    printf 'Refusing to replace unexpected dependency path: %s\n' "$destination" >&2
    return 1
  fi

  printf 'Installing %s %s into %s\n' "$name" "$version" "$DEPS_ROOT"
  git clone --quiet "$url" "$destination"
  git -C "$destination" checkout --quiet --detach "$revision"
}

mkdir -p "$DEPS_ROOT"

install_repo revolver "$REVOLVER_VERSION" "$REVOLVER_REVISION" \
  "https://github.com/molovo/revolver.git"
install_repo zunit "$ZUNIT_VERSION" "$ZUNIT_REVISION" \
  "https://github.com/zunit-zsh/zunit.git"
install_repo bats-core "$BATS_VERSION" "$BATS_REVISION" \
  "https://github.com/bats-core/bats-core.git"

if [[ ! -x "$DEPS_ROOT/zunit-$ZUNIT_VERSION/zunit" ]]; then
  (
    cd "$DEPS_ROOT/zunit-$ZUNIT_VERSION"
    zsh ./build.zsh
    chmod u+x ./zunit
  )
fi

printf 'Test dependencies ready: ZUnit %s, Revolver %s, Bats %s\n' \
  "$ZUNIT_VERSION" "$REVOLVER_VERSION" "$BATS_VERSION"
