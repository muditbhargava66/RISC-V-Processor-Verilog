`timescale 1ns / 1ps
//`timescale 100ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/08 01:58:32
// Design Name: 
// Module Name: Jtype_tb
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


module Jtype_tb;

parameter f = 50;                   //Mhz
parameter PERIOD = 1/(f*0.001);

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



//Data Memory Initialisation
reg [31:0] data0 = 32'b1;
reg [31:0] data1 = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
reg [31:0] data2 = 32'h0100_0024;

initial begin
    processor.data_mem_inst.dmem[0] = data0;
    processor.data_mem_inst.dmem[1] = data1;
    processor.data_mem_inst.dmem[2] = data2; 
end


//Instruction Memory Initialisation
parameter [31:0] operand1 = 32'b000000110010;
parameter [31:0] operand2 = 32'b000000010100;
parameter [20:0] jimm = 21'b0000000010000;         //+16
parameter [31:0] imm = 32'h1000_0000;
parameter [11:0] simm = 12'd12;

initial begin
    //initial
    //lui test
    processor.instr_mem_inst.imem[0] = {32'b10000000000000000000_00001_0110111};           // lui  x1, 0x80000000
    //load data from data memory to registor file
    //load test
    processor.instr_mem_inst.imem[1] = {32'b000000000000_00001_010_00010_0000011};       // lw x2,x1(0) data memory address start at 0x80000000
    processor.instr_mem_inst.imem[2] = {32'b000000000100_00001_010_00011_0000011};       // lw x3,x1(4)
    processor.instr_mem_inst.imem[3] = {32'b000000001000_00001_010_00100_0000011};       // lw x4,x1(8)
    
    //r1 0x8000_0000
    //r2 0x0000_0001
    //r3 0xffff_ffff
    //r4 0x0100_0024

    //Jtype test
    processor.instr_mem_inst.imem[4] = {{jimm[20],jimm[10:1],jimm[11],jimm[19:12]},12'b00101_1101111};       // jal  x5,16       [4]to[8]    (pc+16=0x0100_0010)
    processor.instr_mem_inst.imem[8] = {jimm[11:0],20'b00100_000_00110_1100111};                             // jalr x6,x4,16    [8]to[13]   (rs1+16=0x0100_0034)

    processor.instr_mem_inst.imem[13] = {imm[31:12],12'b00111_0010111};                                      // auipc x7,imm     ($7 = pc+{imm[31:12], 12'b0})
    processor.instr_mem_inst.imem[14] = {32'b000000000001_00000_000_01000_0010011};                          // addi x8,x0,1   
    processor.instr_mem_inst.imem[15] = {simm[11:5],13'b01000_010_00001,simm[4:0],7'b0100011};               // sw x8,x1(12)
end


//Verify
initial begin   
    #1000;
    if(r5 != 32'h01000010 + 32'h4 )                 $fatal("Test case 'jal' failed");    // $5 == 32'h0100_0014
    if(r6 != 32'h01000020 + 32'h4 )                 $fatal("Test case 'jalr' failed");   // $6 == 32'h0100_0024
    if(r7 != 32'h01000034 + {imm[31:12], 12'b0})    $fatal("Test case 'auipc' failed"); // $7 == 32'h1100_0034
    if(processor.data_mem_inst.dmem[3] != 32'd1)     $fatal("Test case 'sw' failed"); 
    #100
    $display("Jump Test case passed");
    $finish;
end

//Monitor
// initial begin
//     $monitor ("R5: %4d, R6: %4d, R7: %4d", processor.regfile_inst.regfile[5], processor.regfile_inst.regfile[6], processor.regfile_inst.regfile[7]); 
    
// end
initial begin
    $monitor ("D0: %4d, D1: %4d, D1: %4d, D3: %4d", processor.data_mem_inst.dmem[0], processor.data_mem_inst.dmem[1], processor.data_mem_inst.dmem[2], processor.data_mem_inst.dmem[3]); 
end

endmodule