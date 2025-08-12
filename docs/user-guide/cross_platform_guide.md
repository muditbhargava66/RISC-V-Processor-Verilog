# Cross-Platform Development Guide

This guide explains how to use the RISC-V processor project on Windows, Linux, and macOS.

## Quick Start

### 1. Environment Setup
```bash
# Run the setup script to configure your environment
python scripts/setup_environment.py
```

### 2. Basic Testing
```bash
# Test syntax without external tools
python scripts/syntax_check.py

# Run comprehensive test suite
python scripts/run_tests.py

# Or use Makefile (if make is available)
make test
```

### 3. Vivado Synthesis (if Vivado is installed)
```bash
# Using Python scripts (works on all platforms)
python scripts/run_vivado.py scripts/vivado_synthesis.tcl

# Or using Makefile
make synthesize
```

## Platform-Specific Instructions

### Windows

#### Prerequisites
- Python 3.6+ (recommended: Python 3.8+)
- Xilinx Vivado (optional, for synthesis)
- Make for Windows (optional, for Makefile support)

#### Installation
1. **Python**: Download from [python.org](https://python.org)
2. **Vivado**: Install Xilinx Vivado Design Suite
3. **Make** (optional): 
   - Install via Chocolatey: `choco install make`
   - Or use Git Bash which includes make
   - Or use Python scripts directly

#### Usage
```cmd
# Setup environment
python scripts\setup_environment.py

# Run tests
python scripts\run_tests.py

# Syntax check
python scripts\syntax_check.py

# Vivado synthesis (if installed)
python scripts\run_vivado.py scripts\vivado_synthesis.tcl
```

#### Windows-Specific Notes
- Use backslashes (`\`) in paths when using cmd
- PowerShell and Git Bash also work well
- The Makefile automatically detects Windows and adjusts commands

### Linux

#### Prerequisites
- Python 3.6+ (usually pre-installed)
- Xilinx Vivado (optional, for synthesis)
- Make (usually pre-installed)
- Optional: iverilog for additional syntax checking

#### Installation
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3 python3-pip make git

# Optional: Install iverilog
sudo apt install iverilog

# CentOS/RHEL/Fedora
sudo yum install python3 python3-pip make git
# or
sudo dnf install python3 python3-pip make git
```

#### Usage
```bash
# Setup environment
python3 scripts/setup_environment.py

# Run tests
make test

# Syntax check with iverilog (if installed)
make lint

# Vivado synthesis
make synthesize
```

### macOS

#### Prerequisites
- Python 3.6+ (install via Homebrew recommended)
- Xilinx Vivado (optional, for synthesis)
- Xcode Command Line Tools (for make)

#### Installation
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python and tools
brew install python3 make git

# Optional: Install iverilog
brew install icarus-verilog

# Install Xcode Command Line Tools
xcode-select --install
```

#### Usage
```bash
# Setup environment
python3 scripts/setup_environment.py

# Run tests
make test

# Syntax check
make lint

# Vivado synthesis
make synthesize
```

## Available Commands

### Python Scripts (Work on all platforms)
```bash
# Environment setup
python scripts/setup_environment.py

# Syntax checking
python scripts/syntax_check.py

# Comprehensive testing
python scripts/run_tests.py

# Vivado operations
python scripts/run_vivado.py scripts/vivado_synthesis.tcl
python scripts/run_vivado.py scripts/run_simulation.tcl
python scripts/run_vivado.py scripts/run_implementation.tcl
```

### Makefile Targets (Require make)
```bash
make help          # Show all available targets
make setup         # Create necessary directories
make check         # Basic syntax check
make lint          # Advanced syntax check (requires iverilog)
make test          # Run all tests
make synthesize    # Run Vivado synthesis
make simulate      # Run Vivado simulation
make implement     # Run Vivado implementation
make reports       # Generate reports
make clean         # Clean generated files
make status        # Show project status
```

## Tool Requirements

### Required
- **Python 3.6+**: Core scripting and automation
- **Project files**: All source files in correct directories

### Optional but Recommended
- **Make**: Enables Makefile usage for easier commands
- **Xilinx Vivado**: Required for synthesis and implementation
- **Git**: Version control and collaboration
- **iverilog**: Additional Verilog syntax checking

### Development Tools (Optional)
- **VS Code**: Excellent Verilog support with extensions
- **Vim/Emacs**: Lightweight editing with Verilog modes
- **GTKWave**: Waveform viewer for simulation results

## Troubleshooting

### Common Issues

#### "Python not found"
- **Windows**: Ensure Python is in PATH, try `py` instead of `python`
- **Linux/macOS**: Try `python3` instead of `python`

#### "Make not found"
- **Windows**: Install make or use Python scripts directly
- **Linux**: Install with package manager (`apt install make`)
- **macOS**: Install Xcode Command Line Tools

#### "Vivado not found"
- Ensure Vivado is installed and in PATH
- Check common installation paths:
  - Windows: `C:\Xilinx\Vivado\<version>\bin\`
  - Linux/macOS: `/opt/Xilinx/Vivado/<version>/bin/`

#### Permission Denied (Linux/macOS)
```bash
# Make scripts executable
chmod +x scripts/*.py
```

#### Unicode Errors (Windows)
- Use PowerShell or Git Bash instead of cmd
- Ensure proper encoding in terminal

### Getting Help

1. **Check setup**: Run `python scripts/setup_environment.py`
2. **Run diagnostics**: Run `python scripts/run_tests.py`
3. **Check status**: Run `make status` or check files manually
4. **Read documentation**: See `README.md` and `VIVADO_IMPROVEMENTS.md`

## Development Workflow

### Recommended Workflow
1. **Setup**: Run environment setup script
2. **Edit**: Modify Verilog files in `src/` directory
3. **Check**: Run syntax checker after changes
4. **Test**: Run comprehensive test suite
5. **Synthesize**: Use Vivado for synthesis and implementation
6. **Debug**: Use simulation and reports for debugging

### File Organization
```
project/
├── src/                    # Verilog source files
├── testbenches/           # Testbench files and memory init
├── constraints/           # Timing and pin constraints
├── scripts/              # Automation scripts
├── reports/              # Generated reports
├── logs/                 # Log files
├── vivado_project/       # Vivado project files
├── Makefile              # Cross-platform build system
└── README.md             # Project documentation
```

### Best Practices
1. **Always run tests** before committing changes
2. **Use version control** (git) for tracking changes
3. **Check syntax regularly** during development
4. **Review reports** after synthesis for optimization
5. **Keep backups** of working configurations

## Platform-Specific Optimizations

### Windows
- Use PowerShell for better Unicode support
- Consider WSL for Linux-like environment
- Use Git Bash for Unix-style commands

### Linux
- Take advantage of native make and shell tools
- Use package managers for easy tool installation
- Consider using tmux for multiple terminal sessions

### macOS
- Use Homebrew for package management
- Terminal.app or iTerm2 work well
- Consider using Xcode for advanced editing

This cross-platform approach ensures your RISC-V processor project works consistently across all major operating systems while taking advantage of platform-specific features where available.