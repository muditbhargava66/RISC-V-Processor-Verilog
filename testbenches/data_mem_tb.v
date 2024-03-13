`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2021 08:26:10 PM
// Design Name: 
// Module Name: data_mem_tb
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
module data_mem_tb;

  reg clk = 0;
  reg [9:0] dmem_addr = 10'd0;
  reg [3:0] we = 4'd0;
  reg re = 0;
  reg [31:0] dmem_in = 32'b0;
  wire [31:0] dmem_out;

  data_mem u_data_mem (
    .clk(clk),
    .dmem_addr(dmem_addr),
    .we(we),
    .re(re),
    .dmem_in(dmem_in),
    .dmem_out(dmem_out)
  );

  parameter PERIOD = 20;
  integer file_pointer;
  reg [31:0] file_din, file_dout;

  // Clock generation
  always #(PERIOD/2) clk = ~clk;

  // Testbench control
  initial begin
    file_pointer = $fopen("dmem_v1.txt", "r");
    if (file_pointer == 0) begin
      $display("Can't open the file.");
      $finish;
    end
    
    // Write data to memory
    #1 we = 4'b1111;
    while (!$feof(file_pointer)) begin
      @(posedge clk);
      #1 dmem_addr = dmem_addr + 1;
      $fscanf(file_pointer, "%h", file_din);
      dmem_in = file_din;
    end
    
    // Read data from memory and compare
    #1 we = 4'b0000;
    re = 1;
    dmem_addr = 10'd0;
    $fseek(file_pointer, 0, 0);  // Reset file pointer
    
    while (!$feof(file_pointer)) begin
      @(posedge clk);
      #1 dmem_addr = dmem_addr + 1;
      $fscanf(file_pointer, "%h", file_dout);
      if (file_dout !== dmem_out) begin
        $fatal("Test Case failed!");
        $finish;
      end
    end
    
    $fclose(file_pointer);
    $display("All test cases passed successfully!");
    $finish;
  end

endmodule
