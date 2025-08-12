# RISC-V Processor v1.0.0 Makefile
# Automation for build, test, clean, and deployment tasks

# Project configuration
PROJECT_NAME = riscv_processor_v1
PROJECT_DIR = ./projects/vivado/$(PROJECT_NAME)
VIVADO = vivado
VIVADO_BATCH = $(VIVADO) -mode batch

# Default target
.PHONY: all
all: help

# Help target
.PHONY: help
help:
	@echo "========================================="
	@echo "RISC-V Processor v1.0.0 Build System"
	@echo "========================================="
	@echo "Available targets:"
	@echo ""
	@echo "Build targets:"
	@echo "  create-project  - Create Vivado project"
	@echo "  synthesize      - Run synthesis"
	@echo "  implement       - Run implementation"
	@echo "  bitstream       - Generate bitstream"
	@echo "  build-all       - Complete build flow"
	@echo ""
	@echo "Test targets:"
	@echo "  test-system     - Run system testbench"
	@echo "  test-alu        - Run ALU testbench"
	@echo "  test-control    - Run control unit testbench"
	@echo "  test-memory     - Run memory testbench"
	@echo "  test-regfile    - Run register file testbench"
	@echo "  test-all        - Run all testbenches"
	@echo ""
	@echo "Analysis targets:"
	@echo "  reports         - Generate all reports"
	@echo "  timing          - Generate timing reports"
	@echo "  utilization     - Generate utilization reports"
	@echo ""
	@echo "Maintenance targets:"
	@echo "  clean           - Clean generated files"
	@echo "  clean-all       - Deep clean (including projects)"
	@echo "  clean-logs      - Clean log and journal files"
	@echo ""
	@echo "Git targets:"
	@echo "  git-status      - Show git status"
	@echo "  git-add         - Add all changes"
	@echo "  git-commit      - Commit with standard message"
	@echo "========================================="

# Build targets
.PHONY: create-project
create-project:
	@echo "Creating Vivado project..."
	$(VIVADO_BATCH) -source scripts/build_vivado_v1.tcl

.PHONY: synthesize
synthesize:
	@echo "Running synthesis..."
	$(VIVADO_BATCH) -source scripts/run_synthesis.tcl

.PHONY: implement
implement: synthesize
	@echo "Running implementation..."
	$(VIVADO_BATCH) -source scripts/run_implementation.tcl

.PHONY: bitstream
bitstream: implement
	@echo "Generating bitstream..."
	$(VIVADO_BATCH) -source scripts/generate_bitstream.tcl

.PHONY: build-all
build-all: create-project synthesize reports
	@echo "Complete build finished successfully!"

# Test targets
.PHONY: test-system
test-system:
	@echo "Running system testbench..."
	$(VIVADO_BATCH) -source scripts/run_system_test.tcl

.PHONY: test-alu
test-alu:
	@echo "Running ALU testbench..."
	$(VIVADO_BATCH) -source testbenches/run_alu_test.tcl

.PHONY: test-control
test-control:
	@echo "Running control unit testbench..."
	$(VIVADO_BATCH) -source testbenches/run_control_test.tcl

.PHONY: test-memory
test-memory:
	@echo "Running memory testbench..."
	$(VIVADO_BATCH) -source testbenches/run_memory_test.tcl

.PHONY: test-regfile
test-regfile:
	@echo "Running register file testbench..."
	$(VIVADO_BATCH) -source testbenches/run_regfile_test.tcl

.PHONY: test-all
test-all: test-system test-alu test-control test-memory test-regfile
	@echo "All tests completed!"

# Analysis targets
.PHONY: reports
reports:
	@echo "Generating comprehensive reports..."
	$(VIVADO_BATCH) -source scripts/generate_reports.tcl

.PHONY: timing
timing:
	@echo "Generating timing reports..."
	$(VIVADO_BATCH) -source scripts/timing_analysis.tcl

.PHONY: utilization
utilization:
	@echo "Generating utilization reports..."
	$(VIVADO_BATCH) -source scripts/utilization_analysis.tcl

# Clean targets
.PHONY: clean-logs
clean-logs:
	@echo "Cleaning log and journal files..."
	@if exist "*.log" del /q *.log >nul 2>&1
	@if exist "*.jou" del /q *.jou >nul 2>&1
	@if exist "vivado*.log" del /q vivado*.log >nul 2>&1
	@if exist "vivado*.jou" del /q vivado*.jou >nul 2>&1
	@for /r %%i in (*.backup.log) do @if exist "%%i" del /q "%%i" >nul 2>&1
	@for /r %%i in (*.backup.jou) do @if exist "%%i" del /q "%%i" >nul 2>&1
	@echo "Log files cleaned."

.PHONY: clean
clean: clean-logs
	@echo "Cleaning generated files..."
	@if exist ".Xil" rmdir /s /q .Xil >nul 2>&1
	@if exist "xsim.dir" rmdir /s /q xsim.dir >nul 2>&1
	@if exist "*.wdb" del /q *.wdb >nul 2>&1
	@if exist "*.wcfg" del /q *.wcfg >nul 2>&1
	@if exist "*.vcd" del /q *.vcd >nul 2>&1
	@if exist "*.pb" del /q *.pb >nul 2>&1
	@if exist "*.dcp" del /q *.dcp >nul 2>&1
	@if exist "*.bit" del /q *.bit >nul 2>&1
	@if exist "*.ltx" del /q *.ltx >nul 2>&1
	@if exist "*.mmi" del /q *.mmi >nul 2>&1
	@echo "Generated files cleaned."

.PHONY: clean-all
clean-all: clean
	@echo "Deep cleaning (including projects)..."
	@if exist "projects" rmdir /s /q projects >nul 2>&1
	@if exist "test_project" rmdir /s /q test_project >nul 2>&1
	@echo "Deep clean completed."

# Git targets
.PHONY: git-status
git-status:
	@git status

.PHONY: git-add
git-add: clean-logs
	@echo "Adding all changes to git..."
	@git add .

.PHONY: git-commit
git-commit: git-add
	@echo "Committing changes..."
	@git commit -m "feat: Production-ready RISC-V processor v1.0.0 with comprehensive testing and verification"

# Utility targets
.PHONY: check-vivado
check-vivado:
	@which $(VIVADO) > /dev/null || (echo "Error: Vivado not found in PATH" && exit 1)
	@echo "Vivado found: $$($(VIVADO) -version | head -1)"

.PHONY: project-info
project-info:
	@echo "Project: $(PROJECT_NAME)"
	@echo "Location: $(PROJECT_DIR)"
	@echo "Source files: $$(find src/ -name "*.v" | wc -l)"
	@echo "Testbenches: $$(find testbenches/ -name "*_tb.v" | wc -l)"
	@echo "Scripts: $$(find scripts/ -name "*.tcl" | wc -l)"

# File existence checks
$(PROJECT_DIR):
	@echo "Project directory does not exist. Run 'make create-project' first."
	@exit 1

# Dependencies
synthesize: | $(PROJECT_DIR)
reports: | $(PROJECT_DIR)
test-system: | $(PROJECT_DIR)