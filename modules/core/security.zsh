# ==============================================================================
# History Security Filter
# zshaddhistory hook: runs before every command is written to HISTFILE
# Returns 1 (non-zero) to block the command from being saved — silently omitted
#
# Patterns blocked (case-insensitive via ${1:u} uppercase expansion):
#   - Env var assignments:  TOKEN=abc, SECRET=xyz, PASSWORD=..., API_KEY=...
#   - URL-embedded tokens:  https://token:secret@host.com/path
#   - Flag-based credentials: --token <val>, --password <val>, -p <val>
#   - SSH key material:     ssh-keygen, /etc/ssh/, .ssh/id_*
#   - GPG operations:       gpg --passphrase, gpg --export-secret-key
#   - AWS credentials:      AWS_ACCESS_KEY, AWS_SECRET_KEY, aws configure
#   Also blocks commands exceeding 4096 chars (likely encoded payloads)
# ==============================================================================
zshaddhistory() {
  local cmd="$1"
  local upper="${cmd:u}"

  # Block excessively long commands (binary blobs, base64 payloads)
  [[ ${#cmd} -gt 4096 ]] && return 1

  # Block env var credential assignments (case-insensitive)
  [[ "$upper" =~ (TOKEN|SECRET|PASSWORD|PASSWD|API[[:space:]]*_?KEY|PRIVATE[[:space:]]*_?KEY|CREDENTIAL|AUTH[[:space:]]*_?TOKEN|ACCESS[[:space:]]*_?KEY|SECRET[[:space:]]*_?KEY)[[:space:]]*= ]] && return 1

  # Block URL-embedded credentials: http[s]://user:token@host
  [[ "$cmd" =~ https?://[^[:space:]]+:[^[:space:]]+@ ]] && return 1

  # Block flag-based credentials: --token <val>, --password <val>, -p <val>
  [[ "$cmd" =~ --(token|password|secret|api-key|access-key)[[:space:]]+[^[:space:]-] ]] && return 1
  [[ "$cmd" =~ (^|[[:space:]])-p[[:space:]]+[^[:space:]-] ]] && return 1

  # Block SSH key generation and GPG passphrase exposure
  [[ "$upper" =~ (SSH-KEYGEN|SSH-ADD[[:space:]]+.*\.SSH|/ETC/SSH/|~?/\.SSH/ID_) ]] && return 1
  [[ "$upper" =~ GPG.*(--PASSPHRASE|--EXPORT-SECRET) ]] && return 1

  # Block AWS CLI credential exposure
  [[ "$upper" =~ AWS[[:space:]]+(CONFIGURE|IAM.*CREATE.*KEY) ]] && return 1

  return 0
}

# ==============================================================================
# Sudo Wrapper — blocks dangerous root commands via pattern matching
#
# When invoked as `sudo !!`:
#   1. Retrieves the last command via `fc -ln -1` (fc = fix command history)
#   2. Checks against a blocklist of destructive patterns using regex
#   3. If blocked: prints error and returns 1 (non-zero exit)
#   4. If allowed: re-executes the last command via `command sudo zsh -c`
#
# Blocked patterns:
#   - sudo:       recursive sudo calls (prevent escalation confusion)
#   - rm -rf /:   wipe root filesystem
#   - mkfs:       format a device (destroys all data)
#   - dd of=:     direct disk writes (can corrupt partition tables)
#   - chmod -R 777 /: world-writable root directory
#
# For normal sudo usage (not `!!`): passes through directly to `command sudo`
# ==============================================================================
sudo() {
  if [[ "$1" == "!!" ]]; then
    local last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')

    # Blocklist: dangerous patterns that must never run as root
    if [[ "$last_cmd" =~ ^(sudo|rm[[:space:]]+-rf[[:space:]]+/|mkfs|dd[[:space:]]+of=|chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/) ]]; then
      printf 'Blocked by security: %s\n' "$last_cmd" >&2
      return 1
    fi

    printf 'Executing as root: %s\n' "$last_cmd"
    command sudo zsh -c "$last_cmd"
  else
    command sudo "$@"
  fi
}
