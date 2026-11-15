// RISC-V Processor with JTAG-based Debug
// SystemVerilog implementation with explicit ILA/VIO instantiation.
// Provides full on-chip debugging via JTAG with runtime control.
//
// Clocking/reset matches the minimal wrapper: 100 MHz board clock divided to
// 50 MHz, asynchronous button reset synchronized before use. error_flag is
// driven by the core's trap signal (illegal instruction / misaligned access),
// which is accurate for all decoded instructions including SYSTEM and FENCE.

module riscv_processor_jtag_debug #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1,
    parameter bit ENABLE_C = 1'b0
)(
    input  logic                  clk,      // 100 MHz board oscillator
    input  logic                  reset,    // async push button, active high
    output logic [7:0]            status_leds,
    output logic                  processor_active,
    output logic                  error_flag
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

    // Internal debug signals from processor core
    logic [XLEN-1:0] pc_debug;
    logic [XLEN-1:0] instruction_debug;
    logic [XLEN-1:0] alu_result_debug;
    logic [XLEN-1:0] reg_debug_data1;
    logic [XLEN-1:0] reg_debug_data2;
    logic [XLEN-1:0] mem_debug_data;
    logic [4:0]      reg_debug_addr1;
    logic [4:0]      reg_debug_addr2;
    logic [XLEN-1:0] immediate_debug;
    logic            reg_write_debug;
    logic            mem_read_debug;
    logic            mem_write_debug;
    logic            branch_taken_debug;
    logic            trap;

    // Instantiate primary processor core
    riscv_processor #(
        .XLEN      (XLEN),
        .ENABLE_M  (ENABLE_M),
        .ENABLE_C  (ENABLE_C)
    ) u_riscv_processor (
        .clk                  (clk_int),
        .reset                (reset_sync),
        .pc_debug             (pc_debug),
        .instruction_debug    (instruction_debug),
        .alu_result_debug     (alu_result_debug),
        .reg_debug_data1      (reg_debug_data1),
        .reg_debug_data2      (reg_debug_data2),
        .mem_debug_data       (mem_debug_data),
        .reg_debug_addr1      (reg_debug_addr1),
        .reg_debug_addr2      (reg_debug_addr2),
        .immediate_debug      (immediate_debug),
        .reg_write_debug      (reg_write_debug),
        .mem_read_debug       (mem_read_debug),
        .mem_write_debug      (mem_write_debug),
        .branch_taken_debug   (branch_taken_debug),
        .trap                 (trap)
    );

    // External status outputs - minimal I/O usage
    assign status_leds        = pc_debug[7:0];
    assign processor_active   = |instruction_debug;
    assign error_flag         = trap;

    // Helper signals for VIO status word
    logic jump_op;
    logic branch_op;
    assign jump_op   = (instruction_debug[6:0] == 7'b1101111) || (instruction_debug[6:0] == 7'b1100111);
    assign branch_op = (instruction_debug[6:0] == 7'b1100011);

    // =====================================================================
    // ILA (Integrated Logic Analyzer) Instantiation
    // =====================================================================
    // ILA depth (1024) is fixed by create_debug_ip in scripts/build_vivado.tcl;
    // the generated IP exposes no overridable C_DATA_DEPTH parameter.
    ila_riscv_processor u_ila (
        .clk     (clk_int),
        .probe0  (pc_debug),
        .probe1  (instruction_debug),
        .probe2  (alu_result_debug),
        .probe3  (reg_debug_data1),
        .probe4  (reg_debug_data2),
        .probe5  (mem_debug_data),
        .probe6  ({27'd0, reg_debug_addr1}),
        .probe7  ({27'd0, reg_debug_addr2}),
        .probe8  (immediate_debug),
        .probe9  ({31'd0, reg_write_debug}),
        .probe10 ({31'd0, mem_read_debug}),
        .probe11 ({31'd0, mem_write_debug}),
        .probe12 ({31'd0, branch_taken_debug})
    );

    // =====================================================================
    // VIO (Virtual Input/Output) Instantiation
    // =====================================================================
    vio_riscv_processor u_vio (
        .clk           (clk_int),
        .probe_in0     (pc_debug),
        .probe_in1     (instruction_debug),
        // 17 + 7 + 8 = 32 bits (was 24 + 7 + 8 = 39, truncated)
        .probe_in2     ({17'd0, instruction_debug[6:0], branch_taken_debug,
                          mem_write_debug, mem_read_debug, reg_write_debug,
                          jump_op, branch_op, processor_active, error_flag}),
        .probe_out0    (),
        .probe_out1    ()
    );

endmodule


// =====================================================================
// ILA / VIO debug IP
// The ila_riscv_processor and vio_riscv_processor modules instantiated above
// are generated by scripts/build_vivado.tcl (create_debug_ip) for the jtag
// target: ILA = 13 x 32-bit probes, depth 1024; VIO = 3 in / 2 out, 32-bit.
// They are intentionally NOT defined here. Declaring black-box modules with
// the same names collides with the generated IP stubs (Synth 8-9873), and the
// IP stub has no C_DATA_DEPTH parameter to override (Synth 8-7136). Vivado
// binds the instantiations to the generated IP by name.
// =====================================================================
