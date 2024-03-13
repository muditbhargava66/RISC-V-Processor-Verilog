`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/12/2024 10:20:24 PM
// Design Name: 
// Module Name: processor_top
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
module processor_top (
    input clk,
    input rst
);

// Signals
wire [31:0] pc_in;
wire [31:0] pc_out;
wire [31:0] instruction;
wire instr_en;
wire [31:0] rd_data_in;
wire [31:0] rs1_data;
wire [31:0] rs2_data;
wire Branch;
wire Jump;
wire MemRead;
wire [1:0] MemtoReg;
wire [3:0] MemWrite;
wire PCsrc;
wire ALUSrc;
wire RegWrite;
wire pc_en;
wire [31:0] imm_extended;
wire [3:0] ALU_op;
wire [31:0] alu_out;
wire [31:0] operand2;
wire [31:0] dmem_out_ext;
wire [31:0] pc_imm;
wire [31:0] pc_add4;
wire [31:0] dmem_out;

// Declare next_pc as reg
reg [31:0] next_pc;

// Internal signal for rd_data_in
reg [31:0] rd_data_in_internal;

// PC
PC PC_inst (
    .clk(clk),
    .rst(rst),
    .en(pc_en),
    .pc_tmp(pc_in),
    .pc(pc_out)
);

// Instruction memory
instr_mem instr_mem_inst (
    .clk(clk),
    .instr_en(instr_en),
    .addr(pc_out[10:2]),
    .instr_out(instruction)
);

// Register file
regfile regfile_inst (
    .clk(clk),
    .rst(rst),
    .we(RegWrite),
    .rd_addr(instruction[11:7]),
    .rs1_addr(instruction[19:15]),
    .rs2_addr(instruction[24:20]),
    .rd_data_in(rd_data_in),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
);

// Control unit
Control_unit Control_unit_inst (
    .clk(clk),
    .opcode(instruction[6:0]),
    .funct3(instruction[14:12]),
    .Branch(Branch),
    .Jump(Jump),
    .MemRead(MemRead),
    .MemtoReg(MemtoReg),
    .MemWrite(MemWrite),
    .PCsrc(PCsrc),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite),
    .pc_en(pc_en),
    .instr_en(instr_en)
);

// Immediate generator
imm_gen imm_gen_inst (
    .instruction(instruction),
    .imm_ext(imm_extended)
);

// Mux for operand2
assign operand2 = ALUSrc ? imm_extended : rs2_data;

// ALU control
ALU_control ALU_control_inst (
    .opcode(instruction[6:0]),
    .funct3(instruction[14:12]),
    .inst30(instruction[30]),
    .ALU_op(ALU_op)
);

// ALU
alu alu_inst (
    .alu_op(ALU_op),
    .operand1(rs1_data),
    .operand2(operand2),
    .alu_out(alu_out)
);

// Data extension for memory
data_ext data_ext_MEM (
    .data_in(dmem_out),
    .funct3(instruction[14:12]),
    .data_out(dmem_out_ext)
);

// Data memory
data_mem data_mem_inst (
    .clk(clk),
    .dmem_addr(alu_out[9:0]),
    .we(MemWrite),
    .re(MemRead),
    .dmem_in(rs2_data),
    .dmem_out(dmem_out)
);

// PC adder
pc_adder pc_adder_inst (
    .pc(pc_out),
    .imm(imm_extended),
    .pc_imm(pc_imm),
    .pc_add4(pc_add4)
);

// Mux for next_pc
always @(*) begin
    case ({Jump, Branch})
        2'b10: next_pc = pc_imm;
        2'b11: begin
            case (instruction[14:12])
                3'b000: next_pc = (alu_out == 0) ? pc_imm : pc_add4; // beq
                3'b001: next_pc = (alu_out != 0) ? pc_imm : pc_add4; // bne
                3'b100: next_pc = alu_out[0] ? pc_imm : pc_add4; // blt
                3'b101: next_pc = !alu_out[0] ? pc_imm : pc_add4; // bge
                3'b110: next_pc = alu_out[0] ? pc_imm : pc_add4; // bltu
                3'b111: next_pc = !alu_out[0] ? pc_imm : pc_add4; // bgeu
                default: next_pc = pc_add4;
            endcase
        end
        default: next_pc = pc_add4;
    endcase
end

// Mux for pc_in
assign pc_in = PCsrc ? alu_out : next_pc;

// Mux for rd_data_in
always @(*) begin
    case (MemtoReg)
        2'b11: rd_data_in_internal = next_pc;
        2'b00: rd_data_in_internal = alu_out;
        2'b01: rd_data_in_internal = dmem_out_ext;
        2'b10: rd_data_in_internal = imm_extended;
        default: rd_data_in_internal = alu_out;
    endcase
end

// Assign the internal signal to the rd_data_in
assign rd_data_in = rd_data_in_internal;

endmodule