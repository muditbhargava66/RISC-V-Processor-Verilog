`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2021 12:11:52 PM
// Design Name: 
// Module Name: instr_mem
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
module instr_mem (
    input wire clk,
    input wire [8:0] addr,
    input wire instr_en,
    output reg [31:0] instr_out
);

parameter Depth = 512;
(*rom_style="block"*) reg [31:0] imem [0:Depth-1];

initial begin
    $readmemh("imem.txt", imem);
end

always @(posedge clk) begin
    if (instr_en)
        instr_out <= imem[addr];
end

endmodule