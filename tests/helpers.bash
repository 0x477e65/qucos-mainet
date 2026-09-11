# shellcheck shell=bash
# shellcheck disable=SC2034   # constants below are used by the .bats files that load this helper
#
# Test helpers for quantus-miner.sh.
#
#  * qm_sandbox        — per-test sandbox: temp HOME, QM_DIR, QM_SYSTEMD_DIR, TMPDIR and a stub
#                        bin dir prepended to PATH (curl, ss, nvidia-smi, sudo, systemctl).
#  * qm_use_stub NAME  — add an optional stub (ps, python3, ldd) to that bin dir.
#  * qm_build_fixtures — (setup_file) fake release assets served by the fake curl: the node
#                        tarball, the miner binary and a real .deb with a fake libnvrtc.
#  * fake_* / qm_*     — control the fakes (RPC answers, GPU driver, crashes) and inspect state.
#
# Nothing here touches the network, the real quantus binaries, sudo or the user's real files:
# every path lives under the per-test sandbox, and the sudo stub refuses paths outside it.

QM_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# QM_TEST_SCRIPT lets you run the suite against another copy (e.g. a mutated one).
QM_SCRIPT="${QM_TEST_SCRIPT:-$(cd "$QM_TESTS_DIR/.." && pwd)/quantus-miner.sh}"
export QM_SCRIPT

# ---------------------------------------------------------------------------------------------
# Fake identities / real chain constants
# ---------------------------------------------------------------------------------------------
# Printed by the quantus-node stub in the exact v1.0.1 `key quantus --scheme wormhole` format.
FAKE_ADDRESS="qzaWPCLW9MEduyvh32Ynrzxp5AAwamVLjHNUHHFkE3bsJqyVb"
FAKE_INNER="0x75279943afd544644571f6f52b15c3cdaf10485b0e087cabb6a536ff56088691"
FAKE_PHRASE="abandon ability able about above absent absorb abstract absurd abuse access accident account accuse achieve acid acoustic acquire across act action actor actress actual"
# What the stub derives for any OTHER imported phrase.
IMPORT_ADDRESS="qzBX1Uz8WdvWAWHbWT4rR2qh7AFMfAkc8nDirDrvYxLnYJjtN"
IMPORT_INNER="0xb1e600c63e7eeb71c7c28f226fac48fb567c4989c0f58a0701bffb54e90959eb"
PAYOUT_ADDRESS_OK="qz4GSoksz5aJo6Q8VJ7vMcX2cW32vZSncBuNcfMtBjjD4WCpY"
FAKE_TLS_FP="5e1f0a3c9b7d2e4f6a8c0b1d3e5f7a9c2b4d6e8f0a1c3e5b7d9f1a2c4e6b8d0f"
MAINNET_GENESIS_HASH="0xfb5487c0be6ae4ade2d41d16e50465129861636c2b8d61fa94d7a19631626fba"
NURSERY_ADDR="162.19.84.16:2255"
NURSERY_FP="e21265920ae09417de61b68705e36357f697d17f8eadb2b04ba620019b291ffe"
QUANPOOL_ADDR="37.187.143.115:9834"
QUANPOOL_FP="87dc37af6096a3ddc860b94368ca087775f3ad3e0c4e9bcff3b07ea08d8abef6"

# Real SCALE answers from mainnet (2026-09-10): QPoWApi_get_difficulty at block 22922 is a U512
# (64 bytes little-endian) = 301898347444336; Balances.TotalIssuance is a u128 (16 bytes LE)
# = 5677021411617334441 planck (5,677,021.41 QTC).
DIFFICULTY_DEC=301898347444336
DIFFICULTY_HEX="0x70f8c12f931201000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
ISSUANCE_DEC=5677021411617334441
ISSUANCE_HEX="0xa9e4bc4de5d4c84e0000000000000000"

# Fixture file names = the official asset names (served only from https://fixtures.invalid/).
FIX_NODE_NAME="quantus-node-v1.0.1-x86_64-unknown-linux-gnu.tar.gz"
FIX_MINER_NAME="quantus-miner-linux-x86_64"
FIX_NVRTC_NAME="cuda-nvrtc-12-8_12.8.93-1_amd64.deb"
NVRTC_SUBDIR="usr/local/cuda-12.8/targets/x86_64-linux/lib"

# ---------------------------------------------------------------------------------------------
# Stub generators
# ---------------------------------------------------------------------------------------------
_qm_fill() {  # file — replace @PLACEHOLDERS@ with the constants above
  sed -i \
    -e "s|@FAKE_ADDRESS@|$FAKE_ADDRESS|g" -e "s|@FAKE_INNER@|$FAKE_INNER|g" \
    -e "s|@FAKE_PHRASE@|$FAKE_PHRASE|g" -e "s|@IMPORT_ADDRESS@|$IMPORT_ADDRESS|g" \
    -e "s|@IMPORT_INNER@|$IMPORT_INNER|g" -e "s|@FAKE_TLS_FP@|$FAKE_TLS_FP|g" "$1"
  chmod 755 "$1"
}

_qm_stub_node() {
  cat >"$1" <<'STUB'
#!/usr/bin/env bash
# Fake quantus-node 1.0.1 (test stub). State lives in $QM_FAKE; no network, no chain.
F=${QM_FAKE:?QM_FAKE is not set}
ADDR='@FAKE_ADDRESS@'; INNER='@FAKE_INNER@'; PHRASE='@FAKE_PHRASE@'
IADDR='@IMPORT_ADDRESS@'; IINNER='@IMPORT_INNER@'
printf '%s\n' "$*" >>"$F/node.calls"
if [[ ${1:-} == --version && -f $F/node.version ]]; then cat "$F/node.version"; exit 0; fi
case ${1:-} in
  --version|-V) echo "quantus-node 1.0.1-f1176cea6a6"; exit 0 ;;
  --help|-h)
    echo "Usage: quantus-node [OPTIONS] [COMMAND]"
    echo "      --validator"
    echo "      --rewards-inner-hash <REWARDS_INNER_HASH>"
    echo "      --miner-listen-port <MINER_LISTEN_PORT>"
    [[ -f $F/node.help_old ]] || echo "      --miner-auth-token-file <PATH>"
    exit 0 ;;
  key)
    sub=${2:-}; shift 2
    case $sub in
      generate-node-key)
        file=""
        while (( $# )); do if [[ $1 == --file ]]; then file=$2; shift; fi; shift; done
        key=$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')
        if [[ -n $file ]]; then printf '%s' "$key" >"$file"; else printf '%s\n' "$key"; fi
        echo "12D3KooWStubPeerIdForTests" >&2
        exit 0 ;;
      quantus)
        scheme=standard words=0 verbose=0
        while (( $# )); do
          case $1 in --scheme) scheme=$2; shift ;; --words) words=1 ;; -v|--verbose) verbose=1 ;; esac
          shift
        done
        [[ $scheme == wormhole ]] || { echo "stub: only --scheme wormhole is emulated" >&2; exit 2; }
        addr=$ADDR inner=$INNER secret=$PHRASE
        if (( words )); then
          IFS= read -r given || true
          n=$(wc -w <<<"$given")
          if (( n != 24 && n != 12 )); then echo "Error deriving wormhole from mnemonic: InvalidWordCount" >&2; exit 1; fi
          secret=""
          if [[ $given != "$PHRASE" ]]; then addr=$IADDR inner=$IINNER; fi
        fi
        echo "Deriving wormhole HD path: m/44'/189189189'/0'/0'/0'"
        echo "Generating wormhole address..."
        echo "XXXXXXXXXXXXXXX Quantus Wormhole Details XXXXXXXXXXXXXXXXX"
        if [[ -n $secret ]]; then echo "Secret phrase: $secret"; fi
        echo "Account index: 0"
        echo "Derivation path: m/44'/189189189'/0'/0'/0'"
        echo "Address: $addr"
        echo "Inner Hash: $inner"
        if (( verbose )); then echo "Address hex: 0x$(printf '%064d' 7)"; fi
        echo "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
        exit 0 ;;
      *) echo "stub: unsupported key subcommand '$sub'" >&2; exit 2 ;;
    esac ;;
esac
# ---------------- run as a node ----------------
printf '%s\n' "$@" >"$F/node.argv"
date +%s >>"$F/node.starts"
base="" inner_arg=""
while (( $# )); do
  case $1 in --base-path) base=$2; shift ;; --rewards-inner-hash) inner_arg=$2; shift ;; esac
  shift
done
if [[ -f $F/node.exit_code ]]; then echo "Error: simulated node failure"; exit "$(cat "$F/node.exit_code")"; fi
if [[ -f $F/node.bad_hash ]]; then echo "Error: --rewards-inner-hash is not a canonical Poseidon digest."; exit 1; fi
[[ -n $base ]] || { echo "Error: stub needs --base-path"; exit 2; }
chain="$base/chains/mainnet"
mkdir -p "$chain"
if [[ ! -f $F/node.no_token ]]; then   # the real node reuses both files across restarts
  [[ -s $chain/miner-auth-token ]] || { od -An -N24 -tx1 /dev/urandom | tr -d ' \n'; echo; } >"$chain/miner-auth-token"
  [[ -s $chain/miner-tls-cert-sha256 ]] || printf '%s' '@FAKE_TLS_FP@' >"$chain/miner-tls-cert-sha256"
fi
rewards=$IADDR; [[ $inner_arg == "$INNER" ]] && rewards=$ADDR
echo "2026-09-10 21:30:00 ⛏️ Rewards wormhole address: $rewards"
echo "2026-09-10 21:30:00 ⛏️ Miner TLS cert SHA-256: @FAKE_TLS_FP@"
child=""
trap 'echo "stub-node: TERM received, clean shutdown"; rm -f "$F/rpc/local/UP"; [[ -z $child ]] || kill "$child" 2>/dev/null; exit 0' TERM INT
echo "$$" >"$F/rpc/local/UP"   # the fake curl answers local RPC only while this process lives
while :; do sleep 1 & child=$!; wait "$child"; done
STUB
  _qm_fill "$1"
}

_qm_stub_miner() {
  cat >"$1" <<'STUB'
#!/usr/bin/env bash
# Fake quantus-miner 4.2.0 (test stub). Records argv/env/nice into $QM_FAKE.
F=${QM_FAKE:?QM_FAKE is not set}
printf '%s\n' "$*" >>"$F/miner.calls"
if [[ ${1:-} == --version && -f $F/miner.version ]]; then cat "$F/miner.version"; exit 0; fi
case ${1:-} in
  --version|-V) echo "miner-cli 4.2.0"; exit 0 ;;
  ""|--help|-h|help) printf '%s\n' "CLI binary to run the Quantus External Miner service" "" "Usage: quantus-miner-linux-x86_64 [COMMAND]"; exit 0 ;;
esac
cmd=$1; shift
if [[ ${1:-} == --help ]]; then
  echo "Usage: quantus-miner-linux-x86_64 $cmd [OPTIONS]"
  echo "      --node-addr <NODE_ADDR>  [env: MINER_NODE_ADDR=] [default: 127.0.0.1:9833]"
  echo "      --auth-token <AUTH_TOKEN>  [env: MINER_AUTH_TOKEN=]"
  if [[ ! -f $F/miner.help_old ]]; then
    echo "      --auth-token-file <AUTH_TOKEN_FILE>  [env: MINER_AUTH_TOKEN_FILE=]"
    echo "      --tls-cert-sha256-file <TLS_CERT_SHA256_FILE>  [env: MINER_TLS_CERT_SHA256_FILE=]"
  fi
  echo "      --tls-cert-sha256 <TLS_CERT_SHA256>  [env: MINER_TLS_CERT_SHA256=]"
  echo "      --cpu-workers <CPU_WORKERS>  [env: MINER_CPU_WORKERS=]"
  echo "      --gpu-devices <GPU_DEVICES>  [env: MINER_GPU_DEVICES=]"
  echo "      --metrics-port <METRICS_PORT>  [env: MINER_METRICS_PORT=] [default: 9900]"
  echo "      --cuda-gpu  Use the native CUDA engine instead of wgpu/Vulkan (NVIDIA only) [env: MINER_CUDA_GPU=]"
  exit 0
fi
# clap reads MINER_* variables; a bool flag set to '1' is rejected by the real v4.2.0 miner.
if [[ -n ${MINER_CUDA_GPU+x} && $MINER_CUDA_GPU != true && $MINER_CUDA_GPU != false ]]; then
  echo "error: invalid value '$MINER_CUDA_GPU' for '--cuda-gpu'" >&2; exit 2
fi
case $cmd in
  serve)
    printf '%s\n' "$cmd" "$@" >"$F/miner.argv.tmp" && mv -f "$F/miner.argv.tmp" "$F/miner.argv"
    env | LC_ALL=C sort >"$F/miner.env"
    nice >"$F/miner.nice"
    date +%s >>"$F/miner.starts"
    if [[ -f $F/miner.exit_code ]]; then echo "Error: simulated miner failure"; exit "$(cat "$F/miner.exit_code")"; fi
    while (( $# )); do
      case $1 in
        --auth-token-file|--tls-cert-sha256-file) [[ -s $2 ]] || { echo "Error: failed to read $2"; exit 1; }; shift ;;
      esac
      shift
    done
    child=""
    trap 'echo "stub-miner: TERM received, clean shutdown"; rm -f "$F/miner.running"; [[ -z $child ]] || kill "$child" 2>/dev/null; exit 0' TERM INT
    echo "$$" >"$F/miner.running"
    echo "stub-miner: mining"
    while :; do sleep 1 & child=$!; wait "$child"; done ;;
  benchmark)
    printf '%s\n' "$cmd" "$@" >"$F/bench.argv"
    env | LC_ALL=C sort >"$F/bench.env"
    cuda=0
    for a in "$@"; do [[ $a == --cuda-gpu ]] && cuda=1; done
    if (( cuda )); then
      found=0
      IFS=: read -r -a dirs <<<"${LD_LIBRARY_PATH:-}"
      for d in "${dirs[@]}"; do [[ -n $d && ( -e $d/libnvrtc.so || -e $d/libnvrtc.so.12 ) ]] && found=1; done
      (( found )) || exit 134       # the real miner aborts silently when NVRTC cannot be loaded
      if [[ -f $F/cuda.fail ]]; then echo "CUDA error: CUDA_ERROR_UNSUPPORTED_PTX_VERSION" >&2; exit 1; fi
    fi
    printf '%s\n' "🚀 Quantus Miner Benchmark" "==========================" "⛏️  Starting benchmark..." "" \
      "📊 Benchmark Results" "===================" "Total time: 5.00s" "Total hashes: 4092600000" \
      "Average rate: 818.52M H/s" "✅ Benchmark completed!"
    exit 0 ;;
  *) echo "error: unrecognized subcommand '$cmd'" >&2; exit 2 ;;
esac
STUB
  _qm_fill "$1"
}

_qm_stub_curl() {
  cat >"$1" <<'STUB'
#!/usr/bin/env bash
# Fake curl: canned downloads, JSON-RPC, indexer and metrics answers from $QM_FAKE. No network.
F=${QM_FAKE:?QM_FAKE is not set}
export LC_ALL=C
{ printf 'curl'; printf ' %q' "$@"; printf '\n'; } >>"$F/curl.log"
out="" data="" url="" head=0
while (( $# )); do
  case $1 in
    -o|--output) out=$2; shift ;;
    -d|--data|--data-raw|--data-binary) data=$2; shift ;;
    -H|--header|-m|--max-time|--retry|--retry-delay|--connect-timeout|-A|--user-agent) shift ;;
    --head) head=1 ;;
    --*) ;;
    -*) [[ $1 == *I* ]] && head=1 ;;
    *) url=$1 ;;
  esac
  shift
done
no_conn() { echo "curl: (7) Failed to connect to server" >&2; exit 7; }
if [[ -n ${QM_LOCAL_RPC:-} && $url == "$QM_LOCAL_RPC" ]] || [[ -n ${QM_PUBLIC_RPC:-} && $url == "$QM_PUBLIC_RPC" ]]; then
  if (( head )); then
    off=$(cat "$F/clock_offset" 2>/dev/null || echo 0)
    printf 'HTTP/2 405\r\ndate: %s\r\ncontent-length: 0\r\n\r\n' \
      "$(date -u -d "@$(( $(date +%s) + off ))" '+%a, %d %b %Y %H:%M:%S GMT')"
    exit 0
  fi
  target=public
  if [[ $url == "${QM_PUBLIC_RPC:-}" && -f $F/rpc/public/DOWN ]]; then no_conn; fi
  if [[ $url == "${QM_LOCAL_RPC:-}" ]]; then
    target=local
    up=$(cat "$F/rpc/local/UP" 2>/dev/null)
    if [[ ! -f $F/rpc/local/FORCE_UP ]] && ! { [[ -n $up ]] && kill -0 "$up" 2>/dev/null; }; then no_conn; fi
  fi
  method=$(sed -n 's/.*"method":"\([^"]*\)".*/\1/p' <<<"$data")
  if [[ -n $method && -f $F/rpc/$target/$method ]]; then cat "$F/rpc/$target/$method"
  else echo '{"jsonrpc":"2.0","id":1,"error":{"code":-32601,"message":"Method not found"}}'; fi
  exit 0
fi
if [[ -n ${QM_INDEXER:-} && $url == "$QM_INDEXER" ]]; then
  case $data in
    *account_stats_by_pk*) cat "$F/indexer/account_stats" 2>/dev/null ;;
    *'block('*) cat "$F/indexer/blocks" 2>/dev/null ;;
    *) echo '{"errors":[{"message":"stub: unknown query"}]}' ;;
  esac
  exit 0
fi
case $url in
  http://127.0.0.1:*/metrics)
    [[ -f $F/metrics ]] || no_conn
    cat "$F/metrics"; exit 0 ;;
  https://fixtures.invalid/*)
    src="${QM_FIXTURES:-/nonexistent}/dl/${url##*/}"
    if [[ -f $src ]]; then
      if [[ -n $out ]]; then cat "$src" >"$out"; else cat "$src"; fi
      exit 0
    fi
    echo "curl: (22) The requested URL returned error: 404" >&2
    exit 22 ;;
esac
echo "$url" >>"$F/curl.unexpected"
echo "curl: (6) Could not resolve host (test sandbox has no network)" >&2
exit 6
STUB
  chmod 755 "$1"
}

_qm_stub_nvidia_smi() {
  cat >"$1" <<'STUB'
#!/usr/bin/env bash
# Fake nvidia-smi: a GPU exists only when $QM_FAKE/gpu.driver holds a driver version.
F=${QM_FAKE:?QM_FAKE is not set}
printf '%s\n' "$*" >>"$F/nvidia-smi.log"
if [[ ! -s $F/gpu.driver ]]; then
  echo "NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver."
  exit 9
fi
case "$*" in
  -L) echo "GPU 0: NVIDIA GeForce RTX 4090 (UUID: GPU-5e1f0a3c-9b7d-2e4f-6a8c-0b1d3e5f7a9c)" ;;
  *query-gpu=driver_version*) cat "$F/gpu.driver" ;;
  *query-gpu=name*) echo "NVIDIA GeForce RTX 4090" ;;
  *query-gpu=power.min_limit,power.max_limit*) echo "150.00, 600.00" ;;
  "-pm 1") echo "Enabled persistence mode for GPU 00000000:01:00.0." ;;
  -pl\ *) echo "Power limit for GPU 00000000:01:00.0 was set to ${2}.00 W from 450.00 W." ;;
  *) echo "nvidia-smi stub: unsupported arguments: $*" >&2; exit 2 ;;
esac
STUB
  chmod 755 "$1"
}

_qm_stub_sudo() {
  cat >"$1" <<'STUB'
#!/usr/bin/env bash
# Fake sudo: logs and runs the command unprivileged; refuses absolute paths outside the sandbox.
F=${QM_FAKE:?QM_FAKE is not set}
printf '%s\n' "$*" >>"$F/sudo.log"
if [[ -f $F/sudo.fail ]]; then echo "sudo: a password is required" >&2; exit 1; fi
for a in "$@"; do
  if [[ $a == /* && $a != "${QM_SANDBOX:?}"/* ]]; then
    echo "sudo stub: refusing path outside the test sandbox: $a" >&2; exit 97
  fi
done
exec "$@"
STUB
  chmod 755 "$1"
}

_qm_stub_systemctl() {
  cat >"$1" <<'STUB'
#!/usr/bin/env bash
# Fake systemctl: logs calls; the unit is "active" while $QM_FAKE/service.active exists.
F=${QM_FAKE:?QM_FAKE is not set}
printf '%s\n' "$*" >>"$F/systemctl.log"
case ${1:-} in
  is-active)
    q=0; [[ ${2:-} == --quiet ]] && q=1
    if [[ -f $F/service.active ]]; then (( q )) || echo active; exit 0; fi
    (( q )) || echo inactive; exit 3 ;;
  start|restart) touch "$F/service.active" ;;
  stop) rm -f "$F/service.active" ;;
  enable) [[ ${2:-} == --now ]] && touch "$F/service.active" ;;
  disable) [[ ${2:-} == --now ]] && rm -f "$F/service.active" ;;
  daemon-reload|status) ;;
  *) echo "systemctl stub: unsupported: $*" >&2; exit 1 ;;
esac
exit 0
STUB
  chmod 755 "$1"
}

_qm_stub_ss() {
  cat >"$1" <<'STUB'
#!/usr/bin/env bash
# Fake ss: a port is "busy" when "$proto $port" is listed in $QM_FAKE/busy_ports.
F=${QM_FAKE:?QM_FAKE is not set}
proto=tcp port=""
for a in "$@"; do
  [[ $a == -*u* ]] && proto=udp
  [[ $a =~ :([0-9]+)$ ]] && port=${BASH_REMATCH[1]}
done
if [[ -n $port ]] && grep -qx "$proto $port" "$F/busy_ports" 2>/dev/null; then
  echo "LISTEN 0 4096 127.0.0.1:$port 0.0.0.0:*"
fi
exit 0
STUB
  chmod 755 "$1"
}

_qm_stub_ps() {
  cat >"$1" <<'STUB'
#!/usr/bin/env bash
# Fake ps: answers `ps -p 1 -o comm=` from $QM_FAKE/pid1_comm (default systemd), else real ps.
F=${QM_FAKE:?QM_FAKE is not set}
if [[ "$*" == "-p 1 -o comm=" ]]; then cat "$F/pid1_comm" 2>/dev/null || echo systemd; exit 0; fi
for p in /usr/bin/ps /bin/ps; do [[ -x $p ]] && exec "$p" "$@"; done
exit 1
STUB
  chmod 755 "$1"
}

_qm_stub_python3() {
  cat >"$1" <<'STUB'
#!/usr/bin/env bash
# Fake python3 for nvrtc_version(): emulates ctypes.CDLL name lookup over LD_LIBRARY_PATH and
# prints the version stored in the fake library file (FAKE_NVRTC_VERSION=x.y).
cat >/dev/null
IFS=: read -r -a dirs <<<"${LD_LIBRARY_PATH:-}"
for name in libnvrtc.so libnvrtc.so.12 libnvrtc.so.11; do
  for d in "${dirs[@]}"; do
    [[ -n $d && -e $d/$name ]] || continue
    v=$(sed -n 's/^FAKE_NVRTC_VERSION=//p' "$d/$name")
    if [[ -n $v ]]; then echo "$v"; exit 0; fi
  done
done
exit 1
STUB
  chmod 755 "$1"
}

_qm_stub_ldd() {
  cat >"$1" <<'STUB'
#!/usr/bin/env bash
# Fake ldd --version: reports the glibc version stored in $QM_FAKE/glibc (e.g. 2.35 = Ubuntu 22.04).
v=$(cat "${QM_FAKE:?}/glibc" 2>/dev/null || echo 2.39)
echo "ldd (Ubuntu GLIBC ${v}-0ubuntu3.8) ${v}"
STUB
  chmod 755 "$1"
}

_qm_stub_dpkg_deb() {  # only used when the host has no real dpkg-deb: the "deb" is a tar.gz
  cat >"$1" <<'STUB'
#!/usr/bin/env bash
[[ ${1:-} == -x ]] || { echo "dpkg-deb stub: only -x is supported" >&2; exit 2; }
mkdir -p "$3" && tar -xzf "$2" -C "$3"
STUB
  chmod 755 "$1"
}

qm_write_stubs() {  # dir
  mkdir -p "$1"
  _qm_stub_node "$1/quantus-node"
  _qm_stub_miner "$1/quantus-miner"
  _qm_stub_curl "$1/curl"
  _qm_stub_nvidia_smi "$1/nvidia-smi"
  _qm_stub_sudo "$1/sudo"
  _qm_stub_systemctl "$1/systemctl"
  _qm_stub_ss "$1/ss"
  _qm_stub_ps "$1/ps"
  _qm_stub_python3 "$1/python3"
  _qm_stub_dpkg_deb "$1/dpkg-deb"
  _qm_stub_ldd "$1/ldd"
}

# ---------------------------------------------------------------------------------------------
# Fixtures (release assets). Call from setup_file; exports QM_FIXTURES and FIX_*_SHA256.
# ---------------------------------------------------------------------------------------------
qm_build_fixtures() {
  QM_FIXTURES="${BATS_FILE_TMPDIR:?}/fixtures"
  local stubs="$QM_FIXTURES/stubs" dl="$QM_FIXTURES/dl" work="$QM_FIXTURES/work"
  mkdir -p "$dl" "$work/tar" "$work/pkg/DEBIAN" "$work/pkg/$NVRTC_SUBDIR"
  qm_write_stubs "$stubs"
  # Node release: a tarball with the single file `quantus-node` at the archive root.
  cp "$stubs/quantus-node" "$work/tar/quantus-node"
  tar -czf "$dl/$FIX_NODE_NAME" -C "$work/tar" quantus-node
  # Miner release: the bare binary.
  cp "$stubs/quantus-miner" "$dl/$FIX_MINER_NAME"
  # NVRTC 12.8 .deb with the same layout as NVIDIA's package (lib + lib64 symlink).
  printf 'FAKE_NVRTC_VERSION=12.8\n' >"$work/pkg/$NVRTC_SUBDIR/libnvrtc.so.12"
  printf 'fake builtins\n' >"$work/pkg/$NVRTC_SUBDIR/libnvrtc-builtins.so.12.8"
  ln -s targets/x86_64-linux/lib "$work/pkg/usr/local/cuda-12.8/lib64"
  printf '%s\n' "Package: cuda-nvrtc-12-8" "Version: 12.8.93-1" "Architecture: amd64" \
    "Maintainer: tests <tests@fixtures.invalid>" "Description: fake NVRTC for quantus-miner.sh tests" \
    >"$work/pkg/DEBIAN/control"
  if command -v dpkg-deb >/dev/null 2>&1; then
    dpkg-deb --root-owner-group -Zgzip --build "$work/pkg" "$dl/$FIX_NVRTC_NAME" >/dev/null
    QM_FAKE_DPKG=0
  else
    tar -czf "$dl/$FIX_NVRTC_NAME" -C "$work/pkg" usr
    QM_FAKE_DPKG=1
  fi
  FIX_NODE_SHA256=$(sha256sum "$dl/$FIX_NODE_NAME" | awk '{print $1}')
  FIX_MINER_SHA256=$(sha256sum "$dl/$FIX_MINER_NAME" | awk '{print $1}')
  FIX_NVRTC_SHA256=$(sha256sum "$dl/$FIX_NVRTC_NAME" | awk '{print $1}')
  export QM_FIXTURES QM_FAKE_DPKG FIX_NODE_SHA256 FIX_MINER_SHA256 FIX_NVRTC_SHA256
}

# ---------------------------------------------------------------------------------------------
# Sandbox
# ---------------------------------------------------------------------------------------------
qm_sandbox() {
  QM_SANDBOX="${BATS_TEST_TMPDIR:?}/sb"
  export QM_SANDBOX
  export HOME="$QM_SANDBOX/home" QM_DIR="$QM_SANDBOX/kit" QM_SYSTEMD_DIR="$QM_SANDBOX/systemd"
  export QM_FAKE="$QM_SANDBOX/fake" TMPDIR="$QM_SANDBOX/tmp"
  QM_STUBS="$QM_SANDBOX/stubs"; QM_STUB_BIN="$QM_SANDBOX/bin"
  mkdir -p "$HOME" "$QM_SYSTEMD_DIR" "$TMPDIR" "$QM_FAKE/rpc/local" "$QM_FAKE/rpc/public" \
           "$QM_FAKE/indexer" "$QM_STUB_BIN"
  qm_write_stubs "$QM_STUBS"
  local s
  for s in curl ss nvidia-smi sudo systemctl; do ln -sf "$QM_STUBS/$s" "$QM_STUB_BIN/$s"; done
  if [[ ${QM_FAKE_DPKG:-0} == 1 ]]; then ln -sf "$QM_STUBS/dpkg-deb" "$QM_STUB_BIN/dpkg-deb"; fi
  case ":$PATH:" in *":$QM_STUB_BIN:"*) ;; *) export PATH="$QM_STUB_BIN:$PATH" ;; esac

  export QM_TICK=1 QM_RESTART_DELAY=1
  export QM_QUIZ_POSITIONS="1 2 3"   # the new-phrase check asks for words 1, 2, 3 (not random)
  export QM_LOCAL_RPC="http://127.0.0.1:59944"
  export QM_PUBLIC_RPC="https://rpc.fixtures.invalid"
  export QM_INDEXER="https://indexer.fixtures.invalid/v1/graphql"
  export QM_NODE_URL="https://fixtures.invalid/$FIX_NODE_NAME" QM_NODE_SHA256="${FIX_NODE_SHA256:-unset}"
  export QM_MINER_URL="https://fixtures.invalid/$FIX_MINER_NAME" QM_MINER_SHA256="${FIX_MINER_SHA256:-unset}"
  export QM_NVRTC_URL="https://fixtures.invalid/$FIX_NVRTC_NAME" QM_NVRTC_SHA256="${FIX_NVRTC_SHA256:-unset}"
  unset QM_NODE_VERSION_MATCH QM_MINER_VERSION_MATCH LD_LIBRARY_PATH
  local v
  for v in $(compgen -e | grep '^MINER_' || true); do unset "$v"; done

  # Default world: the node is syncing, chain is mainnet, indexer knows 3 mined blocks.
  fake_node_syncing
  fake_rpc local chain_getBlockHash "\"$MAINNET_GENESIS_HASH\""
  fake_rpc public chain_getBlockHash "\"$MAINNET_GENESIS_HASH\""
  fake_rpc local chain_getHeader '{"parentHash":"0x0a","number":"0x59d8","stateRoot":"0x0b","extrinsicsRoot":"0x0c","digest":{"logs":[]}}'
  fake_rpc public chain_getHeader '{"parentHash":"0x0a","number":"0x59d9","stateRoot":"0x0b","extrinsicsRoot":"0x0c","digest":{"logs":[]}}'
  fake_rpc public state_call "\"$DIFFICULTY_HEX\""
  fake_rpc local state_call "\"$DIFFICULTY_HEX\""
  fake_rpc public state_getStorage "\"$ISSUANCE_HEX\""
  fake_rpc local state_getStorage "\"$ISSUANCE_HEX\""
  printf '%s\n' '{"data":{"s":{"total_mined_blocks":3}}}' >"$QM_FAKE/indexer/account_stats"
  printf '%s\n' '{"data":{"a":[{"height":23300,"timestamp":"2026-09-10T21:30:00.807+00:00"}],"b":[{"height":23000,"timestamp":"2026-09-10T20:21:30.807+00:00"}]}}' >"$QM_FAKE/indexer/blocks"
}

qm_use_stub() {  # name… — put optional stubs (ps, python3, ldd) on PATH for this test
  local s
  for s in "$@"; do ln -sf "$QM_STUBS/$s" "$QM_STUB_BIN/$s"; done
}

# Source the script for unit tests (main does not run when sourced). The script's top-level
# `declare -A CLI_SET=()` becomes function-local when sourced from inside a function, so the
# global associative array is re-created here.
qm_source() {
  # shellcheck source=SCRIPTDIR/../quantus-miner.sh
  source "$QM_SCRIPT"
  declare -gA CLI_SET=()
  set_paths
}

# Run the script as a separate process, like a user would. fds 3/4 (bats' own pipes) are closed
# so the daemonised supervisor cannot keep bats waiting; stdin is not a terminal.
qm() {
  timeout --kill-after=5 "${QM_CMD_TIMEOUT:-90}" bash "$QM_SCRIPT" "$@" </dev/null 3>&- 4>&-
}

# Same, but inside a pseudo-terminal (util-linux `script`), typing INPUT — for the questions
# that must never be answered from a pipe or shown in a log (the 24-word phrase).
qm_tty() {  # input args…
  local input=$1 cmd
  shift
  printf -v cmd '%q ' bash "$QM_SCRIPT" "$@"
  printf '%s' "$input" | TERM=xterm-256color timeout --kill-after=5 "${QM_CMD_TIMEOUT:-90}" \
    script -qec "$cmd" /dev/null 3>&- 4>&-
}
NEW_KEY_ANSWERS=$'ZAPISAŁEM\nabandon\nability\nable\n'   # confirmation + words 1, 2, 3 of FAKE_PHRASE

# ---------------------------------------------------------------------------------------------
# Fake-world controls
# ---------------------------------------------------------------------------------------------
fake_rpc() {  # local|public method result-json — atomic, so a polling supervisor never sees half a file
  local d="$QM_FAKE/rpc/$1"
  mkdir -p "$d"
  printf '{"jsonrpc":"2.0","result":%s,"id":1}\n' "$3" >"$d/.$2.tmp"
  mv -f "$d/.$2.tmp" "$d/$2"
}
fake_node_syncing() {
  fake_rpc local system_health '{"peers":5,"isSyncing":true,"shouldHavePeers":true}'
  fake_rpc local system_syncState '{"startingBlock":0,"currentBlock":1200,"highestBlock":23001}'
}
fake_node_synced() {
  fake_rpc local system_syncState '{"startingBlock":0,"currentBlock":23000,"highestBlock":23001}'
  fake_rpc local system_health '{"peers":8,"isSyncing":false,"shouldHavePeers":true}'
}
fake_gpu() {  # driver-version — makes nvidia-smi report an RTX 4090 with that driver
  printf '%s\n' "$1" >"$QM_FAKE/gpu.driver"
}
fake_metrics() {  # hash rate (H/s) served on the miner's Prometheus endpoint
  printf '%s\n' "# HELP miner_hash_rate Total hash rate in hashes per second" \
    "# TYPE miner_hash_rate gauge" "miner_hash_rate $1" >"$QM_FAKE/metrics"
}

# ---------------------------------------------------------------------------------------------
# Process inspection / cleanup
# ---------------------------------------------------------------------------------------------
qm_alive() {  # pid — running and not a zombie
  local s
  [[ ${1:-} =~ ^[0-9]+$ ]] || return 1
  s=$(cat "/proc/$1/stat" 2>/dev/null) || return 1
  s=${s##*) }
  [[ ${s:0:1} != Z ]]
}
qm_pgid() {  # pid → process group id
  local s f
  s=$(cat "/proc/$1/stat" 2>/dev/null) || return 1
  s=${s##*) }
  read -r -a f <<<"$s"
  echo "${f[2]}"
}
qm_regex_escape() { printf '%s' "$1" | sed -E 's/[][\.*^$+?(){}|]/\\&/g'; }
qm_sandbox_pids() {  # every live process whose command line mentions this test's QM_DIR
  local p
  while read -r p; do qm_alive "$p" && echo "$p"; done < <(pgrep -f -- "$(qm_regex_escape "$QM_DIR")" || true)
}
qm_no_sandbox_procs() { [[ -z $(qm_sandbox_pids) ]]; }
qm_show_procs() {  # debugging aid for failed assertions
  local p
  for p in $(qm_sandbox_pids); do printf '  pid %s pgid %s: %s\n' "$p" "$(qm_pgid "$p")" "$(tr '\0' ' ' <"/proc/$p/cmdline" 2>/dev/null)"; done
}

qm_read_pid() { if [[ -f $1 ]]; then tr -cd '0-9' <"$1" 2>/dev/null || true; fi; }
qm_supervisor_pid() { local p; p=$(qm_read_pid "$QM_DIR/run/supervisor.pid"); qm_alive "$p" && echo "$p"; }
qm_node_pid() { local p; p=$(qm_read_pid "$QM_DIR/run/node.pid"); qm_alive "$p" && echo "$p"; }
qm_miner_pid() { local p; p=$(qm_read_pid "$QM_DIR/run/miner.pid"); qm_alive "$p" && echo "$p"; }
qm_supervisor_up() { [[ -n $(qm_supervisor_pid) ]]; }
qm_supervisor_down() { ! qm_supervisor_up && [[ -z $(pgrep -f -- "_supervise --dir $(qm_regex_escape "$QM_DIR")\$" || true) ]]; }
qm_node_up() { [[ -n $(qm_node_pid) ]]; }
qm_miner_up() { local p; p=$(qm_miner_pid) && [[ -n $p && $(cat "$QM_FAKE/miner.running" 2>/dev/null) == "$p" ]]; }
qm_count_lines() { if [[ -f $1 ]]; then wc -l <"$1" | tr -d ' '; else echo 0; fi; }

# Kill every process of this test: TERM the process groups (the supervisor is a session/group
# leader via setsid, node and miner are in its group), then KILL whatever is left.
qm_cleanup_procs() {
  [[ -n ${QM_DIR:-} ]] || return 0
  local own pid pg i
  local -a pids=() groups=()
  own=$(qm_pgid "$$")
  mapfile -t pids < <(qm_sandbox_pids)
  (( ${#pids[@]} )) || return 0
  for pid in "${pids[@]}"; do
    pg=$(qm_pgid "$pid") || continue
    if [[ -n $pg && $pg != "$own" && $pg -gt 1 ]]; then groups+=("$pg"); else kill -TERM "$pid" 2>/dev/null || true; fi
  done
  for pg in "${groups[@]}"; do kill -TERM -- "-$pg" 2>/dev/null || true; done
  for ((i = 0; i < 50; i++)); do qm_no_sandbox_procs && break; sleep 0.1; done
  for pg in "${groups[@]}"; do kill -KILL -- "-$pg" 2>/dev/null || true; done
  mapfile -t pids < <(qm_sandbox_pids)
  for pid in "${pids[@]}"; do kill -KILL "$pid" 2>/dev/null || true; done
  return 0
}

# ---------------------------------------------------------------------------------------------
# Polling and assertions
# ---------------------------------------------------------------------------------------------
wait_for() {  # seconds command… — poll every 0.2 s until the command succeeds
  local deadline=$(( $(date +%s) + $1 ))
  shift
  until "$@"; do
    (( $(date +%s) < deadline )) || return 1
    sleep 0.2
  done
}

assert_status() {  # expected — for the last `run`
  [[ ${status:-} == "$1" ]] && return 0
  printf 'expected exit status %s, got %s. Output:\n%s\n' "$1" "${status:-?}" "${output:-}" >&2
  return 1
}
assert_contains() {  # haystack needle
  [[ $1 == *"$2"* ]] && return 0
  printf 'expected to find:\n  %s\n--- in: ---\n%s\n-----------\n' "$2" "$1" >&2
  return 1
}
refute_contains() {  # haystack needle
  [[ $1 != *"$2"* ]] && return 0
  printf 'did NOT expect to find:\n  %s\n--- in: ---\n%s\n-----------\n' "$2" "$1" >&2
  return 1
}
assert_equal() {  # actual expected
  [[ $1 == "$2" ]] && return 0
  printf 'expected: %s\nactual:   %s\n' "$2" "$1" >&2
  return 1
}
refute() {  # command… — must FAIL (a bare `! cmd` never fails a bats test)
  if "$@"; then printf 'expected this to fail, but it succeeded: %s\n' "$*" >&2; return 1; fi
  return 0
}
assert_file_contains() {  # file needle
  if [[ -f $1 ]] && grep -qF -- "$2" "$1"; then return 0; fi
  printf 'file %s does not contain: %s\n--- file: ---\n%s\n' "$1" "$2" "$(cat "$1" 2>/dev/null || echo '<missing>')" >&2
  return 1
}
refute_file_contains() {  # file needle
  if [[ ! -f $1 ]] || ! grep -qF -- "$2" "$1"; then return 0; fi
  printf 'file %s unexpectedly contains: %s\n' "$1" "$2" >&2
  return 1
}
assert_accepts() {  # validator value…
  local fn=$1 v
  shift
  for v in "$@"; do "$fn" "$v" || { printf '%s rejected a valid value: %q\n' "$fn" "$v" >&2; return 1; }; done
}
assert_rejects() {  # validator value…
  local fn=$1 v
  shift
  for v in "$@"; do if "$fn" "$v"; then printf '%s accepted an invalid value: %q\n' "$fn" "$v" >&2; return 1; fi; done
}
