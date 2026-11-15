# Power Analysis Guide

## Overview

Power analysis estimates dynamic and static power consumption for the RISC-V processor on Artix-7.

## Running Power Analysis

### Via Make
```bash
make implement-minimal
cat build/reports/power_minimal_impl.rpt
```

### Via Vivado Tcl
```tcl
open_run impl_1
report_power -file power_report.rpt
```

## Power Components (verified v1.2.0, vector-less)

Reproduced from `build/reports/power_minimal_impl.rpt` (Vivado 2023.2, routed
minimal design, xc7a35tcpg236-1). Overall confidence: **Medium** (vector-less;
internal-node activity is estimated, not from simulation).

| Component | Value | Notes |
|-----------|-------|-------|
| **Dynamic Power** | 16 mW | Switching activity |
| **Device Static Power** | 72 mW | Leakage |
| **Total On-Chip Power** | 88 mW | |
| **Junction Temperature** | 25.4 °C | Ambient 25 °C, θJA 5.0 °C/W |

### Where the dynamic power goes

The core logic is tiny (540 LUTs / 227 FFs), so dynamic power is dominated by
I/O, not the datapath:

| Block | Dynamic Power |
|-------|---------------|
| I/O (18 pins) | ~14 mW |
| Core logic (`u_riscv_processor`) | ~2 mW |
| — of which `pc_inst` | ~1 mW |
| Clocks (2 BUFG) | ~1 mW |
| Slice logic / signals / distributed RAM | <1 mW each |

(The earlier per-module table that attributed ~60 mW to data memory was a
v1.1.0 estimate from the flip-flop-based memory; that reset loop was removed in
v1.2.0, so the memory is now distributed RAM and draws negligible dynamic power.)

## Power Optimization

### Dynamic Power Reduction

| Technique | Impact | Implementation |
|-----------|--------|----------------|
| Clock Gating | ~30% reduction | Add enable to clock enables |
| Operand Isolation | ~15% reduction | Gate ALU inputs when not used |
| Memory Power Down | ~20% reduction | Power down unused memory banks |
| Operand Forwarding | ~10% reduction | Reduce register file reads |

### Static Power Reduction

| Technique | Impact | Implementation |
|-----------|--------|----------------|
| Power Gating | ~90% reduction | Power domains for unused modules |
| Lower Vccint | ~30% reduction | Reduce core voltage (if supported) |
| Temperature Control | ~2x per 10°C | Thermal management |

## Power Report Analysis

### Key Sections

1. **Summary**: Total power, junction temperature
2. **By Hierarchy**: Power per module
3. **By Type**: Dynamic vs Static
4. **By Resource**: LUTs, FFs, DSPs, BRAM, I/O
5. **Switching Activity**: Toggle rates per net

### Key Metrics

| Metric | Target | Actual (v1.2.0) |
|--------|--------|---------|
| Junction Temp | < 85°C | 25.4°C |
| Thermal Margin | > 10°C | ~59°C |
| Total Power | < 500 mW | 88 mW |

## Power Constraints

### XDC Constraints
```tcl
# Operating conditions
set_operating_conditions -design_power_budget 500
set_operating_conditions -ambient_temp 25.0
set_operating_conditions -junction_temp 85.0
set_operating_conditions -airflow 0.0
set_operating_conditions -heatsink "none"
```

### Activity Estimation
```tcl
# Vectorless activity propagation
report_power -vectorless_activity_propagation
```

## Thermal Analysis

### Junction Temperature Calculation
```
Tj = Ta + (Pd * θJA)
```
- Ta: Ambient temperature (25 °C)
- Pd: Total power dissipation (0.085 W)
- θJA: Junction-to-ambient thermal resistance (5.0 °C/W for CPG236 with the
  report's medium heatsink / 250 LFM airflow environment)

### Result
```
Tj = 25 + (0.085 * 5.0) = 25.4 °C
```
**Margin**: 85 °C - 25.4 °C = 59.6 °C (matches the report's 25.4 °C junction).

## Related Documents
- [Basys3 Build Guide](basys3-guide.md)
- [Timing Analysis](timing.md)
- [Bitstream Generation](bitstream.md)