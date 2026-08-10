# Prerequisites

## Required Software

### Xilinx Vivado
- **Version**: 2023.2 (recommended) or 2022.2+
- **Edition**: Standard, Enterprise, or WebPACK
- **Components**: Vivado Simulator (XSim), Synthesis, Implementation
- **License**: WebPACK license sufficient for Artix-7

### SymbiYosys (Formal Verification)
- **Installation**: `pip install symbiyosys` or download from [symbiyosys.readthedocs.io](https://symbiyosys.readthedocs.io/)
- **Solvers**: Yices2 (default), Z3, Boolector, or CVC4
- **Yosys**: Included with SymbiYosys or install separately

### Version Control
- **Git**: 2.30+ for repository management

### Optional
- **GTKWave**: For viewing VCD waveforms
- **Verilator**: Alternative fast simulator (`apt install verilator` / `choco install verilator`)

## Hardware

### Basys3 Board (Recommended)
- **FPGA**: Xilinx Artix-7 XC7A35T-CPG236-1
- **Clock**: 100 MHz on-board oscillator (W5 pin)
- **USB**: USB-UART/JTAG for programming
- **LEDs**: 16 user LEDs (LD0-LD15)
- **Switches**: 16 slide switches
- **Buttons**: 5 push buttons

### Alternative Boards
Any Xilinx 7-series board with sufficient I/O can be used by modifying the XDC constraints file.

## Environment Setup

### Windows (PowerShell)
```powershell
# Verify Vivado installation
$env:VIVADO = "C:\Xilinx\Vivado\2023.2\bin\vivado.bat"
& $env:VIVADO -version

# Set PATH if needed
$env:PATH += ";C:\Xilinx\Vivado\2023.2\bin"
```

### Linux/macOS
```bash
# Source Vivado settings
source /opt/Xilinx/Vivado/2023.2/settings64.sh

# Verify
vivado -version
```

## Repository Setup

```bash
git clone <repository-url>
cd RISC-V-Processor-Verilog

# Verify structure
ls -la
# Should show: src/, testbenches/, verification/, benchmarks/, scripts/, constraints/, docs/, Makefile
```

## Verify Installation

```bash
# Quick sanity check
make lint
# Should complete with "SYNTHESIS: PASSED"
```

## Troubleshooting Prerequisites

| Issue | Solution |
|-------|----------|
| Vivado not in PATH | Add to system PATH or set `VIVADO` env var |
| XSim blocked on Windows | Disable Device Guard / Credential Guard |
| SymbiYosys not found | Install via pip or download binary |
| Yosys solver missing | Install yices2: `conda install -c conda-forge yices2` |
| Permission denied (Linux) | Add user to `dialout` group for USB-JTAG |

## Next Steps

After prerequisites are met, proceed to [Quick Start Guide](quick-start.md).