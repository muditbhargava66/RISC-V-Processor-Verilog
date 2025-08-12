`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Control Unit Test - Production Ready
// Comprehensive verification of control unit functionality
//////////////////////////////////////////////////////////////////////////////////

module control_unit_tb;

    // Test parameters
    localparam CLK_PERIOD = 10;
    
    // RISC-V instruction opcodes
    localparam [6:0] OPCODE_R_TYPE    = 7'b0110011;
    localparam [6:0] OPCODE_I_TYPE    = 7'b0010011;
    localparam [6:0] OPCODE_LOAD      = 7'b0000011;
    localparam [6:0] OPCODE_STORE     = 7'b0100011;
    localparam [6:0] OPCODE_BRANCH    = 7'b1100011;
    localparam [6:0] OPCODE_JAL       = 7'b1101111;
    localparam [6:0] OPCODE_JALR      = 7'b1100111;
    localparam [6:0] OPCODE_LUI       = 7'b0110111;
    localparam [6:0] OPCODE_AUIPC     = 7'b0010111;
    
    // Test signals
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic reg_write;
    logic mem_read;
    logic mem_write;
    logic branch;
    logic jump;
    logic [1:0] alu_src;
    logic [3:0] alu_op;
    logic [1:0] reg_write_src;
    
    // Test control
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // Expected control signals structure
    typedef struct {
        logic reg_write;
        logic mem_read;
        logic mem_write;
        logic branch;
        logic jump;
        logic [1:0] alu_src;
        logic [3:0] alu_op;
        logic [1:0] reg_write_src;
    } control_signals_t;
    
    // DUT instantiation
    control_unit dut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .jump(jump),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .reg_write_src(reg_write_src)
    );
    
    // Test sequence
    initial begin
        $display("========================================");
        $display("Control Unit Test - Production Verification");
        $display("========================================");
        
        // Run directed tests
        run_directed_tests();
        
        // Run instruction type tests
        run_instruction_type_tests();
        
        // Run edge case tests
        run_edge_case_tests();
        
        // Generate final report
        generate_test_report();
        
        $finish;
    end
    
    // Directed test cases
    task run_directed_tests();
        $display("🧪 Running directed tests...");
        
        // Test R-type instructions
        test_r_type_instructions();
        
        // Test I-type instructions
        test_i_type_instructions();
        
        // Test Load instructions
        test_load_instructions();
        
        // Test Store instructions
        test_store_instructions();
        
        // Test Branch instructions
        test_branch_instructions();
        
        // Test Jump instructions
        test_jump_instructions();
        
        // Test Upper immediate instructions
        test_upper_immediate_instructions();
        
        $display("✅ Directed tests completed");
        $display("");
    endtask
    
    // Test R-type instructions
    task test_r_type_instructions();
        control_signals_t expected;
        
        $display("  Testing R-type instructions...");
        
        // Common R-type expected signals
        expected.reg_write = 1;
        expected.mem_read = 0;
        expected.mem_write = 0;
        expected.branch = 0;
        expected.jump = 0;
        expected.alu_src = 2'b00; // Register
        expected.reg_write_src = 2'b00; // ALU result
        
        // ADD instruction
        expected.alu_op = 4'b0000;
        check_control_signals(OPCODE_R_TYPE, 3'b000, 7'b0000000, expected, "ADD");
        
        // SUB instruction
        expected.alu_op = 4'b1000;
        check_control_signals(OPCODE_R_TYPE, 3'b000, 7'b0100000, expected, "SUB");
        
        // SLL instruction
        expected.alu_op = 4'b0001;
        check_control_signals(OPCODE_R_TYPE, 3'b001, 7'b0000000, expected, "SLL");
        
        // SLT instruction
        expected.alu_op = 4'b0010;
        check_control_signals(OPCODE_R_TYPE, 3'b010, 7'b0000000, expected, "SLT");
        
        // SLTU instruction
        expected.alu_op = 4'b0011;
        check_control_signals(OPCODE_R_TYPE, 3'b011, 7'b0000000, expected, "SLTU");
        
        // XOR instruction
        expected.alu_op = 4'b0100;
        check_control_signals(OPCODE_R_TYPE, 3'b100, 7'b0000000, expected, "XOR");
        
        // SRL instruction
        expected.alu_op = 4'b0101;
        check_control_signals(OPCODE_R_TYPE, 3'b101, 7'b0000000, expected, "SRL");
        
        // SRA instruction
        expected.alu_op = 4'b1101;
        check_control_signals(OPCODE_R_TYPE, 3'b101, 7'b0100000, expected, "SRA");
        
        // OR instruction
        expected.alu_op = 4'b0110;
        check_control_signals(OPCODE_R_TYPE, 3'b110, 7'b0000000, expected, "OR");
        
        // AND instruction
        expected.alu_op = 4'b0111;
        check_control_signals(OPCODE_R_TYPE, 3'b111, 7'b0000000, expected, "AND");
    endtask
    
    // Test I-type instructions
    task test_i_type_instructions();
        control_signals_t expected;
        
        $display("  Testing I-type instructions...");
        
        // Common I-type expected signals
        expected.reg_write = 1;
        expected.mem_read = 0;
        expected.mem_write = 0;
        expected.branch = 0;
        expected.jump = 0;
        expected.alu_src = 2'b01; // Immediate
        expected.reg_write_src = 2'b00; // ALU result
        
        // ADDI instruction
        expected.alu_op = 4'b0000;
        check_control_signals(OPCODE_I_TYPE, 3'b000, 7'b0000000, expected, "ADDI");
        
        // SLTI instruction
        expected.alu_op = 4'b0010;
        check_control_signals(OPCODE_I_TYPE, 3'b010, 7'b0000000, expected, "SLTI");
        
        // SLTIU instruction
        expected.alu_op = 4'b0011;
        check_control_signals(OPCODE_I_TYPE, 3'b011, 7'b0000000, expected, "SLTIU");
        
        // XORI instruction
        expected.alu_op = 4'b0100;
        check_control_signals(OPCODE_I_TYPE, 3'b100, 7'b0000000, expected, "XORI");
        
        // ORI instruction
        expected.alu_op = 4'b0110;
        check_control_signals(OPCODE_I_TYPE, 3'b110, 7'b0000000, expected, "ORI");
        
        // ANDI instruction
        expected.alu_op = 4'b0111;
        check_control_signals(OPCODE_I_TYPE, 3'b111, 7'b0000000, expected, "ANDI");
        
        // SLLI instruction
        expected.alu_op = 4'b0001;
        check_control_signals(OPCODE_I_TYPE, 3'b001, 7'b0000000, expected, "SLLI");
        
        // SRLI instruction
        expected.alu_op = 4'b0101;
        check_control_signals(OPCODE_I_TYPE, 3'b101, 7'b0000000, expected, "SRLI");
        
        // SRAI instruction
        expected.alu_op = 4'b1101;
        check_control_signals(OPCODE_I_TYPE, 3'b101, 7'b0100000, expected, "SRAI");
    endtask
    
    // Test Load instructions
    task test_load_instructions();
        control_signals_t expected;
        
        $display("  Testing Load instructions...");
        
        // Common Load expected signals
        expected.reg_write = 1;
        expected.mem_read = 1;
        expected.mem_write = 0;
        expected.branch = 0;
        expected.jump = 0;
        expected.alu_src = 2'b01; // Immediate
        expected.alu_op = 4'b0000; // ADD for address calculation
        expected.reg_write_src = 2'b01; // Memory data
        
        // LB instruction
        check_control_signals(OPCODE_LOAD, 3'b000, 7'b0000000, expected, "LB");
        
        // LH instruction
        check_control_signals(OPCODE_LOAD, 3'b001, 7'b0000000, expected, "LH");
        
        // LW instruction
        check_control_signals(OPCODE_LOAD, 3'b010, 7'b0000000, expected, "LW");
        
        // LBU instruction
        check_control_signals(OPCODE_LOAD, 3'b100, 7'b0000000, expected, "LBU");
        
        // LHU instruction
        check_control_signals(OPCODE_LOAD, 3'b101, 7'b0000000, expected, "LHU");
    endtask
    
    // Test Store instructions
    task test_store_instructions();
        control_signals_t expected;
        
        $display("  Testing Store instructions...");
        
        // Common Store expected signals
        expected.reg_write = 0;
        expected.mem_read = 0;
        expected.mem_write = 1;
        expected.branch = 0;
        expected.jump = 0;
        expected.alu_src = 2'b01; // Immediate
        expected.alu_op = 4'b0000; // ADD for address calculation
        expected.reg_write_src = 2'b00; // Don't care (not writing to register)
        
        // SB instruction
        check_control_signals(OPCODE_STORE, 3'b000, 7'b0000000, expected, "SB");
        
        // SH instruction
        check_control_signals(OPCODE_STORE, 3'b001, 7'b0000000, expected, "SH");
        
        // SW instruction
        check_control_signals(OPCODE_STORE, 3'b010, 7'b0000000, expected, "SW");
    endtask
    
    // Test Branch instructions
    task test_branch_instructions();
        control_signals_t expected;
        
        $display("  Testing Branch instructions...");
        
        // Common Branch expected signals
        expected.reg_write = 0;
        expected.mem_read = 0;
        expected.mem_write = 0;
        expected.branch = 1;
        expected.jump = 0;
        expected.alu_src = 2'b00; // Register
        expected.reg_write_src = 2'b00; // Don't care
        
        // BEQ instruction
        expected.alu_op = 4'b1000; // SUB for comparison
        check_control_signals(OPCODE_BRANCH, 3'b000, 7'b0000000, expected, "BEQ");
        
        // BNE instruction
        expected.alu_op = 4'b1000; // SUB for comparison
        check_control_signals(OPCODE_BRANCH, 3'b001, 7'b0000000, expected, "BNE");
        
        // BLT instruction
        expected.alu_op = 4'b0010; // SLT for comparison
        check_control_signals(OPCODE_BRANCH, 3'b100, 7'b0000000, expected, "BLT");
        
        // BGE instruction
        expected.alu_op = 4'b0010; // SLT for comparison
        check_control_signals(OPCODE_BRANCH, 3'b101, 7'b0000000, expected, "BGE");
        
        // BLTU instruction
        expected.alu_op = 4'b0011; // SLTU for comparison
        check_control_signals(OPCODE_BRANCH, 3'b110, 7'b0000000, expected, "BLTU");
        
        // BGEU instruction
        expected.alu_op = 4'b0011; // SLTU for comparison
        check_control_signals(OPCODE_BRANCH, 3'b111, 7'b0000000, expected, "BGEU");
    endtask
    
    // Test Jump instructions
    task test_jump_instructions();
        control_signals_t expected;
        
        $display("  Testing Jump instructions...");
        
        // JAL instruction
        expected.reg_write = 1;
        expected.mem_read = 0;
        expected.mem_write = 0;
        expected.branch = 0;
        expected.jump = 1;
        expected.alu_src = 2'b10; // PC
        expected.alu_op = 4'b0000; // ADD
        expected.reg_write_src = 2'b10; // PC+4
        check_control_signals(OPCODE_JAL, 3'b000, 7'b0000000, expected, "JAL");
        
        // JALR instruction
        expected.reg_write = 1;
        expected.mem_read = 0;
        expected.mem_write = 0;
        expected.branch = 0;
        expected.jump = 1;
        expected.alu_src = 2'b01; // Immediate
        expected.alu_op = 4'b0000; // ADD
        expected.reg_write_src = 2'b10; // PC+4
        check_control_signals(OPCODE_JALR, 3'b000, 7'b0000000, expected, "JALR");
    endtask
    
    // Test Upper immediate instructions
    task test_upper_immediate_instructions();
        control_signals_t expected;
        
        $display("  Testing Upper immediate instructions...");
        
        // LUI instruction
        expected.reg_write = 1;
        expected.mem_read = 0;
        expected.mem_write = 0;
        expected.branch = 0;
        expected.jump = 0;
        expected.alu_src = 2'b01; // Immediate
        expected.alu_op = 4'b0110; // OR (pass through immediate)
        expected.reg_write_src = 2'b00; // ALU result
        check_control_signals(OPCODE_LUI, 3'b000, 7'b0000000, expected, "LUI");
        
        // AUIPC instruction
        expected.reg_write = 1;
        expected.mem_read = 0;
        expected.mem_write = 0;
        expected.branch = 0;
        expected.jump = 0;
        expected.alu_src = 2'b10; // PC
        expected.alu_op = 4'b0000; // ADD
        expected.reg_write_src = 2'b00; // ALU result
        check_control_signals(OPCODE_AUIPC, 3'b000, 7'b0000000, expected, "AUIPC");
    endtask
    
    // Run instruction type tests
    task run_instruction_type_tests();
        $display("🔍 Running instruction type classification tests...");
        
        // Test that each opcode generates appropriate control signals
        test_opcode_classification();
        
        $display("✅ Instruction type tests completed");
        $display("");
    endtask
    
    // Test opcode classification
    task test_opcode_classification();
        $display("  Testing opcode classification...");
        
        // Test that R-type instructions don't generate memory signals
        opcode = OPCODE_R_TYPE;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        #1;
        
        if (mem_read || mem_write) begin
            fail_count++;
            $display("    ❌ R-type should not generate memory signals");
        end else begin
            pass_count++;
            $display("    ✅ R-type memory signals correct");
        end
        test_count++;
        
        // Test that Load instructions generate mem_read
        opcode = OPCODE_LOAD;
        funct3 = 3'b010;
        funct7 = 7'b0000000;
        #1;
        
        if (!mem_read || mem_write) begin
            fail_count++;
            $display("    ❌ Load should generate mem_read only");
        end else begin
            pass_count++;
            $display("    ✅ Load memory signals correct");
        end
        test_count++;
        
        // Test that Store instructions generate mem_write
        opcode = OPCODE_STORE;
        funct3 = 3'b010;
        funct7 = 7'b0000000;
        #1;
        
        if (mem_read || !mem_write) begin
            fail_count++;
            $display("    ❌ Store should generate mem_write only");
        end else begin
            pass_count++;
            $display("    ✅ Store memory signals correct");
        end
        test_count++;
        
        // Test that Branch instructions generate branch signal
        opcode = OPCODE_BRANCH;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        #1;
        
        if (!branch || jump) begin
            fail_count++;
            $display("    ❌ Branch should generate branch signal only");
        end else begin
            pass_count++;
            $display("    ✅ Branch control signals correct");
        end
        test_count++;
    endtask
    
    // Run edge case tests
    task run_edge_case_tests();
        $display("🧪 Running edge case tests...");
        
        // Test invalid opcodes
        test_invalid_opcodes();
        
        // Test reserved funct3/funct7 combinations
        test_reserved_combinations();
        
        $display("✅ Edge case tests completed");
        $display("");
    endtask
    
    // Test invalid opcodes
    task test_invalid_opcodes();
        $display("  Testing invalid opcodes...");
        
        // Test undefined opcode
        opcode = 7'b1111111;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        #1;
        
        // Should generate safe default signals (no writes, no memory access)
        if (reg_write || mem_read || mem_write || branch || jump) begin
            fail_count++;
            $display("    ❌ Invalid opcode should generate safe defaults");
        end else begin
            pass_count++;
            $display("    ✅ Invalid opcode generates safe defaults");
        end
        test_count++;
    endtask
    
    // Test reserved combinations
    task test_reserved_combinations();
        $display("  Testing reserved funct3/funct7 combinations...");
        
        // Test reserved R-type combination
        opcode = OPCODE_R_TYPE;
        funct3 = 3'b000;
        funct7 = 7'b1111111; // Invalid funct7
        #1;
        
        // Should still generate valid R-type signals or safe defaults
        test_count++;
        if (mem_read || mem_write) begin
            fail_count++;
            $display("    ❌ Reserved R-type should not access memory");
        end else begin
            pass_count++;
            $display("    ✅ Reserved R-type generates safe signals");
        end
    endtask
    
    // Check control signals against expected values
    task check_control_signals(
        logic [6:0] test_opcode,
        logic [2:0] test_funct3,
        logic [6:0] test_funct7,
        control_signals_t expected,
        string test_name
    );
        test_count++;
        
        // Apply inputs
        opcode = test_opcode;
        funct3 = test_funct3;
        funct7 = test_funct7;
        
        // Wait for combinational delay
        #1;
        
        // Check all control signals
        if (reg_write === expected.reg_write &&
            mem_read === expected.mem_read &&
            mem_write === expected.mem_write &&
            branch === expected.branch &&
            jump === expected.jump &&
            alu_src === expected.alu_src &&
            alu_op === expected.alu_op &&
            reg_write_src === expected.reg_write_src) begin
            
            pass_count++;
            $display("    ✅ %s: PASS", test_name);
        end else begin
            fail_count++;
            $display("    ❌ %s: FAIL", test_name);
            $display("       Expected: rw=%b mr=%b mw=%b br=%b j=%b as=%b ao=%b rws=%b",
                     expected.reg_write, expected.mem_read, expected.mem_write,
                     expected.branch, expected.jump, expected.alu_src,
                     expected.alu_op, expected.reg_write_src);
            $display("       Got:      rw=%b mr=%b mw=%b br=%b j=%b as=%b ao=%b rws=%b",
                     reg_write, mem_read, mem_write, branch, jump,
                     alu_src, alu_op, reg_write_src);
        end
    endtask
    
    // Generate test report
    task generate_test_report();
        real success_rate;
        
        $display("========================================");
        $display("CONTROL UNIT TEST REPORT");
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
            $display("🎉 ALL CONTROL UNIT TESTS PASSED!");
            $display("✅ Control unit is functioning correctly");
        end else begin
            $display("❌ %0d CONTROL UNIT TESTS FAILED", fail_count);
            $display("🔧 Review failed tests and fix control unit implementation");
        end
        
        $display("========================================");
    endtask
    
    // Coverage collection
    covergroup control_coverage @(opcode, funct3, funct7);
        opcode_cp: coverpoint opcode {
            bins r_type = {OPCODE_R_TYPE};
            bins i_type = {OPCODE_I_TYPE};
            bins load = {OPCODE_LOAD};
            bins store = {OPCODE_STORE};
            bins branch = {OPCODE_BRANCH};
            bins jal = {OPCODE_JAL};
            bins jalr = {OPCODE_JALR};
            bins lui = {OPCODE_LUI};
            bins auipc = {OPCODE_AUIPC};
            bins invalid = default;
        }
        
        funct3_cp: coverpoint funct3;
        funct7_cp: coverpoint funct7;
        
        cross opcode_cp, funct3_cp;
    endgroup
    
    control_coverage control_cov = new();

endmodule