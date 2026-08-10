# Signal Probing Guide

## Overview

This guide covers signal probing strategies for debugging the RISC-V processor using ILA/VIO.

## Signal Categories

### Control Signals
| Signal | Width | Module | Description |
|--------|-------|--------|-------------|
| reg_write | 1 | control_unit | Register write enable |
| mem_read | 1 | control_unit | Memory read enable |
| mem_write | 1 | control_unit | Memory write enable |
| branch | 1 | control_unit | Branch instruction |
| jump | 1 | control_unit | Jump instruction |
| alu_src1 | 1 | control_unit | ALU operand A select |
| alu_src | 2 | control_unit | ALU operand B select |
| alu_op | 4 | control_unit | ALU operation |
| reg_write_src | 2 | control_unit | Writeback source |

### Datapath Signals
| Signal | Width | Module | Description |
|--------|-------|--------|-------------|
| pc_current | 32 | program_counter | Current PC |
| pc_next | 32 | riscv_processor | Next PC |
| instruction | 32 | instruction_memory | Current instruction |
| immediate | 32 | immediate_generator | Sign-extended immediate |
| read_data1 | 32 | register_file | Register read port 1 |
| read_data2 | 32 | register_file | Register read port 2 |
| alu_operand1 | 32 | riscv_processor | ALU input A |
| alu_operand2 | 32 | riscv_processor | ALU input B |
| alu_result | 32 | alu | ALU result |
| alu_zero | 1 | alu | Zero flag |
| mem_read_data | 32 | data_memory | Memory read data |
| reg_write_data | 32 | riscv_processor | Writeback data |

### Branch/Jump Signals
| Signal | Width | Module | Description |
|--------|-------|--------|-------------|
| beq_cond | 1 | riscv_processor | BEQ condition |
| bne_cond | 1 | riscv_processor | BNE condition |
| blt_cond | 1 | riscv_processor | BLT condition |
| bge_cond | 1 | riscv_processor | BGE condition |
| bltu_cond | 1 | riscv_processor | BLTU condition |
| bgeu_cond | 1 | riscv_processor | BGEU condition |
| branch_taken | 1 | riscv_processor | Any branch taken |
| jump_target | 32 | riscv_processor | Jump target address |
| pc_plus_4 | 32 | riscv_processor | PC + 4 |

## Probing Strategies

### Strategy 1: Control Flow Debugging
**Probes**: pc_current, pc_next, branch_taken, jump, instruction
**Trigger**: branch_taken == 1 or jump == 1
**Analysis**: Verify PC sequence, branch targets, jump targets

### Strategy 2: ALU Operation Verification
**Probes**: alu_operand1, alu_operand2, alu_op, alu_result, alu_zero
**Trigger**: Specific alu_op value
**Analysis**: Verify ALU correctness for each operation

### Strategy 3: Register File Access
**Probes**: reg_write, write_reg, write_data, read_reg1, read_reg2, read_data1, read_data2
**Trigger**: reg_write == 1
**Analysis**: Verify register write data, read data correctness

### Strategy 4: Memory Access
**Probes**: mem_read, mem_write, address, write_data, funct3, mem_read_data
**Trigger**: mem_read == 1 or mem_write == 1
**Analysis**: Verify address calculation, data integrity, alignment

### Strategy 5: Instruction Decode Verification
**Probes**: instruction, opcode, funct3, funct7, immediate
**Trigger**: Specific opcode value
**Analysis**: Verify decode correctness, immediate generation

### Strategy 6: Pipeline Behavior
**Probes**: pc_current, instruction, branch_taken, jump
**Trigger**: Any PC change
**Analysis**: Verify IPC = 1.0, no bubbles, correct sequencing

## Probe Grouping

### Group 1: Core Pipeline
pc_current, pc_next, instruction, pc_plus_4, branch_taken, jump

### Group 2: Datapath
alu_operand1, alu_operand2, alu_op, alu_result, alu_zero, reg_write_data

### Group 3: Register File
reg_write, write_reg, write_data, read_reg1, read_reg2, read_data1, read_data2

### Group 4: Memory
mem_read, mem_write, address, write_data, funct3, mem_read_data

### Group 5: Control
reg_write, mem_read, mem_write, branch, jump, alu_src1, alu_src, alu_op, reg_write_src

### Group 6: Branch/Jump
beq_cond, bne_cond, blt_cond, bge_cond, bltu_cond, bgeu_cond, branch_taken, jump_target, pc_plus_4

## Mark Debug Usage

### Adding Mark Debug
```systemverilog
(* mark_debug = "true" *) logic [31:0] pc_current;
(* mark_debug = "true" *) logic [31:0] instruction;
```

### Removing for Production
```systemverilog
// Remove mark_debug or set to false for production builds
(* mark_debug = "false" *) logic [31:0] pc_current;
```

## Related Documents
- [ILA/VIO Integration](../debug/ila-vio.md)
- [Hardware Debug](hardware-debug.md)
- [Runtime Control](runtime-control.md)