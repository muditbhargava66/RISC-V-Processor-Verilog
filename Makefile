# RISC-V Processor build and verification entry points
#
# Override VIVADO when it is installed elsewhere, for example:
#   make VIVADO="C:/Xilinx/Vivado/2023.2/bin/vivado.bat" test-system

VIVADO ?= C:/Xilinx/Vivado/2023.2/bin/vivado.bat
VIVADO_BATCH = "$(VIVADO)" -mode batch

.DEFAULT_GOAL := help

.PHONY: help lint \
	test-system test-alu test-control test-memory test-regfile test-compliance \
	test-benchmark test-formal test-all \
	create-project create-project-minimal create-project-jtag \
	synthesize implement-minimal implement-jtag build-all status clean-build

help:
	@echo RISC-V Processor build and verification flow
	@echo.
	@echo Verification:
	@echo   lint                  - Synthesize the core as an elaboration check
	@echo   test-system           - Run the self-checking processor program
	@echo   test-alu              - Run ALU unit tests
	@echo   test-control          - Run control-unit tests
	@echo   test-memory           - Run instruction/data-memory tests
	@echo   test-regfile          - Run register-file tests
	@echo   test-compliance       - Run targeted ISA smoke checks
	@echo   test-benchmark        - Run the bounded smoke-program metric report
	@echo   test-formal           - Run SystemVerilog assertion simulation (tool-dependent)
	@echo   test-all              - Run deterministic regression tests (excludes assertions)
	@echo.
	@echo FPGA flow:
	@echo   create-project        - Create/reuse the core synthesis project
	@echo   create-project-minimal- Create/reuse the Basys3 minimal wrapper project
	@echo   create-project-jtag   - Create/reuse the debug-signal wrapper project
	@echo   synthesize            - Synthesize the unconstrained core and write reports
	@echo   implement-minimal     - Implement and write a minimal-wrapper bitstream
	@echo   implement-jtag        - Implement and write a debug-wrapper bitstream
	@echo   build-all             - Implement both FPGA wrappers
	@echo.
	@echo Maintenance:
	@echo   status                - Show the working-tree state
	@echo   clean-build           - Remove only ignored build/ outputs
	@echo.
	@echo All generated projects, simulations, reports, and bitstreams live under build/.

lint:
	$(VIVADO_BATCH) -source scripts/quick_lint_check.tcl

test-system:
	$(VIVADO_BATCH) -source scripts/run_simulation.tcl -tclargs system

test-alu:
	$(VIVADO_BATCH) -source scripts/run_simulation.tcl -tclargs alu

test-control:
	$(VIVADO_BATCH) -source scripts/run_simulation.tcl -tclargs control

test-memory:
	$(VIVADO_BATCH) -source scripts/run_simulation.tcl -tclargs memory

test-regfile:
	$(VIVADO_BATCH) -source scripts/run_simulation.tcl -tclargs regfile

test-compliance:
	$(VIVADO_BATCH) -source scripts/run_simulation.tcl -tclargs compliance

test-benchmark:
	$(VIVADO_BATCH) -source scripts/run_simulation.tcl -tclargs benchmark

test-formal:
	$(VIVADO_BATCH) -source scripts/run_simulation.tcl -tclargs formal

test-all: test-system test-alu test-control test-memory test-regfile test-compliance test-benchmark

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

build-all: implement-minimal implement-jtag

status:
	@git status --short --branch

clean-build:
	@powershell -NoProfile -ExecutionPolicy Bypass -File scripts/clean.ps1
