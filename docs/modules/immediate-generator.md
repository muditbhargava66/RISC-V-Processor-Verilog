# Immediate Generator Module Reference

## Module: `immediate_generator`

**File**: `src/immediate_generator.sv`  
**Lines**: ~50  
**Parameters**: `XLEN=32`

### Interface

```systemverilog
module immediate_generator #(
    parameter int XLEN = 32
)(
    input  logic [31:0] instruction,
    output logic [XLEN-1:0] immediate
);
```

### Implementation

```systemverilog
always_comb begin
    unique case (opcode)
        OPCODE_I_TYPE, OPCODE_LOAD, OPCODE_JALR: begin
            // I-type: imm[11:0] = instruction[31:20]
            immediate = {{(XLEN-12){instruction[31]}}, instruction[31:20]};
        end

        OPCODE_STORE: begin
            // S-type: imm[11:5] = instruction[31:25], imm[4:0] = instruction[11:7]
            immediate = {{(XLEN-12){instruction[31]}}, instruction[31:25], instruction[11:7]};
        end

        OPCODE_BRANCH: begin
            // B-type: imm[12|10:5|4:1|11] = instruction[31|30:25|11:8|7]
            immediate = {{(XLEN-13){instruction[31]}}, instruction[31], instruction[7],
                         instruction[30:25], instruction[11:8], 1'b0};
        end

        OPCODE_LUI, OPCODE_AUIPC: begin
            // U-type: imm[31:12] = instruction[31:12], imm[11:0] = 0
            immediate = {instruction[31:12], {(XLEN-32){1'b0}}, 12'b0};
        end

        OPCODE_JAL: begin
            // J-type: imm[20|10:1|11|19:12] = instruction[31|30:21|20|19:12]
            immediate = {{(XLEN-21){instruction[31]}}, instruction[31], instruction[19:12],
                         instruction[20], instruction[30:21], 1'b0};
        end

        default: begin
            immediate = '0;
        end
    endcase
end
```

### Immediate Formats

| Type | Instructions | Bits | Construction |
|------|--------------|------|--------------|
| I | ADDI, loads, JALR | 12 | `{{20{inst[31]}}, inst[31:20]}` |
| S | Stores | 12 | `{{20{inst[31]}}, inst[31:25], inst[11:7]}` |
| B | Branches | 13 | `{{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}` |
| U | LUI, AUIPC | 20 | `{inst[31:12], 12'b0}` |
| J | JAL | 21 | `{{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}` |

### Sign Extension

All immediates are sign-extended to XLEN bits:
- **I/S/B types**: MSB of immediate field replicated
- **U type**: Zero-extended (upper 20 bits from instruction, lower 12 zero)
- **J type**: Sign bit replicated for upper bits

### Related Documents
- [Core Processor](../modules/core-processor.md)
- [ISA Support](../architecture/isa-support.md)