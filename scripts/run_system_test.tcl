# Quick System Test Script
# Runs the main processor testbench

puts "========================================="
puts "RISC-V Processor System Test"
puts "========================================="

# Open the existing project
open_project ./projects/vivado/riscv_processor_v1/riscv_processor_v1.xpr

# Add the system testbench
add_files -fileset sim_1 -norecurse ./testbenches/riscv_processor_tb.v

# Update compile order
update_compile_order -fileset sim_1

# Set testbench as top
set_property top riscv_processor_tb [get_filesets sim_1]

# Run simulation
puts "Starting system simulation..."
launch_simulation

# Run for sufficient time
run 10000ns

puts "System test completed!"
puts "Check simulation waveforms for results"
puts "========================================="