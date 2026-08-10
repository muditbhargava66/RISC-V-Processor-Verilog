# Quick Lint/Elaboration Check Script
# Checks for syntax and elaboration errors in the core RTL
# Does NOT require board-level constraints — this is a pure RTL check.

source [file join [file dirname [info script]] riscv_build_common.tcl]

riscv_build::init_repo_root

puts "========================================="
puts "RISC-V Processor - Quick Lint Check      "
puts "========================================="

catch {close_project -quiet}

set project_name "riscv_lint_check"
set project_dir [file join $riscv_build::repo_root build lint_check]

# Clean up previous lint run
file delete -force $project_dir

# Create project
create_project $project_name $project_dir -part $riscv_build::part_name -force

# Add ONLY the core source files (not minimal or jtag_debug variants)
puts "Adding core source files..."
set source_files [riscv_build::get_core_files]
set memory_image [riscv_build::get_memory_image]

riscv_build::add_source_files $source_files $memory_image

# No constraint file — lint checking the core RTL does not need board-level pins.

# Set top module
set_property top riscv_processor [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

puts ""
puts "--- Running Syntax Check ---"
# Check syntax
foreach f [get_files -of_objects [get_filesets sources_1]] {
    puts "Checking: [file tail $f]"
}

puts ""
puts "--- Running Synthesis (Lint Mode) ---"

# Run synthesis for quick lint
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
set synth_progress [get_property PROGRESS [get_runs synth_1]]

puts ""
puts "========================================="
puts "LINT CHECK RESULTS"
puts "========================================="
puts "Status: $synth_status"
puts "Progress: $synth_progress"

if {$synth_progress == "100%"} {
    puts "SYNTHESIS: PASSED"

    # Open synthesized design for reports
    open_run synth_1 -name synth_1

    # Quick utilization summary
    puts ""
    puts "--- Resource Utilization ---"
    report_utilization -hierarchical -hierarchical_depth 2

    # Quick timing check
    puts ""
    puts "--- Timing Summary ---"
    report_timing_summary -delay_type max -max_paths 3

    # Check for critical warnings
    puts ""
    puts "--- Critical Warnings ---"
    set msgs [get_msg_config -count -severity {CRITICAL WARNING}]
    puts "Critical Warnings: $msgs"

    # Check for regular warnings
    set warns [get_msg_config -count -severity {WARNING}]
    puts "Warnings: $warns"

} else {
    puts "SYNTHESIS: FAILED"
    puts "Check logs for errors."
}

puts "========================================="

# Save and close
close_project
puts "Lint check completed."