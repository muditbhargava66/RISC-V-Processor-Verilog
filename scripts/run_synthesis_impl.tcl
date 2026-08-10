# Run synthesis, and optionally implementation, in the generated build/ tree.
# Usage: vivado -mode batch -source scripts/run_synthesis_impl.tcl -tclargs <core|minimal|jtag>

source [file join [file dirname [info script]] riscv_build_common.tcl>

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
set project_path [file join $riscv_build::repo_root build vivado $project_name "$project_name.xpr"]

if {![file exists $project_path]} {
    puts "Generated project does not exist; creating it first."
    source [file join $riscv_build::repo_root scripts build_vivado.tcl]
}

if {![file exists $project_path]} {
    puts "ERROR: Project creation did not produce $project_path"
    exit 1
}

file mkdir [file join $riscv_build::repo_root build reports]

if {![riscv_build::run_synthesis $project_path]} {
    exit 1
}

open_run synth_1
riscv_build::generate_synth_reports $riscv_build::repo_root $target

if {$target eq "core"} {
    close_project
    puts "Core synthesis completed successfully. The core has no board-level pin constraints."
    exit 0
}

if {![riscv_build::run_implementation $project_path $target]} {
    exit 1
}

open_run impl_1
riscv_build::generate_impl_reports $riscv_build::repo_root $target
close_project

puts "Implementation and bitstream generation completed successfully."