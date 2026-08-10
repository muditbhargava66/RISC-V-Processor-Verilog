# Project Structure

```
RISC-V-Processor-Verilog/
├── src/                          # RTL Source Files (SystemVerilog)
│   ├── riscv_pkg.sv              # Common package: types, enums, constants
│   ├── alu.sv                    # Arithmetic Logic Unit
│   ├── control_unit.sv           # Instruction decode & control
│   ├── register_file.sv          # 32×32-bit register file
│   ├── program_counter.sv        # PC with branch/jump
│   ├── immediate_generator.sv    # Immediate extraction
│   ├── instruction_memory.sv     # Parameterized I-MEM
│   ├── data_memory.sv            # Parameterized D-MEM
│   ├── riscv_processor.sv        # Top-level core (with inline SVA)
│   ├── riscv_processor_minimal.sv     # Minimal I/O wrapper
│   └── riscv_processor_jtag_debug.sv  # JTAG/ILA/VIO wrapper
│
├── testbenches/                  # Simulation Testbenches (SystemVerilog)
│   ├── alu_tb.sv                 # ALU exhaustive tests
│   ├── control_unit_tb.sv        # Control decode tests
│   ├── memory_tb.sv              # I-MEM/D-MEM tests
│   ├── register_file_tb.sv       # Register file tests
│   └── riscv_processor_tb.sv     # System self-checking test
│
├── verification/                 # Formal & Compliance Verification
│   ├── compliance_tests.sv       # RV32I smoke tests
│   ├── formal_verification_tb.sv # Assertion simulation TB
│   ├── formal.sby                # SymbiYosys prove config
│   ├── formal_bmc.sby            # Bounded model checking
│   ├── formal_cover.sby          # Coverage collection
│   └── formal_core.sby           # Core-only prove
│
├── benchmarks/                   # Performance Analysis
│   └── performance_benchmark.sv  # IPC/throughput measurement
│
├── scripts/                      # Build Automation (Tcl)
│   ├── riscv_build_common.tcl    # Shared library
│   ├── build_vivado.tcl          # Project creation
│   ├── run_simulation.tcl        # Test execution
│   ├── run_synthesis_impl.tcl    # Synth + Impl
│   └── quick_lint_check.tcl      # Lint-only check
│
├── constraints/                  # FPGA Constraints (XDC)
│   ├── riscv_processor_minimal.xdc      # Minimal wrapper (12 pins)
│   └── riscv_processor_jtag_debug.xdc   # JTAG debug (12 pins)
│
├── docs/                         # Documentation (this folder)
│   ├── index.md                  # Documentation index
│   ├── guides/                   # Getting started guides
│   ├── architecture/             # Architecture documentation
│   ├── modules/                  # Module reference
│   ├── verification/             # Verification guides
│   ├── fpga/                     # FPGA implementation
│   ├── debug/                    # Debug/ILA/VIO
│   ├── formal/                   # Formal verification
│   ├── performance/              # Benchmarking
│   ├── development/              # Development guides
│   └── reference/                # Reference tables
│
├── build/                        # Generated (gitignored)
│   ├── vivado/                   # Vivado projects
│   ├── simulations/              # Simulation runs
│   ├── lint_check/               # Lint runs
│   └── reports/                  # Reports
│
├── instruction_memory.hex        # Program image (11 instructions)
├── Makefile                      # Build entry points
├── CHANGELOG.md                  # Version history
├── LICENSE                       # MIT License
├── README.md                     # Project overview
└── VERSION_ROADMAP.md            # Future plans
```

## Key Directories

| Directory | Purpose | Generated? |
|-----------|---------|------------|
| `src/` | RTL source code | No |
| `testbenches/` | Simulation tests | No |
| `verification/` | Formal/compliance | No |
| `benchmarks/` | Performance tests | No |
| `scripts/` | Build automation | No |
| `constraints/` | FPGA pin/timing | No |
| `docs/` | Documentation | No |
| `build/` | Vivado outputs | **Yes** (gitignored) |

## Source File Conventions

### Naming
- **Modules**: `snake_case` (e.g., `riscv_processor`)
- **Files**: Match module name + `.sv` extension
- **Packages**: `_pkg` suffix (e.g., `riscv_pkg`)
- **Testbenches**: `_tb` suffix (e.g., `alu_tb`)

### Parameters
- All modules use `parameter` for configurability
- Core parameters: `XLEN`, `ENABLE_M`, `ENABLE_C`
- Memory parameters: `ADDR_WIDTH`, `INIT_FILE`

### Coding Style
- SystemVerilog (`always_comb`, `always_ff`, `logic`)
- Explicit reset strategies (synchronous preferred)
- Inline SVA assertions in RTL
- Package-based type/enum definitions

## Build Outputs

All generated files go under `build/`:
```
build/
├── vivado/
│   ├── riscv_processor_core/          # Core synthesis project
│   ├── riscv_processor_minimal/       # Minimal implementation
│   └── riscv_processor_jtag_debug/    # JTAG debug implementation
├── simulations/
│   ├── system/                        # System test run
│   ├── alu/                           # ALU test run
│   └── ...                            # Other test runs
├── lint_check/
│   └── riscv_lint_check/              # Lint-only synthesis
└── reports/                           # Utilization, timing, power
```

## Source File Dependencies

```
riscv_processor.sv (top)
├── riscv_pkg.sv
├── program_counter.sv
├── instruction_memory.sv
├── immediate_generator.sv
├── register_file.sv
├── control_unit.sv
├── alu.sv
└── data_memory.sv
```

## File Descriptions

| File | Description | Lines |
|------|-------------|-------|
| `riscv_pkg.sv` | Common types, enums, opcodes, utilities | ~240 |
| `alu.sv` | ALU with M-extension (MUL/DIV) | ~80 |
| `control_unit.sv` | Full RV32I decode | ~180 |
| `register_file.sv` | 32×32 sync reset | ~45 |
| `program_counter.sv` | PC with branch/jump | ~25 |
| `immediate_generator.sv` | All immediate formats | ~50 |
| `instruction_memory.sv` | Parameterized ROM | ~30 |
| `data_memory.sv` | Byte/halfword/word RAM | ~160 |
| `riscv_processor.sv` | Core with inline SVA | ~330 |
| `riscv_processor_minimal.sv` | 12-pin wrapper | ~25 |
| `riscv_processor_jtag_debug.sv` | ILA/VIO wrapper | ~110 |

## Configuration Files

| File | Purpose |
|------|---------|
| `Makefile` | Build/test entry points |
| `instruction_memory.hex` | Program image (11 lines) |
| `constraints/*.xdc` | Pin assignments, timing |
| `scripts/*.tcl` | Vivado automation |
| `verification/*.sby` | SymbiYosys configs |