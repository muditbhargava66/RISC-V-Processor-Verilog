# ALU Module Reference

## Module: `alu`

**File**: `src/alu.sv`  
**Lines**: ~80  
**Parameters**: `XLEN=32`, `ENABLE_M=1`

### Interface

```systemverilog
module alu #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1
)(
    input  logic [XLEN-1:0] operand_a,
    input  logic [XLEN-1:0] operand_b,
    input  logic [4:0]      alu_control,
    output logic [XLEN-1:0] result,
    output logic            zero
);
```

### Operation Table

Control values are the 5-bit `alu_op_e` enums from `src/riscv_pkg.sv` (the single
source of truth). All ALU operations are purely combinational (single-cycle).
**Divide/remainder are not computed here** — since v1.2.0 they are handled by the
sequential [Divider](divider.md); the ALU returns 0 for those codes and the core
muxes the divider result into write-back.

| alu_control | Operation | Description | M-Ext |
|------------|-----------|-------------|-------|
| 5'd0 | ADD | `operand_a + operand_b` | Base |
| 5'd1 | SUB | `operand_a - operand_b` | Base |
| 5'd2 | AND | `operand_a & operand_b` | Base |
| 5'd3 | OR | `operand_a \| operand_b` | Base |
| 5'd4 | XOR | `operand_a ^ operand_b` | Base |
| 5'd5 | SLL | `operand_a << operand_b[4:0]` | Base |
| 5'd6 | SRL | `operand_a >> operand_b[4:0]` | Base |
| 5'd7 | SRA | `$signed(operand_a) >>> operand_b[4:0]` | Base |
| 5'd8 | SLT | `($signed(a) < $signed(b)) ? 1 : 0` | Base |
| 5'd9 | SLTU | `(a < b) ? 1 : 0` | Base |
| 5'd10 | MUL | `(a * b)[31:0]` | M-Ext |
| 5'd11 | MULH | `($signed(a) * $signed(b))[63:32]` | M-Ext |
| 5'd12 | MULHSU | `($signed(a) * $signed({1'b0,b}))[63:32]` | M-Ext |
| 5'd13 | MULHU | `(a * b)[63:32]` (unsigned) | M-Ext |
| 5'd14 | DIV | sequential divider (ALU outputs 0) | M-Ext |
| 5'd15 | DIVU | sequential divider (ALU outputs 0) | M-Ext |
| 5'd16 | REM | sequential divider (ALU outputs 0) | M-Ext |
| 5'd17 | REMU | sequential divider (ALU outputs 0) | M-Ext |

### Implementation Details

```systemverilog
always_comb begin
    result = '0;
    case (alu_control)
        ALU_ADD:  result = operand_a + operand_b;
        ALU_SUB:  result = operand_a - operand_b;
        ALU_AND:  result = operand_a & operand_b;
        ALU_OR:   result = operand_a | operand_b;
        ALU_XOR:  result = operand_a ^ operand_b;
        ALU_SLL:  result = operand_a << operand_b[$clog2(XLEN)-1:0];
        ALU_SRL:  result = operand_a >> operand_b[$clog2(XLEN)-1:0];
        ALU_SRA:  result = $signed(operand_a) >>> operand_b[$clog2(XLEN)-1:0];
        ALU_SLT:  result = ($signed(operand_a) < $signed(operand_b)) ? {{(XLEN-1){1'b0}},1'b1} : '0;
        ALU_SLTU: result = (operand_a < operand_b) ? {{(XLEN-1){1'b0}},1'b1} : '0;

        // M-extension multiply (guarded by ENABLE_M)
        ALU_MUL:   if (ENABLE_M) result = (operand_a * operand_b)[XLEN-1:0];
        ALU_MULH:  if (ENABLE_M) result = ($signed(operand_a) * $signed(operand_b))[2*XLEN-1:XLEN];
        ALU_MULHSU:if (ENABLE_M) result = ($signed(operand_a) * $signed({1'b0,operand_b}))[2*XLEN-1:XLEN];
        ALU_MULHU: if (ENABLE_M) result = (operand_a * operand_b)[2*XLEN-1:XLEN];

        // Divide/remainder are computed by the sequential divider, not here.
        ALU_DIV, ALU_DIVU, ALU_REM, ALU_REMU: result = '0;

        default: result = '0;
    endcase
end

assign zero = (result == '0);
```

### Resource Usage (M-Extension) — verified

The verified Artix-7 build uses **0 DSP48 blocks**: Vivado maps the multipliers
to LUTs/CARRY4 rather than DSP48E1. Multiply is combinational single-cycle;
divide/remainder are handled by the sequential [Divider](divider.md).

| Operation | Implementation | Latency |
|-----------|----------------|---------|
| MUL | LUT/CARRY4 | 1 cycle (combinational) |
| MULH/MULHSU/MULHU | LUT/CARRY4 | 1 cycle (combinational) |
| DIV/DIVU | sequential restoring divider | ~32 cycles (core stalls) |
| REM/REMU | sequential restoring divider | ~32 cycles (core stalls) |

> **Note (v1.2.0)**: DIV/REM moved out of the ALU into a registered multi-cycle
> divider. The former combinational divider was the core's longest timing path;
> removing it shortens the critical path. Corner cases (divide-by-zero, signed
> overflow) still resolve in one cycle. DSP48 inference for the multiplier can be
> encouraged with `(* use_dsp = "yes" *)` if desired.

### Timing Characteristics

The whole core is verified post-route at **50 MHz** (WNS +4.134 ns, WHS +0.081 ns;
all constraints met). The worst core path is ~15.9 ns. Divide/remainder are no
longer combinational — they run in the sequential [Divider](divider.md), so they
do not appear in the ALU's combinational path. Per-operation delays below are
rough estimates, not individually measured:

| Operation | Estimated Delay | Notes |
|-----------|-----------------|-------|
| ADD/SUB | ~3 ns | carry chain |
| Logical | ~2 ns | single LUT level |
| Shift | ~4 ns | barrel shifter |
| SLT/SLTU | ~5 ns | subtract + compare |
| MUL/MULH | ~6–8 ns | LUT/CARRY4 multiplier |
| DIV/REM | n/a (sequential) | computed by the multi-cycle divider, not the ALU |

### Zero Flag

```systemverilog
assign zero = (result == '0);
```

- **Combinational** - updates immediately with result
- **Used by**: Branch conditions (BEQ, BNE, BLT, BGE, BLTU, BGEU)

### Test Coverage

`testbenches/alu_tb.sv` covers the base RV32I operations and the RV32M multiply
ops: **21/21 vectors PASS**. Divide/remainder vectors moved to
`testbenches/divider_tb.sv` (**884/884 checks PASS**, including the corner cases
below) when the divider became sequential in v1.2.0.

| Group | Scope | Status |
|-------|-------|--------|
| Base ALU | ADD/SUB/AND/OR/XOR/SLL/SRL/SRA/SLT/SLTU | PASS |
| M multiply | MUL/MULH/MULHSU/MULHU (incl. signed/unsigned corners) | PASS |
| M divide | DIV/DIVU/REM/REMU — see [Divider](divider.md) | PASS (divider_tb) |

### Edge Cases Handled

| Case | Behavior |
|------|----------|
| ADD overflow | Wraps (mod 2^32) |
| SUB underflow | Wraps (mod 2^32) |
| SLL by ≥32 | Result = 0 (shift by 32+ masked to 5 bits) |
| SRL by ≥32 | Result = 0 |
| SRA of negative | Arithmetic shift preserves sign |
| SLT signed | Correct for negative numbers |
| SLTU unsigned | Correct for large unsigned |

Divide/remainder corner cases (DIV/DIVU by zero, REM/REMU by zero, −2³¹/−1
overflow) are handled by the [Divider](divider.md) per the RISC-V spec.

### Related Documents
- [Core Processor](../modules/core-processor.md)
- [Control Unit](control-unit.md)
- [Architecture Overview](../architecture/overview.md)