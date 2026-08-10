# Data Memory Module Reference

## Module: `data_memory`

**File**: `src/data_memory.sv`  
**Lines**: ~160  
**Parameters**: `ADDR_WIDTH=8`, `XLEN=32`

### Interface

```systemverilog
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
```

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ADDR_WIDTH` | 8 | Address bits for word addressing (256 words = 1KB) |
| `XLEN` | 32 | Data width |

### Access Types

| funct3 | Operation | Size | Sign Extension | Alignment |
|--------|-----------|------|----------------|-----------|
| 000 | LB / SB | 8-bit | Sign | Any |
| 001 | LH / SH | 16-bit | Sign | 2-byte |
| 010 | LW / SW | 32-bit | N/A | 4-byte |
| 100 | LBU | 8-bit | Zero | Any |
| 101 | LHU | 16-bit | Zero | 2-byte |

### Write Path (Synchronous)

```systemverilog
always_ff @(posedge clk) begin
    if (reset) begin
        for (int i = 0; i < MEM_DEPTH; i++) begin
            memory[i] <= '0;
        end
    end else if (mem_write) begin
        unique case (funct3)
            FUNCT3_SB: begin  // Store Byte
                unique case (byte_offset)
                    2'b00: memory[word_address][7:0]   <= write_data[7:0];
                    2'b01: memory[word_address][15:8]  <= write_data[7:0];
                    2'b10: memory[word_address][23:16] <= write_data[7:0];
                    2'b11: memory[word_address][31:24] <= write_data[7:0];
                endcase
            end
            FUNCT3_SH: begin  // Store Halfword
                if (byte_offset[0] != 0) begin
                    $display("ERROR: Misaligned store halfword at %h", address);
                end else if (byte_offset[1] == 1'b0)
                    memory[word_address][15:0] <= write_data[15:0];
                else
                    memory[word_address][31:16] <= write_data[15:0];
            end
            FUNCT3_SW: begin  // Store Word
                if (byte_offset != 2'b00)
                    $display("ERROR: Misaligned store word at %h", address);
                else
                    memory[word_address] <= write_data;
            end
            default: begin
                $display("WARNING: Invalid store funct3 %03b at %h", funct3, address);
            end
        endcase
    end
end
```

### Read Path (Combinational)

```systemverilog
always_comb begin
    read_data = '0;
    if (mem_read) begin
        unique case (funct3)
            FUNCT3_LB: begin  // Load Byte (sign-extended)
                unique case (byte_offset)
                    2'b00: read_data = {{(XLEN-8){memory[word_address][7]}},  memory[word_address][7:0]};
                    2'b01: read_data = {{(XLEN-8){memory[word_address][15]}}, memory[word_address][15:8]};
                    2'b10: read_data = {{(XLEN-8){memory[word_address][23]}}, memory[word_address][23:16]};
                    2'b11: read_data = {{(XLEN-8){memory[word_address][31]}}, memory[word_address][31:24]};
                endcase
            end
            FUNCT3_LH: begin  // Load Halfword (sign-extended)
                if (byte_offset[0] != 0) begin
                    $display("ERROR: Misaligned load halfword at %h", address);
                    read_data = '0;
                end else if (byte_offset[1] == 1'b0)
                    read_data = {{(XLEN-16){memory[word_address][15]}}, memory[word_address][15:0]};
                else
                    read_data = {{(XLEN-16){memory[word_address][31]}}, memory[word_address][31:16]};
            end
            FUNCT3_LW: begin  // Load Word
                if (byte_offset != 2'b00) begin
                    $display("ERROR: Misaligned load word at %h", address);
                    read_data = '0;
                end else
                    read_data = memory[word_address];
            end
            FUNCT3_LBU: begin  // Load Byte Unsigned
                unique case (byte_offset)
                    2'b00: read_data = {{(XLEN-8){1'b0}}, memory[word_address][7:0]};
                    2'b01: read_data = {{(XLEN-8){1'b0}}, memory[word_address][15:8]};
                    2'b10: read_data = {{(XLEN-8){1'b0}}, memory[word_address][23:16]};
                    2'b11: read_data = {{(XLEN-8){1'b0}}, memory[word_address][31:24]};
                endcase
            end
            FUNCT3_LHU: begin  // Load Halfword Unsigned
                if (byte_offset[0] != 0) begin
                    $display("ERROR: Misaligned load halfword unsigned at %h", address);
                    read_data = '0;
                end else if (byte_offset[1] == 1'b0)
                    read_data = {{(XLEN-16){1'b0}}, memory[word_address][15:0]};
                else
                    read_data = {{(XLEN-16){1'b0}}, memory[word_address][31:16]};
            end
            default: begin
                $display("WARNING: Invalid load funct3 %03b at %h", funct3, address);
                read_data = '0;
            end
        endcase
    end
end
```

### Address Mapping

- **Word address**: `address[ADDR_WIDTH+1:2]`
- **Byte offset**: `address[1:0]`
- **Depth**: 2^ADDR_WIDTH words (default 256 = 1KB)

### Alignment Requirements

| Operation | Required Alignment | Error If |
|-----------|-------------------|----------|
| LB/LBU/SB | Any | Never |
| LH/LHU/SH | 2-byte | `address[0] != 0` |
| LW/SW | 4-byte | `address[1:0] != 0` |

### Reset Behavior

- All memory locations cleared to 0 on reset
- Reset is synchronous
- Takes MEM_DEPTH cycles to clear all locations

### Related Documents
- [Core Processor](../modules/core-processor.md)
- [Memory Architecture](../architecture/memory.md)