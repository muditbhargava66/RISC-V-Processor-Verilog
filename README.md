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
- Xilinx Vivado Design Suite (version 2022.2 or later)
- Verilog simulator (e.g., Xilinx Vivado Simulator)

### Installation
1. Clone the repository:
   ```
   git clone https://github.com/muditbhargava66/RISC-V-Processor-Verilog-
   ```
2. Open Xilinx Vivado and create a new project.
3. Add the Verilog files from the `src/` directory to the project.
4. Add the constraint file (`processor.xdc`) from the `constraints/` directory to the project.

## Usage

### Simulation
1. Open the Xilinx Vivado Simulator.
2. Add the desired testbench file from the `testbenches/` directory to the simulation.
3. Set the testbench file as the top module.
4. Run the simulation and observe the results.

### Synthesis
1. In Xilinx Vivado, select the `processor_top.v` file as the top module.
2. Run the synthesis process.
3. Review the synthesis report and address any issues or warnings.
4. Generate the bitstream for the target FPGA device.

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