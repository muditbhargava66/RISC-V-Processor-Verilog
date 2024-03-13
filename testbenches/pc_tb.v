`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2021 11:13:36 PM
// Design Name: 
// Module Name: pc_tb
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
module pc_tb;

  reg [31:0] imm = 32'h8;
  reg pc_en = 0;
  reg clk = 0;
  reg rst;

  wire [31:0] pc;
  wire [31:0] pc_imm;
  wire [31:0] pc_add4;

  parameter PERIOD = 50;

  PC u_PC (
    .clk(clk),
    .rst(rst),
    .en(pc_en),
    .pc_tmp(pc_in),
    .pc(pc)
  );

  pc_adder u_pc_adder (
    .pc(pc),
    .imm(imm),
    .pc_imm(pc_imm),
    .pc_add4(pc_add4)
  );

  // Clock generation
  always begin
    clk = ~clk;
    #(PERIOD/2);
  end

  // Testbench stimulus
  initial begin
    pc_en = 1;
    rst = 0;
    #1;
    rst = 1;
    #500;
    rst = 0;
    #10;
    rst = 1;
    #500;
    $finish;
  end

  // Input to PC module
  // wire [31:0] pc_in;
  assign pc_in = pc_add4;

endmodule