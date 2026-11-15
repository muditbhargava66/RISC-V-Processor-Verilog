`timescale 1ns / 1ps
// Instruction Memory Module
// Parameterized instruction memory with configurable depth and initialization file
// SystemVerilog implementation
//
// Memory map: 2**ADDR_WIDTH words of 32 bits, word-addressed via address[ADDR_WIDTH+1:2].
// With the default ADDR_WIDTH=8 this is 256 words = 1 KB (byte addresses 0x000..0x3FF).
// Fetch addresses above the space wrap (only the low address bits are decoded); the
// core's PC word-alignment assertion catches misaligned fetches during simulation.

module instruction_memory #(
    parameter int ADDR_WIDTH = 8,              // Number of bits for word address (default 256 words = 1KB)
    parameter INIT_FILE = "instruction_memory.hex"  // Memory initialization file (untyped for tool portability)
)(
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    localparam int MEM_DEPTH = 2**ADDR_WIDTH;
    logic [31:0] memory [0:MEM_DEPTH-1];

    // Word-aligned address (divide by 4)
    logic [ADDR_WIDTH-1:0] word_address;
    assign word_address = address[ADDR_WIDTH+1:2];

    integer i;

    // Initialize memory from file
    initial begin
        // Initialize all memory to 0 first
        for (i = 0; i < MEM_DEPTH; i++) begin
            memory[i] = 32'h00000000;
        end
        // Then load the program file
        $readmemh(INIT_FILE, memory);
    end

    assign instruction = memory[word_address];

endmodule
