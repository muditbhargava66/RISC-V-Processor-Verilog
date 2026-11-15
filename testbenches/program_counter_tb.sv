// Program Counter Testbench
// Verifies synchronous reset to zero and PC update on each clock edge.
// Self-checking with $fatal on failure.

`timescale 1ns / 1ps

module program_counter_tb;

    logic        clk;
    logic        reset;
    logic        hold;
    logic [31:0] pc_next;
    logic [31:0] pc_current;

    int test_count = 0;
    int pass_count = 0;

    program_counter dut (
        .clk        (clk),
        .reset      (reset),
        .hold       (hold),
        .pc_next    (pc_next),
        .pc_current (pc_current)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task automatic check_pc(input logic [31:0] expected, input string name);
    begin
        #1;
        test_count++;
        if (pc_current === expected) begin
            pass_count++;
            $display("PASS: %s | pc=%08h", name, pc_current);
        end else begin
            $display("FAIL: %s | expected=%08h got=%08h", name, expected, pc_current);
        end
    end
    endtask

    initial begin
        $display("========================================");
        $display("Program Counter Test");
        $display("========================================");

        reset = 1;
        hold  = 0;
        pc_next = 32'h00000100;
        @(posedge clk);
        check_pc(32'h00000000, "Reset clears PC");

        reset = 0;
        pc_next = 32'h00000100;
        @(posedge clk);
        check_pc(32'h00000100, "PC loads pc_next");

        pc_next = 32'h00000104;
        @(posedge clk);
        check_pc(32'h00000104, "PC increments");

        pc_next = 32'hFFFF_FFFC;
        @(posedge clk);
        check_pc(32'hFFFFFFFC, "PC near top of range");

        // Hold (stall): PC must freeze even though pc_next changes.
        hold = 1;
        pc_next = 32'h00000200;
        @(posedge clk);
        check_pc(32'hFFFFFFFC, "Hold freezes PC");
        pc_next = 32'h00000204;
        @(posedge clk);
        check_pc(32'hFFFFFFFC, "Hold freezes PC across cycles");

        // Release hold: PC resumes loading pc_next.
        hold = 0;
        pc_next = 32'h00000208;
        @(posedge clk);
        check_pc(32'h00000208, "Release hold resumes PC");

        reset = 1;
        @(posedge clk);
        check_pc(32'h00000000, "Reset re-asserted clears PC");

        $display("========================================");
        $display("Program Counter Results: %0d/%0d passed", pass_count, test_count);
        if (pass_count == test_count) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
            $fatal(1, "program_counter_tb: %0d failures", test_count - pass_count);
        end
        $display("========================================");
        $finish;
    end

endmodule