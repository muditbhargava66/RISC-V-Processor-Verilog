# RISC-V Processor Production Makefile
# Professional build system for cross-platform development

# Project Configuration
PROJECT_NAME := riscv_processor
TOP_MODULE := processor_top
TESTBENCH := processor_system_tb

# Tool Configuration
VIVADO := vivado
PYTHON := python3
MAKE := make

# Directory Configuration
SRC_DIR := src/rtl
TB_DIR := verification/testbenches
SCRIPT_DIR := tools/scripts
PROJECT_DIR := projects/vivado
BUILD_DIR := build
DOCS_DIR := docs

# Detect Operating System
ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
    SHELL := cmd
    MKDIR := mkdir
    RM := rmdir /s /q
    RMFILE := del /q
    PYTHON := python
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        DETECTED_OS := Linux
    endif
    ifeq ($(UNAME_S),Darwin)
        DETECTED_OS := macOS
    endif
    MKDIR := mkdir -p
    RM := rm -rf
    RMFILE := rm -f
endif

# Color codes for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
.PHONY: all
all: help

# Help target
.PHONY: help
help:
	@echo "RISC-V Processor Production Build System"
	@echo "========================================"
	@echo "Platform: $(DETECTED_OS)"
	@echo ""
	@echo "🚀 Quick Start:"
	@echo "  make validate        - Validate project setup"
	@echo "  make create-project  - Create Vivado project"
	@echo "  make implement       - Full synthesis and implementation"
	@echo ""
	@echo "🔧 Development:"
	@echo "  make synthesize      - Run synthesis with optimization"
	@echo "  make simulate        - Run system-level simulation"
	@echo "  make test           - Run comprehensive test suite"
	@echo "  make lint           - Code quality and style checks"
	@echo ""
	@echo "🧪 Verification:"
	@echo "  make sim-unit       - Run unit tests"
	@echo "  make sim-integration - Run integration tests"
	@echo "  make sim-system     - Run system tests"
	@echo "  make coverage       - Generate coverage reports"
	@echo ""
	@echo "📊 Analysis:"
	@echo "  make reports        - Generate analysis reports"
	@echo "  make timing         - Timing analysis"
	@echo "  make power          - Power analysis"
	@echo "  make utilization    - Resource utilization"
	@echo ""
	@echo "🛠️  Utilities:"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make distclean      - Deep clean including projects"
	@echo "  make docs           - Generate documentation"
	@echo "  make open-vivado    - Open project in Vivado GUI"

# Setup and validation
.PHONY: setup
setup:
	@echo "Setting up build environment..."
ifeq ($(DETECTED_OS),Windows)
	@if not exist "$(BUILD_DIR)" $(MKDIR) $(BUILD_DIR)
	@if not exist "$(BUILD_DIR)\synthesis" $(MKDIR) $(BUILD_DIR)\synthesis
	@if not exist "$(BUILD_DIR)\implementation" $(MKDIR) $(BUILD_DIR)\implementation
	@if not exist "$(BUILD_DIR)\simulation" $(MKDIR) $(BUILD_DIR)\simulation
	@if not exist "$(BUILD_DIR)\reports" $(MKDIR) $(BUILD_DIR)\reports
else
	@$(MKDIR) $(BUILD_DIR)/{synthesis,implementation,simulation,reports}
endif
	@echo "✅ Build environment ready"

.PHONY: validate
validate: setup
	@echo "🔍 Validating project setup..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/run_tests.py --validate-only
	@echo "✅ Project validation complete"

# Project management
.PHONY: create-project
create-project: setup
	@echo "🔨 Creating Vivado project..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/run_vivado.py $(SCRIPT_DIR)/build/create_project.tcl
	@echo "✅ Vivado project created: $(PROJECT_DIR)/$(PROJECT_NAME).xpr"

.PHONY: open-vivado
open-vivado:
	@echo "🚀 Opening Vivado project..."
ifeq ($(DETECTED_OS),Windows)
	@if exist "$(PROJECT_DIR)\$(PROJECT_NAME).xpr" ($(VIVADO) $(PROJECT_DIR)\$(PROJECT_NAME).xpr) else (echo "❌ Project not found. Run 'make create-project' first.")
else
	@if [ -f "$(PROJECT_DIR)/$(PROJECT_NAME).xpr" ]; then $(VIVADO) $(PROJECT_DIR)/$(PROJECT_NAME).xpr & else echo "❌ Project not found. Run 'make create-project' first."; fi
endif

# Synthesis and Implementation
.PHONY: synthesize
synthesize: create-project
	@echo "⚙️  Running synthesis with optimization..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/run_vivado.py $(SCRIPT_DIR)/synthesis/run_synthesis.tcl
	@echo "✅ Synthesis complete"

.PHONY: implement
implement: synthesize
	@echo "🏗️  Running implementation..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/run_vivado.py $(SCRIPT_DIR)/synthesis/run_implementation.tcl
	@echo "✅ Implementation complete"

.PHONY: program
program: implement
	@echo "📡 Programming FPGA device..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/run_vivado.py $(SCRIPT_DIR)/synthesis/program_device.tcl
	@echo "✅ Device programmed"

# Simulation and Testing
.PHONY: simulate
simulate: create-project
	@echo "🧪 Running system-level simulation..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/run_vivado.py $(SCRIPT_DIR)/simulation/run_simulation.tcl
	@echo "✅ Simulation complete"

.PHONY: sim-unit
sim-unit: setup
	@echo "🔬 Running unit tests..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/run_tests.py --unit-tests
	@echo "✅ Unit tests complete"

.PHONY: sim-integration
sim-integration: setup
	@echo "🔗 Running integration tests..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/run_tests.py --integration-tests
	@echo "✅ Integration tests complete"

.PHONY: sim-system
sim-system: create-project
	@echo "🖥️  Running system tests..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/run_tests.py --system-tests
	@echo "✅ System tests complete"

.PHONY: test
test: sim-unit sim-integration sim-system
	@echo "✅ All tests completed successfully"

# Code Quality
.PHONY: lint
lint: setup
	@echo "🔍 Running code quality checks..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/syntax_check.py --strict
	@echo "✅ Code quality checks complete"

.PHONY: coverage
coverage: test
	@echo "📊 Generating coverage reports..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/generate_coverage.py
	@echo "✅ Coverage reports generated in $(BUILD_DIR)/reports/"

# Analysis and Reports
.PHONY: reports
reports: implement
	@echo "📈 Generating comprehensive reports..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/generate_reports.py --all
	@echo "✅ Reports generated in $(BUILD_DIR)/reports/"

.PHONY: timing
timing: synthesize
	@echo "⏱️  Running timing analysis..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/run_vivado.py $(SCRIPT_DIR)/synthesis/timing_analysis.tcl
	@echo "✅ Timing analysis complete"

.PHONY: power
power: implement
	@echo "⚡ Running power analysis..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/run_vivado.py $(SCRIPT_DIR)/synthesis/power_analysis.tcl
	@echo "✅ Power analysis complete"

.PHONY: utilization
utilization: synthesize
	@echo "📊 Analyzing resource utilization..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/run_vivado.py $(SCRIPT_DIR)/synthesis/utilization_analysis.tcl
	@echo "✅ Utilization analysis complete"

# Documentation
.PHONY: docs
docs: setup
	@echo "📚 Generating documentation..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/generate_docs.py
	@echo "✅ Documentation generated in $(DOCS_DIR)/"

# Cleanup
.PHONY: clean
clean:
	@echo "🧹 Cleaning build artifacts..."
ifeq ($(DETECTED_OS),Windows)
	@if exist "$(BUILD_DIR)" $(RM) $(BUILD_DIR)
	@if exist ".Xil" $(RM) .Xil
	@if exist "*.log" $(RMFILE) *.log
	@if exist "*.jou" $(RMFILE) *.jou
else
	@$(RM) $(BUILD_DIR)
	@$(RM) .Xil
	@$(RMFILE) *.log *.jou
endif
	@echo "✅ Build artifacts cleaned"

.PHONY: distclean
distclean: clean
	@echo "🧹 Deep cleaning including projects..."
ifeq ($(DETECTED_OS),Windows)
	@if exist "$(PROJECT_DIR)" $(RM) $(PROJECT_DIR)
else
	@$(RM) $(PROJECT_DIR)
endif
	@echo "✅ Deep clean complete"

# Status and Information
.PHONY: status
status:
	@echo "📋 Project Status"
	@echo "================"
	@echo "Platform: $(DETECTED_OS)"
	@echo "Project: $(PROJECT_NAME)"
	@echo "Top Module: $(TOP_MODULE)"
	@echo ""
	@echo "📁 Directory Structure:"
	@echo "  Source: $(SRC_DIR)"
	@echo "  Testbenches: $(TB_DIR)"
	@echo "  Scripts: $(SCRIPT_DIR)"
	@echo "  Projects: $(PROJECT_DIR)"
	@echo "  Build: $(BUILD_DIR)"
	@echo ""
	@echo "🔧 Tools:"
	@echo "  Vivado: $(VIVADO)"
	@echo "  Python: $(PYTHON)"
	@echo ""
	@echo "📊 Files:"
ifeq ($(DETECTED_OS),Windows)
	@echo "  RTL Files:"
	@if exist "$(SRC_DIR)" (for /r $(SRC_DIR) %%f in (*.v *.sv) do @echo "    %%~nxf") else (echo "    No RTL files found")
	@echo "  Testbenches:"
	@if exist "$(TB_DIR)" (for /r $(TB_DIR) %%f in (*.v *.sv) do @echo "    %%~nxf") else (echo "    No testbench files found")
else
	@echo "  RTL Files:"
	@find $(SRC_DIR) -name "*.v" -o -name "*.sv" 2>/dev/null | sed 's/^/    /' || echo "    No RTL files found"
	@echo "  Testbenches:"
	@find $(TB_DIR) -name "*.v" -o -name "*.sv" 2>/dev/null | sed 's/^/    /' || echo "    No testbench files found"
endif

# CI/CD Integration
.PHONY: ci-test
ci-test: validate lint test
	@echo "✅ CI/CD test pipeline complete"

.PHONY: ci-build
ci-build: synthesize reports
	@echo "✅ CI/CD build pipeline complete"

.PHONY: ci-deploy
ci-deploy: implement
	@echo "✅ CI/CD deploy pipeline complete"

# Development helpers
.PHONY: dev-setup
dev-setup: setup
	@echo "🛠️  Setting up development environment..."
	@$(PYTHON) $(SCRIPT_DIR)/utils/setup_environment.py --dev
	@echo "✅ Development environment ready"

.PHONY: quick-test
quick-test: lint sim-unit
	@echo "✅ Quick test complete"

# Make sure intermediate files are not deleted
.PRECIOUS: $(BUILD_DIR)/%.rpt $(BUILD_DIR)/%.log

# Include platform-specific extensions if they exist
-include Makefile.$(DETECTED_OS)

# Help for specific targets
help-%:
	@echo "Help for target '$*':"
	@$(MAKE) -s $* --dry-run 2>/dev/null | head -5 || echo "No help available for '$*'"