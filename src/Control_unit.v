// Control Unit Module
// Generates control signals for all RV32I instructions

module control_unit (
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
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

    // ALU operation codes
    localparam [3:0] ALU_ADD  = 4'b0000;
    localparam [3:0] ALU_SUB  = 4'b1000;
    localparam [3:0] ALU_AND  = 4'b0111;
    localparam [3:0] ALU_OR   = 4'b0110;
    localparam [3:0] ALU_XOR  = 4'b0100;
    localparam [3:0] ALU_SLL  = 4'b0001;
    localparam [3:0] ALU_SRL  = 4'b0101;
    localparam [3:0] ALU_SRA  = 4'b1101;
    localparam [3:0] ALU_SLT  = 4'b0010;
    localparam [3:0] ALU_SLTU = 4'b0011;

    always @(*) begin
        // Default values
        reg_write = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        branch = 1'b0;
        jump = 1'b0;
        alu_src = 2'b00;
        alu_op = ALU_ADD;
        reg_write_src = 2'b00;

        case (opcode)
            OPCODE_R_TYPE: begin
                reg_write = 1'b1;
                alu_src = 2'b00; // Register
                reg_write_src = 2'b00; // ALU result
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: alu_op = ALU_ADD;  // ADD
                    {7'b0100000, 3'b000}: alu_op = ALU_SUB;  // SUB
                    {7'b0000000, 3'b001}: alu_op = ALU_SLL;  // SLL
                    {7'b0000000, 3'b010}: alu_op = ALU_SLT;  // SLT
                    {7'b0000000, 3'b011}: alu_op = ALU_SLTU; // SLTU
                    {7'b0000000, 3'b100}: alu_op = ALU_XOR;  // XOR
                    {7'b0000000, 3'b101}: alu_op = ALU_SRL;  // SRL
                    {7'b0100000, 3'b101}: alu_op = ALU_SRA;  // SRA
                    {7'b0000000, 3'b110}: alu_op = ALU_OR;   // OR
                    {7'b0000000, 3'b111}: alu_op = ALU_AND;  // AND
                    default: alu_op = ALU_ADD;
                endcase
            end

            OPCODE_I_TYPE: begin
                reg_write = 1'b1;
                alu_src = 2'b01; // Immediate
                reg_write_src = 2'b00; // ALU result
                case (funct3)
                    3'b000: alu_op = ALU_ADD;  // ADDI
                    3'b010: alu_op = ALU_SLT;  // SLTI
                    3'b011: alu_op = ALU_SLTU; // SLTIU
                    3'b100: alu_op = ALU_XOR;  // XORI
                    3'b110: alu_op = ALU_OR;   // ORI
                    3'b111: alu_op = ALU_AND;  // ANDI
                    3'b001: alu_op = ALU_SLL;  // SLLI
                    3'b101: begin
                        if (funct7[5]) alu_op = ALU_SRA; // SRAI
                        else alu_op = ALU_SRL;           // SRLI
                    end
                    default: alu_op = ALU_ADD;
                endcase
            end

            OPCODE_LOAD: begin
                reg_write = 1'b1;
                mem_read = 1'b1;
                alu_src = 2'b01; // Immediate
                alu_op = ALU_ADD;
                reg_write_src = 2'b01; // Memory data
            end

            OPCODE_STORE: begin
                mem_write = 1'b1;
                alu_src = 2'b01; // Immediate
                alu_op = ALU_ADD;
            end

            OPCODE_BRANCH: begin
                branch = 1'b1;
                alu_src = 2'b00; // Register
                case (funct3)
                    3'b000: alu_op = ALU_SUB;  // BEQ
                    3'b001: alu_op = ALU_SUB;  // BNE
                    3'b100: alu_op = ALU_SLT;  // BLT
                    3'b101: alu_op = ALU_SLT;  // BGE
                    3'b110: alu_op = ALU_SLTU; // BLTU
                    3'b111: alu_op = ALU_SLTU; // BGEU
                    default: alu_op = ALU_SUB;
                endcase
            end

            OPCODE_JAL: begin
                reg_write = 1'b1;
                jump = 1'b1;
                reg_write_src = 2'b10; // PC + 4
            end

            OPCODE_JALR: begin
                reg_write = 1'b1;
                jump = 1'b1;
                alu_src = 2'b01; // Immediate
                alu_op = ALU_ADD;
                reg_write_src = 2'b10; // PC + 4
            end

            OPCODE_LUI: begin
                reg_write = 1'b1;
                reg_write_src = 2'b11; // Immediate
            end

            OPCODE_AUIPC: begin
                reg_write = 1'b1;
                alu_src = 2'b10; // PC
                alu_op = ALU_ADD;
                reg_write_src = 2'b00; // ALU result
            end

            default: begin
                // All signals remain at default values
            end
        endcase
    end

endmodule