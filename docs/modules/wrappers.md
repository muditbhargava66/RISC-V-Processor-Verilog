# Wrapper Modules Reference

## Module: `riscv_processor_minimal`

**File**: `src/riscv_processor_minimal.sv`  
**Purpose**: Production wrapper for Basys3 (12 I/O pins)

### Interface

```systemverilog
module riscv_processor_minimal #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1,
    parameter bit ENABLE_C = 1'b0
)(
    input  logic        clk,
    input  logic        reset,
    output logic [15:0] pc_debug
);
```

### Implementation

```systemverilog
logic [XLEN-1:0] full_pc_debug;

riscv_processor #(
    .XLEN     (XLEN),
    .ENABLE_M (ENABLE_M),
    .ENABLE_C (ENABLE_C)
) u_riscv_processor (
    .clk                  (clk),
    .reset                (reset),
    .pc_debug             (full_pc_debug),
    .instruction_debug    (),
    .alu_result_debug     (),
    .reg_debug_data1      (),
    .reg_debug_data2      (),
    .mem_debug_data       (),
    .reg_debug_addr1      (),
    .reg_debug_addr2      (),
    .immediate_debug      (),
    .reg_write_debug      (),
    .mem_read_debug       (),
    .mem_write_debug      (),
    .branch_taken_debug   ()
);

assign pc_debug = full_pc_debug[15:0];
```

### Pin Mapping (Basys3 Artix-7 XC7A35T-CPG236-1)

| Signal | Pin | I/O Standard | Description |
|--------|-----|--------------|-------------|
| `clk` | W5 | LVCMOS33 | 100 MHz system clock |
| `reset` | U18 | LVCMOS33 | Reset button (active high) |
| `pc_debug[0]` | U16 | LVCMOS33 | LED 0 (LD0) |
| `pc_debug[1]` | E19 | LVCMOS33 | LED 1 (LD1) |
| `pc_debug[2]` | U19 | LVCMOS33 | LED 2 (LD2) |
| `pc_debug[3]` | V19 | LVCMOS33 | LED 3 (LD3) |
| `pc_debug[4]` | W18 | LVCMOS33 | LED 4 (LD4) |
| `pc_debug[5]` | U15 | LVCMOS33 | LED 5 (LD5) |
| `pc_debug[6]` | U14 | LVCMOS33 | LED 6 (LD6) |
| `pc_debug[7]` | V14 | LVCMOS33 | LED 7 (LD7) |
| `pc_debug[8]` | V13 | LVCMOS33 | LED 8 (LD8) |
| `pc_debug[9]` | V3 | LVCMOS33 | LED 9 (LD9) |
| `pc_debug[10]` | W3 | LVCMOS33 | LED 10 (LD10) |
| `pc_debug[11]` | U3 | LVCMOS33 | LED 11 (LD11) |
| `pc_debug[12]` | P3 | LVCMOS33 | LED 12 (LD12) |
| `pc_debug[13]` | N3 | LVCMOS33 | LED 13 (LD13) |
| `pc_debug[14]` | P1 | LVCMOS33 | LED 14 (LD14) |
| `pc_debug[15]` | L1 | LVCMOS33 | LED 15 (LD15) |

### Timing Constraints

```tcl
# Clock: 50 MHz (20ns period)
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} [get_ports clk]

# Input delay for reset
set_input_delay -clock sys_clk_pin -min 0.500 [get_ports reset]
set_input_delay -clock sys_clk_pin -max 2.000 [get_ports reset]

# Output delay for debug LEDs
set_output_delay -clock sys_clk_pin -min 0.500 [get_ports {pc_debug[*]}]
set_output_delay -clock sys_clk_pin -max 3.000 [get_ports {pc_debug[*]}]

# False paths for debug outputs
set_false_path -to [get_ports {pc_debug[*]}]

# Clock uncertainty
set_clock_uncertainty -setup 0.100 [get_clocks sys_clk_pin]
set_clock_uncertainty -hold 0.050 [get_clocks sys_clk_pin]

# Max delay constraint
set_max_delay -from [get_clocks sys_clk_pin] -to [get_clocks sys_clk_pin] 19.500

# I/O voltage configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
```

### Resource Usage (Synthesis)

| Resource | Usage | Available | Utilization |
|----------|-------|-----------|-------------|
| LUTs | ~4,100 | 20,800 | ~19.7% |
| FFs | ~8,400 | 41,600 | ~20.2% |
| DSPs | 2 | 90 | 2.2% |
| BRAM | 0 | 50 | 0% |
| I/O | 18 | 88 | 20.5% |

## Module: `riscv_processor_jtag_debug`

**File**: `src/riscv_processor_jtag_debug.sv`  
**Purpose**: Hardware debug with explicit ILA/VIO instantiation

### Interface

```systemverilog
module riscv_processor_jtag_debug #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1,
    parameter bit ENABLE_C = 1'b0,
    parameter int ILA_DEPTH = 1024
)(
    input  logic        clk,
    input  logic        reset,
    output logic [7:0]  status_leds,
    output logic        processor_active,
    output logic        error_flag
);
```

### Pin Mapping (Basys3)

| Signal | Pin | I/O Standard | Description |
|--------|-----|--------------|-------------|
| `clk` | W5 | LVCMOS33 | 100 MHz system clock |
| `reset` | U18 | LVCMOS33 | Reset button |
| `status_leds[0]` | U16 | LVCMOS33 | LED 0 (LD0) |
| `status_leds[1]` | E19 | LVCMOS33 | LED 1 (LD1) |
| `status_leds[2]` | U19 | LVCMOS33 | LED 2 (LD2) |
| `status_leds[3]` | V19 | LVCMOS33 | LED 3 (LD3) |
| `status_leds[4]` | W18 | LVCMOS33 | LED 4 (LD4) |
| `status_leds[5]` | U15 | LVCMOS33 | LED 5 (LD5) |
| `status_leds[6]` | U14 | LVCMOS33 | LED 6 (LD6) |
| `status_leds[7]` | V14 | LVCMOS33 | LED 7 (LD7) |
| `processor_active` | V13 | LVCMOS33 | Activity LED |
| `error_flag` | V3 | LVCMOS33 | Error LED |

### Explicit ILA Instantiation

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
```

### Explicit VIO Instantiation

```systemverilog
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

### Status Outputs

| Signal | Width | Source | Description |
|--------|-------|--------|-------------|
| `status_leds` | 8 | `pc_debug[7:0]` | PC lower 8 bits on LEDs |
| `processor_active` | 1 | `\|instruction_debug` | High when instruction non-zero |
| `error_flag` | 1 | `active && !valid_opcode` | Illegal opcode detected |

### Resource Usage (JTAG Debug Version)

| Resource | Usage | Available | Utilization |
|----------|-------|-----------|-------------|
| LUTs | ~4,200 | 20,800 | ~20.2% |
| FFs | ~8,500 | 41,600 | ~20.4% |
| DSPs | 2 | 90 | 2.2% |
| BRAM | 0 | 50 | 0% |
| I/O | 12 | 88 | 13.6% |

### ILA/VIO Black Box Declarations

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

### Related Documents
- [JTAG Debug Guide](../debug/ila-vio.md)
- [FPGA Implementation](../fpga/basys3-guide.md)
- [Core Processor](../modules/core-processor.md)