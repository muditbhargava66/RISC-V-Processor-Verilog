# RISC-V Processor v1.0.0 Vivado Build Script
# Production-ready build for version 1.0.0

# Close any existing projects
catch {close_project -quiet}

# Set project variables
set project_name "riscv_processor_v1"
set project_dir "./projects/vivado"
set part_name "xc7a35tcpg236-1"

puts "========================================="
puts "RISC-V Processor v1.0.0 Vivado Build"
puts "========================================="
puts "Target Device: $part_name"
puts "Project Name: $project_name"
puts ""

# Create project directory if it doesn't exist
file mkdir $project_dir

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
    ./src/riscv_processor.v
    ./src/program_counter.v
    ./src/instruction_memory.v
    ./src/register_file.v
    ./src/control_unit.v
    ./src/immediate_generator.v
    ./src/alu.v
    ./src/data_memory.v
    ./src/branch_unit.v
}

# Add constraint files
puts "Adding constraint files..."
add_files -fileset constrs_1 -norecurse ./constraints/riscv_processor.xdc

# Set top module
puts "Setting top module..."
set_property top riscv_processor [current_fileset]

# Update compile order
puts "Updating compile order..."
update_compile_order -fileset sources_1

# Set synthesis strategy for performance
puts "Configuring synthesis settings..."
set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION off [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.BUFG 12 [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION one_hot [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS true [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING off [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC true [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE 5 [get_runs synth_1]

# Set implementation strategy for performance
puts "Configuring implementation settings..."
set_property strategy "Performance_ExplorePostRoutePhysOpt" [get_runs impl_1]
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]

# Generate project report
puts ""
puts "========================================="
puts "PROJECT CREATION SUMMARY"
puts "========================================="
puts "Project created successfully!"
puts "Project location: $project_dir/$project_name"
puts "Top module: riscv_processor"
puts "Source files: [llength [get_files -of_objects [get_filesets sources_1]]]"
puts "Constraint files: [llength [get_files -of_objects [get_filesets constrs_1]]]"
puts ""
puts "Next steps:"
puts "   1. Open project: vivado $project_dir/$project_name/$project_name.xpr"
puts "   2. Run synthesis: launch_runs synth_1"
puts "   3. Run implementation: launch_runs impl_1"
puts "   4. Generate bitstream: launch_runs impl_1 -to_step write_bitstream"
puts "========================================="

# Save project
save_project
close_project

puts "Build script completed successfully!"