# Register File Module Reference

## Module: `register_file`

**File**: `src/register_file.sv`  
**Lines**: ~45  
**Parameters**: `XLEN=32`, `REG_ADDR_WIDTH=5`, `NUM_REGS=32`

### Interface

```systemverilog
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
```

### Implementation

```systemverilog
logic [XLEN-1:0] registers [1:NUM_REGS-1];  // x0 not stored

integer i;

always_ff @(posedge clk) begin
    if (reset) begin
        for (i = 1; i < NUM_REGS; i = i + 1) begin
            registers[i] <= '0;
        end
    end else if (reg_write && write_reg != '0) begin
        registers[write_reg] <= write_data;
    end
end

assign read_data1 = (read_reg1 == '0) ? '0 : registers[read_reg1];
assign read_data2 = (read_reg2 == '0) ? '0 : registers[read_reg2];
```

### Key Features

1. **x0 Hardwired to Zero**
   - Register x0 (address 0) is not physically stored
   - Reads return 0
   - Writes are ignored

2. **Synchronous Write**
   - Write occurs on positive clock edge
   - Write enable (`reg_write`) and address (`write_reg`) sampled at clock edge
   - Data (`write_data`) captured at clock edge

3. **Asynchronous Read**
   - Read data available combinationally
   - No clock delay for read operations

4. **Synchronous Reset**
   - All registers cleared on reset assertion
   - Reset held for 2 cycles recommended for full propagation

### Register Map

| Register | ABI Name | Description |
|----------|----------|-------------|
| x0 | zero | Hardwired zero |
| x1 | ra | Return address |
| x2 | sp | Stack pointer |
| x3 | gp | Global pointer |
| x4 | tp | Thread pointer |
| x5-7 | t0-t2 | Temporaries |
| x8 | s0/fp | Saved register / frame pointer |
| x9 | s1 | Saved register |
| x10-11 | a0-a1 | Function arguments / return values |
| x12-17 | a2-a7 | Function arguments |
| x18-27 | s2-s11 | Saved registers |
| x28-31 | t3-t6 | Temporaries |

### Timing

| Operation | Latency |
|-----------|---------|
| Read | 0 cycles (combinational) |
| Write | 1 cycle (registered) |
| Reset | 1 cycle (per register) |

### Test Coverage

| Test | Description | Status |
|------|-------------|--------|
| x0 hardwired | Write to x0 ignored, reads return 0 | PASS |
| Write/read x1 | Basic write/read | PASS |
| Write/read x2 | Multiple registers | PASS |
| Overwrite | Modify existing register | PASS |
| All registers | Write/read all 31 registers | PASS |
| Reset | Synchronous reset clears all | PASS |

### Related Documents
- [Core Processor](../modules/core-processor.md)
- [Architecture Overview](../architecture/overview.md)