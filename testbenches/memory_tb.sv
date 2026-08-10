// Memory Modules Testbench
// Tests instruction and data memory functionality
// SystemVerilog implementation

`timescale 1ns / 1ps

module memory_tb;

    // Clock for data memory
    logic clk;
    logic reset;

    // Instruction memory signals
    logic [31:0] imem_address;
    logic [31:0] instruction;

    // Data memory signals
    logic        mem_read;
    logic        mem_write;
    logic [31:0] dmem_address;
    logic [31:0] write_data;
    logic [2:0]  funct3;
    logic [31:0] read_data;

    int test_count = 0;
    int pass_count = 0;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // DUT instantiations
    instruction_memory imem (
        .address    (imem_address),
        .instruction(instruction)
    );

    data_memory dmem (
        .clk        (clk),
        .reset      (reset),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .address    (dmem_address),
        .write_data (write_data),
        .funct3     (funct3),
        .read_data  (read_data)
    );

    // Test task for instruction memory
    task automatic test_instruction_memory(
        input logic [31:0] addr,
        input logic [31:0] expected_inst,
        input string test_name
    );
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
    task automatic test_data_memory(
        input logic [31:0] addr,
        input logic [31:0] wr_data,
        input logic [2:0]  f3,
        input logic [31:0] expected_rd_data,
        input string test_name
    );
    begin
        // Write operation
        mem_write = 1;
        mem_read = 0;
        dmem_address = addr;
        write_data = wr_data;
        funct3 = f3;
        @(posedge clk);
        // write captured on this edge
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

        // Reset sequence
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        reset = 0;

        @(posedge clk);

        // Test Instruction Memory
        $display("--- Testing Instruction Memory ---");
        test_instruction_memory(32'h00000000, 32'hDEAD00B7, "First instruction (LUI x1, 0xDEAD0)");
        test_instruction_memory(32'h00000004, 32'h23408093, "Second instruction (ADDI x1, x1, 0x234)");
        test_instruction_memory(32'h00000008, 32'h00102023, "Third instruction (SW x1, 0(x2))");
        test_instruction_memory(32'h0000000C, 32'h00002103, "Fourth instruction (LW x2, 0(x0))");

        // Test word-aligned addresses
        test_instruction_memory(32'h00000010, 32'hFFF00193, "Fifth instruction (ADDI x3, x0, -16)");
        test_instruction_memory(32'h00000014, 32'h00100213, "Sixth instruction (ADDI x4, x0, 1)");
        test_instruction_memory(32'h00000018, 32'h0041C263, "Branch instruction (BLT x3, x1, ...)");
        test_instruction_memory(32'h0000001C, 32'h000002B3, "ADD x5, x0, x0");
        test_instruction_memory(32'h00000020, 32'h004202B3, "ADD x5, x4, x0");
        test_instruction_memory(32'h00000024, 32'h0041D263, "Branch instruction (BGE x3, x1, ...)");
        test_instruction_memory(32'h00000028, 32'h00420333, "ADD x6, x4, x0");
        test_instruction_memory(32'h0000002C, 32'h00000013, "NOP");

        $display("");

        // Test Data Memory
        $display("--- Testing Data Memory ---");

        // Test word operations (SW/LW)
        test_data_memory(32'h00000000, 32'h12345678, 3'b010, 32'h12345678, "Word write/read");
        test_data_memory(32'h00000004, 32'hDEADBEEF, 3'b010, 32'hDEADBEEF, "Word write/read 2");

        // Test halfword operations (SH/LH)
        test_data_memory(32'h00000008, 32'h0000ABCD, 3'b001, 32'hFFFFABCD, "Halfword write/read (signed)");
        test_data_memory(32'h0000000A, 32'h00001234, 3'b001, 32'h00001234, "Halfword write/read (positive)");

        // Test byte operations (SB/LB)
        test_data_memory(32'h00000010, 32'h000000FF, 3'b000, 32'hFFFFFFFF, "Byte write/read (signed -1)");
        test_data_memory(32'h00000011, 32'h0000007F, 3'b000, 32'h0000007F, "Byte write/read (positive)");

        // Test different byte positions using word stores
        $display("--- Testing Byte Positioning (via word stores) ---");
        for (int i = 0; i < 4; i++) begin
            @(posedge clk);
            mem_write = 1;
            dmem_address = 32'h00000020 + (i * 4);
            write_data = {24'h000000, 8'hA0 + i};
            funct3 = 3'b010; // SW
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