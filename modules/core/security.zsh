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

  # Block flag-based credentials: --token <val>, --password <val>, --secret <val>
  # Nota: -p <val> removido intencionalmente — ambíguo demais (ssh -p, ping -p, tar -p)
  # Causava falsos positivos em comandos legítimos comuns
  [[ "$cmd" =~ --(token|password|secret|api-key|access-key)[[:space:]]+[^[:space:]-] ]] && return 1

  # Block SSH key generation and GPG passphrase exposure
  [[ "$upper" =~ (SSH-KEYGEN|SSH-ADD[[:space:]]+.*\.SSH|/ETC/SSH/|~?/\.SSH/ID_) ]] && return 1
  [[ "$upper" =~ GPG.*(--PASSPHRASE|--EXPORT-SECRET) ]] && return 1

  # Block AWS CLI credential exposure
  [[ "$upper" =~ AWS[[:space:]]+(CONFIGURE|IAM.*CREATE.*KEY) ]] && return 1

  return 0
}

# ==============================================================================
# sudo-last — execute the last history command with sudo after confirmation
#
# Usage: sudo-last [--yes]
#   --yes: skip confirmation (useful in scripts, still checks blocklist)
#
# Flow:
#   1. Retrieves the last command via `fc -ln -1`
#   2. Checks against a blocklist of destructive patterns
#   3. If blocked: prints error and returns 1
#   4. Shows preview and asks for confirmation (unless --yes)
#   5. On confirm: executes via `command sudo zsh -c "<last_cmd>"`
#
# Blocked patterns:
#   - rm -rf /:   wipe root filesystem
#   - mkfs:       format a device
#   - dd of=:     direct disk writes
#   - chmod -R 777 /: world-writable root directory
# ==============================================================================
sudo-last() {
  local yes_mode=0
  [[ "$1" == "--yes" ]] && { yes_mode=1; shift; }

  local last_cmd=$(fc -ln -1 | sed 's/^[[:space:]]*//')

  [[ -z "$last_cmd" ]] && { printf 'No previous command in history.\n' >&2; return 1; }

  if [[ "$last_cmd" =~ ^(rm[[:space:]]+-rf[[:space:]]+/|mkfs|dd[[:space:]]+of=|chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/) ]]; then
    printf 'Blocked by security: %s\n' "$last_cmd" >&2
    return 1
  fi

  printf 'Last command: %s\n' "$last_cmd"

  if (( yes_mode )); then
    command sudo zsh -c "$last_cmd"
    return $?
  fi

  printf 'Confirm execution with sudo? [y/N] '
  local confirm
  read -r -t 10 confirm || { printf '\nTimeout — cancelled.\n' >&2; return 0; }

  if [[ "$confirm" =~ ^[yY]$ ]]; then
    command sudo zsh -c "$last_cmd"
  else
    printf 'Cancelled.\n'
  fi
}
