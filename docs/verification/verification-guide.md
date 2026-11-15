# Verification Guide

## Overview

This guide describes the verification infrastructure for the RISC-V processor. The verification suite includes unit tests, system integration tests, compliance smoke tests, formal verification, and performance benchmarking.

## Test Suite Summary

| Test Target | Testbench | Scope | Pass Criterion |
|-------------|-----------|-------|----------------|
| `lint` | Core RTL | Vivado compile/elaboration | No compile/elaboration errors |
| `test-alu` | `alu_tb.sv` | ALU operation vectors | All 21 vectors pass |
| `test-control` | `control_unit_tb.sv` | Decoder outputs | All 45 decode vectors match |
| `test-regfile` | `register_file_tb.sv` | Register writes/reads, x0 | All 37 checks pass |
| `test-memory` | `memory_tb.sv` | I-MEM/D-MEM byte/half/word | All 18 checks pass |
| `test-immgen` | `immediate_generator_tb.sv` | I/S/B/U/J immediates | All 8 checks pass |
| `test-pc` | `program_counter_tb.sv` | PC reset/update/hold | All 8 checks pass |
| `test-divider` | `divider_tb.sv` | RV32M divide (sequential) | All 884 checks pass |
| `test-system` | `riscv_processor_tb.sv` | Demo program execution | 6 register checks pass |
| `test-compliance` | `compliance_tests.sv` | Directed ISA checks | 41/41 pass |
| `test-benchmark` | `performance_benchmark.sv` | IPC measurement | 11 non-NOP instr / 14 cycles |
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

# Other tests: alu, control, memory, regfile, divider, compliance, formal, benchmark
```

## Test Details

### System Test (`test-system`)

**Testbench**: `testbenches/riscv_processor_tb.sv`

**Program** (`instruction_memory.hex`):
```
DEAD00B7  # LUI x1, 0xDEAD0
23408093  # ADDI x1, x1, 0x234
00102023  # SW x1, 0(x0)
00002103  # LW x2, 0(x0)
FFF00193  # ADDI x3, x0, -1
00100213  # ADDI x4, x0, 1
0041C263  # BLT x3, x4, target
000002B3  # ADD x5, x0, x0
004202B3  # ADD x5, x4, x4
0041D263  # BGE x3, x4, target
00420333  # ADD x6, x4, x4
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

**Coverage**: 21 test vectors covering all 10 base operations and the 4 RV32M
multiply ops (MUL/MULH/MULHSU/MULHU) with signed/unsigned corners. Divide/
remainder vectors moved to `divider_tb` when the divider became sequential.

### Divider Test (`test-divider`)

**Testbench**: `testbenches/divider_tb.sv`

**Coverage**: 884 checks against an independent oracle (SystemVerilog signed/
unsigned arithmetic): the combinational corner path (divide-by-zero, signed
overflow), directed normal vectors, 200 randomized operand/sign/opcode
combinations, busy/done handshake timing, the single-cycle `done` pulse, and
reset. See [Divider](../modules/divider.md).

### Control Unit Test (`test-control`)

**Testbench**: `testbenches/control_unit_tb.sv`

**Coverage**: 45 decode vectors covering all RV32I opcodes and funct3/funct7 combinations, plus the 8 RV32M decodes.

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

**Coverage**: A directed, cycle-accurate harness that deposits known programs into
instruction memory, runs them to completion, and checks architectural state via
hierarchical references. 41 checks across four phases:
- Phase A: R-type and I-type ALU operations
- Phase B: LUI/AUIPC, loads and stores (byte/half/word)
- Phase C: RV32M multiply/divide/remainder (including corner cases). The four
  normal divides stall the core ~32 cycles each; the harness runs a larger cycle
  budget for this phase. Divide-by-zero resolves in one cycle.
- Phase D: control flow (BEQ/BNE/BLT taken, JAL/JALR link and target)

**Note**: This is a directed self-checking harness, not the official RISC-V
Architectural Test suite. Full rv32ui compliance remains future work.

### Performance Benchmark (`test-benchmark`)

**Testbench**: `benchmarks/performance_benchmark.sv`

**Methodology**:
- Runs the canonical program at the 100 MHz simulation testbench clock
- Counts each non-NOP instruction once (single-cycle core: one fetch per cycle)
- Detects program end via a NOP/zero streak
- Reports IPC over the active program window and an instruction mix that sums to 100%

**Results (verified v1.2.0)**:
- Active program: 11 non-NOP instructions in 14 cycles (IPC ≈ 0.786)
- Instruction mix: 54.5% ALU, 9.1% Load, 9.1% Store, 18.2% Branch, 9.1% LUI/AUIPC
- Branch taken rate: 50% (1 of 2 branches taken)

**Honesty note**: This is a bounded diagnostic over a ~12-instruction program, not
a sustained performance measurement. There are no pass/fail "target frequency" or
"MIPS" targets, and no branch-prediction metric (the core has no predictor). The
100 MHz figure is the simulation clock, not the measured FPGA Fmax (the
synthesized core targets 50 MHz; see `build/reports/timing_minimal_impl.rpt`).

### Formal Verification (`test-formal`)

**Testbench**: `verification/formal_verification_tb.sv` + `verification/riscv_processor_sva.sv`

**SVA Properties**: 14 assertions + 15 cover properties (simulation-only; xsim ignores `cover property`)

**Key Properties**:
- PC word alignment
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
| `formal.sby` | prove | 50 | smtbmc, abc pdr |
| `formal_bmc.sby` | bmc | 12 | smtbmc bitwuzla |
| `formal_cover.sby` | cover | 30 | smtbmc |
| `formal_core.sby` | prove | 30 | abc pdr (quick core prove) |

All configs use the **yosys-slang** frontend (`read_slang --top riscv_processor_sva
-D IVERILOG ...`), which handles the SystemVerilog package/enums that Yosys's
native `read_verilog -sv` cannot parse. `-D IVERILOG` excludes the core's
simulation-only SVA; the formal contract is the wrapper `riscv_processor_sva.sv`,
elaborated with `prep -flatten`. The wrapper assumes a reset pulse in the first
cycle (an `init_cycle` flag) so PC word-alignment is checked from the
reset-initialized state. The prove configs use `wait off` so the fast `abc pdr`
(IC3) result terminates the run.

Running these requires the OSS CAD Suite (yosys + sby + solvers). With it
installed, `formal.sby` and `formal_core.sby` prove all assertions (abc pdr,
<1 s), and `formal_cover.sby` reaches all three cover points (branch taken,
memory write, memory read). `bitwuzla` is used for the BMC config (faster than
yices on this bitvector-heavy circuit). The canonical program image contains no
divide instructions, so the sequential divider stays idle in these proofs; its
correctness is established by `divider_tb` and the compliance Phase C checks.

### SVA Properties (in `riscv_processor.sv`)

**Assertions** (14):
1. PC word-aligned
2. x0 = 0 on read port 1
3. x0 = 0 on read port 2
4. Register write only for valid opcodes
5. Memory read only for loads
6. Memory write only for stores
7. Branch taken only for control flow
8. Valid opcode check
9. ADD ALU correctness
10. SUB ALU correctness
11. ADDI ALU correctness
12. No X/Z in PC
13. No X/Z in instruction
14. Reset behavior (PC = 0 after reset)

These invariants hold during a divide stall: the PC is held (still aligned),
register write-back is gated until `done`, and the divide funct3 never matches
the ADD/SUB/ADDI assertions.

**Cover Properties** (15):
- All 9 opcode types
- Branch taken/not taken
- Register writes to x1-x31
- Memory read/write

## Running Individual Tests Without Make

```bash
# Using the unified simulation script
vivado -mode batch -source scripts/run_simulation.tcl -tclargs <test_name>

# Valid test names:
# system, alu, control, memory, regfile, divider, compliance, formal, benchmark
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