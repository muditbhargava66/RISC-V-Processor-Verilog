# Hardware Debug Guide

## Overview

This guide covers hardware debugging using the JTAG/ILA/VIO infrastructure on the Basys3 board.

## Hardware Setup

### Required Hardware
- Basys3 board
- USB cable (JTAG + UART)
- Host PC with Vivado 2023.2+

### Connection
1. Connect Basys3 to PC via USB
2. Power on board (switch SW0)
3. Verify JTAG detection in Vivado Hardware Manager

## Vivado Hardware Manager

### Opening Hardware Manager
```bash
vivado -mode gui
# Tools > Open Hardware Manager
```

### Connecting to Target
```tcl
open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
```

### Programming Bitstream
```tcl
set_property PROGRAM.FILE {build/vivado/riscv_processor_jtag_debug/riscv_processor_jtag_debug.bit} [current_hw_device]
program_hw_devices [current_hw_device]
```

## ILA Debugging

### Opening ILA Dashboard
```tcl
open_hw_ila -name hw_ila_1
```

### Configuring Trigger

1. **Select ILA Core**: `hw_ila_1`
2. **Configure Trigger**:
   - Click **Trigger Setup**
   - Set conditions on probes
   - Choose trigger mode (Single/Window/Basic)

### Capture Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| Single | Capture once on trigger | One-time events |
| Window | Capture before/after trigger | Sequence analysis |
| Basic | Continuous capture | Long-term monitoring |

### Common Trigger Setups

#### Branch Taken
```
Probe: probe12 (branch_taken_debug)
Condition: == 1
Mode: Window (512 before, 512 after)
```

#### Specific Instruction (e.g., BLT at 0x1C)
```
Probe: probe1 (instruction_debug)
Condition: == 32'h0041C263
Mode: Single
```

#### Error Detection
```
Probe: probe_in2[9] (error_flag)
Condition: == 1
Mode: Window
```

#### Memory Access
```
Probe: probe11 (mem_write_debug) OR probe10 (mem_read_debug)
Condition: == 1
Mode: Window
```

#### Specific PC Value
```
Probe: probe0 (pc_debug)
Condition: == 32'h00000020
Mode: Single
```

### Waveform Analysis

#### Viewing Captured Data
1. Trigger fires → capture completes
2. Waveform window opens automatically
3. Use zoom/pan to navigate
3. Add markers for timing measurements

#### Key Measurements
| Measurement | Method |
|-------------|--------|
| Cycle count | Cursor delta on `clk` |
| Branch latency | Cursor on `branch_taken` to PC change |
| Memory latency | Cursor on `mem_read` to `mem_debug_data` valid |
| Pipeline bubbles | Gaps in `instruction_debug` sequence |

#### Exporting Data
```tcl
# Export to CSV
write_hw_ila_data -force -ofile capture.csv hw_ila_1

# Export to VCD
write_hw_ila_data -force -vcd -ofile capture.vcd hw_ila_1
```

## VIO Monitoring

### Opening VIO Dashboard
```tcl
open_hw_vio -name hw_vio_1
```

### Monitoring Status Registers

**Input Probes (Read-Only)**:
| Probe | Bits | Description |
|-------|------|-------------|
| `probe_in0` | 31:0 | PC Value |
| `probe_in1` | 31:0 | Current Instruction |
| `probe_in2` | 31:0 | Control Status |

**Control Status Register (probe_in2) Bit Map**:
| Bit | Name | Description |
|-----|------|-------------|
| 31:24 | Reserved | |
| 23:17 | Opcode | Current instruction opcode |
| 16 | Branch Taken | Branch condition evaluated true |
| 15 | Mem Write | Data memory write active |
| 14 | Mem Read | Data memory read active |
| 13 | Reg Write | Register file write active |
| 12 | Jump Op | JAL/JALR instruction |
| 11 | Branch Op | Branch instruction |
| 10 | Processor Active | Non-zero instruction executing |
| 9 | Error Flag | Illegal opcode detected |
| 8:0 | Reserved | |

### Runtime Control (Future)
**Output Probes** (for future use):
- `probe_out0`: Control Register
- `probe_out1`: Config Register

## Common Debug Scenarios

### Scenario 1: Program Stuck
**Symptoms**: LEDs static, PC not incrementing
**Debug Steps**:
1. Check `processor_active` (probe_in2[10])
2. Check `error_flag` (probe_in2[9])
3. Verify `instruction_debug` not 0 or NOP
4. Check PC sequence in ILA

### Scenario 2: Incorrect Branch Behavior
**Symptoms**: Wrong PC after branch
**Debug Steps**:
1. Trigger on `branch_taken_debug` (probe12)
2. Check `branch_op` (probe_in2[11])
3. Verify ALU result (probe2) and branch condition
4. Check PC before/after branch

### Scenario 3: Memory Corruption
**Symptoms**: Unexpected register values
**Debug Steps**:
1. Trigger on `mem_write_debug` (probe11)
2. Check `alu_result_debug` (address) and `reg_debug_data2` (write data)
3. Trigger on `mem_read_debug` (probe10)
4. Verify `mem_debug_data` matches expected

### Scenario 4: Illegal Instruction
**Symptoms**: `error_flag` asserted
**Debug Steps**:
1. Trigger on `error_flag` (probe_in2[9])
2. Capture `instruction_debug` (probe1)
3. Decode opcode (probe_in2[23:17])
4. Verify against ISA table

## LED Status Interpretation

### Minimal Wrapper (`pc_debug[15:0]`)
| Pattern | Meaning |
|---------|---------|
| Incrementing by 4 | Sequential execution |
| Sudden jump | Branch/Jump taken |
| Static | Processor halted/stuck |
| Alternating | Tight loop |

### JTAG Debug Wrapper
| LED | Signal | Meaning |
|-----|--------|---------|
| LD0-LD7 | `status_leds[7:0]` | PC[7:0] |
| LD8 | `processor_active` | High = executing |
| LD9 | `error_flag` | High = illegal opcode |

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Hardware Manager can't connect | Cable/driver issue | Check USB cable, reinstall drivers |
| ILA not visible | Not instantiated | Check `dont_touch` attribute, re-synthesize |
| No trigger | Condition never met | Verify probe connections, logic |
| VIO not updating | Clock domain | Check `clk` connected to VIO |
| Waveform empty | Trigger not armed | Click "Run Trigger" button |
| Timing violations on debug | No false paths | Add `set_false_path` to debug ports |

## Related Documents
- [ILA/VIO Integration](../debug/ila-vio.md)
- [Signal Probing](signal-probing.md)
- [Runtime Control](runtime-control.md)
- [JTAG Debug Build](../fpga/jtag-debug.md)