# Proof Strategies

## Overview

This guide covers strategies for formal verification of the RISC-V processor using SymbiYosys.

## Proof Approaches

### 1. Bounded Model Checking (BMC)
- **Engine**: `smtbmc`
- **Mode**: `bmc`
- **Depth**: 30-50 cycles
- **Best for**: Finding counterexamples, bug hunting
- **Completeness**: Bounded (up to depth)

### 2. Property Directed Reachability (PDR)
- **Engine**: `abc pdr`
- **Mode**: `prove`
- **Depth**: Unbounded (inductive)
- **Best for**: Full proofs, finding invariants
- **Completeness**: Complete (if converges)

### 3. AIG-based BMC
- **Engine**: `aigbmc`
- **Mode**: `bmc`/`prove`
- **Best for**: Large designs, complement to SMT
- **Completeness**: Bounded

## Strategy Selection

| Goal | Recommended Engine | Configuration |
|------|-------------------|---------------|
| Quick bug finding | `smtbmc` (BMC) | Depth 30 |
| Full proof | `abc pdr` | Default |
| Large design | `aigbmc` | Default |
| Coverage | `smtbmc` (Cover) | Depth 30 |
| Regression | All three | Parallel |

## Proof Decomposition

### Decompose by Module

```bash
# Verify ALU separately
sby -f formal_alu.sby

# Verify Control Unit separately
sby -f formal_control.sby

# Verify Register File separately
sby -f formal_regfile.sby
```

### Decompose by Property Class

```ini
# formal_control.sby
[options]
mode prove
depth 50

[engines]
smtbmc
abc pdr

[script]
read_verilog -I ../src ../src/riscv_pkg.sv
read_verilog -I ../src ../src/control_unit.sv
# Add control unit assertions only

prep -top control_unit

[files]
../src/riscv_pkg.sv
../src/control_unit.sv
```

## Abstraction Techniques

### 1. Data Abstraction
```systemverilog
// Abstract 32-bit data to 8-bit for faster proof
`ifdef FORMAL_ABSTRACT
    typedef logic [7:0] data_t;
`else
    typedef logic [31:0] data_t;
`endif
```

### 2. Memory Abstraction
```systemverilog
// Replace memory with uninterpreted functions
`ifdef FORMAL_MEM_ABS
    function logic [31:0] mem_read(input logic [7:0] addr);
    function void mem_write(input logic [7:0] addr, input logic [31:0] data);
`else
    logic [31:0] memory [0:255];
`endif
```

### 3. Counter Abstraction
```systemverilog
// Abstract PC to 8-bit for control flow proofs
`ifdef FORMAL_PC_ABS
    typedef logic [7:0] pc_t;
`else
    typedef logic [31:0] pc_t;
`endif
```

## Induction Strategies

### k-Induction
```ini
[options]
mode prove
depth 20
induction on
```

### Invariant Strengthening
```systemverilog
// Add auxiliary invariants to help induction
// synthesis translate_off
assert property (@(posedge clk) disable iff (reset)
    (reg_write && write_reg != 0) |-> (write_reg < 32));
// synthesis translate_on
```

### Auxiliary Lemmas
```systemverilog
// Lemma: PC always increments by 4 for non-control-flow
// synthesis translate_off
assert property (@(posedge clk) disable iff (reset)
    (!branch_taken && !jump) |=> (pc_current == $past(pc_current) + 4));
// synthesis translate_on
```

## Handling Complex Properties

### Break Down Complex Properties
```systemverilog
// Instead of one complex property:
property complex_property;
    @(posedge clk) disable iff (reset)
    (condition_a && condition_b && condition_c) |-> (result == expected);
endproperty

// Split into simpler properties:
property part_a;
    @(posedge clk) disable iff (reset)
    condition_a |-> intermediate_a;
endproperty

property part_b;
    @(posedge clk) disable iff (reset)
    condition_b && intermediate_a |-> intermediate_b;
endproperty

property part_c;
    @(posedge clk) disable iff (reset)
    condition_c && intermediate_b |-> (result == expected);
endproperty
```

### Use Auxiliary Signals
```systemverilog
// Add ghost signals for complex conditions
// synthesis translate_off
logic alu_operation_valid;
assign alu_operation_valid = (alu_op inside {ALU_ADD, ALU_SUB, ...});
// synthesis translate_on

assert property (@(posedge clk) disable iff (reset)
    alu_operation_valid);
```

## Handling Failures

### Counterexample Analysis
1. **Open trace**: `gtkwave engine_0/trace.vcd`
2. **Identify failing cycle**: Look for assertion failure
3. **Trace inputs**: Check input values at failure
3. **Check assumptions**: Verify assumptions hold

### Common Failure Patterns

| Pattern | Cause | Fix |
|---------|-------|-----|
| Assertion fails at reset | Property checks during reset | Add `disable iff (reset)` |
| Property fails at cycle 0 | Initial state violation | Add initial assumptions |
| Induction fails at step k | Missing invariant | Add auxiliary invariant |
| Property vacuously true | Antecedent never true | Check coverage |

### Strengthening Invariants

```systemverilog
// Add intermediate invariants to help induction
// synthesis translate_off
// Invariant: PC always word-aligned
assert property (@(posedge clk) disable iff (reset) (pc_current[1:0] == 2'b00));
// synthesis translate_on

// Invariant: x0 always zero
assert property (@(posedge clk) disable iff (reset) 
    (reg_write && write_reg == 0) |-> 1'b0);
// synthesis translate_on
```

## Performance Optimization

### Reduce State Space
1. **Abstract data widths**: 32-bit → 8-bit
2. **Abstract memories**: Replace with UF
3. **Bound loops**: Add `assume` for loop bounds
4. **Remove irrelevant logic**: Use `// synthesis translate_off`

### Engine Selection
```ini
# For control-heavy designs
[engines]
smtbmc
abc pdr

# For datapath-heavy designs
[engines]
aigbmc
smtbmc
```

### Parallel Execution
```bash
# Run engines in parallel
sby -f formal.sby -j 4

# Distributed across machines
sby -f formal.sby --remote host1,host2,host3
```

## Regression Testing

### CI Integration
```yaml
# .github/workflows/formal.yml
name: Formal Verification
on: [push, pull_request]
jobs:
  formal:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install tools
        run: |
          pip install symbiyosys
          sudo apt-get install -y yosys yices2 z3
      - name: Run formal
        run: |
          cd verification
          sby -f formal.sby
```

### Regression Checks
```bash
#!/bin/bash
# regression.sh
set -e

echo "Running formal verification..."
sby -f formal.sby
sby -f formal_bmc.sby
sby -f formal_cover.sby

echo "All formal checks passed!"
```

## Related Documents
- [SymbiYosys Setup](symbiyosys.md)
- [SVA Properties](sva-properties.md)
- [Coverage Collection](coverage.md)
- [Verification Guide](../verification/verification-guide.md)