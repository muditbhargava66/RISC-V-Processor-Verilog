// RISC-V Processor with JTAG-based Debug
// Wraps the main riscv_processor and probes internal signals using JTAG/ILA
// Solves I/O constraints while maintaining full observability

module riscv_processor_jtag_debug (
    input wire clk,
    input wire reset,
    output wire [7:0] status_leds,  // 8 LEDs for basic status
    output wire processor_active,   // Single LED for processor activity
    output wire error_flag         // Single LED for error indication
);

    // Wires for debugging
    wire [31:0] pc_debug;
    wire [31:0] instruction_debug;
    wire [31:0] alu_result_debug;
    wire [31:0] reg_debug_data1;
    wire [31:0] reg_debug_data2;
    wire [31:0] mem_debug_data;
    wire [4:0] reg_debug_addr1;
    wire [4:0] reg_debug_addr2;
    wire [31:0] immediate_debug;
    wire reg_write_debug;
    wire mem_read_debug;
    wire mem_write_debug;
    wire branch_taken_debug;

    // Mark signals for on-chip debugging via ILA/JTAG
    (* mark_debug = "true" *) wire [31:0] debug_pc = pc_debug;
    (* mark_debug = "true" *) wire [31:0] debug_instruction = instruction_debug;
    (* mark_debug = "true" *) wire [31:0] debug_alu_result = alu_result_debug;
    (* mark_debug = "true" *) wire [31:0] debug_reg_data1 = reg_debug_data1;
    (* mark_debug = "true" *) wire [31:0] debug_reg_data2 = reg_debug_data2;
    (* mark_debug = "true" *) wire [31:0] debug_mem_data = mem_debug_data;
    (* mark_debug = "true" *) wire [31:0] debug_immediate = immediate_debug;
    (* mark_debug = "true" *) wire debug_reg_write = reg_write_debug;
    (* mark_debug = "true" *) wire debug_mem_read = mem_read_debug;
    (* mark_debug = "true" *) wire debug_mem_write = mem_write_debug;
    (* mark_debug = "true" *) wire debug_branch_taken = branch_taken_debug;

    // Instantiate primary processor
    riscv_processor u_riscv_processor (
        .clk(clk),
        .reset(reset),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .alu_result_debug(alu_result_debug),
        .reg_debug_data1(reg_debug_data1),
        .reg_debug_data2(reg_debug_data2),
        .mem_debug_data(mem_debug_data),
        .reg_debug_addr1(reg_debug_addr1),
        .reg_debug_addr2(reg_debug_addr2),
        .immediate_debug(immediate_debug),
        .reg_write_debug(reg_write_debug),
        .mem_read_debug(mem_read_debug),
        .mem_write_debug(mem_write_debug),
        .branch_taken_debug(branch_taken_debug)
    );

// External status outputs - minimal I/O usage
    assign status_leds = pc_debug[7:0];      // Show PC lower 8 bits on LEDs
    assign processor_active = |instruction_debug; // Active when instruction is non-zero

    // Helper wires to identify jump and branch operations from the instruction opcode
    wire jump_op = (instruction_debug[6:0] == 7'b1101111) || (instruction_debug[6:0] == 7'b1100111);
    wire branch_op = (instruction_debug[6:0] == 7'b1100011);

    // Detect illegal/unrecognized opcodes when instruction is non-zero
    wire valid_opcode = (instruction_debug[6:0] == 7'b0110011) || // R-type
                         (instruction_debug[6:0] == 7'b0010011) || // I-type ALU
                         (instruction_debug[6:0] == 7'b0000011) || // Load
                         (instruction_debug[6:0] == 7'b0100011) || // Store
                         (instruction_debug[6:0] == 7'b1100011) || // Branch
                         (instruction_debug[6:0] == 7'b1101111) || // JAL
                         (instruction_debug[6:0] == 7'b1100111) || // JALR
                         (instruction_debug[6:0] == 7'b0110111) || // LUI
                         (instruction_debug[6:0] == 7'b0010111) || // AUIPC
                         (instruction_debug == 32'h00000000);     // Reset/uninitialized

    assign error_flag = processor_active && !valid_opcode;

    // Debug signal aggregation for Vivado debug flow
    // Note: mark_debug attributes allow Vivado's "Set Up Debug" wizard or Tcl commands
    // to attach an Integrated Logic Analyzer (ILA) during synthesis/implementation.
    // Explicit ILA/VIO IP blocks are not instantiated directly in Verilog source to keep
    // the core vendor-neutral and avoid IP catalog dependencies.
    (* mark_debug = "true" *) wire [31:0] debug_control_reg = 32'h0;
    (* mark_debug = "true" *) wire [31:0] debug_status_reg = {
        16'h0,
        instruction_debug[6:0],  // opcode
        branch_taken_debug,
        mem_write_debug,
        mem_read_debug,
        reg_write_debug,
        jump_op,
        branch_op,
        processor_active,
        error_flag
    };

endmodule