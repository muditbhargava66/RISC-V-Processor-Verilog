`timescale 1ns / 1ps
// Control Unit Module
// Generates control signals for all RV32I instructions and the RV32M extension
// SystemVerilog implementation with always_comb

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
    output logic        is_div        // RV32M divide/remainder: needs multi-cycle stall
);

    import riscv_pkg::*;

    // Divide/remainder detection: R-type, M-extension funct7, funct3 >= 100
    // (DIV=100, DIVU=101, REM=110, REMU=111 all have funct3[2]=1; the multiply
    // ops 000..011 have funct3[2]=0). Gated by ENABLE_M so a disabled M extension
    // never stalls (the top-level trap logic flags it as illegal instead).
    assign is_div = (opcode == OPCODE_R_TYPE) && (funct7 == FUNCT7_MULDIV) &&
                    funct3[2] && ENABLE_M;

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

        case (opcode)
            OPCODE_R_TYPE: begin
                reg_write      = 1'b1;
                alu_src        = ALU_SRC_REG;
                reg_write_src  = WRITE_SRC_ALU;

                case ({funct7, funct3})
                    {FUNCT7_BASE,      FUNCT3_ADD_SUB}: alu_op = ALU_ADD;  // ADD
                    {FUNCT7_SUB_SRA,   FUNCT3_ADD_SUB}: alu_op = ALU_SUB;  // SUB
                    {FUNCT7_BASE,      FUNCT3_SLL}:     alu_op = ALU_SLL;  // SLL
                    {FUNCT7_BASE,      FUNCT3_SLT}:     alu_op = ALU_SLT;  // SLT
                    {FUNCT7_BASE,      FUNCT3_SLTU}:    alu_op = ALU_SLTU; // SLTU
                    {FUNCT7_BASE,      FUNCT3_XOR}:     alu_op = ALU_XOR;  // XOR
                    {FUNCT7_BASE,      FUNCT3_SRL_SRA}: alu_op = ALU_SRL;  // SRL
                    {FUNCT7_SUB_SRA,   FUNCT3_SRL_SRA}: alu_op = ALU_SRA;  // SRA
                    {FUNCT7_BASE,      FUNCT3_OR}:      alu_op = ALU_OR;   // OR
                    {FUNCT7_BASE,      FUNCT3_AND}:     alu_op = ALU_AND;  // AND

                    // M-extension: funct3 per RV32M spec (000..111)
                    {FUNCT7_MULDIV,    3'b000}: alu_op = ALU_MUL;    // MUL
                    {FUNCT7_MULDIV,    3'b001}: alu_op = ALU_MULH;   // MULH
                    {FUNCT7_MULDIV,    3'b010}: alu_op = ALU_MULHSU; // MULHSU
                    {FUNCT7_MULDIV,    3'b011}: alu_op = ALU_MULHU;  // MULHU
                    {FUNCT7_MULDIV,    3'b100}: alu_op = ALU_DIV;    // DIV
                    {FUNCT7_MULDIV,    3'b101}: alu_op = ALU_DIVU;   // DIVU
                    {FUNCT7_MULDIV,    3'b110}: alu_op = ALU_REM;    // REM
                    {FUNCT7_MULDIV,    3'b111}: alu_op = ALU_REMU;   // REMU

                    default: alu_op = ALU_ADD;
                endcase
            end

            OPCODE_I_TYPE: begin
                reg_write      = 1'b1;
                alu_src        = ALU_SRC_IMM;
                reg_write_src  = WRITE_SRC_ALU;

                case (funct3)
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

            OPCODE_LOAD: begin
                reg_write      = 1'b1;
                mem_read       = 1'b1;
                alu_src        = ALU_SRC_IMM;
                alu_op         = ALU_ADD;
                reg_write_src  = WRITE_SRC_MEM;
            end

            OPCODE_STORE: begin
                mem_write      = 1'b1;
                alu_src        = ALU_SRC_IMM;
                alu_op         = ALU_ADD;
            end

            OPCODE_BRANCH: begin
                branch         = 1'b1;
                alu_src        = ALU_SRC_REG;

                case (funct3)
                    FUNCT3_BEQ:  alu_op = ALU_SUB;  // BEQ
                    FUNCT3_BNE:  alu_op = ALU_SUB;  // BNE
                    FUNCT3_BLT:  alu_op = ALU_SLT;  // BLT
                    FUNCT3_BGE:  alu_op = ALU_SLT;  // BGE
                    FUNCT3_BLTU: alu_op = ALU_SLTU; // BLTU
                    FUNCT3_BGEU: alu_op = ALU_SLTU; // BGEU
                    default:     alu_op = ALU_SUB;
                endcase
            end

            OPCODE_JAL: begin
                reg_write      = 1'b1;
                jump           = 1'b1;
                reg_write_src  = WRITE_SRC_PC_PLUS_4;
            end

            OPCODE_JALR: begin
                reg_write      = 1'b1;
                jump           = 1'b1;
                alu_src        = ALU_SRC_IMM;
                alu_op         = ALU_ADD;
                reg_write_src  = WRITE_SRC_PC_PLUS_4;
            end

            OPCODE_LUI: begin
                reg_write      = 1'b1;
                reg_write_src  = WRITE_SRC_IMM;
            end

            OPCODE_AUIPC: begin
                reg_write      = 1'b1;
                alu_src1       = 1'b1;  // PC as operand A
                alu_src        = ALU_SRC_IMM;
                alu_op         = ALU_ADD;
                reg_write_src  = WRITE_SRC_ALU;
            end

            OPCODE_SYSTEM: begin
                // System instructions (ECALL, EBREAK, CSR) - minimal implementation
                // Treated as NOP; flagged by the top-level trap logic as unimplemented.
            end

            default: begin
                // All signals remain at default values
            end
        endcase
    end

    // Optional simulation-only diagnostic (enable with +define+RISCV_DEBUG).
    // synthesis translate_off
`ifdef RISCV_DEBUG
    always_comb begin
        if (!is_valid_base_opcode(opcode)) begin
            $warning("CTRL_UNIT: Unknown opcode: %07b", opcode);
        end
    end
`endif
    // synthesis translate_on

endmodule
