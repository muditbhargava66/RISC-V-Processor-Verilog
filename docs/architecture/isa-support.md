# RV32I Base ISA Support

## Instruction Categories

| Category | Instructions | Count | Status |
|----------|--------------|-------|--------|
| R-type | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND | 10 | Yes |
| I-type ALU | ADDI, SLTI, SLTIU, XORI, ORI, ANDI | 6 | Yes |
| I-type Shift | SLLI, SRLI, SRAI | 3 | Yes |
| Loads | LB, LH, LW, LBU, LHU | 5 | Yes |
| Stores | SB, SH, SW | 3 | Yes |
| Branches | BEQ, BNE, BLT, BGE, BLTU, BGEU | 6 | Yes |
| Jumps | JAL, JALR | 2 | Yes |
| Upper Imm | LUI, AUIPC | 2 | Yes |
| System | ECALL, EBREAK | 2 | Minimal |

**Base RV32I instruction categories are decoded.** SYSTEM (ECALL/EBREAK/CSR) is
unimplemented and raises the core `trap` output; there are no CSRs.

## Opcode Map

| Instruction | Opcode | funct3 | funct7 | Format |
|-------------|--------|--------|--------|--------|
| ADD | 0110011 | 000 | 0000000 | R |
| SUB | 0110011 | 000 | 0100000 | R |
| SLL | 0110011 | 001 | 0000000 | R |
| SLT | 0110011 | 010 | 0000000 | R |
| SLTU | 0110011 | 011 | 0000000 | R |
| XOR | 0110011 | 100 | 0000000 | R |
| SRL | 0110011 | 101 | 0000000 | R |
| SRA | 0110011 | 101 | 0100000 | R |
| OR | 0110011 | 110 | 0000000 | R |
| AND | 0110011 | 111 | 0000000 | R |
| ADDI | 0010011 | 000 | - | I |
| SLTI | 0010011 | 010 | - | I |
| SLTIU | 0010011 | 011 | - | I |
| XORI | 0010011 | 100 | - | I |
| ORI | 0010011 | 110 | - | I |
| ANDI | 0010011 | 111 | - | I |
| SLLI | 0010011 | 001 | 0000000 | I |
| SRLI | 0010011 | 101 | 0000000 | I |
| SRAI | 0010011 | 101 | 0100000 | I |
| LB | 0000011 | 000 | - | I |
| LH | 0000011 | 001 | - | I |
| LW | 0000011 | 010 | - | I |
| LBU | 0000011 | 100 | - | I |
| LHU | 0000011 | 101 | - | I |
| SB | 0100011 | 000 | - | S |
| SH | 0100011 | 001 | - | S |
| SW | 0100011 | 010 | - | S |
| BEQ | 1100011 | 000 | - | B |
| BNE | 1100011 | 001 | - | B |
| BLT | 1100011 | 100 | - | B |
| BGE | 1100011 | 101 | - | B |
| BLTU | 1100011 | 110 | - | B |
| BGEU | 1100011 | 111 | - | B |
| JAL | 1101111 | - | - | J |
| JALR | 1100111 | 000 | - | I |
| LUI | 0110111 | - | - | U |
| AUIPC | 0010111 | - | - | U |

## Instruction Formats

### R-type (Register-Register)
```
31                                    0
┌───────┬─────┬─────┬──────┬────┬──────┐
│funct7 │ rs2 │ rs1 │funct3│ rd │opcode│
└───────┴─────┴─────┴──────┴────┴──────┘
  7        5     5     3     5     7
```

### I-type (Immediate)
```
31                                 0
┌───────────┬─────┬──────┬─────┬──────┐
│ imm[11:0] │ rs1 │funct3│ rd  │opcode│
└───────────┴─────┴──────┴─────┴──────┘
    12       5      3      5      7
```

### S-type (Store)
```
31                                         0
┌─────────┬─────┬─────┬──────┬────────┬──────┐
│imm[11:5]│ rs2 │ rs1 │funct3│imm[4:0]│opcode│
└─────────┴─────┴─────┴──────┴────────┴──────┘
  7          5     5     3     5         7
```

### B-type (Branch)
```
31                                        0
┌──┬──────┬─────┬─────┬──────┬───┬─────────┐
│12│10:5  │ rs2 │ rs1 │funct3│4:1│11│opcode│
└──┴──────┴─────┴─────┴──────┴───┴─────────┘
 1    6      5     5     3     4  1    7
```

### U-type (Upper Immediate)
```
31                          0
┌───────────────┬─────┬──────┐
│ imm[31:12]    │ rd  │opcode│
└───────────────┴─────┴──────┘
     20          5       7
```

### J-type (JAL)
```
31                             0
┌──┬────┬───┬───────┬─────┬──────┐
│20│10:1│11 │19:12  │ rd  │opcode│
└──┴────┴───┴───────┴─────┴──────┘
 1   10  1    8       5       7
```

## Immediate Generation

| Type | Instruction | Immediate Construction |
|------|-------------|------------------------|
| I | ADDI, loads, JALR | `{{20{imm[11]}}, imm[11:0]}` |
| S | Stores | `{{20{imm[11]}}, imm[11:5], imm[4:0]}` |
| B | Branches | `{{19{imm[12]}}, imm[12], imm[10:5], imm[4:1], 1'b0}` |
| U | LUI, AUIPC | `{imm[31:12], 12'b0}` |
| J | JAL | `{{11{imm[20]}}, imm[20], imm[10:1], imm[11], imm[19:12], 1'b0}` |

## M-Extension (ENABLE_M=1)

| Instruction | Opcode | funct3 | funct7 | Description |
|-------------|--------|--------|--------|-------------|
| MUL | 0110011 | 000 | 0000001 | Multiply (low 32) |
| MULH | 0110011 | 001 | 0000001 | Multiply high (signed) |
| MULHSU | 0110011 | 010 | 0000001 | Multiply high (signed×unsigned) |
| MULHU | 0110011 | 011 | 0000001 | Multiply high (unsigned) |
| DIV | 0110011 | 100 | 0000001 | Signed divide |
| DIVU | 0110011 | 101 | 0000001 | Unsigned divide |
| REM | 0110011 | 110 | 0000001 | Signed remainder |
| REMU | 0110011 | 111 | 0000001 | Unsigned remainder |

Multiply (MUL/MULH/MULHSU/MULHU) is single-cycle in the ALU. Divide/remainder
(DIV/DIVU/REM/REMU) use a multi-cycle sequential restoring divider
([Divider](../modules/divider.md)) that stalls the core ~32 cycles; divide-by-zero
and signed-overflow corner cases resolve in one cycle. All spec corner cases are
implemented (DIV/0→−1, DIVU/0→max unsigned, REM/REMU/0→dividend, −2³¹/−1 overflow).

## C-Extension (RV32C subset, Planned — not implemented)

`ENABLE_C` is currently a reserved parameter; no compressed decode exists yet.
The table lists the RV32C subset only (RV64C-only instructions such as C.ADDIW,
C.LD and C.SD are excluded).

| Instruction | Format | Description |
|-------------|--------|-------------|
| C.ADDI | CI | Add immediate |
| C.LI | CI | Load immediate |
| C.LUI | CI | Load upper immediate |
| C.ADDI16SP | CI | Add to SP |
| C.ADDI4SPN | CIW | Add to SP |
| C.SRLI | CB | Shift right logical |
| C.SRAI | CB | Shift right arithmetic |
| C.ANDI | CB | AND immediate |
| C.SUB | CR | Subtract |
| C.XOR | CR | XOR |
| C.OR | CR | OR |
| C.AND | CR | AND |
| C.J | CJ | Jump |
| C.JAL | CJ | Jump and link |
| C.JR | CR | Jump register |
| C.JALR | CR | Jump and link register |
| C.BEQZ | CB | Branch if zero |
| C.BNEZ | CB | Branch if not zero |
| C.LW | CL | Load word |
| C.SW | CS | Store word |

## Unsupported / Future

| Feature | Status | Notes |
|---------|--------|-------|
| F/D Extensions | No | Floating point |
| A Extension | No | Atomic operations |
| Zicsr | No | No CSRs; SYSTEM raises `trap` |
| Zifencei | No | Instruction fence |
| Zihpm | No | Hardware perf counters |
| Sv32/Sv39/Sv48 | No | Virtual memory |
| Debug Spec | Partial | JTAG ILA only |

## Verification Status

| Instruction | System Test | Unit Test | Formal |
|-------------|-------------|-----------|--------|
| All R-type | Yes | Yes | Yes |
| All I-type ALU | Yes | Yes | Yes |
| All Shifts | Yes | Yes | Yes |
| All Loads | Yes | Yes | Yes |
| All Stores | Yes | Yes | Yes |
| All Branches | Yes | Yes | Yes |
| JAL/JALR | Yes | Yes | Yes |
| LUI/AUIPC | Yes | Yes | Yes |
| M-Extension (MUL/DIV) | Yes | Yes | No |

> **Note**: RV32M multiply is covered by `alu_tb` and `control_unit_tb`; divide/remainder
> by the dedicated `divider_tb` (884 checks) and the compliance harness. No dedicated
> formal properties for the M extension yet.

## Reference

- [RISC-V ISA Specification](https://riscv.org/specifications/)
- [RV32I Base ISA](https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf)
- [Module Reference: Control Unit](../modules/control-unit.md)
- [Module Reference: Immediate Generator](../modules/immediate-generator.md)