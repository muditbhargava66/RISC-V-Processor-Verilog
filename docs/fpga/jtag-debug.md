# JTAG Debug Build Guide

## Overview

The JTAG debug wrapper (`riscv_processor_jtag_debug`) provides full internal visibility through explicit ILA/VIO instantiation, using only 12 I/O pins.

## Build Flow

```bash
# Create project
make create-project-jtag

# Full implementation with bitstream
make implement-jtag
```

### Using Vivado Directly

```bash
# Create project
vivado -mode batch -source scripts/build_vivado.tcl -tclargs jtag

# Synthesize and implement
vivado -mode batch -source scripts/run_synthesis_impl.tcl -tclargs jtag
```

## ILA/VIO Integration

### Explicit Instantiation

The wrapper includes explicit black-box instantiation of ILA and VIO cores:

```systemverilog
ila_riscv_processor #(
    .C_DATA_DEPTH (ILA_DEPTH)
) u_ila (
    .clk     (clk),
    .probe0  (pc_debug),             // [31:0] Program Counter
    .probe1  (instruction_debug),    // [31:0] Current Instruction
    .probe2  (alu_result_debug),     // [31:0] ALU Result
    .probe3  (reg_debug_data1),      // [31:0] Reg Read Data 1
    .probe4  (reg_debug_data2),      // [31:0] Reg Read Data 2
    .probe5  (mem_debug_data),       // [31:0] Memory Read Data
    .probe6  ({27'd0, reg_debug_addr1}), // [31:0] Reg Read Addr 1
    .probe7  ({27'd0, reg_debug_addr2}), // [31:0] Reg Read Addr 2
    .probe8  (immediate_debug),      // [31:0] Generated Immediate
    .probe9  ({31'd0, reg_write_debug}), // [31:0] Reg Write Enable
    .probe10 ({31'd0, mem_read_debug}),  // [31:0] Mem Read Enable
    .probe11 ({31'd0, mem_write_debug}), // [31:0] Mem Write Enable
    .probe12 ({31'd0, branch_taken_debug}) // [31:0] Branch Taken
);

vio_riscv_processor u_vio (
    .clk           (clk),
    .probe_in0     (pc_debug),           // [31:0] PC Status
    .probe_in1     (instruction_debug),  // [31:0] Instruction Status
    .probe_in2     ({24'd0, instruction_debug[6:0], branch_taken_debug, 
                     mem_write_debug, mem_read_debug, reg_write_debug,
                     jump_op, branch_op, processor_active, error_flag}),
    .probe_out0    (),  // Control Register (reserved)
    .probe_out1    ()   // Config Register (reserved)
);
```

### Black Box Declarations

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

## Pin Mapping

| Signal | Pin | Description |
|--------|-----|-------------|
| `clk` | W5 | 100 MHz clock |
| `reset` | U18 | Reset button |
| `status_leds[0]` | U16 | LED 0 (LD0) |
| `status_leds[1]` | E19 | LED 1 (LD1) |
| `status_leds[2]` | U19 | LED 2 (LD2) |
| `status_leds[3]` | V19 | LED 3 (LD3) |
| `status_leds[4]` | W18 | LED 4 (LD4) |
| `status_leds[5]` | U15 | LED 5 (LD5) |
| `status_leds[6]` | U14 | LED 6 (LD6) |
| `status_leds[7]` | V14 | LED 7 (LD7) |
| `processor_active` | V13 | Activity LED |
| `error_flag` | V3 | Error LED |

## Debug Capabilities

### ILA Probes (13 x 32-bit)

| Probe | Signal | Description |
|-------|--------|-------------|
| 0 | `pc_debug` | Program Counter |
| 1 | `instruction_debug` | Current Instruction |
| 2 | `alu_result_debug` | ALU Result |
| 2 | `reg_debug_data1` | Register Read Data 1 |
| 4 | `reg_debug_data2` | Register Read Data 2 |
| 5 | `mem_debug_data` | Memory Read Data |
| 6 | `reg_debug_addr1` | Register Read Address 1 |
| 7 | `reg_debug_addr2` | Register Read Address 2 |
| 8 | `immediate_debug` | Generated Immediate |
| 9 | `reg_write_debug` | Register Write Enable |
| 10 | `mem_read_debug` | Memory Read Enable |
| 11 | `mem_write_debug` | Memory Write Enable |
| 12 | `branch_taken_debug` | Branch Taken Status |

### VIO Interface

**Inputs (to VIO)**:
- `probe_in0`: PC Status (32-bit)
- `probe_in1`: Instruction Status (32-bit)
- `probe_in2`: Control Status Register (32-bit)
  - Bits 31:24: Reserved
  - Bits 23:17: Current Opcode (7 bits)
  - Bit 16: Branch Taken
  - Bit 15: Mem Write
  - Bit 14: Mem Read
  - Bit 13: Reg Write
  - Bit 12: Jump Op
  - Bit 11: Branch Op
  - Bit 10: Processor Active
  - Bit 9: Error Flag
  - Bits 8:0: Reserved

**Outputs (from VIO)**:
- `probe_out0`: Control Register (reserved for future runtime control)
- `probe_out1`: Config Register (reserved for future runtime config)

## Build and Debug Flow

### 1. Build
```bash
make implement-jtag
```

### 2. Program Board
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

1. Open ILA dashboard in Hardware Manager
2. Set trigger conditions:
   - **Trigger on**: `branch_taken_debug == 1`
   - **Or**: `error_flag == 1`
   - **Or**: Specific instruction pattern
3. Set capture mode: **Window** (capture before/after trigger)
4. Set capture depth: **1024** samples
5. Click **Run Trigger**

### 5. Use VIO for Runtime Control

1. Open VIO dashboard
2. Monitor `probe_in` status registers in real-time
3. Use `probe_out` for future runtime control (reserved)

## Resource Usage

| Resource | Minimal | JTAG Debug | Available |
|----------|---------|------------|-----------|
| LUTs | ~4,100 | ~4,200 | 20,800 |
| FFs | ~8,400 | ~8,500 | 41,600 |
| DSPs | 2 | 2 | 90 |
| I/O | 18 | 12 | 88 |

## ILA Configuration

### Default Settings
- **Capture Depth**: 1024 samples
- **Trigger Mode**: Auto (manual or trigger)
- **Data Depth**: 13 probes x 32-bit
- **Clock Domain**: System clock (50 MHz)

### Customizing Capture Depth

```systemverilog
module riscv_processor_jtag_debug #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1,
    parameter bit ENABLE_C = 1'b0,
    parameter int ILA_DEPTH = 1024  // Change here
)(...);
```

### Common Trigger Patterns

| Scenario | Trigger Condition |
|----------|-------------------|
| Branch taken | `probe12 == 1` |
| Error detected | `probe_in2[9] == 1` |
| Specific opcode | `probe_in2[23:17] == 7'b1101111` (JAL) |
| Specific PC | `probe0 == 32'h00000020` |
| Memory write | `probe11 == 1` |
| Register write | `probe9 == 1` |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| ILA not visible | Check `dont_touch` attribute on ILA/VIO modules |
| No trigger | Verify probe connections, check trigger condition |
| VIO not updating | Ensure `probe_in` signals connected, check clock domain |
| Timing violation | Add false paths to debug signals in XDC |
| Bitstream too large | Reduce ILA depth, remove unused probes |

## Related Documents
- [Basys3 Build Guide](basys3-guide.md)
- [Hardware Debug Guide](../debug/hardware-debug.md)
- [Signal Probing Guide](../debug/signal-probing.md)
- [Runtime Control Guide](../debug/runtime-control.md)