# Create or reuse a Vivado project without touching legacy projects/.
# Usage: vivado -mode batch -source scripts/build_vivado.tcl -tclargs <core|minimal|jtag>

catch {close_project -quiet}

set target "core"
if {$argc > 0} {
    set target [lindex $argv 0]
}

set repo_root [file normalize [file join [file dirname [info script]] ..]]
set part_name "xc7a35tcpg236-1"

switch -- $target {
    core {
        set project_name "riscv_processor_core"
        set top_module "riscv_processor"
        set constraint_file ""
    }
    minimal {
        set project_name "riscv_processor_minimal"
        set top_module "riscv_processor_minimal"
        set constraint_file [file join $repo_root constraints riscv_processor_minimal.xdc]
    }
    jtag {
        set project_name "riscv_processor_jtag_debug"
        set top_module "riscv_processor_jtag_debug"
        set constraint_file [file join $repo_root constraints riscv_processor_jtag_debug.xdc]
    }
    default {
        puts "ERROR: Unknown target '$target'. Use core, minimal, or jtag."
        exit 1
    }
}

set build_root [file join $repo_root build vivado]
set project_dir [file join $build_root $project_name]
set project_path [file join $project_dir "$project_name.xpr"]
file mkdir $build_root

if {[file exists $project_path]} {
    puts "Reusing generated Vivado project: $project_path"
    open_project $project_path
    set_property top $top_module [current_fileset]
    update_compile_order -fileset sources_1
    close_project
    exit 0
}

puts "========================================="
puts "Creating Vivado project: $project_name"
puts "Target: $target"
puts "Device: $part_name"
puts "Output: $project_dir"
puts "========================================="

create_project $project_name $project_dir -part $part_name
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

set source_files [list \
    [file join $repo_root src riscv_processor.v] \
    [file join $repo_root src program_counter.v] \
    [file join $repo_root src instruction_memory.v] \
    [file join $repo_root src register_file.v] \
    [file join $repo_root src Control_unit.v] \
    [file join $repo_root src immediate_generator.v] \
    [file join $repo_root src alu.v] \
    [file join $repo_root src data_memory.v] \
]

if {$target eq "minimal"} {
    lappend source_files [file join $repo_root src riscv_processor_minimal.v]
} elseif {$target eq "jtag"} {
    lappend source_files [file join $repo_root src riscv_processor_jtag_debug.v]
}

set memory_image [file join $repo_root instruction_memory.hex]
if {![file exists $memory_image]} {
    puts "ERROR: Missing instruction-memory image: $memory_image"
    close_project
    exit 1
}

add_files -norecurse $source_files
add_files -norecurse $memory_image
set_property file_type {Memory File} [get_files $memory_image]
set_property used_in_synthesis true [get_files $memory_image]
set_property used_in_simulation true [get_files $memory_image]

if {$constraint_file ne ""} {
    if {![file exists $constraint_file]} {
        puts "ERROR: Missing constraint file: $constraint_file"
        close_project
        exit 1
    }
    add_files -fileset constrs_1 -norecurse $constraint_file
}

set_property top $top_module [current_fileset]
update_compile_order -fileset sources_1
close_project

puts "Project created successfully. Generated files are isolated under build/."
