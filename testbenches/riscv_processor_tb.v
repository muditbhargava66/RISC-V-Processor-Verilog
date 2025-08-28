// RISC-V Processor Self-Checking Testbench
`timescale 1ns / 1ps

module riscv_processor_tb;

    // Clock and reset
    reg clk;
    reg reset;

    // Instantiate the DUT
    riscv_processor dut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation - 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

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
        integer errors = 0;
        
        // Check final register values
        // To access internal signals, we use hierarchical names.
        // This requires the simulator to have appropriate permissions.
        check_register(1, 32'hDEAD0234, "LUI + ADDI", errors);
        check_register(2, 32'hDEAD0234, "SW + LW", errors);
        check_register(3, 32'hFFFFFFFF, "ADDI negative", errors);
        check_register(4, 32'd1, "ADDI positive", errors);
        check_register(5, 32'd2, "Branch Taken (BLT)", errors);
        check_register(6, 32'd2, "Branch Not Taken (BGE)", errors);

        $display("----------------------------------------");

        // 4. Report final status
        if (errors == 0) begin
            $display("✅ ✅ ✅ ALL TESTS PASSED! ✅ ✅ ✅");
            $display("The RISC-V processor is behaving as expected.");
        end else begin
            $display("❌ ❌ ❌ %0d TESTS FAILED! ❌ ❌ ❌", errors);
            $display("The RISC-V processor has bugs to fix.");
        end

        $display("========================================");
        $finish;
    end

    // Task to check a register's value
    task check_register;
        input [4:0] reg_num;
        input [31:0] expected_value;
        input [79:0] test_name;
        inout integer error_count;
        
        reg [31:0] actual_value;
    begin
        // Access the register file memory directly
        actual_value = dut.regfile_inst.memory[reg_num];
        
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

endmodule