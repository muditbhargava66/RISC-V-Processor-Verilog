`timescale 1ns / 1ps
// Data Memory Module
// Parameterized data memory with byte, halfword, and word access
// SystemVerilog implementation with synchronous write / asynchronous read
//
// Memory map: MEM_DEPTH = 2**ADDR_WIDTH words of XLEN bits each, byte-addressed
// over [0, MEM_DEPTH*4). With the default ADDR_WIDTH=8 this is 256 words = 1 KB
// (byte addresses 0x000..0x3FF). Addresses above this range are flagged via
// addr_out_of_range so the core can raise trap; the access itself is suppressed
// to prevent silent wrap-around aliasing into valid memory.

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
    output logic [XLEN-1:0]      read_data,
    output logic                 addr_out_of_range
);

    import riscv_pkg::*;

    localparam int MEM_DEPTH = 2**ADDR_WIDTH;
    logic [XLEN-1:0] memory [0:MEM_DEPTH-1];

    // Word-aligned address (divide by 4)
    logic [ADDR_WIDTH-1:0] word_address;
    logic [1:0]            byte_offset;

    assign word_address = address[ADDR_WIDTH+1:2];
    assign byte_offset  = address[1:0];

    // Range check: any address bit above the byte-address space means the access
    // is outside physical memory. ADDR_WIDTH+2 bits cover MEM_DEPTH*4 bytes.
    logic addr_hi;
    assign addr_hi           = |address[XLEN-1:ADDR_WIDTH+2];
    assign addr_out_of_range = (mem_read || mem_write) && addr_hi;

    integer i;

    // Power-on / simulation initialization. The memory is NOT cleared on reset:
    // resetting a 256-word array would force a flip-flop implementation (~8K FFs)
    // and block RAM inference. Initial values map to RAM init contents instead.
    initial begin
        for (i = 0; i < MEM_DEPTH; i++) begin
            memory[i] = '0;
        end
    end

    // Write operation (synchronous). Reset does not clear memory contents.
    // Out-of-range writes are suppressed (flagged by addr_out_of_range).
    always_ff @(posedge clk) begin
        if (mem_write && !addr_hi) begin
            case (funct3)
                FUNCT3_SB: begin // SB (Store Byte)
                    case (byte_offset)
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

    // Read operation (combinational). Out-of-range reads return zero.
    always_comb begin
        read_data = '0;
        if (mem_read && !addr_hi) begin
            case (funct3)
                FUNCT3_LB: begin // LB (Load Byte)
                    case (byte_offset)
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
                    case (byte_offset)
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
