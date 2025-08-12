`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// ALU Unit Test - Production Ready
// Comprehensive verification of ALU functionality
//////////////////////////////////////////////////////////////////////////////////

module alu_tb;

    // Test parameters
    localparam CLK_PERIOD = 10;
    localparam NUM_RANDOM_TESTS = 1000;
    
    // ALU operation codes
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0000,
        ALU_SUB  = 4'b1000,
        ALU_SLL  = 4'b0001,
        ALU_SLT  = 4'b0010,
        ALU_SLTU = 4'b0011,
        ALU_XOR  = 4'b0100,
        ALU_SRL  = 4'b0101,
        ALU_SRA  = 4'b1101,
        ALU_OR   = 4'b0110,
        ALU_AND  = 4'b0111
    } alu_op_t;
    
    // Test signals
    logic [3:0] alu_op;
    logic [31:0] operand1;
    logic [31:0] operand2;
    logic [31:0] alu_result;
    
    // Test control
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // DUT instantiation
    alu dut (
        .alu_op(alu_op),
        .operand1(operand1),
        .operand2(operand2),
        .alu_result(alu_result)
    );
    
    // Test sequence
    initial begin
        $display("========================================");
        $display("ALU Unit Test - Production Verification");
        $display("========================================");
        
        // Run directed tests
        run_directed_tests();
        
        // Run random tests
        run_random_tests();
        
        // Generate final report
        generate_test_report();
        
        $finish;
    end
    
    // Directed test cases
    task run_directed_tests();
        $display("🧪 Running directed tests...");
        
        // Test ADD operation
        test_add_operation();
        
        // Test SUB operation
        test_sub_operation();
        
        // Test logical operations
        test_logical_operations();
        
        // Test shift operations
        test_shift_operations();
        
        // Test comparison operations
        test_comparison_operations();
        
        // Test edge cases
        test_edge_cases();
        
        $display("✅ Directed tests completed");
        $display("");
    endtask
    
    // Test ADD operation
    task test_add_operation();
        $display("  Testing ADD operation...");
        
        // Test case 1: Positive numbers
        check_alu_operation(ALU_ADD, 32'd15, 32'd25, 32'd40, "ADD positive");
        
        // Test case 2: Negative numbers
        check_alu_operation(ALU_ADD, -32'd10, -32'd5, -32'd15, "ADD negative");
        
        // Test case 3: Mixed signs
        check_alu_operation(ALU_ADD, 32'd100, -32'd50, 32'd50, "ADD mixed signs");
        
        // Test case 4: Zero operands
        check_alu_operation(ALU_ADD, 32'd0, 32'd42, 32'd42, "ADD with zero");
        
        // Test case 5: Maximum values
        check_alu_operation(ALU_ADD, 32'h7FFFFFFF, 32'd1, 32'h80000000, "ADD overflow");
    endtask
    
    // Test SUB operation
    task test_sub_operation();
        $display("  Testing SUB operation...");
        
        // Test case 1: Basic subtraction
        check_alu_operation(ALU_SUB, 32'd50, 32'd30, 32'd20, "SUB basic");
        
        // Test case 2: Result is negative
        check_alu_operation(ALU_SUB, 32'd10, 32'd20, -32'd10, "SUB negative result");
        
        // Test case 3: Subtract zero
        check_alu_operation(ALU_SUB, 32'd100, 32'd0, 32'd100, "SUB zero");
        
        // Test case 4: Subtract from zero
        check_alu_operation(ALU_SUB, 32'd0, 32'd50, -32'd50, "SUB from zero");
        
        // Test case 5: Underflow
        check_alu_operation(ALU_SUB, 32'h80000000, 32'd1, 32'h7FFFFFFF, "SUB underflow");
    endtask
    
    // Test logical operations
    task test_logical_operations();
        $display("  Testing logical operations...");
        
        // AND operation
        check_alu_operation(ALU_AND, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'h00000000, "AND operation");
        check_alu_operation(ALU_AND, 32'hFFFFFFFF, 32'h12345678, 32'h12345678, "AND with all 1s");
        
        // OR operation
        check_alu_operation(ALU_OR, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, "OR operation");
        check_alu_operation(ALU_OR, 32'h00000000, 32'h12345678, 32'h12345678, "OR with zero");
        
        // XOR operation
        check_alu_operation(ALU_XOR, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, "XOR operation");
        check_alu_operation(ALU_XOR, 32'h12345678, 32'h12345678, 32'h00000000, "XOR same values");
    endtask
    
    // Test shift operations
    task test_shift_operations();
        $display("  Testing shift operations...");
        
        // Left shift
        check_alu_operation(ALU_SLL, 32'h00000001, 32'd4, 32'h00000010, "SLL basic");
        check_alu_operation(ALU_SLL, 32'h12345678, 32'd8, 32'h34567800, "SLL multi-bit");
        
        // Logical right shift
        check_alu_operation(ALU_SRL, 32'h80000000, 32'd4, 32'h08000000, "SRL basic");
        check_alu_operation(ALU_SRL, 32'h12345678, 32'd8, 32'h00123456, "SRL multi-bit");
        
        // Arithmetic right shift
        check_alu_operation(ALU_SRA, 32'h80000000, 32'd4, 32'hF8000000, "SRA negative");
        check_alu_operation(ALU_SRA, 32'h12345678, 32'd8, 32'h00123456, "SRA positive");
        
        // Shift by zero
        check_alu_operation(ALU_SLL, 32'h12345678, 32'd0, 32'h12345678, "SLL by zero");
        check_alu_operation(ALU_SRL, 32'h12345678, 32'd0, 32'h12345678, "SRL by zero");
        check_alu_operation(ALU_SRA, 32'h12345678, 32'd0, 32'h12345678, "SRA by zero");
    endtask
    
    // Test comparison operations
    task test_comparison_operations();
        $display("  Testing comparison operations...");
        
        // SLT (Set Less Than)
        check_alu_operation(ALU_SLT, 32'd10, 32'd20, 32'd1, "SLT true");
        check_alu_operation(ALU_SLT, 32'd20, 32'd10, 32'd0, "SLT false");
        check_alu_operation(ALU_SLT, 32'd10, 32'd10, 32'd0, "SLT equal");
        check_alu_operation(ALU_SLT, -32'd10, 32'd10, 32'd1, "SLT negative");
        
        // SLTU (Set Less Than Unsigned)
        check_alu_operation(ALU_SLTU, 32'd10, 32'd20, 32'd1, "SLTU true");
        check_alu_operation(ALU_SLTU, 32'd20, 32'd10, 32'd0, "SLTU false");
        check_alu_operation(ALU_SLTU, 32'hFFFFFFFF, 32'd1, 32'd0, "SLTU unsigned max");
        check_alu_operation(ALU_SLTU, 32'd1, 32'hFFFFFFFF, 32'd1, "SLTU unsigned comparison");
    endtask
    
    // Test edge cases
    task test_edge_cases();
        $display("  Testing edge cases...");
        
        // Maximum positive value
        check_alu_operation(ALU_ADD, 32'h7FFFFFFF, 32'd0, 32'h7FFFFFFF, "Max positive");
        
        // Maximum negative value
        check_alu_operation(ALU_ADD, 32'h80000000, 32'd0, 32'h80000000, "Max negative");
        
        // All zeros
        check_alu_operation(ALU_ADD, 32'd0, 32'd0, 32'd0, "All zeros");
        
        // All ones
        check_alu_operation(ALU_AND, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF, "All ones AND");
        
        // Shift by maximum amount (should only use lower 5 bits)
        check_alu_operation(ALU_SLL, 32'h00000001, 32'd31, 32'h80000000, "Shift by 31");
        check_alu_operation(ALU_SLL, 32'h00000001, 32'd32, 32'h00000001, "Shift by 32 (mod 32)");
    endtask
    
    // Random test generation
    task run_random_tests();
        logic [31:0] op1, op2, expected;
        alu_op_t operation;
        
        $display("🎲 Running %0d random tests...", NUM_RANDOM_TESTS);
        
        for (int i = 0; i < NUM_RANDOM_TESTS; i++) begin
            // Generate random inputs
            op1 = $random;
            op2 = $random;
            operation = alu_op_t'($urandom_range(0, 9));
            
            // Calculate expected result
            expected = calculate_expected_result(operation, op1, op2);
            
            // Test the operation
            check_alu_operation(operation, op1, op2, expected, $sformatf("Random test %0d", i+1));
        end
        
        $display("✅ Random tests completed");
        $display("");
    endtask
    
    // Calculate expected result for verification
    function logic [31:0] calculate_expected_result(alu_op_t op, logic [31:0] a, logic [31:0] b);
        case (op)
            ALU_ADD:  return a + b;
            ALU_SUB:  return a - b;
            ALU_SLL:  return a << b[4:0];
            ALU_SLT:  return ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU: return (a < b) ? 32'd1 : 32'd0;
            ALU_XOR:  return a ^ b;
            ALU_SRL:  return a >> b[4:0];
            ALU_SRA:  return $signed(a) >>> b[4:0];
            ALU_OR:   return a | b;
            ALU_AND:  return a & b;
            default:  return 32'h00000000;
        endcase
    endfunction
    
    // Check ALU operation
    task check_alu_operation(logic [3:0] op, logic [31:0] a, logic [31:0] b, logic [31:0] expected, string test_name);
        test_count++;
        
        // Apply inputs
        alu_op = op;
        operand1 = a;
        operand2 = b;
        
        // Wait for combinational delay
        #1;
        
        // Check result
        if (alu_result === expected) begin
            pass_count++;
            $display("    ✅ %s: PASS", test_name);
        end else begin
            fail_count++;
            $display("    ❌ %s: FAIL", test_name);
            $display("       Expected: 0x%08h, Got: 0x%08h", expected, alu_result);
            $display("       Op: %b, A: 0x%08h, B: 0x%08h", op, a, b);
        end
    endtask
    
    // Generate test report
    task generate_test_report();
        real success_rate;
        
        $display("========================================");
        $display("ALU UNIT TEST REPORT");
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
            $display("🎉 ALL ALU TESTS PASSED!");
            $display("✅ ALU is functioning correctly");
        end else begin
            $display("❌ %0d ALU TESTS FAILED", fail_count);
            $display("🔧 Review failed tests and fix ALU implementation");
        end
        
        $display("========================================");
    endtask

endmodule