// LUI (Load Upper Immediate) Instruction Test
// Tests the critical LUI bug fix

`timescale 1ns / 1ps

module lui_test;

    // Test signals
    reg clk;
    reg reset;
    wire [31:0] pc_debug;
    wire [31:0] instruction_debug;
    wire [31:0] alu_result_debug;
    wire [31:0] reg_debug_data1;
    wire [31:0] reg_debug_data2;
    wire [31:0] immediate_debug;
    wire reg_write_debug;
    
    // Instantiate processor
    riscv_processor uut (
        .clk(clk),
        .reset(reset),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .alu_result_debug(alu_result_debug),
        .reg_debug_data1(reg_debug_data1),
        .reg_debug_data2(reg_debug_data2),
        .immediate_debug(immediate_debug),
        .reg_write_debug(reg_write_debug)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test variables
    integer test_count = 0;
    integer pass_count = 0;
    
    // Test task
    task check_register;
        input [4:0] reg_addr;
        input [31:0] expected_value;
        input [200*8-1:0] test_name;
        reg [31:0] actual_val;
        begin
            test_count = test_count + 1;
            // Wait for register write to complete
            @(posedge clk);
            #1; // Wait for write to complete in register file
            
            actual_val = (reg_addr == 5'b0) ? 32'h0 : uut.regfile_inst.registers[reg_addr];
            if (actual_val == expected_value) begin
                $display("PASS: %s - Expected: 0x%08h, Actual: 0x%08h", test_name, expected_value, actual_val);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s - Expected: 0x%08h, Actual: 0x%08h", 
                        test_name, expected_value, actual_val);
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("=========================================");
        $display("LUI (Load Upper Immediate) Test");
        $display("Testing Critical LUI Bug Fix");
        $display("=========================================");
        
        // Initialize
        reset = 1;
        #20;
        reset = 0;
        
        $display("Starting LUI instruction tests...");
        
        // Monitor for LUI instructions
        // LUI opcode is 7'b0110111 (0x37)
        repeat (30) begin
            if (!reset && (instruction_debug[6:0] == 7'b0110111)) begin // LUI instruction detected
                $display("LUI Instruction Detected:");
                $display("  PC: 0x%08h", pc_debug);
                $display("  Instruction: 0x%08h", instruction_debug);
                $display("  Immediate: 0x%08h", immediate_debug);
                $display("  Reg Write: %b", reg_write_debug);
                
                // Extract the immediate field (bits [31:12])
                check_register(instruction_debug[11:7], {instruction_debug[31:12], 12'b0}, "LUI Immediate Check");
            end
            
            // Also check for AUIPC (Add Upper Immediate to PC)
            if (!reset && (instruction_debug[6:0] == 7'b0010111)) begin // AUIPC instruction
                $display("AUIPC Instruction Detected:");
                $display("  PC: 0x%08h", pc_debug);
                $display("  Instruction: 0x%08h", instruction_debug);
                $display("  Immediate: 0x%08h", immediate_debug);
                $display("  ALU Result: 0x%08h", alu_result_debug);
            end
            @(posedge clk);
        end
        
        // Test summary
        $display("");
        $display("=========================================");
        $display("LUI Test Results:");
        $display("Tests Run: %0d", test_count);
        $display("Tests Passed: %0d", pass_count);
        if (pass_count == test_count && test_count > 0) begin
            $display("STATUS: ALL TESTS PASSED!");
        end else if (test_count == 0) begin
            $display("STATUS: NO LUI INSTRUCTIONS FOUND IN TEST PROGRAM");
            $display("NOTE: This may indicate the instruction memory needs LUI test cases");
        end else begin
            $display("STATUS: SOME TESTS FAILED!");
        end
        $display("=========================================");
        
        #100;
        $finish;
    end
    
    // Monitor all instructions for debugging
    always @(posedge clk) begin
        if (!reset && reg_write_debug) begin
            $display("Instruction: PC=0x%08h, Instr=0x%08h, Imm=0x%08h, RegWrite=%b", 
                    pc_debug, instruction_debug, immediate_debug, reg_write_debug);
        end
    end

endmodule