`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Branch Unit Test - Production Ready
// Comprehensive verification of branch condition evaluation
//////////////////////////////////////////////////////////////////////////////////

module branch_unit_tb;

    // Test parameters
    localparam NUM_RANDOM_TESTS = 200;
    
    // Test signals
    logic [2:0] funct3;
    logic [31:0] operand1;
    logic [31:0] operand2;
    logic branch;
    logic jump;
    logic branch_taken;
    
    // Test control
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // DUT instantiation
    branch_unit dut (
        .funct3(funct3),
        .operand1(operand1),
        .operand2(operand2),
        .branch(branch),
        .jump(jump),
        .branch_taken(branch_taken)
    );
    
    // Test sequence
    initial begin
        $display("========================================");
        $display("Branch Unit Test - Production Verification");
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
        
        // Test jump conditions
        test_jump_conditions();
        
        // Test branch conditions
        test_branch_conditions();
        
        // Test no branch/jump
        test_no_branch_jump();
        
        // Test edge cases
        test_edge_cases();
        
        $display("✅ Directed tests completed");
        $display("");
    endtask
    
    // Test jump conditions
    task test_jump_conditions();
        $display("  Testing jump conditions...");
        
        // Jump should always be taken regardless of operands
        check_branch_condition(3'b000, 32'd10, 32'd20, 0, 1, 1, "Jump always taken (equal operands)");
        check_branch_condition(3'b000, 32'd10, 32'd5, 0, 1, 1, "Jump always taken (different operands)");
        check_branch_condition(3'b000, 32'h80000000, 32'h7FFFFFFF, 0, 1, 1, "Jump always taken (extreme values)");
        check_branch_condition(3'b000, 32'd0, 32'd0, 0, 1, 1, "Jump always taken (zero operands)");
    endtask
    
    // Test branch conditions
    task test_branch_conditions();
        $display("  Testing branch conditions...");
        
        // BEQ (000) - Branch if Equal
        check_branch_condition(3'b000, 32'd10, 32'd10, 1, 0, 1, "BEQ equal");
        check_branch_condition(3'b000, 32'd10, 32'd20, 1, 0, 0, "BEQ not equal");
        check_branch_condition(3'b000, 32'd0, 32'd0, 1, 0, 1, "BEQ both zero");
        check_branch_condition(3'b000, 32'hFFFFFFFF, 32'hFFFFFFFF, 1, 0, 1, "BEQ both -1");
        
        // BNE (001) - Branch if Not Equal
        check_branch_condition(3'b001, 32'd10, 32'd20, 1, 0, 1, "BNE not equal");
        check_branch_condition(3'b001, 32'd10, 32'd10, 1, 0, 0, "BNE equal");
        check_branch_condition(3'b001, 32'd0, 32'd1, 1, 0, 1, "BNE zero vs one");
        
        // BLT (100) - Branch if Less Than (signed)
        check_branch_condition(3'b100, 32'd10, 32'd20, 1, 0, 1, "BLT positive less");
        check_branch_condition(3'b100, 32'd20, 32'd10, 1, 0, 0, "BLT positive greater");
        check_branch_condition(3'b100, -32'd10, 32'd10, 1, 0, 1, "BLT negative less than positive");
        check_branch_condition(3'b100, 32'd10, -32'd10, 1, 0, 0, "BLT positive greater than negative");
        check_branch_condition(3'b100, -32'd20, -32'd10, 1, 0, 1, "BLT negative less");
        check_branch_condition(3'b100, -32'd10, -32'd20, 1, 0, 0, "BLT negative greater");
        check_branch_condition(3'b100, 32'd10, 32'd10, 1, 0, 0, "BLT equal");
        
        // BGE (101) - Branch if Greater or Equal (signed)
        check_branch_condition(3'b101, 32'd20, 32'd10, 1, 0, 1, "BGE positive greater");
        check_branch_condition(3'b101, 32'd10, 32'd20, 1, 0, 0, "BGE positive less");
        check_branch_condition(3'b101, 32'd10, 32'd10, 1, 0, 1, "BGE equal");
        check_branch_condition(3'b101, 32'd10, -32'd10, 1, 0, 1, "BGE positive >= negative");
        check_branch_condition(3'b101, -32'd10, 32'd10, 1, 0, 0, "BGE negative < positive");
        check_branch_condition(3'b101, -32'd10, -32'd20, 1, 0, 1, "BGE negative greater");
        
        // BLTU (110) - Branch if Less Than Unsigned
        check_branch_condition(3'b110, 32'd10, 32'd20, 1, 0, 1, "BLTU unsigned less");
        check_branch_condition(3'b110, 32'd20, 32'd10, 1, 0, 0, "BLTU unsigned greater");
        check_branch_condition(3'b110, 32'd1, 32'hFFFFFFFF, 1, 0, 1, "BLTU small vs large unsigned");
        check_branch_condition(3'b110, 32'hFFFFFFFF, 32'd1, 1, 0, 0, "BLTU large vs small unsigned");
        check_branch_condition(3'b110, 32'd10, 32'd10, 1, 0, 0, "BLTU equal");
        
        // BGEU (111) - Branch if Greater or Equal Unsigned
        check_branch_condition(3'b111, 32'd20, 32'd10, 1, 0, 1, "BGEU unsigned greater");
        check_branch_condition(3'b111, 32'd10, 32'd20, 1, 0, 0, "BGEU unsigned less");
        check_branch_condition(3'b111, 32'd10, 32'd10, 1, 0, 1, "BGEU equal");
        check_branch_condition(3'b111, 32'hFFFFFFFF, 32'd1, 1, 0, 1, "BGEU large vs small unsigned");
        check_branch_condition(3'b111, 32'd1, 32'hFFFFFFFF, 1, 0, 0, "BGEU small vs large unsigned");
    endtask
    
    // Test no branch/jump conditions
    task test_no_branch_jump();
        $display("  Testing no branch/jump conditions...");
        
        // Neither branch nor jump enabled
        check_branch_condition(3'b000, 32'd10, 32'd10, 0, 0, 0, "No branch, no jump");
        check_branch_condition(3'b001, 32'd10, 32'd20, 0, 0, 0, "No branch, no jump (different values)");
        check_branch_condition(3'b100, 32'd5, 32'd10, 0, 0, 0, "No branch, no jump (would branch if enabled)");
    endtask
    
    // Test edge cases
    task test_edge_cases();
        $display("  Testing edge cases...");
        
        // Test with maximum/minimum values
        check_branch_condition(3'b100, 32'h80000000, 32'h7FFFFFFF, 1, 0, 1, "BLT min vs max signed");
        check_branch_condition(3'b101, 32'h7FFFFFFF, 32'h80000000, 1, 0, 1, "BGE max vs min signed");
        check_branch_condition(3'b110, 32'h00000000, 32'hFFFFFFFF, 1, 0, 1, "BLTU min vs max unsigned");
        check_branch_condition(3'b111, 32'hFFFFFFFF, 32'h00000000, 1, 0, 1, "BGEU max vs min unsigned");
        
        // Test both branch and jump enabled (jump should take precedence)
        check_branch_condition(3'b000, 32'd10, 32'd20, 1, 1, 1, "Both branch and jump (jump precedence)");
        check_branch_condition(3'b001, 32'd10, 32'd10, 1, 1, 1, "Both branch and jump (branch would fail)");
        
        // Test reserved funct3 values (should not cause issues)
        check_branch_condition(3'b010, 32'd10, 32'd20, 1, 0, 0, "Reserved funct3 010");
        check_branch_condition(3'b011, 32'd10, 32'd20, 1, 0, 0, "Reserved funct3 011");
    endtask
    
    // Random test generation
    task run_random_tests();
        logic [2:0] rand_funct3;
        logic [31:0] rand_op1, rand_op2;
        logic rand_branch, rand_jump;
        logic expected_result;
        
        $display("🎲 Running %0d random tests...", NUM_RANDOM_TESTS);
        
        for (int i = 0; i < NUM_RANDOM_TESTS; i++) begin
            // Generate random inputs
            rand_funct3 = $urandom_range(0, 7);
            rand_op1 = $random;
            rand_op2 = $random;
            rand_branch = $urandom_range(0, 1);
            rand_jump = $urandom_range(0, 1);
            
            // Calculate expected result
            expected_result = calculate_expected_branch(rand_funct3, rand_op1, rand_op2, rand_branch, rand_jump);
            
            // Test the operation
            check_branch_condition(rand_funct3, rand_op1, rand_op2, rand_branch, rand_jump, 
                                 expected_result, $sformatf("Random test %0d", i+1));
        end
        
        $display("✅ Random tests completed");
        $display("");
    endtask
    
    // Calculate expected branch result
    function logic calculate_expected_branch(logic [2:0] f3, logic [31:0] op1, logic [31:0] op2, logic br, logic jmp);
        if (jmp) return 1; // Jump always taken
        if (!br) return 0; // No branch
        
        case (f3)
            3'b000: return (op1 == op2);                    // BEQ
            3'b001: return (op1 != op2);                    // BNE
            3'b100: return ($signed(op1) < $signed(op2));   // BLT
            3'b101: return ($signed(op1) >= $signed(op2));  // BGE
            3'b110: return (op1 < op2);                     // BLTU
            3'b111: return (op1 >= op2);                    // BGEU
            default: return 0; // Reserved/invalid
        endcase
    endfunction
    
    // Check branch condition
    task check_branch_condition(
        logic [2:0] f3,
        logic [31:0] op1,
        logic [31:0] op2,
        logic br,
        logic jmp,
        logic expected,
        string test_name
    );
        test_count++;
        
        // Apply inputs
        funct3 = f3;
        operand1 = op1;
        operand2 = op2;
        branch = br;
        jump = jmp;
        
        // Wait for combinational delay
        #1;
        
        // Check result
        if (branch_taken === expected) begin
            pass_count++;
            $display("    ✅ %s: PASS", test_name);
        end else begin
            fail_count++;
            $display("    ❌ %s: FAIL", test_name);
            $display("       funct3=%b, op1=0x%08h, op2=0x%08h, branch=%b, jump=%b", 
                     f3, op1, op2, br, jmp);
            $display("       Expected: %b, Got: %b", expected, branch_taken);
        end
    endtask
    
    // Generate test report
    task generate_test_report();
        real success_rate;
        
        $display("========================================");
        $display("BRANCH UNIT TEST REPORT");
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
            $display("🎉 ALL BRANCH UNIT TESTS PASSED!");
            $display("✅ Branch unit is functioning correctly");
        end else begin
            $display("❌ %0d BRANCH UNIT TESTS FAILED", fail_count);
            $display("🔧 Review failed tests and fix branch unit implementation");
        end
        
        $display("========================================");
    endtask
    
    // Coverage collection
    covergroup branch_coverage @(funct3, operand1, operand2, branch, jump);
        funct3_cp: coverpoint funct3 {
            bins beq = {3'b000};
            bins bne = {3'b001};
            bins blt = {3'b100};
            bins bge = {3'b101};
            bins bltu = {3'b110};
            bins bgeu = {3'b111};
            bins reserved = {3'b010, 3'b011};
        }
        
        branch_cp: coverpoint branch {
            bins enabled = {1};
            bins disabled = {0};
        }
        
        jump_cp: coverpoint jump {
            bins enabled = {1};
            bins disabled = {0};
        }
        
        operand_relation: coverpoint (operand1 == operand2) {
            bins equal = {1};
            bins not_equal = {0};
        }
        
        cross funct3_cp, branch_cp, jump_cp;
        cross funct3_cp, operand_relation, branch_cp;
    endgroup
    
    branch_coverage branch_cov = new();

endmodule