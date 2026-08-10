# Quick Start Guide

Get the RISC-V processor running in 5 minutes.

## Prerequisites

- **Xilinx Vivado 2023.2** (or compatible 2022.2+)
- **Windows 10/11** with PowerShell
- **Git** for cloning

## 1. Clone and Setup

```powershell
git clone <repository-url>
cd RISC-V-Processor-Verilog
```

## 2. Run All Tests

```powershell
make test-all
```

This runs: `lint`, `test-system`, `test-alu`, `test-control`, `test-memory`, `test-regfile`, `test-compliance`, `test-benchmark`

## 3. Build for FPGA (Basys3)

### Minimal Wrapper (Production)
```powershell
make implement-minimal
```
Generates `build/vivado/riscv_processor_minimal/riscv_processor_minimal.bit`

### JTAG Debug Wrapper (Development)
```powershell
make implement-jtag
```
Generates `build/vivado/riscv_processor_jtag_debug/riscv_processor_jtag_debug.bit` with ILA/VIO

## 4. Program the Board

Open Vivado Hardware Manager, connect to Basys3, and program the generated `.bit` file.

## 5. Run Formal Verification (Optional)

```powershell
# Install SymbiYosys first
sby -f verification/formal.sby          # Full proof
sby -f verification/formal_bmc.sby      # Bounded model checking
sby -f verification/formal_cover.sby    # Coverage collection
```

## Expected Results

| Test | Expected Outcome |
|------|------------------|
| `make lint` | SYNTHESIS: PASSED (0 errors, 0 critical warnings) |
| `make test-system` | 6/6 register checks PASS |
| `make test-alu` | 24/24 ALU operations PASS |
| `make test-control` | 37/37 decode tests PASS |
| `make test-memory` | 18/18 memory tests PASS |
| `make test-regfile` | 37/37 register tests PASS |
| `make test-compliance` | 5/5 PASS (3 skipped) |
| `make test-benchmark` | 10 instructions in 10 cycles (IPC=1.0 active) |

## Common Issues

| Problem | Solution |
|---------|----------|
| Vivado not found | Set `VIVADO` env var or edit Makefile |
| XSim fails on Windows | Check Device Guard/Credential Guard settings |
| `$readmemh` warning | Ensure `instruction_memory.hex` is in repo root |
| Timing not met | Check `constraints/riscv_processor_minimal.xdc` |

## Next Steps

- Read [Architecture Overview](../architecture/overview.md) to understand the design
- Browse [Module Reference](../modules/core-processor.md) for implementation details
- See [FPGA Implementation](../fpga/basys3-guide.md) for hardware deployment
- Check [Verification Guide](../verification/verification-guide.md) for test details