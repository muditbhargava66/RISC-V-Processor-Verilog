`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Register File Unit Test - Production Ready
// Comprehensive verification of register file functionality
//////////////////////////////////////////////////////////////////////////////////

module register_file_tb;

    // Test parameters
    localparam CLK_PERIOD = 10;
    localparam NUM_REGISTERS = 32;
    localparam NUM_RANDOM_TESTS = 500;
    
    // Test signals
    logic clk;
    logic reset;
    logic reg_write;
    logic [4:0] read_reg1;
    logic [4:0] read_reg2;
    logic [4:0] write_reg;
    logic [31:0] write_data;
    logic [31:0] read_data1;
    logic [31:0] read_data2;
    
    // Test control
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // Test data storage for verification
    logic [31:0] expected_registers [0:31];
    
    // DUT instantiation
    register_file dut (
        .clk(clk),
        .reset(reset),
        .reg_write(reg_write),
        .read_reg1(read_reg1),
        .read_reg2(read_reg2),
        .write_reg(write_reg),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test sequence
    initial begin
        $display("========================================");
        $display("Register File Unit Test - Production Verification");
        $display("========================================");
        
        // Initialize
        initialize_test();
        
        // Run directed tests
        run_directed_tests();
        
        // Run random tests
        run_random_tests();
        
        // Generate final report
        generate_test_report();
        
        $finish;
    end
    
    // Initialize test environment
    task initialize_test();
        $display("🔧 Initializing test environment...");
        
        // Initialize signals
        reset = 1;
        reg_write = 0;
        read_reg1 = 0;
        read_reg2 = 0;
        write_reg = 0;
        write_data = 0;
        
        // Initialize expected register values
        for (int i = 0; i < NUM_REGISTERS; i++) begin
            expected_registers[i] = 32'h00000000;
        end
        
        // Apply reset
        repeat(3) @(posedge clk);
        reset = 0;
        repeat(2) @(posedge clk);
        
        $display("✅ Test environment initialized");
        $display("");
    endtask
    
    // Directed test cases
    task run_directed_tests();
        $display("🧪 Running directed tests...");
        
        // Test reset functionality
        test_reset_functionality();
        
        // Test x0 register (always zero)
        test_x0_register();
        
        // Test basic read/write operations
        test_basic_read_write();
        
        // Test simultaneous read operations
        test_simultaneous_reads();
        
        // Test write-then-read operations
        test_write_then_read();
        
        // Test all registers
        test_all_registers();
        
        // Test edge cases
        test_edge_cases();
        
        $display("✅ Directed tests completed");
        $display("");
    endtask
    
    // Test reset functionality
    task test_reset_functionality();
        $display("  Testing reset functionality...");
        
        // Write some data to registers
        write_register(5'd5, 32'hDEADBEEF);
        write_register(5'd10, 32'hCAFEBABE);
        write_register(5'd15, 32'h12345678);
        
        // Apply reset
        @(posedge clk);
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        @(posedge clk);
        
        // Check that all registers are zero (except x0 which is always zero)
        for (int i = 1; i < NUM_REGISTERS; i++) begin
            read_register(i[4:0], 5'd0);
            check_read_result(32'h00000000, $sformatf("Reset check reg x%0d", i));
            expected_registers[i] = 32'h00000000;
        end
    endtask
    
    // Test x0 register (always zero)
    task test_x0_register();
        $display("  Testing x0 register (hardwired zero)...");
        
        // Try to write to x0
        write_register(5'd0, 32'hFFFFFFFF);
        
        // Read x0 - should always be zero
        read_register(5'd0, 5'd0);
        check_read_result(32'h00000000, "x0 register always zero");
        
        // Try different values
        write_register(5'd0, 32'hDEADBEEF);
        read_register(5'd0, 5'd0);
        check_read_result(32'h00000000, "x0 register write protection");
    endtask
    
    // Test basic read/write operations
    task test_basic_read_write();
        $display("  Testing basic read/write operations...");
        
        // Test writing and reading different values
        write_register(5'd1, 32'h12345678);
        read_register(5'd1, 5'd0);
        check_read_result(32'h12345678, "Basic write/read x1");
        
        write_register(5'd2, 32'hDEADBEEF);
        read_register(5'd2, 5'd0);
        check_read_result(32'hDEADBEEF, "Basic write/read x2");
        
        write_register(5'd31, 32'hCAFEBABE);
        read_register(5'd31, 5'd0);
        check_read_result(32'hCAFEBABE, "Basic write/read x31");
    endtask
    
    // Test simultaneous read operations
    task test_simultaneous_reads();
        $display("  Testing simultaneous read operations...");
        
        // Write test data
        write_register(5'd5, 32'h11111111);
        write_register(5'd10, 32'h22222222);
        write_register(5'd15, 32'h33333333);
        
        // Test reading two different registers simultaneously
        @(posedge clk);
        read_reg1 = 5'd5;
        read_reg2 = 5'd10;
        @(posedge clk);
        
        check_dual_read_result(32'h11111111, 32'h22222222, "Simultaneous read x5, x10");
        
        // Test reading same register on both ports
        @(posedge clk);
        read_reg1 = 5'd15;
        read_reg2 = 5'd15;
        @(posedge clk);
        
        check_dual_read_result(32'h33333333, 32'h33333333, "Simultaneous read x15, x15");
    endtask
    
    // Test write-then-read operations
    task test_write_then_read();
        $display("  Testing write-then-read operations...");
        
        // Test write followed immediately by read
        @(posedge clk);
        reg_write = 1;
        write_reg = 5'd7;
        write_data = 32'h87654321;
        read_reg1 = 5'd7;
        @(posedge clk);
        reg_write = 0;
        
        // Check if read reflects the written value
        check_read_result(32'h87654321, "Write-then-read x7");
        expected_registers[7] = 32'h87654321;
        
        // Test overwriting a register
        write_register(5'd7, 32'hFEDCBA98);
        read_register(5'd7, 5'd0);
        check_read_result(32'hFEDCBA98, "Overwrite x7");
    endtask
    
    // Test all registers
    task test_all_registers();
        $display("  Testing all registers...");
        
        // Write unique values to all registers (except x0)
        for (int i = 1; i < NUM_REGISTERS; i++) begin
            logic [31:0] test_value = 32'h10000000 + i;
            write_register(i[4:0], test_value);
        end
        
        // Read back all registers and verify
        for (int i = 1; i < NUM_REGISTERS; i++) begin
            logic [31:0] expected_value = 32'h10000000 + i;
            read_register(i[4:0], 5'd0);
            check_read_result(expected_value, $sformatf("All registers test x%0d", i));
        end
    endtask
    
    // Test edge cases
    task test_edge_cases();
        $display("  Testing edge cases...");
        
        // Test maximum and minimum values
        write_register(5'd20, 32'hFFFFFFFF);
        read_register(5'd20, 5'd0);
        check_read_result(32'hFFFFFFFF, "Maximum value");
        
        write_register(5'd21, 32'h00000000);
        read_register(5'd21, 5'd0);
        check_read_result(32'h00000000, "Minimum value");
        
        // Test alternating bit patterns
        write_register(5'd22, 32'hAAAAAAAA);
        read_register(5'd22, 5'd0);
        check_read_result(32'hAAAAAAAA, "Alternating pattern 1");
        
        write_register(5'd23, 32'h55555555);
        read_register(5'd23, 5'd0);
        check_read_result(32'h55555555, "Alternating pattern 2");
        
        // Test power-of-2 values
        for (int i = 0; i < 32; i++) begin
            logic [31:0] pow2_value = 32'h00000001 << i;
            write_register(5'd24, pow2_value);
            read_register(5'd24, 5'd0);
            check_read_result(pow2_value, $sformatf("Power of 2: 2^%0d", i));
        end
    endtask
    
    // Random test generation
    task run_random_tests();
        logic [4:0] rand_reg;
        logic [31:0] rand_data;
        
        $display("🎲 Running %0d random tests...", NUM_RANDOM_TESTS);
        
        for (int i = 0; i < NUM_RANDOM_TESTS; i++) begin
            // Generate random register and data
            rand_reg = $urandom_range(1, 31); // Skip x0
            rand_data = $random;
            
            // Write random data
            write_register(rand_reg, rand_data);
            
            // Read back and verify
            read_register(rand_reg, 5'd0);
            check_read_result(rand_data, $sformatf("Random test %0d (x%0d)", i+1, rand_reg));
        end
        
        $display("✅ Random tests completed");
        $display("");
    endtask
    
    // Helper task to write to a register
    task write_register(logic [4:0] reg_addr, logic [31:0] data);
        @(posedge clk);
        reg_write = 1;
        write_reg = reg_addr;
        write_data = data;
        @(posedge clk);
        reg_write = 0;
        
        // Update expected value (except for x0)
        if (reg_addr != 5'd0) begin
            expected_registers[reg_addr] = data;
        end
    endtask
    
    // Helper task to read from a register
    task read_register(logic [4:0] reg_addr1, logic [4:0] reg_addr2);
        @(posedge clk);
        read_reg1 = reg_addr1;
        read_reg2 = reg_addr2;
        @(posedge clk);
    endtask
    
    // Check single read result
    task check_read_result(logic [31:0] expected, string test_name);
        test_count++;
        
        if (read_data1 === expected) begin
            pass_count++;
            $display("    ✅ %s: PASS", test_name);
        end else begin
            fail_count++;
            $display("    ❌ %s: FAIL", test_name);
            $display("       Expected: 0x%08h, Got: 0x%08h", expected, read_data1);
        end
    endtask
    
    // Check dual read result
    task check_dual_read_result(logic [31:0] expected1, logic [31:0] expected2, string test_name);
        test_count++;
        
        if (read_data1 === expected1 && read_data2 === expected2) begin
            pass_count++;
            $display("    ✅ %s: PASS", test_name);
        end else begin
            fail_count++;
            $display("    ❌ %s: FAIL", test_name);
            $display("       Expected: 0x%08h, 0x%08h", expected1, expected2);
            $display("       Got: 0x%08h, 0x%08h", read_data1, read_data2);
        end
    endtask
    
    // Generate test report
    task generate_test_report();
        real success_rate;
        
        $display("========================================");
        $display("REGISTER FILE UNIT TEST REPORT");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (test_count > 0) begin
            success_rate = (real'(pass_count) / real'(test_count)) * 100.0;
            $display("Success Rate: %.2f%%", success_rate);
        end
        
        $display("");
        
        if (fail_count == 0) begin
            $display("🎉 ALL REGISTER FILE TESTS PASSED!");
            $display("✅ Register file is functioning correctly");
        end else begin
            $display("❌ %0d REGISTER FILE TESTS FAILED", fail_count);
            $display("🔧 Review failed tests and fix register file implementation");
        end
        
        $display("========================================");
    endtask
    
    // Coverage collection
    covergroup regfile_coverage @(posedge clk);
        write_enable: coverpoint reg_write {
            bins enabled = {1};
            bins disabled = {0};
        }
        
        write_register: coverpoint write_reg {
            bins x0 = {0};
            bins x1_to_x15 = {[1:15]};
            bins x16_to_x31 = {[16:31]};
        }
        
        read_register1: coverpoint read_reg1 {
            bins x0 = {0};
            bins x1_to_x15 = {[1:15]};
            bins x16_to_x31 = {[16:31]};
        }
        
        read_register2: coverpoint read_reg2 {
            bins x0 = {0};
            bins x1_to_x15 = {[1:15]};
            bins x16_to_x31 = {[16:31]};
        }
        
        write_data_patterns: coverpoint write_data {
            bins zero = {32'h00000000};
            bins all_ones = {32'hFFFFFFFF};
            bins alternating1 = {32'hAAAAAAAA};
            bins alternating2 = {32'h55555555};
            bins others = default;
        }
        
        cross write_enable, write_register;
        cross read_register1, read_register2;
    endgroup
    
    regfile_coverage regfile_cov = new();

endmodule