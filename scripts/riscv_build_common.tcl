# Common Tcl Library for RISC-V Processor Build Scripts
# Provides shared functions and constants for all build scripts

namespace eval riscv_build {

    # Project configuration
    variable repo_root ""
    variable part_name "xc7a35tcpg236-1"
    variable vivado_version "2023.2"

    # Core source files (SystemVerilog)
    variable core_files {
        src/riscv_pkg.sv
        src/alu.sv
        src/immediate_generator.sv
        src/program_counter.sv
        src/register_file.sv
        src/instruction_memory.sv
        src/data_memory.sv
        src/control_unit.sv
        src/riscv_processor.sv
    }

    variable memory_image "instruction_memory.hex"

    # Target configurations
    variable targets {
        core {
            project_name "riscv_processor_core"
            top_module "riscv_processor"
            constraint_file ""
            wrapper_file ""
        }
        minimal {
            project_name "riscv_processor_minimal"
            top_module "riscv_processor_minimal"
            constraint_file "constraints/riscv_processor_minimal.xdc"
            wrapper_file "src/riscv_processor_minimal.sv"
        }
        jtag {
            project_name "riscv_processor_jtag_debug"
            top_module "riscv_processor_jtag_debug"
            constraint_file "constraints/riscv_processor_jtag_debug.xdc"
            wrapper_file "src/riscv_processor_jtag_debug.sv"
        }
    }

    # Simulation test configurations
    variable sim_tests {
        system {
            top_module "riscv_processor_tb"
            test_file "testbenches/riscv_processor_tb.sv"
        }
        alu {
            top_module "alu_tb"
            test_file "testbenches/alu_tb.sv"
        }
        control {
            top_module "control_unit_tb"
            test_file "testbenches/control_unit_tb.sv"
        }
        memory {
            top_module "memory_tb"
            test_file "testbenches/memory_tb.sv"
        }
        regfile {
            top_module "register_file_tb"
            test_file "testbenches/register_file_tb.sv"
        }
        compliance {
            top_module "compliance_tests"
            test_file "verification/compliance_tests.sv"
        }
        formal {
            top_module "formal_verification_tb"
            test_files {
                "verification/riscv_processor_sva.sv"
                "verification/formal_verification_tb.sv"
            }
        }
        benchmark {
            top_module "performance_benchmark"
            test_file "benchmarks/performance_benchmark.sv"
        }
    }

    # Initialize repository root
    proc init_repo_root {} {
        variable repo_root
        set script_path [info script]
        set script_dir [file dirname $script_path]
        set repo_root [file normalize [file join $script_dir ..]]
        return $repo_root
    }

    # Get absolute path for a relative file
    proc abspath {rel_path} {
        variable repo_root
        return [file join $repo_root $rel_path]
    }

    # Check if target is valid
    proc validate_target {target} {
        variable targets
        if {![dict exists $targets $target]} {
            puts "ERROR: Unknown target '$target'. Valid targets: [dict keys $targets]"
            return 0
        }
        return 1
    }

    # Get target configuration
    proc get_target_config {target key} {
        variable targets
        return [dict get $targets $target $key]
    }

    # Validate simulation test name
    proc validate_sim_test {test_name} {
        variable sim_tests
        if {![dict exists $sim_tests $test_name]} {
            puts "ERROR: Unknown test '$test_name'. Valid tests: [dict keys $sim_tests]"
            return 0
        }
        return 1
    }

    # Get simulation test configuration
    proc get_sim_test_config {test_name key} {
        variable sim_tests
        return [dict get $sim_tests $test_name $key]
    }

    # Get core files with absolute paths
    proc get_core_files {} {
        variable core_files
        variable repo_root
        set abs_files {}
        foreach f $core_files {
            lappend abs_files [abspath $f]
        }
        return $abs_files
    }

    # Get wrapper file for target (if any)
    proc get_wrapper_file {target} {
        variable targets
        set wrapper [dict get $targets $target wrapper_file]
        if {$wrapper ne ""} {
            return [abspath $wrapper]
        }
        return ""
    }

    # Get constraint file for target (if any)
    proc get_constraint_file {target} {
        variable targets
        set constraint [dict get $targets $target constraint_file]
        if {$constraint ne ""} {
            return [abspath $constraint]
        }
        return ""
    }

    # Get memory image path
    proc get_memory_image {} {
        variable memory_image
        return [abspath $memory_image]
    }

    # Get simulation test files
    proc get_sim_test_files {test_name} {
        variable sim_tests
        if {[dict exists $sim_tests $test_name test_files]} {
            set files [dict get $sim_tests $test_name test_files]
            set abs_files {}
            foreach f $files {
                lappend abs_files [abspath $f]
            }
            return $abs_files
        } else {
            set f [dict get $sim_tests $test_name test_file]
            return [list [abspath $f]]
        }
    }

    # Get simulation top module
    proc get_sim_top_module {test_name} {
        variable sim_tests
        return [dict get $sim_tests $test_name top_module]
    }

    # Create or open Vivado project
    proc create_or_open_project {project_name project_dir part_name} {
        if {[file exists [file join $project_dir "$project_name.xpr"]]} {
            puts "Reusing generated Vivado project: [file join $project_dir "$project_name.xpr"]"
            open_project [file join $project_dir "$project_name.xpr"]
            return 1
        }

        puts "========================================="
        puts "Creating Vivado project: $project_name"
        puts "Device: $part_name"
        puts "Output: $project_dir"
        puts "========================================="

        create_project $project_name $project_dir -part $part_name
        set_property target_language Verilog [current_project]
        set_property simulator_language Mixed [current_project]
        return 0
    }

    # Add source files to project
    proc add_source_files {source_files memory_image} {
        add_files -norecurse $source_files
        add_files -norecurse $memory_image
        set_property file_type {Memory File} [get_files $memory_image]
        set_property used_in_synthesis true [get_files $memory_image]
        set_property used_in_simulation true [get_files $memory_image]
    }

    # Add wrapper file if provided
    proc add_wrapper_file {wrapper_file} {
        if {$wrapper_file ne ""} {
            add_files -norecurse $wrapper_file
        }
    }

    # Add constraint file if provided
    proc add_constraint_file {constraint_file} {
        if {$constraint_file ne ""} {
            if {![file exists $constraint_file]} {
                puts "ERROR: Missing constraint file: $constraint_file"
                return 0
            }
            add_files -fileset constrs_1 -norecurse $constraint_file
        }
        return 1
    }

    # Finalize project setup
    proc finalize_project {top_module} {
        set_property top $top_module [current_fileset]
        update_compile_order -fileset sources_1
        close_project
    }

    # Run synthesis
    proc run_synthesis {project_path} {
        open_project $project_path
        update_compile_order -fileset sources_1

        puts "========================================="
        puts "Running synthesis"
        puts "========================================="
        reset_run synth_1
        launch_runs synth_1 -jobs 4
        wait_on_run synth_1

        set synth_status [get_property STATUS [get_runs synth_1]]
        puts "Synthesis status: $synth_status"
        if {![string match "*Complete*" $synth_status]} {
            puts "ERROR: Synthesis failed. Review $project_path.runs/synth_1/runme.log"
            close_project
            return 0
        }
        return 1
    }

    # Generate synthesis reports
    proc generate_synth_reports {repo_root target} {
        set build_reports [file join $repo_root build reports]
        file mkdir $build_reports

        report_utilization -file [file join $build_reports "utilization_${target}_synth.rpt"]
        report_timing_summary -file [file join $build_reports "timing_${target}_synth.rpt"]
    }

    # Run implementation
    proc run_implementation {project_path target} {
        puts "========================================="
        puts "Running implementation for $target"
        puts "========================================="
        reset_run impl_1
        launch_runs impl_1 -to_step write_bitstream -jobs 4
        wait_on_run impl_1

        set impl_status [get_property STATUS [get_runs impl_1]]
        puts "Implementation status: $impl_status"
        if {![string match "*Complete*" $impl_status]} {
            puts "ERROR: Implementation or bitstream generation failed."
            close_project
            return 0
        }
        return 1
    }

    # Generate implementation reports
    proc generate_impl_reports {repo_root target} {
        set build_reports [file join $repo_root build reports]
        file mkdir $build_reports

        report_utilization -file [file join $build_reports "utilization_${target}_impl.rpt"]
        report_timing_summary -file [file join $build_reports "timing_${target}_impl.rpt"]
        report_power -file [file join $build_reports "power_${target}_impl.rpt"]
        report_drc -file [file join $build_reports "drc_${target}_impl.rpt"]
        report_methodology -file [file join $build_reports "methodology_${target}_impl.rpt"]
    }

    # Create simulation project
    proc create_sim_project {test_name run_dir part_name core_files memory_image test_files top_module} {
        puts "========================================="
        puts "Running $test_name simulation in $run_dir"
        puts "========================================="

        create_project "riscv_sim_$test_name" $run_dir -part $part_name -force
        set_property target_language Verilog [current_project]
        set_property simulator_language Mixed [current_project]

        add_files -norecurse $core_files
        add_files -norecurse $memory_image
        set_property file_type {Memory File} [get_files $memory_image]
        add_files -fileset sim_1 -norecurse $test_files
        add_files -fileset sim_1 -norecurse $memory_image
        set_property top $top_module [get_filesets sim_1]
        update_compile_order -fileset sources_1
        update_compile_order -fileset sim_1
    }

    # Validate required files exist
    proc validate_files {file_list} {
        foreach f $file_list {
            if {![file exists $f]} {
                puts "ERROR: Missing required file: $f"
                return 0
            }
        }
        return 1
    }
}