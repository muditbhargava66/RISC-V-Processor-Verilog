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

## Power Components

| Component | Typical Value | Notes |
|-----------|---------------|-------|
| **Dynamic Power** | ~53 mW | Switching activity |
| **Static Power** | ~74 mW | Leakage |
| **Total Power** | ~127 mW | Estimated |

### Breakdown by Module

| Module | Dynamic (mW) | Static (mW) | Total (mW) | % of Total |
|--------|-------------|-------------|------------|------------|
| Data Memory | ~25 | ~35 | ~60 | 47% |
| Register File | ~10 | ~20 | ~30 | 24% |
| ALU | ~8 | ~5 | ~13 | 10% |
| Control Unit | ~5 | ~3 | ~8 | 6% |
| PC / Immediate Gen | ~3 | ~2 | ~5 | 4% |
| Instruction Memory | ~2 | ~2 | ~4 | 3% |
| **Total** | **~53** | **~74** | **~127** | **100%** |

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

| Metric | Target | Typical |
|--------|--------|---------|
| Junction Temp | < 85°C | ~25°C |
| Thermal Margin | > 10°C | ~60°C |
| Power Budget | < 500 mW | ~127 mW |

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
Tj = Ta + (Pd * θja)
```
- Ta: Ambient temperature (25°C)
- Pd: Total power dissipation (0.127 W)
- θja: Junction-to-ambient thermal resistance (~25°C/W for CPG236)

### Result
```
Tj = 25 + (0.127 * 25) = 28.2°C
```
**Margin**: 85°C - 28.2°C = 56.8°C

## Power Budget

| Component | Budget (mW) | Actual (mW) | Margin |
|-----------|-------------|-------------|--------|
| Core Logic | 200 | 127 | 73 mW |
| I/O | 100 | ~20 | 80 mW |
| **Total** | **300** | **~147** | **153 mW** |

## Related Documents
- [Basys3 Build Guide](basys3-guide.md)
- [Timing Analysis](timing.md)
- [Bitstream Generation](bitstream.md)