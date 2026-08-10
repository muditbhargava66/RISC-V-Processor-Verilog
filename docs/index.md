# RISC-V Processor Documentation

Welcome to the RISC-V Processor documentation. This single-cycle RV32I processor is implemented in SystemVerilog and targets Xilinx Artix-7 FPGAs (Basys3 board).

## Documentation Index

### Getting Started
- [Quick Start Guide](guides/quick-start.md) - Build and run in 5 minutes
- [Prerequisites](guides/prerequisites.md) - Required tools and setup
- [Project Structure](guides/project-structure.md) - Repository layout explanation

### Architecture & Design
- [Architecture Overview](architecture/overview.md) - Single-cycle RV32I design
- [Instruction Set Support](architecture/isa-support.md) - RV32I base ISA coverage
- [Pipeline Design](architecture/pipeline.md) - Single-cycle datapath explanation
- [Memory Architecture](architecture/memory.md) - Harvard-style instruction/data memory
- [Extension Support](architecture/extensions.md) - M-extension and future C-extension

### Module Reference
- [Core Processor](modules/core-processor.md) - Top-level `riscv_processor`
- [ALU](modules/alu.md) - Arithmetic Logic Unit with M-extension
- [Control Unit](modules/control-unit.md) - Instruction decode and control signals
- [Register File](modules/register-file.md) - 32×32-bit with x0 hardwired
- [Program Counter](modules/program-counter.md) - PC with branch/jump handling
- [Immediate Generator](modules/immediate-generator.md) - All immediate formats
- [Instruction Memory](modules/instruction-memory.md) - Parameterized ROM
- [Data Memory](modules/data-memory.md) - Byte/halfword/word access
- [Wrappers](modules/wrappers.md) - Minimal and JTAG debug variants

### Verification
- [Verification Guide](verification/verification-guide.md) - Complete test suite
- [Unit Tests](verification/unit-tests.md) - ALU, Control, Memory, RegFile
- [System Integration](verification/system-tests.md) - Full processor test
- [Compliance Testing](verification/compliance.md) - RV32I smoke tests
- [Formal Verification](verification/formal.md) - SymbiYosys setup and SVA
- [Performance Benchmark](verification/benchmark.md) - IPC and throughput analysis

### FPGA Implementation
- [Basys3 Deployment](fpga/basys3-guide.md) - XC7A35T target
- [Minimal Wrapper](fpga/minimal-wrapper.md) - Low-I/O production build
- [JTAG Debug Build](fpga/jtag-debug.md) - ILA/VIO integration
- [Timing Analysis](fpga/timing.md) - 50MHz constraints and closure
- [Power Analysis](fpga/power.md) - Estimation and optimization
- [Bitstream Generation](fpga/bitstream.md) - Production flow

### Debug & Observability
- [ILA/VIO Integration](debug/ila-vio.md) - Explicit instantiation guide
- [Hardware Debug](debug/hardware-debug.md) - Vivado Hardware Manager
- [Signal Probing](debug/signal-probing.md) - Mark_debug and ILA signals
- [Runtime Control](debug/runtime-control.md) - VIO virtual I/O

### Formal Verification
- [SymbiYosys Setup](formal/symbiyosys.md) - Installation and configuration
- [SVA Properties](formal/sva-properties.md) - 15 assertions + 12 covers
- [Proof Strategies](formal/proof-strategies.md) - BMC, PDR, induction
- [Coverage Collection](formal/coverage.md) - Functional coverage metrics

### Performance Analysis
- [Benchmark Methodology](performance/methodology.md) - IPC measurement
- [Results Interpretation](performance/results.md) - Understanding IPC/CPI
- [Optimization Guide](performance/optimization.md) - Pipeline and timing

### Development
- [Build System](development/build-system.md) - Makefile and Tcl scripts
- [Adding Instructions](development/adding-instructions.md) - ISA extension guide
- [Coding Standards](development/coding-standards.md) - SystemVerilog style guide
- [Contributing](development/contributing.md) - Pull request process

### Reference
- [Instruction Set Table](reference/isa-table.md) - Complete RV32I encoding
- [Control Signal Table](reference/control-signals.md) - All control signals
- [Signal Dictionary](reference/signals.md) - All internal signals
- [FAQ](reference/faq.md) - Common questions
- [Troubleshooting](reference/troubleshooting.md) - Build/run issues

---

## Quick Links

| Task | Command |
|------|---------|
| Run all tests | `make test-all` |
| Lint check | `make lint` |
| Build minimal bitstream | `make implement-minimal` |
| Build JTAG debug bitstream | `make implement-jtag` |
| Run formal verification | `sby -f verification/formal.sby` |

---

*Last updated: August 2026 | Version 1.1.0 | [Changelog](../CHANGELOG.md)*