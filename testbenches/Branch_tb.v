`timescale 1ns / 1ps
//`timescale 100ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/06 17:47:12
// Design Name: 
// Module Name: Branch_tb
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


module Branch_tb;
parameter f = 500;                   //Mhz
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
reg [31:0] data2 = 32'b1;

initial begin
    processor.data_mem_inst.dmem[0] = data0;
    processor.data_mem_inst.dmem[1] = data1;
    processor.data_mem_inst.dmem[2] = data2; 
end


//Instruction Memory Initialisation
parameter [31:0] operand1 = 32'b000000110010;
parameter [31:0] operand2 = 32'b000000010100;
parameter [12:0] imm0 = 13'b0000000001000;         //+8
parameter [12:0] imm1 = 13'b1111111111000;         //-8
parameter [12:0] imm2 = 13'b0000000010000;         //+16
parameter [12:0] imm3 = 13'b0000000011000;         //+24
parameter [12:0] imm4 = 13'b1111111110000;         //-16


// Test instruction

initial begin
    //initial
    //lui test
    processor.instr_mem_inst.imem[0] = {32'b10000000000000000000_00001_0110111};           // lui  x1, imm 
    //load data from data memory to registor file
    //load test
    processor.instr_mem_inst.imem[1] = {32'b000000000000_00001_010_00010_0000011};       // lw x2,x1(0) data memory address start at 0x80000000
    processor.instr_mem_inst.imem[2] = {32'b000000000100_00001_010_00011_0000011};       // lw x3,x1(4)
    processor.instr_mem_inst.imem[3] = {32'b000000001000_00001_010_00100_0000011};       // lw x4,x1(8)
    
    //r1 0x8000_0000
    //r2 0x0000_0001
    //r3 0xffff_ffff
    //r4 0x0000_0001

    //branch test
    //notice                                                  x4     x2
    processor.instr_mem_inst.imem[4] = {{imm2[12],imm2[10:5]},13'b00100_00010_000,{imm2[4:1],imm2[11]},7'b1100011};      // beq x2,x4,16     [4]to[8]    (branch+16)
    processor.instr_mem_inst.imem[5] = {32'b000000000001_00000_000_00101_0010011};                                       // addi x5,x0,1

    processor.instr_mem_inst.imem[6] = {{imm2[12],imm2[10:5]},13'b00001_00010_001,{imm2[4:1],imm2[11]},7'b1100011};      // bne x2,x1,16     [6]to[10]   (branch+16)
    processor.instr_mem_inst.imem[7] = {32'b000000000001_00000_000_00101_0010011};                                       // addi x5,x0,1

    processor.instr_mem_inst.imem[8] = {{imm1[12],imm1[10:5]},13'b00100_00010_000,{imm1[4:1],imm1[11]},7'b1100011};      // beq x2,x4,-8     [8]to[6]    (branch-8)
    processor.instr_mem_inst.imem[9] = {32'b000000000001_00000_000_00101_0010011};                                       // addi x5,x0,1

    processor.instr_mem_inst.imem[10] = {{imm0[12],imm0[10:5]},13'b00100_00010_001,{imm0[4:1],imm0[11]},7'b1100011};     // bne x2,x4,8      [10]to[11]   (+4)

    processor.instr_mem_inst.imem[11] = {{imm2[12],imm2[10:5]},13'b00010_00001_100,{imm2[4:1],imm2[11]},7'b1100011};     // blt x1,x2,16     [11]to[15]  (branch+16)
    processor.instr_mem_inst.imem[12] = {32'b000000000001_00000_000_00101_0010011};                                      // addi x5,x0,1 

    processor.instr_mem_inst.imem[13] = {{imm3[12],imm3[10:5]},13'b00001_00010_101,{imm3[4:1],imm3[11]},7'b1100011};     // bge x2,x1,24     [13]to[19]  (branch+24)
    processor.instr_mem_inst.imem[14] = {32'b000000000001_00000_000_00101_0010011};                                      // addi x5,x0,1   

    processor.instr_mem_inst.imem[15] = {{imm0[12],imm0[10:5]},13'b00011_00010_100,{imm0[4:1],imm0[11]},7'b1100011};     // blt x2,x3,8      [15]to[16]  (+4)

    processor.instr_mem_inst.imem[16] = {{imm0[12],imm0[10:5]},13'b00010_00011_101,{imm0[4:1],imm0[11]},7'b1100011};     // bge x3,x2,8      [16]to[17]  (+4)

    processor.instr_mem_inst.imem[17] = {{imm4[12],imm4[10:5]},13'b00011_00010_110,{imm4[4:1],imm4[11]},7'b1100011};     // bltu x2,x3,-24   [17]to[13]  (branch-16)
    processor.instr_mem_inst.imem[18] = {32'b000000000001_00000_000_00101_0010011};                                      // addi x5,x0,1

    processor.instr_mem_inst.imem[19] = {{imm0[12],imm0[10:5]},13'b00010_00011_111,{imm0[4:1],imm0[11]},7'b1100011};     // bgeu x3,x2,8     [19]to[21]  (branch+8)
    processor.instr_mem_inst.imem[20] = {32'b000000000001_00000_000_00101_0010011};                                      // addi x5,x0,1

    processor.instr_mem_inst.imem[21] = {32'b000000000001_00000_000_00110_0010011};                                      // addi x6,x0,1   
end


//Verify
initial begin   
    #1200;
    if(r5 != 32'd0 | r6 != 32'd1) $fatal("Test case failed"); //when $5 == 0, all branch instruction succeed 
    #100
    $display("Branch Test case passed");
    $finish;
end

//Monitor
initial begin
    $monitor ("R1: %4d, R2: %4d, R3: %4d", processor.regfile_inst.regfile[1], processor.regfile_inst.regfile[2], processor.regfile_inst.regfile[3]); 
    
end
initial begin
    $monitor ("D0: %4d, D1: %4d, D1: %4d, D3: %4d", processor.data_mem_inst.dmem[0], processor.data_mem_inst.dmem[1], processor.data_mem_inst.dmem[2], processor.data_mem_inst.dmem[3]); 
end

endmodule