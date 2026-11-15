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

### formal.sby (Full Proof) — actual config
```ini
[options]
mode prove
depth 50
wait off

[engines]
smtbmc
abc pdr

[script]
read_slang --top riscv_processor_sva -D IVERILOG riscv_pkg.sv alu.sv immediate_generator.sv program_counter.sv register_file.sv instruction_memory.sv data_memory.sv control_unit.sv divider.sv riscv_processor.sv riscv_processor_sva.sv
prep -top riscv_processor_sva -flatten

[files]
../src/riscv_pkg.sv
../src/alu.sv
../src/immediate_generator.sv
../src/program_counter.sv
../src/register_file.sv
../src/instruction_memory.sv
../src/data_memory.sv
../src/control_unit.sv
../src/divider.sv
../src/riscv_processor.sv
riscv_processor_sva.sv
../instruction_memory.hex
```

Key points (v1.2.0):
- **`read_slang`** (yosys-slang frontend) is required for the SystemVerilog
  package/enums; the native `read_verilog -sv` fails on `import riscv_pkg::*`.
- **`-D IVERILOG`** excludes the core's simulation-only SVA so the formal wrapper
  (`riscv_processor_sva.sv`) is the proof contract.
- **`wait off`** stops at the first definitive result; `abc pdr` (IC3) proves the
  wrapper properties unbounded in <1 s. `aigbmc` is not used (it is invalid for
  `bmc` mode in this sby version).
- The hex image is listed so proofs reason about the canonical program.

## Running Results

### Successful Proof
```
SBY 12:34:56 [formal] engine_0: ##   0:00:00  Starting engine_0 (smtbmc)
SBY 12:34:56 [formal] engine_1: ##   0:00:00  Starting engine_1 (abc pdr)
SBY 12:34:57 [formal] engine_1: ##   0:00:01  Solved (proved)
SBY 12:34:57 [formal] Status: PASSED
```

### Failed Property
```
SBY 12:34:56 [formal] engine_0: ##   0:00:05  Counterexample found
SBY 12:34:56 [formal] engine_0: ##   0:00:05  Assertion failed: reg_x0_always_zero
SBY 12:35:12 [formal] Status: FAILED
```

## SVA Properties

There are two distinct sets of properties:

### Formal wrapper (`verification/riscv_processor_sva.sv`)
The Yosys-friendly proof contract used by the `.sby` configs (plain boolean
expressions, no `$isunknown` / implication operators):
- **4 assertions**: x0 = 0 on read port 1; x0 = 0 on read port 2; PC word-aligned;
  register write only for the 7 writing opcodes.
- **3 cover properties**: branch taken; memory write; memory read.
- A first-cycle reset assumption (`init_cycle`) so PC alignment is checked from
  the reset state.

### Inline core SVA (`src/riscv_processor.sv`, simulation-only)
14 assertions + 15 cover properties, guarded by `` `ifndef IVERILOG `` and excluded
from formal via `-D IVERILOG`. These include PC alignment/advancement, x0 behavior,
opcode/format validity, and ADD/SUB/ADDI correctness. Note: the ADD/SUB/ADDI
assertions recompute the datapath expressions (tautological against the RTL); the
independently useful checks are x0 / alignment / opcode-validity. xsim evaluates the
assertions but ignores `cover property` (the covers are exercised by the sby cover
flow).

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