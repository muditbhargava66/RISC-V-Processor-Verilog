`timescale 1ns / 1ps
// Divider Testbench (RV32M DIV / DIVU / REM / REMU)
// Verifies the multi-cycle restoring divider against an independent oracle built
// from SystemVerilog's own signed/unsigned arithmetic. Covers:
//   * combinational corner path (divide-by-zero, signed overflow): result valid
//     in the start cycle, busy never rises
//   * sequential path: busy handshake, single-cycle done pulse, ~32-cycle latency
//   * directed vectors (incl. the cases formerly in alu_tb) and randomized vectors
//   * reset behavior
// Self-checking with $fatal on any failure.

module divider_tb;

    logic        clk;
    logic        reset;
    logic        start;
    logic        is_signed;
    logic        is_remainder;
    logic [31:0] dividend;
    logic [31:0] divisor;
    logic [31:0] result;
    logic        done;
    logic        busy;
    logic        corner;

    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;

    divider dut (
        .clk          (clk),
        .reset        (reset),
        .start        (start),
        .is_signed    (is_signed),
        .is_remainder (is_remainder),
        .dividend     (dividend),
        .divisor      (divisor),
        .result       (result),
        .done         (done),
        .busy         (busy),
        .corner       (corner)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Independent reference model (RISC-V trunc-toward-zero semantics).
    function automatic logic [31:0] oracle(input logic [31:0] a, input logic [31:0] b,
                                           input logic sgn, input logic rem);
        if (b == 32'h0)
            return rem ? a : 32'hFFFFFFFF;
        if (sgn && a == 32'h80000000 && b == 32'hFFFFFFFF)
            return rem ? 32'h0 : 32'h80000000;
        if (sgn)
            return rem ? ($signed(a) % $signed(b)) : ($signed(a) / $signed(b));
        return rem ? (a % b) : (a / b);
    endfunction

    function automatic logic is_corner(input logic [31:0] a, input logic [31:0] b, input logic sgn);
        return (b == 32'h0) || (sgn && a == 32'h80000000 && b == 32'hFFFFFFFF);
    endfunction

    task automatic check(input logic cond, input string name);
        begin
            test_count++;
            if (cond) begin
                pass_count++;
                $display("PASS: %s", name);
            end else begin
                fail_count++;
                $display("FAIL: %s", name);
            end
        end
    endtask

    // Apply one division and verify result + handshake.
    task automatic run_div(input logic [31:0] a, input logic [31:0] b,
                           input logic sgn, input logic rem, input string name);
        logic [31:0] exp;
        logic        corn;
        logic        timed_out;
        int          cyc;
        begin
            exp  = oracle(a, b, sgn, rem);
            corn = is_corner(a, b, sgn);
            dividend     = a;
            divisor      = b;
            is_signed    = sgn;
            is_remainder = rem;
            @(negedge clk);

            if (corn) begin
                // Corner cases resolve combinationally; the engine must not start.
                start = 0;
                #1;
                check(corner === 1'b1,  {name, " | corner flag"});
                check(result === exp,   {name, " | corner result"});
                check(busy   === 1'b0,  {name, " | no busy on corner"});
            end else begin
                start = 1;
                @(negedge clk);
                start = 0;
                check(busy === 1'b1, {name, " | busy asserted"});
                cyc = 0;
                timed_out = 0;
                while (done !== 1'b1 && !timed_out) begin
                    @(negedge clk);
                    cyc++;
                    if (cyc > 80) timed_out = 1;
                end
                if (timed_out) begin
                    check(1'b0, {name, " | timeout waiting for done"});
                end else begin
                    check(result === exp,  {name, " | result"});
                    check(busy   === 1'b0, {name, " | busy cleared on done"});
                    @(negedge clk);
                    check(done === 1'b0,   {name, " | done is single-cycle pulse"});
                    $display("  info: %s latency=%0d iterations (a=%08h b=%08h)", name, cyc, a, b);
                end
            end
        end
    endtask

    int i;
    logic [31:0] ra, rb;
    logic        rs, rr;

    initial begin
        $display("========================================");
        $display("Divider Test (RV32M multi-cycle)");
        $display("========================================");

        // Reset behavior
        reset = 1; start = 0; is_signed = 0; is_remainder = 0;
        dividend = 0; divisor = 0;
        @(negedge clk);
        #1;
        check(busy === 1'b0, "reset | busy low");
        check(done === 1'b0, "reset | done low");
        reset = 0;

        // ---- Directed corner cases (combinational fast path) ----
        run_div(32'h00000005, 32'h00000000, 1'b1, 1'b0, "DIV  by zero -> -1");
        run_div(32'h00000005, 32'h00000000, 1'b0, 1'b0, "DIVU by zero -> maxU");
        run_div(32'h00000005, 32'h00000000, 1'b1, 1'b1, "REM  by zero -> dividend");
        run_div(32'h00000007, 32'h00000000, 1'b0, 1'b1, "REMU by zero -> dividend");
        run_div(32'h80000000, 32'hFFFFFFFF, 1'b1, 1'b0, "DIV  overflow -> MOST_NEG");
        run_div(32'h80000000, 32'hFFFFFFFF, 1'b1, 1'b1, "REM  overflow -> 0");

        // ---- Directed normal cases (sequential path) ----
        run_div(32'h00000014, 32'h00000003, 1'b1, 1'b0, "DIV  20/3");
        run_div(32'hFFFFFFEC, 32'h00000003, 1'b1, 1'b0, "DIV  -20/3");
        run_div(32'h00000014, 32'hFFFFFFFD, 1'b1, 1'b0, "DIV  20/-3");
        run_div(32'hFFFFFFEC, 32'hFFFFFFFD, 1'b1, 1'b0, "DIV  -20/-3");
        run_div(32'hFFFFFFFF, 32'h00000002, 1'b0, 1'b0, "DIVU maxU/2");
        run_div(32'h00000014, 32'h00000003, 1'b1, 1'b1, "REM  20%3");
        run_div(32'hFFFFFFEC, 32'h00000003, 1'b1, 1'b1, "REM  -20%3");
        run_div(32'h00000014, 32'hFFFFFFFD, 1'b1, 1'b1, "REM  20%-3");
        run_div(32'hFFFFFFFF, 32'h00000002, 1'b0, 1'b1, "REMU maxU%2");
        run_div(32'h00000000, 32'h00000005, 1'b1, 1'b0, "DIV  0/5");
        run_div(32'h00000003, 32'h00000014, 1'b1, 1'b0, "DIV  3/20 (quot 0)");
        run_div(32'h00000003, 32'h00000014, 1'b1, 1'b1, "REM  3%20 (rem 3)");
        run_div(32'h80000000, 32'h00000002, 1'b1, 1'b0, "DIV  -2^31/2");
        run_div(32'h80000000, 32'h00000002, 1'b1, 1'b1, "REM  -2^31%2");
        run_div(32'h7FFFFFFF, 32'h00000001, 1'b1, 1'b0, "DIV  maxInt/1");
        run_div(32'hFFFFFFFF, 32'hFFFFFFFF, 1'b0, 1'b0, "DIVU maxU/maxU");

        // ---- Randomized vectors vs oracle ----
        $display("--- Randomized vectors ---");
        for (i = 0; i < 200; i++) begin
            ra = $urandom;
            rb = $urandom;
            rs = $urandom_range(0, 1);
            rr = $urandom_range(0, 1);
            if (rb == 0) rb = 32'h1;   // keep random set on the sequential path
            run_div(ra, rb, rs, rr, $sformatf("rand[%0d]", i));
        end

        // ---- Report ----
        $display("========================================");
        $display("Divider Results: %0d/%0d passed, %0d failed", pass_count, test_count, fail_count);
        if (fail_count == 0) begin
            $display("ALL DIVIDER TESTS PASSED!");
        end else begin
            $display("DIVIDER FAILURES DETECTED");
            $fatal(1, "divider_tb: %0d failures", fail_count);
        end
        $display("========================================");
        $finish;
    end

    initial begin
        #2000000;
        $fatal(1, "divider_tb: global timeout");
    end

endmodule
