
# XSim simulation script for alu_tb
create_project -force temp_proj ./temp_proj -part xc7a35tcpg236-1

# Add source files
add_files -norecurse {
    ../src/alu.v
    ../src/register_file.v
    ../src/control_unit.v
    ../src/immediate_generator.v
}

# Add testbench
add_files -fileset sim_1 -norecurse {
    C:\Users\mudit\OneDrive\Desktop\Projects\RISC-V-Processor-Verilog-\verification\testbenches\unit/alu_tb.sv
}

# Set top module
set_property top alu_tb [get_filesets sim_1]

# Launch simulation
launch_simulation -mode behavioral

# Run simulation
run all

# Close project
close_project
