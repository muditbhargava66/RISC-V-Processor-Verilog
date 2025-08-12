`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Basic ALU Testbench - Simple verification
// Compatible with the existing test infrastructure
//////////////////////////////////////////////////////////////////////////////////

module alu_tb;

    // Test parameters
    parameter PERIOD = 10;
    
    // Test signals
    reg clk = 0;
    reg [31:0] operand1 = 0;
    reg [31:0] operand2 = 0;
    reg [3:0] alu_op = 0;
    wire [31:0] alu_result;
    
    // Expected result for verification
    reg [31:0] expected_result = 0;
    
    // Test control
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    // Clock generation
    always #(PERIOD/2) clk = ~clk;
    
    // ALU instantiation
    alu dut (
        .alu_op(alu_op),
        .operand1(operand1),
        .operand2(operand2),
        .alu_result(alu_result)
    );
    
    // Main test sequence
    initial begin
        $display("========================================");
        $display("Basic ALU Test - Simple Verification");
        $display("========================================");
        
        // Wait for initial settling
        #(PERIOD * 2);
        
        // Test all ALU operations with known values
        test_all_operations();
        
        // Test with random data if file exists
        test_with_file_data();
        
        // Generate final report
        generate_report();
        
        $finish;
    end
    
    // Test all ALU operations systematically
    task test_all_operations();
        $display("Testing all ALU operations...");
        
        // Test ADD (0000)
        test_operation(4'b0000, 32'd15, 32'd25, 32'd40, "ADD");
        test_operation(4'b0000, 32'hFFFFFFFF, 32'd1, 32'd0, "ADD overflow");
        
        // Test SUB (1000)
        test_operation(4'b1000, 32'd50, 32'd30, 32'd20, "SUB");
        test_operation(4'b1000, 32'd10, 32'd20, -32'd10, "SUB negative");
        
        // Test SLL (0001)
        test_operation(4'b0001, 32'd1, 32'd4, 32'd16, "SLL");
        test_operation(4'b0001, 32'h12345678, 32'd8, 32'h34567800, "SLL multi-bit");
        
        // Test SLT (0010)
        test_operation(4'b0010, 32'd10, 32'd20, 32'd1, "SLT true");
        test_operation(4'b0010, 32'd20, 32'd10, 32'd0, "SLT false");
        
        // Test SLTU (0011)
        test_operation(4'b0011, 32'd10, 32'd20, 32'd1, "SLTU true");
        test_operation(4'b0011, 32'hFFFFFFFF, 32'd1, 32'd0, "SLTU unsigned");
        
        // Test XOR (0100)
        test_operation(4'b0100, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, "XOR");
        test_operation(4'b0100, 32'h12345678, 32'h12345678, 32'd0, "XOR same");
        
        // Test SRL (0101)
        test_operation(4'b0101, 32'h80000000, 32'd4, 32'h08000000, "SRL");
        test_operation(4'b0101, 32'h12345678, 32'd8, 32'h00123456, "SRL multi-bit");
        
        // Test SRA (1101)
        test_operation(4'b1101, 32'h80000000, 32'd4, 32'hF8000000, "SRA negative");
        test_operation(4'b1101, 32'h12345678, 32'd8, 32'h00123456, "SRA positive");
        
        // Test OR (0110)
        test_operation(4'b0110, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, "OR");
        test_operation(4'b0110, 32'd0, 32'h12345678, 32'h12345678, "OR with zero");
        
        // Test AND (0111)
        test_operation(4'b0111, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'd0, "AND");
        test_operation(4'b0111, 32'hFFFFFFFF, 32'h12345678, 32'h12345678, "AND with all 1s");
        
        $display("Systematic testing completed.");
    endtask
    
    // Test with file data (if available)
    task test_with_file_data();
        integer file_pointer;
        reg [31:0] file_data0, file_data1;
        integer file_tests = 0;
        
        $display("Testing with file data...");
        
        file_pointer = $fopen("random_dataset.txt", "r");
        if (file_pointer == 0) begin
            $display("No random_dataset.txt file found, skipping file tests.");
            return;
        end
        
        // Test each operation with file data
        for (alu_op = 4'b0000; alu_op <= 4'b0111; alu_op = alu_op + 1) begin
            if (alu_op == 4'b1000 || alu_op == 4'b1101) continue; // Skip invalid codes in loop
            
            $fseek(file_pointer, 0, 0); // Reset file pointer
            
            while (!$feof(file_pointer) && file_tests < 50) begin
                if ($fscanf(file_pointer, "%h", file_data0) != 1) break;
                if ($fscanf(file_pointer, "%h", file_data1) != 1) break;
                
                operand1 = file_data0;
                operand2 = file_data1;
                
                // Calculate expected result
                calculate_expected_result();
                
                // Apply inputs and wait
                #1;
                
                // Check result
                if (alu_result !== expected_result) begin
                    $display("❌ File test failed: op=%b, A=%h, B=%h, Expected=%h, Got=%h", 
                             alu_op, operand1, operand2, expected_result, alu_result);
                    fail_count = fail_count + 1;
                end else begin
                    pass_count = pass_count + 1;
                end
                test_count = test_count + 1;
                file_tests = file_tests + 1;
            end
        end
        
        // Test SUB operation separately
        alu_op = 4'b1000;
        $fseek(file_pointer, 0, 0);
        file_tests = 0;
        while (!$feof(file_pointer) && file_tests < 10) begin
            if ($fscanf(file_pointer, "%h", file_data0) != 1) break;
            if ($fscanf(file_pointer, "%h", file_data1) != 1) break;
            
            operand1 = file_data0;
            operand2 = file_data1;
            calculate_expected_result();
            #1;
            
            if (alu_result !== expected_result) begin
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
            test_count = test_count + 1;
            file_tests = file_tests + 1;
        end
        
        // Test SRA operation separately  
        alu_op = 4'b1101;
        $fseek(file_pointer, 0, 0);
        file_tests = 0;
        while (!$feof(file_pointer) && file_tests < 10) begin
            if ($fscanf(file_pointer, "%h", file_data0) != 1) break;
            if ($fscanf(file_pointer, "%h", file_data1) != 1) break;
            
            operand1 = file_data0;
            operand2 = file_data1;
            calculate_expected_result();
            #1;
            
            if (alu_result !== expected_result) begin
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
            test_count = test_count + 1;
            file_tests = file_tests + 1;
        end
        
        $fclose(file_pointer);
        $display("File testing completed.");
    endtask
    
    // Test a single operation
    task test_operation(input [3:0] op, input [31:0] a, input [31:0] b, input [31:0] expected, input [8*20:1] name);
        test_count = test_count + 1;
        
        alu_op = op;
        operand1 = a;
        operand2 = b;
        expected_result = expected;
        
        #1; // Wait for combinational delay
        
        if (alu_result === expected_result) begin
            $display("✅ %s: PASS", name);
            pass_count = pass_count + 1;
        end else begin
            $display("❌ %s: FAIL - Expected: %h, Got: %h", name, expected_result, alu_result);
            fail_count = fail_count + 1;
        end
    endtask
    
    // Calculate expected result based on operation
    task calculate_expected_result();
        case (alu_op)
            4'b0000: expected_result = operand1 + operand2;                    // ADD
            4'b1000: expected_result = operand1 - operand2;                    // SUB
            4'b0001: expected_result = operand1 << operand2[4:0];              // SLL
            4'b0010: expected_result = ($signed(operand1) < $signed(operand2)) ? 32'd1 : 32'd0; // SLT
            4'b0011: expected_result = (operand1 < operand2) ? 32'd1 : 32'd0;  // SLTU
            4'b0100: expected_result = operand1 ^ operand2;                    // XOR
            4'b0101: expected_result = operand1 >> operand2[4:0];              // SRL
            4'b1101: expected_result = $signed(operand1) >>> operand2[4:0];    // SRA
            4'b0110: expected_result = operand1 | operand2;                    // OR
            4'b0111: expected_result = operand1 & operand2;                    // AND
            default: expected_result = 32'd0;
        endcase
    endtask
    
    // Generate final test report
    task generate_report();
        real success_rate;
        
        $display("");
        $display("========================================");
        $display("BASIC ALU TEST REPORT");
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
            $display("🎉 ALL BASIC ALU TESTS PASSED!");
            $display("✅ ALU basic functionality verified");
        end else begin
            $display("❌ %0d BASIC ALU TESTS FAILED", fail_count);
            $display("🔧 Review failed tests and fix ALU implementation");
        end
        
        $display("========================================");
    endtask

endmodule