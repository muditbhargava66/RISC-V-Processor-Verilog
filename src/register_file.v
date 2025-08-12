module register_file (
    input clk,
    input reset,
    input reg_write,
    input [4:0] read_reg1,
    input [4:0] read_reg2,
    input [4:0] write_reg,
    input [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);

    // 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];
    
    // Initialize registers
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'h00000000;
            end
        end else if (reg_write && write_reg != 5'b00000) begin
            // x0 is hardwired to zero, cannot be written
            registers[write_reg] <= write_data;
        end
    end
    
    // Asynchronous read
    assign read_data1 = (read_reg1 == 5'b00000) ? 32'h00000000 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 5'b00000) ? 32'h00000000 : registers[read_reg2];

endmodule