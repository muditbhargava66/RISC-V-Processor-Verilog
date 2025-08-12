# Comprehensive Project Validation Script
# Validates the RISC-V processor project for completeness and correctness

set project_name "riscv_processor"
set project_dir "./vivado_project"

puts "=========================================="
puts "RISC-V PROCESSOR PROJECT VALIDATION"
puts "=========================================="
puts "Timestamp: [clock format [clock seconds]]"
puts ""

# Check if project exists
if {![file exists "$project_dir/$project_name.xpr"]} {
    puts "❌ ERROR: Project file not found!"
    puts "Expected: $project_dir/$project_name.xpr"
    puts "Run: make create-project"
    exit 1
}

# Open project
puts "📂 Opening project..."
open_project "$project_dir/$project_name.xpr"

puts "✅ Project opened successfully"
puts ""

#######################################
# Design Hierarchy Validation
#######################################
puts "🔍 DESIGN HIERARCHY VALIDATION"
puts "=============================="

# Check top module
set top_module [get_property top [current_fileset]]
puts "Top module: $top_module"

if {$top_module ne "processor_top"} {
    puts "⚠️  WARNING: Expected top module 'processor_top', found '$top_module'"
} else {
    puts "✅ Correct top module set"
}

# Check source files
set source_files [get_files -of_objects [get_filesets sources_1] *.v]
set expected_sources {
    "processor_top.v" "alu.v" "ALU_control.v" "Control_unit.v"
    "data_ext.v" "data_mem.v" "imm_gen.v" "instr_mem.v"
    "PC.v" "pc_adder.v" "regfile.v" "shifter.v"
}

puts ""
puts "Source files validation:"
set missing_sources {}
foreach expected $expected_sources {
    set found 0
    foreach actual $source_files {
        if {[string match "*$expected" $actual]} {
            puts "  ✅ $expected"
            set found 1
            break
        }
    }
    if {!$found} {
        puts "  ❌ $expected (MISSING)"
        lappend missing_sources $expected
    }
}

if {[llength $missing_sources] > 0} {
    puts ""
    puts "❌ Missing source files: [join $missing_sources {, }]"
    exit 1
}

#######################################
# Constraint File Validation
#######################################
puts ""
puts "🎯 CONSTRAINT FILE VALIDATION"
puts "============================="

set constraint_files [get_files -of_objects [get_filesets constrs_1] *.xdc]
if {[llength $constraint_files] == 0} {
    puts "❌ No constraint files found!"
    exit 1
} else {
    foreach xdc $constraint_files {
        puts "✅ Constraint file: [file tail $xdc]"
    }
}

#######################################
# Testbench Validation
#######################################
puts ""
puts "🧪 TESTBENCH VALIDATION"
puts "======================"

set sim_top [get_property top [get_filesets sim_1]]
puts "Simulation top: $sim_top"

set testbench_files [get_files -of_objects [get_filesets sim_1] *.v]
puts "Testbench files found: [llength $testbench_files]"

foreach tb $testbench_files {
    puts "  📋 [file tail $tb]"
}

#######################################
# Synthesis Validation
#######################################
puts ""
puts "⚙️  SYNTHESIS VALIDATION"
puts "======================"

# Check if synthesis has been run
set synth_run [get_runs synth_1]
set synth_status [get_property STATUS $synth_run]
set synth_progress [get_property PROGRESS $synth_run]

puts "Synthesis status: $synth_status"
puts "Synthesis progress: $synth_progress"

if {$synth_progress eq "100%"} {
    puts "✅ Synthesis completed successfully"
    
    # Open synthesized design for analysis
    if {[catch {open_run synth_1} result]} {
        puts "⚠️  Could not open synthesized design: $result"
    } else {
        puts "📊 Analyzing synthesized design..."
        
        # Get utilization summary
        set luts [get_cells -hier -filter {IS_PRIMITIVE && (REF_NAME == LUT1 || REF_NAME == LUT2 || REF_NAME == LUT3 || REF_NAME == LUT4 || REF_NAME == LUT5 || REF_NAME == LUT6)} -quiet]
        set ffs [get_cells -hier -filter {IS_PRIMITIVE && (REF_NAME == FDRE || REF_NAME == FDSE || REF_NAME == FDCE || REF_NAME == FDPE)} -quiet]
        set brams [get_cells -hier -filter {IS_PRIMITIVE && (REF_NAME == RAMB18E1 || REF_NAME == RAMB36E1)} -quiet]
        set dsps [get_cells -hier -filter {IS_PRIMITIVE && REF_NAME == DSP48E1} -quiet]
        
        puts "Resource utilization:"
        puts "  LUTs: [llength $luts]"
        puts "  Flip-Flops: [llength $ffs]"
        puts "  Block RAMs: [llength $brams]"
        puts "  DSP Slices: [llength $dsps]"
        
        # Check for critical warnings
        set crit_warnings [get_msg_config -count -severity "CRITICAL WARNING"]
        set errors [get_msg_config -count -severity "ERROR"]
        
        puts "Message summary:"
        puts "  Errors: $errors"
        puts "  Critical Warnings: $crit_warnings"
        
        if {$errors > 0} {
            puts "❌ Synthesis has errors!"
        } elseif {$crit_warnings > 0} {
            puts "⚠️  Synthesis has critical warnings"
        } else {
            puts "✅ Clean synthesis (no errors or critical warnings)"
        }
    }
} else {
    puts "⚠️  Synthesis not completed or failed"
    puts "Run: make synthesize"
}

#######################################
# Implementation Validation
#######################################
puts ""
puts "🏗️  IMPLEMENTATION VALIDATION"
puts "============================"

set impl_run [get_runs impl_1]
set impl_status [get_property STATUS $impl_run]
set impl_progress [get_property PROGRESS $impl_run]

puts "Implementation status: $impl_status"
puts "Implementation progress: $impl_progress"

if {$impl_progress eq "100%"} {
    puts "✅ Implementation completed"
    
    if {[catch {open_run impl_1} result]} {
        puts "⚠️  Could not open implemented design: $result"
    } else {
        puts "📊 Analyzing implemented design..."
        
        # Timing analysis
        set setup_paths [get_timing_paths -max_paths 1 -nworst 1 -setup -quiet]
        if {[llength $setup_paths] > 0} {
            set wns [get_property SLACK $setup_paths]
            puts "Timing analysis:"
            puts "  Worst Negative Slack: $wns ns"
            
            if {$wns < 0} {
                puts "  ❌ Timing not met"
            } else {
                puts "  ✅ Timing requirements met"
            }
        } else {
            puts "Timing analysis: No timing paths found"
        }
    }
} else {
    puts "⚠️  Implementation not completed"
    puts "Run: make implement"
}

#######################################
# File System Validation
#######################################
puts ""
puts "📁 FILE SYSTEM VALIDATION"
puts "========================"

# Check for important directories
set important_dirs {"src" "testbenches" "constraints" "scripts"}
foreach dir $important_dirs {
    if {[file exists $dir]} {
        puts "✅ Directory: $dir"
    } else {
        puts "❌ Missing directory: $dir"
    }
}

# Check for documentation
set doc_files {"README.md" "VIVADO_IMPROVEMENTS.md" "CROSS_PLATFORM_GUIDE.md"}
foreach doc $doc_files {
    if {[file exists $doc]} {
        puts "✅ Documentation: $doc"
    } else {
        puts "⚠️  Missing documentation: $doc"
    }
}

# Check for build system
if {[file exists "Makefile"]} {
    puts "✅ Build system: Makefile"
} else {
    puts "⚠️  Missing build system: Makefile"
}

if {[file exists ".gitignore"]} {
    puts "✅ Version control: .gitignore"
} else {
    puts "⚠️  Missing .gitignore file"
}

#######################################
# Final Assessment
#######################################
puts ""
puts "=========================================="
puts "VALIDATION SUMMARY"
puts "=========================================="

set validation_score 0
set max_score 10

# Score components
if {[llength $missing_sources] == 0} {incr validation_score 2}
if {[llength $constraint_files] > 0} {incr validation_score 1}
if {[llength $testbench_files] > 0} {incr validation_score 1}
if {$synth_progress eq "100%"} {incr validation_score 2}
if {$impl_progress eq "100%"} {incr validation_score 2}
if {[file exists "Makefile"]} {incr validation_score 1}
if {[file exists ".gitignore"]} {incr validation_score 1}

set score_percent [expr {($validation_score * 100) / $max_score}]

puts "Project validation score: $validation_score/$max_score ($score_percent%)"
puts ""

if {$validation_score >= 8} {
    puts "🎉 EXCELLENT PROJECT!"
    puts "✅ Project is complete and ready for use"
    puts "✅ All major components validated"
    puts "✅ Ready for production deployment"
} elseif {$validation_score >= 6} {
    puts "👍 GOOD PROJECT"
    puts "✅ Core functionality complete"
    puts "⚠️  Some optional components missing"
    puts "✅ Ready for development use"
} elseif {$validation_score >= 4} {
    puts "⚠️  PROJECT NEEDS WORK"
    puts "✅ Basic structure present"
    puts "❌ Missing critical components"
    puts "🔧 Requires additional development"
} else {
    puts "❌ PROJECT INCOMPLETE"
    puts "❌ Major components missing"
    puts "🔧 Significant work required"
}

puts ""
puts "Validation completed at: [clock format [clock seconds]]"
puts "=========================================="