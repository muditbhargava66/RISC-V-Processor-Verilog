`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Immediate Generator Unit Test - Production Ready
// Comprehensive verification of immediate generation functionality
//////////////////////////////////////////////////////////////////////////////////

module immediate_generator_tb;

    // Test parameters
    localparam NUM_RANDOM_TESTS = 200;
    
    // RISC-V instruction types
    typedef enum logic [2:0] {
        I_TYPE = 3'b000,
        S_TYPE = 3'b001,
        B_TYPE = 3'b010,
        U_TYPE = 3'b011,
        J_TYPE = 3'b100
    } inst_type_t;
    
    // Test signals
    logic [31:0] instruction;
    logic [2:0] inst_type;
    logic [31:0] immediate;
    
    // Test control
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // DUT instantiation
    immediate_generator dut (
        .instruction(instruction),
        .inst_type(inst_type),
        .immediate(immediate)
    );
    
    // Test sequence
    initial begin
        $display("========================================");
        $display("Immediate Generator Unit Test - Production Verification");
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
        
        // Test I-type immediate generation
        test_i_type_immediate();
        
        // Test S-type immediate generation
        test_s_type_immediate();
        
        // Test B-type immediate generation
        test_b_type_immediate();
        
        // Test U-type immediate generation
        test_u_type_immediate();
        
        // Test J-type immediate generation
        test_j_type_immediate();
        
        // Test edge cases
        test_edge_cases();
        
        $display("✅ Directed tests completed");
        $display("");
    endtask
    
    // Test I-type immediate generation
    task test_i_type_immediate();
        logic [31:0] test_inst;
        logic [31:0] expected_imm;
        
        $display("  Testing I-type immediate generation...");
        
        // Test case 1: Positive immediate
        test_inst = 32'h12345093; // ADDI x1, x8, 0x123
        expected_imm = 32'h00000123;
        check_immediate_generation(test_inst, I_TYPE, expected_imm, "I-type positive");
        
        // Test case 2: Negative immediate (sign extension)
        test_inst = 32'hFFF45093; // ADDI x1, x8, -1
        expected_imm = 32'hFFFFFFFF;
        check_immediate_generation(test_inst, I_TYPE, expected_imm, "I-type negative");
        
        // Test case 3: Zero immediate
        test_inst = 32'h00045093; // ADDI x1, x8, 0
        expected_imm = 32'h00000000;
        check_immediate_generation(test_inst, I_TYPE, expected_imm, "I-type zero");
        
        // Test case 4: Maximum positive (11 bits)
        test_inst = 32'h7FF45093; // ADDI x1, x8, 0x7FF
        expected_imm = 32'h000007FF;
        check_immediate_generation(test_inst, I_TYPE, expected_imm, "I-type max positive");
        
        // Test case 5: Maximum negative (sign bit set)
        test_inst = 32'h80045093; // ADDI x1, x8, 0x800 (sign extended)
        expected_imm = 32'hFFFFF800;
        check_immediate_generation(test_inst, I_TYPE, expected_imm, "I-type max negative");
    endtask
    
    // Test S-type immediate generation
    task test_s_type_immediate();
        logic [31:0] test_inst;
        logic [31:0] expected_imm;
        
        $display("  Testing S-type immediate generation...");
        
        // Test case 1: Positive immediate
        test_inst = 32'h12345123; // SW with immediate 0x123
        expected_imm = 32'h00000123;
        check_immediate_generation(test_inst, S_TYPE, expected_imm, "S-type positive");
        
        // Test case 2: Negative immediate
        test_inst = 32'hFFF45FE3; // SW with immediate -1
        expected_imm = 32'hFFFFFFFF;
        check_immediate_generation(test_inst, S_TYPE, expected_imm, "S-type negative");
        
        // Test case 3: Zero immediate
        test_inst = 32'h00045023; // SW with immediate 0
        expected_imm = 32'h00000000;
        check_immediate_generation(test_inst, S_TYPE, expected_imm, "S-type zero");
        
        // Test case 4: Mixed bits
        test_inst = 32'h55545AA3; // SW with mixed immediate
        expected_imm = 32'h000005AA;
        check_immediate_generation(test_inst, S_TYPE, expected_imm, "S-type mixed bits");
    endtask
    
    // Test B-type immediate generation
    task test_b_type_immediate();
        logic [31:0] test_inst;
        logic [31:0] expected_imm;
        
        $display("  Testing B-type immediate generation...");
        
        // Test case 1: Positive branch offset
        test_inst = 32'h10845063; // BEQ with positive offset
        expected_imm = 32'h00000100;
        check_immediate_generation(test_inst, B_TYPE, expected_imm, "B-type positive");
        
        // Test case 2: Negative branch offset
        test_inst = 32'hFE845FE3; // BEQ with negative offset
        expected_imm = 32'hFFFFFFFE;
        check_immediate_generation(test_inst, B_TYPE, expected_imm, "B-type negative");
        
        // Test case 3: Zero offset
        test_inst = 32'h00845063; // BEQ with zero offset
        expected_imm = 32'h00000000;
        check_immediate_generation(test_inst, B_TYPE, expected_imm, "B-type zero");
        
        // Test case 4: Maximum positive offset
        test_inst = 32'h7E845FE3; // BEQ with max positive
        expected_imm = 32'h00000FFE;
        check_immediate_generation(test_inst, B_TYPE, expected_imm, "B-type max positive");
    endtask  
  
    // Test U-type immediate generation
    task test_u_type_immediate();
        logic [31:0] test_inst;
        logic [31:0] expected_imm;
        
        $display("  Testing U-type immediate generation...");
        
        // Test case 1: LUI with positive immediate
        test_inst = 32'h12345037; // LUI x0, 0x12345
        expected_imm = 32'h12345000;
        check_immediate_generation(test_inst, U_TYPE, expected_imm, "U-type positive");
        
        // Test case 2: LUI with all 1s in upper bits
        test_inst = 32'hFFFFF037; // LUI x0, 0xFFFFF
        expected_imm = 32'hFFFFF000;
        check_immediate_generation(test_inst, U_TYPE, expected_imm, "U-type all 1s");
        
        // Test case 3: LUI with zero
        test_inst = 32'h00000037; // LUI x0, 0
        expected_imm = 32'h00000000;
        check_immediate_generation(test_inst, U_TYPE, expected_imm, "U-type zero");
        
        // Test case 4: AUIPC test
        test_inst = 32'hABCDE017; // AUIPC x0, 0xABCDE
        expected_imm = 32'hABCDE000;
        check_immediate_generation(test_inst, U_TYPE, expected_imm, "U-type AUIPC");
    endtask
    
    // Test J-type immediate generation
    task test_j_type_immediate();
        logic [31:0] test_inst;
        logic [31:0] expected_imm;
        
        $display("  Testing J-type immediate generation...");
        
        // Test case 1: JAL with positive offset
        test_inst = 32'h1234506F; // JAL with positive offset
        expected_imm = 32'h00012344;
        check_immediate_generation(test_inst, J_TYPE, expected_imm, "J-type positive");
        
        // Test case 2: JAL with negative offset
        test_inst = 32'hFFFFF06F; // JAL with negative offset
        expected_imm = 32'hFFFFFFFE;
        check_immediate_generation(test_inst, J_TYPE, expected_imm, "J-type negative");
        
        // Test case 3: JAL with zero offset
        test_inst = 32'h0000006F; // JAL with zero offset
        expected_imm = 32'h00000000;
        check_immediate_generation(test_inst, J_TYPE, expected_imm, "J-type zero");
        
        // Test case 4: JAL with maximum positive
        test_inst = 32'h7FFFF06F; // JAL with max positive
        expected_imm = 32'h000FFFFE;
        check_immediate_generation(test_inst, J_TYPE, expected_imm, "J-type max positive");
    endtask
    
    // Test edge cases
    task test_edge_cases();
        logic [31:0] test_inst;
        logic [31:0] expected_imm;
        
        $display("  Testing edge cases...");
        
        // Test all bits set in instruction
        test_inst = 32'hFFFFFFFF;
        expected_imm = 32'hFFFFFFFF;
        check_immediate_generation(test_inst, I_TYPE, expected_imm, "All bits set I-type");
        
        // Test alternating bit pattern
        test_inst = 32'hAAAAAAAA;
        expected_imm = 32'hFFFFFAAA;
        check_immediate_generation(test_inst, I_TYPE, expected_imm, "Alternating pattern I-type");
        
        // Test sign extension boundary
        test_inst = 32'h7FF00093; // I-type with bit 11 = 0
        expected_imm = 32'h000007FF;
        check_immediate_generation(test_inst, I_TYPE, expected_imm, "Sign extension boundary +");
        
        test_inst = 32'h80000093; // I-type with bit 11 = 1
        expected_imm = 32'hFFFFF800;
        check_immediate_generation(test_inst, I_TYPE, expected_imm, "Sign extension boundary -");
    endtask
    
    // Random test generation
    task run_random_tests();
        logic [31:0] rand_inst;
        inst_type_t rand_type;
        logic [31:0] expected_imm;
        
        $display("🎲 Running %0d random tests...", NUM_RANDOM_TESTS);
        
        for (int i = 0; i < NUM_RANDOM_TESTS; i++) begin
            // Generate random instruction and type
            rand_inst = $random;
            rand_type = inst_type_t'($urandom_range(0, 4));
            
            // Calculate expected immediate
            expected_imm = calculate_expected_immediate(rand_inst, rand_type);
            
            // Test the operation
            check_immediate_generation(rand_inst, rand_type, expected_imm, 
                                     $sformatf("Random test %0d", i+1));
        end
        
        $display("✅ Random tests completed");
        $display("");
    endtask   
 
    // Calculate expected immediate for verification
    function logic [31:0] calculate_expected_immediate(logic [31:0] inst, inst_type_t itype);
        case (itype)
            I_TYPE: begin
                // I-type: imm[11:0] = inst[31:20]
                return {{20{inst[31]}}, inst[31:20]};
            end
            
            S_TYPE: begin
                // S-type: imm[11:0] = {inst[31:25], inst[11:7]}
                return {{20{inst[31]}}, inst[31:25], inst[11:7]};
            end
            
            B_TYPE: begin
                // B-type: imm[12:1] = {inst[31], inst[7], inst[30:25], inst[11:8]}
                return {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            end
            
            U_TYPE: begin
                // U-type: imm[31:12] = inst[31:12], imm[11:0] = 0
                return {inst[31:12], 12'b0};
            end
            
            J_TYPE: begin
                // J-type: imm[20:1] = {inst[31], inst[19:12], inst[20], inst[30:21]}
                return {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
            end
            
            default: return 32'h00000000;
        endcase
    endfunction
    
    // Check immediate generation
    task check_immediate_generation(
        logic [31:0] test_inst,
        inst_type_t test_type,
        logic [31:0] expected,
        string test_name
    );
        test_count++;
        
        // Apply inputs
        instruction = test_inst;
        inst_type = test_type;
        
        // Wait for combinational delay
        #1;
        
        // Check result
        if (immediate === expected) begin
            pass_count++;
            $display("    ✅ %s: PASS", test_name);
        end else begin
            fail_count++;
            $display("    ❌ %s: FAIL", test_name);
            $display("       Instruction: 0x%08h, Type: %s", test_inst, test_type.name());
            $display("       Expected: 0x%08h, Got: 0x%08h", expected, immediate);
            
            // Show bit breakdown for debugging
            case (test_type)
                I_TYPE: $display("       I-type bits [31:20]: 0x%03h", test_inst[31:20]);
                S_TYPE: $display("       S-type bits [31:25,11:7]: 0x%02h%01h", test_inst[31:25], test_inst[11:7]);
                B_TYPE: $display("       B-type bits [31,7,30:25,11:8]: %b_%b_%b_%b", test_inst[31], test_inst[7], test_inst[30:25], test_inst[11:8]);
                U_TYPE: $display("       U-type bits [31:12]: 0x%05h", test_inst[31:12]);
                J_TYPE: $display("       J-type bits [31,19:12,20,30:21]: %b_%b_%b_%b", test_inst[31], test_inst[19:12], test_inst[20], test_inst[30:21]);
            endcase
        end
    endtask
    
    // Generate test report
    task generate_test_report();
        real success_rate;
        
        $display("========================================");
        $display("IMMEDIATE GENERATOR UNIT TEST REPORT");
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
            $display("🎉 ALL IMMEDIATE GENERATOR TESTS PASSED!");
            $display("✅ Immediate generator is functioning correctly");
        end else begin
            $display("❌ %0d IMMEDIATE GENERATOR TESTS FAILED", fail_count);
            $display("🔧 Review failed tests and fix immediate generator implementation");
        end
        
        $display("========================================");
    endtask
    
    // Coverage collection
    covergroup imm_gen_coverage @(instruction, inst_type);
        inst_type_cp: coverpoint inst_type {
            bins i_type = {I_TYPE};
            bins s_type = {S_TYPE};
            bins b_type = {B_TYPE};
            bins u_type = {U_TYPE};
            bins j_type = {J_TYPE};
        }
        
        sign_bit: coverpoint instruction[31] {
            bins positive = {0};
            bins negative = {1};
        }
        
        immediate_ranges: coverpoint immediate {
            bins zero = {32'h00000000};
            bins small_pos = {[32'h00000001:32'h0000FFFF]};
            bins large_pos = {[32'h00010000:32'h7FFFFFFF]};
            bins small_neg = {[32'h80000000:32'hFFFF0000]};
            bins large_neg = {[32'hFFFF0001:32'hFFFFFFFF]};
        }
        
        cross inst_type_cp, sign_bit;
        cross inst_type_cp, immediate_ranges;
    endgroup
    
    imm_gen_coverage imm_gen_cov = new();

endmodule