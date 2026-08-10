// Control Unit Testbench
// Tests all RV32I instruction decoding
// SystemVerilog implementation

`timescale 1ns / 1ps

module control_unit_tb;

    import riscv_pkg::*;

    // Testbench signals
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic        reg_write;
    logic        mem_read;
    logic        mem_write;
    logic        branch;
    logic        jump;
    logic        alu_src1;
    logic [1:0]  alu_src;
    logic [3:0]  alu_op;
    logic [1:0]  reg_write_src;

    int test_count = 0;
    int pass_count = 0;

    // DUT instantiation
    control_unit dut (
        .opcode         (opcode),
        .funct3         (funct3),
        .funct7         (funct7),
        .reg_write      (reg_write),
        .mem_read       (mem_read),
        .mem_write      (mem_write),
        .branch         (branch),
        .jump           (jump),
        .alu_src1       (alu_src1),
        .alu_src        (alu_src),
        .alu_op         (alu_op),
        .reg_write_src  (reg_write_src)
    );

    // Test task
    task automatic test_instruction(
        input logic [6:0] op,
        input logic [2:0] f3,
        input logic [6:0] f7,
        input logic       expected_reg_write,
        input logic       expected_mem_read,
        input logic       expected_mem_write,
        input logic       expected_branch,
        input logic       expected_jump,
        input logic       expected_alu_src1,
        input logic [1:0] expected_alu_src,
        input logic [3:0] expected_alu_op,
        input logic [1:0] expected_reg_write_src,
        input string      inst_name
    );
    begin
        opcode = op;
        funct3 = f3;
        funct7 = f7;
        #10;

        test_count = test_count + 1;
        if (reg_write == expected_reg_write &&
            mem_read == expected_mem_read &&
            mem_write == expected_mem_write &&
            branch == expected_branch &&
            jump == expected_jump &&
            alu_src1 == expected_alu_src1 &&
            alu_src == expected_alu_src &&
            alu_op == expected_alu_op &&
            reg_write_src == expected_reg_write_src) begin
            pass_count = pass_count + 1;
            $display("PASS: %s", inst_name);
        end else begin
            $display("FAIL: %s", inst_name);
            $display("   Expected: rw=%b mr=%b mw=%b br=%b jmp=%b as1=%b as=%b ao=%b rws=%b",
                    expected_reg_write, expected_mem_read, expected_mem_write,
                    expected_branch, expected_jump, expected_alu_src1,
                    expected_alu_src, expected_alu_op, expected_reg_write_src);
            $display("   Got:      rw=%b mr=%b mw=%b br=%b jmp=%b as1=%b as=%b ao=%b rws=%b",
                    reg_write, mem_read, mem_write, branch, jump,
                    alu_src1, alu_src, alu_op, reg_write_src);
        end
    end
    endtask

    initial begin
        $display("========================================");
        $display("Control Unit Comprehensive Test");
        $display("========================================");

        // R-type instructions
        test_instruction(OPCODE_R_TYPE, FUNCT3_ADD_SUB, FUNCT7_BASE,      1,0,0,0,0, 1'b0, ALU_SRC_REG, ALU_ADD,  WRITE_SRC_ALU, "ADD");
        test_instruction(OPCODE_R_TYPE, FUNCT3_ADD_SUB, FUNCT7_SUB_SRA,   1,0,0,0,0, 1'b0, ALU_SRC_REG, ALU_SUB,  WRITE_SRC_ALU, "SUB");
        test_instruction(OPCODE_R_TYPE, FUNCT3_SLL,     FUNCT7_BASE,      1,0,0,0,0, 1'b0, ALU_SRC_REG, ALU_SLL,  WRITE_SRC_ALU, "SLL");
        test_instruction(OPCODE_R_TYPE, FUNCT3_SLT,     FUNCT7_BASE,      1,0,0,0,0, 1'b0, ALU_SRC_REG, ALU_SLT,  WRITE_SRC_ALU, "SLT");
        test_instruction(OPCODE_R_TYPE, FUNCT3_SLTU,    FUNCT7_BASE,      1,0,0,0,0, 1'b0, ALU_SRC_REG, ALU_SLTU, WRITE_SRC_ALU, "SLTU");
        test_instruction(OPCODE_R_TYPE, FUNCT3_XOR,     FUNCT7_BASE,      1,0,0,0,0, 1'b0, ALU_SRC_REG, ALU_XOR,  WRITE_SRC_ALU, "XOR");
        test_instruction(OPCODE_R_TYPE, FUNCT3_SRL_SRA, FUNCT7_BASE,      1,0,0,0,0, 1'b0, ALU_SRC_REG, ALU_SRL,  WRITE_SRC_ALU, "SRL");
        test_instruction(OPCODE_R_TYPE, FUNCT3_SRL_SRA, FUNCT7_SUB_SRA,   1,0,0,0,0, 1'b0, ALU_SRC_REG, ALU_SRA,  WRITE_SRC_ALU, "SRA");
        test_instruction(OPCODE_R_TYPE, FUNCT3_OR,      FUNCT7_BASE,      1,0,0,0,0, 1'b0, ALU_SRC_REG, ALU_OR,   WRITE_SRC_ALU, "OR");
        test_instruction(OPCODE_R_TYPE, FUNCT3_AND,     FUNCT7_BASE,      1,0,0,0,0, 1'b0, ALU_SRC_REG, ALU_AND,  WRITE_SRC_ALU, "AND");

        // I-type instructions
        test_instruction(OPCODE_I_TYPE, FUNCT3_ADD_SUB, 7'b0,             1,0,0,0,0, 1'b0, ALU_SRC_IMM, ALU_ADD,  WRITE_SRC_ALU, "ADDI");
        test_instruction(OPCODE_I_TYPE, FUNCT3_SLT,     7'b0,             1,0,0,0,0, 1'b0, ALU_SRC_IMM, ALU_SLT,  WRITE_SRC_ALU, "SLTI");
        test_instruction(OPCODE_I_TYPE, FUNCT3_SLTU,    7'b0,             1,0,0,0,0, 1'b0, ALU_SRC_IMM, ALU_SLTU, WRITE_SRC_ALU, "SLTIU");
        test_instruction(OPCODE_I_TYPE, FUNCT3_XOR,     7'b0,             1,0,0,0,0, 1'b0, ALU_SRC_IMM, ALU_XOR,  WRITE_SRC_ALU, "XORI");
        test_instruction(OPCODE_I_TYPE, FUNCT3_OR,      7'b0,             1,0,0,0,0, 1'b0, ALU_SRC_IMM, ALU_OR,   WRITE_SRC_ALU, "ORI");
        test_instruction(OPCODE_I_TYPE, FUNCT3_AND,     7'b0,             1,0,0,0,0, 1'b0, ALU_SRC_IMM, ALU_AND,  WRITE_SRC_ALU, "ANDI");
        test_instruction(OPCODE_I_TYPE, FUNCT3_SLL,     7'b0,             1,0,0,0,0, 1'b0, ALU_SRC_IMM, ALU_SLL,  WRITE_SRC_ALU, "SLLI");
        test_instruction(OPCODE_I_TYPE, FUNCT3_SRL_SRA, 7'b0100000,       1,0,0,0,0, 1'b0, ALU_SRC_IMM, ALU_SRA,  WRITE_SRC_ALU, "SRAI");
        test_instruction(OPCODE_I_TYPE, FUNCT3_SRL_SRA, 7'b0000000,       1,0,0,0,0, 1'b0, ALU_SRC_IMM, ALU_SRL,  WRITE_SRC_ALU, "SRLI");

        // Load instructions
        test_instruction(OPCODE_LOAD, FUNCT3_LB,  7'b0, 1,1,0,0,0, 1'b0, ALU_SRC_IMM, ALU_ADD, WRITE_SRC_MEM, "LB");
        test_instruction(OPCODE_LOAD, FUNCT3_LH,  7'b0, 1,1,0,0,0, 1'b0, ALU_SRC_IMM, ALU_ADD, WRITE_SRC_MEM, "LH");
        test_instruction(OPCODE_LOAD, FUNCT3_LW,  7'b0, 1,1,0,0,0, 1'b0, ALU_SRC_IMM, ALU_ADD, WRITE_SRC_MEM, "LW");
        test_instruction(OPCODE_LOAD, FUNCT3_LBU, 7'b0, 1,1,0,0,0, 1'b0, ALU_SRC_IMM, ALU_ADD, WRITE_SRC_MEM, "LBU");
        test_instruction(OPCODE_LOAD, FUNCT3_LHU, 7'b0, 1,1,0,0,0, 1'b0, ALU_SRC_IMM, ALU_ADD, WRITE_SRC_MEM, "LHU");

        // Store instructions
        test_instruction(OPCODE_STORE, FUNCT3_SB, 7'b0, 0,0,1,0,0, 1'b0, ALU_SRC_IMM, ALU_ADD, WRITE_SRC_ALU, "SB");
        test_instruction(OPCODE_STORE, FUNCT3_SH, 7'b0, 0,0,1,0,0, 1'b0, ALU_SRC_IMM, ALU_ADD, WRITE_SRC_ALU, "SH");
        test_instruction(OPCODE_STORE, FUNCT3_SW, 7'b0, 0,0,1,0,0, 1'b0, ALU_SRC_IMM, ALU_ADD, WRITE_SRC_ALU, "SW");

        // Branch instructions
        test_instruction(OPCODE_BRANCH, FUNCT3_BEQ,  7'b0, 0,0,0,1,0, 1'b0, ALU_SRC_REG, ALU_SUB,  WRITE_SRC_ALU, "BEQ");
        test_instruction(OPCODE_BRANCH, FUNCT3_BNE,  7'b0, 0,0,0,1,0, 1'b0, ALU_SRC_REG, ALU_SUB,  WRITE_SRC_ALU, "BNE");
        test_instruction(OPCODE_BRANCH, FUNCT3_BLT,  7'b0, 0,0,0,1,0, 1'b0, ALU_SRC_REG, ALU_SLT,   WRITE_SRC_ALU, "BLT");
        test_instruction(OPCODE_BRANCH, FUNCT3_BGE,  7'b0, 0,0,0,1,0, 1'b0, ALU_SRC_REG, ALU_SLT,   WRITE_SRC_ALU, "BGE");
        test_instruction(OPCODE_BRANCH, FUNCT3_BLTU, 7'b0, 0,0,0,1,0, 1'b0, ALU_SRC_REG, ALU_SLTU,  WRITE_SRC_ALU, "BLTU");
        test_instruction(OPCODE_BRANCH, FUNCT3_BGEU, 7'b0, 0,0,0,1,0, 1'b0, ALU_SRC_REG, ALU_SLTU,  WRITE_SRC_ALU, "BGEU");

        // Jump instructions
        test_instruction(OPCODE_JAL,  7'b0, 7'b0, 1,0,0,0,1, 1'b0, ALU_SRC_REG, ALU_ADD, WRITE_SRC_PC_PLUS_4, "JAL");
        test_instruction(OPCODE_JALR, FUNCT3_JALR, 7'b0, 1,0,0,0,1, 1'b0, ALU_SRC_IMM, ALU_ADD, WRITE_SRC_PC_PLUS_4, "JALR");

        // Upper immediate instructions
        test_instruction(OPCODE_LUI,   7'b0, 7'b0, 1,0,0,0,0, 1'b0, ALU_SRC_REG, ALU_ADD, WRITE_SRC_IMM, "LUI");
        test_instruction(OPCODE_AUIPC, 7'b0, 7'b0, 1,0,0,0,0, 1'b1, ALU_SRC_IMM, ALU_ADD, WRITE_SRC_ALU, "AUIPC");

        $display("========================================");
        $display("Control Unit Test Results: %0d/%0d tests passed", pass_count, test_count);
        if (pass_count == test_count) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        $display("========================================");

        $finish;
    end

endmodule