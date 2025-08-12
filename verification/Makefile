# RISC-V Processor Verification Makefile
# Production-ready test automation

# Configuration
PYTHON := python3
SIMULATOR := xsim
PROJECT_ROOT := ..
SCRIPTS_DIR := scripts
RESULTS_DIR := results
COVERAGE_DIR := coverage

# Default target
.PHONY: all
all: unit-tests

# Clean previous results
.PHONY: clean
clean:
	@echo "🧹 Cleaning verification results..."
	rm -rf $(RESULTS_DIR)/*
	rm -rf $(COVERAGE_DIR)/*
	rm -rf temp_proj/
	rm -rf work/
	rm -rf *.log *.wlf *.vstf
	@echo "✅ Clean completed"

# Run all unit tests
.PHONY: unit-tests
unit-tests: clean
	@echo "🚀 Running unit test suite..."
	$(PYTHON) $(SCRIPTS_DIR)/run_unit_tests.py --simulator $(SIMULATOR)

# Run unit tests in parallel
.PHONY: unit-tests-parallel
unit-tests-parallel: clean
	@echo "🚀 Running unit tests in parallel..."
	$(PYTHON) $(SCRIPTS_DIR)/run_unit_tests.py --simulator $(SIMULATOR) --parallel

# Run unit tests with coverage
.PHONY: unit-tests-coverage
unit-tests-coverage: clean
	@echo "🚀 Running unit tests with coverage..."
	$(PYTHON) $(SCRIPTS_DIR)/run_unit_tests.py --simulator $(SIMULATOR) --coverage

# Run specific unit test
.PHONY: test-alu
test-alu: clean
	@echo "🧪 Testing ALU..."
	$(PYTHON) $(SCRIPTS_DIR)/run_unit_tests.py --test alu_tb --simulator $(SIMULATOR)

.PHONY: test-regfile
test-regfile: clean
	@echo "🧪 Testing Register File..."
	$(PYTHON) $(SCRIPTS_DIR)/run_unit_tests.py --test register_file_tb --simulator $(SIMULATOR)

.PHONY: test-control
test-control: clean
	@echo "🧪 Testing Control Unit..."
	$(PYTHON) $(SCRIPTS_DIR)/run_unit_tests.py --test control_unit_tb --simulator $(SIMULATOR)

.PHONY: test-imm-gen
test-imm-gen: clean
	@echo "🧪 Testing Immediate Generator..."
	$(PYTHON) $(SCRIPTS_DIR)/run_unit_tests.py --test immediate_generator_tb --simulator $(SIMULATOR)

.PHONY: test-pc
test-pc: clean
	@echo "🧪 Testing Program Counter..."
	$(PYTHON) $(SCRIPTS_DIR)/run_unit_tests.py --test program_counter_tb --simulator $(SIMULATOR)

.PHONY: test-branch
test-branch: clean
	@echo "🧪 Testing Branch Unit..."
	$(PYTHON) $(SCRIPTS_DIR)/run_unit_tests.py --test branch_unit_tb --simulator $(SIMULATOR)

# Run system-level tests (placeholder)
.PHONY: system-tests
system-tests:
	@echo "🏗️  System tests not yet implemented"
	@echo "    Will test full processor integration"

# Run integration tests (placeholder)
.PHONY: integration-tests
integration-tests:
	@echo "🔗 Integration tests not yet implemented"
	@echo "    Will test module interactions"

# Generate reports
.PHONY: reports
reports:
	@echo "📊 Generating verification reports..."
	@if [ -f $(RESULTS_DIR)/unit_test_report.json ]; then \
		echo "✅ Unit test report available: $(RESULTS_DIR)/unit_test_report.json"; \
	else \
		echo "❌ No unit test results found. Run 'make unit-tests' first."; \
	fi

# Setup verification environment
.PHONY: setup
setup:
	@echo "🔧 Setting up verification environment..."
	mkdir -p $(RESULTS_DIR)
	mkdir -p $(COVERAGE_DIR)
	mkdir -p testbenches/unit
	mkdir -p testbenches/integration
	mkdir -p testbenches/system
	@echo "✅ Verification environment ready"

# Help target
.PHONY: help
help:
	@echo "RISC-V Processor Verification Makefile"
	@echo "======================================"
	@echo ""
	@echo "Available targets:"
	@echo "  all              - Run all unit tests (default)"
	@echo "  unit-tests       - Run all unit tests sequentially"
	@echo "  unit-tests-parallel - Run unit tests in parallel"
	@echo "  unit-tests-coverage - Run unit tests with coverage"
	@echo ""
	@echo "Individual unit tests:"
	@echo "  test-alu         - Test ALU module"
	@echo "  test-regfile     - Test Register File module"
	@echo "  test-control     - Test Control Unit module"
	@echo "  test-imm-gen     - Test Immediate Generator module
  test-pc          - Test Program Counter module
  test-branch      - Test Branch Unit module"
	@echo ""
	@echo "Other targets:"
	@echo "  system-tests     - Run system-level tests (TBD)"
	@echo "  integration-tests - Run integration tests (TBD)"
	@echo "  reports          - Generate verification reports"
	@echo "  setup            - Setup verification environment"
	@echo "  clean            - Clean all generated files"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Configuration:"
	@echo "  SIMULATOR=$(SIMULATOR)  - Simulation tool (xsim, modelsim)"
	@echo "  PYTHON=$(PYTHON)        - Python interpreter"
	@echo ""
	@echo "Examples:"
	@echo "  make unit-tests SIMULATOR=modelsim"
	@echo "  make test-alu"
	@echo "  make unit-tests-parallel"

# Continuous Integration target
.PHONY: ci
ci: clean unit-tests-coverage reports
	@echo "🤖 CI verification pipeline completed"

# Development workflow
.PHONY: dev
dev: test-alu test-regfile
	@echo "🛠️  Development verification completed"