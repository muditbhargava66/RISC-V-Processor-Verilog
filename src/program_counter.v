module program_counter (
    input clk,
    input reset,
    input pc_write,
    input [31:0] pc_next,
    output reg [31:0] pc_current
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_current <= 32'h00000000;
        end else if (pc_write) begin
            pc_current <= pc_next;
        end
    end

endmodule