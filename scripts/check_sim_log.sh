#!/usr/bin/env bash
# Verify a Vivado xsim simulation actually ran and passed.
#
# This runs in the Makefile's shell AFTER Vivado returns, so it survives the case
# where xsim fails to launch and issues `exit`, terminating the Vivado batch with
# code 0 before run_simulation.tcl's own checks can run. run_simulation.tcl deletes
# the stale log before launching, so a missing/empty log here means the engine did
# not run.
#
# Usage: check_sim_log.sh <test_name>
set -u
test_name="${1:?usage: check_sim_log.sh <test_name>}"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
log="$repo_root/build/simulations/$test_name/riscv_sim_$test_name.sim/sim_1/behav/xsim/simulate.log"

if [ ! -s "$log" ]; then
    echo "ERROR: $test_name: xsim log missing or empty (engine did not run): $log" >&2
    exit 1
fi
if grep -qE 'FAIL:|TESTS FAILED|COMPLIANCE FAILURES DETECTED|Fatal error|FATAL|ERROR:' "$log"; then
    echo "ERROR: $test_name: failure markers found in xsim log: $log" >&2
    exit 1
fi
if [ "$test_name" != "benchmark" ] && ! grep -q 'PASSED' "$log"; then
    echo "ERROR: $test_name: no PASSED banner in xsim log: $log" >&2
    exit 1
fi
echo "Simulation $test_name verified PASS (xsim log checked)."