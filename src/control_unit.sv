// Control Unit Module
// Generates control signals for all RV32I instructions
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
    output logic [3:0]  alu_op,
    output logic [1:0]  reg_write_src
);

    import riscv_pkg::*;

    // ALU operation codes
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

    // M-extension ALU ops
    localparam logic [3:0] ALU_MUL   = 4'b1110;
    localparam logic [3:0] ALU_MULH  = 4'b1111;
    localparam logic [3:0] ALU_DIV   = 4'b1010;
    localparam logic [3:0] ALU_REM   = 4'b1011;

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
            OPCODE_R_TYPE: begin
                reg_write      = 1'b1;
                alu_src        = ALU_SRC_REG;
                reg_write_src  = WRITE_SRC_ALU;

                unique case ({funct7, funct3})
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

                    // M-extension
                    {FUNCT7_MULDIV,    FUNCT3_ADD_SUB}: alu_op = (ENABLE_M) ? ALU_MUL   : ALU_ADD;  // MUL
                    {FUNCT7_MULDIV,    FUNCT3_SLL}:     alu_op = (ENABLE_M) ? ALU_MULH  : ALU_ADD;  // MULH
                    {FUNCT7_MULDIV,    FUNCT3_SLT}:     alu_op = (ENABLE_M) ? ALU_DIV   : ALU_ADD;  // DIV
                    {FUNCT7_MULDIV,    FUNCT3_SLTU}:    alu_op = (ENABLE_M) ? ALU_REM   : ALU_ADD;  // REM

                    default: alu_op = ALU_ADD;
                endcase
            end

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

                unique case (funct3)
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
                // For now, treat as NOP
            end

            default: begin
                // All signals remain at default values
            end
        endcase
    end

    // Synthesis-time assertion for debugging
    // synthesis translate_off
    always_comb begin
        if (!is_valid_base_opcode(opcode)) begin
            $warning("CTRL_UNIT: Unknown opcode: %07b", opcode);
        end
    end
    // synthesis translate_on

endmodule