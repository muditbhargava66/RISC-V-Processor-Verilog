# Program Counter Module Reference

## Module: `program_counter`

**File**: `src/program_counter.sv`  
**Lines**: ~25  
**Parameters**: `XLEN=32`

### Interface

```systemverilog
module program_counter #(
    parameter int XLEN = 32
)(
    input  logic        clk,
    input  logic        reset,
    input  logic [XLEN-1:0] pc_next,
    output logic [XLEN-1:0] pc_current
);
```

### Implementation

```systemverilog
always_ff @(posedge clk) begin
    if (reset)
        pc_current <= '0;
    else
        pc_current <= pc_next;
end
```

### Behavior

- **Reset**: PC initializes to 0x00000000
- **Update**: PC updates to `pc_next` on each clock cycle
- **No enable signal**: PC updates every cycle (single-cycle architecture)

### PC Next Calculation (in core processor)

```systemverilog
pc_plus_4 = pc_current + 32'd4;

branch_taken = branch & (beq_cond | bne_cond | blt_cond | bge_cond | bltu_cond | bgeu_cond);

jump_target = (opcode == JAL) ? (pc_current + immediate) :
              {alu_result[XLEN-1:1], 1'b0};  // JALR clears LSB

pc_next = jump ? jump_target :
          branch_taken ? (pc_current + immediate) :
                         pc_plus_4;
```

### Related Documents
- [Core Processor](../modules/core-processor.md)
- [Architecture Overview](../architecture/overview.md)