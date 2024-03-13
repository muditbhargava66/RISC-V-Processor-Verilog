`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/12 00:51:03
// Design Name: 
// Module Name: alu
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
//last change: 2021/11/12 18:00 by lzy 
module alu (
    input wire [3:0] alu_op,
    input wire [31:0] operand1,
    input wire [31:0] operand2,
    output reg [31:0] alu_out
);

wire [31:0] alu_sll;
wire less_than;
wire u_less_than;
wire [31:0] alu_xor;
wire [31:0] alu_sra;
wire [31:0] alu_or;
wire [31:0] alu_and;
wire [31:0] shift_out;
wire [31:0] add_out;

assign alu_sll = operand1 << operand2[4:0];
assign less_than = $signed(operand1) < $signed(operand2);
assign u_less_than = operand1 < operand2;
assign alu_xor = operand1 ^ operand2;
assign alu_sra = $signed(operand1) >>> operand2[4:0];
assign alu_or = operand1 | operand2;
assign alu_and = operand1 & operand2;

assign add_out = (alu_op == 4'b1000) ? operand1 - operand2 : operand1 + operand2;

shifter u_shifter (
    .data(operand1),
    .direction(alu_op == 4'b0001),
    .shift(operand2[4:0]),
    .shift_out(shift_out)
);

always @(*) begin
    case (alu_op)
        4'b0000: alu_out = add_out;
        4'b1000: alu_out = add_out;
        4'b0001: alu_out = shift_out;
        4'b0010: alu_out = less_than;
        4'b0011: alu_out = u_less_than;
        4'b0100: alu_out = alu_xor;
        4'b0101: alu_out = shift_out;
        4'b1101: alu_out = alu_sra;
        4'b0110: alu_out = alu_or;
        4'b0111: alu_out = alu_and;
        default: alu_out = 32'b0;
    endcase
end

//SVA
// sequence s0;
// alu_op == 4'b1000 ? add_out == operand1 - operand2 : add_out == operand1 + operand2;
// endsequence

// property p0;
// @(posedge clk) s0;
// endproperty

// alu0: assert property (p0);


endmodule
