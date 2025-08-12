# RISC-V Processor Verification Environment

This directory contains a comprehensive verification environment for the RISC-V processor implementation, featuring production-ready testbenches, automated test runners, and coverage analysis.

## 📁 Directory Structure

```
verification/
├── testbenches/
│   ├── unit/                    # Unit-level testbenches
│   │   ├── alu_tb.sv           # ALU comprehensive tests
│   │   ├── register_file_tb.sv  # Register file tests
│   │   ├── control_unit_tb.sv   # Control unit tests
│   │   └── immediate_generator_tb.sv # Immediate generator tests
│   ├── integration/             # Integration testbenches
│   └── system/                  # System-level testbenches
│       └── processor_system_tb.sv
├── scripts/
│   └── run_unit_tests.py       # Automated test runner
├── results/                     # Test results and logs
├── coverage/                    # Coverage reports
├── Makefile                     # Build automation
└── README.md                    # This file
```

## 🚀 Quick Start

### Prerequisites

- **Xilinx Vivado** (for XSim simulation) or **ModelSim/QuestaSim**
- **Python 3.7+** for test automation
- **Make** for build automation

### Running Tests

```bash
# Run all unit tests
make unit-tests

# Run tests in parallel (faster)
make unit-tests-parallel

# Run with coverage analysis
make unit-tests-coverage

# Run specific module test
make test-alu
make test-regfile
make test-control
make test-imm-gen

# Clean and setup
make clean
make setup
```

### Using Python Test Runner Directly

```bash
# Run all tests with XSim
python3 scripts/run_unit_tests.py --simulator xsim

# Run all tests with ModelSim
python3 scripts/run_unit_tests.py --simulator modelsim

# Run specific test
python3 scripts/run_unit_tests.py --test alu_tb

# Run with coverage
python3 scripts/run_unit_tests.py --coverage

# Run in parallel
python3 scripts/run_unit_tests.py --parallel
```

## 🧪 Test Modules

### ALU Testbench (`alu_tb.sv`)
- **Comprehensive arithmetic operations**: ADD, SUB with overflow/underflow
- **Logical operations**: AND, OR, XOR with various bit patterns
- **Shift operations**: SLL, SRL, SRA with edge cases
- **Comparison operations**: SLT, SLTU with signed/unsigned values
- **1000+ random test cases** for thorough coverage
- **Edge case testing**: Maximum/minimum values, zero operands

### Register File Testbench (`register_file_tb.sv`)
- **Reset functionality**: Verify all registers clear to zero
- **x0 hardwired zero**: Ensure x0 always reads zero regardless of writes
- **Dual-port read**: Simultaneous read operations on both ports
- **Write-then-read**: Immediate read after write verification
- **All 32 registers**: Individual testing of each register
- **500+ random operations** for comprehensive validation

### Control Unit Testbench (`control_unit_tb.sv`)
- **All instruction types**: R, I, S, B, U, J type instructions
- **Complete opcode coverage**: Every supported RISC-V instruction
- **Control signal validation**: reg_write, mem_read, mem_write, branch, jump
- **ALU operation codes**: Correct ALU_OP generation for each instruction
- **Data path control**: alu_src, reg_write_src signal verification
- **Invalid instruction handling**: Safe default signal generation

### Immediate Generator Testbench (`immediate_generator_tb.sv`)
- **All immediate formats**: I, S, B, U, J type immediate extraction
- **Sign extension**: Proper sign extension for negative immediates
- **Bit field extraction**: Correct bit positioning and concatenation
- **Edge cases**: Maximum/minimum immediate values
- **200+ random instructions** for format validation

## 📊 Test Features

### Production-Ready Quality
- **Comprehensive coverage**: Functional, edge case, and random testing
- **Professional reporting**: Detailed pass/fail statistics with timing
- **Error diagnostics**: Clear failure messages with expected vs actual values
- **Automated execution**: One-command test suite execution
- **Parallel execution**: Faster test completion for large suites

### Coverage Analysis
- **Functional coverage**: SystemVerilog covergroups for each module
- **Code coverage**: Integration with simulator coverage tools
- **Cross coverage**: Interaction between different input combinations
- **Coverage reports**: HTML and text format reports

### Continuous Integration Ready
- **JSON result format**: Machine-readable test results
- **Exit codes**: Proper success/failure indication for CI systems
- **Timeout handling**: Prevents hanging tests in automated environments
- **Parallel execution**: Efficient resource utilization

## 🔧 Configuration

### Simulator Selection
The verification environment supports multiple simulators:

```bash
# Xilinx XSim (default)
make unit-tests SIMULATOR=xsim

# Mentor ModelSim/QuestaSim
make unit-tests SIMULATOR=modelsim
```

### Test Customization
Modify test parameters in individual testbench files:

```systemverilog
// In alu_tb.sv
localparam NUM_RANDOM_TESTS = 1000;  // Adjust random test count

// In register_file_tb.sv
localparam NUM_RANDOM_TESTS = 500;   // Adjust random operations
```

## 📈 Results and Reports

### Test Results
Results are saved in `results/` directory:
- `unit_test_report.json`: Comprehensive JSON report
- `*_xsim.log`: Individual test simulation logs
- `*_modelsim.log`: ModelSim simulation logs

### Coverage Reports
Coverage data is saved in `coverage/` directory:
- `unit_coverage.html`: HTML coverage report
- Coverage databases from simulator tools

### Example Output
```
========================================
🎯 OVERALL SUMMARY
========================================
Modules Tested: 4
Modules Passed: 4
Modules Failed: 0
Total Test Cases: 2847
Total Passed: 2847
Total Failed: 0
Overall Success Rate: 100.00%
Total Duration: 45.23s

🎉 ALL UNIT TESTS PASSED!
✅ RISC-V processor units are ready for integration
```

## 🛠️ Development Workflow

### Adding New Tests
1. Create testbench in appropriate directory
2. Add to test list in `run_unit_tests.py`
3. Add Makefile target for individual execution
4. Update this README

### Debugging Failed Tests
1. Check individual test logs in `results/`
2. Run specific test: `make test-<module>`
3. Review expected vs actual values in output
4. Use simulator GUI for waveform analysis

### Best Practices
- **Write self-checking tests**: Automatic pass/fail determination
- **Include edge cases**: Test boundary conditions
- **Use random testing**: Catch unexpected corner cases
- **Document test intent**: Clear test descriptions
- **Maintain coverage**: Ensure all functionality is tested

## 🤝 Contributing

When adding new verification components:
1. Follow existing testbench structure and naming
2. Include comprehensive test coverage
3. Add appropriate documentation
4. Update automation scripts
5. Test with multiple simulators if possible

## 📚 References

- [RISC-V Specification](https://riscv.org/specifications/)
- [SystemVerilog Verification](https://www.systemverilog.io/)
- [Vivado Simulation Guide](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2021_1/ug900-vivado-logic-simulation.pdf)
- [ModelSim User Guide](https://www.microsemi.com/document-portal/doc_download/136364-modelsim-user-manual-pdf)