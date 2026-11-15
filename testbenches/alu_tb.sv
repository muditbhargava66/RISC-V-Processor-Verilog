// ALU Testbench
// Comprehensive test for all RV32I ALU operations and the RV32M multiply ops.
// Divide/remainder are tested separately in divider_tb.sv. Self-checking with $fatal.

`timescale 1ns / 1ps

module alu_tb;

    import riscv_pkg::*;

    logic [31:0] operand_a;
    logic [31:0] operand_b;
    logic [4:0]  alu_control;
    logic [31:0] result;
    logic        zero;

    int test_count = 0;
    int pass_count = 0;

    alu dut (
        .operand_a   (operand_a),
        .operand_b   (operand_b),
        .alu_control (alu_control),
        .result      (result),
        .zero        (zero)
    );

    task automatic test_alu_operation(
        input logic [4:0]  op,
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [31:0] expected,
        input string       op_name
    );
    begin
        operand_a = a;
        operand_b = b;
        alu_control = op;
        #10;
        test_count = test_count + 1;
        if (result === expected) begin
            pass_count = pass_count + 1;
            $display("PASS: %s | A=%08h B=%08h Result=%08h", op_name, a, b, result);
        end else begin
            $display("FAIL: %s | A=%08h B=%08h Expected=%08h Got=%08h",
                    op_name, a, b, expected, result);
        end
    end
    endtask

    initial begin
        $display("========================================");
        $display("ALU Comprehensive Test (RV32I + RV32M)");
        $display("========================================");

        // Base RV32I operations
        test_alu_operation(ALU_ADD, 32'h00000005, 32'h00000003, 32'h00000008, "ADD");
        test_alu_operation(ALU_ADD, 32'hFFFFFFFF, 32'h00000001, 32'h00000000, "ADD wrap");
        test_alu_operation(ALU_SUB, 32'h00000005, 32'h00000003, 32'h00000002, "SUB");
        test_alu_operation(ALU_SUB, 32'h00000000, 32'h00000001, 32'hFFFFFFFF, "SUB borrow");
        test_alu_operation(ALU_AND, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'h00000000, "AND");
        test_alu_operation(ALU_OR,  32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, "OR");
        test_alu_operation(ALU_XOR, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, "XOR");
        test_alu_operation(ALU_SLL, 32'h00000001, 32'h00000004, 32'h00000010, "SLL");
        test_alu_operation(ALU_SRL, 32'h80000000, 32'h00000004, 32'h08000000, "SRL");
        test_alu_operation(ALU_SRA, 32'h80000000, 32'h00000004, 32'hF8000000, "SRA");
        test_alu_operation(ALU_SLT, 32'hFFFFFFFF, 32'h00000001, 32'h00000001, "SLT signed");
        test_alu_operation(ALU_SLT, 32'h00000001, 32'hFFFFFFFF, 32'h00000000, "SLT signed 2");
        test_alu_operation(ALU_SLTU,32'hFFFFFFFF, 32'h00000001, 32'h00000000, "SLTU unsigned");
        test_alu_operation(ALU_SLTU,32'h00000001, 32'hFFFFFFFF, 32'h00000001, "SLTU unsigned 2");

        // M-extension: multiply
        test_alu_operation(ALU_MUL,   32'h00000007, 32'h00000006, 32'h0000002A, "MUL");
        test_alu_operation(ALU_MUL,   32'hFFFFFFFD, 32'h00000005, 32'hFFFFFFF1, "MUL neg (-3*5)");
        test_alu_operation(ALU_MULH,  32'h80000000, 32'h80000000, 32'h40000000, "MULH (-2^31)^2");
        test_alu_operation(ALU_MULH,  32'hFFFFFFFF, 32'hFFFFFFFF, 32'h00000000, "MULH (-1*-1)");
        test_alu_operation(ALU_MULHSU,32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF, "MULHSU (-1 * maxU)");
        test_alu_operation(ALU_MULHSU,32'h80000000, 32'h80000000, 32'hC0000000, "MULHSU (-2^31 * 2^31)");
        test_alu_operation(ALU_MULHU, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFE, "MULHU maxU*maxU");

        // M-extension: divide / remainder are computed by the sequential divider
        // (divider.sv), not the combinational ALU. Those vectors live in
        // divider_tb.sv; the ALU intentionally returns 0 for the divide codes.

        $display("========================================");
        $display("ALU Test Results: %0d/%0d tests passed", pass_count, test_count);
        if (pass_count == test_count) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
            $fatal(1, "ALU testbench: %0d failures", test_count - pass_count);
        end
        $display("========================================");
        $finish;
    end

endmodule