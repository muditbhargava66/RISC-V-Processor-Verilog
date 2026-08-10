// Instruction Memory Module
// Parameterized instruction memory with configurable depth and initialization file
// SystemVerilog implementation

module instruction_memory #(
    parameter int ADDR_WIDTH = 8,              // Number of bits for word address (default 256 words = 1KB)
    parameter string INIT_FILE = "instruction_memory.hex"  // Memory initialization file
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