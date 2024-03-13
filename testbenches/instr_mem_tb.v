`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2021 04:14:05 PM
// Design Name: 
// Module Name: instr_mem_tb
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
module instr_mem_tb;

  reg [8:0] addr = 9'b0;
  wire [31:0] instr_out;
  reg clk = 0;
  reg instr_en = 0;

  // File handling
  parameter PERIOD = 10;
  reg [31:0] file_dout;
  integer file_pointer;

  instr_mem u_instr_mem (
    .clk(clk),
    .instr_en(instr_en),
    .addr(addr),
    .instr_out(instr_out)
  );

  // Clock generation
  always #(PERIOD/2) clk = ~clk;

  // Testbench control
  initial begin
    file_pointer = $fopen("imem.txt", "r");
    if (file_pointer == 0) begin
      $display("Can't open the file.");
      $finish;
    end

    #6 instr_en = 1;
    
    while (!$feof(file_pointer)) begin
      @(posedge clk);
      #1;
      addr = addr + 1;
    end

    $fclose(file_pointer);
    $finish;
  end

  // Output comparison
  initial begin
    #6;
    
    while (!$feof(file_pointer)) begin
      @(posedge clk);
      #1;
      $fscanf(file_pointer, "%h", file_dout);
      
      if (file_dout !== instr_out) begin
        $display("Test failed! Expected: %h, Actual: %h", file_dout, instr_out);
        $finish;
      end
    end

    $display("All test cases passed successfully!");
  end

endmodule