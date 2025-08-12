`timescale 1ns / 1ps

module simple_processor_tb;

    // Clock and reset
    reg clk;
    reg reset;
    
    // Debug outputs
    wire [31:0] pc_debug;
    wire [31:0] instruction_debug;
    wire [31:0] alu_result_debug;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // DUT instantiation
    riscv_processor dut (
        .clk(clk),
        .reset(reset),
        .pc_debug(pc_debug),
        .instruction_debug(instruction_debug),
        .alu_result_debug(alu_result_debug)
    );
    
    // Test sequence
    initial begin
        $display("========================================");
        $display("RISC-V Processor Simple Test");
        $display("========================================");
        
        // Initialize
        reset = 1;
        #20;
        reset = 0;
        
        $display("Starting processor execution...");
        $display("PC\t\tInstruction\tALU Result");
        $display("----------------------------------------");
        
        // Run for several clock cycles
        repeat(20) begin
            @(posedge clk);
            $display("%08h\t%08h\t%08h", pc_debug, instruction_debug, alu_result_debug);
        end
        
        $display("========================================");
        $display("Simple processor test completed");
        $display("✅ Processor executed %0d instructions", (pc_debug / 4) + 1);
        $display("========================================");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #1000;
        $display("❌ Test timeout - processor may be stuck");
        $finish;
    end

endmodule