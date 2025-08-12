// Memory Modules Testbench
// Tests instruction and data memory functionality

`timescale 1ns / 1ps

module memory_tb;

    // Clock for data memory
    reg clk;
    
    // Instruction memory signals
    reg [31:0] imem_address;
    wire [31:0] instruction;
    
    // Data memory signals
    reg mem_read;
    reg mem_write;
    reg [31:0] dmem_address;
    reg [31:0] write_data;
    reg [2:0] funct3;
    wire [31:0] read_data;
    
    integer test_count = 0;
    integer pass_count = 0;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // DUT instantiations
    instruction_memory imem (
        .address(imem_address),
        .instruction(instruction)
    );
    
    data_memory dmem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .address(dmem_address),
        .write_data(write_data),
        .funct3(funct3),
        .read_data(read_data)
    );
    
    // Test task for instruction memory
    task test_instruction_memory;
        input [31:0] addr;
        input [31:0] expected_inst;
        input [79:0] test_name;
        begin
            imem_address = addr;
            #1; // Combinational delay
            
            test_count = test_count + 1;
            if (instruction == expected_inst) begin
                pass_count = pass_count + 1;
                $display("PASS: %s | Addr=%08h Inst=%08h", test_name, addr, instruction);
            end else begin
                $display("FAIL: %s | Addr=%08h Expected=%08h Got=%08h", 
                        test_name, addr, expected_inst, instruction);
            end
        end
    endtask
    
    // Test task for data memory
    task test_data_memory;
        input [31:0] addr;
        input [31:0] wr_data;
        input [2:0] f3;
        input [31:0] expected_rd_data;
        input [79:0] test_name;
        begin
            // Write operation
            @(posedge clk);
            mem_write = 1;
            mem_read = 0;
            dmem_address = addr;
            write_data = wr_data;
            funct3 = f3;
            
            @(posedge clk);
            mem_write = 0;
            
            // Read operation
            mem_read = 1;
            #1; // Combinational delay
            
            test_count = test_count + 1;
            if (read_data == expected_rd_data) begin
                pass_count = pass_count + 1;
                $display("PASS: %s | Addr=%08h Data=%08h", test_name, addr, read_data);
            end else begin
                $display("FAIL: %s | Addr=%08h Expected=%08h Got=%08h", 
                        test_name, addr, expected_rd_data, read_data);
            end
            
            mem_read = 0;
        end
    endtask
    
    initial begin
        $display("========================================");
        $display("Memory Modules Comprehensive Test");
        $display("========================================");
        
        // Initialize
        mem_read = 0;
        mem_write = 0;
        dmem_address = 0;
        write_data = 0;
        funct3 = 0;
        imem_address = 0;
        
        @(posedge clk);
        
        // Test Instruction Memory
        $display("--- Testing Instruction Memory ---");
        test_instruction_memory(32'h00000000, 32'h00000013, "First instruction (NOP)");
        test_instruction_memory(32'h00000004, 32'h00100093, "Second instruction (ADDI x1, x0, 1)");
        test_instruction_memory(32'h00000008, 32'h00200113, "Third instruction (ADDI x2, x0, 2)");
        test_instruction_memory(32'h0000000C, 32'h002081B3, "Fourth instruction (ADD x3, x1, x2)");
        
        // Test word-aligned addresses
        test_instruction_memory(32'h00000010, 32'h40208233, "Fifth instruction");
        test_instruction_memory(32'h00000048, 32'h00300513, "Branch target instruction");
        
        $display("");
        
        // Test Data Memory
        $display("--- Testing Data Memory ---");
        
        // Test word operations (SW/LW)
        test_data_memory(32'h00000000, 32'h12345678, 3'b010, 32'h12345678, "Word write/read");
        test_data_memory(32'h00000004, 32'hDEADBEEF, 3'b010, 32'hDEADBEEF, "Word write/read 2");
        
        // Test halfword operations (SH/LH)
        test_data_memory(32'h00000008, 32'h0000ABCD, 3'b001, 32'hFFFFABCD, "Halfword write/read (signed)");
        test_data_memory(32'h0000000A, 32'h00001234, 3'b001, 32'h00001234, "Halfword write/read (positive)");
        
        // Test halfword unsigned (LHU)
        @(posedge clk);
        mem_write = 1;
        dmem_address = 32'h0000000C;
        write_data = 32'h0000FFFF;
        funct3 = 3'b001; // SH
        @(posedge clk);
        mem_write = 0;
        mem_read = 1;
        funct3 = 3'b101; // LHU
        #1;
        test_count = test_count + 1;
        if (read_data == 32'h0000FFFF) begin
            pass_count = pass_count + 1;
            $display("PASS: Halfword unsigned read | Data=%08h", read_data);
        end else begin
            $display("FAIL: Halfword unsigned read | Expected=0000FFFF Got=%08h", read_data);
        end
        mem_read = 0;
        
        // Test byte operations (SB/LB)
        test_data_memory(32'h00000010, 32'h000000FF, 3'b000, 32'hFFFFFFFF, "Byte write/read (signed -1)");
        test_data_memory(32'h00000011, 32'h0000007F, 3'b000, 32'h0000007F, "Byte write/read (positive)");
        
        // Test byte unsigned (LBU)
        @(posedge clk);
        mem_write = 1;
        dmem_address = 32'h00000012;
        write_data = 32'h000000FF;
        funct3 = 3'b000; // SB
        @(posedge clk);
        mem_write = 0;
        mem_read = 1;
        funct3 = 3'b100; // LBU
        #1;
        test_count = test_count + 1;
        if (read_data == 32'h000000FF) begin
            pass_count = pass_count + 1;
            $display("PASS: Byte unsigned read | Data=%08h", read_data);
        end else begin
            $display("FAIL: Byte unsigned read | Expected=000000FF Got=%08h", read_data);
        end
        mem_read = 0;
        
        // Test different byte positions
        $display("--- Testing Byte Positioning ---");
        for (integer i = 0; i < 4; i = i + 1) begin
            @(posedge clk);
            mem_write = 1;
            dmem_address = 32'h00000020 + i;
            write_data = 32'h000000A0 + i;
            funct3 = 3'b000; // SB
            @(posedge clk);
            mem_write = 0;
            mem_read = 1;
            funct3 = 3'b100; // LBU
            #1;
            $display("Byte position %0d: Wrote %02h, Read %08h", i, 8'hA0 + i, read_data);
            mem_read = 0;
        end
        
        $display("========================================");
        $display("Memory Test Results: %0d/%0d tests passed", pass_count, test_count);
        if (pass_count == test_count) begin
            $display("ALL MEMORY TESTS PASSED!");
        end else begin
            $display("SOME MEMORY TESTS FAILED!");
        end
        $display("========================================");
        
        $finish;
    end

endmodule