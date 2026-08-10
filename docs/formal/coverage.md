# Coverage Collection Guide

## Overview

Coverage collection measures how thoroughly the verification exercises the design functionality.

## Coverage Types

### 1. Code Coverage
- **Line coverage**: Each line executed
- **Branch coverage**: Each if/else taken both ways
- **Toggle coverage**: Each signal toggles 0→1 and 1→0
- **FSM coverage**: All states and transitions visited

### 2. Functional Coverage
- **Opcode coverage**: All instructions executed
- **Register coverage**: All registers written
- **Memory coverage**: All addresses accessed
- **Corner cases**: Overflow, underflow, alignment

## Collection Methods

### SymbiYosys Coverage Mode
```bash
sby -f formal_cover.sby
```

### Simulation Coverage (Vivado)
```tcl
# Enable coverage
set_property COVERAGE 1 [current_project]
launch_simulation
run all
report_coverage -ofile coverage_report.rpt
```

## SymbiYosys Coverage Configuration

### formal_cover.sby
```ini
[options]
mode cover
depth 30

[engines]
smtbmc

[script]
read_verilog -I ../src ../src/riscv_pkg.sv
read_verilog -I ../src ../src/alu.sv
read_verilog -I ../src ../src/immediate_generator.sv
read_verilog -I ../src ../src/program_counter.sv
read_verilog -I ../src ../src/register_file.sv
read_verilog -I ../src ../src/instruction_memory.sv
read_verilog -I ../src ../src/data_memory.sv
read_verilog -I ../src ../src/control_unit.sv
read_verilog -I ../src ../src/riscv_processor.sv
read_verilog -I ../verification ../verification/riscv_processor_sva.sv

prep -top riscv_processor_sva

[files]
../src/riscv_pkg.sv
../src/alu.sv
../src/immediate_generator.sv
../src/program_counter.sv
../src/register_file.sv
../src/instruction_memory.sv
../src/data_memory.sv
../src/control_unit.sv
../src/riscv_processor.sv
../verification/riscv_processor_sva.sv
```

## Coverage Points

### Defined in SVA (riscv_processor.sv)

#### Opcode Coverage (9 points)
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

#### Branch Coverage (2 points)
```systemverilog
cover property (@(posedge clk) disable iff (reset) branch_taken_debug);
cover property (@(posedge clk) disable iff (reset) !branch_taken_debug && opcode == OPCODE_BRANCH);
```

#### Register Write Coverage (2 points)
```systemverilog
cover property (@(posedge clk) disable iff (reset) reg_write_debug && rd != 5'b00000);
cover property (@(posedge clk) disable iff (reset) reg_write_debug && rd == 5'b11111);
```

#### Memory Operation Coverage (2 points)
```systemverilog
cover property (@(posedge clk) disable iff (reset) mem_read_debug);
cover property (@(posedge clk) disable iff (reset) mem_write_debug);
```

### Additional Coverage (Recommended)

```systemverilog
// ALU operation coverage
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_ADD);
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_SUB);
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_SLT);
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_SLTU);
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_AND);
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_OR);
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_XOR);
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_SLL);
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_SRL);
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_SRA);

// Branch type coverage
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_BRANCH && funct3 == FUNCT3_BEQ);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_BRANCH && funct3 == FUNCT3_BNE);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_BRANCH && funct3 == FUNCT3_BLT);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_BRANCH && funct3 == FUNCT3_BGE);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_BRANCH && funct3 == FUNCT3_BLTU);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_BRANCH && funct3 == FUNCT3_BGEU);

// Load/store size coverage
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_LOAD && funct3 == FUNCT3_LB);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_LOAD && funct3 == FUNCT3_LH);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_LOAD && funct3 == FUNCT3_LW);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_LOAD && funct3 == FUNCT3_LBU);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_LOAD && funct3 == FUNCT3_LHU);

cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_STORE && funct3 == FUNCT3_SB);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_STORE && funct3 == FUNCT3_SH);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_STORE && funct3 == FUNCT3_SW);

// Immediate type coverage
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_I_TYPE && funct3 == FUNCT3_ADD_SUB);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_I_TYPE && funct3 == FUNCT3_SLT);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_I_TYPE && funct3 == FUNCT3_SLTU);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_I_TYPE && funct3 == FUNCT3_XOR);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_I_TYPE && funct3 == FUNCT3_OR);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_I_TYPE && funct3 == FUNCT3_AND);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_I_TYPE && funct3 == FUNCT3_SLL);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_I_TYPE && funct3 == FUNCT3_SRL_SRA && funct7[5] == 1'b0);
cover property (@(posedge clk) disable iff (reset) opcode == OPCODE_I_TYPE && funct3 == FUNCT3_SRL_SRA && funct7[5] == 1'b1);

// Shift amount coverage
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_SLL && operand_b[4:0] == 5'd0);
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_SLL && operand_b[4:0] == 5'd31);
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_SRL && operand_b[4:0] == 5'd0);
cover property (@(posedge clk) disable iff (reset) alu_op == ALU_SRL && operand_b[4:0] == 5'd31);

// ALU result coverage
cover property (@(posedge clk) disable iff (reset) alu_result == 32'h00000000);
cover property (@(posedge clk) disable iff (reset) alu_result == 32'hFFFFFFFF);
cover property (@(posedge clk) disable iff (reset) alu_zero);
cover property (@(posedge clk) disable iff (reset) !alu_zero);
```

## Running Coverage Collection

### SymbiYosys
```bash
cd verification
sby -f formal_cover.sby
```

### Vivado Simulation
```bash
# Enable coverage in project
set_property COVERAGE 1 [current_project]

# Run simulation
launch_simulation -mode behavioral
run all

# Generate report
report_coverage -ofile coverage_report.rpt
```

## Analyzing Coverage Results

### SymbiYosys Output
```
SBY 12:34:56 [formal_cover] engine_0: ##   0:00:15  Coverage: 87.5%
SBY 12:34:56 [formal_cover] engine_0: ##   0:00:15  Cover points: 28/32 hit
SBY 12:34:56 [formal_cover] engine_0: ##   0:00:15  Unhit: 4
```

### Identifying Unhit Cover Points
```bash
# Check SymbiYosys output for unhit cover points
# Or generate detailed report
sby -f formal_cover.sby --vcd
gtkwave engine_0/cover.vcd
```

### Typical Unhit Points
| Cover Point | Reason | Action |
|-------------|--------|--------|
| MULH/MULHSU | M-extension not exercised | Add M-extension test program |
| DIV/REM | Division not in test program | Add division test |
| C-extension | C-extension not implemented | N/A |
| Shift by 31 | Edge case not in test | Add shift test |

## Coverage Goals

### Minimum Targets
| Coverage Type | Target |
|---------------|--------|
| Opcode coverage | 100% (9/9 base opcodes) |
| ALU operation | 100% (10/10 base ops) |
| Branch types | 100% (6/6 branch types) |
| Load/store sizes | 100% (5 loads, 3 stores) |
| Shift amounts | 100% (0 and 31) |
| ALU results | Zero and non-zero |

### Aspirational Targets
| Coverage Type | Target |
|---------------|--------|
| M-extension ops | 100% (8/8 ops) |
| Shift amounts | 0, 1, 16, 31 |
| ALU edge cases | Overflow, underflow |
| Memory alignment | All alignments |

## Coverage-Driven Development

### Workflow
1. Run coverage collection
2. Identify unhit cover points
3. Add test cases to hit missing points
4. Re-run coverage
5. Repeat until targets met

### Test Program Enhancement
```bash
# Add to instruction_memory.hex for missing coverage
# MUL: 0000001 00000 00001 000 00000 0110011 (MUL x0, x1, x1)
# DIV: 0000001 00000 00010 100 00000 0110011 (DIV x0, x1, x2)
# Shift by 31: 0000001 00000 00001 101 00000 0010011 (SRLI x0, x1, 31)
```

## CI Integration

```yaml
# .github/workflows/coverage.yml
name: Coverage Collection
on: [push, pull_request]
jobs:
  coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install tools
        run: |
          pip install symbiyosys
          sudo apt-get install -y yosys yices2 z3
      - name: Run coverage
        run: |
          cd verification
          sby -f formal_cover.sby
      - name: Upload coverage report
        uses: actions/upload-artifact@v3
        with:
          name: coverage-report
          path: verification/formal_cover/
```

## Related Documents
- [SymbiYosys Setup](symbiyosys.md)
- [SVA Properties](sva-properties.md)
- [Proof Strategies](proof-strategies.md)
- [Verification Guide](../verification/verification-guide.md)