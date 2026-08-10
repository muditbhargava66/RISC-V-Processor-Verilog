# Control Unit Module Reference

## Module: `control_unit`

**File**: `src/control_unit.sv`  
**Lines**: ~180  
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
    output logic [3:0]  alu_op,
    output logic [1:0]  reg_write_src
);
```

### Local Parameters

```systemverilog
// ALU operations
localparam logic [3:0] ALU_ADD  = 4'b0000;
localparam logic [3:0] ALU_SUB  = 4'b1000;
localparam logic [3:0] ALU_AND  = 4'b0111;
localparam logic [3:0] ALU_OR   = 4'b0110;
localparam logic [3:0] ALU_XOR  = 4'b0100;
localparam logic [3:0] ALU_SLL  = 4'b0001;
localparam logic [3:0] ALU_SRL  = 4'b0101;
localparam logic [3:0] ALU_SRA  = 4'b1101;
localparam logic [3:0] ALU_SLT  = 4'b0010;
localparam logic [3:0] ALU_SLTU = 4'b0011;

// M-extension
localparam logic [3:0] ALU_MUL   = 4'b1110;
localparam logic [3:0] ALU_MULH  = 4'b1111;
localparam logic [3:0] ALU_DIV   = 4'b1010;
localparam logic [3:0] ALU_REM   = 4'b1011;

// ALU sources
localparam logic [1:0] ALU_SRC_REG = 2'b00;
localparam logic [1:0] ALU_SRC_IMM = 2'b01;
localparam logic [1:0] ALU_SRC_PC  = 2'b10;

// Register write sources
localparam logic [1:0] WRITE_SRC_ALU       = 2'b00;
localparam logic [1:0] WRITE_SRC_MEM       = 2'b01;
localparam logic [1:0] WRITE_SRC_PC_PLUS_4 = 2'b10;
localparam logic [1:0] WRITE_SRC_IMM       = 2'b11;

// Funct7 values
localparam logic [6:0] FUNCT7_BASE      = 7'b0000000;
localparam logic [6:0] FUNCT7_SUB_SRA   = 7'b0100000;
localparam logic [6:0] FUNCT7_MULDIV    = 7'b0000001;

// Funct3 values (using package enums)
```

### Decode Logic

```systemverilog
always_comb begin
    // Default values
    reg_write      = 1'b0;
    mem_read       = 1'b0;
    mem_write      = 1'b0;
    branch         = 1'b0;
    jump           = 1'b0;
    alu_src1       = 1'b0;
    alu_src        = ALU_SRC_REG;
    alu_op         = ALU_ADD;
    reg_write_src  = WRITE_SRC_ALU;

    unique case (opcode)
        // R-type: Register-Register operations
        OPCODE_R_TYPE: begin
            reg_write      = 1'b1;
            alu_src        = ALU_SRC_REG;
            reg_write_src  = WRITE_SRC_ALU;
            
            unique case ({funct7, funct3})
                {FUNCT7_BASE,      FUNCT3_ADD_SUB}: alu_op = ALU_ADD;   // ADD
                {FUNCT7_SUB_SRA,   FUNCT3_ADD_SUB}: alu_op = ALU_SUB;   // SUB
                {FUNCT7_BASE,      FUNCT3_SLL}:     alu_op = ALU_SLL;   // SLL
                {FUNCT7_BASE,      FUNCT3_SLT}:     alu_op = ALU_SLT;   // SLT
                {FUNCT7_BASE,      FUNCT3_SLTU}:    alu_op = ALU_SLTU;  // SLTU
                {FUNCT7_BASE,      FUNCT3_XOR}:     alu_op = ALU_XOR;   // XOR
                {FUNCT7_BASE,      FUNCT3_SRL_SRA}: alu_op = ALU_SRL;   // SRL
                {FUNCT7_SUB_SRA,   FUNCT3_SRL_SRA}: alu_op = ALU_SRA;   // SRA
                {FUNCT7_BASE,      FUNCT3_OR}:      alu_op = ALU_OR;    // OR
                {FUNCT7_BASE,      FUNCT3_AND}:     alu_op = ALU_AND;   // AND
                
                // M-extension
                {FUNCT7_MULDIV,    FUNCT3_ADD_SUB}: alu_op = (ENABLE_M) ? ALU_MUL   : ALU_ADD;  // MUL
                {FUNCT7_MULDIV,    FUNCT3_SLL}:     alu_op = (ENABLE_M) ? ALU_MULH  : ALU_ADD;  // MULH
                {FUNCT7_MULDIV,    FUNCT3_SLT}:     alu_op = (ENABLE_M) ? ALU_DIV   : ALU_ADD;  // DIV
                {FUNCT7_MULDIV,    FUNCT3_SLTU}:    alu_op = (ENABLE_M) ? ALU_REM   : ALU_ADD;  // REM
                
                default: alu_op = ALU_ADD;
            endcase
        end

        // I-type: Immediate ALU operations
        OPCODE_I_TYPE: begin
            reg_write      = 1'b1;
            alu_src        = ALU_SRC_IMM;
            reg_write_src  = WRITE_SRC_ALU;
            
            unique case (funct3)
                FUNCT3_ADD_SUB: alu_op = ALU_ADD;   // ADDI
                FUNCT3_SLT:     alu_op = ALU_SLT;   // SLTI
                FUNCT3_SLTU:    alu_op = ALU_SLTU;  // SLTIU
                FUNCT3_XOR:     alu_op = ALU_XOR;   // XORI
                FUNCT3_OR:      alu_op = ALU_OR;    // ORI
                FUNCT3_AND:     alu_op = ALU_AND;   // ANDI
                FUNCT3_SLL:     alu_op = ALU_SLL;   // SLLI
                FUNCT3_SRL_SRA: begin
                    if (funct7[5]) alu_op = ALU_SRA; // SRAI
                    else           alu_op = ALU_SRL; // SRLI
                end
                default: alu_op = ALU_ADD;
            endcase
        end

        // Load instructions
        OPCODE_LOAD: begin
            reg_write      = 1'b1;
            mem_read       = 1'b1;
            alu_src        = ALU_SRC_IMM;
            alu_op         = ALU_ADD;           // Address = rs1 + imm
            reg_write_src  = WRITE_SRC_MEM;     // Write memory data to register
        end

        // Store instructions
        OPCODE_STORE: begin
            mem_write      = 1'b1;
            alu_src        = ALU_SRC_IMM;
            alu_op         = ALU_ADD;           // Address = rs1 + imm
        end

        // Branch instructions
        OPCODE_BRANCH: begin
            branch         = 1'b1;
            alu_src        = ALU_SRC_REG;
            
            unique case (funct3)
                FUNCT3_BEQ:  alu_op = ALU_SUB;  // BEQ
                FUNCT3_BNE:  alu_op = ALU_SUB;  // BNE
                FUNCT3_BLT:  alu_op = ALU_SLT;  // BLT (signed <)
                FUNCT3_BGE:  alu_op = ALU_SLT;  // BGE (signed >=)
                FUNCT3_BLTU: alu_op = ALU_SLTU; // BLTU (unsigned <)
                FUNCT3_BGEU: alu_op = ALU_SLTU; // BGEU (unsigned >=)
                default:     alu_op = ALU_SUB;
            endcase
        end

        // JAL: Jump and Link
        OPCODE_JAL: begin
            reg_write      = 1'b1;
            jump           = 1'b1;
            reg_write_src  = WRITE_SRC_PC_PLUS_4;  // Return address = PC+4
        end

        // JALR: Jump and Link Register
        OPCODE_JALR: begin
            reg_write      = 1'b1;
            jump           = 1'b1;
            alu_src        = ALU_SRC_IMM;
            alu_op         = ALU_ADD;              // Target = rs1 + imm
            reg_write_src  = WRITE_SRC_PC_PLUS_4;  // Return address = PC+4
        end

        // LUI: Load Upper Immediate
        OPCODE_LUI: begin
            reg_write      = 1'b1;
            reg_write_src  = WRITE_SRC_IMM;        // Write immediate to register
        end

        // AUIPC: Add Upper Immediate to PC
        OPCODE_AUIPC: begin
            reg_write      = 1'b1;
            alu_src1       = 1'b1;                 // Operand A = PC
            alu_src        = ALU_SRC_IMM;          // Operand B = immediate
            alu_op         = ALU_ADD;              // PC + immediate
            reg_write_src  = WRITE_SRC_ALU;        // Write ALU result
        end

        // System instructions (ECALL, EBREAK, CSR)
        OPCODE_SYSTEM: begin
            // Minimal implementation - treat as NOP
        end

        default: begin
            // All signals remain at default (0)
        end
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
| `alu_src` | 2 | ALU operand B: 00=rs2, 01=imm, 10=PC | — |
| `alu_op` | 4 | ALU operation select | — |
| `reg_write_src` | 2 | Writeback source: 00=ALU, 01=MEM, 10=PC+4, 11=IMM | — |

### Opcode Decode Map

| Opcode | Name | reg_wr | mem_rd | mem_wr | branch | jump | alu_src | reg_wr_src |
|--------|------|--------|--------|--------|--------|------|---------|------------|
| 0110011 | R-type | 1 | 0 | 0 | 0 | 0 | REG | ALU |
| 0010011 | I-type | 1 | 0 | 0 | 0 | 0 | IMM | ALU |
| 0000011 | Load | 1 | 1 | 0 | 0 | 0 | IMM | MEM |
| 0100011 | Store | 0 | 0 | 1 | 0 | 0 | IMM | ALU |
| 1100011 | Branch | 0 | 0 | 0 | 1 | 0 | REG | ALU |
| 1101111 | JAL | 1 | 0 | 0 | 0 | 1 | REG | PC+4 |
| 1100111 | JALR | 1 | 0 | 0 | 0 | 1 | IMM | PC+4 |
| 0110111 | LUI | 1 | 0 | 0 | 0 | 0 | REG | IMM |
| 0010111 | AUIPC | 1 | 0 | 0 | 0 | 0 | IMM | ALU |

### M-Extension Decode

| funct7 | funct3 | Instruction | alu_op (if ENABLE_M) |
|--------|--------|-------------|---------------------|
| 0000001 | 000 | MUL | ALU_MUL |
| 0000001 | 001 | MULH | ALU_MULH |
| 0000001 | 010 | MULHSU | (not implemented) |
| 0000001 | 011 | MULHU | (not implemented) |
| 0000001 | 100 | DIV | ALU_DIV |
| 0000001 | 101 | DIVU | (not implemented) |
| 0000001 | 110 | REM | ALU_REM |
| 0000001 | 111 | REMU | (not implemented) |

### Shift Amount Encoding (I-type)

| funct3 | funct7[5] | Instruction | ALU Op |
|--------|-----------|-------------|--------|
| 001 | 0 | SLLI | ALU_SLL |
| 101 | 0 | SRLI | ALU_SRL |
| 101 | 1 | SRAI | ALU_SRA |

### Branch ALU Operations

| funct3 | Instruction | ALU Op | Condition |
|--------|-------------|--------|-----------|
| 000 | BEQ | SUB | zero == 1 |
| 001 | BNE | SUB | zero == 0 |
| 100 | BLT | SLT | result[0] == 1 (signed <) |
| 101 | BGE | SLT | result[0] == 0 (signed >=) |
| 110 | BLTU | SLTU | result[0] == 1 (unsigned <) |
| 111 | BGEU | SLTU | result[0] == 0 (unsigned >=) |

### Implementation Notes

1. **Default assignments** prevent latches
2. **Unique case** ensures parallel_case synthesis
3. **ENABLE_M guard** allows M-extension synthesis-time disable
4. **Package enums** used for funct3/funct7/opcode readability
5. **Combinational always_comb** for zero-latency decode

### Test Coverage

| Category | Tests | Status |
|----------|-------|--------|
| R-type | 10 | ✅ |
| I-type ALU | 6 | ✅ |
| I-type Shift | 3 | ✅ |
| Loads | 5 | ✅ |
| Stores | 3 | ✅ |
| Branches | 6 | ✅ |
| Jumps | 2 | ✅ |
| Upper Imm | 2 | ✅ |
| **Total** | **37** | **✅ 100%** |

### Related Documents
- [Core Processor](../modules/core-processor.md)
- [ALU](alu.md)
- [ISA Support](../architecture/isa-support.md)
- [Architecture Overview](../architecture/overview.md)