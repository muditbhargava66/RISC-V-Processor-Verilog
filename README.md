# RISC-V Processor (v1.1.0 integration work)

This repository contains a Verilog, single-cycle RISC-V processor and a Vivado-oriented verification/build flow. `v1.1.0` is an **unreleased integration milestone**; the only published Git tag is `v1.0.0`. Treat the build and test results produced from the current checkout as the source of truth rather than historical performance, compliance, or FPGA-readiness claims.

## Status at a glance

- The core RTL, unit testbenches, system testbench, and Vivado Tcl flow are maintained together in this repository.
- The canonical demonstration program is [instruction_memory.hex](instruction_memory.hex). The build and simulation flows add this file explicitly; a bare `$readmemh("instruction_memory.hex", ...)` lookup is not a portable program-loading mechanism.
- `riscv_processor` exposes wide debug ports for simulation and inspection. It is not the board top-level because those ports exceed the Basys3 I/O budget.
- `riscv_processor_minimal` is the baseline board wrapper. `riscv_processor_jtag_debug` marks internal nets for Vivado debug discovery, but it does **not** instantiate an ILA, VIO, or a RISC-V Debug Specification module. See [reports/JTAG_DEBUG_SOLUTION_SUMMARY.md](reports/JTAG_DEBUG_SOLUTION_SUMMARY.md).
- `verification/compliance_tests.v`, the SVA files, and the benchmark are useful diagnostics, not evidence of official RISC-V compliance, exhaustive formal proof, or measured sustained IPC. See [docs/VERIFICATION_GUIDE.md](docs/VERIFICATION_GUIDE.md).

## Repository layout

```text
src/                         Processor RTL
  riscv_processor.v          Core with simulation/debug ports
  riscv_processor_minimal.v  Basys3-oriented, low-I/O wrapper
  riscv_processor_jtag_debug.v  Debug-net wrapper (no debug IP instantiated)
testbenches/                 Directed unit and system testbenches
instruction_memory.hex       Canonical demonstration program image
verification/                Assertion simulation and directed smoke checks
benchmarks/                  Diagnostic benchmark testbench
scripts/                     Unified Vivado and Quartus Tcl entry points
constraints/                 Target-specific FPGA constraints
reports/                     Checked-in historical/audit summaries
build/                       Ignored generated Vivado projects, runs, and reports
docs/                        Verification guidance
```

## Requirements

- Xilinx Vivado 2023.2 or a compatible 7-series Vivado release. The checked-in scripts target `xc7a35tcpg236-1` (Basys3).
- GNU Make is optional; it is a convenience wrapper around the Tcl scripts.
- Vitis is not required: this is RTL-only and contains no Vitis platform, HLS, BSP, or software application project.

## Coherent verification flow

Run commands from the repository root. The test image belongs in `testbenches/`; do not copy it to arbitrary working directories by hand.

```powershell
# Directed RTL tests
make test-alu
make test-control
make test-regfile
make test-memory
make test-system

# Optional diagnostic checks; not release qualification
make test-compliance
make test-formal
make test-benchmark
```

The five directed tests are the functional gate. A run passes only when its testbench reports no failed checks and exits normally. The diagnostic targets may reveal useful issues, but they must not be summarized as “100% RV32I compliant,” “formally verified,” or “1.0 IPC” without the stronger evidence described in the verification guide.

To invoke the test runner without Make:

```powershell
vivado -mode batch -source scripts/run_simulation.tcl -tclargs system
vivado -mode batch -source scripts/run_simulation.tcl -tclargs alu
```

The supported test names are `system`, `alu`, `control`, `memory`, `regfile`, `compliance`, `formal`, and `benchmark`.

## FPGA build flow

Run the non-destructive lint/synthesis check first, then start with the minimal wrapper. It has a target-specific XDC and stays within the Basys3 I/O budget.

```powershell
# Compile/elaborate the core without replacing an existing project.
make lint

# Create and implement a fresh minimal-wrapper project under build/.
make implement-minimal
```

The resulting Vivado project and generated timing/utilization reports are local artifacts under `build/`. Review the implementation status, DRC, and timing report before programming hardware. Do not call a design timing-clean or FPGA-ready based only on a previous report or a successful RTL simulation.

The full-debug core can be synthesized for RTL/resource inspection:

```powershell
make synthesize
```

It is intentionally not the FPGA implementation target. The JTAG-marked wrapper is exploratory until a reproducible debug-core flow (with an ILA/VIO instance or a documented Vivado debug-insertion flow and generated `.ltx`) is added and verified:

```powershell
make implement-jtag
```

## Program images

Instruction memory is word-addressed by `address[ADDR_WIDTH+1:2]`. A program image contains one 32-bit hexadecimal instruction per line, with the first line mapped to PC `0x00000000`. The repository uses [instruction_memory.hex](instruction_memory.hex) for the self-checking system program.

When adding an image, keep it in an explicit, version-controlled location and update the appropriate test/build configuration. A synthesis or implementation run must also declare/stage the image, otherwise the initialized memory contents are tool- and working-directory-dependent.

## Architecture notes

- Harvard-style instruction and data memories
- 32 general-purpose registers, with x0 hard-wired to zero
- Single-cycle datapath and control flow
- Directed tests exercise ALU operations, decoding, register file behavior, memory accesses, and a small integration program

The decoder and RTL are intended to cover the RV32I base instruction categories. Full ISA conformance requires the official RISC-V Architectural Test suite (or an equivalent independently maintained suite), an explicit execution environment, and reproducible pass logs; that qualification has not yet been completed.

## Release gate for v1.1.0

Before creating a v1.1.0 tag or claiming FPGA deployment readiness, record all of the following from a clean checkout:

1. Passing directed unit and system test logs using the staged instruction image.
2. Successful fresh synthesis, implementation, DRC, and timing reports for the selected board wrapper.
3. The exact Vivado version, FPGA part, top module, constraints file, and program image hash.
4. If debug is advertised, a reproducible ILA/VIO or equivalent flow, including the generated probe file and a hardware capture.
5. If compliance, formal verification, or performance is advertised, the corresponding official suite/prover/retirement-based benchmark and its raw result.

## Documentation

- [Verification guide](docs/VERIFICATION_GUIDE.md)
- [Change log](CHANGELOG.md)
- [Version roadmap](VERSION_ROADMAP.md)
- [Verification audit report](reports/COMPREHENSIVE_VERIFICATION_REPORT.md)
- [JTAG/debug status](reports/JTAG_DEBUG_SOLUTION_SUMMARY.md)

## License

This project is licensed under the [MIT License](LICENSE).
