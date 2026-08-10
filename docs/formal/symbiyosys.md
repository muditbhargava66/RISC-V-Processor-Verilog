# SymbiYosys Setup Guide

## Installation

### Linux (Ubuntu/Debian)
```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y python3 python3-pip git make gcc g++

# Install Yosys
git clone https://github.com/YosysHQ/yosys.git
cd yosys
make -j$(nproc)
sudo make install

# Install SymbiYosys
pip3 install symbiyosys

# Install solvers
sudo apt-get install -y yices2 z3 boolector cvc4
# Or via conda:
# conda install -c conda-forge yices2 z3 boolector cvc4
```

### Windows
```powershell
# Using conda (recommended)
conda create -n sby python=3.9
conda activate sby
conda install -c conda-forge yosys symbiyosys yices2 z3 boolector cvc4

# Or using Chocolatey
choco install yosys
choco install python
pip install symbiyosys
```

### macOS
```bash
brew install yosys
brew install python
pip3 install symbiyosys
brew install yices z3 boolector cvc4
```

## Verification

```bash
# Check installation
sby --version
yosys -V
```

## Configuration Files

The project includes four SymbiYosys configurations:

| File | Mode | Purpose |
|------|------|---------|
| `formal.sby` | prove | Full proof (BMC + PDR + ABC) |
| `formal_bmc.sby` | bmc | Bounded model checking |
| `formal_cover.sby` | cover | Coverage collection |
| `formal_core.sby` | prove | Core-only prove |

## Running Formal Verification

### Full Proof
```bash
cd verification
sby -f formal.sby
```

### Bounded Model Checking
```bash
sby -f formal_bmc.sby
```

### Coverage Collection
```bash
sby -f formal_cover.sby
```

### Core Only
```bash
sby -f formal_core.sby
```

## Configuration Details

### formal.sby (Full Proof)
```ini
[options]
mode prove
depth 50
wait on

[engines]
smtbmc
abc pdr
aigbmc

[script]
read_verilog -I ../src ../src/riscv_pkg.sv
read_verilog -I ../src ../src/alu.sv
read_verilog -I ../src ../src/immediate_generator.sv
read_verilog -I ../src ../src/program_counter.sv
read_verilog -I ../src ../src/register_file.sv
read_verilog -I ../src ../src/instruction_memory.sv
read_verilog -I ../src ../src/data_memory.sv
read_verilog -I ../src ../src/control_unit.sv
read_verilog -I ../src ../src/riscv_processor.sv
read_verilog -I ../verification ../verification/riscv_processor_sva.sv

prep -top riscv_processor_sva

[files]
../src/riscv_pkg.sv
../src/alu.sv
../src/immediate_generator.sv
../src/program_counter.sv
../src/register_file.sv
../src/instruction_memory.sv
../src/data_memory.sv
../src/control_unit.sv
../src/riscv_processor.sv
../verification/riscv_processor_sva.sv
```

## Running Results

### Successful Proof
```
SBY 12:34:56 [formal] engine_0: ##   0:00:00  Starting engine_0 (smtbmc)
SBY 12:34:56 [formal] engine_1: ##   0:00:00  Starting engine_1 (abc pdr)
SBY 12:34:56 [formal] engine_2: ##   0:00:00  Starting engine_2 (aigbmc)
SBY 12:35:12 [formal] engine_0: ##   0:00:16  Solved (proved)
SBY 12:35:12 [formal] engine_1: ##   0:00:16  Solved (proved)
SBY 12:35:12 [formal] engine_2: ##   0:00:16  Solved (proved)
SBY 12:35:12 [formal] Status: PASSED
```

### Failed Property
```
SBY 12:34:56 [formal] engine_0: ##   0:00:05  Counterexample found
SBY 12:34:56 [formal] engine_0: ##   0:00:05  Assertion failed: reg_x0_always_zero
SBY 12:35:12 [formal] Status: FAILED
```

## SVA Properties Verified

The `riscv_processor.sva` module contains 15 assertions and 12 cover properties:

### Assertions (15)
1. PC word-aligned
2. PC sequential advancement
3. x0 = 0 on read port 1
4. x0 = 0 on read port 2
5. Register write only for valid opcodes
6. Memory read only for loads
7. Memory write only for stores
8. Branch taken only for control flow
9. Valid opcode check
10. R-type format validation
11. I-type immediate generation
12. ADD ALU correctness
13. SUB ALU correctness
14. ADDI ALU correctness
15. No X/Z in PC/instruction

### Cover Properties (12)
- All 9 opcode types
- Branch taken/not taken
- Register writes to x1-x31
- Memory read/write

## Interpreting Results

### PASS
- All assertions proven
- All cover points hit (in cover mode)
- No counterexamples found

### FAIL
- Counterexample generated
- View waveform: `gtkwave engine_0/trace.vcd`
- Check assertion that failed
- Fix RTL or adjust property

### UNKNOWN
- Timeout
- Increase depth or timeout
- Simplify property

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Solver timeout | Increase timeout, reduce depth |
| Memory exhaustion | Use simpler engine, reduce design |
| Unsatisfiable assumptions | Check assumptions in SVA |
| Engine crash | Update Yosys/SymbiYosys |
| Missing files | Check file paths in .sby |

## Advanced Usage

### Custom Depth
```bash
sby -f formal.sby --depth 100
```

### Specific Engine
```bash
sby -f formal.sby --engine smtbmc
```

### Parallel Jobs
```bash
sby -f formal.sby -j 4
```

### Generate VCD for Debug
```bash
# In .sby file:
[options]
vcd on
```

### Incremental Verification
```bash
sby -f formal.sby --incremental
```

## Related Documents
- [SVA Properties](sva-properties.md)
- [Proof Strategies](proof-strategies.md)
- [Coverage Collection](coverage.md)
- [Verification Guide](../verification/verification-guide.md)