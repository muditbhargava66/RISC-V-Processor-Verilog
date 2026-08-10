// Register File Module
// 32 x XLEN-bit registers with x0 hardwired to zero
// SystemVerilog implementation with synchronous reset

module register_file #(
    parameter int XLEN = 32,
    parameter int REG_ADDR_WIDTH = 5,
    parameter int NUM_REGS = 32
)(
    input  logic                    clk,
    input  logic                    reset,
    input  logic                    reg_write,
    input  logic [REG_ADDR_WIDTH-1:0] read_reg1,
    input  logic [REG_ADDR_WIDTH-1:0] read_reg2,
    input  logic [REG_ADDR_WIDTH-1:0] write_reg,
    input  logic [XLEN-1:0]         write_data,
    output logic [XLEN-1:0]         read_data1,
    output logic [XLEN-1:0]         read_data2
);

    // Register array (x0 is not stored - hardwired to zero)
    logic [XLEN-1:0] registers [1:NUM_REGS-1];

    integer i;

    // Synchronous write with synchronous reset
    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 1; i < NUM_REGS; i++) begin
                registers[i] <= '0;
            end
        end else if (reg_write && write_reg != '0) begin
            // x0 is hardwired to zero, cannot be written
            registers[write_reg] <= write_data;
        end
    end

    // Asynchronous read (combinational)
    assign read_data1 = (read_reg1 == '0) ? '0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == '0) ? '0 : registers[read_reg2];

    // Synthesis-time assertions
    // synthesis translate_off
    always_ff @(posedge clk) begin
        if (reg_write && write_reg == '0) begin
            $warning("REG_FILE: Attempt to write to x0 (ignored)");
        end
    end
    // synthesis translate_on

endmodule