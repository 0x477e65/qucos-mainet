#!/usr/bin/env bats
# Integration tests: quantus-miner.sh runs as a real process inside a per-test sandbox.
# Downloads, node, miner, GPU tools, sudo and systemctl are stubs (see helpers.bash); the
# supervisor ticks every second (QM_TICK=1) and restarts after 1 s (QM_RESTART_DELAY=1).

load helpers

setup_file() { qm_build_fixtures; }
setup() { qm_sandbox; }
teardown() { qm_cleanup_procs; }

# ---------------------------------------------------------------------------------------------
# Local helpers
# ---------------------------------------------------------------------------------------------
CONF() { sed -n "s/^$1=//p" "$QM_DIR/mining.conf"; }
sup_log() { cat "$QM_DIR/logs/supervisor.log" 2>/dev/null || true; }
log_has() { grep -qF -- "$1" "$QM_DIR/logs/supervisor.log" 2>/dev/null; }
wait_log() { wait_for "${2:-15}" log_has "$1" || { echo "supervisor.log never said: $1" >&2; sup_log >&2; return 1; }; }
lines() { printf '%s\n' "$@"; }
chain_dir() { echo "$HOME/.local/share/quantus-node/chains/mainnet"; }

setup_solo() {  # extra flags… — first-time CPU solo setup with a fresh key (shown in a terminal)
  command -v script >/dev/null 2>&1 || skip "util-linux 'script' (pty) not available"
  run qm_tty "$NEW_KEY_ANSWERS" setup --yes --key new --device cpu --cpu-workers 3 "$@"
  assert_status 0
}
setup_gpu() {  # extra flags… — GPU solo setup with a known inner hash
  fake_gpu "${GPU_DRIVER:-580.82.07}"
  qm_use_stub python3
  run qm setup --yes --device gpu --inner-hash "$FAKE_INNER" "$@"
}
start_bg() {  # start in the background and wait for the supervisor
  run qm start "$@"
  assert_status 0
  wait_for 15 qm_supervisor_up || { echo "supervisor did not come up" >&2; sup_log >&2; return 1; }
}
wait_node() { wait_for 15 qm_node_up || { echo "node did not start" >&2; sup_log >&2; return 1; }; }
wait_miner() { wait_for 15 qm_miner_up || { echo "miner did not start" >&2; sup_log >&2; cat "$QM_DIR/logs/miner.log" >&2 2>/dev/null; return 1; }; }
no_procs() { wait_for "${1:-3}" qm_no_sandbox_procs || { echo "leftover processes:" >&2; qm_show_procs >&2; return 1; }; }
miner_argv() { cat "$QM_FAKE/miner.argv"; }
own_nice_plus() { local n; n=$(( $(nice) + $1 )); (( n > 19 )) && n=19; echo "$n"; }

# ---------------------------------------------------------------------------------------------
# setup
# ---------------------------------------------------------------------------------------------
@test "setup --yes --key new: verified downloads, node key, new rewards key; phrase shown once, never stored" {
  setup_solo
  assert_contains "$output" "Suma SHA-256 poprawna: quantus-miner"
  assert_contains "$output" "Suma SHA-256 poprawna: node.tar.gz"
  assert_contains "$output" "Zainstalowano quantus-node 1.0.1-f1176cea6a6"
  assert_contains "$output" "Zainstalowano miner-cli 4.2.0"
  assert_contains "$output" " 1. abandon"                  # numbered, 4 words per row
  assert_contains "$output" "24. actual"
  refute_contains "$output" "Secret phrase:"               # the raw node output is never echoed
  assert_contains "$output" "Zapis frazy sprawdzony"
  assert_contains "$output" "Nagrody trafią na adres: $FAKE_ADDRESS"
  [ -x "$QM_DIR/bin/quantus-node" ]
  [ -x "$QM_DIR/bin/quantus-miner" ]
  cmp "$QM_FIXTURES/dl/$FIX_MINER_NAME" "$QM_DIR/bin/quantus-miner"
  # config
  assert_equal "$(stat -c %a "$QM_DIR")" 700
  assert_equal "$(stat -c %a "$QM_DIR/mining.conf")" 600
  assert_equal "$(CONF INNER_HASH)" "$FAKE_INNER"
  assert_equal "$(CONF REWARDS_ADDRESS)" "$FAKE_ADDRESS"
  assert_equal "$(CONF MODE) $(CONF DEVICE) $(CONF CPU_WORKERS)" "solo cpu 3"
  # node P2P key
  assert_equal "$(stat -c %a "$QM_DIR/node_key.p2p")" 600
  [[ $(cat "$QM_DIR/node_key.p2p") =~ ^[0-9a-f]{64}$ ]]
  assert_file_contains "$QM_FAKE/node.calls" "key generate-node-key --file $QM_DIR/node_key.p2p"
  assert_file_contains "$QM_FAKE/node.calls" "key quantus --scheme wormhole"
  # the 24 words exist only on screen
  run grep -rlF --exclude-dir=bin -- "$FAKE_PHRASE" "$QM_DIR" "$HOME" "$TMPDIR"   # bin/ = the stub itself
  [ -z "$output" ] || { echo "phrase written to: $output" >&2; false; }
  # nothing was fetched from anywhere but the fixtures, nothing needed sudo
  [ ! -e "$QM_FAKE/curl.unexpected" ]
  [ ! -e "$QM_FAKE/sudo.log" ]
  [ -z "$(find "$TMPDIR" -mindepth 1)" ]
}

@test "setup --yes --inner-hash: uses the given hash, never generates or asks for a phrase" {
  run qm setup --yes --device cpu --inner-hash "$FAKE_INNER"
  assert_status 0
  assert_equal "$(CONF INNER_HASH)" "$FAKE_INNER"
  assert_equal "$(CONF REWARDS_ADDRESS)" ""
  refute_file_contains "$QM_FAKE/node.calls" "key quantus"
  refute_contains "$output" "Secret phrase"
  refute_contains "$output" "ZAPISAŁEM"
}

@test "setup --key import: phrase typed in a terminal is converted by the node, never stored" {
  command -v script >/dev/null 2>&1 || skip "util-linux 'script' (pty) not available"
  run bash -c 'printf "%s\n" "$1" | timeout 30 script -qec "bash \"$2\" setup --yes --key import --device cpu" /dev/null' \
    _ "$FAKE_PHRASE" "$QM_SCRIPT" 3>&- 4>&-
  assert_status 0
  assert_equal "$(CONF INNER_HASH)" "$FAKE_INNER"
  assert_equal "$(CONF REWARDS_ADDRESS)" "$FAKE_ADDRESS"
  assert_file_contains "$QM_FAKE/node.calls" "key quantus --scheme wormhole --words"
  refute_contains "$(cat "$QM_FAKE/node.calls")" "abandon"     # never on a command line
  run grep -rlF --exclude-dir=bin -- "$FAKE_PHRASE" "$QM_DIR" "$HOME" "$TMPDIR"   # bin/ = the stub itself
  [ -z "$output" ]
}

@test "setup --key import: a numbered list pasted over several lines is joined; nothing is left over for the shell" {
  command -v script >/dev/null 2>&1 || skip "util-linux 'script' (pty) not available"
  local numbered="" i=1 w cmd
  for w in $FAKE_PHRASE; do
    numbered+="$i. $w"
    if (( i % 12 == 0 )); then numbered+=$'\n'; else numbered+=" "; fi
    i=$(( i + 1 ))
  done
  # Whatever is still pending in the terminal after the script ends would be run by the user's
  # shell (and saved in ~/.bash_history). A shell-like `read` afterwards must find nothing.
  printf -v cmd '%q ' bash "$QM_SCRIPT" setup --yes --key import --device cpu
  run bash -c 'printf "%s" "$1" | TERM=xterm-256color timeout 30 script -qec "$2; rc=\$?; if IFS= read -r -t 2 left; then echo LEFTOVER:\$left; fi; exit \$rc" /dev/null' \
    _ "$numbered"$'extra typed words\n' "$cmd" 3>&- 4>&-
  assert_status 0
  assert_contains "$output" "(wpisano 12/24 słów"
  assert_equal "$(CONF INNER_HASH)" "$FAKE_INNER"
  assert_contains "$output" "Adres nagród z tej frazy: $FAKE_ADDRESS"
  refute_contains "$output" "LEFTOVER:"
}

@test "setup --key import: 25 words are refused; 12 words need an extra empty line (a 12-word phrase)" {
  command -v script >/dev/null 2>&1 || skip "util-linux 'script' (pty) not available"
  run qm_tty "$FAKE_PHRASE extra"$'\n' setup --yes --key import --device cpu
  assert_status 1
  assert_contains "$output" "wpisano: 25"
  [ ! -e "$QM_DIR/mining.conf" ]
  local twelve
  twelve=$(cut -d' ' -f1-12 <<<"$FAKE_PHRASE")
  run qm_tty "$twelve"$'\n\n' setup --yes --key import --device cpu
  assert_status 0
  assert_contains "$output" "(wpisano 12/24 słów"
  assert_equal "$(CONF INNER_HASH)" "$IMPORT_INNER"
}

@test "setup --yes --key new in a terminal: the new phrase is not wiped before it can be written down" {
  command -v script >/dev/null 2>&1 || skip "util-linux 'script' (pty) not available"
  # --yes does NOT skip the "type ZAPISAŁEM" confirmation: the phrase is the ONLY copy of the key.
  run qm_tty "$NEW_KEY_ANSWERS" setup --yes --key new --device cpu
  assert_status 0
  assert_contains "$output" " 1. abandon"
  assert_contains "$output" "Wpisz ZAPISAŁEM"
  local before=${output%%Wpisz ZAPISAŁEM*}
  if [[ $before == *$'\e[3J'* || $before == *$'\e[2J'* ]]; then
    echo "the screen is erased before the user confirmed that the 24 words are written down" >&2
    false
  fi
  local after=${output#*Zapis frazy sprawdzony}
  [[ ${output%%Zapis frazy sprawdzony*} == *$'\e[2J'* ]]   # …and it IS erased once the check passed
  refute_contains "$after" "abandon"
  assert_equal "$(CONF INNER_HASH)" "$FAKE_INNER"
}

@test "setup --key new without a terminal (pipe, '| tee log', automation): refused, the phrase is never printed" {
  run qm setup --yes --key new --device cpu
  assert_status 1
  assert_contains "$output" "tylko na ekranie terminala"
  assert_contains "$output" "--inner-hash"
  refute_contains "$output" "abandon"
  refute_file_contains "$QM_FAKE/node.calls" "key quantus"   # no key was even generated
  [ ! -e "$QM_DIR/mining.conf" ]
}

@test "setup --key new: a wrong word in the paper check shows the phrase again; 3 failures abort, nothing saved" {
  command -v script >/dev/null 2>&1 || skip "util-linux 'script' (pty) not available"
  run qm_tty $'ZAPISAŁEM\nabandon\nwrong\nZAPISAŁEM\nabandon\nability\nable\n' setup --key new --device cpu
  assert_status 0
  assert_equal "$(grep -o ' 1\. abandon' <<<"$output" | wc -l)" 2      # shown twice
  assert_contains "$output" "To słowo nie zgadza się z frazą"
  assert_equal "$(CONF INNER_HASH)" "$FAKE_INNER"
  rm -rf "$QM_DIR"
  run qm_tty $'ZAPISAŁEM\nx\nZAPISAŁEM\nx\nZAPISAŁEM\nx\n' setup --key new --device cpu
  assert_status 1
  assert_contains "$output" "Trzy razy błędne słowo"
  [ ! -e "$QM_DIR/mining.conf" ]
}

@test "setup --key new: not typing ZAPISAŁEM aborts; the phrase is wiped and nothing is saved" {
  command -v script >/dev/null 2>&1 || skip "util-linux 'script' (pty) not available"
  run qm_tty $'nie\n' setup --key new --device cpu
  assert_status 1
  assert_contains "$output" "Przerwano — nic nie zapisano"
  [[ ${output#*Wpisz ZAPISAŁEM} == *$'\e[2J'* ]]
  [ ! -e "$QM_DIR/mining.conf" ]
}

@test "setup --key new on an existing rewards key: replaced only after confirmation" {
  setup_solo
  run qm_tty $'n\n' setup --key new --device cpu
  assert_status 1
  assert_contains "$output" "Masz już ustawiony klucz nagród (adres: $FAKE_ADDRESS"
  assert_contains "$output" "klucz nagród bez zmian"
  assert_equal "$(grep -c 'key quantus' "$QM_FAKE/node.calls")" 1
  run qm_tty $'t\n'"$NEW_KEY_ANSWERS" setup --key new --device cpu
  assert_status 0
  assert_equal "$(grep -c 'key quantus' "$QM_FAKE/node.calls")" 2
  assert_equal "$(CONF INNER_HASH)" "$FAKE_INNER"
  run qm setup --yes --device cpu --inner-hash "$IMPORT_INNER"     # --inner-hash replaces without asking
  assert_status 0
  assert_equal "$(CONF INNER_HASH) $(CONF REWARDS_ADDRESS)" "$IMPORT_INNER "
}

@test "setup is idempotent: second run downloads nothing and keeps the node key and rewards identity" {
  setup_solo
  local key
  key=$(cat "$QM_DIR/node_key.p2p")
  : >"$QM_FAKE/curl.log"
  run qm setup --yes --device cpu
  assert_status 0
  assert_contains "$output" "quantus-node już zainstalowany"
  assert_contains "$output" "quantus-miner już zainstalowany"
  refute_file_contains "$QM_FAKE/curl.log" "fixtures.invalid"
  assert_equal "$(cat "$QM_DIR/node_key.p2p")" "$key"
  assert_equal "$(CONF INNER_HASH)" "$FAKE_INNER"
  assert_equal "$(grep -c 'key quantus' "$QM_FAKE/node.calls")" 1
}

@test "setup --yes without a rewards key choice refuses to guess" {
  run qm setup --yes --device cpu
  assert_status 1
  assert_contains "$output" "Brak klucza do nagród. Podaj --key new, --key import albo --inner-hash"
  [ ! -e "$QM_DIR/mining.conf" ]
  run qm setup --yes --device cpu --key maybe
  assert_status 1
  assert_contains "$output" "Nieznany --key 'maybe'"
  run qm setup --yes --device cpu --inner-hash 0x1234
  assert_status 1
  assert_contains "$output" "INNER_HASH musi mieć postać 0x + 64 znaki hex"
}

@test "setup: wrong SHA-256 of the miner aborts with a clear message; no miner installed" {
  export QM_MINER_SHA256=0000000000000000000000000000000000000000000000000000000000000000
  run qm setup --yes --key new --device cpu
  assert_status 1
  assert_contains "$output" "Suma kontrolna się NIE zgadza dla quantus-miner! Oczekiwano $QM_MINER_SHA256, jest $FIX_MINER_SHA256"
  [ ! -e "$QM_DIR/bin/quantus-miner" ]
  [ ! -e "$QM_DIR/bin/quantus-node" ]
  [ ! -e "$QM_DIR/mining.conf" ]
}

@test "setup: wrong SHA-256 of the node aborts with a clear message; no node installed, no config" {
  export QM_NODE_SHA256=1111111111111111111111111111111111111111111111111111111111111111
  run qm setup --yes --key new --device cpu
  assert_status 1
  assert_contains "$output" "Suma kontrolna się NIE zgadza dla node.tar.gz"
  assert_contains "$output" "plik mógł zostać podmieniony"
  [ ! -e "$QM_DIR/bin/quantus-node" ]
  [ ! -e "$QM_DIR/mining.conf" ]
  [ ! -e "$QM_DIR/node_key.p2p" ]
  refute_contains "$output" "Secret phrase"
}

@test "setup: an aborted checksum verification leaves no unverified download behind" {
  export QM_NODE_SHA256=1111111111111111111111111111111111111111111111111111111111111111
  run qm setup --yes --key new --device cpu
  assert_status 1
  local left
  left=$(find "$TMPDIR" -type f)
  [ -z "$left" ] || { echo "unverified download left on disk: $left" >&2; false; }
}

@test "setup: a failed download aborts with a clear message" {
  export QM_MINER_URL="https://fixtures.invalid/no-such-asset"
  run qm setup --yes --key new --device cpu
  assert_status 1
  assert_contains "$output" "Pobieranie nie powiodło się: https://fixtures.invalid/no-such-asset"
  [ ! -e "$QM_DIR/bin/quantus-miner" ]
}

@test "setup: binaries without the miner-auth flags (old versions) are refused" {
  touch "$QM_FAKE/node.help_old"
  run qm setup --yes --key new --device cpu
  assert_status 1
  assert_contains "$output" "nie obsługuje autoryzacji minera (brak --miner-auth-token-file)"
  rm "$QM_FAKE/node.help_old"
  touch "$QM_FAKE/miner.help_old"
  rm -rf "$QM_DIR"
  run qm setup --yes --key new --device cpu
  assert_status 1
  assert_contains "$output" "Ta wersja minera nie pasuje do node'a v1.0.1"
}

# ---------------------------------------------------------------------------------------------
# start / supervisor (solo)
# ---------------------------------------------------------------------------------------------
@test "start (solo): node starts with the official flags; miner waits while syncing, then starts correctly" {
  setup_solo
  run qm start
  assert_status 0
  assert_contains "$output" "Wystartowano!"
  assert_contains "$output" "Miner włączy się SAM"
  assert_contains "$output" "Twoje nagrody: https://explorer.quantus.com/accounts/$FAKE_ADDRESS"
  wait_for 15 qm_supervisor_up
  wait_node
  local name base
  name=$(CONF NODE_NAME)
  base="$HOME/.local/share/quantus-node"
  assert_equal "$(cat "$QM_FAKE/node.argv")" "$(lines --chain mainnet --validator --name "$name" --base-path "$base" \
    --node-key-file "$QM_DIR/node_key.p2p" --rewards-inner-hash "$FAKE_INNER" --miner-listen-port 9833 \
    --max-blocks-per-request 64 --sync full)"
  wait_log "Czekam, aż node się zsynchronizuje"
  wait_log "Node na mainnecie (genesis OK)."
  sleep 2.5                                   # several ticks while the RPC still says "syncing"
  [ ! -e "$QM_FAKE/miner.starts" ]
  [ -z "$(qm_miner_pid)" ]
  fake_node_synced
  wait_miner
  wait_log "Node zsynchronizowany — uruchamiam minera."
  assert_equal "$(miner_argv)" "$(lines serve --metrics-port 9900 --node-addr 127.0.0.1:9833 \
    --auth-token-file "$(chain_dir)/miner-auth-token" --tls-cert-sha256-file "$(chain_dir)/miner-tls-cert-sha256" \
    --cpu-workers 3 --gpu-devices 0)"
  assert_equal "$(cat "$QM_FAKE/miner.nice")" "$(own_nice_plus 5)"
  assert_equal "$(grep -c '^MINER_' "$QM_FAKE/miner.env")" 0
  refute_file_contains "$QM_FAKE/miner.env" "LD_LIBRARY_PATH="
  assert_equal "$(qm_count_lines "$QM_FAKE/miner.starts")" 1
  # the miner is a direct child process: its pid file holds the real miner pid
  assert_equal "$(qm_miner_pid)" "$(cat "$QM_FAKE/miner.running")"
}

@test "start (solo): a killed miner is restarted (with back-off), the node keeps running" {
  setup_solo
  fake_node_synced
  start_bg
  wait_miner
  local m1 n1
  m1=$(qm_miner_pid); n1=$(qm_node_pid)
  kill -KILL "$m1"
  restarted() { local p; p=$(qm_miner_pid); [[ -n $p && $p != "$m1" ]] && qm_miner_up; }
  wait_for 15 restarted || { sup_log >&2; false; }
  wait_log "Miner zakończył działanie (kod 137). Restart za 2s."
  assert_equal "$(qm_count_lines "$QM_FAKE/miner.starts")" 2
  assert_equal "$(qm_node_pid)" "$n1"
  assert_equal "$(qm_count_lines "$QM_FAKE/node.starts")" 1
}

@test "start (solo): a crashing node is restarted and the miner is not started meanwhile" {
  setup_solo
  fake_node_synced
  echo 1 >"$QM_FAKE/node.exit_code"
  start_bg
  twice() { (( $(qm_count_lines "$QM_FAKE/node.starts") >= 2 )); }
  wait_for 15 twice || { sup_log >&2; false; }
  wait_log "Node zakończył działanie (kod 1)."
  [ ! -e "$QM_FAKE/miner.starts" ]
  rm -f "$QM_FAKE/node.exit_code"
  wait_for 20 qm_node_up || { sup_log >&2; false; }
  wait_miner
}

@test "status: sane output while mining (supervisor, node, chain height, hash rate, rewards)" {
  setup_solo
  fake_node_synced
  fake_metrics 818520000
  start_bg
  wait_miner
  run qm status
  assert_status 0
  assert_contains "$output" "Tryb: solo   Urządzenie: cpu   Katalog: $QM_DIR"
  assert_contains "$output" "Nadzorca: działa (pid $(qm_supervisor_pid))"
  assert_contains "$output" "Node:  działa (pid $(qm_node_pid))"
  assert_contains "$output" "Miner: działa (pid $(qm_miner_pid))   moc: 818.5 MH/s"
  assert_contains "$output" "Łańcuch: blok 23000 / sieć 23001   peers: 8   synchronizacja: zakończona"
  assert_contains "$output" "Nagrody: https://explorer.quantus.com/accounts/$FAKE_ADDRESS"
  assert_contains "$output" "Wykopane bloki (łańcuch): 3   zgłoszone przez ten node (log): 0"
}

@test "status: rewards address is read from the node log when setup used only --inner-hash" {
  run qm setup --yes --device cpu --inner-hash "$FAKE_INNER"
  assert_status 0
  start_bg
  wait_node
  wait_for 10 grep -q "Rewards wormhole address" "$QM_DIR/logs/node.log"
  run qm status
  assert_status 0
  assert_contains "$output" "Nagrody: https://explorer.quantus.com/accounts/$FAKE_ADDRESS"
  assert_contains "$output" "Miner: nie działa (czeka na synchronizację node'a)"
  assert_contains "$output" "synchronizacja: w toku"
}

@test "stop: supervisor, node and miner all exit cleanly; pid files removed; no orphan processes" {
  setup_solo
  fake_node_synced
  start_bg
  wait_miner
  local sp np mp
  sp=$(qm_supervisor_pid); np=$(qm_node_pid); mp=$(qm_miner_pid)
  run qm stop
  assert_status 0
  assert_contains "$output" "Zatrzymano."
  no_procs 2
  refute qm_alive "$sp"
  refute qm_alive "$np"
  refute qm_alive "$mp"
  [ ! -e "$QM_DIR/run/supervisor.pid" ]
  [ ! -e "$QM_DIR/run/node.pid" ]
  [ ! -e "$QM_DIR/run/miner.pid" ]
  assert_file_contains "$QM_DIR/logs/node.log" "stub-node: TERM received, clean shutdown"
  assert_file_contains "$QM_DIR/logs/miner.log" "stub-miner: TERM received, clean shutdown"
  assert_file_contains "$QM_DIR/logs/supervisor.log" "Zatrzymano."
  run qm status
  assert_contains "$output" "Nadzorca: nie działa"
  run qm stop                                  # stopping twice is harmless
  assert_status 0
}

@test "start twice: no duplicate supervisor or node; a hand-started second supervisor exits (lock)" {
  setup_solo
  start_bg
  wait_node
  local sp np re
  sp=$(qm_supervisor_pid); np=$(qm_node_pid)
  run qm start
  assert_status 0
  assert_contains "$output" "Kopanie już działa."
  assert_contains "$output" "Nadzorca: działa (pid $sp)"
  run timeout 10 bash "$QM_SCRIPT" _supervise --dir "$QM_DIR" </dev/null 3>&- 4>&-
  assert_status 0
  assert_contains "$output" "Nadzorca już działa — kończę."
  sleep 1.5
  re=$(qm_regex_escape "$QM_DIR")
  assert_equal "$(pgrep -fc -- "_supervise --dir $re\$")" 1
  assert_equal "$(pgrep -fc -- "$re/bin/quantus-node ")" 1
  assert_equal "$(qm_supervisor_pid) $(qm_node_pid)" "$sp $np"
  assert_equal "$(qm_count_lines "$QM_FAKE/node.starts")" 1
}

@test "genesis mismatch: supervisor stops the node and exits; the miner never starts" {
  setup_solo
  fake_node_synced
  fake_rpc local chain_getBlockHash '"0x1111111111111111111111111111111111111111111111111111111111111111"'
  run qm start
  assert_status 0
  wait_for 15 qm_supervisor_down || { sup_log >&2; false; }
  assert_contains "$(sup_log)" "BŁĄD: node jest na innym łańcuchu (genesis 0x1111111111111111111111111111111111111111111111111111111111111111)"
  no_procs 3
  [ ! -e "$QM_FAKE/miner.starts" ]
  [ ! -e "$QM_DIR/run/node.pid" ]
  [ ! -e "$QM_DIR/run/supervisor.pid" ]
  assert_file_contains "$QM_DIR/logs/node.log" "stub-node: TERM received"
}

@test "synced node that has not written miner-auth-token yet: miner is not started" {
  setup_solo
  touch "$QM_FAKE/node.no_token"
  fake_node_synced
  start_bg
  wait_node
  wait_log "Node na mainnecie (genesis OK)."
  sleep 2.5
  [ ! -e "$QM_FAKE/miner.starts" ]
  assert_contains "$(sup_log)" "Czekam, aż node się zsynchronizuje"
}

@test "stray MINER_* variables in the user's environment (MINER_CUDA_GPU=1) do not reach the miner" {
  setup_solo
  fake_node_synced
  export MINER_CUDA_GPU=1 MINER_NODE_ADDR=10.9.9.9:1 MINER_CPU_WORKERS=99
  start_bg
  wait_miner
  assert_equal "$(grep -c '^MINER_' "$QM_FAKE/miner.env")" 0
  assert_contains "$(miner_argv)" "127.0.0.1:9833"
  assert_equal "$(sed -n '/^--cpu-workers$/{n;p}' "$QM_FAKE/miner.argv")" 3
}

@test "stop after the supervisor was killed -9: orphaned node and miner are stopped too" {
  setup_solo
  fake_node_synced
  start_bg
  wait_miner
  local sp np mp
  sp=$(qm_supervisor_pid); np=$(qm_node_pid); mp=$(qm_miner_pid)
  kill -KILL "$sp"
  wait_for 5 eval '! qm_alive '"$sp"
  qm_alive "$np"
  qm_alive "$mp"
  run qm stop
  assert_status 0
  refute qm_alive "$np"
  refute qm_alive "$mp"
  [ ! -e "$QM_DIR/run/node.pid" ]
  [ ! -e "$QM_DIR/run/miner.pid" ]
  [ ! -e "$QM_DIR/run/supervisor.pid" ]
  no_procs 3
}

@test "restart: a new supervisor starts a new node" {
  setup_solo
  start_bg
  wait_node
  local sp
  sp=$(qm_supervisor_pid)
  run qm restart
  assert_status 0
  wait_for 15 qm_supervisor_up
  [ "$(qm_supervisor_pid)" != "$sp" ]
  wait_node
  assert_equal "$(qm_count_lines "$QM_FAKE/node.starts")" 2
  refute qm_alive "$sp"
}

@test "stop still stops mining when mining.conf became invalid afterwards" {
  setup_solo
  start_bg
  wait_node
  sed -i 's/^CPU_WORKERS=.*/CPU_WORKERS=0/' "$QM_DIR/mining.conf"
  run qm stop
  assert_status 0
  no_procs 3
}

@test "start: busy ports abort before anything is started" {
  setup_solo
  printf '%s\n' "tcp 9944" "udp 9833" >"$QM_FAKE/busy_ports"
  run qm start
  assert_status 1
  assert_contains "$output" "Zajęte porty: 9944/tcp (RPC) 9833/udp (miner)"
  refute qm_supervisor_up
  [ ! -e "$QM_FAKE/node.starts" ]
}

@test "start: clock drift against the public RPC is reported" {
  setup_solo
  echo 120 >"$QM_FAKE/clock_offset"
  run qm start --dry-run
  assert_status 0
  [[ $output =~ Zegar\ komputera\ różni\ się\ o\ (119|120|121)s ]] || { echo "$output" >&2; false; }
  echo 0 >"$QM_FAKE/clock_offset"
  run qm start --dry-run
  assert_contains "$output" "Zegar zsynchronizowany"
}

# ---------------------------------------------------------------------------------------------
# pool mode
# ---------------------------------------------------------------------------------------------
@test "pool (nurserypool preset): no node installed or started; miner gets the pool arguments" {
  run qm setup --yes --pool nurserypool --payout-address "$PAYOUT_ADDRESS_OK" --worker rig7 --device cpu --cpu-workers 2
  assert_status 0
  assert_contains "$output" "Pule są NIEOFICJALNE"
  [ ! -e "$QM_DIR/bin/quantus-node" ]
  [ ! -e "$QM_DIR/node_key.p2p" ]
  assert_equal "$(CONF MODE) $(CONF POOL_NAME) $(CONF POOL_ADDR) $(CONF POOL_FP)" "pool nurserypool $NURSERY_ADDR $NURSERY_FP"
  assert_equal "$(CONF PAYOUT_ADDRESS) $(CONF WORKER_NAME)" "$PAYOUT_ADDRESS_OK rig7"
  run qm start
  assert_status 0
  assert_contains "$output" "Miner łączy się z pulą nurserypool ($NURSERY_ADDR). Panel puli: https://quan.nurserypool.com"
  wait_miner
  assert_equal "$(miner_argv)" "$(lines serve --metrics-port 9900 --node-addr "$NURSERY_ADDR" \
    --auth-token "$PAYOUT_ADDRESS_OK.rig7" --tls-cert-sha256 "$NURSERY_FP" --cpu-workers 2 --gpu-devices 0)"
  [ ! -e "$QM_FAKE/node.calls" ]
  [ -z "$(qm_node_pid)" ]
  run qm status
  assert_status 0
  assert_contains "$output" "Pula: nurserypool ($NURSERY_ADDR)   wypłaty na: $PAYOUT_ADDRESS_OK   panel: https://quan.nurserypool.com"
  run qm stop
  assert_status 0
  no_procs 3
}

@test "pool (custom): fingerprint is lower-cased; host names and bad IPs are rejected" {
  run qm setup --yes --pool custom --pool-addr 10.20.30.40:7777 --payout-address "$PAYOUT_ADDRESS_OK" --device cpu
  assert_status 1
  assert_contains "$output" "Dla --pool custom podaj --pool-addr IP:PORT i --pool-fp"
  run qm setup --yes --pool custom --pool-addr 10.20.30.40:7777 --pool-fp "${QUANPOOL_FP^^}" \
    --payout-address "$PAYOUT_ADDRESS_OK" --worker w1 --device cpu
  assert_status 0
  assert_equal "$(CONF POOL_ADDR) $(CONF POOL_FP)" "10.20.30.40:7777 $QUANPOOL_FP"
  run qm setup --yes --pool custom --pool-addr pool.example.com:7777 --pool-fp "$QUANPOOL_FP" --payout-address "$PAYOUT_ADDRESS_OK" --device cpu
  assert_status 1
  assert_contains "$output" "--pool-addr musi być adresem IP:port"
  run qm setup --yes --pool custom --pool-addr 300.20.30.40:7777 --pool-fp "$QUANPOOL_FP" --payout-address "$PAYOUT_ADDRESS_OK" --device cpu
  assert_status 1
  assert_contains "$output" "--pool-addr musi być adresem IP:port"
  assert_equal "$(CONF POOL_ADDR)" "10.20.30.40:7777"      # the rejected runs changed nothing
}

@test "pool: --yes without a payout address refuses; a bad payout address is rejected" {
  run qm setup --yes --pool quanpool --device cpu
  assert_status 1
  assert_contains "$output" "W trybie puli podaj --payout-address qz"
  run qm setup --yes --pool quanpool --device cpu --payout-address "$FAKE_INNER"
  assert_status 1
  assert_contains "$output" "Adres wypłat z puli wygląda na błędny adres"
}

# ---------------------------------------------------------------------------------------------
# GPU (NVIDIA CUDA)
# ---------------------------------------------------------------------------------------------
@test "gpu setup: driver 580 accepted; NVRTC 12.8 unpacked into the kit without sudo; CUDA self-test" {
  setup_gpu
  assert_status 0
  assert_contains "$output" "GPU: NVIDIA GeForce RTX 4090, sterownik 580.82.07"
  assert_contains "$output" "Suma SHA-256 poprawna: nvrtc.deb"
  assert_contains "$output" "NVRTC 12.8 gotowy (CUDA)."
  assert_contains "$output" "CUDA działa: Average rate: 818.52M H/s"
  local lib="$QM_DIR/nvrtc/$NVRTC_SUBDIR"
  [ -f "$lib/libnvrtc.so.12" ]
  [ -L "$lib/libnvrtc.so" ]
  assert_equal "$(readlink "$lib/libnvrtc.so")" libnvrtc.so.12
  assert_equal "$(cat "$QM_FAKE/bench.argv")" "$(lines benchmark --cuda-gpu --gpu-devices 1 --cpu-workers 0 --duration 5)"
  assert_file_contains "$QM_FAKE/bench.env" "LD_LIBRARY_PATH=$lib"
  [ ! -e "$QM_FAKE/sudo.log" ]
  assert_equal "$(CONF DEVICE) $(CONF GPU_DEVICES)" "gpu 1"
}

@test "gpu start: miner runs with --cuda-gpu --gpu-devices 1 --cpu-workers 0 and the kit's NVRTC" {
  setup_gpu
  assert_status 0
  fake_node_synced
  start_bg
  wait_miner
  assert_equal "$(miner_argv)" "$(lines serve --metrics-port 9900 --node-addr 127.0.0.1:9833 \
    --auth-token-file "$(chain_dir)/miner-auth-token" --tls-cert-sha256-file "$(chain_dir)/miner-tls-cert-sha256" \
    --cuda-gpu --gpu-devices 1 --cpu-workers 0)"
  assert_file_contains "$QM_FAKE/miner.env" "LD_LIBRARY_PATH=$QM_DIR/nvrtc/$NVRTC_SUBDIR"
  assert_equal "$(cat "$QM_FAKE/miner.nice")" "$(own_nice_plus 0)"
}

@test "gpu: driver older than 570 is rejected before NVRTC is installed" {
  GPU_DRIVER=565.57.01 setup_gpu
  assert_status 1
  assert_contains "$output" "Sterownik NVIDIA 565.57.01 jest za stary (potrzeba >= 570)"
  [ ! -e "$QM_DIR/nvrtc" ]
  [ ! -e "$QM_DIR/mining.conf" ]
}

@test "gpu: driver 570.x is the minimum and is accepted" {
  GPU_DRIVER=570.86.10 setup_gpu
  assert_status 0
  assert_contains "$output" "sterownik 570.86.10"
}

@test "gpu: --device gpu without an NVIDIA card is refused" {
  qm_use_stub python3
  run qm setup --yes --device gpu --inner-hash "$FAKE_INNER"
  assert_status 1
  assert_contains "$output" "Nie widzę karty NVIDIA"
}

@test "gpu: wrong NVRTC SHA-256 aborts; nothing is unpacked" {
  export QM_NVRTC_SHA256=2222222222222222222222222222222222222222222222222222222222222222
  setup_gpu
  assert_status 1
  assert_contains "$output" "Suma kontrolna się NIE zgadza dla nvrtc.deb"
  [ ! -e "$QM_DIR/nvrtc" ]
  [ ! -e "$QM_DIR/mining.conf" ]
}

@test "gpu: without --device the NVIDIA card is detected automatically" {
  fake_gpu 580.82.07
  qm_use_stub python3
  run qm setup --yes --inner-hash "$FAKE_INNER"
  assert_status 0
  assert_equal "$(CONF DEVICE)" gpu
}

@test "gpu: --gpu-power-limit is applied with sudo nvidia-smi when mining starts" {
  setup_gpu --gpu-power-limit 350
  assert_status 0
  [ ! -e "$QM_FAKE/sudo.log" ]
  start_bg
  assert_file_contains "$QM_FAKE/sudo.log" "nvidia-smi -pm 1"
  assert_file_contains "$QM_FAKE/sudo.log" "nvidia-smi -pl 350"
}

# ---------------------------------------------------------------------------------------------
# systemd service
# ---------------------------------------------------------------------------------------------
@test "install-service: correct unit via sudo; start/stop/status use systemctl; remove-service" {
  qm_use_stub ps
  setup_solo
  run qm install-service
  assert_status 0
  local unit="$QM_SYSTEMD_DIR/quantus-miner-kit.service"
  [ -f "$unit" ]
  assert_equal "$(stat -c %a "$unit")" 644
  assert_file_contains "$unit" "User=$(id -un)"
  assert_file_contains "$unit" "Group=$(id -gn)"
  assert_file_contains "$unit" "Environment=\"HOME=$HOME\""
  assert_file_contains "$unit" "WorkingDirectory=$QM_DIR"
  assert_file_contains "$unit" "ExecStart=/bin/bash \"$QM_DIR/bin/quantus-miner.sh\" _supervise --dir \"$QM_DIR\""
  assert_file_contains "$unit" "Restart=always"
  assert_file_contains "$unit" "WantedBy=multi-user.target"
  refute_file_contains "$unit" "ExecStartPre"
  cmp "$QM_SCRIPT" "$QM_DIR/bin/quantus-miner.sh"
  [ -x "$QM_DIR/bin/quantus-miner.sh" ]
  assert_file_contains "$QM_FAKE/sudo.log" "install -m 644"
  assert_file_contains "$QM_FAKE/sudo.log" "systemctl daemon-reload"
  assert_file_contains "$QM_FAKE/sudo.log" "systemctl enable --now quantus-miner-kit"
  refute qm_supervisor_up                        # systemd runs it, not a background copy
  run qm status
  assert_contains "$output" "Usługa systemd: active"
  run qm stop
  assert_status 0
  assert_contains "$output" "Usługa zatrzymana."
  assert_file_contains "$QM_FAKE/sudo.log" "systemctl stop quantus-miner-kit"
  run qm start
  assert_status 0
  assert_contains "$output" "Usługa systemd jest zainstalowana — uruchamiam przez systemctl."
  assert_file_contains "$QM_FAKE/sudo.log" "systemctl start quantus-miner-kit"
  refute qm_supervisor_up
  run qm remove-service
  assert_status 0
  [ ! -e "$unit" ]
  assert_file_contains "$QM_FAKE/sudo.log" "systemctl disable --now quantus-miner-kit"
}

@test "install-service (gpu + power limit): unit re-applies the limit and the kit copy is used" {
  qm_use_stub ps
  setup_gpu --gpu-power-limit 350
  assert_status 0
  run qm install-service
  assert_status 0
  local unit="$QM_SYSTEMD_DIR/quantus-miner-kit.service"
  # '+' = as root; '-' = a refused limit must not keep the service (and mining) from starting
  assert_file_contains "$unit" "ExecStartPre=-+/usr/bin/nvidia-smi -pm 1"
  assert_file_contains "$unit" "ExecStartPre=-+/usr/bin/nvidia-smi -pl 350"
}

@test "service running + start with changed settings: unit refreshed (power limit) and the service restarted" {
  qm_use_stub ps
  setup_gpu --gpu-power-limit 350
  assert_status 0
  run qm install-service
  assert_status 0
  : >"$QM_FAKE/sudo.log"
  run qm start                                          # nothing changed → nothing restarted
  assert_status 0
  assert_contains "$output" "już działa"
  refute_file_contains "$QM_FAKE/sudo.log" "systemctl restart"
  run qm start --gpu-power-limit 300
  assert_status 0
  assert_contains "$output" "Aktualizuję plik usługi"
  assert_file_contains "$QM_SYSTEMD_DIR/quantus-miner-kit.service" "nvidia-smi -pl 300"
  assert_file_contains "$QM_FAKE/sudo.log" "systemctl daemon-reload"
  assert_file_contains "$QM_FAKE/sudo.log" "systemctl restart quantus-miner-kit"
  assert_contains "$output" "Usługa uruchomiona ponownie z nowymi ustawieniami."
  run qm start --gpu-power-limit off                   # "off" removes the limit from settings and unit
  assert_status 0
  assert_equal "$(CONF GPU_POWER_LIMIT)" ""
  refute_file_contains "$QM_SYSTEMD_DIR/quantus-miner-kit.service" "ExecStartPre"
}

@test "gpu: a power limit outside the card's range is refused at setup" {
  setup_gpu --gpu-power-limit 120
  assert_status 1
  assert_contains "$output" "Limit mocy 120 W jest poza zakresem tej karty (150–600 W)"
  [ ! -e "$QM_DIR/mining.conf" ]
}

@test "systemd mode: the supervisor writes to logs/supervisor.log (so 'logs supervisor' works)" {
  setup_solo
  mkdir -p "$QM_DIR/logs"
  INVOCATION_ID=0123456789abcdef timeout 4 bash "$QM_SCRIPT" _supervise --dir "$QM_DIR" </dev/null >"$BATS_TEST_TMPDIR/journal" 2>&1 3>&- 4>&- || true
  assert_file_contains "$QM_DIR/logs/supervisor.log" "Nadzorca 1.0.0 start"
  refute_file_contains "$BATS_TEST_TMPDIR/journal" "Nadzorca 1.0.0 start"
}

@test "install-service while mining in the background: the background supervisor is stopped first" {
  qm_use_stub ps
  setup_solo
  start_bg
  wait_node
  run qm install-service
  assert_status 0
  assert_contains "$output" "Zatrzymuję kopanie w tle (przejmie je systemd)"
  no_procs 3
  [ -f "$QM_SYSTEMD_DIR/quantus-miner-kit.service" ]
}

@test "install-service without systemd (WSL default): refuses and explains how to enable it" {
  qm_use_stub ps
  echo "init(Ubuntu)" >"$QM_FAKE/pid1_comm"
  setup_solo
  run qm install-service
  assert_status 1
  assert_contains "$output" "systemd nie działa na tym systemie."
  if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    assert_contains "$output" "systemd=true"
    assert_contains "$output" "wsl --shutdown"
  fi
  [ ! -e "$QM_SYSTEMD_DIR/quantus-miner-kit.service" ]
  [ ! -e "$QM_FAKE/sudo.log" ]
}

@test "install-service --dry-run: prints the unit, installs nothing, runs no sudo/systemctl" {
  qm_use_stub ps
  setup_solo
  run qm install-service --dry-run
  assert_status 0
  assert_contains "$output" "[Service]"
  assert_contains "$output" "ExecStart=/bin/bash \"$QM_DIR/bin/quantus-miner.sh\" _supervise --dir \"$QM_DIR\""
  [ ! -e "$QM_SYSTEMD_DIR/quantus-miner-kit.service" ]
  [ ! -e "$QM_FAKE/sudo.log" ]
  [ ! -e "$QM_FAKE/systemctl.log" ]
}

@test "install-service --dry-run does not stop mining that is running in the background" {
  qm_use_stub ps
  setup_solo
  start_bg
  wait_node
  local sp
  sp=$(qm_supervisor_pid)
  run qm install-service --dry-run
  assert_status 0
  assert_equal "$(qm_supervisor_pid)" "$sp"
  qm_node_up
}

@test "install-service also works when run from the kit's own copy (bin/quantus-miner.sh)" {
  qm_use_stub ps
  setup_solo
  mkdir -p "$QM_DIR/bin"
  install -m 755 "$QM_SCRIPT" "$QM_DIR/bin/quantus-miner.sh"
  run timeout 60 bash "$QM_DIR/bin/quantus-miner.sh" install-service </dev/null 3>&- 4>&-
  assert_status 0
  [ -f "$QM_SYSTEMD_DIR/quantus-miner-kit.service" ]
}

# ---------------------------------------------------------------------------------------------
# dry-run
# ---------------------------------------------------------------------------------------------
@test "start --dry-run with the systemd service installed does not start the service" {
  qm_use_stub ps
  setup_solo
  run qm install-service
  assert_status 0
  run qm stop
  assert_status 0
  : >"$QM_FAKE/sudo.log"
  run qm start --dry-run
  assert_status 0
  refute_file_contains "$QM_FAKE/sudo.log" "systemctl start"
  [ ! -e "$QM_FAKE/service.active" ]
}

@test "start --dry-run: prints the supervisor command and starts nothing" {
  setup_solo
  run qm start --dry-run
  assert_status 0
  assert_contains "$output" "[dry-run] setsid nohup bash $(readlink -f "$QM_SCRIPT") _supervise --dir $QM_DIR"
  sleep 1
  refute qm_supervisor_up
  [ ! -e "$QM_DIR/run/supervisor.pid" ]
  [ ! -e "$QM_FAKE/node.starts" ]
  no_procs 1
}

@test "start --dry-run never changes the GPU power limit" {
  setup_gpu --gpu-power-limit 350
  assert_status 0
  run qm start --dry-run
  assert_status 0
  refute_file_contains "$QM_FAKE/sudo.log" "nvidia-smi -pl"
}

# ---------------------------------------------------------------------------------------------
# other commands
# ---------------------------------------------------------------------------------------------
@test "difficulty: real SCALE answers → difficulty, block time, reward and solo estimates" {
  run qm difficulty
  assert_status 0
  # D = 301898347444336; 300 blocks in 4110 s; R = (21e6 - 5677021.41) / 5e7
  assert_contains "$output" "Trudność (D): 3.019e+14"
  assert_contains "$output" "Średni czas bloku (ostatnie 300): 13.70 s   → moc sieci ≈ 22.04 TH/s"
  assert_contains "$output" "Nagroda za blok ≈ 0.3065 QTC (+ opłaty)   bloków/dzień ≈ 6307   emisja ≈ 1933 QTC/dzień"
  [[ $output =~ RTX\ 4090\ \(~820\ MH/s,\ CUDA\)\ +820\.0\ MH/s\ +0\.0719\ QTC/dzień\ +średnio\ 1\ blok\ co\ 4\.3\ dni ]] \
    || { echo "$output" >&2; false; }
  refute_contains "$output" "Twoja koparka"
  # the local node was down → the public RPC was used, and nothing unexpected was contacted
  assert_file_contains "$QM_FAKE/curl.log" "$QM_PUBLIC_RPC"
  [ ! -e "$QM_FAKE/curl.unexpected" ]
}

@test "difficulty --hashrate 820: adds the user's own row" {
  run qm difficulty --hashrate 820
  assert_status 0
  [[ $output =~ Twoja\ koparka\ +820\.0\ MH/s\ +0\.0719\ QTC/dzień ]] || { echo "$output" >&2; false; }
}

@test "benchmark (cpu): runs the miner benchmark with the configured workers" {
  setup_solo
  run qm benchmark --duration 3
  assert_status 0
  assert_contains "$output" "Average rate: 818.52M H/s"
  assert_equal "$(cat "$QM_FAKE/bench.argv")" "$(lines benchmark --duration 3 --cpu-workers 3 --gpu-devices 0)"
}

@test "solo mode on an old glibc (Ubuntu 22.04: 2.35) is refused before downloading; pool mode is allowed" {
  qm_use_stub ldd
  echo 2.35 >"$QM_FAKE/glibc"
  run qm setup --yes --key new --device cpu
  assert_status 1
  assert_contains "$output" "Node v1.0.1 wymaga glibc >= 2.38 (masz: 2.35)"
  [ ! -e "$QM_DIR/bin/quantus-node" ]
  [ ! -e "$QM_FAKE/curl.log" ]
  run qm setup --yes --pool nurserypool --payout-address "$PAYOUT_ADDRESS_OK" --device cpu
  assert_status 0
}

@test "benchmark (gpu): CUDA flags and the kit's NVRTC on LD_LIBRARY_PATH" {
  setup_gpu
  assert_status 0
  run qm benchmark --duration 4
  assert_status 0
  assert_contains "$output" "Average rate: 818.52M H/s"
  assert_equal "$(cat "$QM_FAKE/bench.argv")" "$(lines benchmark --duration 4 --cuda-gpu --gpu-devices 1 --cpu-workers 0)"
  assert_file_contains "$QM_FAKE/bench.env" "LD_LIBRARY_PATH=$QM_DIR/nvrtc/$NVRTC_SUBDIR"
}

@test "difficulty: public RPC first (a syncing local node knows only an OLD difficulty); synced local node = fallback" {
  asked() { grep -F -- "$1" "$QM_FAKE/curl.log" | grep -q QPoWApi_get_difficulty; }
  touch "$QM_FAKE/rpc/local/FORCE_UP"
  fake_rpc local state_call '"0x00e1f50500000000"'           # block ~1000: D = 1e8, far too low
  run qm difficulty
  assert_status 0
  assert_contains "$output" "Trudność (D): 3.019e+14"
  refute asked "$QM_LOCAL_RPC"
  # public RPC down + local node still syncing → no guess from the local node
  touch "$QM_FAKE/rpc/public/DOWN"
  : >"$QM_FAKE/curl.log"
  run qm difficulty
  assert_status 1
  assert_contains "$output" "lokalny node nie jest zsynchronizowany"
  refute asked "$QM_LOCAL_RPC"
  # public RPC down + local node synced on mainnet → the local node answers
  fake_node_synced
  fake_rpc local state_call "\"$DIFFICULTY_HEX\""
  run qm difficulty
  assert_status 0
  assert_contains "$output" "Trudność (D): 3.019e+14"
  asked "$QM_LOCAL_RPC"
}

@test "difficulty/status without the indexer: says so instead of showing made-up numbers" {
  setup_solo
  rm -f "$QM_FAKE/indexer/blocks" "$QM_FAKE/indexer/account_stats"
  run qm difficulty
  assert_status 0
  assert_contains "$output" "Czas bloku (brak danych z indeksatora — przyjęto cel 12): 12 s"
  refute_contains "$output" "ostatnie 300"
  run qm status
  assert_status 0
  assert_contains "$output" "Wykopane bloki (łańcuch): ? (brak odpowiedzi indeksatora)"
  # the real indexer answers {"s":null} for an address without any mined block yet → 0, not "?"
  printf '%s\n' '{"data":{"s":null}}' >"$QM_FAKE/indexer/account_stats"
  run qm status
  assert_contains "$output" "Wykopane bloki (łańcuch): 0   zgłoszone przez ten node (log): 0"
  # hints mention --dir when the kit is not in the default directory (tests use a sandbox dir)
  assert_contains "$output" "--dir $QM_DIR start"
}

@test "help, unknown command/option, logs without logs, stop/status when nothing runs" {
  run qm help
  assert_status 0
  assert_contains "$output" "Użycie:"
  assert_contains "$output" "install-service"
  run qm --help
  assert_status 0
  run qm bogus
  assert_status 1
  assert_contains "$output" "Nieznane polecenie: bogus"
  run qm start --bogus
  assert_status 1
  assert_contains "$output" "Nieznana opcja: --bogus"
  run qm logs
  assert_status 1
  assert_contains "$output" "Brak logów"
  run qm logs bogus
  assert_status 1
  assert_contains "$output" "Nieznany log 'bogus'"
  run qm stop
  assert_status 0
  assert_contains "$output" "Zatrzymano."
  run qm status
  assert_status 0
  assert_contains "$output" "Nadzorca: nie działa"
  [ ! -e "$QM_FAKE/curl.unexpected" ]
}

@test "logs node: follows the node log" {
  mkdir -p "$QM_DIR/logs"
  echo "hello from the node log" >"$QM_DIR/logs/node.log"
  QM_CMD_TIMEOUT=2 run qm logs node
  assert_status 124                  # tail -F runs until interrupted
  assert_contains "$output" "hello from the node log"
}

# ---------------------------------------------------------------------------------------------
# review round 1 (2026-09-10): settings changes, rejected keys, safer defaults
# ---------------------------------------------------------------------------------------------
@test "start with changed settings while mining in the background: restarts with the new settings" {
  setup_solo
  fake_node_synced
  start_bg
  wait_miner
  local sp
  sp=$(qm_supervisor_pid)
  run qm start                                          # same settings → just "already running"
  assert_status 0
  assert_contains "$output" "Kopanie już działa."
  run qm start --cpu-workers 2
  assert_status 0
  assert_contains "$output" "Ustawienia się zmieniły — uruchamiam kopanie ponownie"
  wait_for 15 qm_supervisor_up
  [ "$(qm_supervisor_pid)" != "$sp" ]
  wait_miner
  workers_now() { [[ $(sed -n '/^--cpu-workers$/{n;p}' "$QM_FAKE/miner.argv" 2>/dev/null) == "$1" ]]; }
  wait_for 15 workers_now 2
  assert_equal "$(CONF CPU_WORKERS)" 2
}

@test "a rewards key the node rejects (not a canonical Poseidon digest) stops the supervisor instead of looping" {
  run qm setup --yes --device cpu --inner-hash "$FAKE_INNER"
  assert_status 0
  touch "$QM_FAKE/node.bad_hash"
  run qm start
  assert_status 0
  wait_for 15 qm_supervisor_down || { sup_log >&2; false; }
  assert_contains "$(sup_log)" "BŁĄD: node odrzuca Inner Hash z ustawień"
  assert_contains "$(sup_log)" "setup --key new"
  assert_equal "$(qm_count_lines "$QM_FAKE/node.starts")" 1
  no_procs 3
}

@test "second computer: --inner-hash + --rewards-address; a mistyped hash (other address) stops mining" {
  # right pair (as printed by `rewards` on the first computer) → mines normally
  run qm setup --yes --device cpu --rewards-address "$FAKE_ADDRESS" --inner-hash "$FAKE_INNER"
  assert_status 0
  assert_equal "$(CONF INNER_HASH) $(CONF REWARDS_ADDRESS)" "$FAKE_INNER $FAKE_ADDRESS"
  fake_node_synced
  start_bg
  wait_miner
  wait_log "Nagrody idą na adres (według node'a): $FAKE_ADDRESS"
  run qm stop
  assert_status 0
  # typo in the hash → the node would pay another address → the supervisor refuses to mine
  run qm setup --yes --device cpu --inner-hash "$IMPORT_INNER" --rewards-address "$FAKE_ADDRESS"
  assert_status 0
  rm -f "$QM_FAKE/miner.starts"
  run qm start
  assert_status 0
  wait_for 15 qm_supervisor_down || { sup_log >&2; false; }
  assert_contains "$(sup_log)" "BŁĄD: node kopałby na adres $IMPORT_ADDRESS, a oczekiwany adres nagród to $FAKE_ADDRESS"
  [ ! -e "$QM_FAKE/miner.starts" ]
  no_procs 3
  # status shows the node's address and the mismatch
  run qm status
  assert_contains "$output" "Uwaga: node kopie na adres $IMPORT_ADDRESS, a w ustawieniach zapisano $FAKE_ADDRESS"
}

@test "rewards: prints the Inner Hash, the address and a ready command for the second computer" {
  setup_solo
  run qm rewards
  assert_status 0
  assert_contains "$output" "Inner Hash:   $FAKE_INNER"
  assert_contains "$output" "Adres nagród: $FAKE_ADDRESS"
  assert_contains "$output" "./quantus-miner.sh start --inner-hash $FAKE_INNER --rewards-address $FAKE_ADDRESS"
  assert_contains "$output" "--device gpu"
  refute_contains "$output" "abandon"
}

@test "ZAPISAŁEM is accepted in any case (zapisałem, Zapisalem); a wrong answer asks again instead of aborting" {
  command -v script >/dev/null 2>&1 || skip "util-linux 'script' (pty) not available"
  run qm_tty $'zapisalem ok\nZapisałem\nabandon\nability\nable\n' setup --key new --device cpu
  assert_status 0
  assert_contains "$output" "Nie rozpoznałem odpowiedzi"
  assert_equal "$(CONF INNER_HASH)" "$FAKE_INNER"
  assert_equal "$(grep -c 'key quantus' "$QM_FAKE/node.calls")" 1     # still the same phrase
}

@test "mining.conf with Windows line endings (CRLF) is read correctly" {
  setup_solo
  sed -i 's/$/\r/' "$QM_DIR/mining.conf"
  run qm status
  assert_status 0
  refute_contains "$output" "Błędne ustawienia"
  assert_contains "$output" "Tryb: solo   Urządzenie: cpu"
}

@test "restart with the default 5 s supervisor tick: no leftover process keeps the supervisor lock" {
  setup_solo
  export QM_TICK=5
  start_bg
  wait_node
  sleep 1
  run qm stop
  assert_status 0
  flock -n "$QM_DIR/run/supervisor.lock" true || { echo "supervisor.lock still held after stop:" >&2; qm_show_procs >&2; false; }
  run qm start
  assert_status 0
  assert_contains "$output" "Wystartowano!"
  wait_for 15 qm_supervisor_up
}

@test "status: stale pid files, an inactive service, 0 peers and a crash-looping miner are reported honestly" {
  qm_use_stub ps
  setup_solo
  sleep 60 3>&- 4>&- & local stray=$!
  mkdir -p "$QM_DIR/run"
  echo "$stray" >"$QM_DIR/run/node.pid"; echo "$stray" >"$QM_DIR/run/miner.pid"
  run qm status
  kill "$stray" 2>/dev/null || true
  assert_contains "$output" "Node:  nie działa"
  assert_contains "$output" "Miner: nie działa"
  # service installed but inactive: one line, no stray '?'
  run qm install-service
  assert_status 0
  run qm stop
  run qm status
  assert_contains "$output" "Usługa systemd: inactive"
  refute_contains "$output" $'\n?'
  run qm remove-service
  # 0 peers: never "zakończona", even though the node says isSyncing=false
  fake_rpc local system_health '{"peers":0,"isSyncing":false,"shouldHavePeers":true}'
  start_bg
  wait_node
  run qm status
  assert_contains "$output" "synchronizacja: brak połączeń z siecią (peers: 0)"
  run qm stop
  # synced, but the miner dies on every start → not "czeka na synchronizację"
  fake_node_synced
  echo 1 >"$QM_FAKE/miner.exit_code"
  start_bg
  wait_log "Miner zakończył działanie (kod 1)."
  run qm status
  assert_contains "$output" "Miner: nie działa (wyłącza się i jest uruchamiany ponownie"
}

@test "benchmark works before setup (the bin/ directory is created)" {
  run qm benchmark --device cpu --cpu-workers 2 --duration 3
  assert_status 0
  assert_contains "$output" "Average rate: 818.52M H/s"
  [ -x "$QM_DIR/bin/quantus-miner" ]
}

@test "settings: node names with '.' (refused by the node) and values with line breaks are rejected" {
  run qm setup --yes --device cpu --inner-hash "$FAKE_INNER" --name rig.1
  assert_status 1
  assert_contains "$output" "Nazwa node'a: tylko litery/cyfry/_- (bez kropek"
  run qm setup --yes --device cpu --inner-hash "$FAKE_INNER" --payout-address "$(printf 'qzjunk\nINNER_HASH=0xbad')"
  assert_status 1
  [ ! -e "$QM_DIR/mining.conf" ]
  run qm setup --yes --device cpu --inner-hash "$FAKE_INNER" --worker "$(printf 'w1\nMODE=pool')"
  assert_status 1
  [ ! -e "$QM_DIR/mining.conf" ]
}

@test "--dir with a relative path is turned into an absolute one (systemd needs absolute paths)" {
  cd "$QM_SANDBOX"
  run env -u QM_DIR timeout 60 bash "$QM_SCRIPT" setup --yes --device cpu --inner-hash "$FAKE_INNER" --dir relkit </dev/null 3>&- 4>&-
  assert_status 0
  assert_contains "$output" "katalog: $QM_SANDBOX/relkit"
  [ -f "$QM_SANDBOX/relkit/mining.conf" ]
}

@test "gpu without any NVIDIA driver (no nvidia-smi at all): the driver hint, not a wrong apt hint" {
  rm -f "$QM_STUB_BIN/nvidia-smi"
  command -v nvidia-smi >/dev/null 2>&1 && skip "this host has a real nvidia-smi"
  qm_use_stub python3
  run qm setup --yes --device gpu --inner-hash "$FAKE_INNER"
  assert_status 1
  assert_contains "$output" "Nie widzę karty NVIDIA"
  refute_contains "$output" "Brakuje programów"
}

@test "stop/status with a broken mining.conf: they still work and only warn" {
  setup_solo
  sed -i 's/^CPU_WORKERS=.*/CPU_WORKERS=0/' "$QM_DIR/mining.conf"
  run qm status
  assert_status 0
  assert_contains "$output" "Błędne ustawienia w $QM_DIR/mining.conf"
  run qm start
  assert_status 1
  assert_contains "$output" "CPU_WORKERS musi być liczbą 1..1024"
}
