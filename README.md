<div align="center">

# RISC-V Processor

[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)](https://github.com/muditbhargava66/RISC-V-Processor-Verilog-/actions)
[![License](https://img.shields.io/badge/License-MIT-blue)](https://github.com/muditbhargava66/RISC-V-Processor-Verilog-/blob/main/LICENSE)
[![SystemVerilog](https://img.shields.io/badge/SystemVerilog-2017-blue)](https://github.com/muditbhargava66/RISC-V-Processor-Verilog-)
[![FPGA Target](https://img.shields.io/badge/FPGA-Artix%207%20XC7A35T-green)](https://www.xilinx.com/products/silicon-devices/fpga/artix-7.html)
[![RV32I](https://img.shields.io/badge/ISA-RV32I%20Complete-orange)](https://riscv.org/specifications/)

Single-cycle RV32I processor implemented in SystemVerilog with Vivado and Quartus build flows.

</div>

## Status

- Core RTL, testbenches, and build scripts maintained in this repository
- Canonical test program in instruction_memory.hex
- Debug-oriented core (riscv_processor) exposes wide debug ports for simulation
- Minimal wrapper (riscv_processor_minimal) fits Basys3 I/O budget
- JTAG debug wrapper (riscv_processor_jtag_debug) includes explicit ILA and VIO instantiation
- Verification infrastructure includes unit tests, system tests, compliance checks, formal verification, and benchmarks

## Repository Layout

```
src/                          Processor RTL
  riscv_processor.sv          Core with simulation/debug ports
  riscv_processor_minimal.sv  Basys3-oriented low-I/O wrapper
  riscv_processor_jtag_debug.sv  JTAG debug wrapper with ILA/VIO
testbenches/                  Unit and system testbenches
instruction_memory.hex        Canonical test program
verification/                 Formal verification and compliance checks
benchmarks/                   Performance benchmark testbench
scripts/                      Vivado and Quartus Tcl entry points
constraints/                  XDC (Xilinx) and SDC (Intel) constraint files
docs/                         Documentation
build/                        Generated Vivado/Quartus projects (gitignored)
```

## Requirements

- Xilinx Vivado 2023.2 or compatible 7-series release (target: xc7a35tcpg236-1 Basys3)
- Intel Quartus Prime 23.1 or later (for SDC flow)
- GNU Make (optional, convenience wrapper around Tcl scripts)
- SymbiYosys and solvers (Yices2, Z3, Boolector) for formal verification

## Getting Started

### Prerequisites

- Xilinx Vivado Design Suite 2023.2 or later
- Target FPGA: Xilinx Artix-7 XC7A35T (Basys3 board recommended)
- Git and GNU Make

### Quick Start (Recommended)

```bash
# 1. Clone the repository
git clone https://github.com/muditbhargava66/RISC-V-Processor-Verilog-.git
cd RISC-V-Processor-Verilog-

# 2. Run lint check (verifies syntax and elaboration)
make lint

# 3. Run all directed tests (functional gate)
make test-all

# 4. Build minimal wrapper bitstream for Basys3
make implement-minimal
```

### Running Individual Tests

```bash
# Directed RTL tests
make test-alu
make test-control
make test-regfile
make test-memory
make test-system

# Optional diagnostic checks
make test-compliance
make test-formal
make test-benchmark

# Lint/synthesis check only
make lint
```

### Without Make (Direct Vivado)

```powershell
# System test
vivado -mode batch -source scripts/run_simulation.tcl -tclargs system

# ALU test
vivado -mode batch -source scripts/run_simulation.tcl -tclargs alu

# Other targets: control, memory, regfile, compliance, formal, benchmark
vivado -mode batch -source scripts/run_simulation.tcl -tclargs <test_name>
```

### FPGA Build Flow

1. **Lint check first** (catches syntax/elaboration errors early):
   ```bash
   make lint
   ```

2. **Implement minimal wrapper** (creates bitstream for Basys3):
   ```bash
   make implement-minimal
   ```
   Output: `build/vivado/riscv_processor_minimal/riscv_processor_minimal.bit`

3. **Optional: JTAG debug build** (includes ILA/VIO cores):
   ```bash
   make implement-jtag
   ```

### Program Images

Instruction memory is word-addressed by `address[ADDR_WIDTH+1:2]`. One 32-bit hex instruction per line, first line maps to PC `0x00000000`. The repository uses `instruction_memory.hex` for the self-checking system program.

Keep images in explicit, version-controlled locations and update test/build configurations. Synthesis and implementation runs must declare the image, otherwise memory contents are tool- and directory-dependent.

## Architecture

- Harvard-style instruction and data memories
- 32 general-purpose registers, x0 hardwired to zero
- Single-cycle datapath and control
- Tests cover ALU operations, decoding, register file, memory access, and a small integration program

The decoder and RTL cover RV32I base instruction categories. Full ISA conformance requires the official RISC-V Architectural Test suite, an explicit execution environment, and reproducible pass logs.

## Implementation Results (v1.1.0 on Artix-7 xc7a35tcpg236-1)

### Synthesis Results (Vivado 2023.2)

| Metric | Value |
|--------|-------|
| **Status** | PASSED (0 errors, 0 critical warnings, 3 warnings) |
| **LUTs** | 4,132 / 20,800 (19.9%) |
| **Flip-Flops** | 8,416 / 41,600 (20.2%) |
| **DSP48E1** | 2 / 90 (2.2%) |
| **Block RAM** | 0 / 50 (0%) |
| **I/O** | 12 / 88 (13.6%) |

**Hierarchy Breakdown:**
| Instance | LUTs | FFs | DSPs |
|----------|------|-----|------|
| riscv_processor (top) | 4,132 | 8,416 | 2 |
| └── dmem_inst (data_memory) | 2,200 | 8,192 | 0 |
| └── pc_inst (program_counter) | 538 | 32 | 0 |
| └── regfile_inst (register_file) | 1,394 | 192 | 0 |

**DSP Utilization:** 2 DSP48E1 blocks (MUL/MULH operations)

### Implementation Results (Vivado 2023.2, xc7a35tcpg236-1)

| Metric | Value | Status |
|--------|-------|--------|
| **WNS (Worst Negative Slack)** | +1.771 ns | ✅ MET |
| **TNS (Total Negative Slack)** | 0.000 ns | ✅ MET |
| **WHS (Worst Hold Slack)** | +0.124 ns | ✅ MET |
| **THS (Total Hold Slack)** | 0.000 ns | ✅ MET |
| **DRC Errors** | 0 | ✅ CLEAN |
| **Bitstream Generated** | ✅ SUCCESS | `riscv_processor_minimal.bit` |

**Resource Utilization (Post-Implementation):**
| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUTs | 4,132 | 20,800 | 19.9% |
| FFs | 8,416 | 41,600 | 20.2% |
| DSP48E1 | 2 | 90 | 2.2% |
| BRAM | 0 | 50 | 0% |
| I/O | 18 | 88 | 20.5% |

**Timing Summary (50 MHz / 20 ns period):**
| Corner | WNS (ns) | TNS (ns) | WHS (ns) | THS (ns) |
|--------|----------|----------|----------|----------|
| Slow (max) | +1.771 | 0.000 | +0.124 | 0.000 |
| Fast (min) | +1.771 | 0.000 | +0.124 | 0.000 |

**Power Estimation (Vector-less):**
- Total Power: ~127 mW
- Dynamic: ~53 mW (42%)
- Static: ~74 mW (58%)
- Junction Temp: ~25.6°C

### Synthesis Results (v1.1.0)

| Metric | Value |
|--------|-------|
| **Errors** | 0 |
| **Critical Warnings** | 0 |
| **Warnings** | 3 (unused address bits - expected) |
| **Critical Path** | ~9.5 ns (ALU → D-MEM → Writeback) |
| **Max Frequency** | >100 MHz (50 MHz target with 100%+ margin) |

### Hierarchy Breakdown (Synthesis)

| Instance | Module | LUTs | FFs | DSPs |
|----------|--------|------|-----|------|
| riscv_processor (top) | 4,132 | 8,416 | 2 |
| └── dmem_inst | data_memory | 2,200 | 8,192 | 0 |
| └── pc_inst | program_counter | 538 | 32 | 0 |
| └── regfile_inst | register_file | 1,394 | 192 | 0 |

**Synthesis Warnings:** 3 (unused address bits on I-MEM/D-MEM - expected for 8-bit address width)

## Verification

### Directed Tests (Functional Gate)

```bash
make test-all
```

| Test | Scope | Result |
|------|-------|--------|
| `test-system` | Full program execution (11 instructions) | 6/6 register checks PASS |
| `test-alu` | 24 ALU operation vectors | 24/24 PASS |
| `test-control` | 37 decode vectors | 37/37 PASS |
| `test-memory` | I-MEM/D-MEM access patterns | 18/18 PASS |
| `test-regfile` | Register read/write, x0 behavior | 37/37 PASS |

### Diagnostic Checks

```bash
make test-compliance   # RV32I smoke checks (5/5 PASS, 3 skipped)
make test-formal       # SVA assertion simulation (15 assertions, 12 covers)
make test-benchmark    # IPC measurement (10 instr / 10 cycles = 1.0 IPC active)
make test-benchmark    # Full run: 0.020 IPC over 500 cycles (includes NOP padding)
```

### Formal Verification (SymbiYosys)

```bash
sby -f verification/formal.sby      # Full proof (BMC + PDR + ABC)
sby -f verification/formal_bmc.sby  # Bounded model checking
sby -f verification/formal_cover.sby # Coverage collection
sby -f verification/formal_core.sby  # Core-only prove
```

**SVA Properties:** 15 assertions + 12 cover properties (inline in `riscv_processor.sv`)

### Lint/Synthesis Check

```bash
make lint
```

**Result:** SYNTHESIS PASSED (0 errors, 0 critical warnings, 3 warnings)

## Documentation

- [Verification guide](docs/verification/verification-guide.md)
- [Change log](CHANGELOG.md)
- [Version roadmap](VERSION_ROADMAP.md)

## License

This project is licensed under the [MIT License](LICENSE).