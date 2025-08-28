// Instruction Memory Module
// 1KB instruction memory with test program

module instruction_memory (
    input wire [31:0] address,
    output wire [31:0] instruction
);

    // Instruction memory - 1KB (256 words)
    reg [31:0] memory [0:255];
    
    // Word-aligned address (divide by 4)
    wire [7:0] word_address = address[9:2];
    
    // Initialize memory from file
    initial begin
        $readmemh("instruction_memory.hex", memory);
    end
    
    assign instruction = memory[word_address];

endmodule