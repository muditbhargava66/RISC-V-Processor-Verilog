# Architecture Overview

## High-Level Block Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                      RISC-V Processor Core                          │
│                                                                     │
│  ┌──────────────┐                                                   │
│  │ Program      │                                                   │
│  │ Counter (PC) │                                                   │
│  └──────┬───────┘                                                   │
│         │                                                           │
│         ▼                                                           │
│  ┌──────────────────────┐                                           │
│  │ Instruction Memory   │                                           │
│  │ (I-MEM)              │                                           │
│  └──────────┬───────────┘                                           │
│             │                                                       │
│             ▼                                                       │
│  ┌────────────────────────┐                                         │
│  │ Instruction Register   │                                         │
│  └──────────┬─────────────┘                                         │
│             │                                                       │
│             ▼                                                       │
│  ┌────────────────────────┐    ┌────────────────────────┐           │
│  │ Control Unit           │    │ Immediate Generator    │           │
│  │ (Decode + Control)     │    │                        │           │
│  └──────────┬─────────────┘    └───────────┬────────────┘           │
│             │                               │                       │
│     ┌───────┼───────┬───────┬───────┬───────┼───────┬───────┐       │
│     ▼       ▼       ▼       ▼       ▼       ▼       ▼       ▼       │
│  reg_wr  mem_rd  mem_wr  branch  jump   alu_s1  alu_src alu_op      │
│  wr_src                                                             │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                        Datapath                              │   │
│  │                                                              │   │
│  │  ┌─────────────────┐     ┌───────────────────────────────┐   │   │
│  │  │ Register File   │     │ ALU Operand Selection         │   │   │
│  │  │ (32×32-bit)     │     │                               │   │   │
│  │  │ x0=0 hardwired  │     │  alu_operand1 = alu_src1 ?    │   │   │
│  │  └────────┬────────┘     │       pc_current : read_data1 │   │   │
│  │           │              │                               │   │   │
│  │     ┌─────┴─────┐        │  alu_operand2 = case(alu_src) │   │   │
│  │     ▼           ▼        │   ALU_SRC_REG: read_data2     │   │   │
│  │  read_data1  read_data2  │   ALU_SRC_IMM: immediate      │   │   │
│  │                    │     │   ALU_SRC_PC: pc_current      │   │   │
│  │                    ▼     │   default: 0                  │   │   │
│  │              ┌──────────┐  │                             │   │   │
│  │              │   ALU    │  │                             │   │   │
│  │              │          │  │                             │   │   │
│  │              │ operand_a◄──┼─────────────────────────────┘   │   │
│  │              │ operand_b◄┼───────────────────────────────────┘   │
│  │              │          │  │                                 │   │
│  │              │ alu_op   │  │                                 │   │
│  │              │          │  │                                 │   │
│  │              │  result ◄┼────────────────────────────────────┘   │
│  │              │   zero   │  │                                 │   │
│  │              └────┬─────┘  │                                 │   │
│  │                   │        │                                 │   │
│  │                   ▼        ▼                                 │   │
│  │            ┌────────────────┐                                │   │
│  │            │ Data Memory    │                                │   │
│  │            │ (D-MEM)        │                                │   │
│  │            └────────┬───────┘                                │   │
│  │                     │                                        │   │
│  │                     ▼                                        │   │
│  │            ┌─────────────────┐                               │   │
│  │            │ Writeback Mux   │                               │   │
│  │            │                 │                               │   │
│  │            │ case(reg_wr_s)  │                               │   │
│  │            │  ALU: alu_result│                               │   │
│  │            │  MEM: mem_data  │                               │   │
│  │            │  PC+4: pc_plus_4│                               │   │
│  │            │  IMM: immediate │                               │   │
│  │            └────────┬────────┘                               │   │
│  │                     │                                        │   │
│  │                     ▼                                        │   │
│  │              ┌─────────────┐                                 │   │
│  │              │ Register    │                                 │   │
│  │              │ File Write  │                                 │   │
│  │              └─────────────┘                                 │   │
│  │                                                              │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    PC Next Generation                        │   │
│  │                                                              │   │
│  │  pc_plus_4 = pc_current + 4                                  │   │
│  │                                                              │   │
│  │  branch_taken = branch & (beq_cond | bne_cond | blt_cond |   │   │
│  │                     bge_cond | bltu_cond | bgeu_cond)        │   │
│  │                                                              │   │
│  │  jump_target = (opcode==JAL)  ? pc_current + immediate       │   │
│  │                : {alu_result[31:1], 1'b0}  // JALR           │   │
│  │                                                              │   │
│  │  pc_next = jump ? jump_target :                              │   │
│  │            branch_taken ? pc_current + immediate :           │   │
│  │            pc_plus_4                                         │   │
│  │                                                              │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Architectural Decisions

### Single-Cycle Implementation
- **One instruction per cycle** (ideal IPC = 1.0)
- **No pipeline hazards** - simpler control logic
- **Longer clock period** limited by critical path
- **Target**: 50 MHz on Artix-7 (20ns period)

### Harvard Architecture
- **Separate I-MEM and D-MEM** - simultaneous access
- **I-MEM**: Read-only, initialized from hex file
- **D-MEM**: Read/write with byte/halfword/word granularity
- **Address width**: 8 bits (256 words = 1KB each) by default

### Register File
- **32 registers × 32 bits** (x0-x31)
- **x0 hardwired to zero** - reads return 0, writes ignored
- **Synchronous reset** - FPGA-friendly
- **Two read ports, one write port**

### ALU Operations

| Category | Operations |
|----------|------------|
| Arithmetic | ADD, SUB |
| Logical | AND, OR, XOR |
| Shift | SLL, SRL, SRA |
| Comparison | SLT, SLTU |
| M-Extension | MUL, MULH, DIV, REM |

### Branch/Jump Handling
- **Branches**: ALU-based comparison (SUB/SLT/SLTU)
- **JAL**: PC + immediate → PC, PC+4 → rd
- **JALR**: (rs1 + immediate) & ~1 → PC, PC+4 → rd
- **PC Mux**: Sequential (+4), Branch, Jump

## Instruction Memory (I-MEM)

- **Parameterized depth** via `ADDR_WIDTH` (default 8 = 256 words)
- **Initialization**: `$readmemh` from `instruction_memory.hex`
- **Word-aligned access**: `address[ADDR_WIDTH+1:2]`
- **Read-only** during simulation/synthesis

## Data Memory (D-MEM)

| Access Type | funct3 | Operation |
|-------------|--------|-----------|
| LB | 000 | Load byte (sign-extended) |
| LH | 001 | Load halfword (sign-extended) |
| LW | 010 | Load word |
| LBU | 100 | Load byte (zero-extended) |
| LHU | 101 | Load halfword (zero-extended) |
| SB | 000 | Store byte |
| SH | 001 | Store halfword |
| SW | 010 | Store word |

- **Alignment checking** with error reporting
- **Parameterized depth** via `ADDR_WIDTH`
- **Synchronous write, asynchronous read**

## Control Unit

### Decode Structure
- **Opcode-based** primary decode
- **funct3/funct7** secondary decode for R/I-type
- **Combinational logic** (`always_comb`)

### Control Signals

| Signal | Width | Description |
|--------|-------|-------------|
| `reg_write` | 1 | Register write enable |
| `mem_read` | 1 | Data memory read enable |
| `mem_write` | 1 | Data memory write enable |
| `branch` | 1 | Branch instruction |
| `jump` | 1 | JAL/JALR instruction |
| `alu_src1` | 1 | Operand A: 0=rs1, 1=PC (for AUIPC) |
| `alu_src` | 2 | Operand B: 00=rs2, 01=imm, 10=PC, 11=zero |
| `alu_op` | 4 | ALU operation select |
| `reg_write_src` | 2 | Writeback: 00=ALU, 01=MEM, 10=PC+4, 11=IMM |

### Opcode Decode Map

| Opcode | Name | reg_wr | mem_rd | mem_wr | branch | jump | alu_src | reg_wr_src |
|--------|------|--------|--------|--------|--------|------|---------|------------|
| 0110011 | R-type | 1 | 0 | 0 | 0 | 0 | REG | ALU |
| 0010011 | I-type | 1 | 0 | 0 | 0 | 0 | IMM | ALU |
| 0000011 | Load | 1 | 1 | 0 | 0 | 0 | IMM | MEM |
| 0100011 | Store | 0 | 0 | 1 | 0 | 0 | IMM | ALU |
| 1100011 | Branch | 0 | 0 | 0 | 1 | 0 | REG | ALU |
| 1101111 | JAL | 1 | 0 | 0 | 0 | 1 | REG | PC+4 |
| 1100111 | JALR | 1 | 0 | 0 | 0 | 1 | IMM | PC+4 |
| 0110111 | LUI | 1 | 0 | 0 | 0 | 0 | REG | IMM |
| 0010111 | AUIPC | 1 | 0 | 0 | 0 | 0 | IMM | ALU |

### M-Extension Decode (ENABLE_M=1)

| funct7 | funct3 | Instruction | alu_op |
|--------|--------|-------------|--------|
| 0000001 | 000 | MUL | ALU_MUL |
| 0000001 | 001 | MULH | ALU_MULH |
| 0000001 | 100 | DIV | ALU_DIV |
| 0000001 | 110 | REM | ALU_REM |

### Shift Amount Encoding (I-type)

| funct3 | funct7[5] | Instruction | ALU Op |
|--------|-----------|-------------|--------|
| 001 | 0 | SLLI | ALU_SLL |
| 101 | 0 | SRLI | ALU_SRL |
| 101 | 1 | SRAI | ALU_SRA |

### Branch ALU Operations

| funct3 | Instruction | ALU Op | Condition |
|--------|-------------|--------|-----------|
| 000 | BEQ | SUB | zero == 1 |
| 001 | BNE | SUB | zero == 0 |
| 100 | BLT | SLT | result[0] == 1 (signed <) |
| 101 | BGE | SLT | result[0] == 0 (signed >=) |
| 110 | BLTU | SLTU | result[0] == 1 (unsigned <) |
| 111 | BGEU | SLTU | result[0] == 0 (unsigned >=) |

## Extensions

### M-Extension (ENABLE_M=1)
- **MUL**: 32×32 → 32-bit (low)
- **MULH**: 32×32 → 32-bit (high, signed)
- **DIV**: Signed division
- **REM**: Signed remainder
- **DSP Usage**: 2 DSP48E1 blocks on Artix-7

### C-Extension (ENABLE_C=0, Future)
- 16-bit compressed instructions
- Requires instruction fetch modification

## Debug Interface

### Core Debug Ports (riscv_processor)

| Signal | Width | Description |
|--------|-------|-------------|
| `pc_debug` | 32 | Current PC |
| `instruction_debug` | 32 | Current instruction |
| `alu_result_debug` | 32 | ALU result |
| `reg_debug_data1` | 32 | Register read port 1 |
| `reg_debug_data2` | 32 | Register read port 2 |
| `mem_debug_data` | 32 | Data memory read |
| `reg_debug_addr1` | 5 | Read register 1 |
| `reg_debug_addr2` | 5 | Read register 2 |
| `immediate_debug` | 32 | Generated immediate |
| `reg_write_debug` | 1 | Reg write enable |
| `mem_read_debug` | 1 | Mem read enable |
| `mem_write_debug` | 1 | Mem write enable |
| `branch_taken_debug` | 1 | Branch taken |

### JTAG Debug Wrapper (riscv_processor_jtag_debug)

- **Explicit ILA**: 13 probes × 32-bit, configurable depth (default 1024)
  - Probe 0: Program Counter
  - Probe 1: Current Instruction
  - Probe 2: ALU Result
  - Probe 3: Register Read Data 1
  - Probe 4: Register Read Data 2
  - Probe 5: Memory Read Data
  - Probe 6: Register Read Address 1
  - Probe 7: Register Read Address 2
  - Probe 8: Generated Immediate
  - Probe 9: Register Write Enable
  - Probe 10: Memory Read Enable
  - Probe 11: Memory Write Enable
  - Probe 12: Branch Taken Status

- **Explicit VIO**: 3 probe_in × 32-bit, 2 probe_out × 32-bit
  - `probe_in0`: PC Status
  - `probe_in1`: Instruction Status
  - `probe_in2`: Control Status Register (opcode + flags)
  - `probe_out0`: Control Register (reserved for runtime control)
  - `probe_out1`: Config Register (reserved)

- **External I/O**: 12 pins (clk, reset, 8 status LEDs, processor_active, error_flag)

## Parameterization

| Parameter | Default | Description |
|-----------|---------|-------------|
| `XLEN` | 32 | Register width (32/64) |
| `ENABLE_M` | 1 | Enable M-extension |
| `ENABLE_C` | 0 | Enable C-extension |
| `IMEM_ADDR_WIDTH` | 8 | I-MEM address bits |
| `DMEM_ADDR_WIDTH` | 8 | D-MEM address bits |
| `ILA_DEPTH` | 1024 | ILA capture depth |

## Timing Characteristics

| Metric | Value | Notes |
|--------|-------|-------|
| Target Frequency | 50 MHz | Artix-7 -1 speed grade |
| Critical Path | ~9.5 ns | ALU → D-MEM → Writeback |
| Setup Slack | > 1 ns | With 20ns period |
| Hold Slack | > 0 ns | Met |
| Pipeline Stages | 1 | Single-cycle |

## Resource Utilization (Estimated)

| Resource | Minimal | JTAG Debug | Available (XC7A35T) |
|----------|---------|------------|---------------------|
| LUTs | ~4,100 | ~4,200 | 20,800 |
| FFs | ~8,400 | ~8,500 | 41,600 |
| DSPs | 2 | 2 | 90 |
| BRAM | 0 | 0 | 50 |
| I/O | 12 | 12 | 88 |

## Design Variants

| Variant | Module | I/O Pins | Use Case |
|---------|--------|----------|----------|
| Core | `riscv_processor` | 238 | Simulation, synthesis check |
| Minimal | `riscv_processor_minimal` | 12 | Production deployment |
| JTAG Debug | `riscv_processor_jtag_debug` | 12 | Hardware debug |

## Related Documents
- [Module Reference](../modules/core-processor.md)
- [Instruction Set Support](isa-support.md)
- [Pipeline Design](pipeline.md)
- [Memory Architecture](memory.md)
- [Extension Support](extensions.md)