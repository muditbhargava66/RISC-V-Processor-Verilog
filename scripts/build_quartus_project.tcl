# RISC-V Processor Quartus Build Script
# Intel Quartus Prime TCL script

# Set project variables
set project_name "riscv_processor"
set project_dir "./projects/quartus"
set device_family "Cyclone IV E"
set device_part "EP4CE22F17C6"

puts "========================================="
puts "RISC-V Processor Quartus Project Builder"
puts "========================================="
puts "Target Device: $device_part"
puts "Device Family: $device_family"
puts "Project Name: $project_name"
puts ""

# Load Quartus packages
package require ::quartus::project
package require ::quartus::flow

# Create project directory if it doesn't exist
file mkdir $project_dir

# Change to project directory
cd $project_dir

# Remove existing project if it exists
if {[project_exists $project_name]} {
    puts "Removing existing project..."
    project_close
    file delete -force $project_name.qpf
    file delete -force $project_name.qsf
    file delete -force db
    file delete -force incremental_db
    file delete -force output_files
}

# Create new project
puts "Creating Quartus project..."
project_new $project_name -overwrite

# Set device
puts "Setting target device..."
set_global_assignment -name FAMILY $device_family
set_global_assignment -name DEVICE $device_part
set_global_assignment -name TOP_LEVEL_ENTITY riscv_processor

# Add source files
puts "Adding source files..."
set_global_assignment -name VERILOG_FILE ../../src/alu.v
set_global_assignment -name VERILOG_FILE ../../src/register_file.v
set_global_assignment -name VERILOG_FILE ../../src/control_unit.v
set_global_assignment -name VERILOG_FILE ../../src/immediate_generator.v
set_global_assignment -name VERILOG_FILE ../../src/program_counter.v
set_global_assignment -name VERILOG_FILE ../../src/instruction_memory.v
set_global_assignment -name VERILOG_FILE ../../src/data_memory.v
set_global_assignment -name VERILOG_FILE ../../src/branch_unit.v
set_global_assignment -name VERILOG_FILE ../../src/riscv_processor.v

# Add constraint file (SDC format for Quartus)
puts "Adding timing constraints..."
set_global_assignment -name SDC_FILE ../../constraints/riscv_processor.sdc

# Set compilation settings
puts "Configuring compilation settings..."
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 1
set_global_assignment -name NOMINAL_CORE_SUPPLY_VOLTAGE 1.2V

# Set pin assignments (basic example for DE0-Nano board)
puts "Setting pin assignments..."
set_location_assignment PIN_R8 -to clk
set_location_assignment PIN_J15 -to reset
set_location_assignment PIN_A15 -to pc_debug[0]
set_location_assignment PIN_A13 -to pc_debug[1]
set_location_assignment PIN_B13 -to pc_debug[2]
set_location_assignment PIN_A11 -to pc_debug[3]

# Set I/O standards
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to reset
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to pc_debug[*]

# Save project
puts "Saving project..."
project_close

puts ""
puts "========================================="
puts "PROJECT CREATION SUMMARY"
puts "========================================="
puts "✅ Quartus project created successfully!"
puts "📁 Project location: $project_dir/$project_name.qpf"
puts "🎯 Top module: riscv_processor"
puts "💾 Target device: $device_part"
puts ""
puts "🚀 Next steps:"
puts "   1. Open project: quartus $project_dir/$project_name.qpf"
puts "   2. Compile project: quartus_sh --flow compile $project_name"
puts "   3. Program device: quartus_pgm -c USB-Blaster -m jtag -o p\\;output_files/$project_name.sof"
puts "========================================="