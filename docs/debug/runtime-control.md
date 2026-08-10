# Runtime Control Guide

## Overview

The VIO (Virtual Input/Output) core provides runtime control and monitoring capabilities through JTAG without recompilation.

## VIO Interface

### Current Implementation (Monitoring Only)

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

### Input Monitoring (probe_in)

| Probe | Bits | Description |
|-------|------|-------------|
| `probe_in0` | 31:0 | Program Counter |
| `probe_in1` | 31:0 | Current Instruction |
| `probe_in2` | 31:0 | Control Status Register |

**Control Status Register Bit Map**:
| Bit | Name | Description |
|-----|------|-------------|
| 31:24 | Reserved | |
| 23:17 | Opcode | Current instruction opcode |
| 16 | Branch Taken | Branch condition true |
| 15 | Mem Write | Data memory write active |
| 14 | Mem Read | Data memory read active |
| 13 | Reg Write | Register file write active |
| 12 | Jump Op | JAL/JALR instruction |
| 11 | Branch Op | Branch instruction |
| 10 | Processor Active | Non-zero instruction |
| 9 | Error Flag | Illegal opcode detected |
| 8:0 | Reserved | |

### Output Control (probe_out) - Reserved for Future

| Probe | Width | Planned Use |
|-------|-------|-------------|
| `probe_out0` | 32 | Control Register |
| `probe_out1` | 32 | Config Register |

## Future Runtime Control Features

### Planned Control Register (probe_out0)
| Bit | Name | Function |
|-----|------|----------|
| 0 | Single Step | Enable single-step mode |
| 1 | Break on Error | Halt on error_flag |
| 2 | Break on Branch | Halt on branch_taken |
| 3 | Break on PC Match | Halt when PC == value |
| 4 | Inject Instruction | Override instruction |
| 5 | Flush Pipeline | Clear pipeline state |
| 31:6 | Reserved | |

### Planned Config Register (probe_out1)
| Bit | Name | Function |
|-----|------|----------|
| 7:0 | Breakpoint PC Low | Low 8 bits of breakpoint PC |
| 15:8 | Breakpoint PC High | High 8 bits of breakpoint PC |
| 16 | Enable Breakpoint | Enable PC breakpoint |
| 31:17 | Reserved | |

## VIO Dashboard Usage

### Opening VIO
```tcl
open_hw_vio -name hw_vio_1
```

### Monitoring Status
1. Open VIO dashboard
2. Observe `probe_in` values updating in real-time
3. Monitor status changes without stopping processor

### Setting Breakpoints (Future)
1. Set `probe_out0[3]` = 1 (Enable PC breakpoint)
2. Set `probe_out1[15:0]` = breakpoint address
3. Processor halts when PC matches

### Single Stepping (Future)
1. Set `probe_out0[0]` = 1 (Single step mode)
2. Pulse `probe_out0[5]` = 1 (Step pulse)
3. Processor executes one instruction, halts

## Current Limitations

| Feature | Status |
|---------|--------|
| Real-time monitoring | Working |
| Runtime breakpoints | Reserved (probe_out not connected) |
| Single stepping | Reserved |
| Instruction injection | Reserved |
| Pipeline flush | Reserved |

## Implementation Notes

### VIO Clock Domain
- VIO runs on same clock as processor (`clk`)
- No clock domain crossing needed
- Synchronous with processor pipeline

### Probe Width
- All probes 32-bit for consistency
- Control status packed into 32-bit register
- Easy to expand in future

### Latency
- VIO reads: ~2-3 clock cycles
- VIO writes: ~2-3 clock cycles
- No impact on processor timing (separate JTAG domain)

## Related Documents
- [ILA/VIO Integration](ila-vio.md)
- [Hardware Debug](hardware-debug.md)
- [Signal Probing](signal-probing.md)
- [JTAG Debug Build](../fpga/jtag-debug.md)