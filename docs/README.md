# RISC-V Processor

This repository contains a RISC-V processor implemented in Verilog. The processor supports a subset of the RISC-V instruction set architecture (ISA) and is designed to be synthesized and simulated using Xilinx Vivado.

## Table of Contents
- [Features](#features)
- [Directory Structure](#directory-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
  - [Simulation](#simulation)
  - [Synthesis](#synthesis)
- [Instruction Set Support](#instruction-set-support)
- [Testbenches](#testbenches)
- [Memory Initialization](#memory-initialization)
- [Contributing](#contributing)
- [License](#license)
- [Future Work](#planned-updates-and-future-work)

## Features
- Implements a subset of the RISC-V ISA
- Supports R-type, I-type, S-type, J-type, and B-type instructions
- 5-stage pipeline architecture
- Hazard detection and forwarding unit
- Branch prediction and control flow handling
- Memory interface for instruction and data memory
- Parameterized design for easy configuration

## Directory Structure
```
├── src/
│   ├── ALU_control.v
│   ├── Control_unit.v
│   ├── PC.v
│   ├── alu.v
│   ├── data_ext.v
│   ├── data_mem.v
│   ├── imm_gen.v
│   ├── instr_mem.v
│   ├── pc_adder.v
│   ├── processor_top.v
│   ├── regfile.v
│   └── shifter.v
├── testbenches/
│   ├── ALU_control_tb.v
│   ├── Branch_tb.v
│   ├── Control_unit_tb.v
│   ├── Itype_tb.v
│   ├── Jtype_tb.v
│   ├── Rtype_tb.v
│   ├── alu_tb.v
│   ├── data_mem_tb.v
│   ├── imm_gen_tb.v
│   ├── instr_mem_tb.v
│   ├── pc_tb.v
│   ├── program_tb.v
│   ├── regfile_tb.v
│   ├── dmem.txt
│   ├── imem_divide.txt
│   ├── imem_multiply.txt
│   └── imem.txt
├── constraints/
│   └── processor.xdc
├── README.md
└── LICENSE
```

## Getting Started

### Prerequisites
- Xilinx Vivado Design Suite (version 2020.2 or later)
- Make (optional, for using the provided Makefile)
- Git

### Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/muditbhargava66/RISC-V-Processor-Verilog-
cd RISC-V-Processor-Verilog-
```

### 2. Validate Environment
```bash
# Check if everything is set up correctly
make validate

# Or run comprehensive tests
make test
```

### 3. Create Vivado Project
```bash
# Create the .xpr project file
make create-project

# Or manually:
python scripts/run_vivado.py scripts/create_project_simple.tcl
```

### 4. Run Synthesis and Implementation
```bash
# Professional-grade synthesis with timing analysis
make synthesize

# Run simulation
make simulate

# Full implementation with timing closure
make implement
```

### 5. Open in Vivado GUI
```bash
# Windows
open_vivado_project.bat

# Linux/macOS
./open_vivado_project.sh

# Or manually
vivado vivado_project/riscv_processor.xpr
```

## Usage

### Synthesis and Implementation
The project includes automated scripts for easy synthesis and implementation:

```bash
# Quick syntax check
make lint

# Run synthesis only
make synthesize

# Run full implementation (includes synthesis)
make implement

# Generate detailed reports
make reports
```

### Simulation
Multiple simulation options are available:

1. **Vivado Simulator (Recommended)**
   ```bash
   make simulate
   ```

2. **Manual Simulation**
   - Open Vivado GUI
   - Set `processor_vivado_tb` as simulation top
   - Run behavioral simulation

3. **Custom Testbenches**
   - Use any testbench from `testbenches/` directory
   - Modify memory initialization files as needed

### Key Improvements for Vivado
- **Consistent Reset Logic**: All modules use active-high reset
- **Synthesis Attributes**: Proper RAM/ROM inference with block memory
- **Timing Constraints**: Comprehensive timing constraints for 100MHz operation
- **Memory Initialization**: Robust memory initialization that works in synthesis
- **Pipeline Optimization**: Improved critical path timing

## Instruction Set Support
The RISC-V processor supports the following instruction types:
- R-type: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
- I-type: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, LB, LH, LW, LBU, LHU, JALR
- S-type: SB, SH, SW
- J-type: JAL
- B-type: BEQ, BNE, BLT, BGE, BLTU, BGEU

Refer to the RISC-V ISA specification for more details on the supported instructions.

## Testbenches
The `testbenches/` directory contains various testbench files for verifying the functionality of the RISC-V processor and its individual modules. The testbenches cover different instruction types, branch handling, memory operations, and overall processor functionality.

- `ALU_control_tb.v`: Testbench for the ALU control module.
- `Branch_tb.v`: Testbench for branch instructions.
- `Control_unit_tb.v`: Testbench for the control unit module.
- `Itype_tb.v`: Testbench for I-type instructions.
- `Jtype_tb.v`: Testbench for J-type instructions.
- `Rtype_tb.v`: Testbench for R-type instructions.
- `alu_tb.v`: Testbench for the ALU module.
- `data_mem_tb.v`: Testbench for the data memory module.
- `imm_gen_tb.v`: Testbench for the immediate generator module.
- `instr_mem_tb.v`: Testbench for the instruction memory module.
- `pc_tb.v`: Testbench for the program counter module.
- `program_tb.v`: Testbench for running complete programs on the processor.
- `regfile_tb.v`: Testbench for the register file module.

## Memory Initialization
The processor's instruction memory and data memory can be initialized using the following files:

- `imem.txt`: Contains the instructions to be loaded into the instruction memory.
- `dmem.txt`: Contains the initial contents of the data memory.
- `imem_multiply.txt`: Contains instructions for testing multiplication operations.
- `imem_divide.txt`: Contains instructions for testing division operations.

These files should be placed in the `testbenches/` directory. The testbenches will read the contents of these files and initialize the respective memories before running the simulation.

## Contributing
Contributions to this RISC-V processor implementation are welcome. If you find any issues or have suggestions for improvement, please open an issue or submit a pull request.

## License
This project is licensed under the [MIT License](LICENSE).

## Planned Updates and Future Work

### SVA (SystemVerilog Assertions)
- [ ] Implement SystemVerilog Assertions (SVA) for better design verification and error checking.
- [ ] Add assertion monitors to ensure the correct behavior of various modules and the overall processor.

### Expanded Instruction Set Support
- [ ] Extend the instruction set support to include additional RISC-V instructions and features.
- [ ] Implement support for compressed instructions, vector extensions, and other advanced features.

### Cache Coherence and Memory Hierarchy
- [ ] Implement cache coherence protocols for multi-core or multi-processor systems.
- [ ] Add support for multi-level cache hierarchies and advanced memory management techniques.

### Performance Optimizations
- [ ] Explore techniques for improving the processor's performance, such as branch prediction, speculation, and out-of-order execution.
- [ ] Implement pipelining optimizations and hazard handling mechanisms.

### Verification and Testing
- [ ] Enhance the existing testbenches and create additional test cases for comprehensive verification.
- [ ] Explore the use of formal verification techniques and tools for more rigorous design verification.

### Documentation and Examples
- [ ] Improve the documentation and provide more detailed explanations of the processor's architecture and design choices.
- [ ] Include additional examples and use cases to help users better understand and utilize the processor.

Note that these planned updates and future work are subject to change based on project priorities, resource availability, and community feedback.