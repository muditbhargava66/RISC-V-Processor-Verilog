# Full-core characterization flow.
#
# Synthesizes AND implements the complete riscv_processor core (every debug port
# retained, no wrapper trimming) on xc7a35tfgg484-1: the SAME xc7a35t die and -1
# speed grade as the Basys3 target (xc7a35tcpg236-1), in a larger 250-user-I/O
# package so all 241 core I/O fit. Absolute logic counts, timing, and utilization
# percentages are directly comparable to the Basys3 minimal/jtag runs; only the
# package differs. Implementation runs to route_design (no bitstream -- this is a
# pin-less characterization build, not a board image).
#
# Usage:   vivado -mode batch -source scripts/run_full_core.tcl
# Reports: build/reports/*_full_*.rpt

source [file join [file dirname [info script]] riscv_build_common.tcl]

riscv_build::init_repo_root
catch {close_project -quiet}

set part "xc7a35tfgg484-1"
set project_name "riscv_processor_full"
set project_dir [file join $riscv_build::repo_root build vivado $project_name]
set project_path [file join $project_dir "$project_name.xpr"]
set reports [file join $riscv_build::repo_root build reports]
file mkdir $reports
file mkdir [file join $riscv_build::repo_root build vivado]

# Force a fresh project so the current source list (incl. divider.sv) is used.
if {[file exists $project_dir]} {
    file delete -force $project_dir
}

puts "========================================="
puts "Full-core characterization: $project_name"
puts "Device: $part (xc7a35t die, -1 speed, 250 user I/O)"
puts "Top: riscv_processor (all debug ports retained)"
puts "========================================="

create_project $project_name $project_dir -part $part
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
riscv_build::add_source_files [riscv_build::get_core_files] [riscv_build::get_memory_image]
if {![riscv_build::add_constraint_file [file join $riscv_build::repo_root constraints riscv_processor_core.xdc]]} {
    close_project
    exit 1
}
set_property top riscv_processor [current_fileset]
update_compile_order -fileset sources_1
close_project

# ---- Synthesis ----
if {![riscv_build::run_synthesis $project_path]} {
    exit 1
}
open_run synth_1
report_utilization -file [file join $reports utilization_full_synth.rpt]
report_utilization -hierarchical -file [file join $reports utilization_full_synth_hier.rpt]
report_timing_summary -file [file join $reports timing_full_synth.rpt]

# ---- Implementation to route_design (no bitstream) ----
reset_run impl_1
launch_runs impl_1 -to_step route_design -jobs 4
wait_on_run impl_1
set impl_status [get_property STATUS [get_runs impl_1]]
puts "Implementation status: $impl_status"
if {![string match "*Complete*" $impl_status]} {
    puts "ERROR: Implementation failed. Review $project_path.runs/impl_1/runme.log"
    close_project
    exit 1
}
open_run impl_1

# ---- Comprehensive post-route report set ----
report_utilization -file [file join $reports utilization_full_impl.rpt]
report_utilization -hierarchical -file [file join $reports utilization_full_impl_hier.rpt]
report_timing_summary -delay_type min_max -report_unconstrained -file [file join $reports timing_full_impl.rpt]
report_timing -max_paths 10 -nworst 10 -delay_type max -file [file join $reports worst_paths_full_impl.rpt]
report_power -file [file join $reports power_full_impl.rpt]
report_drc -file [file join $reports drc_full_impl.rpt]
report_methodology -file [file join $reports methodology_full_impl.rpt]
report_cdc -file [file join $reports cdc_full_impl.rpt]
report_clock_interaction -file [file join $reports clock_interaction_full_impl.rpt]
report_clocks -file [file join $reports clocks_full_impl.rpt]
report_clock_utilization -file [file join $reports clock_util_full_impl.rpt]
report_control_sets -file [file join $reports control_sets_full_impl.rpt]
report_io -file [file join $reports io_full_impl.rpt]
check_timing -file [file join $reports check_timing_full_impl.rpt]
report_design_analysis -congestion -file [file join $reports congestion_full_impl.rpt]

close_project
puts "FULL_CORE_COMPLETE"
exit 0