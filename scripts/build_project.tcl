# RISC-V Processor Enhanced Build Script
# Xilinx Vivado TCL script with comprehensive setup

# Set project variables
set project_name "riscv_processor"
set project_dir "./projects/vivado"
set part_name "xc7a35tcpg236-1"

puts "========================================="
puts "RISC-V Processor Vivado Project Builder"
puts "========================================="
puts "Target Device: $part_name"
puts "Project Name: $project_name"
puts ""

# Create project directory if it doesn't exist
file mkdir $project_dir

# Close any open projects first
catch {close_project -quiet}

# Remove existing project if it exists
if {[file exists $project_dir/$project_name]} {
    puts "Removing existing project..."
    file delete -force $project_dir/$project_name
}

# Create project
puts "Creating Vivado project..."
create_project $project_name $project_dir/$project_name -part $part_name -force

# Add source files
puts "Adding source files..."
add_files -norecurse {
    ./src/alu.v
    ./src/register_file.v
    ./src/control_unit.v
    ./src/immediate_generator.v
    ./src/program_counter.v
    ./src/instruction_memory.v
    ./src/data_memory.v
    ./src/branch_unit.v
    ./src/riscv_processor.v
}

# Add constraint files
puts "Adding constraint files..."
add_files -fileset constrs_1 -norecurse ./constraints/riscv_processor.xdc

# Add testbench files
puts "Adding testbench files..."
add_files -fileset sim_1 -norecurse {
    ./verification/testbenches/unit/alu_tb.v
    ./verification/testbenches/unit/alu_tb.sv
    ./verification/testbenches/unit/register_file_tb.sv
    ./verification/testbenches/unit/control_unit_tb.sv
    ./verification/testbenches/unit/immediate_generator_tb.sv
    ./verification/testbenches/unit/program_counter_tb.sv
    ./verification/testbenches/unit/branch_unit_tb.sv
    ./verification/testbenches/system/simple_processor_tb.v
    ./verification/testbenches/system/processor_system_tb.sv
}

# Set top module
puts "Setting top module..."
set_property top riscv_processor [current_fileset]

# Set simulation top (use simple testbench by default)
set_property top simple_processor_tb [get_filesets sim_1]

# Update compile order
puts "Updating compile order..."
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Set synthesis strategy
puts "Configuring synthesis settings..."
set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]

# Set implementation strategy
puts "Configuring implementation settings..."
set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]

# Configure simulation settings
puts "Configuring simulation settings..."
set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_1]

# Generate project report
puts ""
puts "========================================="
puts "PROJECT CREATION SUMMARY"
puts "========================================="
puts "✅ Project created successfully!"
puts "📁 Project location: $project_dir/$project_name"
puts "🎯 Top module: riscv_processor"
puts "🧪 Simulation top: simple_processor_tb"
puts "📊 Source files: [llength [get_files -of_objects [get_filesets sources_1]]]"
puts "🔧 Testbench files: [llength [get_files -of_objects [get_filesets sim_1]]]"
puts "⚙️  Constraint files: [llength [get_files -of_objects [get_filesets constrs_1]]]"
puts ""
puts "🚀 Next steps:"
puts "   1. Open project: vivado $project_dir/$project_name/$project_name.xpr"
puts "   2. Run simulation: launch_simulation"
puts "   3. Run synthesis: launch_runs synth_1"
puts "   4. Run implementation: launch_runs impl_1"
puts "========================================="

# Save project
save_project_as $project_name $project_dir/$project_name -force