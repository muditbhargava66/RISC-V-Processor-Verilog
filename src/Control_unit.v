module control_unit (
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg branch,
    output reg jump,
    output reg [1:0] alu_src,
    output reg [3:0] alu_op,
    output reg [1:0] reg_write_src
);

    // RISC-V opcodes
    localparam [6:0] OPCODE_R_TYPE  = 7'b0110011;
    localparam [6:0] OPCODE_I_TYPE  = 7'b0010011;
    localparam [6:0] OPCODE_LOAD    = 7'b0000011;
    localparam [6:0] OPCODE_STORE   = 7'b0100011;
    localparam [6:0] OPCODE_BRANCH  = 7'b1100011;
    localparam [6:0] OPCODE_JAL     = 7'b1101111;
    localparam [6:0] OPCODE_JALR    = 7'b1100111;
    localparam [6:0] OPCODE_LUI     = 7'b0110111;
    localparam [6:0] OPCODE_AUIPC   = 7'b0010111;

    always @(*) begin
        // Default values
        reg_write = 0;
        mem_read = 0;
        mem_write = 0;
        branch = 0;
        jump = 0;
        alu_src = 2'b00;
        alu_op = 4'b0000;
        reg_write_src = 2'b00;
        
        case (opcode)
            OPCODE_R_TYPE: begin
                reg_write = 1;
                alu_src = 2'b00; // Register
                reg_write_src = 2'b00; // ALU result
                
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: alu_op = 4'b0000; // ADD
                    {7'b0100000, 3'b000}: alu_op = 4'b1000; // SUB
                    {7'b0000000, 3'b001}: alu_op = 4'b0001; // SLL
                    {7'b0000000, 3'b010}: alu_op = 4'b0010; // SLT
                    {7'b0000000, 3'b011}: alu_op = 4'b0011; // SLTU
                    {7'b0000000, 3'b100}: alu_op = 4'b0100; // XOR
                    {7'b0000000, 3'b101}: alu_op = 4'b0101; // SRL
                    {7'b0100000, 3'b101}: alu_op = 4'b1101; // SRA
                    {7'b0000000, 3'b110}: alu_op = 4'b0110; // OR
                    {7'b0000000, 3'b111}: alu_op = 4'b0111; // AND
                    default: alu_op = 4'b0000;
                endcase
            end
            
            OPCODE_I_TYPE: begin
                reg_write = 1;
                alu_src = 2'b01; // Immediate
                reg_write_src = 2'b00; // ALU result
                
                case (funct3)
                    3'b000: alu_op = 4'b0000; // ADDI
                    3'b010: alu_op = 4'b0010; // SLTI
                    3'b011: alu_op = 4'b0011; // SLTIU
                    3'b100: alu_op = 4'b0100; // XORI
                    3'b110: alu_op = 4'b0110; // ORI
                    3'b111: alu_op = 4'b0111; // ANDI
                    3'b001: alu_op = 4'b0001; // SLLI
                    3'b101: begin
                        if (funct7[5]) alu_op = 4'b1101; // SRAI
                        else alu_op = 4'b0101; // SRLI
                    end
                    default: alu_op = 4'b0000;
                endcase
            end
            
            OPCODE_LOAD: begin
                reg_write = 1;
                mem_read = 1;
                alu_src = 2'b01; // Immediate
                alu_op = 4'b0000; // ADD for address calculation
                reg_write_src = 2'b01; // Memory data
            end
            
            OPCODE_STORE: begin
                mem_write = 1;
                alu_src = 2'b01; // Immediate
                alu_op = 4'b0000; // ADD for address calculation
            end
            
            OPCODE_BRANCH: begin
                branch = 1;
                alu_src = 2'b00; // Register
                case (funct3)
                    3'b000, 3'b001: alu_op = 4'b1000; // BEQ, BNE (SUB)
                    3'b100, 3'b101: alu_op = 4'b0010; // BLT, BGE (SLT)
                    3'b110, 3'b111: alu_op = 4'b0011; // BLTU, BGEU (SLTU)
                    default: alu_op = 4'b1000;
                endcase
            end
            
            OPCODE_JAL: begin
                reg_write = 1;
                jump = 1;
                alu_src = 2'b10; // PC
                alu_op = 4'b0000; // ADD
                reg_write_src = 2'b10; // PC+4
            end
            
            OPCODE_JALR: begin
                reg_write = 1;
                jump = 1;
                alu_src = 2'b01; // Immediate
                alu_op = 4'b0000; // ADD
                reg_write_src = 2'b10; // PC+4
            end
            
            OPCODE_LUI: begin
                reg_write = 1;
                alu_src = 2'b01; // Immediate
                alu_op = 4'b0110; // OR (pass through)
                reg_write_src = 2'b00; // ALU result
            end
            
            OPCODE_AUIPC: begin
                reg_write = 1;
                alu_src = 2'b10; // PC
                alu_op = 4'b0000; // ADD
                reg_write_src = 2'b00; // ALU result
            end
            
            default: begin
                // Safe defaults for invalid opcodes
                reg_write = 0;
                mem_read = 0;
                mem_write = 0;
                branch = 0;
                jump = 0;
                alu_src = 2'b00;
                alu_op = 4'b0000;
                reg_write_src = 2'b00;
            end
        endcase
    end

endmodule