`timescale 1ns / 1ps
// Program Counter Module
// PC register with synchronous reset and an active-high hold (stall) input.
// When hold=1 the PC freezes its current value; this is used to stall the core
// during multi-cycle RV32M divide/remainder operations.
// SystemVerilog implementation

module program_counter #(
    parameter int XLEN = 32
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        hold,
    input  logic [XLEN-1:0] pc_next,
    output logic [XLEN-1:0] pc_current
);

    always_ff @(posedge clk) begin
        if (reset) begin
            pc_current <= '0;
        end else if (!hold) begin
            pc_current <= pc_next;
        end
    end

endmodule
