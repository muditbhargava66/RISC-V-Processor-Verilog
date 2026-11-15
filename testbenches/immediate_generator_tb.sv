// Immediate Generator Testbench
// Verifies sign/zero-extension and field extraction for I/S/B/U/J formats.
// Self-checking with $fatal on failure.

`timescale 1ns / 1ps

module immediate_generator_tb;

    import riscv_pkg::*;

    logic [31:0] instruction;
    logic [31:0] immediate;

    int test_count = 0;
    int pass_count = 0;

    immediate_generator dut (
        .instruction (instruction),
        .immediate   (immediate)
    );

    task automatic check_imm(input logic [31:0] inst, input logic [31:0] expected, input string name);
    begin
        instruction = inst;
        #10;
        test_count++;
        if (immediate === expected) begin
            pass_count++;
            $display("PASS: %s | inst=%08h imm=%08h", name, inst, immediate);
        end else begin
            $display("FAIL: %s | inst=%08h expected=%08h got=%08h", name, inst, expected, immediate);
        end
    end
    endtask

    initial begin
        $display("========================================");
        $display("Immediate Generator Test");
        $display("========================================");

        // I-type
        check_imm(32'h00A00093, 32'h0000000A, "I-type ADDI +10");
        check_imm(32'hFFF00093, 32'hFFFFFFFF, "I-type ADDI -1 (sign-extend)");
        // S-type: SW x1, -4(x0)
        check_imm(32'hFE102E23, 32'hFFFFFFFC, "S-type store -4");
        // B-type: BEQ x0,x0,-8
        check_imm(32'hFE000CE3, 32'hFFFFFFF8, "B-type branch -8");
        // U-type
        check_imm(32'hDEAD00B7, 32'hDEAD0000, "U-type LUI");
        check_imm(32'h00000017, 32'h00000000, "U-type AUIPC 0");
        // J-type: JAL x0,-4
        check_imm(32'hFFDFF06F, 32'hFFFFFFFC, "J-type JAL -4");
        check_imm(32'h008000EF, 32'h00000008, "J-type JAL +8");

        $display("========================================");
        $display("Immediate Generator Results: %0d/%0d passed", pass_count, test_count);
        if (pass_count == test_count) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
            $fatal(1, "immediate_generator_tb: %0d failures", test_count - pass_count);
        end
        $display("========================================");
        $finish;
    end

endmodule