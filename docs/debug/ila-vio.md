# ILA/VIO Integration Guide

## Overview

The JTAG debug wrapper includes explicit instantiation of ILA (Integrated Logic Analyzer) and VIO (Virtual Input/Output) cores for hardware debugging.

## ILA (Integrated Logic Analyzer)

### Probe Configuration

| Probe | Width | Signal | Description |
|-------|-------|--------|-------------|
| 0 | 32 | `pc_debug` | Program Counter |
| 1 | 32 | `instruction_debug` | Current Instruction |
| 2 | 32 | `alu_result_debug` | ALU Result |
| 3 | 32 | `reg_debug_data1` | Register Read Data 1 |
| 4 | 32 | `reg_debug_data2` | Register Read Data 2 |
| 5 | 32 | `mem_debug_data` | Memory Read Data |
| 6 | 32 | `reg_debug_addr1` | Register Read Address 1 |
| 7 | 32 | `reg_debug_addr2` | Register Read Address 2 |
| 8 | 32 | `immediate_debug` | Generated Immediate |
| 9 | 32 | `reg_write_debug` | Register Write Enable |
| 10 | 32 | `mem_read_debug` | Memory Read Enable |
| 11 | 32 | `mem_write_debug` | Memory Write Enable |
| 12 | 32 | `branch_taken_debug` | Branch Taken Status |

### Configuration Parameters

```systemverilog
module riscv_processor_jtag_debug #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1,
    parameter bit ENABLE_C = 1'b0,
    parameter int ILA_DEPTH = 1024  // Capture depth
)(...);
```

### ILA Black Box Declaration

```systemverilog
(* dont_touch = "true" *)
module ila_riscv_processor #(
    parameter int C_DATA_DEPTH = 1024
)(
    input  logic        clk,
    input  logic [31:0] probe0,
    input  logic [31:0] probe1,
    input  logic [31:0] probe2,
    input  logic [31:0] probe3,
    input  logic [31:0] probe4,
    input  logic [31:0] probe5,
    input  logic [31:0] probe6,
    input  logic [31:0] probe7,
    input  logic [31:0] probe8,
    input  logic [31:0] probe9,
    input  logic [31:0] probe10,
    input  logic [31:0] probe11,
    input  logic [31:0] probe12
);
endmodule
```

### Vivado ILA Customization

1. **Open synthesized design**
2. **Tools > Set Up Debug**
3. **ILA Core Options**:
   - Sample depth: 1024 (configurable via `ILA_DEPTH`)
   - Data width: 13 probes × 32-bit = 416 bits
   - Trigger width: 416 bits
4. **Probe Assignment**: Automatic from `mark_debug` or explicit instantiation

## VIO (Virtual Input/Output)

### VIO Interface

```systemverilog
(* dont_touch = "true" *)
module vio_riscv_processor (
    input  logic        clk,
    input  logic [31:0] probe_in0,
    input  logic [31:0] probe_in1,
    input  logic [31:0] probe_in2,
    output logic [31:0] probe_out0,
    output logic [31:0] probe_out1
);
endmodule
```

### VIO Probe Mapping

**Inputs (probe_in)**:
- `probe_in0` (32-bit): PC Status
- `probe_in1` (32-bit): Instruction Status
- `probe_in2` (32-bit): Control Status Register
  - [31:24]: Reserved
  - [23:17]: Current Opcode (7 bits)
  - [16]: Branch Taken
  - [15]: Memory Write
  - [14]: Memory Read
  - [13]: Register Write
  - [12]: Jump Op
  - [11]: Branch Op
  - [10]: Processor Active
  - [9]: Error Flag
  - [8:0]: Reserved

**Outputs** (for future runtime control):
- `probe_out0`: Control Register (reserved)
- `probe_out1`: Config Register (reserved)

## Debug Workflow

### 1. Synthesis with Debug
```bash
make implement-jtag
```

### 2. Program Device
```bash
vivado -mode batch -source - <<EOF
open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {build/vivado/riscv_processor_jtag_debug/riscv_processor_jtag_debug.bit} [current_hw_device]
program_hw_devices [current_hw_device]
EOF
```

### 3. Open Hardware Manager
```bash
vivado -mode gui -source - <<EOF
open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
open_hw_ila -name hw_ila_1
run_hw_ila
EOF
```

### 4. Configure ILA Trigger

**Common Trigger Conditions**:
| Scenario | Trigger Setup |
|----------|---------------|
| Branch taken | `probe12 == 1` |
| Error detected | `probe_in2[9] == 1` |
| Specific instruction | `probe1 == 32'h0041C263` (BLT) |
| Memory write | `probe11 == 1` |
| Register write | `probe9 == 1` |
| PC reaches address | `probe0 == 32'h00000020` |

**Trigger Mode**: Window (captures before/after trigger)
**Capture Depth**: 1024 samples (configurable via `ILA_DEPTH`)

### 2. Use VIO for Runtime Monitoring

**Monitor in Real-Time**:
- `probe_in0`: Current PC value
- `probe_in1`: Current instruction
- `probe_in2[23:17]`: Current opcode
- `probe_in2[16]`: Branch taken
- `probe_in2[9]`: Error flag

**Runtime Control** (future):
- `probe_out0`: Control register writes
- `probe_out1`: Config register writes

## Trigger Examples

### Trigger on Branch Taken
```
Trigger Condition: probe12 == 1
Trigger Mode: Window (512 before, 512 after)
```

### Trigger on Specific Instruction
```
Trigger Condition: probe1 == 32'h0041C263
Trigger Mode: Single
```

### Trigger on Error
```
Trigger Condition: probe_in2[9] == 1
Trigger Mode: Window
```

### Trigger on Memory Access
```
Trigger Condition: probe10 == 1 || probe11 == 1
Trigger Mode: Window
```

## Common Issues

| Issue | Solution |
|-------|----------|
| ILA not found | Check `dont_touch` attribute, re-synthesize |
| No trigger | Verify probe connections, check trigger condition syntax |
| VIO not updating | Check clock domain, probe_in connections |
| Timing violations | Add false paths to debug signals |
| Missing probes | Check `mark_debug` attributes, re-synthesize |

## Related Documents
- [JTAG Debug Build](jtag-debug.md)
- [Hardware Debug](hardware-debug.md)
- [Signal Probing](signal-probing.md)
- [Runtime Control](runtime-control.md)