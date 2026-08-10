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

launch_simulation -mode behavioral
run all
close_sim -quiet
close_project
puts "Simulation $test_name completed."