// RISC-V Processor Performance Diagnostic
//
// Measures instruction-level activity over the canonical program in
// instruction_memory.hex. This is a BOUNDED DIAGNOSTIC over a ~12-instruction
// program, not a sustained performance measurement (e.g. Dhrystone/CoreMark).
//
// Honesty notes (v1.2.0):
//  - The clock here is the SIMULATION testbench clock (100 MHz), NOT a measured
//    FPGA frequency. The synthesized core targets 50 MHz on Basys3; real
//    post-route timing is in build/reports/timing_minimal_impl.rpt.
//  - This single-cycle core has no branch predictor, so no "prediction
//    accuracy" is reported — only the observed branch-taken rate.
//  - No pass/fail "target frequency" or "MIPS target" is asserted; such targets
//    are meaningless for a 12-instruction program.
//  - The instruction mix counts every non-NOP instruction exactly once, so the
//    category percentages sum to 100%.

`timescale 1ns / 1ps

module performance_benchmark;

    localparam real CLK_PERIOD_NS = 10.0;  // simulation testbench clock (100 MHz)

    logic clk;
    logic reset;

    // Processor debug interface
    logic [31:0] pc_debug;
    logic [31:0] instruction_debug;
    logic [31:0] alu_result_debug;
    logic [31:0] reg_debug_data1;
    logic [31:0] reg_debug_data2;
    logic [31:0] mem_debug_data;
    logic [4:0]  reg_debug_addr1;
    logic [4:0]  reg_debug_addr2;
    logic [31:0] immediate_debug;
    logic        reg_write_debug;
    logic        mem_read_debug;
    logic        mem_write_debug;
    logic        branch_taken_debug;
    logic        trap;

    // Activity counters (non-NOP instructions only)
    int total_cycles = 0;
    int end_cycle = 0;
    int instruction_count = 0;
    int branch_count = 0;
    int branch_taken_count = 0;
    int load_count = 0;
    int store_count = 0;
    int alu_op_count = 0;
    int lui_auipc_count = 0;
    int jump_count = 0;
    int other_count = 0;
    int nop_streak = 0;
    logic program_end_detected = 1'b0;

    // Derived metrics
    real ipc = 0.0;
    real execution_time = 0.0;

    // 100 MHz simulation clock
    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS / 2.0) clk = ~clk;
    end

    // DUT instantiation
    riscv_processor dut (
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
        .branch_taken_debug   (branch_taken_debug),
        .trap                 (trap)
    );

    // Activity monitoring. The single-cycle core fetches one instruction per
    // cycle; NOP/zero filler is excluded so the instruction mix sums to 100%.
    always_ff @(posedge clk) begin
        if (reset) begin
            total_cycles         <= 0;
            instruction_count    <= 0;
            branch_count         <= 0;
            branch_taken_count   <= 0;
            load_count           <= 0;
            store_count          <= 0;
            alu_op_count         <= 0;
            lui_auipc_count      <= 0;
            jump_count           <= 0;
            other_count          <= 0;
            nop_streak           <= 0;
            program_end_detected <= 1'b0;
        end else begin
            total_cycles <= total_cycles + 1;

            if (!program_end_detected) begin
                if (instruction_debug != 32'h00000013 &&
                    instruction_debug != 32'h00000000) begin
                    instruction_count <= instruction_count + 1;
                    case (instruction_debug[6:0])
                        7'b1100011: begin // Branch
                            branch_count <= branch_count + 1;
                            if (branch_taken_debug)
                                branch_taken_count <= branch_taken_count + 1;
                        end
                        7'b0000011: load_count      <= load_count + 1;      // Load
                        7'b0100011: store_count     <= store_count + 1;     // Store
                        7'b0110011,
                        7'b0010011: alu_op_count    <= alu_op_count + 1;    // R/I-type ALU
                        7'b0110111,
                        7'b0010111: lui_auipc_count <= lui_auipc_count + 1; // LUI/AUIPC
                        7'b1101111,
                        7'b1100111: jump_count      <= jump_count + 1;      // JAL/JALR
                        default:    other_count     <= other_count + 1;     // SYSTEM/FENCE/etc.
                    endcase
                    nop_streak <= 0;
                end else begin
                    // NOP/zero filler: watch for the program-end tail.
                    nop_streak <= nop_streak + 1;
                    if (nop_streak >= 2) begin
                        program_end_detected <= 1'b1;
                        end_cycle <= total_cycles + 1;
                        $display("Program end detected: %0d non-NOP instructions in %0d cycles",
                                 instruction_count, total_cycles + 1);
                    end
                end
            end
        end
    end

    // Diagnostic report
    task automatic analyze_performance();
        int window_cycles;
        begin
            window_cycles  = (end_cycle > 0) ? end_cycle : total_cycles;
            ipc            = (window_cycles > 0) ? ($itor(instruction_count) / $itor(window_cycles)) : 0.0;
            execution_time = window_cycles * CLK_PERIOD_NS;

            $display("========================================");
            $display("PERFORMANCE DIAGNOSTIC (bounded program)");
            $display("========================================");
            $display("Simulation clock: %0.1f MHz (testbench; NOT measured FPGA Fmax)",
                     1000.0 / CLK_PERIOD_NS);
            $display("Active window: %0d cycles, %0d non-NOP instructions",
                     window_cycles, instruction_count);
            $display("Execution time (sim): %0.1f ns", execution_time);
            $display("");
            $display("Instructions Per Cycle (IPC): %0.3f", ipc);
            $display("Cycles Per Instruction (CPI): %0.3f", (ipc > 0) ? (1.0 / ipc) : 0.0);
            $display("");
            $display("Instruction Mix (sums to 100%%):");
            if (instruction_count > 0) begin
                $display("- ALU (R/I-type):  %0d (%0.1f%%)", alu_op_count,
                         100.0 * $itor(alu_op_count) / $itor(instruction_count));
                $display("- Load:            %0d (%0.1f%%)", load_count,
                         100.0 * $itor(load_count) / $itor(instruction_count));
                $display("- Store:           %0d (%0.1f%%)", store_count,
                         100.0 * $itor(store_count) / $itor(instruction_count));
                $display("- Branch:          %0d (%0.1f%%)", branch_count,
                         100.0 * $itor(branch_count) / $itor(instruction_count));
                $display("- LUI/AUIPC:       %0d (%0.1f%%)", lui_auipc_count,
                         100.0 * $itor(lui_auipc_count) / $itor(instruction_count));
                $display("- Jump (JAL/JALR): %0d (%0.1f%%)", jump_count,
                         100.0 * $itor(jump_count) / $itor(instruction_count));
                $display("- Other:           %0d (%0.1f%%)", other_count,
                         100.0 * $itor(other_count) / $itor(instruction_count));
            end
            $display("");
            $display("Branch Activity (no predictor in this core):");
            $display("- Branches: %0d, taken: %0d, taken rate: %0.1f%%",
                     branch_count, branch_taken_count,
                     (branch_count > 0) ? 100.0 * $itor(branch_taken_count) / $itor(branch_count) : 0.0);
            $display("");
            $display("NOTE: Diagnostic over the canonical ~12-instruction program.");
            $display("      Not a sustained performance measurement; no pass/fail targets.");
            $display("========================================");
        end
    endtask

    // Benchmark execution
    initial begin
        $display("========================================");
        $display("RISC-V Processor Performance Diagnostic");
        $display("========================================");

        reset = 1;
        #50;
        reset = 0;

        // Run long enough to finish the program and detect the NOP tail.
        #5000;

        analyze_performance();
        $display("Performance diagnostic completed.");
        $finish;
    end

    // Timeout watchdog
    initial begin
        #10000;
        $display("Performance diagnostic timeout reached");
        analyze_performance();
        $finish;
    end

endmodule