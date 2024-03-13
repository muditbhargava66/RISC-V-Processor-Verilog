`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/13/2024 05:18:15 PM
// Design Name: 
// Module Name: Control_unit_tb
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
module Control_unit_testbench;

  reg clk = 0;
  reg [6:0] opcode;
  reg [2:0] funct3;
  wire Branch;
  wire Jump;
  wire MemRead;
  wire [1:0] MemtoReg;
  wire [3:0] MemWrite;
  wire PCsrc;
  wire ALUSrc;
  wire RegWrite;
  wire pc_en;

  Control_unit dut (
    .clk(clk),
    .opcode(opcode),
    .funct3(funct3),
    .Branch(Branch),
    .Jump(Jump),
    .MemRead(MemRead),
    .MemtoReg(MemtoReg),
    .MemWrite(MemWrite),
    .PCsrc(PCsrc),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite),
    .pc_en(pc_en)
  );

  always #50 clk = ~clk;

  initial begin
    #100;
    opcode = 7'b0110011; // R-type
    #400;
    opcode = 7'b0010011; // I-type (arithmetic)
    #400;
    opcode = 7'b0110111; // LUI
    #400;
    opcode = 7'b0010111; // AUIPC
    #400;
    opcode = 7'b0110111; // LUI (repeated)
    #400;
    opcode = 7'b1100111; // JALR
    #400;
    opcode = 7'b1100011; // B-type
    #400;
    opcode = 7'b0000011; // I-type (load)
    #400;
    opcode = 7'b0100011; // S-type
    #400;
    opcode = 7'b0001111; // FENCE
    #400;
    opcode = 7'b1110011; // ECALL/EBREAK
    #800;
    $finish;
  end

endmodule
