# Instruction Memory Module Reference

## Module: `instruction_memory`

**File**: `src/instruction_memory.sv`  
**Lines**: ~30  
**Parameters**: `ADDR_WIDTH=8`, `INIT_FILE="instruction_memory.hex"`

### Interface

```systemverilog
module instruction_memory #(
    parameter int ADDR_WIDTH = 8,
    parameter string INIT_FILE = "instruction_memory.hex"
)(
    input  logic [31:0] address,
    output logic [31:0] instruction
);
```

### Implementation

```systemverilog
localparam int MEM_DEPTH = 2**ADDR_WIDTH;
logic [31:0] memory [0:MEM_DEPTH-1];

logic [ADDR_WIDTH-1:0] word_address = address[ADDR_WIDTH+1:2];

integer i;

initial begin
    for (i = 0; i < MEM_DEPTH; i = i + 1) begin
        memory[i] = 32'h00000000;
    end
    $readmemh(INIT_FILE, memory);
end

assign instruction = memory[word_address];
```

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ADDR_WIDTH` | 8 | Address bits for word addressing (256 words = 1KB) |
| `INIT_FILE` | "instruction_memory.hex" | Hex file for initialization |

### Address Mapping

- **Input**: 32-bit byte address
- **Word address**: `address[ADDR_WIDTH+1:2]` (divide by 4)
- **Depth**: 2^ADDR_WIDTH words
- **Total size**: 2^(ADDR_WIDTH+2) bytes

### Initialization Sequence

1. Zero-fill all memory locations
2. Load program from hex file via `$readmemh`

### Hex File Format

One 32-bit instruction per line (8 hex characters):
```
DEAD00B7
23408093
00102023
...
```

### Related Documents
- [Core Processor](../modules/core-processor.md)
- [Memory Architecture](../architecture/memory.md)