# SVA Properties Reference

## Overview

The RISC-V processor includes 15 SystemVerilog Assertions (SVA) and 12 cover properties embedded directly in `riscv_processor.sv`.

## Assertion Reference

### 1. PC Word Alignment
```systemverilog
property pc_word_aligned;
    @(posedge clk) disable iff (reset)
    (pc_current[1:0] == 2'b00);
endproperty

assert property (pc_word_aligned)
    else $error("PC not word-aligned: PC = %08h", pc_current);
```
**Description**: PC must always be 4-byte aligned
**Severity**: Error

### 2. PC Sequential Advancement
```systemverilog
property pc_sequential_advance;
    @(posedge clk) disable iff (reset)
    (!branch_taken_debug && opcode != OPCODE_JAL && opcode != OPCODE_JALR) |=>
    (pc_debug == $past(pc_debug, 1, 1'b1, @(posedge clk)) + 4);
endproperty

assert property (pc_sequential_advance)
    else $error("PC did not advance sequentially");
```
**Description**: PC increments by 4 for non-branch/jump instructions
**Severity**: Error

### 3. x0 Hardwired Zero (Port 1)
```systemverilog
property reg_x0_always_zero;
    @(posedge clk) disable iff (reset)
    (reg_debug_addr1 == 5'b00000) |-> (reg_debug_data1 == 32'h00000000);
endproperty

assert property (reg_x0_always_zero)
    else $error("Register x0 not zero: x0 = %08h", reg_debug_data1);
```
**Description**: Register x0 always reads zero on port 1
**Severity**: Error

### 4. x0 Hardwired Zero (Port 2)
```systemverilog
property reg_x0_always_zero_2;
    @(posedge clk) disable iff (reset)
    (reg_debug_addr2 == 5'b00000) |-> (reg_debug_data2 == 32'h00000000);
endproperty

assert property (reg_x0_always_zero_2)
    else $error("Register x0 not zero: x0 = %08h", reg_debug_data2);
```
**Description**: Register x0 always reads zero on port 2
**Severity**: Error

### 5. Valid Register Write
```systemverilog
property reg_write_valid_instructions;
    @(posedge clk) disable iff (reset)
    reg_write_debug |-> writes_register(opcode);
endproperty

assert property (reg_write_valid_instructions)
    else $error("Invalid register write for opcode %07b", opcode);
```
**Description**: Register write only for valid write instructions
**Severity**: Error

### 6. Valid Memory Read
```systemverilog
property mem_read_valid_instructions;
    @(posedge clk) disable iff (reset)
    mem_read_debug |-> (opcode == OPCODE_LOAD);
endproperty

assert property (mem_read_valid_instructions)
    else $error("Invalid memory read for opcode %07b", opcode);
```
**Description**: Memory read only for load instructions
**Severity**: Error

### 7. Valid Memory Write
```systemverilog
property mem_write_valid_instructions;
    @(posedge clk) disable iff (reset)
    mem_write_debug |-> (opcode == OPCODE_STORE);
endproperty

assert property (mem_write_valid_instructions)
    else $error("Invalid memory write for opcode %07b", opcode);
```
**Description**: Memory write only for store instructions
**Severity**: Error

### 8. Valid Branch Taken
```systemverilog
property branch_taken_valid_instructions;
    @(posedge clk) disable iff (reset)
    branch_taken_debug |-> is_control_flow(opcode);
endproperty

assert property (branch_taken_valid_instructions)
    else $error("Invalid branch taken for opcode %07b", opcode);
```
**Description**: Branch taken only for branch/jump instructions
**Severity**: Error

### 9. Valid Opcode
```systemverilog
property valid_opcode;
    @(posedge clk) disable iff (reset)
    is_valid_base_opcode(opcode) || (instruction_debug == 32'h00000000);
endproperty

assert property (valid_opcode)
    else $error("Invalid opcode: %07b", opcode);
```
**Description**: All executed instructions have valid opcodes
**Severity**: Error

### 10. R-type Format Validation
```systemverilog
property r_type_format_valid;
    @(posedge clk) disable iff (reset)
    (opcode == OPCODE_R_TYPE) |-> 
    ((funct7 == FUNCT7_BASE || funct7 == FUNCT7_SUB_SRA) &&
     (funct3 >= 3'b000 && funct3 <= 3'b111));
endproperty

assert property (r_type_format_valid)
    else $error("Invalid R-type format: funct7=%07b, funct3=%03b", funct7, funct3);
```
**Description**: R-type instructions have valid funct3/funct7 combinations
**Severity**: Error

### 11. I-type Immediate Generation
```systemverilog
property i_type_immediate_valid;
    @(posedge clk) disable iff (reset)
    (opcode == OPCODE_I_TYPE || opcode == OPCODE_LOAD || opcode == OPCODE_JALR) |->
    (immediate_debug == {{20{instruction_debug[31]}}, instruction_debug[31:20]});
endproperty

assert property (i_type_immediate_valid)
    else $error("Invalid I-type immediate: expected=%08h, actual=%08h",
                {{20{instruction_debug[31]}}, instruction_debug[31:20]}, immediate_debug);
```
**Description**: I-type immediates correctly sign-extended
**Severity**: Error

### 12. ADD Instruction ALU Correctness
```systemverilog
property add_instruction_alu_result;
    @(posedge clk) disable iff (reset)
    (opcode == OPCODE_R_TYPE && funct3 == FUNCT3_ADD_SUB && funct7 == FUNCT7_BASE) |->
    (alu_result_debug == (reg_debug_data1 + reg_debug_data2));
endproperty

assert property (add_instruction_alu_result)
    else $error("ADD instruction ALU mismatch: %08h + %08h != %08h",
                reg_debug_data1, reg_debug_data2, alu_result_debug);
```
**Description**: ADD instruction produces correct ALU result
**Severity**: Error

### 13. SUB Instruction ALU Correctness
```systemverilog
property sub_instruction_alu_result;
    @(posedge clk) disable iff (reset)
    (opcode == OPCODE_R_TYPE && funct3 == FUNCT3_ADD_SUB && funct7 == FUNCT7_SUB_SRA) |->
    (alu_result_debug == (reg_debug_data1 - reg_debug_data2));
endproperty

assert property (sub_instruction_alu_result)
    else $error("SUB instruction ALU mismatch: %08h - %08h != %08h",
                reg_debug_data1, reg_debug_data2, alu_result_debug);
```
**Description**: SUB instruction produces correct ALU result
**Severity**: Error

### 14. ADDI Instruction ALU Correctness
```systemverilog
property addi_instruction_alu_result;
    @(posedge clk) disable iff (reset)
    (opcode == OPCODE_I_TYPE && funct3 == FUNCT3_ADD_SUB) |->
    (alu_result_debug == (reg_debug_data1 + immediate_debug));
endproperty

assert property (addi_instruction_alu_result)
    else $error("ADDI instruction ALU mismatch: %08h + %08h != %08h",
                reg_debug_data1, immediate_debug, alu_result_debug);
```
**Description**: ADDI instruction produces correct ALU result
**Severity**: Error

### 15. No Unknown Values in PC
```systemverilog
property no_unknown_pc;
    @(posedge clk) disable iff (reset)
    !$isunknown(pc_debug);
endproperty

assert property (no_unknown_pc)
    else $error("PC contains unknown values: %08h", pc_debug);
```
**Description**: PC never contains X or Z values
**Severity**: Error

### 16. No Unknown Values in Instruction
```systemverilog
property no_unknown_instruction;
    @(posedge clk) disable iff (reset)
    !$isunknown(instruction_debug);
endproperty

assert property (no_unknown_instruction)
    else $error("Instruction contains unknown values: %08h", instruction_debug);
```
**Description**: Instruction register never contains X/Z
**Severity**: Error

### 17. Reset Behavior
```systemverilog
property reset_behavior;
    @(posedge clk)
    reset |=> (pc_debug == 32'h00000000);
endproperty

assert property (reset_behavior)
    else $error("PC not reset to zero: PC = %08h", pc_debug);
```
**Description**: PC resets to zero on reset
**Severity**: Error

## Cover Properties

### Opcode Coverage
```systemverilog
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_R_TYPE);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_I_TYPE);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_LOAD);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_STORE);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_BRANCH);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_JAL);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_JALR);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_LUI);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_AUIPC);
```

### Branch Coverage
```systemverilog
cover property (@(posedge clk) disable iff (reset) branch_taken_debug);
cover property (@(posedge clk) disable iff (reset) !branch_taken_debug && opcode == OPCODE_BRANCH);
```

### Register Write Coverage
```systemverilog
cover property (@(posedge clk) disable iff (reset) reg_write_debug && rd != 5'b00000);
cover property (@(posedge clk) disable iff (reset) reg_write_debug && rd == 5'b11111);
```

### Memory Operation Coverage
```systemverilog
cover property (@(posedge clk) disable iff (reset) mem_read_debug);
cover property (@(posedge clk) disable iff (reset) mem_write_debug);
```

## Using Properties in Formal Verification

### Enable All Assertions
```bash
sby -f formal.sby
```

### Check Specific Property
```bash
# In formal.sby, add to [script]:
# assert -all
```

### Generate Coverage Report
```bash
sby -f formal_cover.sby
```

## Property Writing Guidelines

### 1. Use `disable iff (reset)` for Reset
```systemverilog
property my_property;
    @(posedge clk) disable iff (reset)
    condition |-> consequence;
endproperty
```

### 2. Use Implication (`|->`) for Implications
```systemverilog
property implication_example;
    @(posedge clk) disable iff (reset)
    antecedent |-> consequent;
endproperty
```

### 3. Use Sequence (`##`) for Temporal
```systemverilog
property temporal_example;
    @(posedge clk) disable iff (reset)
    signal_a |=> signal_b;  // Next cycle
endproperty
```

### 4. Use `$past` for History
```systemverilog
property history_example;
    @(posedge clk) disable iff (reset)
    condition |-> (signal == $past(signal) + 4);
endproperty
```

### 5. Use Package Functions
```systemverilog
property package_example;
    @(posedge clk) disable iff (reset)
    reg_write |-> writes_register(opcode);
endproperty
```

## Related Documents
- [SymbiYosys Setup](symbiyosys.md)
- [Proof Strategies](proof-strategies.md)
- [Coverage Collection](coverage.md)
- [Verification Guide](../verification/verification-guide.md)