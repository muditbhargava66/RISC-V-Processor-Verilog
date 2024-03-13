`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2021 10:18:29 AM
// Design Name: 
// Module Name: regfile
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
module regfile (
    input wire clk,
    input wire rst,
    input wire we,          // write_enable control signal
    input wire [4:0] rd_addr,
    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,
    input wire [31:0] rd_data_in,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);

reg [31:0] regfile [0:31];

integer i;

always @(posedge clk) begin
    if (!rst) begin
        for (i = 0; i < 32; i = i + 1)
            regfile[i] <= 32'b0;
    end
    else if (we && rd_addr != 5'b0)
        regfile[rd_addr] <= rd_data_in;
end

assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : regfile[rs1_addr];
assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : regfile[rs2_addr];

endmodule