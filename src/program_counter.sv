// Program Counter Module
// PC register with synchronous reset
// SystemVerilog implementation

module program_counter #(
    parameter int XLEN = 32
)(
    input  logic        clk,
    input  logic        reset,
    input  logic [XLEN-1:0] pc_next,
    output logic [XLEN-1:0] pc_current
);

    always_ff @(posedge clk) begin
        if (reset) begin
            pc_current <= '0;
        end else begin
            pc_current <= pc_next;
        end
    end

endmodule