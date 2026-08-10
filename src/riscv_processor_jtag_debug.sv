// RISC-V Processor with JTAG-based Debug
// SystemVerilog implementation with explicit ILA/VIO instantiation
// Provides full on-chip debugging via JTAG with runtime control

module riscv_processor_jtag_debug #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1,
    parameter bit ENABLE_C = 1'b0,
    parameter int ILA_DEPTH = 1024
)(
    input  logic                  clk,
    input  logic                  reset,
    output logic [7:0]            status_leds,
    output logic                  processor_active,
    output logic                  error_flag
);

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

    // Instantiate primary processor core
    riscv_processor #(
        .XLEN      (XLEN),
        .ENABLE_M  (ENABLE_M),
        .ENABLE_C  (ENABLE_C)
    ) u_riscv_processor (
        .clk                  (clk),
        .reset                (reset),
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
        .branch_taken_debug   (branch_taken_debug)
    );

    // External status outputs - minimal I/O usage
    assign status_leds        = pc_debug[7:0];
    assign processor_active   = |instruction_debug;

    // Helper signals for instruction decode
    logic        jump_op;
    logic        branch_op;
    logic        valid_opcode;

    assign jump_op      = (instruction_debug[6:0] == 7'b1101111) || (instruction_debug[6:0] == 7'b1100111);
    assign branch_op    = (instruction_debug[6:0] == 7'b1100011);

    assign valid_opcode = (instruction_debug[6:0] == 7'b0110011) ||  // R-type
                          (instruction_debug[6:0] == 7'b0010011) ||  // I-type ALU
                          (instruction_debug[6:0] == 7'b0000011) ||  // Load
                          (instruction_debug[6:0] == 7'b0100011) ||  // Store
                          (instruction_debug[6:0] == 7'b1100011) ||  // Branch
                          (instruction_debug[6:0] == 7'b1101111) ||  // JAL
                          (instruction_debug[6:0] == 7'b1100111) ||  // JALR
                          (instruction_debug[6:0] == 7'b0110111) ||  // LUI
                          (instruction_debug[6:0] == 7'b0010111) ||  // AUIPC
                          (instruction_debug == 32'h00000000);       // Reset/NOP

    assign error_flag   = processor_active && !valid_opcode;

    // =====================================================================
    // ILA (Integrated Logic Analyzer) Instantiation
    // Captures all critical processor signals for JTAG-based debugging
    // =====================================================================
    ila_riscv_processor #(
        .C_DATA_DEPTH (ILA_DEPTH)
    ) u_ila (
        .clk     (clk),
        .probe0  (pc_debug),             // [31:0] Program Counter
        .probe1  (instruction_debug),    // [31:0] Current Instruction
        .probe2  (alu_result_debug),     // [31:0] ALU Result
        .probe3  (reg_debug_data1),      // [31:0] Register Read Data 1
        .probe4  (reg_debug_data2),      // [31:0] Register Read Data 2
        .probe5  (mem_debug_data),       // [31:0] Memory Read Data
        .probe6  ({27'd0, reg_debug_addr1}), // [31:0] Register Read Addr 1
        .probe7  ({27'd0, reg_debug_addr2}), // [31:0] Register Read Addr 2
        .probe8  (immediate_debug),      // [31:0] Generated Immediate
        .probe9  ({31'd0, reg_write_debug}), // [31:0] Reg Write Enable
        .probe10 ({31'd0, mem_read_debug}),  // [31:0] Mem Read Enable
        .probe11 ({31'd0, mem_write_debug}), // [31:0] Mem Write Enable
        .probe12 ({31'd0, branch_taken_debug}) // [31:0] Branch Taken
    );

    // =====================================================================
    // VIO (Virtual Input/Output) Instantiation
    // Provides runtime control and status monitoring via JTAG
    // =====================================================================
    vio_riscv_processor u_vio (
        .clk           (clk),
        .probe_in0     (pc_debug),           // [31:0] PC Status
        .probe_in1     (instruction_debug),  // [31:0] Instruction Status
        .probe_in2     ({24'd0, instruction_debug[6:0], branch_taken_debug, 
                          mem_write_debug, mem_read_debug, reg_write_debug,
                          jump_op, branch_op, processor_active, error_flag}), // [31:0] Control Status
        .probe_out0    (),                    // [31:0] Control Register (unused - reserved)
        .probe_out1    ()                     // [31:0] Config Register (unused - reserved)
    );

endmodule


// =====================================================================
// ILA IP Declaration (Black Box)
// Generated by Vivado IP Integrator - customize via IP Catalog
// =====================================================================
(* dont_touch = "true" *)
module ila_riscv_processor #(
    parameter int C_DATA_DEPTH = 1024
)(
    input  logic         clk,
    input  logic [31:0]  probe0,
    input  logic [31:0]  probe1,
    input  logic [31:0]  probe2,
    input  logic [31:0]  probe3,
    input  logic [31:0]  probe4,
    input  logic [31:0]  probe5,
    input  logic [31:0]  probe6,
    input  logic [31:0]  probe7,
    input  logic [31:0]  probe8,
    input  logic [31:0]  probe9,
    input  logic [31:0]  probe10,
    input  logic [31:0]  probe11,
    input  logic [31:0]  probe12
);
    // This module is a black box for synthesis
    // Vivado will replace with actual ILA IP during synthesis
    // Customize in IP Catalog: 13 probes, 32-bit each, depth = C_DATA_DEPTH
endmodule


// =====================================================================
// VIO IP Declaration (Black Box)
// Generated by Vivado IP Integrator - customize via IP Catalog
// =====================================================================
(* dont_touch = "true" *)
module vio_riscv_processor (
    input  logic        clk,
    input  logic [31:0] probe_in0,
    input  logic [31:0] probe_in1,
    input  logic [31:0] probe_in2,
    output logic [31:0] probe_out0,
    output logic [31:0] probe_out1
);
    // This module is a black box for synthesis
    // Vivado will replace with actual VIO IP during synthesis
    // Customize in IP Catalog: 3 probe_in (32-bit), 2 probe_out (32-bit)
endmodule