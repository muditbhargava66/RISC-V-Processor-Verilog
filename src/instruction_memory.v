// Instruction Memory Module
// Parameterized instruction memory.

module instruction_memory #(
    parameter ADDR_WIDTH = 8 // Number of bits for word address, default = 256 words
)(
    input wire [31:0] address,
    output wire [31:0] instruction
);

    // Instruction memory
    localparam MEM_DEPTH = 2**ADDR_WIDTH;
    reg [31:0] memory [0:MEM_DEPTH-1];
    
    // Word-aligned address (divide by 4)
    wire [ADDR_WIDTH-1:0] word_address = address[ADDR_WIDTH+1:2];
    
    // Initialize memory from file
    initial begin
        $readmemh("instruction_memory.hex", memory);
    end
    
    assign instruction = memory[word_address];

endmodule