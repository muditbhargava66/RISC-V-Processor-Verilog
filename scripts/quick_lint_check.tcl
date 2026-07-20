# Synthesis-backed elaboration check for the core. Generated files stay in build/.

catch {close_project -quiet}
set repo_root [file normalize [file join [file dirname [info script]] ..]]
set project_name "riscv_processor_core"
set project_path [file join $repo_root build vivado $project_name "$project_name.xpr"]

if {![file exists $project_path]} {
    puts "Generated core project does not exist; creating it first."
    source [file join $repo_root scripts build_vivado.tcl]
}

if {![file exists $project_path]} {
    puts "ERROR: Core project was not created."
    exit 1
}

open_project $project_path
update_compile_order -fileset sources_1
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

set status [get_property STATUS [get_runs synth_1]]
puts "Lint synthesis status: $status"
if {![string match "*Complete*" $status]} {
    close_project
    exit 1
}

close_project
puts "Core elaboration and synthesis check passed."
