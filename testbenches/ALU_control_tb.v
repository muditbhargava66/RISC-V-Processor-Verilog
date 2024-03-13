`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/19 02:34:02
// Design Name: 
// Module Name: ALU_control_tb
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

module ALU_control_tb;

  reg [6:0] opcode = 7'd0;
  reg [2:0] funct3 = 3'd0;
  reg inst30 = 1'b0;
  wire [3:0] ALU_op;

  ALU_control u_ALU_control (
    .opcode(opcode),
    .funct3(funct3),
    .inst30(inst30),
    .ALU_op(ALU_op)
  );

  initial begin
    #1;

    // R-type instruction
    opcode = 7'b0110011;
    inst30 = 1'b1;
    funct3 = 3'b000;
    #10;
    if (ALU_op !== {inst30, funct3}) begin
      $fatal("Test Case failed for R-type instruction!");
      $finish;
    end

    // I-type instruction
    opcode = 7'b0010011;
    inst30 = 1'b1;
    funct3 = 3'b000;
    #10;
    if (ALU_op !== {1'b0, funct3}) begin
      $fatal("Test Case failed for I-type instruction!");
      $finish;
    end

    // B-type instruction (signed)
    opcode = 7'b1100011;
    inst30 = 1'b1;
    funct3 = 3'b000;
    #10;
    if (ALU_op !== 4'b1000) begin
      $fatal("Test Case failed for B-type instruction (signed)!");
      $finish;
    end

    // B-type instruction (unsigned)
    opcode = 7'b1100011;
    inst30 = 1'b1;
    funct3 = 3'b111;
    #10;
    if (ALU_op !== 4'b0011) begin
      $fatal("Test Case failed for B-type instruction (unsigned)!");
      $finish;
    end

    // Load instruction
    opcode = 7'b0000011;
    inst30 = 1'b1;
    funct3 = 3'b000;
    #10;
    if (ALU_op !== 4'b0000) begin
      $fatal("Test Case failed for Load instruction!");
      $finish;
    end

    // Store instruction
    opcode = 7'b0100011;
    inst30 = 1'b1;
    funct3 = 3'b000;
    #10;
    if (ALU_op !== 4'b0000) begin
      $fatal("Test Case failed for Store instruction!");
      $finish;
    end

    $display("All test cases passed successfully!");
    $finish;
  end

endmodule