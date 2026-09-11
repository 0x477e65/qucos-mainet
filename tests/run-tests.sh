#!/usr/bin/env bash
# Test runner for quantus-miner.sh: (1) ShellCheck, (2) bats unit + integration tests.
#
#   tests/run-tests.sh                 # everything
#   tests/run-tests.sh -f 'pool'       # extra arguments go to bats (e.g. a name filter)
#
# ShellCheck: local `shellcheck` if installed, else the koalaman/shellcheck:stable docker image;
# the script and tests/*.bash strictly, tests/*.bats in bats mode.
# bats: local `bats` (>= 1.5) if installed, else bats-core (pinned tag) cloned into tests/.bats-core
# and run on the host — the host is the real target OS (Ubuntu 24.04: GNU date/stat/flock/setsid).
# Exit code: 0 only when ShellCheck is clean and every bats test passes.
set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
BATS_TAG="v1.11.1"
BATS_REPO="https://github.com/bats-core/bats-core.git"
BATS_DIR="$HERE/.bats-core"
SHELLCHECK_IMAGE="koalaman/shellcheck:stable"

if [[ -t 1 ]]; then G=$'\e[32m' R=$'\e[31m' Y=$'\e[33m' B=$'\e[1m' N=$'\e[0m'; else G="" R="" Y="" B="" N=""; fi
section() { printf '\n%s== %s ==%s\n' "$B" "$1" "$N"; }
verdict() { if [[ $1 == PASS ]]; then printf '%sPASS%s' "$G" "$N"; else printf '%s%s%s' "$R" "$1" "$N"; fi; }

# ------------------------------------------------------------------------------------ ShellCheck
section "ShellCheck"
cd "$ROOT" || exit 2
sc_files=(quantus-miner.sh)
for f in tests/*.bash tests/run-tests.sh; do [[ -f $f ]] && sc_files+=("$f"); done
bats_files=()
for f in tests/*.bats; do [[ -f $f ]] && bats_files+=("$f"); done
# In .bats files, SC2030/SC2031 (each @test is a subshell) and SC2119/SC2120 (helpers with
# optional arguments) are expected noise; everything else — e.g. SC2314 "! does not fail a
# bats test" — is a real test bug.
BATS_SC_EXCLUDE="SC2030,SC2031,SC2119,SC2120"
sc_result=FAIL
if command -v shellcheck >/dev/null 2>&1; then
  SC=(shellcheck)
  echo "using local $(shellcheck --version | sed -n 's/^version: /shellcheck /p')"
elif command -v docker >/dev/null 2>&1; then
  SC=(docker run --rm -v "$ROOT:/mnt:ro" -w /mnt "$SHELLCHECK_IMAGE")
  echo "using docker image $SHELLCHECK_IMAGE"
else
  SC=()
  echo "${Y}Neither shellcheck nor docker is available: install one (sudo apt install shellcheck).${N}"
  sc_result="FAIL (not available)"
fi
if (( ${#SC[@]} )); then
  echo "script + helpers: ${sc_files[*]}"
  sc_ok=1
  "${SC[@]}" -x "${sc_files[@]}" || sc_ok=0
  if (( ${#bats_files[@]} )); then
    echo "test files (bats mode, excluding $BATS_SC_EXCLUDE): ${bats_files[*]}"
    "${SC[@]}" -x -e "$BATS_SC_EXCLUDE" "${bats_files[@]}" || sc_ok=0
  fi
  if (( sc_ok )); then sc_result=PASS; fi
fi
echo "ShellCheck: $(verdict "$sc_result")"

# ------------------------------------------------------------------------------------ bats
section "bats"
bats_version_ok() {  # bats binary → true when >= 1.5 (BATS_TEST_TMPDIR, setup_file, --tap)
  local v major minor
  v=$("$1" --version 2>/dev/null | sed -n 's/^Bats \([0-9][0-9]*\)\.\([0-9][0-9]*\).*/\1 \2/p')
  [[ -n $v ]] || return 1
  read -r major minor <<<"$v"
  (( major > 1 || (major == 1 && minor >= 5) ))
}
BATS=""
if command -v bats >/dev/null 2>&1 && bats_version_ok "$(command -v bats)"; then
  BATS=$(command -v bats)
else
  if [[ ! -x $BATS_DIR/bin/bats ]]; then
    echo "bats not installed — cloning bats-core $BATS_TAG into $BATS_DIR"
    git clone --quiet --depth 1 --branch "$BATS_TAG" "$BATS_REPO" "$BATS_DIR" 2>&1 \
      || { echo "${R}Could not fetch bats-core ($BATS_REPO, $BATS_TAG).${N}"; exit 2; }
  fi
  BATS="$BATS_DIR/bin/bats"
fi
echo "using $BATS ($("$BATS" --version))"

tap=$(mktemp "${TMPDIR:-/tmp}/quantus-miner-tests.XXXXXX")
trap 'rm -f "$tap"' EXIT
"$BATS" --tap "$@" "$HERE/unit.bats" "$HERE/integration.bats" | tee "$tap"
bats_rc=${PIPESTATUS[0]}

planned=$(sed -n 's/^1\.\.\([0-9][0-9]*\)$/\1/p' "$tap" | tail -n 1)
passed=$(grep -c '^ok ' "$tap")
failed=$(grep -c '^not ok ' "$tap")
skipped=$(grep -cE '^ok .* # skip' "$tap")
ran=$(( passed + failed ))
bats_result=PASS
if (( bats_rc != 0 || failed > 0 || ran == 0 || ran != ${planned:-0} )); then bats_result=FAIL; fi

# ------------------------------------------------------------------------------------ summary
section "Summary"
printf 'ShellCheck : %s\n' "$(verdict "$sc_result")"
printf 'bats       : %s — %s tests run (of %s planned): %s passed (%s skipped), %s failed\n' \
  "$(verdict "$bats_result")" "$ran" "${planned:-?}" "$passed" "$skipped" "$failed"
if (( failed > 0 )); then
  echo "Failed tests:"
  sed -n 's/^not ok /  ✖ /p' "$tap"
fi
if [[ $sc_result == PASS && $bats_result == PASS ]]; then
  printf '%sRESULT: PASS%s\n' "$G$B" "$N"
  exit 0
fi
printf '%sRESULT: FAIL%s\n' "$R$B" "$N"
exit 1
