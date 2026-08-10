# Run implementation for minimal wrapper
# Direct Tcl script to avoid sourcing issues

# Initialize
set repo_root "C:/Users/mudit/Desktop/Projects/RISC-V-Processor-Verilog-"
set part_name "xc7a35tcpg236-1"

set target "minimal"
set project_name "riscv_processor_minimal"
set top_module "riscv_processor_minimal"
set constraint_file "C:/Users/mudit/Desktop/Projects/RISC-V-Processor-Verilog-/constraints/riscv_processor_minimal.xdc"
set wrapper_file "C:/Users/mudit/Desktop/Projects/RISC-V-Processor-Verilog-/src/riscv_processor_minimal.sv"

set build_root "C:/Users/mudit/Desktop/Projects/RISC-V-Processor-Verilog-/build/vivado"
set project_dir "C:/Users/mudit/Desktop/Projects/RISC-V-Processor-Verilog-/build/vivado/riscv_processor_minimal"
set project_path "C:/Users/mudit/Desktop/Projects/RISC-V-Processor-Verilog-/build/vivado/riscv_processor_minimal/riscv_processor_minimal.xpr"

# Open existing project
open_project "C:/Users/mudit/Desktop/Projects/RISC-V-Processor-Verilog-/build/vivado/riscv_processor_minimal/riscv_processor_minimal.xpr"
update_compile_order -fileset sources_1

puts "========================================="
puts "Running synthesis"
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

# Generate synthesis reports
set build_reports "C:/Users/mudit/Desktop/Projects/RISC-V-Processor-Verilog-/build/reports"
file mkdir $build_reports
report_utilization -file "C:/Users/mudit/Desktop/Projects/RISC-V-Processor-Verilog-/build/reports/utilization_minimal_synth.rpt"
report_timing_summary -file [file join $build_reports "timing_minimal_synth.rpt"]

# Run implementation
puts "========================================="
puts "Running implementation for minimal"
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

# Generate implementation reports
set build_reports "C:/Users/mudit/Desktop/Projects/RISC-V-Processor-Verilog-/build/reports"
file mkdir $build_reports
report_utilization -file "C:/Users/mudit/Desktop/Projects/RISC-V-Processor-Verilog-/build/reports/utilization_minimal_impl.rpt"
report_timing_summary -file [file join $build_reports "timing_minimal_impl.rpt"]
report_power -file "C:/Users/mudit/Desktop/Projects/RISC-V-Processor-Verilog-/build/reports/power_minimal_impl.rpt"
report_drc -file "C:/Users/mudit/Desktop/Projects/RISC-V-Processor-Verilog-/build/reports/drc_minimal_impl.rpt"
report_methodology -file [file join $build_reports "methodology_minimal_impl.rpt"]
close_project

puts "Implementation and bitstream generation completed successfully."