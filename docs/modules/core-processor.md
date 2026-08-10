# Core Processor Module Reference

## Module: `riscv_processor`

**File**: `src/riscv_processor.sv`  
**Lines**: ~330  
**Parameters**: `XLEN=32`, `ENABLE_M=1`, `ENABLE_C=0`

### Port Interface

```systemverilog
module riscv_processor #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1,
    parameter bit ENABLE_C = 1'b0
)(
    input  logic        clk,
    input  logic        reset,
    // Debug outputs
    output logic [XLEN-1:0] pc_debug,
    output logic [XLEN-1:0] instruction_debug,
    output logic [XLEN-1:0] alu_result_debug,
    output logic [XLEN-1:0] reg_debug_data1,
    output logic [XLEN-1:0] reg_debug_data2,
    output logic [XLEN-1:0] mem_debug_data,
    output logic [4:0]      reg_debug_addr1,
    output logic [4:0]      reg_debug_addr2,
    output logic [XLEN-1:0] immediate_debug,
    output logic            reg_write_debug,
    output logic            mem_read_debug,
    output logic            mem_write_debug,
    output logic            branch_taken_debug
);
```

### Internal Architecture

```
PC → I-MEM → Instruction → Immediate Gen
                    ↓
              Control Unit → Control Signals
                    ↓
         ┌────────────┼────────────┐
         ▼            ▼            ▼
    Register File   ALU         D-MEM
         │            │            │
         └────────────┼────────────┘
                      ▼
              Writeback Mux
                      │
              Register File (write)
```

### Key Internal Signals

| Signal | Width | Description |
|--------|-------|-------------|
| `pc_current` | XLEN | Current program counter |
| `pc_next` | XLEN | Next program counter |
| `pc_plus_4` | XLEN | PC + 4 |
| `instruction` | 32 | Current instruction |
| `immediate` | XLEN | Sign-extended immediate |
| `read_data1/2` | XLEN | Register file outputs |
| `alu_operand1/2` | XLEN | ALU inputs |
| `alu_result` | XLEN | ALU output |
| `alu_zero` | 1 | Zero flag (for branches) |
| `mem_read_data` | XLEN | Data memory output |
| `reg_write_data` | XLEN | Writeback data |

### PC Next Logic

```systemverilog
// Branch conditions
beq_cond  = (funct3 == 3'b000) & alu_zero;
bne_cond  = (funct3 == 3'b001) & ~alu_zero;
blt_cond  = (funct3 == 3'b100) & alu_result[0];
bge_cond  = (funct3 == 3'b101) & ~alu_result[0];
bltu_cond = (funct3 == 3'b110) & alu_result[0];
bgeu_cond = (funct3 == 3'b111) & ~alu_result[0];

branch_taken = branch & (beq_cond | bne_cond | blt_cond | bge_cond | bltu_cond | bgeu_cond);

// Jump target
jump_target = (opcode == JAL) ? (pc_current + immediate) :
              {alu_result[XLEN-1:1], 1'b0};  // JALR: clear LSB

pc_next = jump ? jump_target :
          branch_taken ? (pc_current + immediate) :
                         pc_plus_4;
```

### ALU Operand Selection

```systemverilog
alu_operand1 = alu_src1 ? pc_current : read_data1;

unique case (alu_src)
    2'b00: alu_operand2 = read_data2;   // Register
    2'b01: alu_operand2 = immediate;    // Immediate
    2'b10: alu_operand2 = pc_current;   // PC (for AUIPC)
    default: alu_operand2 = '0;
endcase
```

### Writeback Selection

```systemverilog
unique case (reg_write_src)
    2'b00: reg_write_data = alu_result;      // ALU result
    2'b01: reg_write_data = mem_read_data;   // Memory data
    2'b10: reg_write_data = pc_plus_4;       // PC+4 (JAL/JALR)
    2'b11: reg_write_data = immediate;       // Immediate (LUI)
    default: reg_write_data = '0;
endcase
```

### Inline SVA Assertions

The module includes 15 assertions and 12 cover properties:

```systemverilog
// PC word-aligned
assert property (@(posedge clk) disable iff (reset) (pc_current[1:0] == 2'b00));

// x0 always zero
assert property (@(posedge clk) disable iff (reset) (rs1 == 5'b0) |-> (read_data1 == '0));

// Valid register writes
assert property (@(posedge clk) disable iff (reset) reg_write |-> writes_register(opcode));

// Valid memory accesses
assert property (@(posedge clk) disable iff (reset) mem_read |-> (opcode == LOAD));
assert property (@(posedge clk) disable iff (reset) mem_write |-> (opcode == STORE));

// Branch only on branch/jump
assert property (@(posedge clk) disable iff (reset) branch_taken |-> is_control_flow(opcode));

// ALU correctness for ADD/SUB/ADDI
assert property (@(posedge clk) disable iff (reset)
    (opcode == R_TYPE && funct3 == ADD_SUB && funct7 == BASE) |->
    (alu_result == (read_data1 + read_data2)));
// ... similar for SUB, ADDI
```

## Module: `riscv_processor_minimal`

**File**: `src/riscv_processor_minimal.sv`  
**Purpose**: Production wrapper for Basys3 (12 I/O pins)

```systemverilog
module riscv_processor_minimal #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1,
    parameter bit ENABLE_C = 1'b0
)(
    input  logic        clk,
    input  logic        reset,
    output logic [15:0] pc_debug   // PC[15:0] to LEDs
);
```

### Pin Mapping (Basys3 XDC)
| Signal | Pin | Description |
|--------|-----|-------------|
| `clk` | W5 | 100 MHz clock |
| `reset` | U18 | Reset button |
| `pc_debug[0]` | U16 | LED 0 |
| `pc_debug[1]` | E19 | LED 1 |
| ... | ... | ... |
| `pc_debug[15]` | L1 | LED 15 |

### Timing Constraints
- **Clock**: 50 MHz (20ns period)
- **False paths**: Debug outputs excluded from timing
- **I/O delays**: Input/output delay constraints on reset/LEDs

## Module: `riscv_processor_jtag_debug`

**File**: `src/riscv_processor_jtag_debug.sv`  
**Purpose**: Hardware debug with explicit ILA/VIO

```systemverilog
module riscv_processor_jtag_debug #(
    parameter int XLEN = 32,
    parameter bit ENABLE_M = 1'b1,
    parameter bit ENABLE_C = 1'b0,
    parameter int ILA_DEPTH = 1024
)(
    input  logic        clk,
    input  logic        reset,
    output logic [7:0]  status_leds,
    output logic        processor_active,
    output logic        error_flag
);
```

### Explicit ILA Instantiation
```systemverilog
ila_riscv_processor #(
    .C_DATA_DEPTH (ILA_DEPTH)
) u_ila (
    .clk     (clk),
    .probe0  (pc_debug),             // Program Counter
    .probe1  (instruction_debug),    // Current Instruction
    .probe2  (alu_result_debug),     // ALU Result
    .probe3  (reg_debug_data1),      // Reg Read Data 1
    .probe4  (reg_debug_data2),      // Reg Read Data 2
    .probe5  (mem_debug_data),       // Memory Read Data
    .probe6  ({27'd0, reg_debug_addr1}), // Reg Addr 1
    .probe7  ({27'd0, reg_debug_addr2}), // Reg Addr 2
    .probe8  (immediate_debug),      // Immediate
    .probe9  ({31'd0, reg_write_debug}), // Reg Write
    .probe10 ({31'd0, mem_read_debug}),  // Mem Read
    .probe11 ({31'd0, mem_write_debug}), // Mem Write
    .probe12 ({31'd0, branch_taken_debug}) // Branch Taken
);
```

### Explicit VIO Instantiation
```systemverilog
vio_riscv_processor u_vio (
    .clk           (clk),
    .probe_in0     (pc_debug),           // PC Status
    .probe_in1     (instruction_debug),  // Instruction Status
    .probe_in2     ({24'd0, instruction_debug[6:0], branch_taken_debug, 
                     mem_write_debug, mem_read_debug, reg_write_debug,
                     jump_op, branch_op, processor_active, error_flag}),
    .probe_out0    (),  // Control Register (reserved)
    .probe_out1    ()   // Config Register (reserved)
);
```

### Status Outputs
| Signal | Source | Description |
|--------|--------|-------------|
| `status_leds[7:0]` | `pc_debug[7:0]` | PC lower 8 bits |
| `processor_active` | `\|instruction_debug` | Non-zero instruction |
| `error_flag` | `processor_active && !valid_opcode` | Illegal opcode |

## Module: `alu`

**File**: `src/alu.sv`  
**Parameters**: `XLEN=32`, `ENABLE_M=1`

### Operations
| ALU_OP | Operation | Description |
|--------|-----------|-------------|
| 4'b0000 | ADD | A + B |
| 4'b1000 | SUB | A - B |
| 4'b0111 | AND | A & B |
| 4'b0110 | OR | A \| B |
| 4'b0100 | XOR | A ^ B |
| 4'b0001 | SLL | A << B[4:0] |
| 4'b0101 | SRL | A >> B[4:0] |
| 4'b1101 | SRA | \$signed(A) >>> B[4:0] |
| 4'b0010 | SLT | (\$signed(A) < \$signed(B)) ? 1 : 0 |
| 4'b0011 | SLTU | (A < B) ? 1 : 0 |
| 4'b1110 | MUL | \$signed(A) * \$signed(B) [31:0] |
| 4'b1111 | MULH | \$signed(A) * \$signed(B) [63:32] |
| 4'b1010 | DIV | \$signed(A) / \$signed(B) |
| 4'b1011 | REM | \$signed(A) % \$signed(B) |

### Zero Flag
```systemverilog
assign zero = (result == '0);
```

### DSP Usage (M-Extension)
- **MUL/MULH**: 2 DSP48E1 blocks
- **DIV/REM**: Iterative (uses LUTs)

## Module: `control_unit`

**File**: `src/control_unit.sv`  
**Parameters**: `ENABLE_M=1`, `ENABLE_C=0`

### Decode Logic
```systemverilog
always_comb begin
    // Defaults
    reg_write = 0; mem_read = 0; mem_write = 0;
    branch = 0; jump = 0; alu_src1 = 0;
    alu_src = ALU_SRC_REG; alu_op = ALU_ADD;
    reg_write_src = WRITE_SRC_ALU;

    unique case (opcode)
        R_TYPE: begin
            reg_write = 1; alu_src = ALU_SRC_REG;
            unique case ({funct7, funct3})
                {BASE, ADD_SUB}: alu_op = ALU_ADD;    // ADD
                {SUB_SRA, ADD_SUB}: alu_op = ALU_SUB; // SUB
                // ... all R-type ops
            endcase
        end
        I_TYPE: begin
            reg_write = 1; alu_src = ALU_SRC_IMM;
            unique case (funct3)
                ADD_SUB: alu_op = ALU_ADD;   // ADDI
                SLT:     alu_op = ALU_SLT;   // SLTI
                // ... all I-type ops
            endcase
        end
        LOAD: begin
            reg_write = 1; mem_read = 1; alu_src = ALU_SRC_IMM;
            reg_write_src = WRITE_SRC_MEM;
        end
        STORE: begin
            mem_write = 1; alu_src = ALU_SRC_IMM;
        end
        BRANCH: begin
            branch = 1; alu_src = ALU_SRC_REG;
            unique case (funct3)
                BEQ/BNE: alu_op = ALU_SUB;
                BLT/BGE: alu_op = ALU_SLT;
                BLTU/BGEU: alu_op = ALU_SLTU;
            endcase
        end
        JAL: begin
            reg_write = 1; jump = 1;
            reg_write_src = WRITE_SRC_PC_PLUS_4;
        end
        JALR: begin
            reg_write = 1; jump = 1; alu_src = ALU_SRC_IMM;
            reg_write_src = WRITE_SRC_PC_PLUS_4;
        end
        LUI: begin
            reg_write = 1; reg_write_src = WRITE_SRC_IMM;
        end
        AUIPC: begin
            reg_write = 1; alu_src1 = 1; alu_src = ALU_SRC_IMM;
        end
    endcase
end
```

## Module: `register_file`

**File**: `src/register_file.sv`  
**Parameters**: `XLEN=32`, `REG_ADDR_WIDTH=5`, `NUM_REGS=32`

### Features
- **x0 hardwired to zero** - reads return 0, writes ignored
- **Synchronous write, asynchronous read**
- **Synchronous reset** (2 cycles for full clear)

```systemverilog
logic [XLEN-1:0] registers [1:NUM_REGS-1];  // x0 not stored

always_ff @(posedge clk) begin
    if (reset) begin
        for (int i = 1; i < NUM_REGS; i++)
            registers[i] <= '0;
    end else if (reg_write && write_reg != '0) begin
        registers[write_reg] <= write_data;
    end
end

assign read_data1 = (read_reg1 == '0) ? '0 : registers[read_reg1];
assign read_data2 = (read_reg2 == '0) ? '0 : registers[read_reg2];
```

## Module: `program_counter`

**File**: `src/program_counter.sv`  
**Parameters**: `XLEN=32`

```systemverilog
always_ff @(posedge clk) begin
    if (reset)
        pc_current <= '0;
    else
        pc_current <= pc_next;
end
```

## Module: `immediate_generator`

**File**: `src/immediate_generator.sv`  
**Parameters**: `XLEN=32`

```systemverilog
always_comb begin
    unique case (opcode)
        I_TYPE, LOAD, JALR:  // I-type
            immediate = {{(XLEN-12){instruction[31]}}, instruction[31:20]};
        STORE:  // S-type
            immediate = {{(XLEN-12){instruction[31]}}, instruction[31:25], instruction[11:7]};
        BRANCH:  // B-type
            immediate = {{(XLEN-13){instruction[31]}}, instruction[31], instruction[7],
                         instruction[30:25], instruction[11:8], 1'b0};
        LUI, AUIPC:  // U-type
            immediate = {instruction[31:12], {(XLEN-32){1'b0}}, 12'b0};
        JAL:  // J-type
            immediate = {{(XLEN-21){instruction[31]}}, instruction[31], instruction[19:12],
                         instruction[20], instruction[30:21], 1'b0};
        default:
            immediate = '0;
    endcase
end
```

## Module: `instruction_memory`

**File**: `src/instruction_memory.sv`  
**Parameters**: `ADDR_WIDTH=8`, `INIT_FILE="instruction_memory.hex"`

```systemverilog
localparam int MEM_DEPTH = 2**ADDR_WIDTH;
logic [31:0] memory [0:MEM_DEPTH-1];
logic [ADDR_WIDTH-1:0] word_address = address[ADDR_WIDTH+1:2];

initial begin
    for (int i = 0; i < MEM_DEPTH; i++)
        memory[i] = '0;
    $readmemh(INIT_FILE, memory);
end

assign instruction = memory[word_address];
```

## Module: `data_memory`

**File**: `src/data_memory.sv`  
**Parameters**: `ADDR_WIDTH=8`, `XLEN=32`

See [Memory Architecture](../architecture/memory.md) for detailed documentation.

---

## Quick Reference Tables

### Core Module Parameters
| Module | Key Parameters |
|--------|----------------|
| `riscv_processor` | `XLEN=32`, `ENABLE_M=1`, `ENABLE_C=0` |
| `alu` | `XLEN=32`, `ENABLE_M=1` |
| `control_unit` | `ENABLE_M=1`, `ENABLE_C=0` |
| `register_file` | `XLEN=32`, `REG_ADDR_WIDTH=5`, `NUM_REGS=32` |
| `program_counter` | `XLEN=32` |
| `immediate_generator` | `XLEN=32` |
| `instruction_memory` | `ADDR_WIDTH=8`, `INIT_FILE` |
| `data_memory` | `ADDR_WIDTH=8`, `XLEN=32` |

### Debug Signal Summary
| Signal | Width | Source |
|--------|-------|--------|
| `pc_debug` | 32 | PC register |
| `instruction_debug` | 32 | I-MEM output |
| `alu_result_debug` | 32 | ALU output |
| `reg_debug_data1/2` | 32 | Register file |
| `mem_debug_data` | 32 | D-MEM output |
| `reg_debug_addr1/2` | 5 | Instruction fields |
| `immediate_debug` | 32 | ImmGen output |
| `reg_write_debug` | 1 | Control unit |
| `mem_read_debug` | 1 | Control unit |
| `mem_write_debug` | 1 | Control unit |
| `branch_taken_debug` | 1 | Branch logic |

### Related Documents
- [Architecture Overview](../architecture/overview.md)
- [ISA Support](isa-support.md)
- [Memory Architecture](memory.md)
- [Control Unit Details](../modules/control-unit.md)
- [ALU Details](../modules/alu.md)