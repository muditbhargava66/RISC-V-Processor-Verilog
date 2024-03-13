`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/12/2024 10:42:48 PM
// Design Name: 
// Module Name: ALU_control - Behavioral
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module ALU_control (
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire inst30,
    output reg [3:0] ALU_op
);

always @(*) begin
    case (opcode)
        7'b0110011: // R-type: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND. I-type: SLLI, SRLI, SRAI
            ALU_op = {inst30, funct3};
        7'b0010011: // I-type: ADDI, SLTI, SLTIU, XORI, ORI, ANDI
            ALU_op = {1'b0, funct3};
        7'b0110111, // I-type: LUI
        7'b0010111, // I-type: AUIPC
        7'b1101111, // UJ-type: JAL
        7'b1100111, // I-type: JALR
        7'b0000011, // I-type: LB, LH, LW, LBU, LHU
        7'b0100011, // S-type: SB, SH, SW
        7'b0001111, // fence
        7'b1110011: // ecall, ebreak
            ALU_op = 4'b0000;
        7'b1100011: begin // SB-type: BEQ, BNE, BLT, BGE, BLTU, BGEU
            case (funct3)
                3'b000, 3'b001: ALU_op = 4'b1000; // BEQ, BNE: perform sub
                3'b100, 3'b101: ALU_op = 4'b0010; // BLT, BGE: perform less than
                3'b110, 3'b111: ALU_op = 4'b0011; // BLTU, BGEU: perform unsigned less than
                default: ALU_op = 4'b0000;
            endcase
        end
        default: ALU_op = 4'b0000;
    endcase
end

endmodule