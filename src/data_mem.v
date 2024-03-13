`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2021 12:59:42 PM
// Design Name: 
// Module Name: data_mem
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
module data_mem (
    input wire clk,
    input wire [9:0] dmem_addr,
    input wire [3:0] we, //0001--SB, 0011--SH, 1111--SW, 0000--write disable
    input wire re,
    input wire [31:0] dmem_in,
    output reg [31:0] dmem_out
);

parameter depth = 1024;
reg [31:0] dmem [0:depth-1];
reg [31:0] rom [0:7];

initial begin
    rom[0] = 32'h11311762;
    rom[1] = 32'h19816562;
    rom[2] = 32'h17003972;
end

initial begin
    $readmemh("dmem_zeros.txt", dmem);
end

always @(posedge clk) begin
    if (we != 4'b0000) begin
        case (we)
            4'b0001: dmem[dmem_addr][7:0] <= dmem_in[7:0];
            4'b0011: dmem[dmem_addr][15:0] <= dmem_in[15:0];
            4'b1111: dmem[dmem_addr] <= dmem_in;
            default: ;
        endcase
    end
    
    if (re) begin
        dmem_out <= dmem[dmem_addr];
    end
end

// //SVA
// sequence s0;
// dmem_out_tmp == dmem[dmem_addr];
// endsequence
// property p0;
// @(posedge clk) s0;
// endproperty
// dmem0: assert property (p0);


endmodule
