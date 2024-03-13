# RISC-V Processor Implementation in Verilog

This repository contains a Verilog implementation of a RISC-V processor. The processor supports a subset of the RISC-V instruction set architecture (ISA) and is designed to be synthesized and simulated using Xilinx Vivado.

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
- [Contributing](#contributing)
- [License](#license)

## Features
- Implements a subset of the RISC-V ISA
- Supports R-type, I-type, S-type, J-type, and B-type instructions
- Includes a 5-stage pipeline architecture
- Utilizes a register file, instruction memory, and data memory
- Provides testbenches for verification and testing

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
│   ├── Branch_tb.v
│   ├── Itype_tb.v
│   ├── Jtype_tb.v
│   ├── Rtype_tb.v
│   ├── program_tb.v
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
The RISC-V processor implementation supports the following instruction types:
- R-type: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
- I-type: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, LB, LH, LW, LBU, LHU, JALR
- S-type: SB, SH, SW
- J-type: JAL
- B-type: BEQ, BNE, BLT, BGE, BLTU, BGEU

Refer to the RISC-V ISA specification for more details on the supported instructions.

## Testbenches
The `testbenches/` directory contains various testbench files for verifying the functionality of the RISC-V processor:
- `Branch_tb.v`: Testbench for testing branch instructions.
- `Itype_tb.v`: Testbench for testing I-type instructions.
- `Jtype_tb.v`: Testbench for testing J-type instructions.
- `Rtype_tb.v`: Testbench for testing R-type instructions.
- `program_tb.v`: Testbench for running a complete program on the processor.

The testbenches use the instruction memory files (`imem_divide.txt`, `imem_multiply.txt`, `imem.txt`) to load instructions into the processor's instruction memory.

## Contributing
Contributions to this RISC-V processor implementation are welcome. If you find any issues or have suggestions for improvement, please open an issue or submit a pull request.

## License
This project is licensed under the [MIT License](LICENSE).