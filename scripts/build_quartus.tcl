# RISC-V Processor Quartus Build Script
# Creates Quartus project and runs synthesis

# Project configuration
set project_name "riscv_processor_quartus"
set project_dir "./build/quartus"
set device_family "Cyclone V"
set device_part "5CGXFC7C7F23C8"

puts "========================================="
puts "RISC-V Processor Quartus Build"
puts "========================================="
puts "Target Device: $device_part"
puts "Project Name: $project_name"
puts ""

# Create project directory
file mkdir $project_dir

# Remove existing project if it exists
if {[file exists $project_dir/$project_name.qpf]} {
    puts "Removing existing project..."
    file delete -force $project_dir/$project_name.qpf
    file delete -force $project_dir/$project_name.qsf
}

# Create new Quartus project
puts "Creating Quartus project..."
cd $project_dir

# Create project files
set qpf_file [open "$project_name.qpf" w]
puts $qpf_file "QUARTUS_VERSION = \"22.1\""
puts $qpf_file "PROJECT_REVISION = \"$project_name\""
close $qpf_file

set qsf_file [open "$project_name.qsf" w]
puts $qsf_file "set_global_assignment -name FAMILY \"$device_family\""
puts $qsf_file "set_global_assignment -name DEVICE $device_part"
puts $qsf_file "set_global_assignment -name TOP_LEVEL_ENTITY riscv_processor"
puts $qsf_file "set_global_assignment -name ORIGINAL_QUARTUS_VERSION 22.1"
puts $qsf_file "set_global_assignment -name PROJECT_CREATION_TIME_DATE \"[clock format [clock seconds]]\""
puts $qsf_file "set_global_assignment -name LAST_QUARTUS_VERSION \"22.1\""
puts $qsf_file "set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files"
puts $qsf_file "set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256"
puts $qsf_file "set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0"
puts $qsf_file "set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85"
puts $qsf_file "set_global_assignment -name POWER_PRESET_COOLING_SOLUTION \"23 MM HEAT SINK WITH 200 LFPM AIRFLOW\""
puts $qsf_file "set_global_assignment -name POWER_BOARD_THERMAL_MODEL \"NONE (CONSERVATIVE)\""

# Add source files
puts $qsf_file ""
puts $qsf_file "# Source files"
puts $qsf_file "set_global_assignment -name VERILOG_FILE ../../src/riscv_processor.v"
puts $qsf_file "set_global_assignment -name VERILOG_FILE ../../src/program_counter.v"
puts $qsf_file "set_global_assignment -name VERILOG_FILE ../../src/instruction_memory.v"
puts $qsf_file "set_global_assignment -name VERILOG_FILE ../../src/register_file.v"
puts $qsf_file "set_global_assignment -name VERILOG_FILE ../../src/Control_unit.v"
puts $qsf_file "set_global_assignment -name VERILOG_FILE ../../src/immediate_generator.v"
puts $qsf_file "set_global_assignment -name VERILOG_FILE ../../src/alu.v"
puts $qsf_file "set_global_assignment -name VERILOG_FILE ../../src/data_memory.v"
puts $qsf_file "set_global_assignment -name HEX_FILE ../../instruction_memory.hex"

# Add constraint files
puts $qsf_file ""
puts $qsf_file "# Constraint files"
puts $qsf_file "set_global_assignment -name SDC_FILE ../../constraints/riscv_processor.sdc"

# Pin assignments (example for DE10-Nano board)
puts $qsf_file ""
puts $qsf_file "# Pin assignments"
puts $qsf_file "set_location_assignment PIN_V11 -to clk"
puts $qsf_file "set_location_assignment PIN_Y16 -to reset"
puts $qsf_file "set_io_standard \"3.3-V LVTTL\" -to clk"
puts $qsf_file "set_io_standard \"3.3-V LVTTL\" -to reset"

# Debug pin assignments (LEDs)
for {set i 0} {$i < 8} {incr i} {
    puts $qsf_file "set_location_assignment PIN_W15 -to pc_debug\[$i\]"
    puts $qsf_file "set_io_standard \"3.3-V LVTTL\" -to pc_debug\[$i\]"
}

close $qsf_file

cd ../..

puts "========================================="
puts "PROJECT CREATION SUMMARY"
puts "========================================="
puts "Project created successfully!"
puts "Project location: $project_dir"
puts "Top module: riscv_processor"
puts "Target device: $device_part"
puts ""
puts "Next steps:"
puts "   1. Open project: quartus $project_dir/$project_name.qpf"
puts "   2. Run synthesis: quartus_map $project_name"
puts "   3. Run place & route: quartus_fit $project_name"
puts "   4. Generate timing: quartus_sta $project_name"
puts "   5. Generate bitstream: quartus_asm $project_name"
puts "========================================="