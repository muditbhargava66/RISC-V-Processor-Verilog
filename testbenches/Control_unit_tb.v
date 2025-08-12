// Control Unit Testbench
// Tests all RV32I instruction decoding

`timescale 1ns / 1ps

module control_unit_tb;

    // Testbench signals
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;
    wire reg_write;
    wire mem_read;
    wire mem_write;
    wire branch;
    wire jump;
    wire [1:0] alu_src;
    wire [3:0] alu_op;
    wire [1:0] reg_write_src;
    
    integer test_count = 0;
    integer pass_count = 0;
    
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
    
    // Test task
    task test_instruction;
        input [6:0] op;
        input [2:0] f3;
        input [6:0] f7;
        input expected_reg_write;
        input expected_mem_read;
        input expected_mem_write;
        input expected_branch;
        input expected_jump;
        input [1:0] expected_alu_src;
        input [3:0] expected_alu_op;
        input [1:0] expected_reg_write_src;
        input [79:0] inst_name;
        begin
            opcode = op;
            funct3 = f3;
            funct7 = f7;
            #10;
            
            test_count = test_count + 1;
            if (reg_write == expected_reg_write &&
                mem_read == expected_mem_read &&
                mem_write == expected_mem_write &&
                branch == expected_branch &&
                jump == expected_jump &&
                alu_src == expected_alu_src &&
                alu_op == expected_alu_op &&
                reg_write_src == expected_reg_write_src) begin
                pass_count = pass_count + 1;
                $display("PASS: %s", inst_name);
            end else begin
                $display("FAIL: %s", inst_name);
                $display("   Expected: rw=%b mr=%b mw=%b br=%b jmp=%b as=%b ao=%b rws=%b",
                        expected_reg_write, expected_mem_read, expected_mem_write,
                        expected_branch, expected_jump, expected_alu_src,
                        expected_alu_op, expected_reg_write_src);
                $display("   Got:      rw=%b mr=%b mw=%b br=%b jmp=%b as=%b ao=%b rws=%b",
                        reg_write, mem_read, mem_write, branch, jump,
                        alu_src, alu_op, reg_write_src);
            end
        end
    endtask
    
    initial begin
        $display("========================================");
        $display("Control Unit Comprehensive Test");
        $display("========================================");
        
        // R-type instructions
        test_instruction(7'b0110011, 3'b000, 7'b0000000, 1, 0, 0, 0, 0, 2'b00, 4'b0000, 2'b00, "ADD");
        test_instruction(7'b0110011, 3'b000, 7'b0100000, 1, 0, 0, 0, 0, 2'b00, 4'b1000, 2'b00, "SUB");
        test_instruction(7'b0110011, 3'b001, 7'b0000000, 1, 0, 0, 0, 0, 2'b00, 4'b0001, 2'b00, "SLL");
        test_instruction(7'b0110011, 3'b010, 7'b0000000, 1, 0, 0, 0, 0, 2'b00, 4'b0010, 2'b00, "SLT");
        test_instruction(7'b0110011, 3'b011, 7'b0000000, 1, 0, 0, 0, 0, 2'b00, 4'b0011, 2'b00, "SLTU");
        test_instruction(7'b0110011, 3'b100, 7'b0000000, 1, 0, 0, 0, 0, 2'b00, 4'b0100, 2'b00, "XOR");
        test_instruction(7'b0110011, 3'b101, 7'b0000000, 1, 0, 0, 0, 0, 2'b00, 4'b0101, 2'b00, "SRL");
        test_instruction(7'b0110011, 3'b101, 7'b0100000, 1, 0, 0, 0, 0, 2'b00, 4'b1101, 2'b00, "SRA");
        test_instruction(7'b0110011, 3'b110, 7'b0000000, 1, 0, 0, 0, 0, 2'b00, 4'b0110, 2'b00, "OR");
        test_instruction(7'b0110011, 3'b111, 7'b0000000, 1, 0, 0, 0, 0, 2'b00, 4'b0111, 2'b00, "AND");
        
        // I-type instructions
        test_instruction(7'b0010011, 3'b000, 7'b0000000, 1, 0, 0, 0, 0, 2'b01, 4'b0000, 2'b00, "ADDI");
        test_instruction(7'b0010011, 3'b010, 7'b0000000, 1, 0, 0, 0, 0, 2'b01, 4'b0010, 2'b00, "SLTI");
        test_instruction(7'b0010011, 3'b011, 7'b0000000, 1, 0, 0, 0, 0, 2'b01, 4'b0011, 2'b00, "SLTIU");
        test_instruction(7'b0010011, 3'b100, 7'b0000000, 1, 0, 0, 0, 0, 2'b01, 4'b0100, 2'b00, "XORI");
        test_instruction(7'b0010011, 3'b110, 7'b0000000, 1, 0, 0, 0, 0, 2'b01, 4'b0110, 2'b00, "ORI");
        test_instruction(7'b0010011, 3'b111, 7'b0000000, 1, 0, 0, 0, 0, 2'b01, 4'b0111, 2'b00, "ANDI");
        
        // Load instructions
        test_instruction(7'b0000011, 3'b000, 7'b0000000, 1, 1, 0, 0, 0, 2'b01, 4'b0000, 2'b01, "LB");
        test_instruction(7'b0000011, 3'b001, 7'b0000000, 1, 1, 0, 0, 0, 2'b01, 4'b0000, 2'b01, "LH");
        test_instruction(7'b0000011, 3'b010, 7'b0000000, 1, 1, 0, 0, 0, 2'b01, 4'b0000, 2'b01, "LW");
        test_instruction(7'b0000011, 3'b100, 7'b0000000, 1, 1, 0, 0, 0, 2'b01, 4'b0000, 2'b01, "LBU");
        test_instruction(7'b0000011, 3'b101, 7'b0000000, 1, 1, 0, 0, 0, 2'b01, 4'b0000, 2'b01, "LHU");
        
        // Store instructions
        test_instruction(7'b0100011, 3'b000, 7'b0000000, 0, 0, 1, 0, 0, 2'b01, 4'b0000, 2'b00, "SB");
        test_instruction(7'b0100011, 3'b001, 7'b0000000, 0, 0, 1, 0, 0, 2'b01, 4'b0000, 2'b00, "SH");
        test_instruction(7'b0100011, 3'b010, 7'b0000000, 0, 0, 1, 0, 0, 2'b01, 4'b0000, 2'b00, "SW");
        
        // Branch instructions
        test_instruction(7'b1100011, 3'b000, 7'b0000000, 0, 0, 0, 1, 0, 2'b00, 4'b1000, 2'b00, "BEQ");
        test_instruction(7'b1100011, 3'b001, 7'b0000000, 0, 0, 0, 1, 0, 2'b00, 4'b1000, 2'b00, "BNE");
        test_instruction(7'b1100011, 3'b100, 7'b0000000, 0, 0, 0, 1, 0, 2'b00, 4'b0010, 2'b00, "BLT");
        test_instruction(7'b1100011, 3'b101, 7'b0000000, 0, 0, 0, 1, 0, 2'b00, 4'b0010, 2'b00, "BGE");
        test_instruction(7'b1100011, 3'b110, 7'b0000000, 0, 0, 0, 1, 0, 2'b00, 4'b0011, 2'b00, "BLTU");
        test_instruction(7'b1100011, 3'b111, 7'b0000000, 0, 0, 0, 1, 0, 2'b00, 4'b0011, 2'b00, "BGEU");
        
        // Jump instructions
        test_instruction(7'b1101111, 3'b000, 7'b0000000, 1, 0, 0, 0, 1, 2'b00, 4'b0000, 2'b10, "JAL");
        test_instruction(7'b1100111, 3'b000, 7'b0000000, 1, 0, 0, 0, 1, 2'b01, 4'b0000, 2'b10, "JALR");
        
        // Upper immediate instructions
        test_instruction(7'b0110111, 3'b000, 7'b0000000, 1, 0, 0, 0, 0, 2'b00, 4'b0000, 2'b11, "LUI");
        test_instruction(7'b0010111, 3'b000, 7'b0000000, 1, 0, 0, 0, 0, 2'b10, 4'b0000, 2'b00, "AUIPC");
        
        $display("========================================");
        $display("Control Unit Test Results: %0d/%0d tests passed", pass_count, test_count);
        if (pass_count == test_count) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        $display("========================================");
        
        $finish;
    end

endmodule