# Safe Synthesis Script for RISC-V Processor
# This script runs synthesis with proper error handling and reporting

# Set project variables
set project_name "riscv_processor"
set project_dir "./vivado_project"

# Check if project exists
if {![file exists "$project_dir/$project_name.xpr"]} {
    puts "ERROR: Project file not found!"
    puts "Please run: make create-project"
    puts "Or: python scripts/run_vivado.py scripts/create_vivado_project.tcl"
    exit 1
}

# Open the project
puts "Opening project: $project_dir/$project_name.xpr"
open_project "$project_dir/$project_name.xpr"

# Reset any previous runs
reset_run synth_1

# Configure synthesis settings for better results
set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
set_property steps.synth_design.args.flatten_hierarchy rebuilt [get_runs synth_1]
set_property steps.synth_design.args.gated_clock_conversion off [get_runs synth_1]
set_property steps.synth_design.args.bufg 12 [get_runs synth_1]
set_property steps.synth_design.args.keep_equivalent_registers true [get_runs synth_1]
set_property steps.synth_design.args.resource_sharing off [get_runs synth_1]
set_property steps.synth_design.args.no_lc true [get_runs synth_1]
set_property steps.synth_design.args.shreg_min_size 5 [get_runs synth_1]

# Run synthesis
puts "Starting synthesis..."
puts "This may take a few minutes..."

launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check synthesis results
set synth_status [get_property STATUS [get_runs synth_1]]
set synth_progress [get_property PROGRESS [get_runs synth_1]]

puts ""
puts "=========================================="
puts "SYNTHESIS RESULTS"
puts "=========================================="
puts "Status: $synth_status"
puts "Progress: $synth_progress"

if {$synth_progress != "100%"} {
    puts "ERROR: Synthesis failed!"
    puts "Check the synthesis log for details"
    exit 1
}

# Open synthesized design
open_run synth_1

# Generate reports
puts ""
puts "Generating synthesis reports..."
file mkdir reports

# Timing report
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -routable_nets -file reports/synth_timing_summary.rpt

# Utilization report
report_utilization -file reports/synth_utilization.rpt

# Power report
report_power -file reports/synth_power.rpt

# Clock report
report_clocks -file reports/synth_clocks.rpt

# Comprehensive timing analysis
puts ""
puts "=========================================="
puts "TIMING ANALYSIS"
puts "=========================================="

# Check if timing paths exist
set setup_paths [get_timing_paths -max_paths 1 -nworst 1 -setup -quiet]
set hold_paths [get_timing_paths -max_paths 1 -nworst 1 -hold -quiet]

set timing_ok 1

if {[llength $setup_paths] > 0} {
    set setup_slack [get_property SLACK $setup_paths]
    puts "Setup Analysis:"
    puts "  Worst setup slack: $setup_slack ns"
    
    if {$setup_slack < 0} {
        puts "  ❌ SETUP TIMING VIOLATION!"
        puts "  Critical path needs optimization"
        set timing_ok 0
    } else {
        puts "  ✅ Setup timing met"
    }
} else {
    puts "Setup Analysis: No setup paths found (combinational design)"
}

if {[llength $hold_paths] > 0} {
    set hold_slack [get_property SLACK $hold_paths]
    puts "Hold Analysis:"
    puts "  Worst hold slack: $hold_slack ns"
    
    if {$hold_slack < 0} {
        puts "  ❌ HOLD TIMING VIOLATION!"
        puts "  Hold time requirements not met"
        set timing_ok 0
    } else {
        puts "  ✅ Hold timing met"
    }
} else {
    puts "Hold Analysis: No hold paths found"
}

# Clock analysis
set clocks [get_clocks -quiet]
if {[llength $clocks] > 0} {
    puts "Clock Analysis:"
    foreach clk $clocks {
        set clk_name [get_property NAME $clk]
        set clk_period [get_property PERIOD $clk]
        set clk_freq [expr {1000.0 / $clk_period}]
        puts "  Clock: $clk_name"
        puts "    Period: $clk_period ns"
        puts "    Frequency: [format "%.2f" $clk_freq] MHz"
    }
} else {
    puts "Clock Analysis: No clocks found"
}

# Overall timing assessment
if {$timing_ok} {
    puts ""
    puts "🎉 TIMING CLOSURE ACHIEVED!"
    puts "Design meets all timing requirements"
} else {
    puts ""
    puts "⚠️  TIMING VIOLATIONS DETECTED"
    puts "Review timing reports and consider:"
    puts "  1. Reducing clock frequency"
    puts "  2. Adding pipeline registers"
    puts "  3. Optimizing critical paths"
    puts "  4. Using faster speed grade"
}

# Resource utilization summary
puts ""
puts "=========================================="
puts "RESOURCE UTILIZATION"
puts "=========================================="

# Get utilization data
set lut_used [get_property USED [get_cells -hier -filter {IS_PRIMITIVE && LUT*}]]
set ff_used [get_property USED [get_cells -hier -filter {IS_PRIMITIVE && (FDRE || FDSE || FDCE || FDPE)}]]
set bram_used [get_property USED [get_cells -hier -filter {IS_PRIMITIVE && RAMB*}]]
set dsp_used [get_property USED [get_cells -hier -filter {IS_PRIMITIVE && DSP*}]]

if {$lut_used ne ""} {puts "LUTs: $lut_used"}
if {$ff_used ne ""} {puts "Flip-Flops: $ff_used"}  
if {$bram_used ne ""} {puts "Block RAMs: $bram_used"}
if {$dsp_used ne ""} {puts "DSP Slices: $dsp_used"}

puts ""
puts "=========================================="
puts "SYNTHESIS COMPLETE"
puts "=========================================="
puts "Reports generated in reports/ directory:"
puts "  - synth_timing_summary.rpt"
puts "  - synth_utilization.rpt"
puts "  - synth_power.rpt"
puts "  - synth_clocks.rpt"
puts ""

if {$timing_ok} {
    puts "✓ Synthesis successful with timing met!"
    puts "Ready for implementation."
} else {
    puts "⚠ Synthesis completed but timing not met."
    puts "Review timing report before implementation."
}

puts "=========================================="