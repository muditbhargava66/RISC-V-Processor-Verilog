# Memory Architecture

## Overview

The processor implements a **Harvard architecture** with separate instruction and data memory spaces, each parameterized independently.

## Instruction Memory (I-MEM)

### Characteristics
- **Read-only** during operation
- **Initialized from hex file** via `$readmemh`
- **Word-aligned access** (32-bit words)
- **Parameterized size** via `IMEM_ADDR_WIDTH`

### Configuration
```systemverilog
module instruction_memory #(
    parameter int ADDR_WIDTH = 8,           // 256 words = 1KB
    parameter string INIT_FILE = "instruction_memory.hex"
)(
    input  logic [31:0] address,
    output logic [31:0] instruction
);
```

### Address Mapping
- **Input**: 32-bit byte address
- **Internal**: Word address = `address[ADDR_WIDTH+1:2]`
- **Depth**: 2^ADDR_WIDTH words (default 256)
- **Total size**: 2^(ADDR_WIDTH+2) bytes (default 1KB)

### Initialization
```systemverilog
initial begin
    for (int i = 0; i < MEM_DEPTH; i++) begin
        memory[i] = 32'h00000000;
    end
    $readmemh(INIT_FILE, memory);
end
```
- **Zero-fill first** - prevents X-propagation
- **Then load hex file** - overrides with program

### Program Image Format (`instruction_memory.hex`)
```
DEAD00B7    # LUI x1, 0xDEAD0
23408093    # ADDI x1, x1, 0x234
00102023    # SW x1, 0(x2)
00002103    # LW x2, 0(x0)
FFF00193    # ADDI x3, x0, -16
00100213    # ADDI x4, x0, 1
0041C263    # BLT x3, x1, target
000002B3    # ADD x5, x0, x0
004202B3    # ADD x5, x4, x0
0041D263    # BGE x3, x1, target
00420333    # ADD x6, x4, x0
00000013    # NOP
```

## Data Memory (D-MEM)

### Characteristics
- **Read/write** accessible
- **Byte/halfword/word granularity**
- **Alignment checking** with error reporting
- **Parameterized size** via `DMEM_ADDR_WIDTH`
- **Synchronous write, asynchronous read**

### Configuration
```systemverilog
module data_memory #(
    parameter int ADDR_WIDTH = 8,  // 256 words = 1KB
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

### Access Types

| funct3 | Operation | Size | Alignment Required |
|--------|-----------|------|-------------------|
| 000 | LB / SB | 8-bit | Any |
| 001 | LH / SH | 16-bit | 2-byte |
| 010 | LW / SW | 32-bit | 4-byte |
| 100 | LBU | 8-bit | Any |
| 101 | LHU | 16-bit | 2-byte |

### Byte Enable Logic
```systemverilog
logic [ADDR_WIDTH-1:0] word_address = address[ADDR_WIDTH+1:2];
logic [1:0] byte_offset = address[1:0];
```

**Store Byte (SB)**:
```systemverilog
case (byte_offset)
    2'b00: memory[word_address][7:0]   <= write_data[7:0];
    2'b01: memory[word_address][15:8]  <= write_data[7:0];
    2'b10: memory[word_address][23:16] <= write_data[7:0];
    2'b11: memory[word_address][31:24] <= write_data[7:0];
endcase
```

**Load Byte (LB)** - Sign extended:
```systemverilog
case (byte_offset)
    2'b00: read_data = {{24{memory[word_address][7]}},  memory[word_address][7:0]};
    2'b01: read_data = {{24{memory[word_address][15]}}, memory[word_address][15:8]};
    2'b10: read_data = {{24{memory[word_address][23]}}, memory[word_address][23:16]};
    2'b11: read_data = {{24{memory[word_address][31]}}, memory[word_address][31:24]};
endcase
```

**Load Byte Unsigned (LBU)** - Zero extended:
```systemverilog
case (byte_offset)
    2'b00: read_data = {24'h000000, memory[word_address][7:0]};
    ...
endcase
```

### Alignment Checking
```systemverilog
if (funct3 == 3'b010 && byte_offset != 2'b00)  // LW/SW
    $display("ERROR: Misaligned word access at %h", address);
if (funct3 == 3'b001 && byte_offset[0] != 1'b0)  // LH/SH
    $display("ERROR: Misaligned halfword access at %h", address);
```

### Synchronous Write / Async Read
```systemverilog
// Write - synchronous with reset
always_ff @(posedge clk) begin
    if (reset) begin
        for (int i = 0; i < MEM_DEPTH; i++)
            memory[i] <= '0;
    end else if (mem_write) begin
        // byte/halfword/word store logic
    end
end

// Read - combinational
always_comb begin
    read_data = '0;
    if (mem_read) begin
        // byte/halfword/word load logic
    end
end
```

## Memory Map

```
0x0000_0000  ┌─────────────────────┐
             │   I-MEM (1KB)       │  0x0000_0000 - 0x0000_03FF
             │ 256 × 32-bit words  │
0x0000_0400  ├─────────────────────┤
             │                     │
             │   Unused / Reserved │
             │                     │
0x1000_0000  ├─────────────────────┤
             │   D-MEM (1KB)       │  0x1000_0000 - 0x1000_03FF
             │ 256 × 32-bit words  │
0x1000_0400  ├─────────────────────┤
             │                     │
             │   Peripherals /     │
             │   Memory Mapped I/O │
             │                     │
0xFFFF_FFFF  └─────────────────────┘
```

> **Note**: Current implementation uses same address space for I-MEM and D-MEM (both at 0x0). In a full SoC, these would be at different base addresses.

## Initialization Sequence

1. **Reset asserted**
2. **I-MEM**: Zero-fill → `$readmemh` from hex file
3. **D-MEM**: Zero-fill all locations
3. **Register File**: All 31 registers → 0 (x0 always 0)
4. **PC**: 0x00000000
5. **Reset deasserted**
6. **First instruction fetch** from address 0x00000000

## Synthesis Considerations

### Distributed RAM vs Block RAM
- **Current**: Distributed RAM (LUTRAM) for both memories
- **Reason**: Small size (1KB each) → efficient in LUTs
- **Scaling**: For larger memories, add `(* ram_style = "block" *)` attribute

```systemverilog
(* ram_style = "block" *) logic [31:0] memory [0:MEM_DEPTH-1];
```

### Initialization in Synthesis
- **Simulation**: `$readmemh` works at time 0
- **Synthesis**: Vivado embeds hex file into bitstream
- **Constraint**: Memory file must be added to project with `set_property file_type {Memory File}`

## Performance Characteristics

| Metric | I-MEM | D-MEM |
|--------|-------|-------|
| Read Latency | 1 cycle (combinational) | 1 cycle (combinational) |
| Write Latency | N/A (read-only) | 1 cycle (registered) |
| Ports | 1 read | 1 read / 1 write |
| Alignment Faults | N/A | Detected & reported |

## Related Documents
- [Architecture Overview](overview.md)
- [Module: Instruction Memory](../modules/instruction-memory.md)
- [Module: Data Memory](../modules/data-memory.md)
- [Module: Register File](../modules/register-file.md)