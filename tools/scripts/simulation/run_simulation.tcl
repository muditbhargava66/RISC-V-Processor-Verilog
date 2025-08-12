# Vivado Simulation Script for RISC-V Processor

# Set project variables
set project_name "riscv_processor"
set project_dir "./vivado_project"

# Open existing project or create if it doesn't exist
if {[file exists $project_dir]} {
    open_project $project_dir/$project_name.xpr
} else {
    puts "Project not found. Please run synthesis first."
    exit 1
}

# Set simulation options
set_property -name {xsim.simulate.runtime} -value {10us} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

# Set testbench as top
set_property top processor_vivado_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Launch simulation
puts "Starting simulation..."
launch_simulation

# Run simulation
run all

# Generate waveform if GUI is available
if {[info exists env(DISPLAY)]} {
    puts "Opening waveform viewer..."
    open_wave_config
}

puts "Simulation completed!"
puts "Check simulation results in the Vivado simulator."