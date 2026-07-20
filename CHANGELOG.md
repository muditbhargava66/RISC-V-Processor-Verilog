# Changelog

All notable changes to the RISC-V Processor project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-05-21

### Added
- **Enhanced Debug Interface**
  - Added comprehensive debug ports to processor module
  - Register file access through debug ports
  - Memory operation monitoring
  - Control signal visibility for verification
  - Branch taken status monitoring

- **Formal Verification Support**
  - SystemVerilog Assertions (SVA) for critical properties
  - Property checking for instruction execution
  - Formal verification scripts for Vivado
  - Assertion-based verification framework

- **Multi-Tool Support**
  - Complete Quartus Prime integration
  - Quartus-specific constraint files (.sdc)
  - Cross-platform build system
  - Tool availability checking

- **Enhanced Testing Framework**
  - Comprehensive instruction decoder in testbench
  - Performance analysis with IPC calculations
  - Instruction trace monitoring
  - Register and memory operation verification
  - Branch behavior validation

- **Consolidated Build System**
  - Parameterized `scripts/build_vivado.tcl` supporting `v1`, `minimal`, and `jtag_debug` project creation
  - Parameterized `scripts/run_simulation.tcl` simulating `system`, `alu`, `control`, `memory`, `regfile`, `compliance`, `formal`, and `benchmarks`
  - Simplified dual-tool Makefile (Vivado + Quartus) pointing to unified scripts and using inline Vivado commands

- **Documentation**
  - VERSION_ROADMAP.md with future development plans
  - CHANGELOG.md for tracking changes
  - Enhanced README with multi-tool support
  - Comprehensive release notes

### Changed
- **RTL Refactoring (DRY compliance)**
  - Refactored `src/riscv_processor_minimal.v` to be a thin wrapper around `src/riscv_processor.v`
  - Refactored `src/riscv_processor_jtag_debug.v` to wrap `src/riscv_processor.v` while preserving logic debugging probe attributes (`mark_debug = "true"`)
  - Eliminated duplicated processor core logic from project wrapper files

- **Testbench & Build System Cleanups**
  - Replaced basic testbench with comprehensive verification suite
  - Removed 14 redundant `.tcl` build and simulation scripts in `scripts/` and `testbenches/`
  - Cleaned up `constraints/` folder by deleting `riscv_processor.xdc` (now using target-specific constraint files)
  - Cleaned up `reports/` folder by removing intermediate `.rpt` files and retaining only final verification and debug summaries
  - Removed emojis from all codebase documentation files to maintain a professional project aesthetic

### Fixed
- **Processor Logic Bug Fixes**
  - Fixed critical bug in `LUI` instruction execution (previously writing 0 to `rd` instead of loading the upper immediate)
  - Removed redundant `branch_unit` and integrated branch evaluation directly into ALU-based comparisons to optimize footprint

- **Testbench Issues**
  - Fixed Verilog-2001 compatibility issues
  - Resolved variable declaration problems
  - Corrected function syntax for older Verilog standards

- **Build System**
  - Fixed Windows command compatibility
  - Resolved path handling issues
  - Corrected Makefile syntax errors

### Technical Achievements
- **Verification Coverage**: 15+ SystemVerilog assertions implemented
- **Compliance Testing**: RV32I specification compliance verification
- **Performance Benchmarking**: Comprehensive performance analysis framework
- **Multi-Tool Support**: Both Vivado and Quartus Prime integration
- **Debug Interface**: Complete processor state visibility for verification

### Quality Metrics
- **Formal Verification**: All critical properties verified
- **Compliance Rate**: 100% RV32I specification adherence
- **Performance Grade**: EXCELLENT (IPC = 1.000, 100MHz operation)
- **Test Coverage**: Enhanced with register and memory verification
- **Build System**: Cross-platform compatibility achieved


## [1.0.0] - 2025-08-12

### Added
- **Complete RV32I Implementation**
  - All 37 RISC-V base integer instructions
  - Single-cycle architecture optimized for FPGA
  - Harvard architecture with separate instruction and data memories
  - 32×32-bit register file with x0 hardwired to zero

- **Core Components**
  - Program Counter with branch and jump support
  - Instruction Memory (1KB) with test program
  - Data Memory (1KB) with byte/halfword/word access
  - Arithmetic Logic Unit with all required operations
  - Control Unit supporting all instruction types
  - Immediate Generator for all immediate formats
  - Branch Unit with all comparison operations

- **FPGA Support**
  - Xilinx Vivado synthesis and implementation
  - Artix-7 XC7A35T target (Basys3 board)
  - Complete constraint files and pin assignments
  - Timing constraints for 100MHz operation

- **Verification**
  - System testbench with instruction execution monitoring
  - Individual component testbenches
  - Synthesis verification with zero errors
  - Timing analysis with positive slack

- **Build System**
  - Comprehensive Makefile for automation
  - Vivado TCL scripts for project creation
  - Automated synthesis and reporting
  - PowerShell cleanup scripts

- **Documentation**
  - Complete README with usage instructions
  - Architecture overview and specifications
  - Synthesis results and performance metrics
  - Installation and deployment guides

### Technical Specifications
- **Resource Utilization**: 875 LUTs (4.2%), 128 FFs (0.3%), 1 BRAM (2%)
- **Timing Performance**: 100MHz operation with positive slack
- **Instruction Set**: Complete RV32I (37 instructions)
- **Memory**: 1KB instruction + 1KB data memory
- **Architecture**: Single-cycle Harvard architecture

### Quality Assurance
- **Synthesis**: Zero errors, zero critical warnings
- **Simulation**: All instructions verified in testbench
- **Timing**: Setup and hold requirements met
- **Resource**: Efficient utilization under 5% LUT usage
- **Documentation**: Complete with examples and usage guides

## [0.1.0] - Initial Development

### Added
- Basic processor structure
- Initial Verilog modules
- Preliminary testbenches
- Basic documentation

### Notes
- This was the initial development version
- Not production-ready
- Used for early development and testing