`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2021 12:37:39 AM
// Design Name: 
// Module Name: regfile_tb
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
module regfile_tb;

  reg clk = 0;
  reg rst;
  reg we; // write_enable control signal
  reg [4:0] rd_addr;
  reg [4:0] rs1_addr;
  reg [4:0] rs2_addr;
  reg [31:0] rd_data_in;
  wire [31:0] rs1_data;
  wire [31:0] rs2_data;

  regfile u_regfile (
    .clk(clk),
    .rst(rst),
    .we(we),
    .rd_addr(rd_addr),
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rd_data_in(rd_data_in),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
  );

  parameter PERIOD = 20;
  integer file_pointer;
  reg [31:0] file_dout1, file_dout2;

  // Clock generation
  always #(PERIOD/2) clk = ~clk;

  // Testbench control
  initial begin
    file_pointer = $fopen("regfile.txt", "r");
    if (file_pointer == 0) begin
      $display("Can't open the file.");
      $finish;
    end

    // Reset and enable write
    #1 rst = 1;
    #5 we = 1;

    // Write data to registers
    while (!$feof(file_pointer)) begin
      @(posedge clk);
      #1;
      rd_addr = rd_addr + 1;
      $fscanf(file_pointer, "%h", rd_data_in);
    end

    // Disable write and reset read addresses
    we = 0;
    rs1_addr = 0;
    rs2_addr = 0;

    // Read data from registers and compare
    $fseek(file_pointer, 0, 0); // Reset file pointer
    while (!$feof(file_pointer)) begin
      @(posedge clk);
      #1;
      rs1_addr = rs1_addr + 1;
      rs2_addr = rs2_addr + 1;
      $fscanf(file_pointer, "%h", file_dout1);
      $fscanf(file_pointer, "%h", file_dout2);

      if (rs1_addr !== 0) begin
        if (file_dout1 !== rs1_data) begin
          $fatal("Test failed for rs1_data! Expected: %h, Actual: %h", file_dout1, rs1_data);
        end
      end

      if (rs2_addr !== 0) begin
        if (file_dout2 !== rs2_data) begin
          $fatal("Test failed for rs2_data! Expected: %h, Actual: %h", file_dout2, rs2_data);
        end
      end
    end

    $fclose(file_pointer);
    $display("All test cases passed successfully!");
    $finish;
  end

endmodule