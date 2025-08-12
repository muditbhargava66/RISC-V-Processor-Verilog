module instruction_memory (
    input [31:0] address,
    output [31:0] instruction
);

    // Instruction memory - 1KB (256 words)
    reg [31:0] memory [0:255];
    
    // Word-aligned address (divide by 4)
    wire [7:0] word_address = address[9:2];
    
    // Initialize with some basic instructions for testing
    initial begin
        // Simple test program
        memory[0] = 32'h00000013;  // NOP (ADDI x0, x0, 0)
        memory[1] = 32'h00100093;  // ADDI x1, x0, 1
        memory[2] = 32'h00200113;  // ADDI x2, x0, 2
        memory[3] = 32'h002081B3;  // ADD x3, x1, x2
        memory[4] = 32'h40208233;  // SUB x4, x1, x2
        memory[5] = 32'h0020F2B3;  // AND x5, x1, x2
        memory[6] = 32'h0020E333;  // OR x6, x1, x2
        memory[7] = 32'h0020C3B3;  // XOR x7, x1, x2
        
        // Initialize rest to NOP
        for (integer i = 8; i < 256; i = i + 1) begin
            memory[i] = 32'h00000013; // NOP
        end
    end
    
    assign instruction = memory[word_address];

endmodule