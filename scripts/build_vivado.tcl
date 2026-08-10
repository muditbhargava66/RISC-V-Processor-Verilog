# Create or reuse a Vivado project without touching legacy projects/.
# Usage: vivado -mode batch -source scripts/build_vivado.tcl -tclargs <core|minimal|jtag>

source [file join [file dirname [info script]] riscv_build_common.tcl]

riscv_build::init_repo_root

catch {close_project -quiet}

set target "core"
if {$argc > 0} {
    set target [lindex $argv 0]
}

if {![riscv_build::validate_target $target]} {
    exit 1
}

set project_name [riscv_build::get_target_config $target project_name]
set top_module [riscv_build::get_target_config $target top_module]
set wrapper_file [riscv_build::get_wrapper_file $target]
set constraint_file [riscv_build::get_constraint_file $target]

set build_root [file join $riscv_build::repo_root build vivado]
set project_dir [file join $build_root $project_name]
set project_path [file join $project_dir "$project_name.xpr"]
file mkdir $build_root

if {[riscv_build::create_or_open_project $project_name $project_dir $riscv_build::part_name]} {
    exit 0
}

set core_files [riscv_build::get_core_files]
set memory_image [riscv_build::get_memory_image]

riscv_build::add_source_files $core_files $memory_image
riscv_build::add_wrapper_file $wrapper_file

if {![riscv_build::add_constraint_file $constraint_file]} {
    close_project
    exit 1
}

riscv_build::finalize_project $top_module

puts "Project created successfully. Generated files are isolated under build/."