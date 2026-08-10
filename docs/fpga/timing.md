# Timing Analysis Guide

## Overview

Timing analysis ensures the design meets setup/hold requirements at the target frequency (50 MHz for Basys3).

## Target Frequency

- **Target**: 50 MHz (20 ns period)
- **Clock**: Single clock domain (sys_clk_pin)
- **Constraint**: `set_max_delay -from [get_clocks sys_clk_pin] -to [get_clocks sys_clk_pin] 19.500`

## Constraint File (XDC)

```tcl
# Clock definition
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} [get_ports clk]

# Input delays
set_input_delay -clock sys_clk_pin -min 0.500 [get_ports reset]
set_input_delay -clock sys_clk_pin -max 2.000 [get_ports reset]

# Output delays
set_output_delay -clock sys_clk_pin -min 0.500 [get_ports {pc_debug[*]}]
set_output_delay -clock sys_clk_pin -max 3.000 [get_ports {pc_debug[*]}]

# False paths for debug outputs
set_false_path -to [get_ports {pc_debug[*]}]

# Clock uncertainty
set_clock_uncertainty -setup 0.100 [get_clocks sys_clk_pin]
set_clock_uncertainty -hold 0.050 [get_clocks sys_clk_pin]

# Max delay constraint
set_max_delay -from [get_clocks sys_clk_pin] -to [get_clocks sys_clk_pin] 19.500
```

## Timing Reports

### Synthesis Timing
```bash
make synthesize
cat build/reports/timing_minimal_synth.rpt
```

### Implementation Timing
```bash
make implement-minimal
cat build/reports/timing_minimal_impl.rpt
```

## Key Metrics

| Metric | Target | Typical Result |
|--------|--------|----------------|
| WNS (Worst Negative Slack) | >= 0 ns | ~1.2 ns |
| TNS (Total Negative Slack) | 0 ns | 0 ns |
| WHS (Worst Hold Slack) | >= 0 ns | ~0.15 ns |
| THS (Total Hold Slack) | 0 ns | 0 ns |

## Critical Paths

### Typical Critical Path
```
Register File Read -> ALU -> Data Memory -> Writeback Mux -> Register File Write
```

### Path Breakdown
| Stage | Delay | Notes |
|-------|-------|-------|
| Register File Read | ~1.5 ns | Async read |
| ALU Operation | ~4.0 ns | ADD/SUB critical |
| Data Memory | ~3.0 ns | Async read |
| Writeback Mux | ~1.0 ns | 4:1 mux |
| Register File Setup | ~0.5 ns | FF setup |
| **Total** | **~9.5 ns** | < 19.5 ns budget |

## Timing Violations

### Common Violations

| Violation | Cause | Fix |
|-----------|-------|-----|
| Setup WNS < 0 | Critical path too long | Pipeline ALU, reduce logic depth |
| Hold violation | Short path | Add buffers, check clock skew |
| I/O setup violation | External delay too large | Adjust input/output delays |
| I/O hold violation | External delay too small | Adjust input/output delays |

### Fixing Setup Violations

1. **Pipeline ALU**: Add register stage after ALU
2. **Reduce Logic Depth**: Optimize critical path logic
3. **Increase Clock Period**: Relax frequency target
4. **Register Retiming**: Enable in synthesis

### Fixing Hold Violations

1. **Add Delay Buffers**: On short paths
2. **Clock Skew Optimization**: Balance clock tree
3. **Remove False Paths**: Check false path constraints

## Running Timing Analysis

### Via Make
```bash
make implement-minimal
cat build/reports/timing_minimal_impl.rpt
```

### Via Vivado Tcl
```tcl
open_run impl_1
report_timing_summary -delay_type max -max_paths 10
report_timing -from [get_clocks sys_clk_pin] -to [get_clocks sys_clk_pin] -max_paths 5
```

### Key Commands
```tcl
# Summary
report_timing_summary

# Top 10 worst paths
report_timing -max_paths 10

# Specific path analysis
report_timing -from [get_pins -hierarchical *alu*] -to [get_pins -hierarchical *data_memory*]

# Check clock uncertainty
report_clock_uncertainty
```

## Timing Closure Checklist

- [ ] WNS >= 0 ns
- [ ] TNS == 0 ns
- [ ] WHS >= 0 ns
- [ ] THS == 0 ns
- [ ] No unconstrained paths
- [ ] I/O constraints satisfied
- [ ] Clock uncertainty accounted
- [ ] False paths correctly defined
- [ ] DRC clean

## Related Documents
- [Basys3 Build Guide](basys3-guide.md)
- [Power Analysis](power.md)
- [Bitstream Generation](bitstream.md)