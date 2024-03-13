`timescale 1ns / 1ps
//`timescale 100ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/03 02:21:48
// Design Name: 
// Module Name: add_tb
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

module Rtype_tb;
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

initial begin

    processor.instr_mem_inst.imem[0] = {operand1[11:0],20'b00001_000_00001_0010011}; // addi x1,x1,50
    processor.instr_mem_inst.imem[1] = {operand2[11:0],20'b00010_000_00010_0010011}; // addi x2,x2,-2028
    processor.instr_mem_inst.imem[2] = 32'b0000000_00010_00001_000_00011_0110011;    // add x3,x1,x2
    processor.instr_mem_inst.imem[3] = 32'b0100000_00010_00001_000_00100_0110011;    // sub x4,x1,x2
    processor.instr_mem_inst.imem[4] = 32'b0000000_00010_00001_001_00101_0110011;    // sll x5,x1,x2  
    processor.instr_mem_inst.imem[5] = 32'b0000000_00010_00001_010_00110_0110011;    // slt x6,x1,x2  
    processor.instr_mem_inst.imem[6] = 32'b0000000_00010_00001_011_00111_0110011;    // sltu x7,x1,x2  
    processor.instr_mem_inst.imem[7] = 32'b0000000_00010_00001_100_01000_0110011;    // xor x8,x1,x2 
    processor.instr_mem_inst.imem[8] = 32'b0000000_00010_00001_101_01001_0110011;    // srl x9,x1,4 
    processor.instr_mem_inst.imem[9] = 32'b0100000_00010_00001_101_01010_0110011;    // sra x10,x1,x2 
    processor.instr_mem_inst.imem[10]= 32'b0000000_00010_00001_110_01011_0110011;    // or x11,x1,x2 
    processor.instr_mem_inst.imem[11]= 32'b0000000_00010_00001_111_01100_0110011;    // and x12,x1,x2 

end


//Verify
wire [31:0] signed_op1 = {{20{operand1[11]}},operand1[11:0]};
wire [31:0] signed_op2 = {{20{operand2[11]}},operand2[11:0]};

initial begin   
    #1200;
    if(r3 != signed_op1 + signed_op2)                       $fatal("Test case 'add' failed");
    if(r4 != signed_op1 - signed_op2)                       $fatal("Test case 'sub' failed");
    if(r5 != signed_op1 << signed_op2[4:0])                 $fatal("Test case 'sll' failed");
    if(r6 != $signed(signed_op1) < $signed(signed_op2))     $fatal("Test case 'slt' failed");
    if(r7 != signed_op1 < signed_op2)                       $fatal("Test case 'sltu' failed");
    if(r8 != (signed_op1 ^ signed_op2))                     $fatal("Test case 'xor' failed");
    if(r9 != signed_op1 >> signed_op2[4:0])                 $fatal("Test case 'srl' failed");
    if(r10!= ($signed(signed_op1)) >>> signed_op2[4:0])     $fatal("Test case 'sra' failed");
    if(r11!= (signed_op1 | signed_op2))                     $fatal("Test case 'or' failed");
    if(r12!= (signed_op1 & signed_op2))                     $fatal("Test case 'and' failed");
    #100
    $display("Rtype Test case passed");
    $finish;
end


//Monitor
initial begin
    $monitor ("R1: %4d, R2: %4d, R3: %4d", processor.regfile_inst.regfile[1], processor.regfile_inst.regfile[2], processor.regfile_inst.regfile[3]); 
    
end

endmodule