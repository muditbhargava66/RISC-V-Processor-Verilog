# Run synthesis, and optionally implementation, in the generated build/ tree.
# Usage: vivado -mode batch -source scripts/run_synthesis_impl.tcl -tclargs <core|minimal|jtag>

catch {close_project -quiet}

set target "core"
if {$argc > 0} {
    set target [lindex $argv 0]
}

set repo_root [file normalize [file join [file dirname [info script]] ..]]

switch -- $target {
    core { set project_name "riscv_processor_core" }
    minimal { set project_name "riscv_processor_minimal" }
    jtag { set project_name "riscv_processor_jtag_debug" }
    default {
        puts "ERROR: Unknown target '$target'. Use core, minimal, or jtag."
        exit 1
    }
}

set project_path [file join $repo_root build vivado $project_name "$project_name.xpr"]
if {![file exists $project_path]} {
    puts "Generated project does not exist; creating it first."
    source [file join $repo_root scripts build_vivado.tcl]
}

if {![file exists $project_path]} {
    puts "ERROR: Project creation did not produce $project_path"
    exit 1
}

file mkdir [file join $repo_root build reports]
open_project $project_path
update_compile_order -fileset sources_1

puts "========================================="
puts "Running synthesis for $target"
puts "========================================="
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "Synthesis status: $synth_status"
if {![string match "*Complete*" $synth_status]} {
    puts "ERROR: Synthesis failed. Review $project_path.runs/synth_1/runme.log"
    close_project
    exit 1
}

open_run synth_1
report_utilization -file [file join $repo_root build reports "utilization_${target}_synth.rpt"]
report_timing_summary -file [file join $repo_root build reports "timing_${target}_synth.rpt"]

if {$target eq "core"} {
    close_project
    puts "Core synthesis completed successfully. The core has no board-level pin constraints."
    exit 0
}

puts "========================================="
puts "Running implementation for $target"
puts "========================================="
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation status: $impl_status"
if {![string match "*Complete*" $impl_status]} {
    puts "ERROR: Implementation or bitstream generation failed."
    close_project
    exit 1
}

open_run impl_1
report_utilization -file [file join $repo_root build reports "utilization_${target}_impl.rpt"]
report_timing_summary -file [file join $repo_root build reports "timing_${target}_impl.rpt"]
report_power -file [file join $repo_root build reports "power_${target}_impl.rpt"]
report_drc -file [file join $repo_root build reports "drc_${target}_impl.rpt"]
report_methodology -file [file join $repo_root build reports "methodology_${target}_impl.rpt"]
close_project

puts "Implementation and bitstream generation completed successfully."
