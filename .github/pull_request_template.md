## Description

<!-- What does this PR change and why? Link the related issue(s). -->

Closes #

## Type of change

- [ ] Bug fix (RTL correctness, toolchain, or build flow)
- [ ] New feature / instruction / module
- [ ] Verification (testbench, compliance, formal)
- [ ] FPGA implementation (constraints, clocking, debug IP)
- [ ] Documentation
- [ ] Refactor / cleanup (no functional change)

## Area affected

- [ ] Core RTL (`src/`)
- [ ] Testbenches / verification (`testbenches/`, `verification/`)
- [ ] Build scripts / constraints (`scripts/`, `constraints/`)
- [ ] Benchmarks (`benchmarks/`)
- [ ] Docs (`docs/`, `README.md`, `CHANGELOG.md`)
- [ ] CI / repo metadata (`.github/`)

## Verification evidence

<!-- Paste real results. Do not claim a check passed unless you actually ran it.
     For RTL changes, the directed regression and lint are the minimum gate. -->

| Check | Command | Result |
|-------|---------|--------|
| Directed tests | `make iv-all` (or `make test-all` with Vivado) | |
| Verilator lint | `make lint-verilator` | |
| Compliance harness | `make test-compliance` | |
| Formal (if SVA / properties touched) | `sby -f verification/formal.sby` | |
| Synthesis (if RTL / constraints touched) | `make synthesize` | |
| Implementation (if FPGA flow touched) | `make implement-minimal` | |

- Tool version(s): <!-- e.g. Icarus Verilog 12.0, Verilator 5.x, Vivado 2023.2 -->
- Post-route timing (if implemented): WNS / WHS / TNS / THS = <!-- from build/reports/ -->

## Checklist

- [ ] RTL changes are covered by a directed test or a formal property
- [ ] Self-checking testbenches `$fatal` on failure (exit code reflects the result)
- [ ] No new lint warnings (or justified in the description)
- [ ] Constraints / clocking updated if the change affects FPGA timing or CDC
- [ ] Docs / CHANGELOG updated for user-visible changes
- [ ] No generated artifacts committed (`build/`, `*.bit`, `*.log`, `.idea/`)

## Notes for reviewers

<!-- Anything subtle: RISC-V ISA spec references, timing trade-offs, known
     limitations, or follow-up work deferred to a later version. -->