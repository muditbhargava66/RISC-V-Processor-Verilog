// RISC-V Processor Self-Checking Testbench
// SystemVerilog implementation with class-based verification

`timescale 1ns / 1ps

module riscv_processor_tb;

    // Clock and reset
    logic clk;
    logic reset;
    int errors;

    // Instantiate the DUT — all debug ports explicitly unconnected
    riscv_processor dut (
        .clk(clk),
        .reset(reset),
        .pc_debug(),
        .instruction_debug(),
        .alu_result_debug(),
        .reg_debug_data1(),
        .reg_debug_data2(),
        .mem_debug_data(),
        .reg_debug_addr1(),
        .reg_debug_addr2(),
        .immediate_debug(),
        .reg_write_debug(),
        .mem_read_debug(),
        .mem_write_debug(),
        .branch_taken_debug()
    );

    // Clock generation - 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Timeout watchdog
    initial begin
        #1000; // 1us timeout - should be plenty for ~20 cycles
        $display("ERROR: Testbench timeout reached!");
        $finish;
    end

    // Task to check a register's value
    task automatic check_register(
        input logic [4:0] reg_num,
        input logic [31:0] expected_value,
        input string test_name,
        inout int error_count
    );
        logic [31:0] actual_value;
    begin
        // Access the register file memory directly
        actual_value = (reg_num == 5'b0) ? 32'h0 : dut.regfile_inst.registers[reg_num];

        if (actual_value === expected_value) begin
            $display("PASS: %s (x%0d = 0x%08h)", test_name, reg_num, actual_value);
        end else begin
            $display("FAIL: %s (x%0d)", test_name, reg_num);
            $display("      Expected: 0x%08h", expected_value);
            $display("      Actual:   0x%08h", actual_value);
            error_count = error_count + 1;
        end
    end
    endtask

    // Test sequence
    initial begin
        $display("========================================");
        $display("RISC-V Processor Self-Checking Test");
        $display("========================================");

        // 1. Reset the processor
        reset = 1;
        #20;
        reset = 0;
        #1;

        $display("Processor reset. Starting execution from memory.");

        // 2. Let the simulation run for enough cycles to complete the program
        // The test program has about 11 instructions. Let's run for 20 cycles.
        #200;

        $display("Program execution finished. Verifying results...");
        $display("----------------------------------------");

        // 3. Verification phase
        errors = 0;

        // Check final register values
        check_register(1, 32'hDEAD0234, "LUI + ADDI", errors);
        check_register(2, 32'hDEAD0234, "SW + LW", errors);
        check_register(3, 32'hFFFFFFFF, "ADDI negative", errors);
        check_register(4, 32'd1, "ADDI positive", errors);
        check_register(5, 32'd2, "Branch Taken (BLT)", errors);
        check_register(6, 32'd2, "Branch Not Taken (BGE)", errors);

        $display("----------------------------------------");

        // 4. Report final status
        if (errors == 0) begin
            $display("ALL TESTS PASSED!");
            $display("The RISC-V processor is behaving as expected.");
        end else begin
            $display("%0d TESTS FAILED!", errors);
            $display("The RISC-V processor has bugs to fix.");
        end

        $display("========================================");
        $finish;
    end

endmodule