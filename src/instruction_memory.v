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
    
    // Initialize with test program
    integer i;
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
        memory[8] = 32'h00209393;  // SLLI x7, x1, 2
        memory[9] = 32'h0020D413;  // SRLI x8, x1, 2
        memory[10] = 32'h00000463; // BEQ x0, x0, 8 (branch to address 18)
        memory[11] = 32'h00100493; // ADDI x9, x0, 1 (should be skipped)
        memory[12] = 32'h00200513; // ADDI x10, x0, 2 (should be skipped)
        memory[13] = 32'h00000013; // NOP
        memory[14] = 32'h00000013; // NOP
        memory[15] = 32'h00000013; // NOP
        memory[16] = 32'h00000013; // NOP
        memory[17] = 32'h00000013; // NOP
        memory[18] = 32'h00300513; // ADDI x10, x0, 3 (branch target)
        memory[19] = 32'h00000013; // NOP
        
        // Initialize rest to NOP
        for (i = 20; i < 256; i = i + 1) begin
            memory[i] = 32'h00000013; // NOP
        end
    end
    
    assign instruction = memory[word_address];

endmodule