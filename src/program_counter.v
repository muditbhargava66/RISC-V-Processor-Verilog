// Program Counter Module
// Simple PC register with synchronous reset

module program_counter (
    input wire clk,
    input wire reset,
    input wire [31:0] pc_next,
    output reg [31:0] pc_current
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_current <= 32'h00000000;
        end else begin
            pc_current <= pc_next;
        end
    end

endmodule