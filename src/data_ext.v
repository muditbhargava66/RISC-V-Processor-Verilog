`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/29 14:37:32
// Design Name: 
// Module Name: data_ext
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
module data_ext (
    input wire [31:0] data_in,
    input wire [2:0] funct3,
    output reg [31:0] data_out
);

always @(*) begin
    case (funct3)
        3'b000: data_out = {{24{data_in[7]}}, data_in[7:0]}; // LB
        3'b001: data_out = {{16{data_in[15]}}, data_in[15:0]}; // LH
        3'b100: data_out = {24'b0, data_in[7:0]}; // LBU
        3'b101: data_out = {16'b0, data_in[15:0]}; // LHU
        default: data_out = data_in; // LW
    endcase
end

endmodule