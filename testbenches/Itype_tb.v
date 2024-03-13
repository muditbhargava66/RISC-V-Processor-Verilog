`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/03 15:37:10
// Design Name: 
// Module Name: Itype_tb
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


module Itype_tb;
parameter PERIOD    = 20  ;

reg clk = 0;
reg rst = 0;

processor_top processor(
    .clk        (clk    ), 
    .rst        (rst    )
);

wire [31:0] pc = processor.pc_out;
wire [31:0] new_pc = processor.pc_in;
wire [31:0] instruction = processor.instruction; 
wire [31:0] alu_a = processor.rs1_data; 
wire [31:0] alu_b = processor.operand2; 
wire [31:0] alu_out = processor.alu_out; 
wire [31:0] r0 = processor.regfile_inst.regfile[0]; 
wire [31:0] r1 = processor.regfile_inst.regfile[1]; 
wire [31:0] r2 = processor.regfile_inst.regfile[2];  
wire [31:0] r3 = processor.regfile_inst.regfile[3]; 
wire [31:0] r4 = processor.regfile_inst.regfile[4]; 
wire [31:0] r5 = processor.regfile_inst.regfile[5]; 
wire [31:0] r6 = processor.regfile_inst.regfile[6];  
wire [31:0] r7 = processor.regfile_inst.regfile[7]; 
wire [31:0] r8 = processor.regfile_inst.regfile[8]; 
wire [31:0] r9 = processor.regfile_inst.regfile[9]; 
wire [31:0] r10 = processor.regfile_inst.regfile[10]; 
wire [31:0] r11 = processor.regfile_inst.regfile[11];  
wire [31:0] r12 = processor.regfile_inst.regfile[12]; 



//Rst
initial begin
    #5 
    rst = 1;
end 

//clk
initial begin
    forever #(PERIOD/2)  clk=~clk;
end


//Instruction Memory Initialisation
reg [31:0] operand1 = 32'b000000110010;
reg [31:0] operand2 = 32'b100000010100;
reg [11:0] imm = 11'b000000000011; //3
initial begin

    processor.instr_mem_inst.imem[0] = {operand1[11:0],20'b00001_000_00001_0010011};         // addi x1,x1,50
    processor.instr_mem_inst.imem[1] = {operand2[11:0],20'b00001_000_00010_0010011};         // addi x2,x1,-2028

    processor.instr_mem_inst.imem[2] = {operand2[11:0],20'b00001_010_00011_0010011};         // slti x3,x1,-2028
    processor.instr_mem_inst.imem[3] = {operand2[11:0],20'b00001_011_00100_0010011};         // sltiu x4,x1,-2028
    processor.instr_mem_inst.imem[4] = {operand2[11:0],20'b00001_100_00101_0010011};         // xori x5,x1,-2028
    processor.instr_mem_inst.imem[5] = {operand2[11:0],20'b00001_110_00110_0010011};         // ori x6,x1,-2028
    processor.instr_mem_inst.imem[6] = {operand2[11:0],20'b00001_111_00111_0010011};         // andi x7,x1,-2028
    processor.instr_mem_inst.imem[7] = {7'b0000000,imm[4:0],20'b00010_001_01000_0010011};    // slli x8,x2,3
    processor.instr_mem_inst.imem[8] = {7'b0000000,imm[4:0],20'b00010_101_01001_0010011};    // srli x9,x2,3
    processor.instr_mem_inst.imem[9] = {7'b0100000,imm[4:0],20'b00010_101_01010_0010011};    // srai x10,x2,3

end


//Verify
wire [31:0] signed_op1 = {{20{operand1[11]}},operand1[11:0]};
wire [31:0] signed_op2 = {{20{operand2[11]}},operand2[11:0]};
wire [31:0] sum = signed_op1 + signed_op2;

initial begin   
    #1200;
    if(r2 != signed_op1 + signed_op2)                   $fatal("Test case 'addi' failed");
    if(r8 != sum << imm[4:0])                           $fatal("Test case 'slli' failed");
    if(r3 != $signed(signed_op1) < $signed(signed_op2)) $fatal("Test case 'slti' failed");
    if(r4 != signed_op1 < signed_op2)                   $fatal("Test case 'sltiu' failed");
    if(r5 != (signed_op1 ^ signed_op2))                 $fatal("Test case 'xori' failed");
    if(r9 != sum >> imm[4:0])                           $fatal("Test case 'srli' failed");
    if(r10!= sum >>> imm[4:0])                          $fatal("Test case 'srai' failed");
    if(r6 != (signed_op1 | signed_op2))                 $fatal("Test case 'ori' failed");
    if(r7 != (signed_op1 & signed_op2))                 $fatal("Test case 'andi' failed");
    #100
    $display("Itype Test case passed");
    $finish;
end


//Monitor
initial begin
    $monitor ("R1: %4d, R2: %4d, R3: %4d", processor.regfile_inst.regfile[1], processor.regfile_inst.regfile[2], processor.regfile_inst.regfile[3]); 
    
end

endmodule