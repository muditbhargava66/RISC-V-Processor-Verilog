`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/18 17:44:09
// Design Name: 
// Module Name: imm_gen_tb
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
module imm_gen_tb;

  reg [31:0] instruction;
  wire [31:0] imm_ext;

  imm_gen u_imm_gen (
    .instruction(instruction),
    .imm_ext(imm_ext)
  );

  initial begin
    // LUI
    instruction = 32'b100000000001_10000_100_00000_0110111;
    #10;
    if (imm_ext !== {instruction[31:12], 12'b0})
      $fatal("Test Case failed for LUI!");

    // AUIPC
    instruction = 32'b100000000000_10000_100_00000_0010111;
    #10;
    if (imm_ext !== {instruction[31:12], 12'b0})
      $fatal("Test Case failed for AUIPC!");

    // JAL
    instruction = 32'b111111111111_11111_111_00000_1101111;
    #10;
    if (imm_ext !== {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0})
      $fatal("Test Case failed for JAL!");

    // JALR
    instruction = 32'b100000000000_00000_000_00000_1100111;
    #10;
    if (imm_ext !== {{21{instruction[31]}}, instruction[30:20]})
      $fatal("Test Case failed for JALR!");

    // BTYPE
    instruction = 32'b1000001_00000_00000_000_10001_1100011;
    #10;
    if (imm_ext !== {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0})
      $fatal("Test Case failed for BTYPE!");

    // LOAD
    instruction = 32'b000000000001_00001_001_00000_0000011;
    #10;
    if (imm_ext !== {{21{instruction[31]}}, instruction[30:20]})
      $fatal("Test Case failed for LOAD!");

    // STYPE
    instruction = 32'b1000001_00000_00000_000_10001_0100011;
    #10;
    if (imm_ext !== {{21{instruction[31]}}, instruction[30:25], instruction[11:7]})
      $fatal("Test Case failed for STYPE!");

    // ITYPE_ALU
    instruction = 32'b000000000001_00001_001_00000_0010011;
    #10;
    if (imm_ext !== {{21{instruction[31]}}, instruction[30:20]})
      $fatal("Test Case failed for ITYPE_ALU!");

    $display("All test cases passed successfully!");
    $finish;
  end

endmodule
