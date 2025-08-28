# Quick System Test Script
# Runs the main processor testbench

puts "========================================="
puts "RISC-V Processor System Test"
puts "========================================="

# Open the existing project
open_project ./projects/vivado/riscv_processor_v1/riscv_processor_v1.xpr

# Add the system testbench and memory file
add_files -fileset sim_1 -norecurse {
    ./testbenches/riscv_processor_tb.v
    ./testbenches/instruction_memory.hex
}

# Update compile order
update_compile_order -fileset sim_1

# Set testbench as top
set_property top riscv_processor_tb [get_filesets sim_1]

# Run simulation
puts "Starting self-checking system simulation..."
launch_simulation

# Run until test completes
run all

puts "System test completed!"
puts "Check simulation log for PASS/FAIL results."
puts "========================================="