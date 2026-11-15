# RISC-V Processor build and verification entry points
#
# Two flows are supported:
#   * Vivado (xsim + synthesis/implementation) - the default FPGA flow
#   * Open-source tools (Icarus Verilog / Verilator) - fast RTL regression
#
# Override VIVADO when it is installed elsewhere, for example:
#   make VIVADO="C:/Xilinx/Vivado/2023.2/bin/vivado.bat" test-system
# On WSL/Linux you can run the open-source flow with no Vivado installed:
#   make iv-all lint-verilator

VIVADO ?= C:/Xilinx/Vivado/2023.2/bin/vivado.bat
VIVADO_BATCH = "$(VIVADO)" -mode batch

IVERILOG ?= iverilog
VVP      ?= vvp
VERILATOR ?= verilator

# OS detection for portable blank-line echo (cmd.exe vs POSIX sh)
ifeq ($(OS),Windows_NT)
  BLANK := @echo.
  MKDIR_P = mkdir
else
  BLANK := @echo
  MKDIR_P = mkdir -p
endif

IVFLAGS = -g2012 -DIVERILOG
CORE_SRC = src/riscv_pkg.sv src/alu.sv src/control_unit.sv src/data_memory.sv \
           src/immediate_generator.sv src/instruction_memory.sv src/program_counter.sv \
           src/register_file.sv src/divider.sv src/riscv_processor.sv
IV_BUILD = build/iverilog

.DEFAULT_GOAL := help

.PHONY: help lint lint-verilator \
	test-system test-alu test-control test-memory test-regfile test-immgen test-pc test-divider \
	test-compliance test-benchmark test-formal test-all \
	iv-system iv-alu iv-control iv-memory iv-regfile iv-immgen iv-pc iv-divider iv-compliance iv-all \
	create-project create-project-minimal create-project-jtag \
	synthesize implement-minimal implement-jtag full-core build-all status clean-build

help:
	$(BLANK)
	@echo RISC-V Processor build and verification flow
	$(BLANK)
	@echo Vivado verification:
	@echo   lint                  - Synthesize the core as an elaboration check
	@echo   test-system           - Run the self-checking processor program
	@echo   test-alu              - Run ALU unit tests (RV32I + RV32M)
	@echo   test-control          - Run control-unit tests
	@echo   test-memory           - Run instruction/data-memory tests
	@echo   test-regfile          - Run register-file tests
	@echo   test-immgen           - Run immediate-generator tests
	@echo   test-pc               - Run program-counter tests
	@echo   test-divider          - Run multi-cycle divider tests (RV32M)
	@echo   test-compliance       - Run directed ISA compliance checks
	@echo   test-benchmark        - Run the bounded smoke-program metric report
	@echo   test-formal           - Run SystemVerilog assertion simulation
	@echo   test-all              - Run deterministic regression tests
	$(BLANK)
	@echo Open-source verification (no Vivado required):
	@echo   iv-all                - Run all directed tests with Icarus Verilog
	@echo   iv-system / iv-alu / iv-control / iv-memory / iv-regfile
	@echo   iv-immgen / iv-pc / iv-divider / iv-compliance
	@echo   lint-verilator        - Lint the core with Verilator
	$(BLANK)
	@echo FPGA flow:
	@echo   create-project        - Create/reuse the core synthesis project
	@echo   create-project-minimal- Create/reuse the Basys3 minimal wrapper project
	@echo   create-project-jtag   - Create/reuse the debug-signal wrapper project
	@echo   synthesize            - Synthesize the unconstrained core and write reports
	@echo   implement-minimal     - Implement and write a minimal-wrapper bitstream
	@echo   implement-jtag        - Implement and write a debug-wrapper bitstream
	@echo   full-core             - Characterize the full core (synth+impl, all debug ports)
	@echo   build-all             - Implement both FPGA wrappers
	$(BLANK)
	@echo Maintenance:
	@echo   status                - Show the working-tree state
	@echo   clean-build           - Remove only ignored build/ outputs
	$(BLANK)
	@echo All generated projects, simulations, reports, and bitstreams live under build/.

# ---------------------------------------------------------------------------
# Vivado flow
# ---------------------------------------------------------------------------
lint:
	$(VIVADO_BATCH) -source scripts/quick_lint_check.tcl

# Vivado simulation followed by an external xsim-log check. The check runs in
# make's shell after Vivado returns, so it still catches failures when xsim fails
# to launch and terminates the Vivado batch early with exit code 0.
define run_vsim
	$(VIVADO_BATCH) -source scripts/run_simulation.tcl -tclargs $(1)
	@bash scripts/check_sim_log.sh $(1)
endef

test-system: ; $(call run_vsim,system)

test-alu: ; $(call run_vsim,alu)

test-control: ; $(call run_vsim,control)

test-memory: ; $(call run_vsim,memory)

test-regfile: ; $(call run_vsim,regfile)

test-immgen: ; $(call run_vsim,immgen)

test-pc: ; $(call run_vsim,pc)

test-divider: ; $(call run_vsim,divider)

test-compliance: ; $(call run_vsim,compliance)

test-benchmark: ; $(call run_vsim,benchmark)

test-formal: ; $(call run_vsim,formal)

test-all: test-system test-alu test-control test-memory test-regfile test-immgen test-pc test-divider test-compliance

create-project:
	$(VIVADO_BATCH) -source scripts/build_vivado.tcl -tclargs core

create-project-minimal:
	$(VIVADO_BATCH) -source scripts/build_vivado.tcl -tclargs minimal

create-project-jtag:
	$(VIVADO_BATCH) -source scripts/build_vivado.tcl -tclargs jtag

synthesize:
	$(VIVADO_BATCH) -source scripts/run_synthesis_impl.tcl -tclargs core

implement-minimal:
	$(VIVADO_BATCH) -source scripts/run_synthesis_impl.tcl -tclargs minimal

implement-jtag:
	$(VIVADO_BATCH) -source scripts/run_synthesis_impl.tcl -tclargs jtag

# Full-core characterization: synth + impl of the complete core (all debug ports)
# on xc7a35tfgg484-1 (same xc7a35t die/-1 as Basys3, larger package for 241 I/O).
# Reports only, no bitstream. See scripts/run_full_core.tcl.
full-core:
	$(VIVADO_BATCH) -source scripts/run_full_core.tcl

build-all: implement-minimal implement-jtag

status:
	@git status --short --branch

clean-build:
	@powershell -NoProfile -ExecutionPolicy Bypass -File scripts/clean.ps1

# ---------------------------------------------------------------------------
# Open-source flow (Icarus Verilog / Verilator)
# ---------------------------------------------------------------------------
define run_iv
	@$(MKDIR_P) $(IV_BUILD)
	$(IVERILOG) $(IVFLAGS) -o $(IV_BUILD)/$(1).vvp -s $(1) $(CORE_SRC) $(2)
	$(VVP) $(IV_BUILD)/$(1).vvp
endef

iv-system: ; $(call run_iv,riscv_processor_tb,testbenches/riscv_processor_tb.sv)
iv-alu: ; $(call run_iv,alu_tb,testbenches/alu_tb.sv)
iv-control: ; $(call run_iv,control_unit_tb,testbenches/control_unit_tb.sv)
iv-memory: ; $(call run_iv,memory_tb,testbenches/memory_tb.sv)
iv-regfile: ; $(call run_iv,register_file_tb,testbenches/register_file_tb.sv)
iv-immgen: ; $(call run_iv,immediate_generator_tb,testbenches/immediate_generator_tb.sv)
iv-pc: ; $(call run_iv,program_counter_tb,testbenches/program_counter_tb.sv)
iv-divider: ; $(call run_iv,divider_tb,testbenches/divider_tb.sv)
iv-compliance: ; $(call run_iv,compliance_tests,verification/compliance_tests.sv)

iv-all: iv-system iv-alu iv-control iv-memory iv-regfile iv-immgen iv-pc iv-divider iv-compliance

lint-verilator:
	$(VERILATOR) --lint-only -Wall --assert --top-module riscv_processor \
		-Wno-UNUSEDPARAM -Wno-UNUSEDSIGNAL -Wno-DECLFILENAME \
		$(CORE_SRC)