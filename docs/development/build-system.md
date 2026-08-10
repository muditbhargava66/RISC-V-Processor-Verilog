# Build System Guide

## Overview

The build system uses a Makefile with Vivado Tcl scripts for automation.

## Makefile Targets

### Verification
```bash
make lint              # Synthesis check (no simulation)
make test-system       # System self-checking test
make test-alu          # ALU unit tests
make test-control      # Control unit tests
make test-memory       # Memory tests
make test-regfile      # Register file tests
make test-compliance   # RV32I smoke checks
make test-benchmark    # Performance benchmark
make test-formal       # SVA assertion simulation
make test-all          # All deterministic tests
```

### FPGA Flow
```bash
make create-project          # Create core synthesis project
make create-project-minimal  # Create Basys3 minimal project
make create-project-jtag     # Create JTAG debug project
make synthesize              # Synthesize core
make implement-minimal       # Implement minimal wrapper + bitstream
make implement-jtag          # Implement JTAG wrapper + bitstream
make build-all               # Build both FPGA wrappers
```

### Maintenance
```bash
make status         # Git status
make clean-build    # Remove build/ directory
```

## Override Variables

```bash
# Override Vivado path
make VIVADO="/opt/Xilinx/Vivado/2023.2/bin/vivado" test-system

# Override target
make VIVADO="/opt/Xilinx/Vivado/2022.2/bin/vivado" implement-minimal
```

## Script Architecture

### Unified Tcl Library
`scripts/riscv_build_common.tcl` - Shared functions and configuration

### Individual Scripts
| Script | Purpose |
|--------|---------|
| `build_vivado.tcl` | Create Vivado projects |
| `run_simulation.tcl` | Run simulation tests |
| `run_synthesis_impl.tcl` | Synthesis + implementation |
| `quick_lint_check.tcl` | Quick lint check |

## Adding New Tests

### 1. Create Testbench
```systemverilog
// testbenches/new_test.sv
module new_test;
    // Test implementation
endmodule
```

### 2. Add to run_simulation.tcl
```tcl
# In sim_tests dict:
new_test { 
    top_module new_test; 
    test_file [file join $repo_root testbenches new_test.sv] 
}
```

### 3. Add to Makefile
```makefile
test-new_test:
	$(VIVADO_BATCH) -source scripts/run_simulation.tcl -tclargs new_test

test-all: ... test-new_test
```

## Adding New Modules

### 1. Create Module
```systemverilog
// src/new_module.sv
module new_module #(
    parameter int PARAM = 32
)(...);
```

### 2. Update Package (if needed)
```systemverilog
// src/riscv_pkg.sv
package riscv_pkg;
    // Add types/constants
endpackage
```

### 3. Update Build Scripts
```tcl
# In riscv_build_common.tcl:
variable core_files {
    ...
    src/new_module.sv
}
```

### 4. Update Makefile (if new test)
```makefile
test-new_module:
	$(VIVADO_BATCH) -source scripts/run_simulation.tcl -tclargs new_module
```

## Adding New FPGA Targets

### 1. Create XDC
```tcl
# constraints/new_board.xdc
# Pin assignments, timing constraints
```

### 2. Create Wrapper
```systemverilog
// src/riscv_processor_new_board.sv
module riscv_processor_new_board #(...)(...);
```

### 3. Add to Build Config
```tcl
# In riscv_build_common.tcl:
variable targets {
    new_board {
        project_name "riscv_processor_new_board"
        top_module "riscv_processor_new_board"
        constraint_file "constraints/new_board.xdc"
        wrapper_file "src/riscv_processor_new_board.sv"
    }
}
```

### 4. Add Make Targets
```makefile
create-project-new-board:
	$(VIVADO_BATCH) -source scripts/build_vivado.tcl -tclargs new_board

implement-new-board:
	$(VIVADO_BATCH) -source scripts/run_synthesis_impl.tcl -tclargs new_board
```

## Customizing Build

### Override Vivado Path
```bash
export VIVADO="/opt/Xilinx/Vivado/2023.2/bin/vivado"
make test-all
```

### Override Target Device
```bash
# Edit Makefile or pass via command line
make VIVADO="..." PART="xc7a100tcsg324-1" implement-minimal
```

### Custom Build Directory
```bash
# Edit Makefile BUILD_DIR variable
BUILD_DIR = custom_build
```

## Continuous Integration

### GitHub Actions Example
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Vivado
        run: |
          # Install Vivado or use pre-installed
      - name: Run Tests
        run: make test-all
      - name: Lint Check
        run: make lint
      - name: Formal Verification
        run: |
          pip install symbiyosys
          cd verification && sby -f formal.sby
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Vivado not found | Set VIVADO env var or edit Makefile |
| XSim fails on Windows | Disable Device Guard/Credential Guard |
| Path too long | Move project to shorter path |
| Tcl errors | Check Tcl syntax, Vivado version compatibility |
| Out of memory | Reduce parallel jobs (`-j 2`) |

## Related Documents
- [Quick Start Guide](../guides/quick-start.md)
- [Prerequisites](../guides/prerequisites.md)
- [Project Structure](../guides/project-structure.md)
- [FPGA Implementation](../fpga/basys3-guide.md)