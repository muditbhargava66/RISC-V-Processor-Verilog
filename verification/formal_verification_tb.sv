// Formal / Assertion Verification Testbench (xsim)
// Runs the canonical program with the core's inline SystemVerilog Assertions
// active. xsim evaluates the concurrent assert properties; any violation is
// reported. This testbench also checks the architectural result and that no
// trap is raised while executing valid instructions. Self-checking with $fatal.
//
// NOTE: This is assertion-based simulation, not an unbounded formal proof.
// For SymbiYosys proofs see verification/formal*.sby (requires oss-cad-suite).

`timescale 1ns / 1ps

module formal_verification_tb;

    logic clk;
    logic reset;
    int errors;
    logic checks_done = 1'b0;
    logic trap_seen = 1'b0;

    logic [31:0] pc_debug, instruction_debug, alu_result_debug;
    logic [31:0] reg_debug_data1, reg_debug_data2, mem_debug_data, immediate_debug;
    logic [4:0]  reg_debug_addr1, reg_debug_addr2;
    logic        reg_write_debug, mem_read_debug, mem_write_debug, branch_taken_debug, trap;

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

    // Flag any trap raised during the valid program region (first 12 instructions)
    always @(posedge clk) begin
        if (!reset && trap && pc_debug < 32'd48) trap_seen <= 1'b1;
    end

    task automatic check_register(input logic [4:0] r, input logic [31:0] expected, input string name);
        logic [31:0] actual;
        begin
            actual = (r == 0) ? 32'h0 : dut.regfile_inst.registers[r];
            if (actual === expected) begin
                $display("PASS: %s (x%0d = 0x%08h)", name, r, actual);
            end else begin
                $display("FAIL: %s (x%0d) expected 0x%08h got 0x%08h", name, r, expected, actual);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $display("========================================");
        $display("Assertion / Formal Simulation Test");
        $display("========================================");
        reset = 1;
        errors = 0;
        #20;
        reset = 0;
        #200;

        check_register(5'd1, 32'hDEAD0234, "LUI + ADDI");
        check_register(5'd2, 32'hDEAD0234, "SW + LW");
        check_register(5'd3, 32'hFFFFFFFF, "ADDI negative");
        check_register(5'd4, 32'd1,        "ADDI positive");
        check_register(5'd5, 32'd2,        "BLT taken");
        check_register(5'd6, 32'd2,        "BGE not taken");

        if (trap_seen) begin
            $display("FAIL: trap asserted during valid program region");
            errors = errors + 1;
        end else begin
            $display("PASS: no trap during valid program region");
        end

        checks_done = 1'b1;
        $display("========================================");
        if (errors == 0) begin
            $display("ALL ASSERTION CHECKS PASSED!");
        end else begin
            $display("%0d CHECKS FAILED!", errors);
            $fatal(1, "formal_verification_tb: %0d failures", errors);
        end
        $display("========================================");
        $finish;
    end

    initial begin
        #1000;
        if (!checks_done) $fatal(1, "formal_verification_tb: timeout");
        $finish;
    end

endmodule