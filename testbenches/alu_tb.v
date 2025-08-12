// ALU Testbench
// Comprehensive test for all ALU operations

`timescale 1ns / 1ps

module alu_tb;

    // Testbench signals
    reg [31:0] operand_a;
    reg [31:0] operand_b;
    reg [3:0] alu_control;
    wire [31:0] result;
    wire zero;
    
    // Expected result for verification
    reg [31:0] expected_result;
    integer test_count = 0;
    integer pass_count = 0;
    
    // DUT instantiation
    alu dut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .alu_control(alu_control),
        .result(result),
        .zero(zero)
    );
    
    // Test task
    task test_alu_operation;
        input [3:0] op;
        input [31:0] a;
        input [31:0] b;
        input [31:0] expected;
        input [79:0] op_name;
        begin
            operand_a = a;
            operand_b = b;
            alu_control = op;
            expected_result = expected;
            #10;
            
            test_count = test_count + 1;
            if (result == expected_result) begin
                pass_count = pass_count + 1;
                $display("PASS: %s | A=%08h B=%08h Result=%08h", op_name, a, b, result);
            end else begin
                $display("FAIL: %s | A=%08h B=%08h Expected=%08h Got=%08h", 
                        op_name, a, b, expected_result, result);
            end
        end
    endtask
    
    initial begin
        $display("========================================");
        $display("ALU Comprehensive Test");
        $display("========================================");
        
        // Test ADD operations
        test_alu_operation(4'b0000, 32'h00000005, 32'h00000003, 32'h00000008, "ADD");
        test_alu_operation(4'b0000, 32'hFFFFFFFF, 32'h00000001, 32'h00000000, "ADD");
        test_alu_operation(4'b0000, 32'h80000000, 32'h80000000, 32'h00000000, "ADD");
        
        // Test SUB operations
        test_alu_operation(4'b1000, 32'h00000005, 32'h00000003, 32'h00000002, "SUB");
        test_alu_operation(4'b1000, 32'h00000000, 32'h00000001, 32'hFFFFFFFF, "SUB");
        test_alu_operation(4'b1000, 32'h80000000, 32'h00000001, 32'h7FFFFFFF, "SUB");
        
        // Test AND operations
        test_alu_operation(4'b0111, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'h00000000, "AND");
        test_alu_operation(4'b0111, 32'hFFFFFFFF, 32'h12345678, 32'h12345678, "AND");
        
        // Test OR operations
        test_alu_operation(4'b0110, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, "OR");
        test_alu_operation(4'b0110, 32'h00000000, 32'h12345678, 32'h12345678, "OR");
        
        // Test XOR operations
        test_alu_operation(4'b0100, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, "XOR");
        test_alu_operation(4'b0100, 32'h12345678, 32'h12345678, 32'h00000000, "XOR");
        
        // Test SLL operations
        test_alu_operation(4'b0001, 32'h00000001, 32'h00000004, 32'h00000010, "SLL");
        test_alu_operation(4'b0001, 32'h80000000, 32'h00000001, 32'h00000000, "SLL");
        
        // Test SRL operations
        test_alu_operation(4'b0101, 32'h80000000, 32'h00000004, 32'h08000000, "SRL");
        test_alu_operation(4'b0101, 32'hFFFFFFFF, 32'h00000001, 32'h7FFFFFFF, "SRL");
        
        // Test SRA operations
        test_alu_operation(4'b1101, 32'h80000000, 32'h00000004, 32'hF8000000, "SRA");
        test_alu_operation(4'b1101, 32'h7FFFFFFF, 32'h00000001, 32'h3FFFFFFF, "SRA");
        
        // Test SLT operations
        test_alu_operation(4'b0010, 32'h00000001, 32'h00000002, 32'h00000001, "SLT");
        test_alu_operation(4'b0010, 32'hFFFFFFFF, 32'h00000001, 32'h00000001, "SLT");
        test_alu_operation(4'b0010, 32'h00000001, 32'hFFFFFFFF, 32'h00000000, "SLT");
        
        // Test SLTU operations
        test_alu_operation(4'b0011, 32'h00000001, 32'h00000002, 32'h00000001, "SLTU");
        test_alu_operation(4'b0011, 32'hFFFFFFFF, 32'h00000001, 32'h00000000, "SLTU");
        test_alu_operation(4'b0011, 32'h00000001, 32'hFFFFFFFF, 32'h00000001, "SLTU");
        
        $display("========================================");
        $display("ALU Test Results: %0d/%0d tests passed", pass_count, test_count);
        if (pass_count == test_count) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        $display("========================================");
        
        $finish;
    end

endmodule