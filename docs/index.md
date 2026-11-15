# RISC-V Processor Documentation

Welcome to the RISC-V Processor documentation. This single-cycle RV32I processor (with the RV32M extension) is implemented in SystemVerilog and targets Xilinx Artix-7 FPGAs (Basys3 board).

## Documentation Index

### Getting Started
- [Quick Start Guide](guides/quick-start.md) - Build and run in 5 minutes
- [Prerequisites](guides/prerequisites.md) - Required tools and setup
- [Project Structure](guides/project-structure.md) - Repository layout explanation

### Architecture & Design
- [Architecture Overview](architecture/overview.md) - Single-cycle RV32I design and datapath
- [Instruction Set Support](architecture/isa-support.md) - RV32I base ISA and RV32M extension coverage
- [Memory Architecture](architecture/memory.md) - Harvard-style instruction/data memory

### Module Reference
- [Core Processor](modules/core-processor.md) - Top-level `riscv_processor`
- [ALU](modules/alu.md) - Arithmetic Logic Unit (base RV32I + RV32M multiply)
- [Divider](modules/divider.md) - RV32M sequential divide/remainder
- [Control Unit](modules/control-unit.md) - Instruction decode and control signals
- [Register File](modules/register-file.md) - 32×32-bit with x0 hardwired
- [Program Counter](modules/program-counter.md) - PC with branch/jump handling
- [Immediate Generator](modules/immediate-generator.md) - All immediate formats
- [Instruction Memory](modules/instruction-memory.md) - Parameterized ROM
- [Data Memory](modules/data-memory.md) - Byte/halfword/word access
- [Wrappers](modules/wrappers.md) - Minimal and JTAG debug variants

### Verification
- [Verification Guide](verification/verification-guide.md) - Complete test suite: unit, system, compliance, formal, and benchmark

### FPGA Implementation
- [Basys3 Deployment](fpga/basys3-guide.md) - XC7A35T target
- [JTAG Debug Build](fpga/jtag-debug.md) - ILA/VIO integration
- [Timing Analysis](fpga/timing.md) - Clock constraints and closure
- [Power Analysis](fpga/power.md) - Estimation and optimization
- [Bitstream Generation](fpga/bitstream.md) - Production flow
- [Full-Core Characterization](fpga/full-core-characterization.md) - Complete core synth+impl (all debug ports)

### Debug & Observability
- [ILA/VIO Integration](debug/ila-vio.md) - Explicit instantiation guide
- [Hardware Debug](debug/hardware-debug.md) - Vivado Hardware Manager
- [Signal Probing](debug/signal-probing.md) - ILA signals
- [Runtime Control](debug/runtime-control.md) - VIO virtual I/O

### Formal Verification
- [SymbiYosys Setup](formal/symbiyosys.md) - Installation and configuration
- [SVA Properties](formal/sva-properties.md) - Assertion and cover properties
- [Proof Strategies](formal/proof-strategies.md) - BMC, PDR, induction
- [Coverage Collection](formal/coverage.md) - Functional coverage metrics

### Development
- [Build System](development/build-system.md) - Makefile and Tcl scripts
- [Adding Instructions](development/adding-instructions.md) - ISA extension guide
- [Coding Standards](development/coding-standards.md) - SystemVerilog style guide
- [Contributing](development/contributing.md) - Pull request process

---

## Quick Links

| Task | Command |
|------|---------|
| Run all directed tests (Vivado) | `make test-all` |
| Run all directed tests (Icarus Verilog) | `make iv-all` |
| Lint check (Verilator) | `make lint-verilator` |
| Lint/synthesis check (Vivado) | `make lint` |
| Build minimal bitstream | `make implement-minimal` |
| Build JTAG debug bitstream | `make implement-jtag` |
| Characterize the full core | `make full-core` |
| Run formal verification | `sby -f verification/formal.sby` |

---

*Last updated: November 2026 | Version 1.2.0 | [Changelog](../CHANGELOG.md)*