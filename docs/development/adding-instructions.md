# Adding Instructions Guide

## Overview

This guide explains how to add new instructions to the RISC-V processor.

## Instruction Addition Process

### 1. Define Opcode and Encoding

Add to `src/riscv_pkg.sv`:

```systemverilog
// New opcode
localparam logic [6:0] OPCODE_NEW = 7'bxxxxxxx;

// Funct3 for new instruction type
localparam logic [2:0] FUNCT3_NEW = 3'bxxx;

// Funct7 if needed
localparam logic [6:0] FUNCT7_NEW = 7'bxxxxxxx;
```

### 2. Update Immediate Generator

In `src/immediate_generator.sv`:

```systemverilog
always_comb begin
    unique case (opcode)
        // ... existing cases
        OPCODE_NEW: begin
            // Define immediate format
            immediate = {{(XLEN-12){instruction[31]}}, instruction[31:20]}; // I-type example
        end
    endcase
end
```

### 3. Update Control Unit

In `src/control_unit.sv`:

```systemverilog
always_comb begin
    unique case (opcode)
        OPCODE_NEW: begin
            reg_write      = 1'b1;
            alu_src        = ALU_SRC_IMM;
            alu_op         = ALU_ADD;  // or new ALU op
            reg_write_src  = WRITE_SRC_ALU;
            // Set other control signals
        end
    endcase
end
```

### 4. Add ALU Operation (if needed)

In `src/alu.sv`:

```systemverilog
localparam logic [3:0] ALU_NEW_OP = 4'bxxxx;

always_comb begin
    unique case (alu_control)
        ALU_NEW_OP: begin
            result = custom_operation(operand_a, operand_b);
        end
    endcase
end
```

### 5. Update Core Processor

In `src/riscv_processor.sv`:

```systemverilog
// Add to opcode decode
localparam logic [6:0] OPCODE_NEW = 7'bxxxxxxx;

// Add to branch/jump logic if needed
// Add to PC next logic if control flow instruction

// Add to formal assertions
// synthesis translate_off
assert property (@(posedge clk) disable iff (reset)
    (opcode == OPCODE_NEW) |-> (alu_result == expected_result));
// synthesis translate_on

// Coverage
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_NEW);
```

### 5. Add Test Vectors

In `testbenches/control_unit_tb.sv`:
```systemverilog
test_instruction(OPCODE_NEW, FUNCT3_NEW, FUNCT7_NEW, 
                 1, 0, 0, 0, 0, 1'b0, ALU_SRC_IMM, ALU_NEW_OP, WRITE_SRC_ALU, "NEW_INST");
```

In `testbenches/alu_tb.sv`:
```systemverilog
test_alu_operation(ALU_NEW_OP, 32'h00000005, 32'h00000003, 32'h00000008, "NEW_OP");
```

### 6. Add to Test Program

Update `instruction_memory.hex` with new instruction encoding.

### 6. Run Tests

```bash
make test-control
make test-alu
make test-system
make lint
```

## Instruction Format Guidelines

### R-type (Register-Register)
```
31-25    24-20  19-15  14-12  11-7   6-0
funct7   rs2    rs1    funct3 rd     opcode
```
- Uses funct7 and funct3 for operation
- Two register sources, one destination

### I-type (Immediate)
```
31-20    19-15  14-12  11-7   6-0
imm[11:0] rs1    funct3 rd     opcode
```
- Single register source, immediate operand
- Used for ALU immediate, loads, JALR

### S-type (Store)
```
31-25   24-20  19-15  14-12  11-7   6-0
imm[11:5] rs2   rs1    funct3 imm[4:0] opcode
```
- Two register sources, no destination
- Immediate split across instruction

### B-type (Branch)
```
31    30-25  24-20  19-15  14-12  11-8   7    6-0
imm[12] imm[10:5] rs2  rs1    funct3  imm[4:1] imm[11] opcode
```
- Two register sources, PC-relative branch
- Immediate encoded in scattered bits

### U-type (Upper Immediate)
```
31-12   11-7   6-0
imm[31:12] rd    opcode
```
- Single destination register
- 20-bit immediate shifted left 12

### J-type (JAL)
```
31    30-21   20    19-12   11-7   6-0
imm[20] imm[10:1] imm[11] imm[19:12] rd   opcode
```
- Single destination register
- 20-bit immediate for PC-relative jump

## Checklist for New Instructions

- [ ] Opcode defined in `riscv_pkg.sv`
- [ ] Funct3/funct7 defined if needed
- [ ] Immediate generation in `immediate_generator.sv`
- [ ] Control signals in `control_unit.sv`
- [ ] ALU operation in `alu.sv` (if needed)
- [ ] PC logic in `riscv_processor.sv` (for control flow)
- [ ] Formal assertions in `riscv_processor.sv`
- [ ] Coverage points in `riscv_processor.sv`
- [ ] Test vector in `control_unit_tb.sv`
- [ ] ALU test in `alu_tb.sv` (if new ALU op)
- [ ] System test in `riscv_processor_tb.sv`
- [ ] Instruction added to `instruction_memory.hex`
- [ ] Documentation updated
- [ ] All tests pass: `make test-all`

## Example: Adding a New CSR Instruction

### 1. Define in Package
```systemverilog
localparam logic [6:0] OPCODE_CSR = 7'b1110011;
localparam logic [2:0] FUNCT3_CSRRW = 3'b001;
localparam logic [2:0] FUNCT3_CSRRS = 3'b010;
localparam logic [2:0] FUNCT3_CSRRC = 3'b011;
```

### 2. Immediate Generator
```systemverilog
OPCODE_CSR: begin
    immediate = {{20{instruction[31]}}, instruction[31:20]};  // CSR address
end
```

### 3. Control Unit
```systemverilog
OPCODE_CSR: begin
    reg_write = 1'b1;
    unique case (funct3)
        FUNCT3_CSRRW: alu_op = ALU_CSRRW;  // New ALU op
        FUNCT3_CSRRS: alu_op = ALU_CSRRS;
        FUNCT3_CSRRC: alu_op = ALU_CSRRC;
        default: alu_op = ALU_ADD;
    endcase
    reg_write_src = WRITE_SRC_CSR;  // New write source
end
```

### 4. ALU
```systemverilog
localparam logic [3:0] ALU_CSRRW = 4'b1100;
localparam logic [3:0] ALU_CSRRS = 4'b1101;
localparam logic [3:0] ALU_CSRRC = 4'b1110;

always_comb begin
    unique case (alu_control)
        ALU_CSRRW: result = csr_read_data;  // Write rs1, return old
        ALU_CSRRS: result = csr_read_data | operand_a;  // Set bits
        ALU_CSRRC: result = csr_read_data & ~operand_a; // Clear bits
    endcase
end
```

## Related Documents
- [Architecture Overview](../architecture/overview.md)
- [ISA Support](isa-support.md)
- [Control Unit](../modules/control-unit.md)
- [ALU](alu.md)