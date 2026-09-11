#!/usr/bin/env bats
# Unit tests for quantus-miner.sh: the script is SOURCED (main does not run) and its pure
# functions are called directly, under the same `set -u -o pipefail` strictness as main().

load helpers

setup() {
  qm_sandbox
  qm_source
  set -uo pipefail
}

# A complete, valid settings set (what apply_defaults + a finished setup would produce).
baseline() {
  DEVICE=cpu MODE=solo TELEMETRY=yes NODE_NAME=qtc-1a2b3c4d CPU_WORKERS=12 GPU_DEVICES=1
  BASE_PATH="$HOME/.local/share/quantus-node" METRICS_PORT=9900 GPU_POWER_LIMIT="" WORKER_NAME=rig1
  INNER_HASH=$FAKE_INNER REWARDS_ADDRESS=$FAKE_ADDRESS POOL_NAME=nurserypool POOL_ADDR="" POOL_FP=""
  PAYOUT_ADDRESS=""
  set_chain_dir
}

lines() { printf '%s\n' "$@"; }

# ---------------------------------------------------------------------------------------------
# Packaging / sourcing
# ---------------------------------------------------------------------------------------------
@test "packaging: bash -n accepts the script" {
  bash -n "$QM_SCRIPT"
}

@test "packaging: quantus-miner.sh is executable, so './quantus-miner.sh start' from the guide works" {
  [ -x "$QM_SCRIPT" ] || { echo "mode is $(stat -c %A "$QM_SCRIPT"): ./quantus-miner.sh → Permission denied" >&2; false; }
}

@test "sourcing: main does not run and nothing is created when the script is sourced" {
  run bash -c 'source "$1"; echo "sourced ok"' _ "$QM_SCRIPT"
  assert_status 0
  assert_equal "$output" "sourced ok"
  [ ! -e "$QM_DIR" ]
}

@test "sourcing: CLI_SET stays a global associative array when sourced from inside a function" {
  # Test harnesses (bats setup, wrappers) source from a function; the top-level `declare -A`
  # then creates a function-local array and parse_args later fails on --pool-addr 1.2.3.4:5.
  run bash -c 'load() { source "$1"; }; load "$1"; parse_args start --pool-addr 1.2.3.4:5555 && declare -p CLI_SET' _ "$QM_SCRIPT"
  assert_status 0
  assert_contains "$output" 'declare -A CLI_SET'
}

# ---------------------------------------------------------------------------------------------
# Validators
# ---------------------------------------------------------------------------------------------
@test "valid_inner_hash: 0x + exactly 64 hex characters" {
  assert_accepts valid_inner_hash "$FAKE_INNER" "0x$(printf 'AB%.0s' {1..32})" "0x$(printf '0%.0s' {1..64})"
  assert_rejects valid_inner_hash "" "0x" "${FAKE_INNER:0:65}" "${FAKE_INNER}0" "${FAKE_INNER#0x}" \
    "0X${FAKE_INNER#0x}" "0x$(printf 'g%.0s' {1..64})" " $FAKE_INNER" "$FAKE_INNER " "$FAKE_ADDRESS"
}

@test "valid_qz_address: qz + 44..52 base58 characters (real 49-char addresses pass)" {
  assert_accepts valid_qz_address "$FAKE_ADDRESS" "$PAYOUT_ADDRESS_OK" \
    "qzowWAgbzjc2XfHY4vyEo2eVLKbknTESUFoXnisQuUh1x1koo" "qz$(printf 'a%.0s' {1..44})" "qz$(printf 'a%.0s' {1..52})"
  assert_rejects valid_qz_address "" "qz" "qz$(printf 'a%.0s' {1..43})" "qz$(printf 'a%.0s' {1..53})" \
    "qa${FAKE_ADDRESS#qz}" "QZ${FAKE_ADDRESS#qz}" "${FAKE_ADDRESS:0:48}0" "${FAKE_ADDRESS:0:48}O" \
    "${FAKE_ADDRESS:0:48}I" "${FAKE_ADDRESS:0:48}l" "$FAKE_ADDRESS " "$FAKE_INNER"
}

@test "valid_tls_fp: exactly 64 lower-case hex characters (63/65 chars and upper case rejected)" {
  assert_accepts valid_tls_fp "$NURSERY_FP" "$QUANPOOL_FP" "$FAKE_TLS_FP"
  assert_rejects valid_tls_fp "" "${NURSERY_FP:0:63}" "${NURSERY_FP}a" "${NURSERY_FP^^}" "0x${NURSERY_FP:2}" \
    "${NURSERY_FP:0:63}g" "${NURSERY_FP:0:32} ${NURSERY_FP:32:31}"
}

@test "valid_ipv4_port: IPv4 literal + port; octets > 255, bad ports and host names rejected" {
  assert_accepts valid_ipv4_port "$NURSERY_ADDR" "$QUANPOOL_ADDR" "127.0.0.1:9833" "0.0.0.0:1" \
    "255.255.255.255:65535"
  assert_rejects valid_ipv4_port "" "162.19.84.16" "162.19.84.16:" "256.1.1.1:2255" "1.256.1.1:2255" \
    "1.1.1.300:2255" "999.999.999.999:1" "1.2.3.4:0" "1.2.3.4:65536" "1.2.3.4:123456" "1.2.3:2255" \
    "1.2.3.4.5:2255" "quan.nurserypool.com:2255" "localhost:9833" "pool.ariabrain.com:9834" \
    "[::1]:9833" " 1.2.3.4:5" "1.2.3.4:5 " "1.2.3.4:-5"
}

@test "valid_node_name / valid_worker_name: safe names only, no dots (the node refuses '.' and '@')" {
  assert_accepts valid_node_name "qtc-1a2b3c4d" "a" "My-Node_1-x" "$(printf 'n%.0s' {1..32})"
  # shellcheck disable=SC2016   # literal $(id) on purpose
  assert_rejects valid_node_name "" "-bad" ".bad" "_bad" "a b" "$(printf 'n%.0s' {1..33})" 'x$(id)' "x;y" \
    "My.Node" "rig@home"
  assert_accepts valid_worker_name "rig1" "Laptop_2" "a-b" "$(printf 'w%.0s' {1..32})"
  assert_rejects valid_worker_name "" "rig.1" "-rig" "rig 1" "$(printf 'w%.0s' {1..33})" "r/g"
}

@test "valid_device / valid_mode / valid_yesno: fixed vocabularies" {
  assert_accepts valid_device cpu gpu
  assert_rejects valid_device "" CPU cuda "gpu "
  assert_accepts valid_mode solo pool
  assert_rejects valid_mode "" SOLO pooled
  assert_accepts valid_yesno yes no
  assert_rejects valid_yesno "" y n true 1
}

@test "numeric validators: is_uint, ports 1024..65535, power 100..600 or empty, workers, gpu count" {
  assert_accepts is_uint 0 7 0012 99999999
  assert_rejects is_uint "" -1 1.5 "1 " abc
  assert_accepts valid_port 1024 9900 65535
  assert_rejects valid_port "" 80 1023 65536 99999 -9900 9900x
  assert_accepts valid_power_limit "" 100 350 600
  assert_rejects valid_power_limit 99 601 350W -350 " "
  assert_accepts valid_cpu_workers 1 12 1024
  assert_rejects valid_cpu_workers "" 0 1025 -1 auto
  assert_accepts valid_gpu_devices 1 16
  assert_rejects valid_gpu_devices "" 0 17 all
}

@test "valid_abs_path: absolute, no '..', no newline" {
  assert_accepts valid_abs_path "/" "/home/u/.local/share/quantus-node" "/data/with space/x"
  # shellcheck disable=SC2088   # literal ~ on purpose (must be rejected)
  assert_rejects valid_abs_path "" "relative/path" "~/x" "/a/../b" "/a/.." $'/a\nb'
}

@test "version_ge: numeric per-component comparison" {
  version_ge 2.39 2.38
  version_ge 2.38 2.38
  version_ge 12.8 12.1
  version_ge 12.10 12.8
  version_ge 1.0.1 1.0
  version_ge 580.82.07 570
  version_ge 570 570.0.0
  run version_ge 2.37 2.38;  [ "$status" -ne 0 ]
  run version_ge 12.0 12.1;  [ "$status" -ne 0 ]
  run version_ge 1.0 1.0.1;  [ "$status" -ne 0 ]
  run version_ge 12.8 12.10; [ "$status" -ne 0 ]
  run version_ge 565.57.01 570; [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------------------------
# Pools
# ---------------------------------------------------------------------------------------------
@test "pool_preset: nurserypool and quanpool presets, unknown names fail" {
  assert_equal "$(pool_preset nurserypool)" "$NURSERY_ADDR $NURSERY_FP https://quan.nurserypool.com"
  assert_equal "$(pool_preset quanpool)" "$QUANPOOL_ADDR $QUANPOOL_FP https://quanpool.com"
  run pool_preset ariapool; [ "$status" -ne 0 ]
  run pool_preset custom;   [ "$status" -ne 0 ]
  run pool_preset "";       [ "$status" -ne 0 ]
}

@test "resolve_pool: presets fill address + fingerprint" {
  baseline; MODE=pool POOL_NAME=quanpool
  resolve_pool
  assert_equal "$POOL_ADDR" "$QUANPOOL_ADDR"
  assert_equal "$POOL_FP" "$QUANPOOL_FP"
  assert_equal "$(pool_dashboard)" "https://quanpool.com"
}

@test "resolve_pool: an explicit --pool-addr/--pool-fp wins over the preset" {
  baseline; MODE=pool
  parse_args start --pool nurserypool --pool-addr 10.1.2.3:4444
  resolve_pool
  assert_equal "$POOL_ADDR" "10.1.2.3:4444"
  assert_equal "$POOL_FP" "$NURSERY_FP"
}

@test "resolve_pool: custom pool needs both a valid IP:port and a 64-hex fingerprint" {
  baseline; MODE=pool POOL_NAME=custom POOL_ADDR=10.20.30.40:7777 POOL_FP=$QUANPOOL_FP
  resolve_pool
  assert_equal "$POOL_ADDR" "10.20.30.40:7777"
  assert_equal "$(pool_dashboard)" "-"

  POOL_FP=""
  run resolve_pool
  assert_status 1
  assert_contains "$output" "Dla --pool custom podaj --pool-addr IP:PORT i --pool-fp"

  POOL_FP=$QUANPOOL_FP POOL_ADDR=""
  run resolve_pool
  assert_status 1
  assert_contains "$output" "Dla --pool custom podaj --pool-addr IP:PORT i --pool-fp"

  POOL_ADDR=pool.example.com:7777
  run resolve_pool
  assert_status 1
  assert_contains "$output" "--pool-addr musi być adresem IP:port"

  POOL_ADDR=10.20.30.40:7777 POOL_FP=${QUANPOOL_FP:0:63}
  run resolve_pool
  assert_status 1
  assert_contains "$output" "--pool-fp musi mieć dokładnie 64 znaki hex"
}

@test "resolve_pool: unknown pool name is rejected with the list of choices" {
  baseline; MODE=pool POOL_NAME=ariapool
  run resolve_pool
  assert_status 1
  assert_contains "$output" "Nieznana pula 'ariapool'. Dostępne: nurserypool, quanpool, custom."
}

# ---------------------------------------------------------------------------------------------
# Configuration file
# ---------------------------------------------------------------------------------------------
@test "save_config/load_config: round trip keeps every key; file 600, dir 700" {
  DEVICE=gpu MODE=pool NODE_NAME=qtc-abc TELEMETRY=no INNER_HASH=$FAKE_INNER REWARDS_ADDRESS=$FAKE_ADDRESS
  CPU_WORKERS=7 GPU_DEVICES=2 POOL_NAME=quanpool POOL_ADDR=$QUANPOOL_ADDR POOL_FP=$QUANPOOL_FP
  PAYOUT_ADDRESS=$PAYOUT_ADDRESS_OK WORKER_NAME=rig_7 BASE_PATH="/data/quantus chain" METRICS_PORT=9911
  GPU_POWER_LIMIT=350
  save_config
  assert_equal "$(stat -c %a "$CONF_FILE")" 600
  assert_equal "$(stat -c %a "$QM_DIR")" 700
  local k
  local -A saved=()
  for k in "${CONF_KEYS[@]}"; do saved[$k]=${!k}; unset "$k"; done
  load_config
  for k in "${CONF_KEYS[@]}"; do assert_equal "$k=${!k-<unset>}" "$k=${saved[$k]}"; done
  [ -z "$(find "$QM_DIR" -name '.mining.conf.*')" ]   # no temp file left behind
}

@test "load_config: values are data — \$(…), backticks and ';' are never executed" {
  mkdir -p "$QM_DIR"
  cat >"$CONF_FILE" <<EOF
NODE_NAME=\$(touch $QM_SANDBOX/pwned1)
WORKER_NAME=\`touch $QM_SANDBOX/pwned2\`
BASE_PATH=/tmp/x; touch $QM_SANDBOX/pwned3
DEVICE="\$(touch $QM_SANDBOX/pwned4)"
EOF
  load_config
  [ ! -e "$QM_SANDBOX/pwned1" ]
  [ ! -e "$QM_SANDBOX/pwned2" ]
  [ ! -e "$QM_SANDBOX/pwned3" ]
  [ ! -e "$QM_SANDBOX/pwned4" ]
  assert_equal "$NODE_NAME" "\$(touch $QM_SANDBOX/pwned1)"
  assert_equal "$WORKER_NAME" "\`touch $QM_SANDBOX/pwned2\`"
  assert_equal "$BASE_PATH" "/tmp/x; touch $QM_SANDBOX/pwned3"
  assert_equal "$DEVICE" "\$(touch $QM_SANDBOX/pwned4)"
  # …and validation refuses them (settings_problems only echoes the text)
  MODE=solo TELEMETRY=yes CPU_WORKERS=1 GPU_DEVICES=1 METRICS_PORT=9900
  local p
  p=$(settings_problems)
  assert_contains "$p" "DEVICE musi być cpu albo gpu"
  assert_contains "$p" "Nazwa node'a"
  assert_contains "$p" "Nazwa koparki"
  [ ! -e "$QM_SANDBOX/pwned1" ]
  [ ! -e "$QM_SANDBOX/pwned4" ]
}

@test "load_config: unknown keys, comments, lower-case keys and garbage lines are ignored" {
  mkdir -p "$QM_DIR"
  cat >"$CONF_FILE" <<EOF
# comment
   # indented comment

PATH=/tmp/evil
QM_DIR=/tmp/evil
LD_PRELOAD=/tmp/evil.so
device=gpu
EVIL=1
export MODE=pool
MODE=solo
DEVICE="cpu"
CPU_WORKERS=5
EOF
  local path_before=$PATH
  load_config
  assert_equal "$PATH" "$path_before"
  refute_contains "$QM_DIR" "/tmp/evil"
  [ -z "${LD_PRELOAD:-}" ]
  [ -z "${EVIL:-}" ]
  assert_equal "$MODE" solo
  assert_equal "$DEVICE" cpu          # surrounding quotes stripped
  assert_equal "$CPU_WORKERS" 5
}

@test "load_config: command-line values win over the saved file" {
  mkdir -p "$QM_DIR"
  printf '%s\n' DEVICE=cpu CPU_WORKERS=9 MODE=solo METRICS_PORT=9911 "INNER_HASH=$IMPORT_INNER" \
    "REWARDS_ADDRESS=$IMPORT_ADDRESS" >"$CONF_FILE"
  parse_args start --device gpu --cpu-workers 3 --inner-hash "$FAKE_INNER"
  load_config
  assert_equal "$DEVICE" gpu
  assert_equal "$CPU_WORKERS" 3
  assert_equal "$MODE" solo          # not on the command line → from the file
  assert_equal "$METRICS_PORT" 9911
  assert_equal "$INNER_HASH" "$FAKE_INNER"
  assert_equal "$REWARDS_ADDRESS" ""  # the old address belongs to the old inner hash
}

@test "load_config: missing file is fine" {
  load_config
  [ ! -e "$CONF_FILE" ]
}

# ---------------------------------------------------------------------------------------------
# Defaults and validation
# ---------------------------------------------------------------------------------------------
@test "apply_defaults: CPU workers = nproc - 2, minimum 1" {
  local n want
  for n in 14 8 4 3 2 1; do
    eval "nproc() { echo $n; }"      # literal value: apply_defaults has its own local \$n
    unset CPU_WORKERS
    apply_defaults
    want=$(( n - 2 )); (( want >= 1 )) || want=1
    assert_equal "nproc=$n → $CPU_WORKERS" "nproc=$n → $want"
  done
  CPU_WORKERS=5
  apply_defaults
  assert_equal "$CPU_WORKERS" 5
}

@test "apply_defaults: solo/cpu defaults, random valid node name, chain dir under the base path" {
  apply_defaults
  assert_equal "$MODE" solo
  assert_equal "$DEVICE" cpu               # nvidia-smi stub: no GPU
  assert_equal "$TELEMETRY" yes
  assert_equal "$BASE_PATH" "$HOME/.local/share/quantus-node"
  assert_equal "$CHAIN_DIR" "$HOME/.local/share/quantus-node/chains/mainnet"
  assert_equal "$METRICS_PORT" 9900
  assert_equal "$GPU_DEVICES" 1
  assert_equal "$POOL_NAME" nurserypool
  valid_node_name "$NODE_NAME"
  [[ $NODE_NAME =~ ^qtc-[0-9a-f]{8}$ ]]
  valid_worker_name "$WORKER_NAME"
  [ -z "$(settings_problems)" ]
}

@test "apply_defaults: DEVICE=gpu when nvidia-smi lists an NVIDIA GPU" {
  fake_gpu 580.82.07
  apply_defaults
  assert_equal "$DEVICE" gpu
}

@test "settings_problems: a valid set produces no output" {
  baseline
  assert_equal "$(settings_problems)" ""
  MODE=pool POOL_ADDR=$NURSERY_ADDR POOL_FP=$NURSERY_FP PAYOUT_ADDRESS=$PAYOUT_ADDRESS_OK
  assert_equal "$(settings_problems)" ""
}

@test "settings_problems: every invalid field is reported" {
  baseline
  DEVICE=tpu MODE=party TELEMETRY=maybe NODE_NAME="bad name" CPU_WORKERS=0 GPU_DEVICES=99
  BASE_PATH=relative METRICS_PORT=80 GPU_POWER_LIMIT=900 WORKER_NAME=".x" INNER_HASH=0x12 REWARDS_ADDRESS=qzBAD
  local p
  p=$(settings_problems)
  assert_contains "$p" "DEVICE musi być cpu albo gpu (jest: 'tpu')"
  assert_contains "$p" "MODE musi być solo albo pool (jest: 'party')"
  assert_contains "$p" "TELEMETRY musi być yes albo no"
  assert_contains "$p" "Nazwa node'a"
  assert_contains "$p" "CPU_WORKERS musi być liczbą 1..1024"
  assert_contains "$p" "GPU_DEVICES musi być liczbą 1..16"
  assert_contains "$p" "BASE_PATH musi być ścieżką absolutną"
  assert_contains "$p" "METRICS_PORT musi być portem 1024..65535"
  assert_contains "$p" "GPU_POWER_LIMIT musi być liczbą 100..600"
  assert_contains "$p" "Nazwa koparki (worker)"
  assert_contains "$p" "INNER_HASH musi mieć postać 0x + 64 znaki hex"
  assert_contains "$p" "REWARDS_ADDRESS wygląda na błędny adres"
  assert_equal "$(wc -l <<<"$p" | tr -d ' ')" 12
}

@test "settings_problems: pool fields are checked in solo mode too (every saved value must be clean)" {
  baseline
  POOL_ADDR=quan.nurserypool.com:2255 POOL_FP=ABC PAYOUT_ADDRESS=nope
  local p mode
  for mode in solo pool; do
    MODE=$mode
    p=$(settings_problems)
    assert_contains "$p" "POOL_ADDR musi być adresem IP:port (miner nie przyjmuje nazw domen)"
    assert_contains "$p" "POOL_FP musi mieć dokładnie 64 znaki hex"
    assert_contains "$p" "Adres wypłat z puli wygląda na błędny adres"
  done
  baseline
  PAYOUT_ADDRESS="$(printf 'qzjunk\nINNER_HASH=0xbad')"
  assert_contains "$(settings_problems)" "Adres wypłat z puli wygląda na błędny adres"
  POOL_NAME="nursery pool"
  assert_contains "$(settings_problems)" "POOL_NAME"
}

@test "save_config: refuses a value with a line break (it would inject another KEY=value line)" {
  baseline
  WORKER_NAME=$'rig1\nINNER_HASH=0xbad'
  run save_config
  assert_status 1
  assert_contains "$output" "Wartość WORKER_NAME zawiera znak nowej linii"
  [ ! -e "$CONF_FILE" ]
}

# ---------------------------------------------------------------------------------------------
# Key output parsing (quantus-node v1.0.1 format, node/src/command.rs)
# ---------------------------------------------------------------------------------------------
@test "parse_key_output: fresh 'key quantus --scheme wormhole' output" {
  local out
  out=$(lines "Deriving wormhole HD path: m/44'/189189189'/0'/0'/0'" "Generating wormhole address..." \
    "XXXXXXXXXXXXXXX Quantus Wormhole Details XXXXXXXXXXXXXXXXX" "Secret phrase: $FAKE_PHRASE" \
    "Account index: 0" "Derivation path: m/44'/189189189'/0'/0'/0'" "Address: $FAKE_ADDRESS" \
    "Inner Hash: $FAKE_INNER" "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
  parse_key_output <<<"$out"
  assert_equal "$PARSED_ADDRESS" "$FAKE_ADDRESS"
  assert_equal "$PARSED_INNER" "$FAKE_INNER"
}

@test "parse_key_output: --words (import) and -v output; 'Address hex:' is not mistaken for the address" {
  local out
  out=$(lines "Deriving wormhole HD path: m/44'/189189189'/0'/0'/0'" "Generating wormhole address..." \
    "XXXXXXXXXXXXXXX Quantus Wormhole Details XXXXXXXXXXXXXXXXX" "Account index: 0" \
    "Derivation path: m/44'/189189189'/0'/0'/0'" "Address: $IMPORT_ADDRESS" "Inner Hash: $IMPORT_INNER" \
    "Address hex: 0x$(printf '%064d' 7)" "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
  parse_key_output <<<"$out"
  assert_equal "$PARSED_ADDRESS" "$IMPORT_ADDRESS"
  assert_equal "$PARSED_INNER" "$IMPORT_INNER"
}

@test "parse_key_output: incomplete or foreign output is rejected" {
  run parse_key_output <<<"Error deriving wormhole from mnemonic: InvalidWordCount"
  [ "$status" -ne 0 ]
  run parse_key_output <<<"Address: $FAKE_ADDRESS"
  [ "$status" -ne 0 ]
  run parse_key_output < <(lines "Address: $FAKE_ADDRESS" "Inner Hash: 0x1234")
  [ "$status" -ne 0 ]
  run parse_key_output < <(lines "Address: 5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY" "Inner Hash: $FAKE_INNER")
  [ "$status" -ne 0 ]
}

@test "rewards_address_from_log: last announced wormhole address wins" {
  mkdir -p "$LOG_DIR"
  lines "2026-09-10 20:00:00 Quantus Node" \
    "2026-09-10 20:00:01 ⛏️ Rewards wormhole address: $IMPORT_ADDRESS" \
    "2026-09-10 21:00:01 ⛏️ Rewards wormhole address: $FAKE_ADDRESS" "2026-09-10 21:00:02 💤 Idle" >"$NODE_LOG"
  assert_equal "$(rewards_address_from_log)" "$FAKE_ADDRESS"
  rm -f "$NODE_LOG"
  assert_equal "$(rewards_address_from_log)" ""
}

# ---------------------------------------------------------------------------------------------
# Command lines
# ---------------------------------------------------------------------------------------------
@test "build_node_args: exact official solo flags" {
  baseline
  NODE_NAME=qtc-test1 BASE_PATH="/data/with space/qn"
  set_chain_dir
  build_node_args
  assert_equal "$(lines "${NODE_ARGS[@]}")" "$(lines --chain mainnet --validator --name qtc-test1 \
    --base-path "/data/with space/qn" --node-key-file "$QM_DIR/node_key.p2p" --rewards-inner-hash "$FAKE_INNER" \
    --miner-listen-port 9833 --max-blocks-per-request 64 --sync full)"
}

@test "build_node_args: --no-telemetry only when TELEMETRY=no" {
  baseline
  TELEMETRY=no
  build_node_args
  assert_equal "${NODE_ARGS[-1]}" --no-telemetry
  assert_equal "$(lines "${NODE_ARGS[@]}" | grep -c -- --no-telemetry)" 1
  TELEMETRY=yes
  build_node_args
  refute_contains " ${NODE_ARGS[*]} " " --no-telemetry "
}

@test "build_node_args: never --force-authoring, --bootnodes, --dev or unsafe RPC flags" {
  baseline
  local t a
  for t in yes no; do
    TELEMETRY=$t
    build_node_args
    for a in --force-authoring --bootnodes --dev --tmp --rpc-external --unsafe-rpc-external --rpc-methods --chain=dev; do
      refute_contains " ${NODE_ARGS[*]} " " $a"
    done
  done
}

@test "build_miner_args: solo + cpu" {
  baseline
  CPU_WORKERS=6
  build_miner_args
  assert_equal "$(lines "${MINER_ARGS[@]}")" "$(lines serve --metrics-port 9900 --node-addr 127.0.0.1:9833 \
    --auth-token-file "$CHAIN_DIR/miner-auth-token" --tls-cert-sha256-file "$CHAIN_DIR/miner-tls-cert-sha256" \
    --cpu-workers 6 --gpu-devices 0)"
  assert_equal "$(miner_nice)" 5
}

@test "build_miner_args: solo + gpu uses --cuda-gpu --gpu-devices N --cpu-workers 0" {
  baseline
  DEVICE=gpu GPU_DEVICES=2 METRICS_PORT=9911
  build_miner_args
  assert_equal "$(lines "${MINER_ARGS[@]}")" "$(lines serve --metrics-port 9911 --node-addr 127.0.0.1:9833 \
    --auth-token-file "$CHAIN_DIR/miner-auth-token" --tls-cert-sha256-file "$CHAIN_DIR/miner-tls-cert-sha256" \
    --cuda-gpu --gpu-devices 2 --cpu-workers 0)"
  assert_equal "$(miner_nice)" 0
}

@test "build_miner_args: pool + cpu → --node-addr IP:PORT --auth-token ADDR.WORKER --tls-cert-sha256 FP" {
  baseline
  MODE=pool POOL_NAME=nurserypool POOL_ADDR=$NURSERY_ADDR POOL_FP=$NURSERY_FP PAYOUT_ADDRESS=$PAYOUT_ADDRESS_OK
  WORKER_NAME=laptop CPU_WORKERS=12
  build_miner_args
  assert_equal "$(lines "${MINER_ARGS[@]}")" "$(lines serve --metrics-port 9900 --node-addr "$NURSERY_ADDR" \
    --auth-token "$PAYOUT_ADDRESS_OK.laptop" --tls-cert-sha256 "$NURSERY_FP" --cpu-workers 12 --gpu-devices 0)"
  refute_contains "${MINER_ARGS[*]}" "auth-token-file"
}

@test "build_miner_args: pool + gpu" {
  baseline
  MODE=pool DEVICE=gpu POOL_ADDR=$QUANPOOL_ADDR POOL_FP=$QUANPOOL_FP PAYOUT_ADDRESS=$PAYOUT_ADDRESS_OK WORKER_NAME=rig1
  build_miner_args
  assert_equal "$(lines "${MINER_ARGS[@]}")" "$(lines serve --metrics-port 9900 --node-addr "$QUANPOOL_ADDR" \
    --auth-token "$PAYOUT_ADDRESS_OK.rig1" --tls-cert-sha256 "$QUANPOOL_FP" --cuda-gpu --gpu-devices 1 --cpu-workers 0)"
}

@test "miner_env_prefix: stray MINER_* variables are removed; cpu adds no LD_LIBRARY_PATH" {
  baseline
  export MINER_CUDA_GPU=1 MINER_NODE_ADDR=10.9.9.9:1 MINER_CPU_WORKERS=99 NOT_A_MINER_VAR=keep
  miner_env_prefix
  assert_equal "${MENV[0]}" env
  assert_contains " ${MENV[*]} " " -u MINER_CUDA_GPU "
  assert_contains " ${MENV[*]} " " -u MINER_NODE_ADDR "
  assert_contains " ${MENV[*]} " " -u MINER_CPU_WORKERS "
  refute_contains "${MENV[*]}" "LD_LIBRARY_PATH"
  local envout
  envout=$(miner_env_run env)
  assert_equal "$(grep -c '^MINER_' <<<"$envout")" 0
  assert_contains "$envout" "NOT_A_MINER_VAR=keep"
}

@test "miner_env_prefix: gpu puts the kit's NVRTC dir first and keeps an existing LD_LIBRARY_PATH" {
  baseline
  DEVICE=gpu
  unset LD_LIBRARY_PATH
  miner_env_prefix
  assert_equal "${MENV[-1]}" "LD_LIBRARY_PATH=$QM_DIR/nvrtc/$NVRTC_SUBDIR"
  export LD_LIBRARY_PATH=/opt/other/lib
  export MINER_CUDA_GPU=1
  local envout
  envout=$(miner_env_run env)
  assert_contains "$envout" "LD_LIBRARY_PATH=$QM_DIR/nvrtc/$NVRTC_SUBDIR:/opt/other/lib"
  assert_equal "$(grep -c '^MINER_' <<<"$envout")" 0
}

# ---------------------------------------------------------------------------------------------
# JSON / SCALE helpers (real single-line Substrate answers)
# ---------------------------------------------------------------------------------------------
@test "json_num / json_bool / json_str on real RPC answers" {
  local h s g hdr err
  h='{"jsonrpc":"2.0","id":1,"result":{"peers":8,"isSyncing":false,"shouldHavePeers":true}}'
  s='{"jsonrpc":"2.0","id":1,"result":{"startingBlock":0,"currentBlock":22953,"highestBlock":22955}}'
  g="{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":\"$MAINNET_GENESIS_HASH\"}"
  hdr='{"jsonrpc":"2.0","id":1,"result":{"parentHash":"0x0a","number":"0x59a9","stateRoot":"0x0b","extrinsicsRoot":"0x0c","digest":{"logs":[]}}}'
  err='{"jsonrpc":"2.0","id":1,"error":{"code":-32601,"message":"Method not found"}}'
  assert_equal "$(json_num peers <<<"$h")" 8
  assert_equal "$(json_bool isSyncing <<<"$h")" false
  assert_equal "$(json_bool shouldHavePeers <<<"$h")" true
  assert_equal "$(json_num startingBlock <<<"$s")" 0
  assert_equal "$(json_num currentBlock <<<"$s")" 22953
  assert_equal "$(json_num highestBlock <<<"$s")" 22955
  assert_equal "$(json_str result <<<"$g")" "$MAINNET_GENESIS_HASH"
  assert_equal "$(json_str number <<<"$hdr")" 0x59a9
  assert_equal "$(json_str result <<<"$err")" ""
  assert_equal "$(json_num peers <<<"")" ""
  json_num missing <<<"$h"          # exit status 0 even without a match
  json_str result <<<"$err"
}

@test "hex_to_dec: block numbers from chain_getHeader" {
  assert_equal "$(hex_to_dec 0x59a9)" 22953
  assert_equal "$(hex_to_dec 0x0)" 0
  assert_equal "$(hex_to_dec 0xFFFFFFFFFFFFFFF)" 1152921504606846975
  assert_equal "$(hex_to_dec 59d9)" 23001
  assert_equal "$(hex_to_dec 0x)" ""
  assert_equal "$(hex_to_dec 0xzz)" ""
  assert_equal "$(hex_to_dec 0x1FFFFFFFFFFFFFFF)" ""   # > 15 digits: refused instead of overflowing
}

@test "le_hex_to_dec: real SCALE difficulty (U512 LE) and TotalIssuance (u128 LE)" {
  assert_equal "$(le_hex_to_dec "$DIFFICULTY_HEX")" "$DIFFICULTY_DEC"
  assert_equal "$(le_hex_to_dec "0x$(printf '%s' "ffe7764817"; printf '0%.0s' {1..118})")" 99999999999   # genesis D
  assert_equal "$(le_hex_to_dec 0x00)" 0
  assert_equal "$(le_hex_to_dec 0x0001)" 256
  # 5,677,021.41 QTC in planck exceeds 2^53: float precision is documented; check 1e-12 relative error
  local got
  got=$(le_hex_to_dec "$ISSUANCE_HEX")
  awk -v g="$got" -v w="$ISSUANCE_DEC" 'BEGIN { d = (g - w) / w; if (d < 0) d = -d; exit !(d < 1e-12) }' \
    || { echo "issuance $got vs $ISSUANCE_DEC" >&2; false; }
  assert_equal "$(awk -v g="$got" 'BEGIN { printf "%.2f", g / 1e12 }')" "5677021.41"
}

@test "node_ready: needs RPC up, peers ≥ 1, isSyncing=false and current within 2 blocks of highest" {
  run node_ready; [ "$status" -ne 0 ]                  # RPC down
  touch "$QM_FAKE/rpc/local/FORCE_UP"
  fake_node_syncing
  run node_ready; [ "$status" -ne 0 ]
  fake_node_synced
  node_ready
  fake_rpc local system_health '{"peers":0,"isSyncing":false,"shouldHavePeers":true}'
  run node_ready; [ "$status" -ne 0 ]
  fake_rpc local system_health '{"peers":3,"isSyncing":false,"shouldHavePeers":true}'
  fake_rpc local system_syncState '{"startingBlock":0,"currentBlock":22990,"highestBlock":23001}'
  run node_ready; [ "$status" -ne 0 ]
  fake_rpc local system_syncState '{"startingBlock":0,"currentBlock":22999,"highestBlock":23001}'
  node_ready
  assert_equal "$(node_genesis)" "$MAINNET_GENESIS_HASH"
  assert_equal "$(best_block "$QM_PUBLIC_RPC")" 23001
  assert_equal "$(mined_blocks_of "$FAKE_ADDRESS")" 3
}

@test "miner_hashrate_hs + fmt_rate: Prometheus miner_hash_rate → human units" {
  baseline
  assert_equal "$(miner_hashrate_hs)" ""
  fake_metrics 818520000
  assert_equal "$(miner_hashrate_hs)" 818520000
  assert_equal "$(fmt_rate 818520000)" "818.5 MH/s"
  assert_equal "$(fmt_rate 1200000000)" "1.20 GH/s"
  assert_equal "$(fmt_rate 4123)" "4 kH/s"
  assert_equal "$(fmt_rate 0)" "0 kH/s"
}

# ---------------------------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------------------------
@test "parse_args: no arguments means 'start' with no CLI overrides" {
  parse_args
  assert_equal "$COMMAND" start
  assert_equal "${#CLI_SET[@]}" 0
}

@test "parse_args: flags set values and mark them as command-line overrides" {
  parse_args status --device gpu --cpu-workers 4 --gpu-devices 2 --gpu-power-limit 350 --name qtc-x \
    --no-telemetry --metrics-port 9911 --base-path /data/qn --worker rig2 --yes --dry-run
  assert_equal "$COMMAND" status
  assert_equal "$DEVICE $CPU_WORKERS $GPU_DEVICES $GPU_POWER_LIMIT $NODE_NAME" "gpu 4 2 350 qtc-x"
  assert_equal "$TELEMETRY $METRICS_PORT $BASE_PATH $WORKER_NAME" "no 9911 /data/qn rig2"
  assert_equal "$ASSUME_YES $DRY_RUN" "1 1"
  local k
  for k in DEVICE CPU_WORKERS GPU_DEVICES GPU_POWER_LIMIT NODE_NAME TELEMETRY METRICS_PORT BASE_PATH WORKER_NAME; do
    [ -n "${CLI_SET[$k]:-}" ] || { echo "CLI_SET[$k] missing" >&2; false; }
  done
  [ -z "${CLI_SET[MODE]:-}" ]
}

@test "parse_args: --pool implies pool mode; --pool-fp is lower-cased" {
  parse_args start --pool quanpool --pool-fp "${QUANPOOL_FP^^}" --payout-address "$PAYOUT_ADDRESS_OK"
  assert_equal "$MODE" pool
  assert_equal "$POOL_NAME" quanpool
  assert_equal "$POOL_FP" "$QUANPOOL_FP"
  assert_equal "$PAYOUT_ADDRESS" "$PAYOUT_ADDRESS_OK"
  [ -n "${CLI_SET[MODE]:-}" ]
  [ -n "${CLI_SET[POOL_NAME]:-}" ]
  [ -n "${CLI_SET[POOL_FP]:-}" ]
}

@test "parse_args: --inner-hash also clears a saved rewards address; --key and --dir are not settings" {
  parse_args setup --inner-hash "$FAKE_INNER" --key new --dir /tmp/elsewhere
  assert_equal "$INNER_HASH" "$FAKE_INNER"
  assert_equal "$REWARDS_ADDRESS" ""
  [ -n "${CLI_SET[REWARDS_ADDRESS]:-}" ]
  assert_equal "$KEY_MODE" new
  assert_equal "$QM_DIR" /tmp/elsewhere
  [ -z "${CLI_SET[QM_DIR]:-}" ]
  [ -z "${CLI_SET[KEY_MODE]:-}" ]
}

@test "parse_args: logs target, help, benchmark duration and difficulty hash rate" {
  parse_args logs miner
  assert_equal "$COMMAND $LOG_TARGET" "logs miner"
  parse_args -h
  assert_equal "$COMMAND" help
  parse_args benchmark --duration 45
  assert_equal "$BENCH_DURATION" 45
  parse_args difficulty --hashrate 820.5
  assert_equal "$HASHRATE_MHS" 820.5
}

@test "parse_args: unknown option" {
  run parse_args start --bogus
  assert_status 1
  assert_contains "$output" "Nieznana opcja: --bogus"
}

@test "parse_args: missing value (at the end, empty, or followed by another option)" {
  run parse_args start --device
  assert_status 1
  assert_contains "$output" "Opcja --device wymaga wartości."
  run parse_args start --pool --yes
  assert_status 1
  assert_contains "$output" "Opcja --pool wymaga wartości."
  run parse_args start --name ""
  assert_status 1
  assert_contains "$output" "Opcja --name wymaga wartości."
  run parse_args start --inner-hash
  assert_status 1
  assert_contains "$output" "Opcja --inner-hash wymaga wartości."
}

@test "parse_args: bad --duration / --hashrate and unexpected positional arguments" {
  run parse_args benchmark --duration 5s
  assert_status 1
  assert_contains "$output" "--duration musi być liczbą sekund"
  run parse_args difficulty --hashrate 8,2
  assert_status 1
  assert_contains "$output" "--hashrate podaj w MH/s"
  run parse_args status extra
  assert_status 1
  assert_contains "$output" "Nieoczekiwany argument: extra"
  run parse_args logs node miner
  assert_status 1
  assert_contains "$output" "Nieoczekiwany argument: miner"
}

# ---------------------------------------------------------------------------------------------
# Process / supervisor helpers
# ---------------------------------------------------------------------------------------------
@test "read_pid / pid_alive / pid_cmd_matches" {
  mkdir -p "$RUN_DIR"
  printf '%s\n' "$$" >"$RUN_DIR/x.pid"
  assert_equal "$(read_pid "$RUN_DIR/x.pid")" "$$"
  assert_equal "$(read_pid "$RUN_DIR/missing.pid")" ""
  pid_alive "$$"
  run pid_alive ""; [ "$status" -ne 0 ]
  run pid_alive 999999999; [ "$status" -ne 0 ]
  pid_cmd_matches "$$" "bats"
  run pid_cmd_matches "$$" "definitely-not-in-the-command-line"; [ "$status" -ne 0 ]
  assert_equal "$(supervisor_pid)" ""
}

@test "sup_backoff: doubles up to 300 s and resets after 10 minutes of healthy running" {
  local now
  now=$(date +%s)
  SUP_MINER_DELAY=1
  sup_backoff SUP_MINER_DELAY "$now"; assert_equal "$SUP_MINER_DELAY" 2
  sup_backoff SUP_MINER_DELAY "$now"; assert_equal "$SUP_MINER_DELAY" 4
  SUP_MINER_DELAY=200
  sup_backoff SUP_MINER_DELAY "$now"; assert_equal "$SUP_MINER_DELAY" 300
  sup_backoff SUP_MINER_DELAY "$now"; assert_equal "$SUP_MINER_DELAY" 300
  sup_backoff SUP_MINER_DELAY $(( now - 601 )); assert_equal "$SUP_MINER_DELAY" "$QM_RESTART_DELAY"
}

@test "rotate_if_big: big log keeps its tail in .1 and is truncated in place; small logs untouched" {
  mkdir -p "$LOG_DIR"
  head -c $(( 2 * 1024 * 1024 + 10 )) /dev/zero | tr '\0' 'a' >"$NODE_LOG"
  printf '\nLAST-LINE\n' >>"$NODE_LOG"
  local ino
  ino=$(stat -c %i "$NODE_LOG")
  rotate_if_big "$NODE_LOG" 1
  assert_equal "$(stat -c %s "$NODE_LOG")" 0
  assert_equal "$(stat -c %i "$NODE_LOG")" "$ino"     # same inode: O_APPEND writers keep working
  assert_equal "$(tail -n 1 "$NODE_LOG.1")" LAST-LINE
  printf 'small\n' >"$MINER_LOG"
  rotate_if_big "$MINER_LOG" 1
  assert_equal "$(cat "$MINER_LOG")" small
  [ ! -e "$MINER_LOG.1" ]
  rotate_if_big "$LOG_DIR/does-not-exist" 1
}

@test "check_nvidia_driver: >= 570 accepted, older or unreadable drivers and no GPU rejected" {
  run check_nvidia_driver
  assert_status 1
  assert_contains "$output" "Nie widzę karty NVIDIA"
  fake_gpu 580.82.07
  run check_nvidia_driver
  assert_status 0
  assert_contains "$output" "GPU: NVIDIA GeForce RTX 4090, sterownik 580.82.07"
  fake_gpu 570.86.10
  run check_nvidia_driver
  assert_status 0
  fake_gpu 565.57.01
  run check_nvidia_driver
  assert_status 1
  assert_contains "$output" "Sterownik NVIDIA 565.57.01 jest za stary (potrzeba >= 570)"
  fake_gpu "N/A"
  run check_nvidia_driver
  assert_status 1
  assert_contains "$output" "Nie mogę odczytać wersji sterownika NVIDIA"
}

@test "systemd_unit: runs the kit copy as the current user with HOME; no power-limit lines for cpu" {
  baseline
  local unit
  unit=$(systemd_unit)
  assert_contains "$unit" "User=$(id -un)"
  assert_contains "$unit" "Group=$(id -gn)"
  assert_contains "$unit" "Environment=\"HOME=$HOME\""
  assert_contains "$unit" "WorkingDirectory=$QM_DIR"
  assert_contains "$unit" "ExecStart=/bin/bash \"$QM_DIR/bin/quantus-miner.sh\" _supervise --dir \"$QM_DIR\""
  assert_contains "$unit" "Restart=always"
  assert_contains "$unit" "TimeoutStopSec=90"
  assert_contains "$unit" "WantedBy=multi-user.target"
  assert_contains "$unit" "After=network-online.target"
  refute_contains "$unit" "ExecStartPre"
  refute_contains "$unit" "ProtectHome"
}

@test "systemd_unit: gpu with a power limit re-applies it (as root) before every start" {
  baseline
  DEVICE=gpu GPU_POWER_LIMIT=350
  local unit
  unit=$(systemd_unit)
  # '-' prefix: a refused limit (outside the card's range, driver not ready) must not fail the unit
  assert_contains "$unit" "ExecStartPre=-+/usr/bin/nvidia-smi -pm 1"
  assert_contains "$unit" "ExecStartPre=-+/usr/bin/nvidia-smi -pl 350"
}

@test "setup_is_complete: needs config, binaries, node key and inner hash (solo)" {
  baseline
  run setup_is_complete; [ "$status" -ne 0 ]
  mkdir -p "$BIN_DIR"
  cp "$QM_STUBS/quantus-node" "$NODE_BIN"; cp "$QM_STUBS/quantus-miner" "$MINER_BIN"
  save_config
  run setup_is_complete; [ "$status" -ne 0 ]          # no node key yet
  printf '%064d' 1 >"$NODE_KEY"
  setup_is_complete
  INNER_HASH=""
  run setup_is_complete; [ "$status" -ne 0 ]
}
