#!/usr/bin/env bash
# quantus-miner.sh — start mining Quantus (QTC) on MAINNET with one command.
#
#   SOLO (default): official quantus-node + official quantus-miner on this machine.
#                   Block rewards go straight to YOUR wormhole ("Encrypted Account") address.
#   POOL (option) : official quantus-miner only, connected to a 3rd-party pool (unofficial,
#                   not validated by Quantus; the pool holds your coins until it pays out).
#   DEVICE        : cpu (any x86_64 Ubuntu 24.04, incl. WSL2) or gpu (one NVIDIA card via CUDA,
#                   e.g. RTX 4090).
#
# Pinned, checksum-verified official releases (researched 2026-09-10):
#   node  v1.0.1  https://github.com/Quantus-Network/chain/releases/tag/v1.0.1
#   miner v4.2.0  https://github.com/Quantus-Network/quantus-miner/releases/tag/v4.2.0
#   NVRTC 12.8.93 (GPU only; Ubuntu's own NVRTC 12.0 cannot compile the v4.2.0 CUDA kernel)
#
# Run `./quantus-miner.sh help` for usage. User-facing messages are in Polish.

# ---------------------------------------------------------------------------------------------
# Pinned official releases. Override ONLY together with a matching SHA-256 (used by the tests).
# ---------------------------------------------------------------------------------------------
QM_NODE_URL="${QM_NODE_URL:-https://github.com/Quantus-Network/chain/releases/download/v1.0.1/quantus-node-v1.0.1-x86_64-unknown-linux-gnu.tar.gz}"
QM_NODE_SHA256="${QM_NODE_SHA256:-5880937c2a933b97d9916c5c9e78425d9918c6d7b68abe69de43680f62c13c93}"
QM_NODE_VERSION_MATCH="${QM_NODE_VERSION_MATCH:-quantus-node 1.0.1-}"
QM_MINER_URL="${QM_MINER_URL:-https://github.com/Quantus-Network/quantus-miner/releases/download/v4.2.0/quantus-miner-linux-x86_64}"
QM_MINER_SHA256="${QM_MINER_SHA256:-a929e11ee1fd4fe291d743f373041bc280620376f5084620db3b0f82d9a2a276}"
QM_MINER_VERSION_MATCH="${QM_MINER_VERSION_MATCH:-miner-cli 4.2.0}"
QM_NVRTC_URL="${QM_NVRTC_URL:-https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-nvrtc-12-8_12.8.93-1_amd64.deb}"
QM_NVRTC_SHA256="${QM_NVRTC_SHA256:-0b97fd1c36434f55292ca1c069247cd38a8709750820214c3aa45deac168db60}"
QM_NVRTC_SUBDIR="usr/local/cuda-12.8/targets/x86_64-linux/lib"

QM_PUBLIC_RPC="${QM_PUBLIC_RPC:-https://rpc1-mainnet.quantus.com}"
QM_INDEXER="${QM_INDEXER:-https://sqm.quantus.com/v1/graphql}"
QM_LOCAL_RPC="${QM_LOCAL_RPC:-http://127.0.0.1:9944}"
QM_SYSTEMD_DIR="${QM_SYSTEMD_DIR:-/etc/systemd/system}"
QM_TICK="${QM_TICK:-5}"                     # supervisor loop interval (s); tests use 1
QM_RESTART_DELAY="${QM_RESTART_DELAY:-10}"  # first restart back-off (s); tests use 1

readonly KIT_VERSION="1.0.0"
readonly MAINNET_GENESIS="0xfb5487c0be6ae4ade2d41d16e50465129861636c2b8d61fa94d7a19631626fba"
readonly EXPLORER_ACCOUNT_URL="https://explorer.quantus.com/accounts"
readonly TOTAL_ISSUANCE_KEY="0xc2261276cc9d1f8598ea4b6a74b15c2f57c875e4cff74148e4628f264b974c80"
readonly MIN_DRIVER_MAJOR=570
readonly MIN_GLIBC="2.38"
readonly MIN_NVRTC="12.1"
readonly SERVICE_NAME="quantus-miner-kit"
readonly MINER_PORT=9833
readonly P2P_PORT=30333
readonly RPC_PORT=9944

# Settings persisted in mining.conf (KEY=value, parsed safely — never `source`d).
readonly CONF_KEYS=(DEVICE MODE NODE_NAME TELEMETRY INNER_HASH REWARDS_ADDRESS CPU_WORKERS
                    GPU_DEVICES POOL_NAME POOL_ADDR POOL_FP PAYOUT_ADDRESS WORKER_NAME
                    BASE_PATH METRICS_PORT GPU_POWER_LIMIT)

# Runtime flags (set by parse_args).
DRY_RUN=0
ASSUME_YES=0
ALLOW_ROOT=0
KEY_MODE=""
REWARDS_ADDRESS_GIVEN=0
BENCH_DURATION=30
HASHRATE_MHS=""
LOG_TARGET=""
declare -gA CLI_SET=()   # -g: stays global even when this file is sourced from a function
TMP_PATHS=()             # temporary downloads, removed on every exit (also after die)

# ---------------------------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_RED=$'\e[31m'; C_GRN=$'\e[32m'; C_YEL=$'\e[33m'; C_BLU=$'\e[36m'; C_BLD=$'\e[1m'; C_OFF=$'\e[0m'
else
  C_RED=""; C_GRN=""; C_YEL=""; C_BLU=""; C_BLD=""; C_OFF=""
fi
info() { printf '%s\n' "${C_BLU}➜${C_OFF} $*"; }
ok()   { printf '%s\n' "${C_GRN}✔${C_OFF} $*"; }
warn() { printf '%s\n' "${C_YEL}⚠ $*${C_OFF}" >&2; }
err()  { printf '%s\n' "${C_RED}✖ $*${C_OFF}" >&2; }
die()  { err "$*"; exit 1; }
ts()   { date -u '+%Y-%m-%d %H:%M:%S UTC'; }
cleanup_tmp() { local p; for p in "${TMP_PATHS[@]}"; do [[ -n $p ]] && rm -rf -- "$p"; done; TMP_PATHS=(); }
new_tmp_dir() { TMP_DIR=$(mktemp -d) || die "Nie mogę utworzyć katalogu tymczasowego."; TMP_PATHS+=("$TMP_DIR"); }
slog() { printf '[%s] %s\n' "$(ts)" "$*"; }   # supervisor log line

# ---------------------------------------------------------------------------------------------
# Validation (pure functions — unit tested)
# ---------------------------------------------------------------------------------------------
is_uint()             { [[ ${1:-} =~ ^[0-9]+$ ]]; }
valid_inner_hash()    { [[ ${1:-} =~ ^0x[0-9a-fA-F]{64}$ ]]; }
valid_qz_address()    { [[ ${1:-} =~ ^qz[1-9A-HJ-NP-Za-km-z]{44,52}$ ]]; }
valid_tls_fp()        { [[ ${1:-} =~ ^[0-9a-f]{64}$ ]]; }
valid_node_name()     { [[ ${1:-} =~ ^[A-Za-z0-9][A-Za-z0-9_-]{0,31}$ ]]; }   # the node rejects '.' and '@'
valid_worker_name()   { [[ ${1:-} =~ ^[A-Za-z0-9][A-Za-z0-9_-]{0,31}$ ]]; }
valid_device()        { [[ ${1:-} == cpu || ${1:-} == gpu ]]; }
valid_mode()          { [[ ${1:-} == solo || ${1:-} == pool ]]; }
valid_yesno()         { [[ ${1:-} == yes || ${1:-} == no ]]; }
valid_port()          { is_uint "${1:-}" && (( 10#$1 >= 1024 && 10#$1 <= 65535 )); }
valid_abs_path()      { [[ ${1:-} == /* && ${1:-} != *$'\n'* && ${1:-} != *'..'* ]]; }
valid_power_limit()   { [[ -z ${1:-} ]] || { is_uint "$1" && (( 10#$1 >= 100 && 10#$1 <= 600 )); }; }
valid_cpu_workers()   { is_uint "${1:-}" && (( 10#$1 >= 1 && 10#$1 <= 1024 )); }
valid_gpu_devices()   { is_uint "${1:-}" && (( 10#$1 >= 1 && 10#$1 <= 16 )); }

# IPv4 literal with port: the official miner rejects host names (node_addr is a SocketAddr).
valid_ipv4_port() {
  local v=${1:-} ip port o
  [[ $v =~ ^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}):([0-9]{1,5})$ ]] || return 1
  ip=${BASH_REMATCH[1]}; port=${BASH_REMATCH[2]}
  (( 10#$port >= 1 && 10#$port <= 65535 )) || return 1
  local IFS=.
  for o in $ip; do (( 10#$o <= 255 )) || return 1; done
}

# version_ge A B → true when dotted version A >= B (numeric compare per component).
version_ge() {
  local IFS=. i
  local -a a b
  read -r -a a <<<"$1"; read -r -a b <<<"$2"
  for ((i = 0; i < ${#a[@]} || i < ${#b[@]}; i++)); do
    local x=${a[i]:-0} y=${b[i]:-0}
    x=${x//[^0-9]/}; y=${y//[^0-9]/}
    (( 10#${x:-0} > 10#${y:-0} )) && return 0
    (( 10#${x:-0} < 10#${y:-0} )) && return 1
  done
  return 0
}

pool_preset() {  # name → "addr fp dashboard"; values fetched from the pools' own pages 2026-09-10
  case "${1:-}" in
    nurserypool) echo "162.19.84.16:2255 e21265920ae09417de61b68705e36357f697d17f8eadb2b04ba620019b291ffe https://quan.nurserypool.com" ;;
    quanpool)    echo "37.187.143.115:9834 87dc37af6096a3ddc860b94368ca087775f3ad3e0c4e9bcff3b07ea08d8abef6 https://quanpool.com" ;;
    *) return 1 ;;
  esac
}

is_conf_key() {
  local k
  for k in "${CONF_KEYS[@]}"; do [[ $k == "$1" ]] && return 0; done
  return 1
}

# ---------------------------------------------------------------------------------------------
# Paths and configuration
# ---------------------------------------------------------------------------------------------
set_paths() {
  QM_DIR="${QM_DIR:-$HOME/quantus-miner-kit}"
  [[ $QM_DIR == /* ]] || QM_DIR="$PWD/$QM_DIR"   # systemd needs absolute paths
  [[ $QM_DIR != *[$'\n\r']* ]] || die "Katalog (--dir) nie może zawierać znaku nowej linii."
  BIN_DIR="$QM_DIR/bin"; LOG_DIR="$QM_DIR/logs"; RUN_DIR="$QM_DIR/run"
  CONF_FILE="$QM_DIR/mining.conf"; NODE_KEY="$QM_DIR/node_key.p2p"
  NODE_BIN="$BIN_DIR/quantus-node"; MINER_BIN="$BIN_DIR/quantus-miner"
  KIT_COPY="$BIN_DIR/quantus-miner.sh"
  # how to call this script again in hints (with --dir when a non-default kit directory is used)
  ME=$0; [[ $QM_DIR == "$HOME/quantus-miner-kit" ]] || ME="$0 --dir $(printf '%q' "$QM_DIR")"
  NVRTC_DIR="$QM_DIR/nvrtc"; NVRTC_LIB="$NVRTC_DIR/$QM_NVRTC_SUBDIR"
  NODE_LOG="$LOG_DIR/node.log"; MINER_LOG="$LOG_DIR/miner.log"; SUP_LOG="$LOG_DIR/supervisor.log"
  SUP_PID="$RUN_DIR/supervisor.pid"; NODE_PID_FILE="$RUN_DIR/node.pid"; MINER_PID_FILE="$RUN_DIR/miner.pid"
}

set_chain_dir() { CHAIN_DIR="$BASE_PATH/chains/mainnet"; }

load_config() {
  [[ -f $CONF_FILE ]] || return 0
  local line key value
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line%$'\r'}   # a file saved with Windows line endings (e.g. edited via \\wsl$)
    [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
    [[ $line =~ ^([A-Z_]+)=(.*)$ ]] || continue
    key=${BASH_REMATCH[1]}; value=${BASH_REMATCH[2]}
    value=${value%\"}; value=${value#\"}
    is_conf_key "$key" || continue
    [[ -n ${CLI_SET[$key]:-} ]] && continue   # command-line flags win
    printf -v "$key" '%s' "$value"
  done <"$CONF_FILE"
}

apply_defaults() {
  local n
  : "${MODE:=solo}"
  : "${TELEMETRY:=yes}"
  : "${BASE_PATH:=$HOME/.local/share/quantus-node}"
  : "${METRICS_PORT:=9900}"
  : "${GPU_DEVICES:=1}"
  : "${POOL_NAME:=nurserypool}"
  : "${WORKER_NAME:=$(hostname -s 2>/dev/null | tr -cd 'A-Za-z0-9_-' | cut -c1-24)}"
  [[ -n $WORKER_NAME ]] || WORKER_NAME="rig1"
  if [[ -z ${DEVICE:-} ]]; then
    if has_nvidia_gpu; then DEVICE=gpu; else DEVICE=cpu; fi
  fi
  if [[ -z ${CPU_WORKERS:-} ]]; then
    n=$(nproc 2>/dev/null || echo 2)
    CPU_WORKERS=$(( n > 2 ? n - 2 : 1 ))
  fi
  if [[ -z ${NODE_NAME:-} ]]; then
    NODE_NAME=$(printf 'qtc-%04x%04x' "$RANDOM" "$RANDOM")
  fi
  set_chain_dir
}

# Returns the list of problems (one per line); empty output = all good.
settings_problems() {
  valid_device "$DEVICE"          || echo "DEVICE musi być cpu albo gpu (jest: '$DEVICE')"
  valid_mode "$MODE"              || echo "MODE musi być solo albo pool (jest: '$MODE')"
  valid_yesno "$TELEMETRY"        || echo "TELEMETRY musi być yes albo no"
  valid_node_name "$NODE_NAME"    || echo "Nazwa node'a: tylko litery/cyfry/_- (bez kropek, max 32), jest: '$NODE_NAME'"
  valid_cpu_workers "$CPU_WORKERS" || echo "CPU_WORKERS musi być liczbą 1..1024"
  valid_gpu_devices "$GPU_DEVICES" || echo "GPU_DEVICES musi być liczbą 1..16"
  valid_abs_path "$BASE_PATH"     || echo "BASE_PATH musi być ścieżką absolutną (bez '..')"
  valid_port "$METRICS_PORT"      || echo "METRICS_PORT musi być portem 1024..65535"
  valid_power_limit "${GPU_POWER_LIMIT:-}" || echo "GPU_POWER_LIMIT musi być liczbą 100..600 (W) albo pusty"
  valid_worker_name "$WORKER_NAME" || echo "Nazwa koparki (worker): tylko litery/cyfry/_- (max 32)"
  [[ -z ${INNER_HASH:-} ]] || valid_inner_hash "$INNER_HASH" || echo "INNER_HASH musi mieć postać 0x + 64 znaki hex"
  [[ -z ${REWARDS_ADDRESS:-} ]] || valid_qz_address "$REWARDS_ADDRESS" || echo "REWARDS_ADDRESS wygląda na błędny adres qz…"
  # Pool fields are checked in solo mode too: every saved value must be clean (no line breaks).
  [[ -z ${POOL_ADDR:-} ]] || valid_ipv4_port "$POOL_ADDR" || echo "POOL_ADDR musi być adresem IP:port (miner nie przyjmuje nazw domen)"
  [[ -z ${POOL_FP:-} ]] || valid_tls_fp "$POOL_FP" || echo "POOL_FP musi mieć dokładnie 64 znaki hex (małe litery)"
  [[ -z ${PAYOUT_ADDRESS:-} ]] || valid_qz_address "$PAYOUT_ADDRESS" || echo "Adres wypłat z puli wygląda na błędny adres qz…"
  [[ ${POOL_NAME:-} =~ ^[a-z]{1,20}$ ]] || echo "POOL_NAME: dozwolone nurserypool, quanpool, custom"
  return 0
}

validate_settings() {
  local problems
  problems=$(settings_problems)
  [[ -z $problems ]] || die "Błędne ustawienia:"$'\n'"$problems"
}

# Resolve pool preset → POOL_ADDR/POOL_FP (custom = both given explicitly).
resolve_pool() {
  local preset
  if [[ $POOL_NAME != custom ]]; then
    preset=$(pool_preset "$POOL_NAME") || die "Nieznana pula '$POOL_NAME'. Dostępne: nurserypool, quanpool, custom."
    if [[ -z ${CLI_SET[POOL_ADDR]:-} ]]; then POOL_ADDR=${preset%% *}; fi
    if [[ -z ${CLI_SET[POOL_FP]:-} ]]; then POOL_FP=$(awk '{print $2}' <<<"$preset"); fi
  fi
  [[ -n ${POOL_ADDR:-} && -n ${POOL_FP:-} ]] || die "Dla --pool custom podaj --pool-addr IP:PORT i --pool-fp <64 hex>."
  valid_ipv4_port "$POOL_ADDR" || die "--pool-addr musi być adresem IP:port (np. 162.19.84.16:2255). Miner odrzuca nazwy domen."
  valid_tls_fp "$POOL_FP" || die "--pool-fp musi mieć dokładnie 64 znaki hex. Skopiuj go ze strony puli."
}

pool_dashboard() {
  local p
  if p=$(pool_preset "${POOL_NAME:-}"); then awk '{print $3}' <<<"$p"; else echo "-"; fi
}

save_config() {
  local tmp k
  for k in "${CONF_KEYS[@]}"; do   # one KEY=value per line: a line break would inject another key
    [[ ${!k:-} != *[$'\n\r']* ]] || die "Wartość $k zawiera znak nowej linii — odrzucam."
  done
  mkdir -p "$QM_DIR" && chmod 700 "$QM_DIR"
  tmp=$(mktemp "$QM_DIR/.mining.conf.XXXXXX")
  {
    echo "# quantus-miner.sh $KIT_VERSION — ustawienia ($(ts)). Nie udostępniaj tego pliku."
    for k in "${CONF_KEYS[@]}"; do printf '%s=%s\n' "$k" "${!k:-}"; done
  } >"$tmp"
  chmod 600 "$tmp"
  mv -f "$tmp" "$CONF_FILE"
}

# ---------------------------------------------------------------------------------------------
# Environment checks
# ---------------------------------------------------------------------------------------------
is_wsl()       { grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null || [[ -n ${WSL_DISTRO_NAME:-} ]]; }
has_systemd()  { [[ $(ps -p 1 -o comm= 2>/dev/null) == systemd ]]; }
has_nvidia_gpu() { command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L 2>/dev/null | grep -q '^GPU '; }
service_installed() { [[ -f $QM_SYSTEMD_DIR/$SERVICE_NAME.service ]]; }

glibc_version() { { ldd --version 2>/dev/null || true; } | sed -n 1p | grep -oE '[0-9]+\.[0-9]+' | tail -n 1 || true; }

check_platform() {
  [[ $(uname -s) == Linux ]] || die "Ten skrypt działa tylko na Linuksie (Ubuntu 24.04)."
  [[ $(uname -m) == x86_64 ]] || die "Oficjalne binarki są tylko dla x86_64 (masz: $(uname -m))."
  if [[ $EUID -eq 0 && $ALLOW_ROOT -ne 1 ]]; then
    die "Nie uruchamiaj jako root. Uruchom jako zwykły użytkownik (skrypt sam poprosi o sudo, gdy trzeba)."
  fi
  local t missing=()
  for t in curl tar sha256sum sed grep awk ps setsid nohup flock mktemp; do
    command -v "$t" >/dev/null 2>&1 || missing+=("$t")
  done
  if [[ $DEVICE == gpu ]]; then
    # (nvidia-smi is checked by check_nvidia_driver, which gives the right fix: install the driver)
    for t in python3 dpkg-deb; do command -v "$t" >/dev/null 2>&1 || missing+=("$t"); done
  fi
  (( ${#missing[@]} == 0 )) || die "Brakuje programów: ${missing[*]}. Zainstaluj: sudo apt install -y curl tar coreutils util-linux procps python3"
  if [[ $MODE == solo ]]; then
    local g
    g=$(glibc_version)
    if [[ -z $g ]] || ! version_ge "$g" "$MIN_GLIBC"; then
      die "Node v1.0.1 wymaga glibc >= $MIN_GLIBC (masz: ${g:-?}). Użyj Ubuntu 24.04 (Ubuntu 22.04 jest za stare)."
    fi
  fi
}

check_resources() {
  local avail_kb mem_kb parent
  parent=$BASE_PATH
  while [[ ! -d $parent ]]; do parent=$(dirname "$parent"); done
  avail_kb=$(df -Pk "$parent" 2>/dev/null | awk 'NR==2{print $4}')
  if is_uint "${avail_kb:-}" && (( avail_kb < 20 * 1024 * 1024 )) && [[ $MODE == solo ]]; then
    warn "Mało miejsca na dysku ($(( avail_kb / 1024 / 1024 )) GB wolnego miejsca). Node potrzebuje co najmniej ~20 GB, zalecane 100 GB+."
  fi
  mem_kb=$(awk '/^MemTotal:/{print $2}' /proc/meminfo 2>/dev/null)
  if is_uint "${mem_kb:-}" && (( mem_kb < 4 * 1024 * 1024 )) && [[ $MODE == solo ]]; then
    warn "Mało RAM ($(( mem_kb / 1024 )) MB). Node potrzebuje minimum 4 GB."
  fi
}

# Clock drift vs public RPC (blocks > 15 s in the future are rejected by the chain).
check_clock() {
  local hdr remote local_now drift
  hdr=$({ curl -sI --max-time 10 "$QM_PUBLIC_RPC" 2>/dev/null || true; } | tr -d '\r' | sed -n 's/^[Dd]ate: //p' | sed -n 1p)
  [[ -n $hdr ]] || { warn "Nie udało się sprawdzić zegara (brak odpowiedzi $QM_PUBLIC_RPC)."; return 0; }
  remote=$(date -u -d "$hdr" +%s 2>/dev/null) || return 0
  local_now=$(date -u +%s)
  drift=$(( local_now - remote )); drift=${drift#-}
  if (( drift > 5 )); then
    warn "Zegar komputera różni się o ${drift}s od sieci. Bloki ze złym czasem są odrzucane."
    if is_wsl; then warn "Napraw (WSL): sudo hwclock -s   (albo w PowerShell: wsl --shutdown i uruchom ponownie)"
    else warn "Napraw: sudo timedatectl set-ntp true"; fi
  else
    ok "Zegar zsynchronizowany (różnica ${drift}s)."
  fi
}

port_in_use() {  # proto port
  command -v ss >/dev/null 2>&1 || return 1
  if [[ $1 == udp ]]; then ss -Hlun "sport = :$2" 2>/dev/null | grep -q .
  else ss -Hltn "sport = :$2" 2>/dev/null | grep -q .; fi
}

check_ports() {
  local busy=()
  if [[ $MODE == solo ]]; then
    port_in_use tcp "$RPC_PORT" && busy+=("$RPC_PORT/tcp (RPC)")
    port_in_use tcp "$P2P_PORT" && busy+=("$P2P_PORT/tcp (P2P)")
    port_in_use udp "$MINER_PORT" && busy+=("$MINER_PORT/udp (miner)")
  fi
  port_in_use tcp "$METRICS_PORT" && busy+=("$METRICS_PORT/tcp (metryki minera; zmień: --metrics-port)")
  (( ${#busy[@]} == 0 )) || die "Zajęte porty: ${busy[*]}. Czy działa już inny node/miner (np. oficjalny quantus-mining.sh)? Zatrzymaj go."
}

# ---------------------------------------------------------------------------------------------
# Downloads and binaries
# ---------------------------------------------------------------------------------------------
download() {  # url dest
  info "Pobieram: $1"
  curl -fL --retry 3 --retry-delay 3 --connect-timeout 20 --progress-bar -o "$2.part" "$1" \
    || { rm -f "$2.part"; die "Pobieranie nie powiodło się: $1"; }
  mv -f "$2.part" "$2"
}

verify_sha256() {  # file expected
  local got
  got=$(sha256sum "$1" | awk '{print $1}')
  [[ $got == "$2" ]] || die "Suma kontrolna się NIE zgadza dla $(basename "$1")! Oczekiwano $2, jest $got. Przerywam (plik mógł zostać podmieniony)."
  ok "Suma SHA-256 poprawna: $(basename "$1")"
}

binary_version_ok() {  # bin match
  [[ -x $1 ]] || return 1
  "$1" --version 2>/dev/null | grep -qF "$2"
}

install_node() {
  if binary_version_ok "$NODE_BIN" "$QM_NODE_VERSION_MATCH"; then ok "quantus-node już zainstalowany ($("$NODE_BIN" --version 2>/dev/null))"; return 0; fi
  local tmp
  new_tmp_dir; tmp=$TMP_DIR
  download "$QM_NODE_URL" "$tmp/node.tar.gz"
  verify_sha256 "$tmp/node.tar.gz" "$QM_NODE_SHA256"
  tar -xzf "$tmp/node.tar.gz" -C "$tmp"
  [[ -f $tmp/quantus-node ]] || die "W archiwum nie ma pliku quantus-node."
  mkdir -p "$BIN_DIR"
  install -m 755 "$tmp/quantus-node" "$NODE_BIN"
  cleanup_tmp
  binary_version_ok "$NODE_BIN" "$QM_NODE_VERSION_MATCH" || die "quantus-node nie uruchamia się poprawnie (--version)."
  "$NODE_BIN" --help 2>/dev/null | grep -q -- '--miner-auth-token-file' || die "Ta wersja node'a nie obsługuje autoryzacji minera (brak --miner-auth-token-file)."
  ok "Zainstalowano $("$NODE_BIN" --version 2>/dev/null)"
}

install_miner() {
  if binary_version_ok "$MINER_BIN" "$QM_MINER_VERSION_MATCH"; then ok "quantus-miner już zainstalowany ($("$MINER_BIN" --version 2>/dev/null))"; return 0; fi
  local tmp
  new_tmp_dir; tmp=$TMP_DIR
  download "$QM_MINER_URL" "$tmp/quantus-miner"
  verify_sha256 "$tmp/quantus-miner" "$QM_MINER_SHA256"
  mkdir -p "$BIN_DIR"
  install -m 755 "$tmp/quantus-miner" "$MINER_BIN"
  cleanup_tmp
  binary_version_ok "$MINER_BIN" "$QM_MINER_VERSION_MATCH" || die "quantus-miner nie uruchamia się poprawnie (--version)."
  local h
  h=$("$MINER_BIN" serve --help 2>/dev/null || true)
  if ! grep -q -- '--auth-token-file' <<<"$h" || ! grep -q -- '--tls-cert-sha256-file' <<<"$h"; then
    die "Ta wersja minera nie pasuje do node'a v1.0.1 (brak --auth-token-file/--tls-cert-sha256-file)."
  fi
  ok "Zainstalowano $("$MINER_BIN" --version 2>/dev/null)"
}

# ---------------------------------------------------------------------------------------------
# GPU (NVIDIA CUDA) preparation
# ---------------------------------------------------------------------------------------------
nvidia_driver_version() { { nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || true; } | sed -n 1p | tr -d ' '; }
nvidia_gpu_name()       { { nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || true; } | sed -n 1p; }

check_nvidia_driver() {
  has_nvidia_gpu || die "Nie widzę karty NVIDIA (nvidia-smi -L). Zainstaluj sterownik: sudo ubuntu-drivers install  (potem restart)."
  local v major
  v=$(nvidia_driver_version); major=${v%%.*}
  is_uint "${major:-}" || die "Nie mogę odczytać wersji sterownika NVIDIA."
  (( major >= MIN_DRIVER_MAJOR )) || die "Sterownik NVIDIA $v jest za stary (potrzeba >= $MIN_DRIVER_MAJOR). Zainstaluj: sudo apt install nvidia-driver-580  i zrestartuj komputer."
  ok "GPU: $(nvidia_gpu_name), sterownik $v"
}

# Prints "MAJOR.MINOR" of the NVRTC that the miner would load (same search order as cudarc).
nvrtc_version() {
  LD_LIBRARY_PATH="$NVRTC_LIB${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" python3 - <<'PY' 2>/dev/null
import ctypes
lib = None
for name in ("libnvrtc.so", "libnvrtc.so.12", "libnvrtc.so.11"):
    try:
        lib = ctypes.CDLL(name)
        break
    except OSError:
        pass
if lib is None:
    raise SystemExit(1)
a, b = ctypes.c_int(), ctypes.c_int()
lib.nvrtcVersion(ctypes.byref(a), ctypes.byref(b))
print("%d.%d" % (a.value, b.value))
PY
}

# NVRTC 12.8 unpacked into the kit directory — no sudo, no apt repo, nothing system-wide.
install_nvrtc() {
  if [[ -e $NVRTC_LIB/libnvrtc.so.12 ]]; then
    ok "NVRTC 12.8 już jest w $NVRTC_LIB"
  else
    local tmp
    new_tmp_dir; tmp=$TMP_DIR
    download "$QM_NVRTC_URL" "$tmp/nvrtc.deb"
    verify_sha256 "$tmp/nvrtc.deb" "$QM_NVRTC_SHA256"
    rm -rf "$NVRTC_DIR"; mkdir -p "$NVRTC_DIR"
    dpkg-deb -x "$tmp/nvrtc.deb" "$NVRTC_DIR"
    cleanup_tmp
    [[ -e $NVRTC_LIB/libnvrtc.so.12 ]] || die "Po rozpakowaniu brak $NVRTC_LIB/libnvrtc.so.12."
  fi
  # cudarc tries the unversioned name first — make sure OUR copy answers to it.
  ln -sfn libnvrtc.so.12 "$NVRTC_LIB/libnvrtc.so"
  local v
  v=$(nvrtc_version) || die "Nie da się załadować NVRTC (python3 + ctypes)."
  version_ge "$v" "$MIN_NVRTC" || die "Załadowany NVRTC ma wersję $v (potrzeba >= $MIN_NVRTC). Usuń stary pakiet: sudo apt remove nvidia-cuda-toolkit nvidia-cuda-dev libnvrtc12"
  ok "NVRTC $v gotowy (CUDA)."
}

# 5-second CUDA self-test: proves libcuda + NVRTC + kernel compile work before we rely on it.
gpu_selftest() {
  info "Test CUDA (5 s, karta zacznie pracować)…"
  local out rc=0
  out=$(miner_env_run "$MINER_BIN" benchmark --cuda-gpu --gpu-devices "$GPU_DEVICES" --cpu-workers 0 --duration 5 2>&1) || rc=$?
  if (( rc == 0 )) && grep -q 'Average rate' <<<"$out"; then
    ok "CUDA działa: $(grep -m1 'Average rate' <<<"$out" | sed 's/^[[:space:]]*//')"
    return 0
  fi
  err "Test CUDA nie przeszedł (kod wyjścia $rc). Ostatnie linie:"
  tail -n 15 <<<"$out" >&2
  if (( rc == 134 )) || [[ -z $out ]]; then
    err "Cichy błąd = brak biblioteki libcuda albo NVRTC. Sprawdź sterownik (nvidia-smi) i uruchom skrypt ponownie."
  fi
  die "Napraw błąd CUDA i spróbuj ponownie (instrukcja: sekcja 'Problemy' w INSTRUKCJA-GPU-RTX4090.md)."
}

# Each card has its own allowed power range (RTX 4090: ~150–450/600 W); check it at setup.
check_power_limit() {
  [[ $DEVICE == gpu && -n ${GPU_POWER_LIMIT:-} ]] || return 0
  local r lo hi
  r=$({ nvidia-smi --query-gpu=power.min_limit,power.max_limit --format=csv,noheader,nounits 2>/dev/null || true; } | sed -n 1p)
  lo=${r%%,*}; hi=${r#*,}; lo=${lo//[[:space:]]/}; hi=${hi//[[:space:]]/}; lo=${lo%%.*}; hi=${hi%%.*}
  if ! is_uint "$lo" || ! is_uint "$hi"; then return 0; fi   # old driver/card: no range reported
  if (( 10#$GPU_POWER_LIMIT < 10#$lo || 10#$GPU_POWER_LIMIT > 10#$hi )); then
    die "Limit mocy ${GPU_POWER_LIMIT} W jest poza zakresem tej karty (${lo}–${hi} W). Podaj wartość z tego zakresu albo --gpu-power-limit off."
  fi
  ok "Limit mocy ${GPU_POWER_LIMIT} W mieści się w zakresie karty (${lo}–${hi} W)."
}

apply_power_limit() {
  [[ $DEVICE == gpu && -n ${GPU_POWER_LIMIT:-} ]] || return 0
  info "Ustawiam limit mocy GPU na ${GPU_POWER_LIMIT} W (wymaga sudo)…"
  if ! { sudo nvidia-smi -pm 1 >/dev/null && sudo nvidia-smi -pl "$GPU_POWER_LIMIT"; }; then
    warn "Nie udało się ustawić limitu mocy (kopanie i tak ruszy)."
  fi
}

# Clean miner environment: stray MINER_* variables can make the miner refuse to start
# (e.g. MINER_CUDA_GPU=1 → "invalid value"), so they are removed; GPU mode adds our NVRTC.
# Sets the MENV array so callers can run `"${MENV[@]}" cmd … &` as ONE simple command —
# then $! is the real miner PID (env → nice → miner all exec in place).
miner_env_prefix() {
  local v
  MENV=(env)
  while IFS= read -r v; do [[ -n $v ]] && MENV+=(-u "$v"); done < <(compgen -e | grep '^MINER_' || true)
  if [[ $DEVICE == gpu ]]; then
    MENV+=("LD_LIBRARY_PATH=$NVRTC_LIB${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}")
  fi
}

miner_env_run() { miner_env_prefix; "${MENV[@]}" "$@"; }

# ---------------------------------------------------------------------------------------------
# Keys and rewards identity (solo)
# ---------------------------------------------------------------------------------------------
ensure_node_key() {
  if [[ -s $NODE_KEY ]]; then return 0; fi
  info "Tworzę klucz sieciowy node'a (to NIE jest portfel)…"
  "$NODE_BIN" key generate-node-key --file "$NODE_KEY" >/dev/null 2>&1 || die "Nie udało się utworzyć klucza node'a."
  chmod 600 "$NODE_KEY"
  ok "Klucz node'a: $NODE_KEY"
}

parse_key_output() {  # stdin: output of `quantus-node key quantus --scheme wormhole` → sets globals
  local out
  out=$(cat)
  PARSED_ADDRESS=$(sed -n 's/^Address:[[:space:]]*\(qz[1-9A-HJ-NP-Za-km-z]*\).*/\1/p' <<<"$out" | head -1)
  PARSED_INNER=$(sed -n 's/^Inner Hash:[[:space:]]*\(0x[0-9a-fA-F]*\).*/\1/p' <<<"$out" | head -1)
  valid_inner_hash "$PARSED_INNER" && valid_qz_address "$PARSED_ADDRESS"
}

ask() {  # prompt → REPLY (from the terminal)
  local prompt=$1
  if [[ ! -t 0 ]]; then die "Potrzebna odpowiedź na pytanie, a skrypt nie działa w terminalu. Uruchom go w oknie terminala albo podaj opcje (np. --inner-hash 0x… --yes)."; fi
  read -r -p "$prompt" REPLY
}

confirm() {  # prompt → true on yes
  (( ASSUME_YES )) && return 0
  ask "$1 [t/N]: " || return 1
  [[ ${REPLY,,} == t || ${REPLY,,} == tak || ${REPLY,,} == y || ${REPLY,,} == yes ]]
}

clear_screen() { clear 2>/dev/null || printf '\e[H\e[2J\e[3J'; }

show_new_phrase() {  # words… — numbered, 4 per row (fewer copying mistakes than one long line)
  local i
  echo
  echo "${C_BLD}========== TWOJA NOWA FRAZA DO NAGRÓD ($# słów) — przepisz ją NA PAPIER ==========${C_OFF}"
  for ((i = 1; i <= $#; i++)); do
    printf '  %2d. %-12s' "$i" "${!i}"
    if (( i % 4 == 0 || i == $# )); then echo; fi
  done
  echo "  Adres nagród (w aplikacji: Encrypted Account): $PARSED_ADDRESS"
  echo "${C_BLD}=================================================================================${C_OFF}"
  warn "Kto ma tę frazę, ten ma Twoje nagrody. Skrypt jej NIGDZIE nie zapisuje — to jedyna kopia."
  warn "Nie rób zdjęcia i nie zaznaczaj/kopiuj jej myszką ani Ctrl+C (schowek Windows ją zapamiętuje)."
  warn "Aplikacja Quantus: zanim wpiszesz tam tę frazę, zapisz na papierze frazę, która już jest w aplikacji" \
       "(np. z testnetu — potrzebna do airdropu). Dodanie nowego portfela może usunąć stary."
}

confirm_written() {  # → true once the user typed ZAPISAŁEM (any case, with or without 'ł'); false = abort
  local r i
  for i in 1 2 3; do
    ask "Wpisz ZAPISAŁEM, gdy fraza jest zapisana na papierze (albo STOP, żeby przerwać): " || return 1
    r=${REPLY,,}; r=${r//Ł/ł}; r=${r//[[:space:]]/}
    if [[ $r == zapisałem || $r == zapisalem ]]; then return 0; fi
    if [[ $r == stop || $r == nie || $r == n ]]; then return 1; fi
    warn "Nie rozpoznałem odpowiedzi. Wpisz słowo ZAPISAŁEM (wielkość liter bez znaczenia)."
  done
  return 1
}

phrase_quiz() {  # words… → true when 3 randomly chosen words are typed correctly (from paper)
  local -a pos=()
  local p ans
  if [[ -n ${QM_QUIZ_POSITIONS:-} ]]; then read -r -a pos <<<"$QM_QUIZ_POSITIONS"   # tests only
  else
    while (( ${#pos[@]} < 3 )); do
      p=$(( RANDOM % $# + 1 ))
      [[ " ${pos[*]} " == *" $p "* ]] || pos+=("$p")
    done
  fi
  echo "Sprawdzenie zapisu — przepisz z PAPIERU słowa o podanych numerach:"
  for p in "${pos[@]}"; do
    ask "  Słowo nr $p: " || { REPLY=""; return 1; }
    ans=${REPLY,,}; ans=${ans//[[:space:]]/}
    [[ $ans == "${!p}" ]] || { REPLY=""; return 1; }
  done
  REPLY=""
}

# New rewards key. The phrase is shown ONLY on the terminal (never in a file or log) and the
# screen is cleared only after the user confirmed AND passed a 3-word check of the paper copy.
# --yes does not skip this: an unseen phrase means rewards nobody can ever spend.
rewards_new_phrase() {
  [[ -t 0 && -t 1 ]] || die "Nową frazę 24 słów można pokazać tylko na ekranie terminala (nigdy w pliku ani logu)." \
    "Uruchom polecenie w oknie terminala, bez '| tee' i bez '>'. Do automatyzacji użyj --inner-hash 0x…"
  local out phrase round
  local -a words
  out=$("$NODE_BIN" key quantus --scheme wormhole 2>&1) || die "Generowanie klucza nie powiodło się."
  parse_key_output <<<"$out" || die "Nie rozpoznałem wyniku generowania klucza."
  phrase=$(sed -n 's/^Secret phrase:[[:space:]]*//p' <<<"$out" | sed -n 1p)
  out=""
  read -r -a words <<<"${phrase,,}"
  phrase=""
  (( ${#words[@]} == 24 || ${#words[@]} == 12 )) || die "Nie rozpoznałem frazy w wyniku generowania klucza."
  for round in 1 2 3; do
    show_new_phrase "${words[@]}"
    if ! confirm_written; then
      words=(); clear_screen
      warn "Tej frazy NIE używamy — przekreśl ją na kartce. Następne uruchomienie pokaże NOWĄ, inną frazę."
      die "Przerwano — nic nie zapisano, nagrody nie są ustawione."
    fi
    clear_screen
    if phrase_quiz "${words[@]}"; then
      words=(); clear_screen
      ok "Zapis frazy sprawdzony. Ekran wyczyszczony."
      return 0
    fi
    warn "To słowo nie zgadza się z frazą. Popraw zapis na papierze — pokazuję frazę jeszcze raz (próba $round/3)."
  done
  words=(); clear_screen
  die "Trzy razy błędne słowo — przerwano, nic nie zapisano. Uruchom ponownie."
}

# Swallow whatever is still typed/pasted, so no seed word can reach the user's shell
# (and ~/.bash_history) after this script ends.
drain_tty_input() {
  local _junk
  while IFS= read -r -s -t 0.3 _junk; do :; done
  _junk=""
  return 0
}

phrase_words() {  # text → words: lower case; "1." / "1)" numbering, commas and semicolons removed
  sed -E 's/[,;]/ /g; s/(^|[[:space:]])[0-9]+[.):]*/ /g' <<<"${1,,}"
}

# Existing phrase, typed invisibly. Words may come on one line or on several (a pasted numbered
# list, two rows of 12…): input is collected until 24 words, or an empty line ends it.
rewards_import_phrase() {
  [[ -t 0 ]] || die "Wpisywanie frazy wymaga terminala."
  local line phrase="" out n=0
  local -a w
  echo "Wpisz słowa swojej frazy (nie będą widoczne). Najlepiej wszystkie w JEDNEJ linii, oddzielone"
  echo "spacjami, i jeden Enter. Możesz też wpisywać po kilka słów + Enter — skrypt poczeka na 24."
  while (( n < 24 )); do
    IFS= read -r -s line || break
    read -r -a w <<<"$(phrase_words "$line")"
    line=""
    if (( ${#w[@]} == 0 )); then
      if (( n > 0 )); then break; fi   # an empty line ends the input (12-word phrases)
      continue
    fi
    phrase+=" ${w[*]}"; n=$(( n + ${#w[@]} )); w=()
    if (( n < 24 )); then printf '  (wpisano %d/24 słów; pusta linia = koniec, jeśli fraza ma 12 słów)\n' "$n"; fi
  done
  echo
  drain_tty_input
  if (( n == 12 )); then
    confirm "Wpisano 12 słów. Czy Twoja fraza ma tylko 12 słów?" || { phrase=""; die "Przerwano. Uruchom ponownie i wpisz całą frazę."; }
  elif (( n != 24 )); then
    phrase=""; die "Fraza musi mieć 24 słowa (albo 12) — wpisano: $n."
  fi
  out=$(printf '%s\n' "${phrase# }" | "$NODE_BIN" key quantus --scheme wormhole --words 2>&1) \
    || { phrase=""; die "Fraza odrzucona (literówka w którymś słowie?)."; }
  phrase=""
  parse_key_output <<<"$out" || die "Nie rozpoznałem wyniku (sprawdź frazę)."
  out=""
  ok "Fraza przyjęta. Adres nagród z tej frazy: $PARSED_ADDRESS"
  info "Porównaj go z adresem 'Encrypted Account' w aplikacji Quantus — powinny być identyczne."
}

ensure_rewards_identity() {
  if [[ -n ${INNER_HASH:-} ]]; then
    valid_inner_hash "$INNER_HASH" || die "INNER_HASH ma zły format (0x + 64 hex)."
    if [[ -z ${KEY_MODE:-} || -n ${CLI_SET[INNER_HASH]:-} ]]; then return 0; fi
    # --key new|import with a key already configured: replace it, but never silently.
    warn "Masz już ustawiony klucz nagród (adres: ${REWARDS_ADDRESS:-nieznany}, Inner Hash ${INNER_HASH:0:12}…)."
    confirm "Zastąpić go (--key $KEY_MODE)? Kolejne nagrody trafią na NOWY adres." || die "Przerwano — klucz nagród bez zmian."
    INNER_HASH=""; REWARDS_ADDRESS=""
  fi
  local choice=${KEY_MODE:-}
  if [[ -z $choice ]]; then
    (( ASSUME_YES )) && die "Brak klucza do nagród. Podaj --key new, --key import albo --inner-hash 0x…"
    echo
    echo "${C_BLD}Dokąd mają trafiać nagrody z kopania?${C_OFF}"
    echo "  1) Utwórz NOWĄ frazę 24 słów (zalecane dla mainnetu)"
    echo "  2) Użyj ISTNIEJĄCEJ frazy 24 słów (fraza z testnetu też zadziała — i tak zachowaj ją do airdropu)"
    echo "  3) Mam już Inner Hash (0x…) — np. z innego komputera"
    ask "Wybierz [1/2/3]: " || die "Przerwano (brak odpowiedzi)."
    case $REPLY in 1) choice="new" ;; 2) choice="import" ;; 3) choice="hash" ;; *) die "Nieprawidłowy wybór." ;; esac
  fi
  case $choice in
    new) rewards_new_phrase; INNER_HASH=$PARSED_INNER; REWARDS_ADDRESS=$PARSED_ADDRESS ;;
    import) rewards_import_phrase; INNER_HASH=$PARSED_INNER; REWARDS_ADDRESS=$PARSED_ADDRESS ;;
    hash)
      ask "Wklej Inner Hash (0x + 64 znaki): " || die "Przerwano (brak odpowiedzi)."
      valid_inner_hash "$REPLY" || die "To nie jest poprawny Inner Hash."
      # The address is taken from the node itself after start (a typed one could be wrong).
      INNER_HASH=$REPLY; REWARDS_ADDRESS="" ;;
    *) die "Nieznany --key '$choice' (dozwolone: new, import)." ;;
  esac
  local shown=${REWARDS_ADDRESS:-}
  [[ -n $shown ]] || shown="(adres pokaże się w: $ME status, po starcie)"
  ok "Nagrody trafią na adres: $shown"
}

ensure_payout_address() {  # pool mode
  if [[ -n ${PAYOUT_ADDRESS:-} ]]; then
    valid_qz_address "$PAYOUT_ADDRESS" || die "Adres wypłat z puli (--payout-address) ma zły format."
    return 0
  fi
  (( ASSUME_YES )) && die "W trybie puli podaj --payout-address qz… (Twój adres, do którego masz frazę 24 słów)."
  echo "Pula wypłaca QTC zwykłym przelewem. Podaj SWÓJ adres qz…, do którego masz frazę 24 słów na papierze."
  echo "(NIE podawaj Inner Hash ani adresu, do którego nie masz frazy.)"
  ask "Adres wypłat qz…: " || die "Przerwano (brak odpowiedzi)."
  valid_qz_address "$REPLY" || die "To nie wygląda na adres Quantus (zaczyna się od qz…)."
  PAYOUT_ADDRESS=$REPLY
}

# ---------------------------------------------------------------------------------------------
# Command lines (pure — unit tested)
# ---------------------------------------------------------------------------------------------
build_node_args() {
  NODE_ARGS=(--chain mainnet --validator --name "$NODE_NAME" --base-path "$BASE_PATH"
             --node-key-file "$NODE_KEY" --rewards-inner-hash "$INNER_HASH"
             --miner-listen-port "$MINER_PORT" --max-blocks-per-request 64 --sync full)
  if [[ $TELEMETRY == no ]]; then NODE_ARGS+=(--no-telemetry); fi
}

build_miner_args() {
  MINER_ARGS=(serve --metrics-port "$METRICS_PORT")
  if [[ $MODE == pool ]]; then
    MINER_ARGS+=(--node-addr "$POOL_ADDR" --auth-token "$PAYOUT_ADDRESS.$WORKER_NAME" --tls-cert-sha256 "$POOL_FP")
  else
    MINER_ARGS+=(--node-addr "127.0.0.1:$MINER_PORT"
                 --auth-token-file "$CHAIN_DIR/miner-auth-token"
                 --tls-cert-sha256-file "$CHAIN_DIR/miner-tls-cert-sha256")
  fi
  if [[ $DEVICE == gpu ]]; then
    MINER_ARGS+=(--cuda-gpu --gpu-devices "$GPU_DEVICES" --cpu-workers 0)
  else
    MINER_ARGS+=(--cpu-workers "$CPU_WORKERS" --gpu-devices 0)
  fi
}

miner_nice() { if [[ $DEVICE == cpu ]]; then echo 5; else echo 0; fi; }

# ---------------------------------------------------------------------------------------------
# RPC / indexer helpers (no jq needed)
# ---------------------------------------------------------------------------------------------
rpc() {  # url method [params_json]
  curl -s --max-time 10 -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$2\",\"params\":${3:-[]}}" "$1" 2>/dev/null || true
}
# Tiny JSON field extractors for single-line RPC answers (first match; always exit 0).
json_num()  { sed -n "s/.*\"$1\":\([0-9][0-9]*\).*/\1/p" | sed -n 1p; }
json_bool() { sed -n "s/.*\"$1\":\(true\|false\).*/\1/p" | sed -n 1p; }
json_str()  { sed -n "s/.*\"$1\":\"\([^\"]*\)\".*/\1/p" | sed -n 1p; }
hex_to_dec() {
  local h=${1#0x}
  if [[ $h =~ ^[0-9a-fA-F]{1,15}$ ]]; then echo $(( 16#$h )); fi
}

le_hex_to_dec() {  # little-endian hex bytes (SCALE) → decimal (float precision)
  awk -v h="${1#0x}" 'BEGIN { d = "0123456789abcdef"; h = tolower(h); v = 0; m = 1
    for (i = 1; i <= length(h); i += 2) {
      b = (index(d, substr(h, i, 1)) - 1) * 16 + (index(d, substr(h, i + 1, 1)) - 1)
      v += b * m; m *= 256 }
    printf "%.0f\n", v }'
}

best_block() { local r; r=$(rpc "$1" chain_getHeader); hex_to_dec "$(json_str number <<<"$r")"; }

node_rpc_up() { [[ -n $(rpc "$QM_LOCAL_RPC" system_health) ]]; }

node_ready() {
  local h s peers syncing cur high
  h=$(rpc "$QM_LOCAL_RPC" system_health); [[ -n $h ]] || return 1
  peers=$(json_num peers <<<"$h"); syncing=$(json_bool isSyncing <<<"$h")
  [[ ${peers:-0} -ge 1 && ${syncing:-true} == false ]] || return 1
  s=$(rpc "$QM_LOCAL_RPC" system_syncState)
  cur=$(json_num currentBlock <<<"$s"); high=$(json_num highestBlock <<<"$s")
  [[ -n $cur && -n $high ]] || return 1
  (( cur + 2 >= high ))
}

node_genesis() { rpc "$QM_LOCAL_RPC" chain_getBlockHash '[0]' | json_str result; }

indexer_query() { curl -s --max-time 15 -H 'Content-Type: application/json' -H 'User-Agent: quantus-miner-kit' -d "$1" "$QM_INDEXER" 2>/dev/null || true; }

mined_blocks_of() {  # address → total_mined_blocks (0 = none yet; empty = indexer unreachable)
  local r n
  r=$(indexer_query "{\"query\":\"{ s: account_stats_by_pk(id: \\\"$1\\\") { total_mined_blocks } }\"}")
  n=$(json_num total_mined_blocks <<<"$r")
  if [[ -z $n && $r == *'"s":null'* ]]; then n=0; fi   # the indexer knows no block by this address yet
  echo "$n"
}

miner_hashrate_hs() {  # current hash rate from the miner's Prometheus endpoint (H/s)
  { curl -s --max-time 3 "http://127.0.0.1:$METRICS_PORT/metrics" 2>/dev/null || true; } \
    | awk '$1 == "miner_hash_rate" && !done { printf "%.0f\n", $2; done = 1 }'
}

# Rewards address as announced by the node itself ("⛏️ Rewards wormhole address: qz…").
rewards_address_from_log() {
  { grep -a 'Rewards wormhole address' "$NODE_LOG" 2>/dev/null || true; } \
    | sed -n 's/.*Rewards wormhole address:[[:space:]]*\(qz[1-9A-HJ-NP-Za-km-z]*\).*/\1/p' | tail -n 1
}

# ---------------------------------------------------------------------------------------------
# Process helpers
# ---------------------------------------------------------------------------------------------
pid_alive() { [[ -n ${1:-} ]] && kill -0 "$1" 2>/dev/null; }
read_pid()  { if [[ -f $1 ]]; then head -c 16 "$1" 2>/dev/null | tr -cd '0-9' || true; fi; }
pid_cmd_matches() { [[ -r /proc/$1/cmdline ]] && tr '\0' ' ' <"/proc/$1/cmdline" | grep -qF -- "$2"; }

supervisor_pid() {
  local p
  p=$(read_pid "$SUP_PID")
  if pid_alive "$p" && pid_cmd_matches "$p" "_supervise"; then echo "$p"; fi
}

rotate_if_big() {  # file maxMB — keeps the last 20 MB in <file>.1, truncates in place (O_APPEND safe)
  local f=$1 max=$(( $2 * 1024 * 1024 )) size
  [[ -f $f ]] || return 0
  size=$(stat -c %s "$f" 2>/dev/null || echo 0)
  if (( size > max )); then
    tail -c $(( 20 * 1024 * 1024 )) "$f" >"$f.1" 2>/dev/null || true
    : >"$f"
  fi
}

kill_wait() {  # pid seconds
  local p=$1 i
  pid_alive "$p" || return 0
  kill -TERM "$p" 2>/dev/null || true
  for ((i = 0; i < $2 * 2; i++)); do pid_alive "$p" || return 0; sleep 0.5; done
  kill -KILL "$p" 2>/dev/null || true
}

# ---------------------------------------------------------------------------------------------
# Supervisor: runs node (solo) + miner, starts the miner only when the node is synced,
# restarts whatever dies (with backoff). Used both in background mode and by systemd.
# ---------------------------------------------------------------------------------------------
SUP_NODE_PID=""; SUP_MINER_PID=""; SUP_SLEEP_PID=""
SUP_NODE_DELAY=$QM_RESTART_DELAY; SUP_MINER_DELAY=$QM_RESTART_DELAY; SUP_NODE_NEXT=0; SUP_MINER_NEXT=0
SUP_NODE_STARTED=0; SUP_MINER_STARTED=0; SUP_GENESIS_OK=0; SUP_WAIT_LOGGED=0

sup_shutdown() {
  slog "Zatrzymuję (sygnał)…"
  [[ -z ${SUP_SLEEP_PID:-} ]] || kill "$SUP_SLEEP_PID" 2>/dev/null || true
  kill_wait "$SUP_MINER_PID" 20
  kill_wait "$SUP_NODE_PID" 45
  rm -f "$MINER_PID_FILE" "$NODE_PID_FILE" "$SUP_PID"
  slog "Zatrzymano."
  exit 0
}

sup_backoff() {  # name started_at → sets new delay (resets after 10 min of healthy run)
  local now ran delay_var=$1
  now=$(date +%s); ran=$(( now - $2 ))
  if (( ran > 600 )); then printf -v "$delay_var" '%s' "$QM_RESTART_DELAY"
  else
    local cur=${!delay_var}
    printf -v "$delay_var" '%s' $(( cur * 2 > 300 ? 300 : cur * 2 ))
  fi
}

# Children are started as ONE simple command each (no subshell), so $! is the real process;
# 8>&- 9>&- keeps our lock descriptors out of the children (an orphan must not hold the lock).
sup_start_node() {
  rotate_if_big "$NODE_LOG" 200
  build_node_args
  slog "Start node'a: $NODE_BIN ${NODE_ARGS[*]}"
  "$NODE_BIN" "${NODE_ARGS[@]}" >>"$NODE_LOG" 2>&1 </dev/null 8>&- 9>&- &
  SUP_NODE_PID=$!; SUP_NODE_STARTED=$(date +%s)
  echo "$SUP_NODE_PID" >"$NODE_PID_FILE"
}

sup_start_miner() {
  rotate_if_big "$MINER_LOG" 100
  build_miner_args
  miner_env_prefix
  local nice_lvl
  nice_lvl=$(miner_nice)
  slog "Start minera: $MINER_BIN ${MINER_ARGS[*]}"
  "${MENV[@]}" nice -n "$nice_lvl" "$MINER_BIN" "${MINER_ARGS[@]}" >>"$MINER_LOG" 2>&1 </dev/null 8>&- 9>&- &
  SUP_MINER_PID=$!; SUP_MINER_STARTED=$(date +%s)
  echo "$SUP_MINER_PID" >"$MINER_PID_FILE"
}

sup_reap() {  # pid → prints its exit code (the child has already exited)
  local rc=0
  wait "$1" 2>/dev/null || rc=$?
  echo "$rc"
}

sup_tick() {
  local now
  now=$(date +%s)
  if [[ $MODE == solo ]]; then
    if ! pid_alive "$SUP_NODE_PID"; then
      if [[ -n $SUP_NODE_PID ]]; then
        local nrc
        nrc=$(sup_reap "$SUP_NODE_PID")
        sup_backoff SUP_NODE_DELAY "$SUP_NODE_STARTED"; SUP_NODE_NEXT=$(( now + SUP_NODE_DELAY )); SUP_NODE_PID=""
        slog "Node zakończył działanie (kod $nrc). Restart za ${SUP_NODE_DELAY}s. Ostatnie linie logu:"
        tail -n 5 "$NODE_LOG" 2>/dev/null | sed 's/^/    /'
        rm -f "$NODE_PID_FILE"
        # A rejected rewards key never fixes itself — restarting forever would only hide it.
        if tail -n 50 "$NODE_LOG" 2>/dev/null | grep -q 'not a canonical Poseidon digest'; then
          slog "BŁĄD: node odrzuca Inner Hash z ustawień (to nie jest poprawny klucz nagród). Zatrzymuję."
          slog "Ustaw klucz ponownie: $ME setup --key new   (albo --key import)"
          sup_shutdown
        fi
      fi
      if (( now >= SUP_NODE_NEXT )); then sup_start_node; fi
    elif (( ! SUP_GENESIS_OK )) && node_rpc_up; then
      local g
      g=$(node_genesis)
      if [[ -n $g ]]; then
        if [[ $g != "$MAINNET_GENESIS" ]]; then
          slog "BŁĄD: node jest na innym łańcuchu (genesis $g), a nie na mainnecie. Zatrzymuję."
          sup_shutdown
        fi
        SUP_GENESIS_OK=1; slog "Node na mainnecie (genesis OK)."
        local la
        la=$(rewards_address_from_log)
        if [[ -n $la ]]; then
          slog "Nagrody idą na adres (według node'a): $la"
          # A mistyped Inner Hash would silently pay an address nobody controls: stop instead.
          if [[ -n ${REWARDS_ADDRESS:-} && $la != "$REWARDS_ADDRESS" ]]; then
            slog "BŁĄD: node kopałby na adres $la, a oczekiwany adres nagród to $REWARDS_ADDRESS (literówka w Inner Hash?). Zatrzymuję."
            slog "Sprawdź Inner Hash i uruchom ponownie: $ME start --inner-hash 0x… --rewards-address qz…"
            sup_shutdown
          fi
        fi
      fi
    fi
  fi

  if ! pid_alive "$SUP_MINER_PID"; then
    if [[ -n $SUP_MINER_PID ]]; then
      local mrc
      mrc=$(sup_reap "$SUP_MINER_PID")
      sup_backoff SUP_MINER_DELAY "$SUP_MINER_STARTED"; SUP_MINER_NEXT=$(( now + SUP_MINER_DELAY )); SUP_MINER_PID=""
      slog "Miner zakończył działanie (kod $mrc). Restart za ${SUP_MINER_DELAY}s. Ostatnie linie logu:"
      tail -n 5 "$MINER_LOG" 2>/dev/null | sed 's/^/    /'
      rm -f "$MINER_PID_FILE"
    fi
    if (( now >= SUP_MINER_NEXT )); then
      if [[ $MODE == pool ]]; then
        sup_start_miner
      elif pid_alive "$SUP_NODE_PID" && (( SUP_GENESIS_OK )) && node_ready \
           && [[ -s $CHAIN_DIR/miner-auth-token && -s $CHAIN_DIR/miner-tls-cert-sha256 ]]; then
        slog "Node zsynchronizowany — uruchamiam minera."
        sup_start_miner; SUP_WAIT_LOGGED=0
      elif (( SUP_WAIT_LOGGED == 0 )); then
        slog "Czekam, aż node się zsynchronizuje (miner ruszy automatycznie)…"; SUP_WAIT_LOGGED=1
      fi
    fi
  fi
}

cmd_supervise() {
  # A long-running loop must survive transient failures (RPC timeouts, a child exiting),
  # so errexit/pipefail are off here; every step handles its own errors.
  set +e +o pipefail
  mkdir -p "$RUN_DIR" "$LOG_DIR"
  exec 9>"$RUN_DIR/supervisor.lock"
  flock -n 9 || { slog "Nadzorca już działa — kończę."; exit 0; }
  # Under systemd (INVOCATION_ID is set) stdout goes to journald; write to our own log file
  # instead, so `logs supervisor` and `status` work the same in both modes.
  if [[ -n ${INVOCATION_ID:-} ]]; then exec >>"$SUP_LOG" 2>&1; fi
  echo $$ >"$SUP_PID"
  trap sup_shutdown TERM INT HUP
  slog "Nadzorca $KIT_VERSION start (tryb $MODE, urządzenie $DEVICE)."
  local ticks=0
  while true; do
    sup_tick
    if (( ++ticks % 60 == 0 )); then rotate_if_big "$NODE_LOG" 200; rotate_if_big "$MINER_LOG" 100; rotate_if_big "$SUP_LOG" 20; fi
    # 9>&-: the sleep must not inherit the lock — an orphaned sleep would hold it for up to
    # QM_TICK seconds after stop, and a quick `restart` would then find "already running".
    sleep "$QM_TICK" 9>&- &
    SUP_SLEEP_PID=$!
    wait "$SUP_SLEEP_PID" || true
  done
}

# ---------------------------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------------------------
do_setup() {
  mkdir -p "$BIN_DIR" "$LOG_DIR" "$RUN_DIR"; chmod 700 "$QM_DIR"
  check_platform
  info "Tryb: ${C_BLD}$MODE${C_OFF}, urządzenie: ${C_BLD}$DEVICE${C_OFF}, katalog: $QM_DIR"
  is_wsl && info "Wykryto WSL2 (Windows). Zobacz w instrukcji, jak utrzymać WSL włączony."
  check_resources
  install_miner
  if [[ $DEVICE == gpu ]]; then
    check_nvidia_driver
    check_power_limit
    install_nvrtc
    gpu_selftest
  fi
  if [[ $MODE == solo ]]; then
    install_node
    ensure_node_key
    ensure_rewards_identity
  else
    resolve_pool
    ensure_payout_address
    warn "Pule są NIEOFICJALNE (Quantus ich nie weryfikował). Pula trzyma Twoje QTC do wypłaty."
  fi
  validate_settings
  save_config
  ok "Ustawienia zapisane: $CONF_FILE (chmod 600)"
}

setup_is_complete() {
  [[ -f $CONF_FILE ]] && binary_version_ok "$MINER_BIN" "$QM_MINER_VERSION_MATCH" || return 1
  if [[ $MODE == solo ]]; then
    binary_version_ok "$NODE_BIN" "$QM_NODE_VERSION_MATCH" && [[ -s $NODE_KEY ]] && valid_inner_hash "${INNER_HASH:-}" || return 1
  else
    [[ -n ${POOL_ADDR:-} && -n ${POOL_FP:-} ]] && valid_qz_address "${PAYOUT_ADDRESS:-}" || return 1
  fi
  if [[ $DEVICE == gpu ]]; then [[ -e $NVRTC_LIB/libnvrtc.so ]] || return 1; fi
  return 0
}

cmd_setup() { do_setup; }

conf_snapshot() { grep -v '^#' "$CONF_FILE" 2>/dev/null || true; }

# Installed unit == unit for the current settings? (the first line is only a timestamp)
unit_is_current() {
  local f=$QM_SYSTEMD_DIR/$SERVICE_NAME.service
  [[ -f $f ]] && cmp -s <(grep -v '^# Wygenerowane' "$f") <(systemd_unit | grep -v '^# Wygenerowane')
}

install_unit_file() {
  new_tmp_dir
  systemd_unit >"$TMP_DIR/unit"
  sudo install -m 644 "$TMP_DIR/unit" "$QM_SYSTEMD_DIR/$SERVICE_NAME.service"
  cleanup_tmp
  sudo systemctl daemon-reload
}

# The service runs a private copy of this script; refresh it when this file is newer/different.
refresh_kit_copy() {  # → true when the copy was (re)installed
  local self
  self=$(readlink -f "${BASH_SOURCE[0]}")
  [[ $self -ef $KIT_COPY ]] && return 1
  cmp -s "$self" "$KIT_COPY" && return 1
  mkdir -p "$BIN_DIR"
  install -m 755 "$self" "$KIT_COPY"
}

# A working NVIDIA card while mining on CPU = ~600x less hash rate; say so (once per start).
hint_unused_gpu() {
  [[ $DEVICE == cpu && -z ${CLI_SET[DEVICE]:-} ]] || return 0
  if has_nvidia_gpu; then
    info "Masz kartę NVIDIA, a kopiesz procesorem. Karta jest dużo szybsza: $ME start --device gpu"
  elif grep -qsx 0x10de /sys/bus/pci/devices/*/vendor 2>/dev/null; then
    warn "Widzę kartę NVIDIA, ale jej sterownik nie działa (nvidia-smi), więc kopię procesorem. Po instalacji sterownika: $ME start --device gpu"
  fi
}

cmd_start() {
  local before changed=0
  before=$(conf_snapshot)
  if ! setup_is_complete || (( ${#CLI_SET[@]} > 0 )) || [[ -n $KEY_MODE ]]; then do_setup; else check_platform; validate_settings; fi
  [[ $(conf_snapshot) == "$before" ]] || changed=1
  hint_unused_gpu
  if service_installed; then
    info "Usługa systemd jest zainstalowana — uruchamiam przez systemctl."
    if (( DRY_RUN )); then info "[dry-run] sudo systemctl start $SERVICE_NAME"; return 0; fi
    refresh_kit_copy && changed=1
    if ! unit_is_current; then info "Aktualizuję plik usługi (zmienione ustawienia)…"; install_unit_file; changed=1; fi
    if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
      if (( changed )); then
        sudo systemctl restart "$SERVICE_NAME" && ok "Usługa uruchomiona ponownie z nowymi ustawieniami."
      else
        ok "Usługa $SERVICE_NAME już działa."
      fi
    else
      sudo systemctl start "$SERVICE_NAME" && ok "Usługa $SERVICE_NAME uruchomiona."
    fi
    return 0
  fi
  if [[ -n $(supervisor_pid) ]]; then
    if (( ! changed )); then ok "Kopanie już działa."; cmd_status; return 0; fi
    if (( DRY_RUN )); then info "[dry-run] ustawienia się zmieniły: $ME stop, potem start"; return 0; fi
    info "Ustawienia się zmieniły — uruchamiam kopanie ponownie z nowymi…"
    cmd_stop
  fi
  check_clock
  check_ports
  local self
  self=$(readlink -f "${BASH_SOURCE[0]}")
  if (( DRY_RUN )); then
    if [[ $DEVICE == gpu && -n ${GPU_POWER_LIMIT:-} ]]; then
      info "[dry-run] sudo nvidia-smi -pm 1 && sudo nvidia-smi -pl $GPU_POWER_LIMIT"
    fi
    info "[dry-run] setsid nohup bash $self _supervise --dir $QM_DIR"
    return 0
  fi
  apply_power_limit
  setsid nohup bash "$self" _supervise --dir "$QM_DIR" >>"$SUP_LOG" 2>&1 </dev/null 8>&- 9>&- &
  local i
  for ((i = 0; i < 20; i++)); do [[ -n $(supervisor_pid) ]] && break; sleep 0.5; done
  [[ -n $(supervisor_pid) ]] || die "Nadzorca nie wystartował. Zobacz: $SUP_LOG"
  echo
  if is_wsl && ! has_systemd; then
    ok "${C_BLD}Wystartowano!${C_OFF} Działa w tle. NIE zamykaj wszystkich okien Ubuntu — to okno możesz zminimalizować."
  else
    ok "${C_BLD}Wystartowano!${C_OFF} Działa w tle (możesz zamknąć ten terminal)."
  fi
  if [[ $MODE == solo ]]; then
    info "Node synchronizuje łańcuch (zwykle od kilkunastu minut do kilku godzin). Miner włączy się SAM, gdy node dogoni sieć."
    info "Postęp: $ME status   (blok X / sieć Y — gdy liczby się zrównają, synchronizacja jest zakończona)"
    [[ -n ${REWARDS_ADDRESS:-} ]] && info "Twoje nagrody: $EXPLORER_ACCOUNT_URL/$REWARDS_ADDRESS"
  else
    info "Miner łączy się z pulą $POOL_NAME ($POOL_ADDR). Panel puli: $(pool_dashboard || echo '-')"
  fi
  info "Stan:  $ME status      Logi:  $ME logs      Stop:  $ME stop"
  if is_wsl && ! has_systemd; then
    warn "WSL: zamknięcie WSZYSTKICH okien Ubuntu może uśpić WSL i zatrzymać kopanie. Zostaw jedno okno otwarte (szczegóły w instrukcji)."
  fi
}

cmd_stop() {
  if service_installed && systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
    sudo systemctl stop "$SERVICE_NAME" && ok "Usługa zatrzymana."
    return 0
  fi
  local p
  p=$(supervisor_pid)
  if [[ -n $p ]]; then
    info "Zatrzymuję kopanie (to może potrwać do minuty)…"
    kill_wait "$p" 80
  fi
  # Leftovers (e.g. supervisor killed with -9): stop our own binaries only.
  for p in "$(read_pid "$MINER_PID_FILE")" "$(read_pid "$NODE_PID_FILE")"; do
    if pid_alive "$p" && { pid_cmd_matches "$p" "$MINER_BIN" || pid_cmd_matches "$p" "$NODE_BIN"; }; then kill_wait "$p" 45; fi
  done
  rm -f "$MINER_PID_FILE" "$NODE_PID_FILE" "$SUP_PID"
  ok "Zatrzymano."
}

fmt_rate() { awk -v h="${1:-0}" 'BEGIN { if (h >= 1e9) printf "%.2f GH/s", h/1e9; else if (h >= 1e6) printf "%.1f MH/s", h/1e6; else printf "%.0f kH/s", h/1e3 }'; }

cmd_status() {
  echo "${C_BLD}Quantus miner kit $KIT_VERSION — status ($(ts))${C_OFF}"
  echo "  Tryb: $MODE   Urządzenie: $DEVICE   Katalog: $QM_DIR"
  if service_installed; then
    local s
    s=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null || true)
    echo "  Usługa systemd: ${s:-?}"
  fi
  local sp np mp ready=0
  sp=$(supervisor_pid); np=$(read_pid "$NODE_PID_FILE"); mp=$(read_pid "$MINER_PID_FILE")
  # pid files can be stale (e.g. after `wsl --shutdown`): a pid only counts if it is OUR binary
  { pid_alive "$np" && pid_cmd_matches "$np" "$NODE_BIN"; } || np=""
  { pid_alive "$mp" && pid_cmd_matches "$mp" "$MINER_BIN"; } || mp=""
  if [[ -n $sp ]]; then echo "  Nadzorca: ${C_GRN}działa${C_OFF} (pid $sp)"; else echo "  Nadzorca: ${C_RED}nie działa${C_OFF}  → uruchom: $ME start"; fi
  if [[ $MODE == solo ]]; then
    if [[ -n $np ]]; then echo "  Node:  ${C_GRN}działa${C_OFF} (pid $np)"; else echo "  Node:  ${C_RED}nie działa${C_OFF}"; fi
    local h peers mine pub st
    h=$(rpc "$QM_LOCAL_RPC" system_health)
    if [[ -n $h ]]; then
      peers=$(json_num peers <<<"$h")
      mine=$(best_block "$QM_LOCAL_RPC"); pub=$(best_block "$QM_PUBLIC_RPC")
      # "done" only by the same test the supervisor uses (peers ≥ 1, not syncing, at the tip):
      # a node with 0 peers also reports isSyncing=false, even at block 0.
      if node_ready; then st="zakończona"; ready=1
      elif [[ ${peers:-0} == 0 ]]; then st="brak połączeń z siecią (peers: 0)"
      else st="w toku"; fi
      echo "  Łańcuch: blok ${mine:-?} / sieć ${pub:-?}   peers: ${peers:-0}   synchronizacja: $st"
    fi
  fi
  if [[ -n $mp ]]; then
    local hr
    hr=$(miner_hashrate_hs)
    echo "  Miner: ${C_GRN}działa${C_OFF} (pid $mp)   moc: $( [[ -n $hr ]] && fmt_rate "$hr" || echo 'n/d (rozgrzewa się)')"
  else
    local why="" crashes
    if [[ $MODE == solo && -n $sp ]]; then
      crashes=$({ tail -n 50 "$SUP_LOG" 2>/dev/null || true; } | grep -ac 'Miner zakończył działanie' || true)
      if (( ready && ${crashes:-0} > 0 )); then why=" (wyłącza się i jest uruchamiany ponownie — zobacz: $ME logs miner)"
      elif (( ready )); then why=" (node gotowy — miner ruszy za chwilę)"
      else why=" (czeka na synchronizację node'a)"; fi
    fi
    echo "  Miner: ${C_YEL}nie działa${C_OFF}$why"
  fi
  local addr=${REWARDS_ADDRESS:-} logaddr=""
  if [[ $MODE == solo ]]; then
    # The node's own announcement is authoritative: rewards go where ITS inner hash points.
    logaddr=$(rewards_address_from_log)
    if [[ -n $logaddr && -n $addr && $logaddr != "$addr" ]]; then
      echo "  ${C_YEL}Uwaga: node kopie na adres $logaddr, a w ustawieniach zapisano $addr (liczy się adres node'a).${C_OFF}"
    fi
    if [[ -n $logaddr ]]; then addr=$logaddr; fi
  fi
  if [[ $MODE == solo && -n $addr ]]; then
    local mb found
    mb=$(mined_blocks_of "$addr")
    found=$(grep -ac 'Successfully mined and submitted a new block' "$NODE_LOG" 2>/dev/null || true)
    echo "  Nagrody: $EXPLORER_ACCOUNT_URL/$addr"
    echo "  Wykopane bloki (łańcuch): ${mb:-? (brak odpowiedzi indeksatora)}   zgłoszone przez ten node (log): ${found:-0}"
  elif [[ $MODE == pool ]]; then
    echo "  Pula: $POOL_NAME ($POOL_ADDR)   wypłaty na: ${PAYOUT_ADDRESS:-?}   panel: $(pool_dashboard || echo '-')"
  fi
}

# Public part of the rewards key, for mining to the SAME address on a second computer
# (e.g. laptop + RTX 4090 PC): one phrase on paper, one address to watch.
cmd_rewards() {
  if [[ $MODE == pool ]]; then
    echo "Tryb puli: pula wypłaca na adres ${PAYOUT_ADDRESS:-?} (pula ${POOL_NAME:-?})."
    return 0
  fi
  [[ -n ${INNER_HASH:-} ]] || die "Brak klucza nagród w $CONF_FILE. Najpierw: $ME setup"
  local addr=${REWARDS_ADDRESS:-} shown
  [[ -n $addr ]] || addr=$(rewards_address_from_log)
  shown=$addr
  [[ -n $shown ]] || shown="? (pokaże się po pierwszym starcie node'a: $ME status)"
  echo "Klucz nagród z tego komputera (to NIE jest fraza — nie da się nim wydać monet):"
  echo "  Inner Hash:   $INNER_HASH"
  echo "  Adres nagród: $shown"
  echo
  echo "Na DRUGIM komputerze kopiesz na TEN SAM adres (bez drugiej frazy) poleceniem:"
  if [[ -n $addr ]]; then
    echo "  ./quantus-miner.sh start --inner-hash $INNER_HASH --rewards-address $addr"
  else
    echo "  ./quantus-miner.sh start --inner-hash $INNER_HASH"
  fi
  echo "(dopisz --device gpu na komputerze z kartą NVIDIA albo --device cpu na laptopie)"
  echo "Najwygodniej zapisz to do pliku ($ME rewards > moj-klucz-nagrod.txt) i przenieś go razem ze skryptem."
  echo "Z --rewards-address skrypt sam sprawdzi, że node kopie na dokładnie ten adres (chroni przed literówką)."
}

cmd_logs() {
  local files=()
  case ${LOG_TARGET:-all} in
    node) files=("$NODE_LOG") ;;
    miner) files=("$MINER_LOG") ;;
    supervisor) files=("$SUP_LOG") ;;
    all) files=("$SUP_LOG" "$NODE_LOG" "$MINER_LOG") ;;
    *) die "Nieznany log '$LOG_TARGET' (node|miner|supervisor)" ;;
  esac
  local f existing=()
  for f in "${files[@]}"; do [[ -f $f ]] && existing+=("$f"); done
  (( ${#existing[@]} )) || die "Brak logów w $LOG_DIR (czy kopanie było uruchomione?)."
  info "Ctrl+C kończy podgląd (kopanie działa dalej)."
  tail -n 40 -F "${existing[@]}"
}

cmd_benchmark() {
  install_miner
  local -a args=(benchmark --duration "$BENCH_DURATION")
  if [[ $DEVICE == gpu ]]; then
    check_nvidia_driver; install_nvrtc
    args+=(--cuda-gpu --gpu-devices "$GPU_DEVICES" --cpu-workers 0)
  else
    args+=(--cpu-workers "$CPU_WORKERS" --gpu-devices 0)
  fi
  info "Benchmark ${BENCH_DURATION}s: quantus-miner ${args[*]}"
  if [[ -n $(supervisor_pid) ]]; then warn "Kopanie działa w tle — wynik będzie zaniżony. Najlepiej najpierw: $ME stop"; fi
  miner_env_run "$MINER_BIN" "${args[@]}"
}

cmd_difficulty() {
  local url=$QM_PUBLIC_RPC d_hex d iss_hex iss top off ta tb ha hb bt hr bt_label
  # The public RPC always has the current tip. A local node that is still syncing would report
  # the difficulty of an OLD block (up to ~2000x lower) → wildly inflated earnings. The local node
  # is only a fallback, and only when it is fully synced and on mainnet.
  d_hex=$(rpc "$url" state_call '["QPoWApi_get_difficulty","0x"]' | json_str result)
  if [[ -z $d_hex ]] && node_ready && [[ $(node_genesis) == "$MAINNET_GENESIS" ]]; then
    url=$QM_LOCAL_RPC
    d_hex=$(rpc "$url" state_call '["QPoWApi_get_difficulty","0x"]' | json_str result)
  fi
  [[ -n $d_hex ]] || die "Nie udało się pobrać trudności ($QM_PUBLIC_RPC nie odpowiada, a lokalny node nie jest zsynchronizowany)."
  d=$(le_hex_to_dec "$d_hex")
  iss_hex=$(rpc "$url" state_getStorage "[\"$TOTAL_ISSUANCE_KEY\"]" | json_str result)
  iss=$(le_hex_to_dec "${iss_hex:-0x00}")
  top=$(indexer_query '{"query":"{ a: block(order_by:{height:desc}, limit:1){ height timestamp } b: block(order_by:{height:desc}, limit:1, offset:300){ height timestamp } }"}')
  off=$(tr '}' '\n' <<<"$top")
  ha=$(sed -n '1,/"b"/p' <<<"$off" | json_num height); ta=$(sed -n '1,/"b"/p' <<<"$off" | json_str timestamp)
  hb=$(sed -n '/"b"/,$p' <<<"$off" | json_num height);  tb=$(sed -n '/"b"/,$p' <<<"$off" | json_str timestamp)
  bt=12; bt_label="Czas bloku (brak danych z indeksatora — przyjęto cel 12)"
  if [[ -n $ha && -n $hb && -n $ta && -n $tb ]] && (( ha > hb )); then
    bt=$(awk -v a="$(date -u -d "$ta" +%s.%N)" -v b="$(date -u -d "$tb" +%s.%N)" -v n=$(( ha - hb )) 'BEGIN{printf "%.2f", (a-b)/n}')
    bt_label="Średni czas bloku (ostatnie $(( ha - hb )))"
  fi
  hr=""
  if [[ -n $HASHRATE_MHS ]]; then hr=$(awk -v m="$HASHRATE_MHS" 'BEGIN{printf "%.0f", m*1e6}')
  elif [[ -n $(read_pid "$MINER_PID_FILE") ]]; then hr=$(miner_hashrate_hs); fi
  awk -v D="$d" -v I="$iss" -v BT="$bt" -v BTL="$bt_label" -v HR="${hr:-0}" '
    function rate(h) { if (h >= 1e12) return sprintf("%.2f TH/s", h/1e12); if (h >= 1e9) return sprintf("%.2f GH/s", h/1e9); return sprintf("%.1f MH/s", h/1e6) }
    function row(name, h,   bpd, qpd, days) { bpd = h * 86400 / D; qpd = bpd * R; days = D / h / 86400
      printf "  %-31s %12s  %9s QTC/dzień  średnio 1 blok co %s\n", name, rate(h), (qpd < 0.01 ? sprintf("%.6f", qpd) : sprintf("%.4f", qpd)),
             (days < 1 ? sprintf("%.1f h", days*24) : (days < 730 ? sprintf("%.1f dni", days) : sprintf("%.0f dni (ok. %.1f roku)", days, days/365))) }
    BEGIN {
      supply = I / 1e12; R = (21000000 - supply) / 50000000; if (R <= 0 || I == 0) R = 0.3066
      printf "Trudność (D): %.4g  (= średnio tyle hashy na 1 blok)\n", D
      printf "%s: %s s   → moc sieci ≈ %s\n", BTL, BT, rate(D / BT)
      printf "Nagroda za blok ≈ %.4f QTC (+ opłaty)   bloków/dzień ≈ %.0f   emisja ≈ %.0f QTC/dzień\n", R, 86400 / BT, 86400 / BT * R
      print  "Szacunek dla SOLO (wartość oczekiwana; w praktyce bloki trafiają się losowo):"
      if (HR > 0) row("Twoja koparka", HR)
      row("CPU laptop (~1.7 MH/s, pomiar)", 1.67e6)
      row("RTX 4090 (~820 MH/s, CUDA)", 820e6)
      print  "W puli zarabiasz tyle samo średnio (minus prowizja), ale drobnymi, regularnymi kwotami."
    }'
}

systemd_unit() {  # prints the unit file for the current settings
  local user group
  user=$(id -un); group=$(id -gn)
  cat <<EOF
# Wygenerowane przez quantus-miner.sh $KIT_VERSION — $(ts)
[Unit]
Description=Quantus (QTC) mining kit — node + miner ($MODE, $DEVICE)
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=$user
Group=$group
Environment="HOME=$HOME"
WorkingDirectory=$QM_DIR
EOF
  if [[ $DEVICE == gpu && -n ${GPU_POWER_LIMIT:-} ]]; then
    # '+' = run as root, '-' = a refused limit must not stop mining (same as in background mode).
    echo "ExecStartPre=-+/usr/bin/nvidia-smi -pm 1"
    echo "ExecStartPre=-+/usr/bin/nvidia-smi -pl $GPU_POWER_LIMIT"
  fi
  cat <<EOF
ExecStart=/bin/bash "$KIT_COPY" _supervise --dir "$QM_DIR"
Restart=always
RestartSec=15
TimeoutStopSec=90
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
}

cmd_install_service() {
  if ! has_systemd; then
    err "systemd nie działa na tym systemie."
    if is_wsl; then
      cat >&2 <<'EOF'
W WSL włącz systemd:
  1) sudo nano /etc/wsl.conf   i dopisz:
       [boot]
       systemd=true
  2) W PowerShell (Windows):  wsl --shutdown
  3) Otwórz Ubuntu ponownie i uruchom:  ./quantus-miner.sh install-service
EOF
    fi
    exit 1
  fi
  setup_is_complete || do_setup
  if (( DRY_RUN )); then
    info "[dry-run] Tak wyglądałaby usługa $QM_SYSTEMD_DIR/$SERVICE_NAME.service (nic nie instaluję, niczego nie zatrzymuję):"
    systemd_unit
    return 0
  fi
  local sp self
  sp=$(supervisor_pid)
  if [[ -n $sp ]]; then info "Zatrzymuję kopanie w tle (przejmie je systemd)…"; cmd_stop; fi
  self=$(readlink -f "${BASH_SOURCE[0]}")
  mkdir -p "$BIN_DIR"
  # The service runs a private copy of this script (the original may live in Downloads/USB).
  if [[ ! $self -ef $KIT_COPY ]]; then install -m 755 "$self" "$KIT_COPY"; fi
  new_tmp_dir
  systemd_unit >"$TMP_DIR/unit"
  info "Instaluję usługę $SERVICE_NAME (wymaga sudo)…"
  sudo install -m 644 "$TMP_DIR/unit" "$QM_SYSTEMD_DIR/$SERVICE_NAME.service"
  cleanup_tmp
  sudo systemctl daemon-reload
  sudo systemctl enable --now "$SERVICE_NAME"
  if is_wsl; then
    ok "Usługa zainstalowana: kopanie ruszy SAMO przy każdym starcie WSL (np. po otwarciu okna Ubuntu)."
    warn "WSL: Windows może wyłączyć WSL po zamknięciu wszystkich okien Ubuntu — zostaw jedno okno otwarte."
  else
    ok "Usługa zainstalowana: kopanie ruszy SAMO po każdym włączeniu komputera."
  fi
  info "Stan: $ME status    Logi: $ME logs    (albo: systemctl status $SERVICE_NAME)"
}

cmd_remove_service() {
  service_installed || { info "Usługa nie jest zainstalowana."; return 0; }
  sudo systemctl disable --now "$SERVICE_NAME" || true
  sudo rm -f "$QM_SYSTEMD_DIR/$SERVICE_NAME.service"
  sudo systemctl daemon-reload
  ok "Usługa usunięta (pliki w $QM_DIR zostały)."
}

usage() {
  cat <<EOF
Quantus (QTC) — skrypt do kopania na MAINNECIE (wersja $KIT_VERSION)

Użycie:  $0 [polecenie] [opcje]      (uruchamiaj jako zwykły użytkownik, BEZ sudo)

Polecenia:
  start              (domyślne) pierwsza konfiguracja + start w tle; miner rusza sam po synchronizacji.
                     Z nowymi opcjami przy działającym kopaniu: zapisuje je i uruchamia kopanie ponownie.
  stop               zatrzymuje node i minera
  restart            stop + start
  status             stan: synchronizacja, moc (MH/s), wykopane bloki
  logs [node|miner|supervisor]   podgląd logów na żywo (Ctrl+C kończy podgląd, kopanie działa dalej)
  setup              tylko konfiguracja (pobranie programów, klucz nagród), bez startu
  benchmark          test mocy obliczeniowej (bez kopania)
  difficulty         aktualna trudność, moc sieci i szacowany zarobek
  rewards            Inner Hash i adres nagród + gotowe polecenie dla drugiego komputera
  install-service    autostart po włączeniu komputera (systemd; skrypt sam zapyta o hasło sudo)
  remove-service     usuwa autostart
  help               ta pomoc

Opcje:
  --device cpu|gpu           urządzenie (domyślnie: gpu, jeśli działa karta NVIDIA; inaczej cpu)
  --mode solo|pool           solo = własny node (domyślnie); pool = pula (nieoficjalna)
  --cpu-workers N            liczba wątków CPU (domyślnie: liczba wątków procesora minus 2, np. 14 → 12)
  --gpu-devices N            liczba kart NVIDIA (domyślnie 1)
  --gpu-power-limit W|off    limit mocy GPU w watach (np. 350; wymaga sudo); off = bez limitu
  --name NAZWA               nazwa node'a widoczna publicznie w telemetrii (litery, cyfry, _ -)
  --no-telemetry             nie wysyłaj danych node'a do publicznej telemetrii Quantus (mapa
                             telemetry.quantus.com: nazwa, wersja, sprzęt, przybliżona lokalizacja)
  --key new|import           solo: nowa fraza albo wpisanie istniejącej (bez pytania o wybór;
                             zmienia też już ustawiony klucz nagród — po potwierdzeniu)
  --inner-hash 0x…           solo: użyj gotowego Inner Hash (np. z polecenia rewards na innym komputerze)
  --rewards-address qz…      solo: oczekiwany adres nagród — node musi kopać dokładnie na niego
  --pool nurserypool|quanpool|custom   pula (domyślnie nurserypool)
  --pool-addr IP:PORT        dla --pool custom
  --pool-fp HEX64            odcisk TLS puli (dla --pool custom)
  --payout-address qz…       pool: Twój adres do wypłat (taki, do którego masz frazę)
  --worker NAZWA             pool: nazwa koparki (domyślnie nazwa komputera)
  --metrics-port PORT        port metryk minera (domyślnie 9900)
  --duration S               czas benchmarku w sekundach (domyślnie 30)
  --hashrate MH              difficulty: policz zarobek dla podanej mocy (MH/s)
  --dir ŚCIEŻKA              katalog na programy, logi i ustawienia (domyślnie ~/quantus-miner-kit);
                             jeśli go zmienisz, podawaj --dir przy KAŻDYM poleceniu
  --base-path ŚCIEŻKA        dane łańcucha (domyślnie ~/.local/share/quantus-node)
  --yes                      nie zadawaj pytań (do automatyzacji). Nowej frazy i tak nie pominie:
                             ją trzeba przepisać na papier (do automatyzacji użyj --inner-hash)
  --dry-run                  pokaż, co zostałoby uruchomione (bez startu)

Przykłady:
  $0                                   # CPU/GPU wykryte automatycznie, solo
  $0 start --device gpu --gpu-power-limit 350
  $0 start --mode pool --pool nurserypool --payout-address qzTwojAdres...
  $0 status
EOF
}

# ---------------------------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------------------------
set_cli() { printf -v "$1" '%s' "$2"; CLI_SET[$1]=1; }

need_val() { [[ $# -ge 2 && -n $2 && $2 != --* ]] || die "Opcja $1 wymaga wartości."; }

parse_args() {
  COMMAND=""
  while (( $# )); do
    case $1 in
      --device) need_val "$@"; set_cli DEVICE "$2"; shift ;;
      --mode) need_val "$@"; set_cli MODE "$2"; shift ;;
      --cpu-workers) need_val "$@"; set_cli CPU_WORKERS "$2"; shift ;;
      --gpu-devices) need_val "$@"; set_cli GPU_DEVICES "$2"; shift ;;
      --gpu-power-limit) need_val "$@"                    # "off" (or 0) removes the limit
             if [[ ${2,,} == off || $2 == 0 ]]; then set_cli GPU_POWER_LIMIT ""; else set_cli GPU_POWER_LIMIT "$2"; fi
             shift ;;
      --name) need_val "$@"; set_cli NODE_NAME "$2"; shift ;;
      --no-telemetry) set_cli TELEMETRY no ;;
      --key) need_val "$@"; [[ $2 == new || $2 == import ]] || die "Nieznany --key '$2' (dozwolone: new, import)."
             KEY_MODE=$2; shift ;;
      --inner-hash) need_val "$@"; set_cli INNER_HASH "$2"
             # a new hash invalidates the saved address — unless --rewards-address gives the expected one
             if (( ! REWARDS_ADDRESS_GIVEN )); then CLI_SET[REWARDS_ADDRESS]=1; REWARDS_ADDRESS=""; fi
             shift ;;
      --rewards-address) need_val "$@"; set_cli REWARDS_ADDRESS "$2"; REWARDS_ADDRESS_GIVEN=1; shift ;;
      --pool) need_val "$@"; set_cli POOL_NAME "$2"; set_cli MODE pool; shift ;;
      --pool-addr) need_val "$@"; set_cli POOL_ADDR "$2"; shift ;;
      --pool-fp) need_val "$@"; set_cli POOL_FP "${2,,}"; shift ;;
      --payout-address) need_val "$@"; set_cli PAYOUT_ADDRESS "$2"; shift ;;
      --worker) need_val "$@"; set_cli WORKER_NAME "$2"; shift ;;
      --metrics-port) need_val "$@"; set_cli METRICS_PORT "$2"; shift ;;
      --base-path) need_val "$@"; set_cli BASE_PATH "$2"; shift ;;
      --dir) need_val "$@"; QM_DIR=$2; shift ;;
      --duration) need_val "$@"; is_uint "$2" || die "--duration musi być liczbą sekund"; BENCH_DURATION=$2; shift ;;
      --hashrate) need_val "$@"; [[ $2 =~ ^[0-9]+([.][0-9]+)?$ ]] || die "--hashrate podaj w MH/s, np. 820"; HASHRATE_MHS=$2; shift ;;
      --yes|-y) ASSUME_YES=1 ;;
      --dry-run) DRY_RUN=1 ;;
      --allow-root) ALLOW_ROOT=1 ;;
      -h|--help) COMMAND=help ;;
      -*) die "Nieznana opcja: $1 (zobacz: $0 help)" ;;
      *)
        if [[ -z $COMMAND ]]; then COMMAND=$1
        elif [[ $COMMAND == logs && -z $LOG_TARGET ]]; then LOG_TARGET=$1
        else die "Nieoczekiwany argument: $1"; fi ;;
    esac
    shift
  done
  : "${COMMAND:=start}"
}

main() {
  set -Eeuo pipefail
  trap cleanup_tmp EXIT
  parse_args "$@"
  [[ $COMMAND == help ]] && { usage; return 0; }
  # As root (e.g. `sudo ./quantus-miner.sh install-service`) the unit would run node+miner as
  # root and leave root-owned files behind. The script asks for sudo itself where needed.
  if [[ $EUID -eq 0 && $ALLOW_ROOT -ne 1 ]]; then
    die "Nie uruchamiaj jako root ani przez sudo. Uruchom jako zwykły użytkownik — skrypt sam poprosi o sudo, gdy trzeba."
  fi
  set_paths
  load_config
  apply_defaults
  # stop/status/logs/remove-service must work even with a broken mining.conf (e.g. edited by
  # hand while mining runs) — they only need the pid files, so problems are just a warning there.
  local lenient=0 problems
  case $COMMAND in stop|status|logs|remove-service|difficulty|rewards) lenient=1 ;; esac
  if (( ! lenient )) && [[ $MODE == pool && $COMMAND != _supervise ]] \
     && { [[ -n ${CLI_SET[POOL_NAME]:-} || -n ${CLI_SET[MODE]:-} || -z ${POOL_ADDR:-} ]]; }; then
    resolve_pool
  fi
  problems=$(settings_problems)
  if [[ -n $problems ]]; then
    if (( lenient )); then warn "Błędne ustawienia w $CONF_FILE (popraw je przed następnym startem):"$'\n'"$problems"
    else die "Błędne ustawienia:"$'\n'"$problems"; fi
  fi
  case $COMMAND in
    start) mkdir -p "$QM_DIR"; exec 8>"$QM_DIR/.start.lock"; flock -n 8 || die "Inny start jest w toku."; cmd_start ;;
    stop) cmd_stop ;;
    restart) cmd_stop; cmd_start ;;
    status) cmd_status ;;
    logs) cmd_logs ;;
    setup) cmd_setup ;;
    benchmark) cmd_benchmark ;;
    difficulty) cmd_difficulty ;;
    install-service) cmd_install_service ;;
    remove-service) cmd_remove_service ;;
    rewards) cmd_rewards ;;
    _supervise) [[ -f $CONF_FILE ]] || die "Brak konfiguracji ($CONF_FILE). Uruchom najpierw: $ME setup"; cmd_supervise ;;
    *) die "Nieznane polecenie: $COMMAND (zobacz: $0 help)" ;;
  esac
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
