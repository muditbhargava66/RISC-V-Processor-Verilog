# Coding Standards

## Language
- **SystemVerilog** (IEEE 1800-2017)
- Target: Xilinx Vivado 2023.2 synthesis

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Modules | `snake_case` | `riscv_processor` |
| Instances | `snake_case` | `alu_inst` |
| Signals | `snake_case` | `pc_current` |
| Parameters | `UPPER_SNAKE` | `XLEN` |
| Localparams | `UPPER_SNAKE` | `ALU_ADD` |
| Functions/Tasks | `snake_case` | `sign_extend` |
| Types/Enums | `snake_case` with `_e` | `opcode_e` |
| Packages | `_pkg` suffix | `riscv_pkg` |
| Testbenches | `_tb` suffix | `alu_tb` |

## Coding Style

### Indentation
- **2 spaces** per level
- **No tabs**
- Opening brace on same line

```systemverilog
always_ff @(posedge clk) begin
  if (reset) begin
    pc_current <= '0;
  end else begin
    pc_current <= pc_next;
  end
end
```

### Signal Declarations
```systemverilog
// Preferred: explicit width
logic [31:0] pc_current;
logic        branch_taken;

// Avoid: implicit width
logic pc_current;        // Bad
logic [31:0] pc_current; // Good
```

### Always Blocks

#### Combinational (`always_comb`)
```systemverilog
always_comb begin
  // Default assignments
  result = '0;
  
  unique case (sel)
    2'b00: result = a + b;
    2'b01: result = a - b;
    default: result = '0;
  endcase
end
```

#### Sequential (`always_ff`)
```systemverilog
always_ff @(posedge clk) begin
  if (reset) begin
    reg_q <= '0;
  end else if (enable) begin
    reg_q <= reg_d;
  end
end
```

#### Latch Prevention
```systemverilog
// Always assign in all branches
always_comb begin
  result = '0;  // Default
  unique case (sel)
    2'b00: result = a;
    2'b01: result = b;
    default: result = '0;  // Explicit default
  endcase
end
```

### Case Statements
```systemverilog
// Use unique_case for parallel case synthesis
unique case (opcode)
  OPCODE_ADD: result = a + b;
  OPCODE_SUB: result = a - b;
  default: result = '0;
endcase

// For priority encoding, use case (not unique_case)
casez (priority_req)
  4'b1???: grant = 4'b0001;
  4'b01??: grant = 4'b0010;
  default: grant = 4'b0000;
endcase
```

### Parameter Usage
```systemverilog
module module_name #(
    parameter int WIDTH = 32,
    parameter bit FEATURE_ENABLE = 1'b1
)(...);

// Usage in submodule
submodule #(
    .WIDTH (WIDTH),
    .FEATURE_ENABLE (FEATURE_ENABLE)
) inst (...);
```

## Module Structure

```systemverilog
module module_name #(
    parameter int PARAM = 32
)(
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] input_signal,
    output logic [31:0] output_signal
);

    // Local parameters
    localparam int LOCAL_PARAM = 16;

    // Internal signals
    logic [31:0] internal_reg;

    // Submodule instances
    submodule sub_inst (
        .clk    (clk),
        .reset  (reset),
        .in     (input_signal),
        .out    (internal_reg)
    );

    // Combinational logic
    always_comb begin
        // Logic here
    end

    // Sequential logic
    always_ff @(posedge clk) begin
        // Sequential logic here
    end

    // Assertions (synthesis translate_off)
    // synthesis translate_off
    assert property (@(posedge clk) disable iff (reset) ...);
    // synthesis translate_on

    // Output assignments
    assign output_signal = internal_reg;

endmodule
```

## Reset Strategy

### Synchronous Reset (Preferred for FPGA)
```systemverilog
always_ff @(posedge clk) begin
  if (reset) begin
    reg_q <= '0;
  end else begin
    reg_q <= reg_d;
  end
end
```

### Asynchronous Reset (When Required)
```systemverilog
always_ff @(posedge clk or posedge reset) begin
  if (reset) begin
    reg_q <= '0;
  end else begin
    reg_q <= reg_d;
  end
end
```

## Assertions

### Inline Assertions
```systemverilog
// synthesis translate_off
assert property (@(posedge clk) disable iff (reset)
    condition |-> consequence);
// synthesis translate_on

// Coverage
cover property (@(posedge clk) disable iff (reset) condition);
```

### Immediate Assertions (Simulation Only)
```systemverilog
// synthesis translate_off
always_comb begin
  if (condition) begin
    assert (check) else $error("Check failed: %s", condition);
  end
end
// synthesis translate_on
```

## File Organization

### File Header
```systemverilog
// Module Name
// Description
// Author
// Date
// License

module module_name (...);
```

### Single Module per File
- File name matches module name
- One top-level module per file

## Comments

### Block Comments
```systemverilog
/*
 * Multi-line comment
 * Explains complex logic
 */
```

### Inline Comments
```systemverilog
logic signal;  // Brief description
```

### No Trailing Whitespace
- No trailing spaces
- No trailing tabs

## Verilog Compatibility

### SystemVerilog Features Used
- `logic` type
- `always_comb` / `always_ff`
- `unique_case` / `unique casez`
- `packed` arrays
- `enum` types
- `package` / `import`
- `$clog2` function
- `assert` / `cover` properties

### Avoided Features (for compatibility)
- Interfaces
- Classes
- Randomization
- Dynamic arrays
- Mailboxes
- Semaphores

## Lint Checks

### Run Lint
```bash
make lint
```

### Common Lint Issues
| Issue | Fix |
|-------|-----|
| Unconnected ports | Connect or explicitly tie off |
| Latch inferred | Complete all case branches |
| Width mismatch | Match signal widths |
| Unused signals | Remove or use `_unused` suffix |
| Reset not synchronized | Use synchronous reset |

## Related Documents
- [Architecture Overview](../architecture/overview.md)
- [Module Reference](../modules/core-processor.md)
- [Build System](build-system.md)