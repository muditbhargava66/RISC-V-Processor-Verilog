# Verification guide

## Purpose and limits

This guide describes the checks that are present in the repository and how to interpret them. A passing directed simulation demonstrates the behavior covered by that testbench only. It is not, by itself, RISC-V certification, exhaustive proof, timing closure, or FPGA hardware validation.

The current release candidate is untagged v1.1.0 integration work. The only published Git tag is `v1.0.0`.

## Test image and working directories

The canonical system-test program is [instruction_memory.hex](../instruction_memory.hex). It is a 32-bit, one-word-per-line hexadecimal image with line 0 mapped to PC `0x00000000`.

The simulation and Vivado-project flows add that image explicitly. Do not rely on the shell's current directory to satisfy `$readmemh`. If a run prints an instruction-memory initialization warning, stop and correct the image configuration before interpreting any test result.

## Directed functional tests

Run commands from the repository root:

```powershell
make lint
make test-alu
make test-control
make test-regfile
make test-memory
make test-system
```

| Target | Testbench | Scope | Pass criterion |
|---|---|---|---|
| `lint` | Core RTL | Vivado compile/elaboration check | The tool reports no compile or elaboration error. This is not a simulation pass. |
| `test-alu` | `testbenches/alu_tb.v` | ALU operation vectors | All checked vectors pass. |
| `test-control` | `testbenches/Control_unit_tb.v` | Decoder outputs, including LUI/AUIPC | Every decoded vector matches the current control interface. |
| `test-regfile` | `testbenches/register_file_tb.v` | Register writes/reads and x0 behavior | All checks pass. |
| `test-memory` | `testbenches/memory_tb.v` | Instruction-image reads plus byte/halfword/word data accesses | All reads/writes are sampled away from the active clock edge and all checks pass. |
| `test-system` | `testbenches/riscv_processor_tb.v` | Demonstration image running through the core | Expected final register values pass. |

`make test-all` runs the maintained suite. Each testbench must provide its own pass/fail summary and terminate with no failure count. Preserve the console transcript or simulator log with the tool version when recording a release result.

To run an individual test without Make:

```powershell
vivado -mode batch -source scripts/run_simulation.tcl -tclargs system
```

Valid simulation target names are `system`, `alu`, `control`, `memory`, `regfile`, `compliance`, `formal`, and `benchmark`.

## Diagnostic checks (not release qualifications)

```powershell
make test-compliance
make test-formal
make test-benchmark
```

### Compliance smoke test

`verification/compliance_tests.v` observes a small number of events in the demonstration program. It does not run the RISC-V Architectural Test suite, does not establish instruction coverage, and may execute zero checks when the expected opcode is absent. Its pass percentage must be described as a **directed smoke-test result**, never as an RV32I compliance rate.

To claim RV32I conformance, add a documented RISC-V Architectural Test runner, specify the test-suite revision and target environment, and retain per-test pass/fail logs.

### Assertion simulation

`verification/riscv_processor_sva.sv` contains SystemVerilog assertions and cover properties. `test-formal` drives them in an ordinary simulator; it is assertion-based simulation, not formal model checking. A formal claim requires a solver-backed proof flow, assumptions/constraints, boundedness or induction settings, and proof/coverage artifacts.

### Benchmark

`benchmarks/performance_benchmark.v` is diagnostic. The original counter treats PC movement as an instruction-retirement signal and continues counting after the short demonstration program reaches uninitialized/zero memory. Any IPC, CPI, MIPS, or branch-prediction figure from it is therefore not a sustained processor measurement. Use a finite program with an explicit completion condition and a retirement counter before publishing performance data.

## Vivado checks

### RTL compile/elaboration

Use `make lint` for the core compilation/elaboration check. On systems where XSim is blocked by Windows Device Guard or another local policy, record that limitation explicitly; do not substitute a successful compile for an XSim result.

### Synthesis and implementation

The low-I/O `riscv_processor_minimal` wrapper is the baseline Basys3 implementation candidate:

```powershell
make synthesize
make implement-minimal
```

Generated files belong under ignored `build/`. The final report must state:

- Vivado release and FPGA part (`xc7a35tcpg236-1` in the supplied scripts)
- top module and XDC file
- exact program image used to initialize instruction memory
- synthesis and implementation status
- DRC result, worst setup/hold slack, and utilization

`riscv_processor` is a debug-rich core and is not a board top-level. The JTAG-marked wrapper has only `mark_debug` attributes today; it is not proof that an ILA/VIO core was inserted or that a hardware probe session works.

## Suggested release sequence

1. Begin from a clean, revision-controlled checkout and record `git rev-parse HEAD`.
2. Run `make lint` and `make test-all`; retain the directed unit/system logs.
3. Run `make synthesize` and `make implement-minimal` from a fresh build directory.
4. Inspect synthesis, implementation, timing, and DRC reports; fix warnings affecting memory initialization, constraints, or design correctness.
5. Program the target board and perform a small observable hardware test.
6. Only then add release claims and, if appropriate, create a version tag.

## Troubleshooting

| Symptom | Likely cause | Action |
|---|---|---|
| `$readmemh` cannot open the program image | The image was not added to the active run. | Use the unified flow and confirm it includes `instruction_memory.hex`; do not hand-copy a stale image. |
| System test reads zeros/X values | Image mismatch or initialization failure. | Confirm the image path and re-run the system test before investigating datapath behavior. |
| Memory test changes between runs | Stimulus is racing a clocked data-memory write. | Drive inputs before the active edge and sample only after it; keep reset connected. |
| Vivado cannot elaborate XSim | A local OS policy or Vivado installation is blocking simulator processes. | Record the error, resolve the local policy/tool issue, then re-run; compile-only output is insufficient. |
| Debug nets are visible in synthesis but no probe file exists | `mark_debug` alone does not constitute a validated debug flow. | Instantiate/configure debug IP or document the supported debug insertion flow, then generate and validate `.ltx`. |
