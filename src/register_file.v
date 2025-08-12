// Register File Module
// 32 x 32-bit registers with x0 hardwired to zero

module register_file (
    input wire clk,
    input wire reset,
    input wire reg_write,
    input wire [4:0] read_reg1,
    input wire [4:0] read_reg2,
    input wire [4:0] write_reg,
    input wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    // 32 registers, each 32 bits wide
    reg [31:0] registers [1:31]; // x0 is not stored (always zero)
    
    // Initialize registers
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 1; i < 32; i = i + 1) begin
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