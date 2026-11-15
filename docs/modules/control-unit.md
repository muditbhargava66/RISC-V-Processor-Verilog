# Control Unit Module Reference

## Module: `control_unit`

**File**: `src/control_unit.sv`
**Parameters**: `ENABLE_M=1`, `ENABLE_C=0`

### Interface

```systemverilog
module control_unit #(
    parameter bit ENABLE_M = 1'b1,
    parameter bit ENABLE_C = 1'b0
)(
    input  logic [6:0]  opcode,
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,
    output logic        reg_write,
    output logic        mem_read,
    output logic        mem_write,
    output logic        branch,
    output logic        jump,
    output logic        alu_src1,
    output logic [1:0]  alu_src,
    output logic [4:0]  alu_op,
    output logic [1:0]  reg_write_src,
    output logic        is_div
);
```

`alu_op` is 5 bits (18 operations: 10 base + 8 M-extension). All encodings are the
`alu_op_e` / `alu_src_e` / `write_src_e` enums from `riscv_pkg.sv` (the single
source of truth — there are no local ALU-code localparams).

### Divide Detection (`is_div`)

```systemverilog
assign is_div = (opcode == OPCODE_R_TYPE) && (funct7 == FUNCT7_MULDIV) &&
                funct3[2] && ENABLE_M;
```

`funct3[2]=1` selects the divide/remainder ops (DIV=100, DIVU=101, REM=110,
REMU=111); the multiply ops (000..011) have `funct3[2]=0`. The core uses `is_div`
to stall for the sequential [Divider](divider.md). Gating by `ENABLE_M` means a
disabled M extension never stalls (the top-level trap logic flags it illegal).

### Decode Logic

```systemverilog
always_comb begin
    // Default values (prevent latches)
    reg_write = 0; mem_read = 0; mem_write = 0;
    branch = 0; jump = 0; alu_src1 = 0;
    alu_src = ALU_SRC_REG; alu_op = ALU_ADD; reg_write_src = WRITE_SRC_ALU;

    case (opcode)
        OPCODE_R_TYPE: begin
            reg_write = 1; alu_src = ALU_SRC_REG; reg_write_src = WRITE_SRC_ALU;
            case ({funct7, funct3})
                {FUNCT7_BASE,    FUNCT3_ADD_SUB}: alu_op = ALU_ADD;   // ADD
                {FUNCT7_SUB_SRA, FUNCT3_ADD_SUB}: alu_op = ALU_SUB;   // SUB
                // ... SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND ...
                {FUNCT7_MULDIV, 3'b000}: alu_op = ALU_MUL;    // MUL
                {FUNCT7_MULDIV, 3'b001}: alu_op = ALU_MULH;   // MULH
                {FUNCT7_MULDIV, 3'b010}: alu_op = ALU_MULHSU; // MULHSU
                {FUNCT7_MULDIV, 3'b011}: alu_op = ALU_MULHU;  // MULHU
                {FUNCT7_MULDIV, 3'b100}: alu_op = ALU_DIV;    // DIV
                {FUNCT7_MULDIV, 3'b101}: alu_op = ALU_DIVU;   // DIVU
                {FUNCT7_MULDIV, 3'b110}: alu_op = ALU_REM;    // REM
                {FUNCT7_MULDIV, 3'b111}: alu_op = ALU_REMU;   // REMU
                default: alu_op = ALU_ADD;
            endcase
        end
        OPCODE_I_TYPE: begin /* ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/SRLI/SRAI */ end
        OPCODE_LOAD:   begin reg_write=1; mem_read=1;  alu_src=ALU_SRC_IMM; reg_write_src=WRITE_SRC_MEM; end
        OPCODE_STORE:  begin mem_write=1; alu_src=ALU_SRC_IMM; end
        OPCODE_BRANCH: begin branch=1; alu_src=ALU_SRC_REG; /* SUB/SLT/SLTU by funct3 */ end
        OPCODE_JAL:    begin reg_write=1; jump=1; reg_write_src=WRITE_SRC_PC_PLUS_4; end
        OPCODE_JALR:   begin reg_write=1; jump=1; alu_src=ALU_SRC_IMM; reg_write_src=WRITE_SRC_PC_PLUS_4; end
        OPCODE_LUI:    begin reg_write=1; reg_write_src=WRITE_SRC_IMM; end
        OPCODE_AUIPC:  begin reg_write=1; alu_src1=1; alu_src=ALU_SRC_IMM; end
        OPCODE_SYSTEM: begin /* treated as NOP; flagged by top-level trap */ end
        default: begin /* all signals remain at default */ end
    endcase
end
```

### Output Signal Summary

| Signal | Width | Description | Active |
|--------|-------|-------------|--------|
| `reg_write` | 1 | Register write enable | High |
| `mem_read` | 1 | Data memory read enable | High |
| `mem_write` | 1 | Data memory write enable | High |
| `branch` | 1 | Branch instruction | High |
| `jump` | 1 | JAL/JALR instruction | High |
| `alu_src1` | 1 | ALU operand A select: 0=rs1, 1=PC | — |
| `alu_src` | 2 | ALU operand B: 00=rs2, 01=imm, 10=PC, 11=zero | — |
| `alu_op` | 5 | ALU operation select | — |
| `reg_write_src` | 2 | Writeback source: 00=ALU, 01=MEM, 10=PC+4, 11=IMM | — |
| `is_div` | 1 | RV32M divide/remainder: stall for the sequential divider | High |

### M-Extension Decode (ENABLE_M=1)

| funct7 | funct3 | Instruction | alu_op | Execution |
|--------|--------|-------------|--------|-----------|
| 0000001 | 000 | MUL | ALU_MUL | ALU, single-cycle |
| 0000001 | 001 | MULH | ALU_MULH | ALU, single-cycle |
| 0000001 | 010 | MULHSU | ALU_MULHSU | ALU, single-cycle |
| 0000001 | 011 | MULHU | ALU_MULHU | ALU, single-cycle |
| 0000001 | 100 | DIV | ALU_DIV | sequential divider |
| 0000001 | 101 | DIVU | ALU_DIVU | sequential divider |
| 0000001 | 110 | REM | ALU_REM | sequential divider |
| 0000001 | 111 | REMU | ALU_REMU | sequential divider |

All eight RV32M operations are implemented. The divide/remainder ALU codes yield
0 in the ALU; the core muxes the [Divider](divider.md) result into write-back.

### Implementation Notes

1. **Default assignments** prevent latches.
2. **Plain `case` with `default`** (not `unique case`): illegal encodings fall to
   the default and are flagged by the top-level trap logic, so simulation does
   not emit `unique case` violation spam.
3. **ENABLE_M guard** allows synthesis-time M-extension disable.
4. **Package enums** used for funct3/funct7/opcode/alu_op readability.
5. **Combinational `always_comb`** for zero-latency decode.

### Test Coverage

`testbenches/control_unit_tb.sv`: **45/45 decode vectors PASS**, covering all
RV32I opcodes and funct3/funct7 combinations plus the 8 RV32M decodes.

### Related Documents
- [Core Processor](core-processor.md)
- [ALU](alu.md)
- [Divider](divider.md)
- [ISA Support](../architecture/isa-support.md)
- [Architecture Overview](../architecture/overview.md)