`timescale 1ns / 1ps
// Sequential Restoring Divider (RV32M: DIV / DIVU / REM / REMU)
// -----------------------------------------------------------------------------
// Radix-2 restoring division over XLEN iterations. The core stalls (holds PC)
// while busy is high and writes the result on the cycle done pulses.
//
// Handshake:
//   * start          : pulse to begin a division (operands sampled this cycle)
//   * busy           : high while the iterative computation is in progress
//   * done           : single-cycle pulse when result_reg holds the final value
//   * corner         : combinational flag for divide-by-zero / signed overflow
//   * result         : corner_result when corner=1, else the registered result
//
// Corner cases (RISC-V spec) resolve combinationally in the start cycle, so the
// core never stalls for them:
//   DIV  / 0 -> -1            DIVU / 0 -> 0xFFFFFFFF
//   REM  / 0 -> dividend      REMU / 0 -> dividend
//   -2^(XLEN-1) / -1 (signed overflow) -> quotient = -2^(XLEN-1), remainder = 0
//
// Normal cases divide the unsigned magnitudes and apply signs afterward:
//   quotient sign = sign(dividend) XOR sign(divisor)
//   remainder sign = sign(dividend)
// This matches RISC-V trunc-toward-zero semantics.

module divider #(
    parameter int XLEN = 32
)(
    input  logic             clk,
    input  logic             reset,
    input  logic             start,
    input  logic             is_signed,
    input  logic             is_remainder,
    input  logic [XLEN-1:0]  dividend,
    input  logic [XLEN-1:0]  divisor,
    output logic [XLEN-1:0]  result,
    output logic             done,
    output logic             busy,
    output logic             corner
);

    localparam int CNT_W = $clog2(XLEN);                       // iteration count width
    localparam int LAST_COUNT = XLEN - 1;                      // final iteration index
    localparam logic [XLEN-1:0] MOST_NEG = {1'b1, {(XLEN-1){1'b0}}};  // -2^(XLEN-1)
    localparam logic [XLEN-1:0] ALL_ONES = {XLEN{1'b1}};             // -1 / max unsigned

    // ------------------------------------------------------------------
    // Corner-case detection (combinational, independent of start)
    // ------------------------------------------------------------------
    logic div_by_zero, overflow;
    assign div_by_zero = (divisor == '0);
    assign overflow    = is_signed && (dividend == MOST_NEG) && (divisor == ALL_ONES);
    assign corner      = div_by_zero | overflow;

    logic [XLEN-1:0] corner_result;
    always_comb begin
        if (div_by_zero)
            corner_result = is_remainder ? dividend : ALL_ONES;
        else // signed overflow
            corner_result = is_remainder ? '0 : MOST_NEG;
    end

    // ------------------------------------------------------------------
    // Operand magnitudes (combinational)
    // ------------------------------------------------------------------
    logic [XLEN-1:0] abs_dividend, abs_divisor;
    assign abs_dividend = (is_signed && dividend[XLEN-1]) ? (~dividend + 1'b1) : dividend;
    assign abs_divisor  = (is_signed && divisor[XLEN-1])  ? (~divisor  + 1'b1) : divisor;

    // ------------------------------------------------------------------
    // Iteration datapath (combinational next-state from current registers)
    // ------------------------------------------------------------------
    logic [XLEN-1:0] divisor_mag;
    logic [XLEN-1:0] quotient, remainder;
    logic [XLEN-1:0] rem_shift, quot_shift, rem_next, quot_next;
    logic            sub_ok;

    assign rem_shift = {remainder[XLEN-2:0], quotient[XLEN-1]};
    assign quot_shift = {quotient[XLEN-2:0], 1'b0};
    assign sub_ok    = (rem_shift >= divisor_mag);
    assign rem_next  = sub_ok ? (rem_shift - divisor_mag) : rem_shift;
    assign quot_next = sub_ok ? {quot_shift[XLEN-1:1], 1'b1} : quot_shift;

    // ------------------------------------------------------------------
    // Sequential control
    // ------------------------------------------------------------------
    logic [CNT_W-1:0] count;
    logic             quot_neg, rem_neg, rem_sel;
    logic [XLEN-1:0]  result_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            busy        <= 1'b0;
            done        <= 1'b0;
            count       <= '0;
            quotient    <= '0;
            remainder   <= '0;
            divisor_mag <= '0;
            quot_neg    <= 1'b0;
            rem_neg     <= 1'b0;
            rem_sel     <= 1'b0;
            result_reg  <= '0;
        end else begin
            done <= 1'b0;   // done is a single-cycle pulse

            if (!busy) begin
                if (start && !corner) begin
                    divisor_mag <= abs_divisor;
                    quotient    <= abs_dividend;
                    remainder   <= '0;
                    quot_neg    <= is_signed && (dividend[XLEN-1] ^ divisor[XLEN-1]);
                    rem_neg     <= is_signed && dividend[XLEN-1];
                    rem_sel     <= is_remainder;
                    count       <= '0;
                    busy        <= 1'b1;
                end
            end else begin
                // One restoring-division iteration.
                quotient  <= quot_next;
                remainder <= rem_next;

                if (count == LAST_COUNT[CNT_W-1:0]) begin
                    // Final (XLEN-th) iteration: apply signs and present result.
                    if (rem_sel)
                        result_reg <= rem_neg  ? (~rem_next  + 1'b1) : rem_next;
                    else
                        result_reg <= quot_neg ? (~quot_next + 1'b1) : quot_next;
                    done <= 1'b1;
                    busy <= 1'b0;
                end else begin
                    count <= count + 1'b1;
                end
            end
        end
    end

    // Result mux: corner cases bypass the iterative datapath entirely.
    assign result = corner ? corner_result : result_reg;

endmodule
