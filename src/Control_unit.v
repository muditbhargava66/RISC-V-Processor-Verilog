`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/18 16:03:55
// Design Name: 
// Module Name: Control_unit - Behavioral
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
module Control_unit (
    input wire clk,
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    output reg Branch,
    output reg Jump,
    output reg MemRead,
    output reg [1:0] MemtoReg,
    output reg [3:0] MemWrite,
    output reg PCsrc,
    output reg ALUSrc,
    output reg RegWrite,
    output reg pc_en,
    output reg instr_en
);

parameter [2:0] INIT = 3'b000, InstF = 3'b001, ID = 3'b010, MEM = 3'b011, WB = 3'b100, STOP = 3'b101;

reg [2:0] state, nextstate;

always @(posedge clk) begin
    state <= nextstate;
end

always @(*) begin
    case (state)
        INIT: nextstate = InstF;
        InstF: nextstate = ID;
        ID: nextstate = (opcode == 7'b1110011) ? STOP : MEM;
        MEM: nextstate = WB;
        WB: nextstate = InstF;
        STOP: nextstate = STOP;
        default: nextstate = INIT;
    endcase
end

always @(*) begin
    case (nextstate)
        InstF: begin
            Branch = (opcode == 7'b1100011) ? 1'b1 : 1'b0;
            Jump = 1'b0;
            PCsrc = 1'b0;
            MemRead = 1'b0;
            MemtoReg = 2'b00;
            MemWrite = 4'b0000;
            ALUSrc = 1'b0;
            RegWrite = 1'b0;
            pc_en = 1'b0;
            instr_en = 1'b1;
        end
        ID: begin
            instr_en = 1'b0;
            case (opcode)
                7'b0110011, 7'b0010011, 7'b0110111, 7'b0010111, 7'b1101111, 7'b1100111, 7'b1100011, 7'b0000011, 7'b0100011, 7'b0001111: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b00;
                    MemWrite = 4'b0000;
                    ALUSrc = (opcode == 7'b0110011) ? 1'b0 : 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b0;
                end
                default: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b0;
                end
            endcase
        end
        MEM: begin
            instr_en = 1'b0;
            case (opcode)
                7'b0110011, 7'b0010011: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b00;
                    MemWrite = 4'b0000;
                    ALUSrc = (opcode == 7'b0110011) ? 1'b0 : 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b0;
                end
                7'b0110111: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b10;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b0;
                end
                7'b0010111: begin
                    Branch = 1'b0;
                    Jump = 1'b1;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b1;
                    pc_en = 1'b0;
                end
                7'b1101111: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b1;
                    pc_en = 1'b0;
                end
                7'b1100111: begin
                    Branch = 1'b0;
                    Jump = 1'b1;
                    PCsrc = 1'b1;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b0;
                end
                7'b1100011: begin
                    Branch = 1'b1;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b0;
                    RegWrite = 1'b0;
                    pc_en = 1'b0;
                end
                7'b0000011: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b1;
                    MemtoReg = 2'b01;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b0;
                end
                7'b0100011: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = (funct3 == 3'b000) ? 4'b0001 :
                               (funct3 == 3'b001) ? 4'b0011 :
                               (funct3 == 3'b010) ? 4'b1111 : 4'b1111;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b0;
                end
                7'b0001111: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b0;
                end
                default: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b0;
                end
            endcase
        end
        WB: begin
            instr_en = 1'b0;
            case (opcode)
                7'b0110011, 7'b0010011, 7'b0110111, 7'b0000011: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = (opcode == 7'b0000011) ? 2'b01 : 
                               (opcode == 7'b0110111) ? 2'b10 : 2'b00;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b1;
                    pc_en = 1'b1;
                end
                7'b0010111: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b1;
                end
                7'b1101111: begin
                    Branch = 1'b0;
                    Jump = 1'b1;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b1;
                end
                7'b1100111: begin
                    Branch = 1'b0;
                    Jump = 1'b1;
                    PCsrc = 1'b1;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b1;
                    pc_en = 1'b1;
                end
                7'b1100011: begin
                    Branch = 1'b1;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b0;
                    RegWrite = 1'b0;
                    pc_en = 1'b1;
                end
                7'b0100011: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b1;
                end
                7'b0001111: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b1;
                end
                default: begin
                    Branch = 1'b0;
                    Jump = 1'b0;
                    PCsrc = 1'b0;
                    MemRead = 1'b0;
                    MemtoReg = 2'b11;
                    MemWrite = 4'b0000;
                    ALUSrc = 1'b1;
                    RegWrite = 1'b0;
                    pc_en = 1'b0;
                end
            endcase
        end
        default: begin
            instr_en = 1'b0;
            Branch = 1'b0;
            Jump = 1'b0;
            PCsrc = 1'b0;
            MemRead = 1'b0;
            MemtoReg = 2'b00;
            MemWrite = 4'b0000;
            ALUSrc = 1'b0;
            RegWrite = 1'b0;
            pc_en = 1'b0;
        end
    endcase
end

endmodule