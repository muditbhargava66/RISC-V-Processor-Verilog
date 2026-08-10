# Verification Guide

## Overview

This guide describes the verification infrastructure for the RISC-V processor. The verification suite includes unit tests, system integration tests, compliance smoke tests, formal verification, and performance benchmarking.

## Test Suite Summary

| Test Target | Testbench | Scope | Pass Criterion |
|-------------|-----------|-------|----------------|
| `lint` | Core RTL | Vivado compile/elaboration | No compile/elaboration errors |
| `test-alu` | `alu_tb.sv` | ALU operation vectors | All 24 vectors pass |
| `test-control` | `control_unit_tb.sv` | Decoder outputs | All 37 decode vectors match |
| `test-regfile` | `register_file_tb.sv` | Register writes/reads, x0 | All 37 checks pass |
| `test-memory` | `memory_tb.sv` | I-MEM/D-MEM byte/half/word | All 18 checks pass |
| `test-system` | `riscv_processor_tb.sv` | Demo program execution | 6 register checks pass |
| `test-compliance` | `compliance_tests.sv` | ISA smoke checks | 5/5 pass (3 skipped) |
| `test-benchmark` | `performance_benchmark.sv` | IPC measurement | 10 instr in 10 cycles |
| `test-formal` | `formal_verification_tb.sv` | SVA simulation | No assertion failures |

## Running Tests

### Using Make (Recommended)

```bash
# Run all deterministic tests
make test-all

# Run individual tests
make lint
make test-system
make test-alu
make test-control
make test-memory
make test-regfile
make test-compliance
make test-benchmark
make test-formal
```

### Using Vivado Directly

```bash
# System test
vivado -mode batch -source scripts/run_simulation.tcl -tclargs system

# ALU test
vivado -mode batch -source scripts/run_simulation.tcl -tclargs alu

# Other tests: alu, control, memory, regfile, compliance, formal, benchmark
```

## Test Details

### System Test (`test-system`)

**Testbench**: `testbenches/riscv_processor_tb.sv`

**Program** (`instruction_memory.hex`):
```
DEAD00B7  # LUI x1, 0xDEAD0
23408093  # ADDI x1, x1, 0x234
00102023  # SW x1, 0(x2)
00002103  # LW x2, 0(x0)
FFF00193  # ADDI x3, x0, -16
00100213  # ADDI x4, x0, 1
0041C263  # BLT x3, x1, target
000002B3  # ADD x5, x0, x0
004202B3  # ADD x5, x4, x0
0041D263  # BGE x3, x1, target
00420333  # ADD x6, x4, x0
00000013  # NOP
```

**Verification**:
- x1 = 0xDEAD0234 (LUI + ADDI)
- x2 = 0xDEAD0234 (SW + LW round-trip)
- x3 = 0xFFFFFFFF (ADDI negative)
- x4 = 0x00000001 (ADDI positive)
- x5 = 0x00000002 (BLT taken)
- x6 = 0x00000002 (BGE not taken)

### ALU Test (`test-alu`)

**Testbench**: `testbenches/alu_tb.sv`

**Coverage**: 24 test vectors covering all 10 base operations plus edge cases.

### Control Unit Test (`test-control`)

**Testbench**: `testbenches/control_unit_tb.sv`

**Coverage**: 37 decode vectors covering all RV32I opcodes and funct3/funct7 combinations.

### Memory Test (`test-memory`)

**Testbench**: `testbenches/memory_tb.sv`

**Coverage**: 
- Instruction memory: 11 address checks
- Data memory: Word, halfword, byte access with sign/zero extension

### Register File Test (`test-regfile`)

**Testbench**: `testbenches/register_file_tb.sv`

**Coverage**:
- x0 hardwired to zero
- Write/read all 31 registers
- Overwrite behavior
- Synchronous reset

### Compliance Test (`test-compliance`)

**Testbench**: `verification/compliance_tests.sv`

**Coverage**: Directed smoke checks on:
- Instruction format recognition
- Register x0 behavior
- ALU operation correctness (ADD, ADDI)
- Memory alignment
- Control flow (PC increment, branch behavior)

**Note**: This is a smoke test, not full RV32I compliance. Skips checks when expected opcodes not observed in demo program.

### Performance Benchmark (`test-benchmark`)

**Testbench**: `benchmarks/performance_benchmark.sv`

**Methodology**:
- Runs processor for 500 cycles (5μs at 100MHz)
- Counts instructions via PC changes
- Detects program end via NOP streak (3 consecutive NOPs)
- Reports IPC over active execution window

**Results**:
- Active program: 10 instructions in 10 cycles (IPC = 1.0)
- Full simulation: 500 cycles (IPC = 0.020 including NOP padding)
- Instruction mix: 70% ALU, 10% Load, 10% Store, 20% Branch

### Formal Verification (`test-formal`)

**Testbench**: `verification/formal_verification_tb.sv` + `verification/riscv_processor_sva.sv`

**SVA Properties**: 15 assertions + 12 cover properties

**Key Properties**:
- PC word alignment
- PC sequential advancement
- x0 hardwired to zero
- Valid register/memory/write operations
- Branch/jump validity
- ALU correctness (ADD, SUB, ADDI)
- No X/Z in critical signals
- Reset behavior

## Formal Verification with SymbiYosys

### Configurations

```bash
# Full proof (BMC + PDR + ABC)
sby -f verification/formal.sby

# Bounded model checking only
sby -f verification/formal_bmc.sby

# Coverage collection
sby -f verification/formal_cover.sby

# Core-only prove
sby -f verification/formal_core.sby
```

### Config Files

| File | Mode | Depth | Engines |
|------|------|-------|---------|
| `formal.sby` | prove | 50 | smtbmc, abc pdr, aigbmc |
| `formal_bmc.sby` | bmc | 30 | smtbmc |
| `formal_cover.sby` | cover | 30 | smtbmc |
| `formal_core.sby` | prove | 50 | smtbmc, abc pdr, aigbmc |

### SVA Properties (in `riscv_processor.sv`)

**Assertions** (15):
1. PC word-aligned
2. PC sequential advancement
3. x0 = 0 on read port 1
4. x0 = 0 on read port 2
5. Register write only for valid opcodes
6. Memory read only for loads
7. Memory write only for stores
8. Branch taken only for control flow
9. Valid opcode check
10. R-type format validation
11. I-type immediate generation
12. ADD ALU correctness
13. SUB ALU correctness
14. ADDI ALU correctness
15. No X/Z in PC/instruction

**Cover Properties** (12):
- All 9 opcode types
- Branch taken/not taken
- Register writes to x1-x31
- Memory read/write

## Running Individual Tests Without Make

```bash
# Using the unified simulation script
vivado -mode batch -source scripts/run_simulation.tcl -tclargs <test_name>

# Valid test names:
# system, alu, control, memory, regfile, compliance, formal, benchmark
```

## Test Output Interpretation

### Passing Test
```
========================================
Test Name Test
========================================
PASS: Test Description
...
ALL TESTS PASSED!
========================================
```

### Failing Test
```
========================================
Test Name Test
========================================
PASS: Some Test
FAIL: Failed Test
      Expected: 0xDEADBEEF
      Actual:   0x00000000
...
1 TESTS FAILED!
========================================
```

## Continuous Integration

```yaml
# Example GitHub Actions workflow
- name: Run Tests
  run: |
    make lint
    make test-all
    sby -f verification/formal.sby
```

## Troubleshooting

| Symptom | Cause | Action |
|---------|-------|--------|
| `$readmemh` fails | Image not in run directory | Use unified flow, check `instruction_memory.hex` exists |
| System test reads X | Image mismatch | Verify image path, re-run system test |
| Memory test flaky | Stimulus races write | Drive before active edge, keep reset connected |
| XSim won't start | OS policy blocking | Resolve Device Guard/Credential Guard |
| Debug nets no probe | `mark_debug` only | Use explicit ILA/VIO or generate `.ltx` |

## Related Documents
- [Unit Tests](../verification/unit-tests.md)
- [System Tests](../verification/system-tests.md)
- [Formal Verification](../formal/symbiyosys.md)
- [Performance Benchmark](../verification/benchmark.md)