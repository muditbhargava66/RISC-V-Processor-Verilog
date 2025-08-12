// Data Memory Module
// 1KB data memory with byte, halfword, and word access

module data_memory (
    input wire clk,
    input wire mem_read,
    input wire mem_write,
    input wire [31:0] address,
    input wire [31:0] write_data,
    input wire [2:0] funct3,
    output reg [31:0] read_data
);

    // Data memory - 1KB (256 words)
    reg [31:0] memory [0:255];
    
    // Word-aligned address (divide by 4)
    wire [7:0] word_address = address[9:2];
    wire [1:0] byte_offset = address[1:0];
    
    // Initialize memory to zero
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = 32'h00000000;
        end
    end
    
    // Write operation
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin // SB (Store Byte)
                    case (byte_offset)
                        2'b00: memory[word_address][7:0]   <= write_data[7:0];
                        2'b01: memory[word_address][15:8]  <= write_data[7:0];
                        2'b10: memory[word_address][23:16] <= write_data[7:0];
                        2'b11: memory[word_address][31:24] <= write_data[7:0];
                    endcase
                end
                3'b001: begin // SH (Store Halfword)
                    if (byte_offset[0] == 1'b0) begin
                        if (byte_offset[1] == 1'b0)
                            memory[word_address][15:0] <= write_data[15:0];
                        else
                            memory[word_address][31:16] <= write_data[15:0];
                    end
                end
                3'b010: begin // SW (Store Word)
                    if (byte_offset == 2'b00)
                        memory[word_address] <= write_data;
                end
            endcase
        end
    end
    
    // Read operation
    always @(*) begin
        read_data = 32'h00000000;
        if (mem_read) begin
            case (funct3)
                3'b000: begin // LB (Load Byte)
                    case (byte_offset)
                        2'b00: read_data = {{24{memory[word_address][7]}},  memory[word_address][7:0]};
                        2'b01: read_data = {{24{memory[word_address][15]}}, memory[word_address][15:8]};
                        2'b10: read_data = {{24{memory[word_address][23]}}, memory[word_address][23:16]};
                        2'b11: read_data = {{24{memory[word_address][31]}}, memory[word_address][31:24]};
                    endcase
                end
                3'b001: begin // LH (Load Halfword)
                    if (byte_offset[0] == 1'b0) begin
                        if (byte_offset[1] == 1'b0)
                            read_data = {{16{memory[word_address][15]}}, memory[word_address][15:0]};
                        else
                            read_data = {{16{memory[word_address][31]}}, memory[word_address][31:16]};
                    end
                end
                3'b010: begin // LW (Load Word)
                    if (byte_offset == 2'b00)
                        read_data = memory[word_address];
                end
                3'b100: begin // LBU (Load Byte Unsigned)
                    case (byte_offset)
                        2'b00: read_data = {24'h000000, memory[word_address][7:0]};
                        2'b01: read_data = {24'h000000, memory[word_address][15:8]};
                        2'b10: read_data = {24'h000000, memory[word_address][23:16]};
                        2'b11: read_data = {24'h000000, memory[word_address][31:24]};
                    endcase
                end
                3'b101: begin // LHU (Load Halfword Unsigned)
                    if (byte_offset[0] == 1'b0) begin
                        if (byte_offset[1] == 1'b0)
                            read_data = {16'h0000, memory[word_address][15:0]};
                        else
                            read_data = {16'h0000, memory[word_address][31:16]};
                    end
                end
            endcase
        end
    end

endmodule