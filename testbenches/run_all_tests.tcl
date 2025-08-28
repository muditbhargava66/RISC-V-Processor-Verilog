# RISC-V Processor Test Runner
# Runs the main system testbench for verification

puts "========================================="
puts "RISC-V Processor v1.0.0 Test Suite"
puts "========================================="

# Set up project
set project_name "riscv_test"
set project_dir "./test_project"

# Clean up previous project
file delete -force $project_dir

create_project $project_name $project_dir -part xc7a35tcpg236-1

# Add source files
add_files -norecurse {
    ../src/alu.v
    ../src/Control_unit.v
    ../src/register_file.v
    ../src/immediate_generator.v
    ../src/program_counter.v
    ../src/instruction_memory.v
    ../src/data_memory.v
    ../src/riscv_processor.v
}

# Add testbench and memory file
add_files -fileset sim_1 -norecurse {
    riscv_processor_tb.v
    instruction_memory.hex
}

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Function to run a testbench
proc run_testbench {tb_name} {
    puts "\n--- Running $tb_name ---"
    set_property top $tb_name [get_filesets sim_1]
    launch_simulation
    run all
    close_sim
}

# Run the main system test
puts "\n🧪 Starting system verification..."
run_testbench "riscv_processor_tb"

puts "\n========================================="
puts "Test completed!"
puts "Check simulation logs for detailed results"
puts "========================================="