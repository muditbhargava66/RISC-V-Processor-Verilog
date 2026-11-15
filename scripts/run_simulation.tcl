# Run one test in a disposable Vivado project under build/simulations/.
# Usage: vivado -mode batch -source scripts/run_simulation.tcl -tclargs <test-name>

source [file join [file dirname [info script]] riscv_build_common.tcl]

riscv_build::init_repo_root

catch {close_project -quiet}

set test_name "system"
if {$argc > 0} {
    set test_name [lindex $argv 0]
}

if {![riscv_build::validate_sim_test $test_name]} {
    exit 1
}

set top_module [riscv_build::get_sim_top_module $test_name]
set test_files [riscv_build::get_sim_test_files $test_name]
set core_files [riscv_build::get_core_files]
set memory_image [riscv_build::get_memory_image]

if {![riscv_build::validate_files [concat $core_files $test_files [list $memory_image]]]} {
    exit 1
}

set run_dir [file join $riscv_build::repo_root build simulations $test_name]
file mkdir [file dirname $run_dir]

riscv_build::create_sim_project $test_name $run_dir $riscv_build::part_name \
    $core_files $memory_image $test_files $top_module

# Path to the xsim simulation log (checked after the run).
set xsim_log [file join $run_dir "riscv_sim_$test_name.sim" sim_1 behav xsim simulate.log]

# Remove any stale log first so a previous successful run cannot mask a current
# failure (xsim may exit before writing a new log if the engine fails to start).
file delete -force $xsim_log

# launch_simulation compiles, elaborates and runs the testbench to $finish.
# A $fatal in the testbench (any failed check) surfaces as a launch error.
# NOTE: if the xsim engine fails to launch, xsim issues `exit` which can terminate
# the whole Vivado batch (exit 0) before the checks below run. The Makefile therefore
# also runs scripts/check_sim_log.sh after Vivado returns to catch that case.
set sim_ok 1
if {[catch {launch_simulation -mode behavioral} launch_err]} {
    puts "ERROR: launch_simulation failed: $launch_err"
    set sim_ok 0
}
close_sim -quiet

# Scan the xsim log for explicit failure markers emitted by the testbenches.
set log_data ""
if {[file exists $xsim_log]} {
    set fh [open $xsim_log r]
    set log_data [read $fh]
    close $fh
}

# The engine must have actually produced output. An empty or missing log means
# xsim failed to launch (e.g. transient "child exe not found"), which
# launch_simulation does not always propagate as a Tcl error.
if {[string trim $log_data] eq ""} {
    puts "ERROR: Simulation $test_name produced no output (xsim engine did not run). See $xsim_log"
    set sim_ok 0
} else {
    # FAIL:/FATAL: testbench self-checks. ERROR: catches xsim runtime errors,
    # including inline SVA assertion violations (else $error(...)).
    if {[regexp {FAIL:|TESTS FAILED|COMPLIANCE FAILURES DETECTED|Fatal error|FATAL|ERROR:} $log_data]} {
        puts "ERROR: Simulation $test_name reported failures (see $xsim_log)."
        set sim_ok 0
    }
    # Self-checking testbenches must reach their success banner. The benchmark
    # is informational (IPC report) and has no pass/fail banner.
    if {$test_name ne "benchmark" && ![regexp {PASSED} $log_data]} {
        puts "ERROR: Simulation $test_name did not reach a PASSED banner (see $xsim_log)."
        set sim_ok 0
    }
}

close_project
if {!$sim_ok} {
    puts "Simulation $test_name FAILED."
    exit 1
}
puts "Simulation $test_name completed successfully."