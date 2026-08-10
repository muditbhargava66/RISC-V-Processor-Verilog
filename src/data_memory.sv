// Data Memory Module
// Parameterized data memory with byte, halfword, and word access
// SystemVerilog implementation with synchronous reset

module data_memory #(
    parameter int ADDR_WIDTH = 8,
    parameter int XLEN = 32
)(
    input  logic                 clk,
    input  logic                 reset,
    input  logic                 mem_read,
    input  logic                 mem_write,
    input  logic [XLEN-1:0]      address,
    input  logic [XLEN-1:0]      write_data,
    input  logic [2:0]           funct3,
    output logic [XLEN-1:0]      read_data
);

    import riscv_pkg::*;

    localparam int MEM_DEPTH = 2**ADDR_WIDTH;
    logic [XLEN-1:0] memory [0:MEM_DEPTH-1];

    // Word-aligned address (divide by 4)
    logic [ADDR_WIDTH-1:0] word_address;
    logic [1:0]            byte_offset;

    assign word_address = address[ADDR_WIDTH+1:2];
    assign byte_offset  = address[1:0];

    integer i;

    // Write operation with synchronous reset
    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < MEM_DEPTH; i++) begin
                memory[i] <= '0;
            end
        end else if (mem_write) begin
            unique case (funct3)
                FUNCT3_SB: begin // SB (Store Byte)
                    unique case (byte_offset)
                        2'b00: memory[word_address][7:0]   <= write_data[7:0];
                        2'b01: memory[word_address][15:8]  <= write_data[7:0];
                        2'b10: memory[word_address][23:16] <= write_data[7:0];
                        2'b11: memory[word_address][31:24] <= write_data[7:0];
                    endcase
                end

                FUNCT3_SH: begin // SH (Store Halfword)
                    if (byte_offset[0] != 0) begin
                        // synthesis translate_off
                        $display("ERROR: Misaligned store halfword at address %h", address);
                        // synthesis translate_on
                    end else begin
                        if (byte_offset[1] == 1'b0)
                            memory[word_address][15:0] <= write_data[15:0];
                        else
                            memory[word_address][31:16] <= write_data[15:0];
                    end
                end

                FUNCT3_SW: begin // SW (Store Word)
                    if (byte_offset != 2'b00) begin
                        // synthesis translate_off
                        $display("ERROR: Misaligned store word at address %h", address);
                        // synthesis translate_on
                    end else begin
                        memory[word_address] <= write_data;
                    end
                end

                default: begin
                    // Invalid funct3 for store - ignore
                    // synthesis translate_off
                    $display("WARNING: Invalid store funct3: %03b at address %h", funct3, address);
                    // synthesis translate_on
                end
            endcase
        end
    end

    // Read operation (combinational)
    always_comb begin
        read_data = '0;
        if (mem_read) begin
            unique case (funct3)
                FUNCT3_LB: begin // LB (Load Byte)
                    unique case (byte_offset)
                        2'b00: read_data = {{(XLEN-8){memory[word_address][7]}},  memory[word_address][7:0]};
                        2'b01: read_data = {{(XLEN-8){memory[word_address][15]}}, memory[word_address][15:8]};
                        2'b10: read_data = {{(XLEN-8){memory[word_address][23]}}, memory[word_address][23:16]};
                        2'b11: read_data = {{(XLEN-8){memory[word_address][31]}}, memory[word_address][31:24]};
                    endcase
                end

                FUNCT3_LH: begin // LH (Load Halfword)
                    if (byte_offset[0] != 0) begin
                        // synthesis translate_off
                        $display("ERROR: Misaligned load halfword at address %h", address);
                        // synthesis translate_on
                        read_data = '0;
                    end else begin
                        if (byte_offset[1] == 1'b0)
                            read_data = {{(XLEN-16){memory[word_address][15]}}, memory[word_address][15:0]};
                        else
                            read_data = {{(XLEN-16){memory[word_address][31]}}, memory[word_address][31:16]};
                    end
                end

                FUNCT3_LW: begin // LW (Load Word)
                    if (byte_offset != 2'b00) begin
                        // synthesis translate_off
                        $display("ERROR: Misaligned load word at address %h", address);
                        // synthesis translate_on
                        read_data = '0;
                    end else begin
                        read_data = memory[word_address];
                    end
                end

                FUNCT3_LBU: begin // LBU (Load Byte Unsigned)
                    unique case (byte_offset)
                        2'b00: read_data = {{(XLEN-8){1'b0}}, memory[word_address][7:0]};
                        2'b01: read_data = {{(XLEN-8){1'b0}}, memory[word_address][15:8]};
                        2'b10: read_data = {{(XLEN-8){1'b0}}, memory[word_address][23:16]};
                        2'b11: read_data = {{(XLEN-8){1'b0}}, memory[word_address][31:24]};
                    endcase
                end

                FUNCT3_LHU: begin // LHU (Load Halfword Unsigned)
                    if (byte_offset[0] != 0) begin
                        // synthesis translate_off
                        $display("ERROR: Misaligned load halfword unsigned at address %h", address);
                        // synthesis translate_on
                        read_data = '0;
                    end else begin
                        if (byte_offset[1] == 1'b0)
                            read_data = {{(XLEN-16){1'b0}}, memory[word_address][15:0]};
                        else
                            read_data = {{(XLEN-16){1'b0}}, memory[word_address][31:16]};
                    end
                end

                default: begin
                    // Invalid funct3 for load - return 0
                    read_data = '0;
                    // synthesis translate_off
                    $display("WARNING: Invalid load funct3: %03b at address %h", funct3, address);
                    // synthesis translate_on
                end
            endcase
        end
    end

endmodule