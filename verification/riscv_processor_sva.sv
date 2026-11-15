// Formal verification wrapper for riscv_processor (SymbiYosys top).
//
// Instantiates the core with free clk/reset and adds a small set of formal
// properties written in a Yosys-friendly style (plain boolean expressions, no
// $isunknown / implication operators). The core's own simulation-only SVA is
// excluded by reading the core with -DIVERILOG (see the .sby [script]); the
// properties below are the formal contract for the wrapper-based proofs.
//
// The instruction memory is initialized from instruction_memory.hex (listed in
// the .sby [files]), so proofs reason about the canonical program image.

module riscv_processor_sva (
    input logic clk,
    input logic reset
);

    logic [31:0] pc_debug, instruction_debug, alu_result_debug;
    logic [31:0] reg_debug_data1, reg_debug_data2, mem_debug_data, immediate_debug;
    logic [4:0]  reg_debug_addr1, reg_debug_addr2;
    logic        reg_write_debug, mem_read_debug, mem_write_debug, branch_taken_debug;
    logic        trap;

    riscv_processor dut (
        .clk(clk), .reset(reset),
        .pc_debug(pc_debug), .instruction_debug(instruction_debug),
        .alu_result_debug(alu_result_debug),
        .reg_debug_data1(reg_debug_data1), .reg_debug_data2(reg_debug_data2),
        .mem_debug_data(mem_debug_data),
        .reg_debug_addr1(reg_debug_addr1), .reg_debug_addr2(reg_debug_addr2),
        .immediate_debug(immediate_debug),
        .reg_write_debug(reg_write_debug), .mem_read_debug(mem_read_debug),
        .mem_write_debug(mem_write_debug), .branch_taken_debug(branch_taken_debug),
        .trap(trap)
    );

    // Formal environment: assume a reset pulse in the first cycle so the
    // synchronous reset loads PC=0. PC word-alignment is an invariant of the
    // reset-initialized core, not of an arbitrary power-on state. An init flag
    // (high only in the first cycle) expresses this in standard SystemVerilog
    // without the Yosys-specific $initstate, which slang does not accept.
    logic init_cycle = 1'b1;
    always @(posedge clk) init_cycle <= 1'b0;
    assume property (@(posedge clk) !init_cycle || reset);

    // x0 is hardwired to zero on both read ports
    assert property (@(posedge clk) disable iff (reset)
        (dut.rs1 != 5'd0) || (dut.read_data1 == 32'd0));
    assert property (@(posedge clk) disable iff (reset)
        (dut.rs2 != 5'd0) || (dut.read_data2 == 32'd0));

    // PC remains word-aligned for the canonical program image
    assert property (@(posedge clk) disable iff (reset)
        (dut.pc_current[1:0] == 2'b00));

    // A register write is only asserted for opcodes that write registers
    assert property (@(posedge clk) disable iff (reset)
        (!dut.reg_write) ||
        (dut.opcode == 7'b0110011) || (dut.opcode == 7'b0010011) ||
        (dut.opcode == 7'b0000011) || (dut.opcode == 7'b1101111) ||
        (dut.opcode == 7'b1100111) || (dut.opcode == 7'b0110111) ||
        (dut.opcode == 7'b0010111));

    // Reachability covers
    cover property (@(posedge clk) disable iff (reset) dut.branch_taken);
    cover property (@(posedge clk) disable iff (reset) dut.mem_write);
    cover property (@(posedge clk) disable iff (reset) dut.mem_read);

endmodule