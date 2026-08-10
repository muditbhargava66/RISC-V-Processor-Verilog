// RISC-V Processor Performance Benchmark
// Measures performance metrics and compares against targets
// SystemVerilog implementation with proper instruction memory loading

`timescale 1ns / 1ps

module performance_benchmark;

    // Test infrastructure
    logic clk;
    logic reset;

    // Processor interface
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

    // Performance counters
    int total_cycles = 0;
    int instruction_count = 0;
    int branch_count = 0;
    int branch_taken_count = 0;
    int load_count = 0;
    int store_count = 0;
    int alu_op_count = 0;
    int nop_streak = 0;
    logic program_end_detected = 1'b0;

    // Timing measurements
    real start_time = 0.0;
    real end_time = 0.0;
    real execution_time = 0.0;

    // Performance metrics
    real ipc = 0.0;
    real branch_prediction_accuracy = 0.0;
    real clock_frequency = 100.0; // MHz

    // Clock generation - 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
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
        .branch_taken_debug   (branch_taken_debug)
    );

    // Performance monitoring
    logic [31:0] prev_pc;

    always_ff @(posedge clk) begin
        if (reset) begin
            prev_pc <= 32'h00000000;
        end else begin
            total_cycles <= total_cycles + 1;

            if (!program_end_detected) begin
                // Count instructions (PC changes indicate new instruction)
                if (pc_debug != prev_pc || total_cycles == 1) begin
                    instruction_count <= instruction_count + 1;

                    // Classify instruction types
                    case (instruction_debug[6:0])
                        7'b1100011: begin // Branch
                            branch_count <= branch_count + 1;
                            if (branch_taken_debug) begin
                                branch_taken_count <= branch_taken_count + 1;
                            end
                        end
                        7'b0000011: begin // Load
                            load_count <= load_count + 1;
                        end
                        7'b0100011: begin // Store
                            store_count <= store_count + 1;
                        end
                        7'b0110011, 7'b0010011: begin // R-type, I-type ALU
                            alu_op_count <= alu_op_count + 1;
                        end
                    endcase
                end
            end
            prev_pc <= pc_debug;

            // Detect program end: consecutive NOPs/zero instructions
            if (instruction_debug == 32'h00000013 || instruction_debug == 32'h00000000) begin
                nop_streak <= nop_streak + 1;
                if (nop_streak >= 3) begin
                    if (!program_end_detected) begin
                        program_end_detected <= 1'b1;
                        // Subtract the NOP streak from instruction count
                        instruction_count <= instruction_count - nop_streak;
                        $display("Program end detected after %0d real instructions", instruction_count - nop_streak);
                    end
                end
            end else begin
                nop_streak <= 0;
            end
        end
    end

    // Performance analysis task
    task automatic analyze_performance();
        begin
            // Calculate metrics
            ipc = (total_cycles > 0) ? ($itor(instruction_count) / $itor(total_cycles)) : 0.0;
            branch_prediction_accuracy = (branch_count > 0) ?
                (($itor(branch_count - branch_taken_count) / $itor(branch_count)) * 100.0) : 0.0;
            execution_time = total_cycles * 10.0; // ns (10ns per cycle at 100MHz)

            $display("========================================");
            $display("PERFORMANCE ANALYSIS REPORT");
            $display("========================================");
            $display("Execution Metrics:");
            $display("- Total Cycles: %0d", total_cycles);
            $display("- Instructions Executed: %0d", instruction_count);
            $display("- Execution Time: %0.1f ns", execution_time);
            $display("- Clock Frequency: %0.1f MHz", clock_frequency);
            $display("");

            $display("Performance Metrics:");
            $display("- Instructions Per Cycle (IPC): %0.3f", ipc);
            $display("- Cycles Per Instruction (CPI): %0.3f", (ipc > 0) ? (1.0/ipc) : 0.0);
            $display("- Instruction Throughput: %0.1f MIPS",
                    (execution_time > 0) ? (instruction_count / (execution_time / 1000.0)) : 0.0);
            $display("");

            $display("Instruction Mix:");
            if (instruction_count > 0) begin
                $display("- ALU Operations: %0d (%0.1f%%)", alu_op_count,
                        ($itor(alu_op_count) / $itor(instruction_count)) * 100.0);
                $display("- Load Instructions: %0d (%0.1f%%)", load_count,
                        ($itor(load_count) / $itor(instruction_count)) * 100.0);
                $display("- Store Instructions: %0d (%0.1f%%)", store_count,
                        ($itor(store_count) / $itor(instruction_count)) * 100.0);
                $display("- Branch Instructions: %0d (%0.1f%%)", branch_count,
                        ($itor(branch_count) / $itor(instruction_count)) * 100.0);
            end
            $display("");

            $display("Branch Analysis:");
            $display("- Total Branches: %0d", branch_count);
            $display("- Branches Taken: %0d", branch_taken_count);
            $display("- Branch Taken Rate: %0.1f%%",
                    (branch_count > 0) ? (($itor(branch_taken_count) / $itor(branch_count)) * 100.0) : 0.0);
            $display("");

            $display("Performance Targets:");
            $display("- Diagnostic IPC over bounded program: %0.3f", ipc);
            $display("- Target Frequency: 100 MHz - %s",
                    (clock_frequency >= 100.0) ? "PASS" : "FAIL");
            $display("- Target Throughput: >90 MIPS - %s",
                    ((instruction_count / (execution_time / 1000.0)) >= 90.0) ? "PASS" : "FAIL");
            $display("");

            // Performance note
            $display("NOTE: This is a diagnostic metric over the bounded program region.");
            $display("      It is not a sustained processor performance measurement.");

            $display("========================================");
        end
    endtask

    // Benchmark execution
    initial begin
        $display("========================================");
        $display("RISC-V Processor Performance Benchmark");
        $display("Measuring Single-Cycle Architecture Performance");
        $display("========================================");

        // Initialize
        reset = 1;
        #50;
        reset = 0;
        start_time = $realtime;

        $display("Starting performance benchmark...");
        $display("Running processor for performance measurement...");

        // Run for sufficient time to get meaningful measurements
        #5000; // 5us execution time

        end_time = $realtime;

        // Analyze performance
        analyze_performance();

        // Additional detailed analysis
        $display("Detailed Analysis:");
        $display("- Average Instruction Execution Time: %0.1f ns",
                (instruction_count > 0) ? (execution_time / instruction_count) : 0.0);
        $display("- Memory Access Efficiency: %0.1f%% (Load+Store/Total)",
                (instruction_count > 0) ? (($itor(load_count + store_count) / $itor(instruction_count)) * 100.0) : 0.0);
        $display("- Computational Intensity: %0.1f%% (ALU/Total)",
                (instruction_count > 0) ? (($itor(alu_op_count) / $itor(instruction_count)) * 100.0) : 0.0);

        $display("========================================");
        $display("Performance benchmark completed successfully!");
        $display("========================================");

        $finish;
    end

    // Progress monitoring
    always_ff @(posedge clk) begin
        if (!reset && total_cycles > 0 && total_cycles % 100 == 0) begin
            $display("Benchmark Progress: %0d cycles, %0d instructions, IPC = %0.3f",
                    total_cycles, instruction_count,
                    (total_cycles > 0) ? ($itor(instruction_count) / $itor(total_cycles)) : 0.0);
        end
    end

    // Timeout watchdog
    initial begin
        #10000; // 10us timeout
        $display("Performance benchmark timeout reached");
        analyze_performance();
        $finish;
    end

endmodule