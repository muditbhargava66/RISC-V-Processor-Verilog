# Run one test in a disposable Vivado project under build/simulations/.
# Usage: vivado -mode batch -source scripts/run_simulation.tcl -tclargs <test-name>

catch {close_project -quiet}

set test_name "system"
if {$argc > 0} {
    set test_name [lindex $argv 0]
}

set repo_root [file normalize [file join [file dirname [info script]] ..]]
set part_name "xc7a35tcpg236-1"
set core_files [list \
    [file join $repo_root src riscv_processor.v] \
    [file join $repo_root src program_counter.v] \
    [file join $repo_root src instruction_memory.v] \
    [file join $repo_root src register_file.v] \
    [file join $repo_root src Control_unit.v] \
    [file join $repo_root src immediate_generator.v] \
    [file join $repo_root src alu.v] \
    [file join $repo_root src data_memory.v] \
]
set memory_image [file join $repo_root instruction_memory.hex]

switch -- $test_name {
    system { set top_module riscv_processor_tb; set test_files [list [file join $repo_root testbenches riscv_processor_tb.v]] }
    alu { set top_module alu_tb; set test_files [list [file join $repo_root testbenches alu_tb.v]] }
    control { set top_module control_unit_tb; set test_files [list [file join $repo_root testbenches Control_unit_tb.v]] }
    memory { set top_module memory_tb; set test_files [list [file join $repo_root testbenches memory_tb.v]] }
    regfile { set top_module register_file_tb; set test_files [list [file join $repo_root testbenches register_file_tb.v]] }
    compliance { set top_module compliance_tests; set test_files [list [file join $repo_root verification compliance_tests.v]] }
    formal { set top_module formal_verification_tb; set test_files [list [file join $repo_root verification riscv_processor_sva.sv] [file join $repo_root verification formal_verification_tb.sv]] }
    benchmark { set top_module performance_benchmark; set test_files [list [file join $repo_root benchmarks performance_benchmark.v]] }
    default {
        puts "ERROR: Unknown test '$test_name'. Use system, alu, control, memory, regfile, compliance, formal, or benchmark."
        exit 1
    }
}

foreach file [concat $core_files $test_files [list $memory_image]] {
    if {![file exists $file]} {
        puts "ERROR: Missing required file: $file"
        exit 1
    }
}

set run_dir [file join $repo_root build simulations $test_name]
file mkdir [file dirname $run_dir]
puts "========================================="
puts "Running $test_name simulation in $run_dir"
puts "========================================="

create_project "riscv_sim_$test_name" $run_dir -part $part_name -force
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
add_files -norecurse $core_files
add_files -norecurse $memory_image
set_property file_type {Memory File} [get_files $memory_image]
add_files -fileset sim_1 -norecurse $test_files
add_files -fileset sim_1 -norecurse $memory_image
set_property top $top_module [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

launch_simulation -mode behavioral
run all
close_sim -quiet
close_project
puts "Simulation $test_name completed."
