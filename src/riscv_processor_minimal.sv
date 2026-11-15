// RISC-V Processor Minimal Version for FPGA Deployment (Basys3)
// Wraps the main riscv_processor and exposes only a minimal PC debug port.
//
// Clocking: the Basys3 W5 pin is a 100 MHz oscillator. The core is constrained
// and timed at 50 MHz, so this wrapper divides the board clock by 2 with a
// toggle flop buffered onto the global clock network by a BUFG (7-series
// supported; BUFGCE_DIV is UltraScale-only). Reset is an asynchronous push
// button, synchronized here before being applied to the core's synchronous reset.

module riscv_processor_minimal #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1,
    parameter bit ENABLE_C = 1'b0
)(
    input  logic        clk,      // 100 MHz board oscillator (pin W5)
    input  logic        reset,    // async push button, active high (pin U18)
    output logic [15:0] pc_debug
);

    logic clk_int;
    logic reset_sync;

    // ---- Clock division: 100 MHz -> 50 MHz ----
    // BUFGCE_DIV is an UltraScale primitive and is NOT supported on Artix-7
    // (Vivado treats it as a black box). Divide by 2 with a toggle flop and
    // buffer the result onto the global clock network with a BUFG.
    logic clk_div_reg = 1'b0;
    always_ff @(posedge clk) clk_div_reg <= ~clk_div_reg;
`ifdef SYNTHESIS
    BUFG u_clkbuf (.I(clk_div_reg), .O(clk_int));
`else
    assign clk_int = clk_div_reg;
`endif

    // ---- Reset synchronizer (async assert, sync deassert) ----
    // ASYNC_REG keeps the two synchronizer flops in the same slice for
    // metastability hardening (CDC best practice for the async button reset).
    (* ASYNC_REG = "TRUE" *) logic [1:0] reset_pipe;
    always_ff @(posedge clk_int or posedge reset) begin
        if (reset) reset_pipe <= 2'b11;
        else       reset_pipe <= {reset_pipe[0], 1'b0};
    end
    assign reset_sync = reset_pipe[1];

    logic [XLEN-1:0] full_pc_debug;

    // Instantiate primary processor
    riscv_processor #(
        .XLEN     (XLEN),
        .ENABLE_M (ENABLE_M),
        .ENABLE_C (ENABLE_C)
    ) u_riscv_processor (
        .clk                  (clk_int),
        .reset                (reset_sync),
        .pc_debug             (full_pc_debug),
        .instruction_debug    (),
        .alu_result_debug     (),
        .reg_debug_data1      (),
        .reg_debug_data2      (),
        .mem_debug_data       (),
        .reg_debug_addr1      (),
        .reg_debug_addr2      (),
        .immediate_debug      (),
        .reg_write_debug      (),
        .mem_read_debug       (),
        .mem_write_debug      (),
        .branch_taken_debug   (),
        .trap                 ()
    );

    assign pc_debug = full_pc_debug[15:0];

endmodule
