# RISC-V Processor Synthesis Script
# Run synthesis and check for errors

# Open the project
open_project ./projects/vivado/riscv_processor_v1/riscv_processor_v1.xpr

puts "========================================="
puts "Running RISC-V Processor Synthesis"
puts "========================================="

# Reset synthesis run
reset_run synth_1

# Launch synthesis
puts "Starting synthesis..."
launch_runs synth_1 -jobs 4

# Wait for synthesis to complete
wait_on_run synth_1

# Check synthesis results
set synth_status [get_property STATUS [get_runs synth_1]]
set synth_progress [get_property PROGRESS [get_runs synth_1]]

puts ""
puts "========================================="
puts "SYNTHESIS RESULTS"
puts "========================================="
puts "Status: $synth_status"
puts "Progress: $synth_progress"

if {$synth_progress == "100%"} {
    puts "Synthesis completed successfully!"
    
    # Open synthesized design
    open_run synth_1 -name synth_1
    
    # Generate utilization report
    puts ""
    puts "Generating utilization report..."
    report_utilization -file ./reports/utilization_synth.rpt
    
    # Generate timing summary
    puts "Generating timing report..."
    report_timing_summary -file ./reports/timing_synth.rpt
    
    # Print basic utilization
    puts ""
    puts "Resource Utilization:"
    puts "LUT: [get_property USED [get_cells -hierarchical -filter {PRIMITIVE_TYPE =~ LUT*}]]"
    puts "FF: [get_property USED [get_cells -hierarchical -filter {PRIMITIVE_TYPE =~ FD*}]]"
    puts "BRAM: [get_property USED [get_cells -hierarchical -filter {PRIMITIVE_TYPE =~ RAMB*}]]"
    puts "DSP: [get_property USED [get_cells -hierarchical -filter {PRIMITIVE_TYPE =~ DSP*}]]"
    
    puts ""
    puts "SUCCESS: Design synthesized without errors!"
    
} else {
    puts "ERROR: Synthesis failed or incomplete"
    puts "Check synthesis log for details"
}

puts "========================================="

close_project