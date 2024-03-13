`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/11/07 22:57:29
// Design Name: 
// Module Name: rc5_tb
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

module alu_tb;

  parameter PERIOD = 10;

  // I/O
  reg clk = 0;
  reg [31:0] operand1 = 0;
  reg [31:0] operand2 = 0;
  reg [3:0] alu_op = 0;
  reg [31:0] result = 0;
  wire [31:0] alu_out;

  // File handling
  integer file_pointer;
  reg [63:0] file_data0, file_data1;

  // Clock generation
  always #(PERIOD/2) clk = ~clk;

  // ALU instantiation
  alu u_alu (
    .alu_op(alu_op),
    .operand1(operand1),
    .operand2(operand2),
    .alu_out(alu_out)
  );

  // Testbench control
  initial begin
    // Test different ALU operations
    for (alu_op = 4'b0000; alu_op <= 4'b0111; alu_op = alu_op + 1) begin
      repeat (10) @(posedge clk);
    end
    repeat (10) @(posedge clk);
    $finish;
  end

  // Read input data from file
  initial begin
    file_pointer = $fopen("random_dataset.txt", "r");
    if (file_pointer == 0) begin
      $display("Can't open the file.");
      $finish;
    end
    while (!$feof(file_pointer)) begin
      $fscanf(file_pointer, "%h", file_data0);
      $fscanf(file_pointer, "%h", file_data1);
      operand1 = file_data0;
      operand2 = file_data1;
      @(posedge clk);
      // Compare output
      if (alu_out !== result) begin
        $display("alu_op = %b", alu_op);
        $display("operand1: %h", operand1);
        $display("operand2: %h", operand2);
        $display("alu_out: %h", alu_out);
        $fatal("Test Case failed!");
        $finish;
      end
    end
    $fclose(file_pointer);
    $display("All ALU test cases passed successfully!");
    $finish;
  end

  // Calculate expected result
  always @(*) begin
    case (alu_op)
      4'b0000: result = $signed(operand1) + $signed(operand2);
      4'b1000: result = $signed(operand1) - $signed(operand2);
      4'b0001: result = operand1 << operand2[4:0];
      4'b0010: result = $signed(operand1) < $signed(operand2);
      4'b0011: result = operand1 < operand2;
      4'b0100: result = operand1 ^ operand2;
      4'b0101: result = operand1 >> operand2[4:0];
      4'b1101: result = $signed(operand1) >>> operand2[4:0];
      4'b0110: result = operand1 | operand2;
      4'b0111: result = operand1 & operand2;
      default: result = 32'd0;
    endcase
  end

endmodule