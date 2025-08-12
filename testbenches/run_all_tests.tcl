# RISC-V Processor Test Runner
# Runs all testbenches for comprehensive verification

puts "========================================="
puts "RISC-V Processor v1.0.0 Test Suite"
puts "========================================="

# Set up project
set project_name "riscv_test"
set project_dir "./test_project"

# Create project if it doesn't exist
if {![file exists $project_dir]} {
    create_project $project_name $project_dir -part xc7a35tcpg236-1
    
    # Add source files
    add_files -norecurse {
        ../src/alu.v
        ../src/control_unit.v
        ../src/register_file.v
        ../src/immediate_generator.v
        ../src/program_counter.v
        ../src/instruction_memory.v
        ../src/data_memory.v
        ../src/branch_unit.v
        ../src/riscv_processor.v
    }
    
    # Add testbench files
    add_files -fileset sim_1 -norecurse {
        alu_tb.v
        control_unit_tb.v
        register_file_tb.v
        memory_tb.v
        riscv_processor_tb.v
    }
    
    update_compile_order -fileset sources_1
    update_compile_order -fileset sim_1
} else {
    open_project $project_dir/$project_name.xpr
}

# Function to run a testbench
proc run_testbench {tb_name} {
    puts "\n--- Running $tb_name ---"
    set_property top $tb_name [get_filesets sim_1]
    launch_simulation
    run all
    close_sim
}

# Run all testbenches
puts "\n🧪 Starting comprehensive test suite..."

# Test 1: ALU
run_testbench "alu_tb"

# Test 2: Control Unit
run_testbench "control_unit_tb"

# Test 3: Register File
run_testbench "register_file_tb"

# Test 4: Memory Modules
run_testbench "memory_tb"

# Test 5: Complete System
run_testbench "riscv_processor_tb"

puts "\n========================================="
puts "All tests completed!"
puts "Check simulation logs for detailed results"
puts "========================================="