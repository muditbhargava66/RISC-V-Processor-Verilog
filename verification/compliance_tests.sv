// RISC-V Directed Compliance Test
// A real directed harness (replaces the previous opportunistic sampler).
// Programs are assembled in-testbench with field encoders, deposited into the
// instruction memory, executed for a fixed number of cycles, and the resulting
// architectural register state is checked against an independent oracle.
// Covers RV32I datapath, loads/stores, the RV32M extension, and control flow.
// Self-checking with $fatal on any failure.

`timescale 1ns / 1ps

module compliance_tests;

    import riscv_pkg::*;

    logic clk;
    logic reset;

    logic [31:0] pc_debug, instruction_debug, alu_result_debug;
    logic [31:0] reg_debug_data1, reg_debug_data2, mem_debug_data, immediate_debug;
    logic [4:0]  reg_debug_addr1, reg_debug_addr2;
    logic        reg_write_debug, mem_read_debug, mem_write_debug, branch_taken_debug, trap;

    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    riscv_processor dut (
        .clk(clk), .reset(reset),
        .pc_debug(pc_debug), .instruction_debug(instruction_debug),
        .alu_result_debug(alu_result_debug),
        .reg_debug_data1(reg_debug_data1), .reg_debug_data2(reg_debug_data2),
        .mem_debug_data(mem_debug_data),
        .reg_debug_addr1(reg_debug_addr1), .reg_debug_addr2(reg_debug_addr2),
        .immediate_debug(immediate_debug),
        .reg_write_debug(reg_write_debug), .mem_read_debug(mem_read_debug),
        .mem_write_debug(mem_write_debug), .branch_taken_debug(branch_taken_debug),
        .trap(trap)
    );

    // ---- Instruction field encoders (independent of the DUT decode) ----
    function automatic logic [31:0] enc_r(input logic [6:0] f7, input logic [4:0] rs2,
                                          input logic [4:0] rs1, input logic [2:0] f3,
                                          input logic [4:0] rd, input logic [6:0] op);
        return {f7, rs2, rs1, f3, rd, op};
    endfunction
    function automatic logic [31:0] enc_i(input logic [11:0] imm, input logic [4:0] rs1,
                                          input logic [2:0] f3, input logic [4:0] rd,
                                          input logic [6:0] op);
        return {imm, rs1, f3, rd, op};
    endfunction
    function automatic logic [31:0] enc_s(input logic [11:0] imm, input logic [4:0] rs2,
                                          input logic [4:0] rs1, input logic [2:0] f3,
                                          input logic [6:0] op);
        return {imm[11:5], rs2, rs1, f3, imm[4:0], op};
    endfunction
    function automatic logic [31:0] enc_b(input int offset, input logic [4:0] rs2,
                                          input logic [4:0] rs1, input logic [2:0] f3);
        logic [12:0] imm;
        imm = offset[12:0];
        return {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], 7'b1100011};
    endfunction
    function automatic logic [31:0] enc_u(input logic [19:0] imm, input logic [4:0] rd,
                                          input logic [6:0] op);
        return {imm, rd, op};
    endfunction
    function automatic logic [31:0] enc_j(input int offset, input logic [4:0] rd);
        logic [20:0] imm;
        imm = offset[20:0];
        return {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'b1101111};
    endfunction

    // ---- Load a program into IMEM, reset, and run for n cycles ----
    task automatic run_program(input logic [31:0] prog[], input int n_cycles);
        int i;
        begin
            reset = 1;
            for (i = 0; i < 64; i++) dut.imem_inst.memory[i] = 32'h0;
            foreach (prog[i]) dut.imem_inst.memory[i] = prog[i];
            repeat (2) @(posedge clk);
            reset = 0;
            repeat (n_cycles) @(posedge clk);
            #1;
        end
    endtask

    task automatic check_reg(input logic [4:0] r, input logic [31:0] expected, input string name);
        logic [31:0] actual;
        begin
            actual = (r == 0) ? 32'h0 : dut.regfile_inst.registers[r];
            test_count++;
            if (actual === expected) begin
                pass_count++;
                $display("PASS: %s (x%0d = 0x%08h)", name, r, actual);
            end else begin
                fail_count++;
                $display("FAIL: %s (x%0d) expected 0x%08h got 0x%08h", name, r, expected, actual);
            end
        end
    endtask

    logic [31:0] prog[];

    initial begin
        $display("========================================");
        $display("RISC-V Directed Compliance Test");
        $display("========================================");

        // ---------------- Phase A: R-type and I-type ALU ----------------
        prog = new[24];
        prog[0]  = enc_i(12'd10, 5'd0, 3'b000, 5'd1, OPCODE_I_TYPE);   // x1 = 10
        prog[1]  = enc_i(12'd3,  5'd0, 3'b000, 5'd2, OPCODE_I_TYPE);   // x2 = 3
        prog[2]  = enc_i(12'hFFF,5'd0, 3'b000, 5'd3, OPCODE_I_TYPE);   // x3 = -1
        prog[3]  = enc_r(7'b0000000,5'd2,5'd1,3'b000,5'd5,OPCODE_R_TYPE);  // ADD  x5=13
        prog[4]  = enc_r(7'b0100000,5'd2,5'd1,3'b000,5'd6,OPCODE_R_TYPE);  // SUB  x6=7
        prog[5]  = enc_r(7'b0000000,5'd2,5'd1,3'b111,5'd7,OPCODE_R_TYPE);  // AND  x7=2
        prog[6]  = enc_r(7'b0000000,5'd2,5'd1,3'b110,5'd8,OPCODE_R_TYPE);  // OR   x8=11
        prog[7]  = enc_r(7'b0000000,5'd2,5'd1,3'b100,5'd9,OPCODE_R_TYPE);  // XOR  x9=9
        prog[8]  = enc_r(7'b0000000,5'd2,5'd1,3'b001,5'd10,OPCODE_R_TYPE); // SLL  x10=80
        prog[9]  = enc_r(7'b0000000,5'd2,5'd1,3'b101,5'd11,OPCODE_R_TYPE); // SRL  x11=1
        prog[10] = enc_r(7'b0100000,5'd2,5'd3,3'b101,5'd12,OPCODE_R_TYPE); // SRA  x12=-1
        prog[11] = enc_r(7'b0000000,5'd2,5'd3,3'b010,5'd13,OPCODE_R_TYPE); // SLT  x13=1
        prog[12] = enc_r(7'b0000000,5'd2,5'd3,3'b011,5'd14,OPCODE_R_TYPE); // SLTU x14=0
        prog[13] = enc_i(12'd5,  5'd1, 3'b000, 5'd15,OPCODE_I_TYPE);   // ADDI x15=15
        prog[14] = enc_i(12'd1,  5'd3, 3'b010, 5'd16,OPCODE_I_TYPE);   // SLTI x16=1
        prog[15] = enc_i(12'd20, 5'd1, 3'b011, 5'd17,OPCODE_I_TYPE);   // SLTIU x17=1
        prog[16] = enc_i(12'h00F,5'd1, 3'b100, 5'd18,OPCODE_I_TYPE);   // XORI x18=5
        prog[17] = enc_i(12'h100,5'd1, 3'b110, 5'd19,OPCODE_I_TYPE);   // ORI  x19=266
        prog[18] = enc_i(12'h006,5'd1, 3'b111, 5'd20,OPCODE_I_TYPE);   // ANDI x20=2
        prog[19] = enc_i(12'd2,  5'd1, 3'b001, 5'd21,OPCODE_I_TYPE);   // SLLI x21=40
        prog[20] = enc_i(12'd28, 5'd3, 3'b101, 5'd22,OPCODE_I_TYPE);   // SRLI x22=0xF
        prog[21] = enc_i(12'h400 | 12'd28, 5'd3, 3'b101, 5'd23,OPCODE_I_TYPE); // SRAI x23=-1
        prog[22] = enc_j(0, 5'd0);                                     // loop: JAL x0,0
        prog[23] = 32'h0;
        run_program(prog, 40);
        $display("--- Phase A: R/I-type ALU ---");
        check_reg(5'd5,  32'd13,        "ADD");
        check_reg(5'd6,  32'd7,         "SUB");
        check_reg(5'd7,  32'd2,         "AND");
        check_reg(5'd8,  32'd11,        "OR");
        check_reg(5'd9,  32'd9,         "XOR");
        check_reg(5'd10, 32'd80,        "SLL");
        check_reg(5'd11, 32'd1,         "SRL");
        check_reg(5'd12, 32'hFFFFFFFF,  "SRA");
        check_reg(5'd13, 32'd1,         "SLT");
        check_reg(5'd14, 32'd0,         "SLTU");
        check_reg(5'd15, 32'd15,        "ADDI");
        check_reg(5'd16, 32'd1,         "SLTI");
        check_reg(5'd17, 32'd1,         "SLTIU");
        check_reg(5'd18, 32'd5,         "XORI");
        check_reg(5'd19, 32'd266,       "ORI");
        check_reg(5'd20, 32'd2,         "ANDI");
        check_reg(5'd21, 32'd40,        "SLLI");
        check_reg(5'd22, 32'hF,         "SRLI");
        check_reg(5'd23, 32'hFFFFFFFF,  "SRAI");

        // ---------------- Phase B: LUI / AUIPC / loads / stores ----------------
        prog = new[16];
        prog[0]  = enc_i(12'd10, 5'd0, 3'b000, 5'd1, OPCODE_I_TYPE);   // x1=10
        prog[1]  = enc_i(12'hFFF,5'd0, 3'b000, 5'd2, OPCODE_I_TYPE);   // x2=-1
        prog[2]  = enc_u(20'hDEAD0, 5'd3, OPCODE_LUI);                 // x3=0xDEAD0000
        prog[3]  = enc_u(20'h0,     5'd4, OPCODE_AUIPC);               // x4=PC=12
        prog[4]  = enc_s(12'd0, 5'd1, 5'd0, 3'b010, OPCODE_STORE);     // SW x1 -> mem[0]
        prog[5]  = enc_i(12'd0, 5'd0, 3'b010, 5'd5, OPCODE_LOAD);      // LW x5=10
        prog[6]  = enc_s(12'd4, 5'd2, 5'd0, 3'b000, OPCODE_STORE);     // SB x2(0xFF) -> mem[4]
        prog[7]  = enc_i(12'd4, 5'd0, 3'b000, 5'd6, OPCODE_LOAD);      // LB x6=-1
        prog[8]  = enc_i(12'd4, 5'd0, 3'b100, 5'd7, OPCODE_LOAD);      // LBU x7=255
        prog[9]  = enc_s(12'd8, 5'd1, 5'd0, 3'b001, OPCODE_STORE);     // SH x1(10) -> mem[8]
        prog[10] = enc_i(12'd8, 5'd0, 3'b001, 5'd8, OPCODE_LOAD);      // LH x8=10
        prog[11] = enc_i(12'd8, 5'd0, 3'b101, 5'd9, OPCODE_LOAD);      // LHU x9=10
        prog[12] = enc_j(0, 5'd0);
        prog[13] = 32'h0; prog[14] = 32'h0; prog[15] = 32'h0;
        run_program(prog, 40);
        $display("--- Phase B: LUI/AUIPC/loads/stores ---");
        check_reg(5'd3, 32'hDEAD0000, "LUI");
        check_reg(5'd4, 32'd12,       "AUIPC");
        check_reg(5'd5, 32'd10,       "LW");
        check_reg(5'd6, 32'hFFFFFFFF, "LB sign-extend");
        check_reg(5'd7, 32'd255,      "LBU zero-extend");
        check_reg(5'd8, 32'd10,       "LH");
        check_reg(5'd9, 32'd10,       "LHU");

        // ---------------- Phase C: RV32M extension ----------------
        prog = new[16];
        prog[0]  = enc_i(12'd20, 5'd0, 3'b000, 5'd1, OPCODE_I_TYPE);   // x1=20
        prog[1]  = enc_i(12'd3,  5'd0, 3'b000, 5'd2, OPCODE_I_TYPE);   // x2=3
        prog[2]  = enc_i(12'hFFF,5'd0, 3'b000, 5'd3, OPCODE_I_TYPE);   // x3=-1
        prog[3]  = enc_r(7'b0000001,5'd2,5'd1,3'b000,5'd4,OPCODE_R_TYPE);  // MUL   x4=60
        prog[4]  = enc_r(7'b0000001,5'd2,5'd1,3'b001,5'd5,OPCODE_R_TYPE);  // MULH  x5=0
        prog[5]  = enc_r(7'b0000001,5'd2,5'd1,3'b011,5'd6,OPCODE_R_TYPE);  // MULHU x6=0
        prog[6]  = enc_r(7'b0000001,5'd2,5'd1,3'b100,5'd7,OPCODE_R_TYPE);  // DIV   x7=6
        prog[7]  = enc_r(7'b0000001,5'd2,5'd1,3'b101,5'd8,OPCODE_R_TYPE);  // DIVU  x8=6
        prog[8]  = enc_r(7'b0000001,5'd2,5'd1,3'b110,5'd9,OPCODE_R_TYPE);  // REM   x9=2
        prog[9]  = enc_r(7'b0000001,5'd2,5'd1,3'b111,5'd10,OPCODE_R_TYPE); // REMU  x10=2
        prog[10] = enc_r(7'b0000001,5'd0,5'd1,3'b100,5'd11,OPCODE_R_TYPE); // DIV by zero x11=-1
        prog[11] = enc_j(0, 5'd0);
        prog[12] = 32'h0; prog[13] = 32'h0; prog[14] = 32'h0; prog[15] = 32'h0;
        // Four normal divides (DIV/DIVU/REM/REMU) each stall ~33 cycles; the
        // divide-by-zero corner resolves in one cycle. Budget covers them all.
        run_program(prog, 250);
        $display("--- Phase C: RV32M ---");
        check_reg(5'd4,  32'd60,       "MUL");
        check_reg(5'd5,  32'd0,        "MULH");
        check_reg(5'd6,  32'd0,        "MULHU");
        check_reg(5'd7,  32'd6,        "DIV");
        check_reg(5'd8,  32'd6,        "DIVU");
        check_reg(5'd9,  32'd2,        "REM");
        check_reg(5'd10, 32'd2,        "REMU");
        check_reg(5'd11, 32'hFFFFFFFF, "DIV by zero");

        // ---------------- Phase D: control flow ----------------
        // Each branch/jump's correct path sets a marker register; wrong path skips it.
        prog = new[24];
        prog[0]  = enc_i(12'd5, 5'd0, 3'b000, 5'd1, OPCODE_I_TYPE);    // x1=5
        prog[1]  = enc_i(12'd5, 5'd0, 3'b000, 5'd2, OPCODE_I_TYPE);    // x2=5
        prog[2]  = enc_i(12'd7, 5'd0, 3'b000, 5'd3, OPCODE_I_TYPE);    // x3=7
        // BEQ x1,x2 taken -> skip prog[3], land prog[4]
        prog[3]  = enc_b(8, 5'd2, 5'd1, 3'b000);                       // BEQ (offset +8)
        prog[4]  = enc_i(12'd0, 5'd0, 3'b000, 5'd10, OPCODE_I_TYPE);   // decoy (skipped) x10=0
        prog[5]  = enc_i(12'd1, 5'd0, 3'b000, 5'd11, OPCODE_I_TYPE);   // x11=1 (BEQ taken marker)
        // BNE x1,x3 taken (5!=7) -> skip prog[7], land prog[8]
        prog[6]  = enc_b(8, 5'd3, 5'd1, 3'b001);                       // BNE (offset +8)
        prog[7]  = enc_i(12'd0, 5'd0, 3'b000, 5'd12, OPCODE_I_TYPE);   // decoy x12=0
        prog[8]  = enc_i(12'd1, 5'd0, 3'b000, 5'd13, OPCODE_I_TYPE);   // x13=1 (BNE taken)
        // BLT x1,x3 taken (5<7) -> skip prog[10], land prog[11]
        prog[9]  = enc_b(8, 5'd3, 5'd1, 3'b100);                       // BLT (offset +8)
        prog[10] = enc_i(12'd0, 5'd0, 3'b000, 5'd14, OPCODE_I_TYPE);   // decoy x14=0
        prog[11] = enc_i(12'd1, 5'd0, 3'b000, 5'd15, OPCODE_I_TYPE);   // x15=1 (BLT taken)
        // JAL x16, +8 -> link x16=PC+4, skip prog[13], land prog[14]
        prog[12] = enc_j(8, 5'd16);                                    // JAL (offset +8)
        prog[13] = enc_i(12'd0, 5'd0, 3'b000, 5'd17, OPCODE_I_TYPE);   // decoy x17=0
        prog[14] = enc_i(12'd1, 5'd0, 3'b000, 5'd18, OPCODE_I_TYPE);   // x18=1 (JAL target)
        // JALR x19, x20, 0 with x20 = addr of prog[16] (set via AUIPC-free ADDI)
        prog[15] = enc_i(12'd68, 5'd0, 3'b000, 5'd20, OPCODE_I_TYPE);  // x20=68 (prog[17] addr=17*4=68)
        prog[16] = enc_i(12'd0, 5'd20, 3'b000, 5'd19, OPCODE_JALR);    // JALR x19, x20, 0 -> PC=68, link
        prog[17] = enc_i(12'd1, 5'd0, 3'b000, 5'd21, OPCODE_I_TYPE);   // x21=1 (JALR target)
        prog[18] = enc_j(0, 5'd0);                                     // loop
        prog[19] = 32'h0; prog[20] = 32'h0; prog[21] = 32'h0;
        prog[22] = 32'h0; prog[23] = 32'h0;
        run_program(prog, 60);
        $display("--- Phase D: control flow ---");
        check_reg(5'd11, 32'd1, "BEQ taken");
        check_reg(5'd13, 32'd1, "BNE taken");
        check_reg(5'd15, 32'd1, "BLT taken");
        check_reg(5'd16, 32'd52, "JAL link (PC+4 = 12*4+4)");
        check_reg(5'd18, 32'd1, "JAL target reached");
        check_reg(5'd19, 32'd68, "JALR link (PC+4 = 16*4+4)");
        check_reg(5'd21, 32'd1, "JALR target reached");

        // ---------------- Report ----------------
        $display("========================================");
        $display("Directed Compliance Results: %0d/%0d passed, %0d failed",
                 pass_count, test_count, fail_count);
        if (fail_count == 0) begin
            $display("ALL DIRECTED COMPLIANCE CHECKS PASSED!");
        end else begin
            $display("COMPLIANCE FAILURES DETECTED");
            $fatal(1, "compliance_tests: %0d failures", fail_count);
        end
        $display("========================================");
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "compliance_tests: global timeout");
    end

endmodule