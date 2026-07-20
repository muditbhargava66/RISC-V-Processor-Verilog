// RISC-V Processor Minimal Version for FPGA Deployment
// Wraps the main riscv_processor and exposes only a minimal PC debug port to fit I/O constraints

module riscv_processor_minimal (
    input wire clk,
    input wire reset,
    output wire [15:0] pc_debug
);

    wire [31:0] full_pc_debug;
    
    // Instantiate primary processor
    riscv_processor u_riscv_processor (
        .clk(clk),
        .reset(reset),
        .pc_debug(full_pc_debug),
        .instruction_debug(),
        .alu_result_debug(),
        .reg_debug_data1(),
        .reg_debug_data2(),
        .mem_debug_data(),
        .reg_debug_addr1(),
        .reg_debug_addr2(),
        .immediate_debug(),
        .reg_write_debug(),
        .mem_read_debug(),
        .mem_write_debug(),
        .branch_taken_debug()
    );

    assign pc_debug = full_pc_debug[15:0];

endmodule