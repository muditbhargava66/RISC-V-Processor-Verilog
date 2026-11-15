# Divider Module Reference

## Module: `divider`

**File**: `src/divider.sv`
**Parameters**: `XLEN=32` (RV32 only)
**Introduced**: v1.2.0

A sequential radix-2 **restoring divider** for the RV32M divide/remainder
instructions (`DIV`, `DIVU`, `REM`, `REMU`). It replaces the former combinational
divide logic in the ALU, which was the core's longest timing path. The core
stalls (holds the PC) while a division is in progress and writes the result back
on the cycle the divider signals `done`.

### Interface

```systemverilog
module divider #(
    parameter int XLEN = 32
)(
    input  logic             clk,
    input  logic             reset,
    input  logic             start,         // pulse to begin a division
    input  logic             is_signed,     // 1 = DIV/REM, 0 = DIVU/REMU
    input  logic             is_remainder,  // 1 = REM/REMU, 0 = DIV/DIVU
    input  logic [XLEN-1:0]  dividend,
    input  logic [XLEN-1:0]  divisor,
    output logic [XLEN-1:0]  result,        // corner_result when corner=1, else registered
    output logic             done,          // single-cycle pulse: result_reg valid
    output logic             busy,          // high during the iterative computation
    output logic             corner         // combinational: divide-by-zero / overflow
);
```

### Handshake

| Signal | Direction | Meaning |
|--------|-----------|---------|
| `start` | in | Sample operands and begin. The core pulses it once per divide. |
| `busy` | out | High from the cycle after `start` until the result is ready. |
| `done` | out | Registered single-cycle pulse marking the final result. |
| `corner` | out | Combinational flag for the spec corner cases (see below). |
| `result` | out | `corner_result` when `corner=1`, otherwise the registered quotient/remainder. |

The core derives its control as:

```systemverilog
assign div_start = is_div && !div_busy && !div_done;   // pulse once
assign div_done  = div_done_pulse | (is_div && div_corner);
assign pc_hold   = is_div && !div_done;                // freeze PC while dividing
assign reg_write = reg_write_ctrl && (!is_div || div_done);
```

`is_signed = ~funct3[0]` and `is_remainder = funct3[1]` decode the four ops
directly from the instruction's `funct3` field.

### Algorithm

Normal cases divide the **unsigned magnitudes** and apply signs afterward,
which yields RISC-V trunc-toward-zero semantics:

1. On `start` (non-corner): latch `|dividend|`, `|divisor|`, the quotient sign
   (`sign(dividend) XOR sign(divisor)`), and the remainder sign (`sign(dividend)`).
2. Iterate **32 times** (verified in `divider_tb`): shift the partial remainder
   and quotient left by one; if the shifted remainder ≥ divisor, subtract and set
   the quotient LSB (restoring division).
3. On the final iteration, apply the latched signs and pulse `done`.

The magnitude of `−2³¹` is `2³¹`, which fits the 32-bit unsigned datapath, so the
most-negative dividend is handled correctly for all non-overflow divisors.

### Corner Cases (combinational fast path)

These resolve in the `start` cycle via `corner`/`corner_result`; `busy` never
rises and the core does not stall:

| Case | `DIV`/`DIVU` result | `REM`/`REMU` result |
|------|---------------------|---------------------|
| divisor = 0 | `0xFFFFFFFF` (−1 / max unsigned) | dividend |
| `−2³¹ / −1` (signed overflow) | `0x80000000` (−2³¹) | 0 |

### Latency

- **Normal divide**: 32 shift/subtract iterations (measured in `divider_tb`),
  plus the start/done handshake cycles. The PC is held for the duration.
- **Corner case**: 1 cycle (combinational).
- **Multiply** (`MUL`/`MULH`/`MULHSU`/`MULHU`) is unaffected — still single-cycle
  in the ALU.

### Verification

`testbenches/divider_tb.sv` checks the divider against an independent oracle built
from SystemVerilog's own signed/unsigned arithmetic: directed corner cases, the
directed normal vectors formerly in `alu_tb`, 200 randomized operand/sign/opcode
combinations, busy/done handshake timing, single-cycle `done` pulse, and reset.
**884/884 checks pass.** End-to-end core behavior is covered by `compliance_tests`
Phase C (RV32M) with the stall active.

### Related Documents
- [ALU](alu.md)
- [Core Processor](core-processor.md)
- [Program Counter](program-counter.md)
- [Architecture Overview](../architecture/overview.md)