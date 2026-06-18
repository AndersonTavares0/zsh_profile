# ==============================================================================
# NVIDIA Helpers — Fedora/RPMFusion GPU diagnostics and CUDA opt-in setup
#
# Startup rule: never run nvidia-smi while sourcing this module. GPU queries stay
# on-demand so shell startup remains fast.
# ==============================================================================

if command -v nvidia-smi &>/dev/null; then
  alias nvidia-ver='nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null'
  alias nvidia-stat='nvidia-smi --query-gpu=timestamp,name,temperature.gpu,utilization.gpu,utilization.memory,power.draw,power.limit,memory.used,memory.total,pstate --format=csv 2>/dev/null'
  alias nvidia-quick='nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw --format=csv,noheader,nounits 2>/dev/null'
  alias nvidia-watch='watch -n2 nvidia-smi'
  alias nvidia-procs='nvidia-smi --query-compute-apps=pid,gpu_uuid,used_memory --format=csv 2>/dev/null'

  nvidia-temp() {
    nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null
  }

  nvidia-mem() {
    nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>/dev/null
  }

  nvidia-power() {
    nvidia-smi --query-gpu=power.draw,power.limit --format=csv,noheader 2>/dev/null
  }

  nvidia-clock() {
    nvidia-smi --query-gpu=clocks.current.graphics,clocks.current.memory,pstate --format=csv 2>/dev/null
  }

  nvidia-persistence() {
    case "$1" in
      on) sudo nvidia-smi -pm 1 ;;
      off) sudo nvidia-smi -pm 0 ;;
      "") nvidia-smi --query-gpu=persistence_mode --format=csv,noheader 2>/dev/null ;;
      *) printf 'Usage: nvidia-persistence [on|off]\n' >&2; return 1 ;;
    esac
  }

  nvidia-plimit() {
    [[ -z "$1" ]] && { printf 'Usage: nvidia-plimit <watts>\n' >&2; return 1; }
    sudo nvidia-smi -pl "$1"
  }
fi

# ==============================================================================
# Fedora/RPMFusion NVIDIA Package Helpers
# ==============================================================================
command -v rpm &>/dev/null && \
  alias nvidia-rpm='rpm -qa "*nvidia*" --queryformat "%{NAME} %{VERSION}-%{RELEASE}\n" | sort'

command -v lsmod &>/dev/null && \
  alias nvidia-kmod='lsmod | grep nvidia'

command -v dnf &>/dev/null && \
  alias nvidia-update-check='dnf check-update "*nvidia*" --refresh 2>/dev/null'

nvidia-akmods() {
  command -v akmods &>/dev/null || { printf 'akmods not found\n' >&2; return 1; }
  command -v dracut &>/dev/null || { printf 'dracut not found\n' >&2; return 1; }

  printf 'This rebuilds NVIDIA kernel modules and initramfs. Continue? [y/N] '
  read -r confirm
  [[ "$confirm" =~ ^[yY]$ ]] || { printf 'Aborted.\n'; return 1; }

  sudo akmods --force && sudo dracut --force
}

# ==============================================================================
# CUDA Environment — explicit opt-in to avoid global LD_LIBRARY_PATH side effects
# ==============================================================================
cuda-env() {
  [[ -d /usr/local/cuda ]] || {
    printf 'CUDA not found at /usr/local/cuda\n' >&2
    return 1
  }

  export PATH="/usr/local/cuda/bin${PATH:+:${PATH}}"

  if [[ -d /usr/local/cuda/lib64 ]]; then
    export LD_LIBRARY_PATH="/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
  fi

  if [[ -d /opt/nvidia/nsight-compute ]]; then
    export PATH="/opt/nvidia/nsight-compute${PATH:+:${PATH}}"
  fi

  if command -v nvcc &>/dev/null; then
    printf 'CUDA environment loaded: %s\n' "$(nvcc --version 2>/dev/null | tail -1)"
  else
    printf 'CUDA environment loaded\n'
  fi
}

cuda-use() {
  [[ -z "$1" ]] && { printf 'Usage: cuda-use <version>\n' >&2; return 1; }

  local cuda_path="/usr/local/cuda-$1"
  [[ -d "$cuda_path" ]] || {
    printf 'CUDA %s not found at %s\n' "$1" "$cuda_path" >&2
    printf 'Available versions:\n'
    ls -d /usr/local/cuda-* 2>/dev/null | sed 's|.*/cuda-||'
    return 1
  }

  path=(${path:#/usr/local/cuda*/bin})
  ld_library_path=(${ld_library_path:#/usr/local/cuda*/lib64})

  export PATH="$cuda_path/bin${PATH:+:${PATH}}"
  export LD_LIBRARY_PATH="$cuda_path/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"

  printf 'CUDA set to %s\n' "$1"
}

cuda-gcc13() {
  [[ -x /usr/bin/g++-13 ]] || {
    printf 'g++-13 not found. Install gcc13-c++.\n' >&2
    return 1
  }

  export NVCC_CCBIN='g++-13'
  printf 'NVCC_CCBIN=g++-13\n'
}
