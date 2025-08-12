// Register File Testbench
// Tests 32x32-bit register file with x0 hardwired to zero

`timescale 1ns / 1ps

module register_file_tb;

    // Clock and reset
    reg clk;
    reg reset;
    
    // Register file signals
    reg reg_write;
    reg [4:0] read_reg1;
    reg [4:0] read_reg2;
    reg [4:0] write_reg;
    reg [31:0] write_data;
    wire [31:0] read_data1;
    wire [31:0] read_data2;
    
    integer test_count = 0;
    integer pass_count = 0;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // DUT instantiation
    register_file dut (
        .clk(clk),
        .reset(reset),
        .reg_write(reg_write),
        .read_reg1(read_reg1),
        .read_reg2(read_reg2),
        .write_reg(write_reg),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );
    
    // Test task
    task test_register_operation;
        input [4:0] wr_reg;
        input [31:0] wr_data;
        input [4:0] rd_reg1;
        input [4:0] rd_reg2;
        input [31:0] expected_data1;
        input [31:0] expected_data2;
        input [79:0] test_name;
        begin
            @(posedge clk);
            reg_write = 1;
            write_reg = wr_reg;
            write_data = wr_data;
            read_reg1 = rd_reg1;
            read_reg2 = rd_reg2;
            
            @(posedge clk);
            reg_write = 0;
            #1; // Small delay for combinational read
            
            test_count = test_count + 1;
            if (read_data1 == expected_data1 && read_data2 == expected_data2) begin
                pass_count = pass_count + 1;
                $display("PASS: %s | R%0d=%08h R%0d=%08h", 
                        test_name, rd_reg1, read_data1, rd_reg2, read_data2);
            end else begin
                $display("FAIL: %s | Expected R%0d=%08h R%0d=%08h, Got R%0d=%08h R%0d=%08h",
                        test_name, rd_reg1, expected_data1, rd_reg2, expected_data2,
                        rd_reg1, read_data1, rd_reg2, read_data2);
            end
        end
    endtask
    
    initial begin
        $display("========================================");
        $display("Register File Comprehensive Test");
        $display("========================================");
        
        // Initialize
        reset = 1;
        reg_write = 0;
        read_reg1 = 0;
        read_reg2 = 0;
        write_reg = 0;
        write_data = 0;
        
        @(posedge clk);
        reset = 0;
        @(posedge clk);
        
        // Test 1: x0 is always zero
        test_register_operation(5'd0, 32'hDEADBEEF, 5'd0, 5'd0, 32'h00000000, 32'h00000000, "x0 hardwired to zero");
        
        // Test 2: Write and read different registers
        test_register_operation(5'd1, 32'h12345678, 5'd1, 5'd0, 32'h12345678, 32'h00000000, "Write x1, read x1 and x0");
        test_register_operation(5'd2, 32'h87654321, 5'd1, 5'd2, 32'h12345678, 32'h87654321, "Write x2, read x1 and x2");
        test_register_operation(5'd31, 32'hFFFFFFFF, 5'd31, 5'd1, 32'hFFFFFFFF, 32'h12345678, "Write x31, read x31 and x1");
        
        // Test 3: Overwrite existing register
        test_register_operation(5'd1, 32'hAAAABBBB, 5'd1, 5'd2, 32'hAAAABBBB, 32'h87654321, "Overwrite x1");
        
        // Test 4: Test all registers can be written (except x0)
        $display("Testing all registers...");
        for (integer i = 1; i < 32; i = i + 1) begin
            test_register_operation(i[4:0], i[31:0] + 32'h1000, i[4:0], 5'd0, i[31:0] + 32'h1000, 32'h00000000, "All registers");
        end
        
        // Test 5: Reset functionality
        $display("Testing reset...");
        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);
        
        // After reset, all registers should be zero
        read_reg1 = 5'd1;
        read_reg2 = 5'd31;
        #1;
        test_count = test_count + 1;
        if (read_data1 == 32'h00000000 && read_data2 == 32'h00000000) begin
            pass_count = pass_count + 1;
            $display("PASS: Reset functionality");
        end else begin
            $display("FAIL: Reset functionality | R1=%08h R31=%08h", read_data1, read_data2);
        end
        
        $display("========================================");
        $display("Register File Test Results: %0d/%0d tests passed", pass_count, test_count);
        if (pass_count == test_count) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        $display("========================================");
        
        $finish;
    end

endmodule