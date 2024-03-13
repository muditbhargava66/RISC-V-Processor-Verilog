`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2021 12:50:36 PM
// Design Name: 
// Module Name: pc_adder
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
module pc_adder (
    input wire [31:0] pc,
    input wire [31:0] imm,
    output wire [31:0] pc_imm,
    output wire [31:0] pc_add4
);

assign pc_imm = pc + imm;
assign pc_add4 = pc + 32'd4;

endmodule