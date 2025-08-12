# Vivado Implementation Script for RISC-V Processor

# Set project variables
set project_name "riscv_processor"
set project_dir "./vivado_project"

# Open existing project
if {[file exists $project_dir]} {
    open_project $project_dir/$project_name.xpr
} else {
    puts "Project not found. Please run synthesis first."
    exit 1
}

# Check if synthesis is complete
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "Synthesis not complete. Running synthesis first..."
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
}

# Set implementation options
set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
set_property steps.opt_design.args.directive Explore [get_runs impl_1]
set_property steps.place_design.args.directive Explore [get_runs impl_1]
set_property steps.phys_opt_design.is_enabled true [get_runs impl_1]
set_property steps.phys_opt_design.args.directive AggressiveExplore [get_runs impl_1]
set_property steps.route_design.args.directive Explore [get_runs impl_1]

# Run implementation
puts "Starting implementation..."
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check implementation results
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "Implementation failed!"
}

# Open implemented design
open_run impl_1

# Generate implementation reports
puts "Generating implementation reports..."
file mkdir reports

report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -routable_nets -file reports/impl_timing_summary.rpt
report_utilization -file reports/impl_utilization.rpt
report_power -file reports/impl_power.rpt
report_drc -file reports/impl_drc.rpt
report_methodology -file reports/impl_methodology.rpt

# Comprehensive post-implementation timing analysis
puts ""
puts "=========================================="
puts "POST-IMPLEMENTATION TIMING ANALYSIS"
puts "=========================================="

# Setup timing analysis
set setup_paths [get_timing_paths -max_paths 1 -nworst 1 -setup -quiet]
set hold_paths [get_timing_paths -max_paths 1 -nworst 1 -hold -quiet]

set timing_closure 1

if {[llength $setup_paths] > 0} {
    set setup_slack [get_property SLACK $setup_paths]
    puts "Setup Timing:"
    puts "  Worst Negative Slack (WNS): $setup_slack ns"
    
    if {$setup_slack < 0} {
        puts "  ❌ SETUP TIMING FAILED"
        set timing_closure 0
        
        # Get failing endpoint
        set failing_endpoint [get_property ENDPOINT_PIN $setup_paths]
        puts "  Failing endpoint: $failing_endpoint"
        
        # Get critical path delay
        set path_delay [get_property DATAPATH_DELAY $setup_paths]
        puts "  Critical path delay: $path_delay ns"
        
    } else {
        puts "  ✅ Setup timing met"
        
        # Calculate maximum achievable frequency
        set clock_period [get_property PERIOD [get_clocks sys_clk]]
        set max_freq [expr {1000.0 / ($clock_period - $setup_slack)}]
        puts "  Maximum frequency: [format "%.2f" $max_freq] MHz"
    }
} else {
    puts "Setup Timing: No setup paths analyzed"
}

if {[llength $hold_paths] > 0} {
    set hold_slack [get_property SLACK $hold_paths]
    puts "Hold Timing:"
    puts "  Worst Hold Slack (WHS): $hold_slack ns"
    
    if {$hold_slack < 0} {
        puts "  ❌ HOLD TIMING FAILED"
        set timing_closure 0
    } else {
        puts "  ✅ Hold timing met"
    }
} else {
    puts "Hold Timing: No hold paths analyzed"
}

# Power analysis
puts ""
puts "Power Analysis:"
set total_power [get_property TOTAL_POWER [current_design] -quiet]
if {$total_power ne ""} {
    puts "  Total Power: $total_power W"
} else {
    puts "  Power analysis not available"
}

# Final assessment
puts ""
if {$timing_closure} {
    puts "🎉 IMPLEMENTATION SUCCESSFUL!"
    puts "✅ All timing requirements met"
    puts "✅ Ready for bitstream generation"
} else {
    puts "⚠️  IMPLEMENTATION ISSUES DETECTED"
    puts "❌ Timing closure failed"
    puts "Review implementation reports for optimization"
}

# Generate bitstream (optional)
set generate_bitstream 0
if {$generate_bitstream} {
    puts "Generating bitstream..."
    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1
    puts "Bitstream generated successfully!"
}

puts "Implementation completed successfully!"
puts "Check reports in the reports/ directory"