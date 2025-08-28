<div align = "center">

# RISC-V Processor v1.1.0

[![Improved](https://img.shields.io/badge/Status-Improved-brightgreen)](https://github.com/muditbhargava66/RISC-V-Processor-Verilog-)
[![FPGA Verified](https://img.shields.io/badge/FPGA-Synthesized-blue)](https://github.com/muditbhargava66/RISC-V-Processor-Verilog-)
[![RV32I Complete](https://img.shields.io/badge/ISA-RV32I%20Complete-orange)](https://github.com/muditbhargava66/RISC-V-Processor-Verilog-)

**A complete, improved, and more robust RISC-V RV32I processor implemented in Verilog. Successfully synthesized in Xilinx Vivado with excellent resource utilization and timing performance. Ready for FPGA deployment and educational use.**

</div>

## Table of Contents
- [Features](#-features)
- [Changelog (v1.1.0)](#-changelog-v110)
- [Directory Structure](#-directory-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#-usage)
  - [Simulation](#simulation)
  - [Synthesis & Implementation](#synthesis--implementation)
  - [FPGA Deployment](#fpga-deployment)
- [Complete RV32I Instruction Set Support](#-complete-rv32i-instruction-set-support)
- [Architecture Overview](#-architecture-overview)
- [Verification & Testing](#-verification--testing)
- [Synthesis Results](#-synthesis-results-vivado-20222)
- [Production Status](#-production-status)
- [Future Enhancements](#-future-enhancements)
- [Contributing](#-contributing)
- [License](#-license)

## ✅ Features
- **Complete RV32I Implementation**: All 37 RISC-V base integer instructions.
- **Configurable Memory**: Instruction and data memory sizes can be easily configured using Verilog parameters.
- **Robust Memory Access**: Data memory includes simulation-time checks for misaligned load/store operations, improving software development reliability.
- **Bug Fixes & Refactoring**: Corrected LUI instruction and optimized branch logic.
- **Robust Verification**: Includes a comprehensive, self-checking testbench.
- **Flexible Program Loading**: Instruction memory can be loaded from a hex file for easy testing.
- **FPGA Optimized**: Single-cycle architecture with proper resets on all state elements.
- **Resource Efficient**: Low resource footprint on Artix-7 FPGAs.
- **Timing Clean**: Meets 100MHz operation with positive slack.

## 📖 Changelog (v1.1.0)
- **Bug Fix**: Corrected a critical bug in the `LUI` instruction where it would write `0` instead of the immediate value.
- **Refactoring**: Removed the redundant `branch_unit` and now use the ALU for branch condition evaluation. This simplifies the design and reduces resource usage.
- **Enhanced Verification**: Replaced the previous testbench with a comprehensive, self-checking testbench (`riscv_processor_tb.v`) that verifies the correctness of register values against a test program.
- **Flexible Memory**: The instruction memory is now loaded from `instruction_memory.hex` using `$readmemh`, allowing for easy testing of different programs without re-synthesis.

## 📁 Directory Structure
```
├── src/                          # Core processor implementation
│   ├── riscv_processor.v         # Top-level processor integration
│   ├── alu.v                     # Arithmetic Logic Unit
│   ├── register_file.v           # 32×32-bit register file
│   ├── Control_unit.v            # Instruction decoder
│   ├── immediate_generator.v     # Immediate value extraction
│   ├── program_counter.v         # PC management
│   ├── instruction_memory.v      # 1KB instruction storage
│   └── data_memory.v             # 1KB data storage
├── testbenches/                  # Comprehensive verification suite
│   ├── riscv_processor_tb.v      # Self-checking system testbench
│   ├── instruction_memory.hex    # Test program for simulation
│   ├── alu_tb.v                  # ALU component test
│   ├── control_unit_tb.v         # Control unit test
│   ├── register_file_tb.v        # Register file test
│   ├── memory_tb.v               # Memory modules test
│   └── run_all_tests.tcl         # Automated test runner
├── constraints/                  # FPGA constraints
│   └── riscv_processor.xdc       # Timing and pin assignments
├── scripts/                      # Build and analysis automation
│   ├── build_vivado_v1.tcl       # Project generation
│   ├── run_synthesis.tcl         # Synthesis automation
│   └── generate_reports.tcl      # Enhanced reporting
├── reports/                      # Synthesis reports
│   ├── utilization_synth.rpt     # Resource utilization
│   └── timing_synth.rpt          # Timing analysis
├── projects/                     # Generated Vivado projects
├── .gitignore                    # Git ignore rules
├── README.md
└── LICENSE
```

## Getting Started

### Prerequisites
- Xilinx Vivado Design Suite (version 2022.2 or later)
- Target FPGA: Xilinx Artix-7 XC7A35T (Basys3 board recommended)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/muditbhargava66/RISC-V-Processor-Verilog-.git
   cd RISC-V-Processor-Verilog-
   ```

2. **Quick Start - Automated Setup:**
   ```bash
   # Generate Vivado project automatically
   vivado -mode batch -source scripts/build_vivado_v1.tcl
   
   # Open the generated project
   vivado projects/vivado/riscv_processor_v1/riscv_processor_v1.xpr
   ```

3. **Manual Setup:**
   - Open Xilinx Vivado and create a new project
   - Add all Verilog files from `src/` directory
   - Add constraint file `constraints/riscv_processor.xdc`
   - Set `riscv_processor.v` as top module

## 🚀 Usage

### Simulation
```bash
# Run testbench simulation
vivado -mode batch -source scripts/run_synthesis.tcl

# Or manually in Vivado GUI:
# 1. Open project: projects/vivado/riscv_processor_v1/riscv_processor_v1.xpr
# 2. Set testbenches/riscv_processor_tb.v as simulation top
# 3. Run behavioral simulation
```

### Synthesis & Implementation
```bash
# Automated synthesis (recommended)
vivado -mode batch -source scripts/run_synthesis.tcl

# Manual process:
# 1. Open Vivado project
# 2. Run Synthesis (takes ~2-3 minutes)
# 3. Run Implementation 
# 4. Generate Bitstream
# 5. Program FPGA (Basys3/Artix-7 target)
```

### FPGA Deployment
- **Target Board**: Digilent Basys3 (Artix-7 XC7A35T)
- **Clock**: 100MHz system clock
- **Resources Used**: 911 LUTs (4.4%), 128 FFs (0.3%), 1 BRAM (2%)
- **Performance**: Timing clean at 100MHz operation

## 📋 Complete RV32I Instruction Set Support

**✅ All 37 RV32I Base Instructions Implemented:**

| Type | Instructions | Count | Status |
|------|-------------|-------|---------|
| **R-type** | ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND | 10 | ✅ Complete |
| **I-type** | ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, LB, LH, LW, LBU, LHU, JALR | 15 | ✅ Complete |
| **S-type** | SB, SH, SW | 3 | ✅ Complete |
| **B-type** | BEQ, BNE, BLT, BGE, BLTU, BGEU | 6 | ✅ Complete |
| **U-type** | LUI, AUIPC | 2 | ✅ Complete |
| **J-type** | JAL | 1 | ✅ Complete |

## 🏗️ Architecture Overview

### Single-Cycle Design
- **Harvard Architecture**: Separate instruction and data memory paths
- **32-bit RISC-V RV32I**: Complete base integer instruction set
- **Single-Cycle Execution**: One instruction per clock cycle for predictable timing
- **32 Registers**: x0-x31 with x0 hardwired to zero
- **Memory**: 1KB instruction memory (loadable from file), 1KB data memory
- **Addressing**: Byte-addressable memory with proper alignment

### Key Components
1. **Program Counter (PC)**: Manages instruction sequencing
2. **Instruction Memory**: 1KB ROM, loadable from a hex file for simulation.
3. **Control Unit**: Decodes instructions and generates control signals
4. **Register File**: 32×32-bit registers with x0=0
5. **ALU**: Performs all arithmetic, logical, and branch comparison operations.
6. **Immediate Generator**: Extracts and sign-extends immediates
7. **Data Memory**: 1KB RAM with byte/halfword/word access

## 🧪 Verification & Testing

### Robust Verification Environment
The processor includes an improved verification environment designed for robustness and accuracy:

#### **Individual Component Tests**
- **`alu_tb.v`**: Tests all 10 ALU operations with comprehensive test vectors
- **`control_unit_tb.v`**: Verifies all 37 RV32I instruction decodings
- **`register_file_tb.v`**: Tests 32×32-bit register file with x0 hardwiring
- **`memory_tb.v`**: Validates instruction and data memory with all access types

#### **System Integration Test**
- **`riscv_processor_tb.v`**: A self-checking testbench that runs a comprehensive test program (`instruction_memory.hex`) and verifies the final register state against expected values.
  - **Test Program**: The test program covers a wide range of instructions, including arithmetic, logic, load/store, and control flow operations, specifically testing the LUI bugfix and the new branch logic.
  - **Self-Checking**: The testbench automatically compares the contents of the register file at the end of the simulation with golden values, reporting a clear PASS or FAIL status.
  - **Flexible**: Easily test new programs by modifying the `instruction_memory.hex` file.

#### **Running the System Test**
The primary method for verification is now through the self-checking system test.

```bash
# Run the self-checking system testbench
cd testbenches
vivado -mode batch -source run_all_tests.tcl
```
The script will create a Vivado project, load the processor and the test program, run the simulation, and print the verification results to the console. A successful run will end with an "ALL TESTS PASSED!" message.

## 📊 Synthesis Results (Vivado 2022.2)

### Resource Utilization
| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| **LUTs** | 911 | 20,800 | 4.4% |
| **Flip-Flops** | 128 | 41,600 | 0.3% |
| **Block RAM** | 1 | 50 | 2.0% |
| **DSP Slices** | 0 | 90 | 0% |

### Timing Performance
- **Target Device**: Xilinx Artix-7 XC7A35T (Basys3 board)
- **Clock Frequency**: 100MHz (10ns period)
- **Setup Timing**: Met with positive slack
- **Hold Timing**: Met
- **Critical Path**: Through ALU and register file

### Power Estimation
- **Dynamic Power**: Low (single-cycle, no complex control)
- **Static Power**: Minimal FPGA overhead
- **Thermal**: Well within Artix-7 limits

### Enhanced Reporting
Generate comprehensive analysis reports:
```bash
# Generate detailed reports
vivado -mode batch -source scripts/generate_reports.tcl

# Reports generated:
# - utilization_detailed.rpt: Hierarchical resource usage
# - timing_summary.rpt: Complete timing analysis
# - critical_path.rpt: Critical path details
# - power_analysis.rpt: Power consumption analysis
# - methodology_check.rpt: Design methodology verification
# - synthesis_summary.rpt: Executive summary
```

## 🏆 Production Status

### ✅ Version 1.1.0 Achievements
- **Improved Correctness**: Fixed critical bug in LUI instruction.
- **Efficient Design**: Refactored branch logic to be more efficient and simpler.
- **Robust Verification**: Implemented a comprehensive self-checking testbench.
- **Enhanced Usability**: Processor can now be tested with any program via a hex file.
- **FPGA Verified**: Successfully synthesized in Vivado 2022.2.
- **Timing Clean**: Meets 100MHz operation with positive slack.
- **Resource Efficient**: Optimized for Artix-7 FPGA family.

## 🔮 Future Enhancements

### Performance Improvements
- [ ] **5-Stage Pipeline**: Increase throughput to ~500MHz
- [ ] **Branch Prediction**: Reduce branch penalty
- [ ] **Cache System**: Add L1 instruction/data caches
- [ ] **Forwarding Unit**: Handle data hazards in pipeline

### ISA Extensions
- [ ] **RV32M**: Multiply/Divide extension
- [ ] **RV32F**: Single-precision floating-point
- [ ] **RV32C**: Compressed instructions (16-bit)
- [ ] **Custom Extensions**: Application-specific instructions

### System Features
- [ ] **Interrupt Controller**: Handle external interrupts
- [ ] **Memory Management**: Virtual memory support
- [ ] **Debug Interface**: JTAG debugging capability
- [ ] **Multi-Core**: SMP support with cache coherence

### Verification Enhancements
- [ ] **Formal Verification**: Property checking with SVA
- [ ] **Coverage Analysis**: Functional and code coverage
- [ ] **RISC-V Compliance**: Official test suite integration
- [ ] **Performance Benchmarks**: CoreMark, Dhrystone testing

## 🤝 Contributing
Contributions are welcome! Areas where help is appreciated:
- Performance optimizations and pipelining
- Additional ISA extensions (RV32M, RV32F, RV32C)
- Enhanced verification and formal methods
- Documentation improvements and examples
- FPGA board support for other devices

Please open an issue or submit a pull request with your improvements.

## 📄 License
This project is licensed under the [MIT License](LICENSE).

---
<div align = "center">

**🎯 Ready to deploy your RISC-V processor? Clone, synthesize, and program to FPGA in minutes!**

</div>