# Basys3 FPGA Implementation Guide

## Target Platform

- **Board**: Digilent Basys3
- **FPGA**: Xilinx Artix-7 XC7A35T-CPG236-1
- **Clock**: 100 MHz on-board oscillator (pin W5)
- **Reset**: Push button BTNC (pin U18)
- **LEDs**: 16 user LEDs (LD0-LD15)

## Build Flow

### Using Make (Recommended)

```bash
# Create project
make create-project-minimal

# Synthesize core
make synthesize

# Full implementation with bitstream
make implement-minimal
```

### Using Vivado Directly

```bash
# Create project
vivado -mode batch -source scripts/build_vivado.tcl -tclargs minimal

# Synthesize and implement
vivado -mode batch -source scripts/run_synthesis_impl.tcl -tclargs minimal
```

## Project Structure

```
build/vivado/riscv_processor_minimal/
├── riscv_processor_minimal.xpr          # Project file
├── riscv_processor_minimal.runs/
│   ├── synth_1/                         # Synthesis run
│   │   ├── runme.log                    # Synthesis log
│   │   └── riscv_processor_minimal.dcp  # Synthesized checkpoint
│   └── impl_1/                          # Implementation run
│       ├── runme.log                    # Implementation log
│       ├── riscv_processor_minimal.dcp  # Implemented checkpoint
│       └── riscv_processor_minimal.bit  # Generated bitstream
└── riscv_processor_minimal.cache/       # Cache files
```

## Source Files

The minimal wrapper uses only the core processor with minimal I/O:

| File | Purpose |
|------|---------|
| `src/riscv_pkg.sv` | Common package |
| `src/alu.sv` | ALU (base RV32I + RV32M multiply) |
| `src/divider.sv` | RV32M sequential divide/remainder |
| `src/control_unit.sv` | Instruction decode + control |
| `src/register_file.sv` | 32x32 register file |
| `src/program_counter.sv` | PC with branch/jump + hold |
| `src/immediate_generator.sv` | Immediate extraction |
| `src/instruction_memory.sv` | I-MEM (1KB) |
| `src/data_memory.sv` | D-MEM (1KB) |
| `src/riscv_processor.sv` | Core processor |
| `src/riscv_processor_minimal.sv` | Minimal wrapper |

### Pin Constraints (XDC)

```tcl
# Board clock: 100 MHz oscillator (pin W5)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin [get_ports clk]

# Generated 50 MHz core clock from the toggle-flop + BUFG divider in the wrapper
create_generated_clock -name clk_core -source [get_ports clk] -divide_by 2 [get_pins u_clkbuf/O]

# Reset button (active high, async) - synchronized in the wrapper
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]
set_false_path -from [get_ports reset]

# PC Debug LEDs (16 bits)
set_property PACKAGE_PIN U16 [get_ports {pc_debug[0]}]
set_property PACKAGE_PIN E19 [get_ports {pc_debug[1]}]
set_property PACKAGE_PIN U19 [get_ports {pc_debug[2]}]
set_property PACKAGE_PIN V19 [get_ports {pc_debug[3]}]
set_property PACKAGE_PIN W18 [get_ports {pc_debug[4]}]
set_property PACKAGE_PIN U15 [get_ports {pc_debug[5]}]
set_property PACKAGE_PIN U14 [get_ports {pc_debug[6]}]
set_property PACKAGE_PIN V14 [get_ports {pc_debug[7]}]
set_property PACKAGE_PIN V13 [get_ports {pc_debug[8]}]
set_property PACKAGE_PIN V3  [get_ports {pc_debug[9]}]
set_property PACKAGE_PIN W3  [get_ports {pc_debug[10]}]
set_property PACKAGE_PIN U3  [get_ports {pc_debug[11]}]
set_property PACKAGE_PIN P3  [get_ports {pc_debug[12]}]
set_property PACKAGE_PIN N3  [get_ports {pc_debug[13]}]
set_property PACKAGE_PIN P1  [get_ports {pc_debug[14]}]
set_property PACKAGE_PIN L1  [get_ports {pc_debug[15]}]

set_property IOSTANDARD LVCMOS33 [get_ports {pc_debug[*]}]

# LEDs are asynchronous status outputs - no timing requirement
set_false_path -to [get_ports {pc_debug[*]}]

# Clock uncertainty on the core clock
set_clock_uncertainty -setup 0.100 [get_clocks clk_core]
set_clock_uncertainty -hold 0.050 [get_clocks clk_core]

# I/O voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
```

## Clock Strategy

The wrapper divides the 100 MHz board clock to a 50 MHz core clock:

- **Basys3 oscillator**: 100 MHz on pin W5 (`sys_clk_pin`).
- **Core clock**: 50 MHz (`clk_core`), produced by a toggle flop (`clk_div_reg`)
  followed by a `BUFG` (`u_clkbuf`) in the wrapper.
- **Why not BUFGCE_DIV / MMCM?**: `BUFGCE_DIV` is an UltraScale primitive and is
  not supported on Artix-7 (it fails implementation as a black box). A toggle
  flop + BUFG is the simple, supported divide-by-2; an MMCM/PLL would also work
  but is unnecessary for a fixed ÷2.
- **Rationale**: the single-cycle datapath's worst path (~15.9 ns) needs the
  20 ns core period; 50 MHz gives comfortable margin.

The XDC defines `create_clock` on the 100 MHz pin and a `create_generated_clock`
(`-divide_by 2`) on `u_clkbuf/O`, so timing is analyzed on the real 50 MHz core
clock. There is no "100 MHz with 20 ns" option — that would be contradictory.

## Build Steps

### 1. Create Project
```bash
make create-project-minimal
```

### 2. Synthesize
```bash
make synthesize
# or
vivado -mode batch -source scripts/run_synthesis_impl.tcl -tclargs minimal
```

### 3. Check Synthesis Reports
```bash
# Utilization
cat build/reports/utilization_minimal_synth.rpt

# Timing
cat build/reports/timing_minimal_synth.rpt
```

### 4. Implement
```bash
make implement-minimal
```

### 5. Check Implementation Reports
```bash
# Utilization
cat build/reports/utilization_minimal_impl.rpt

# Timing
cat build/reports/timing_minimal_impl.rpt

# Power
cat build/reports/power_minimal_impl.rpt

# DRC
cat build/reports/drc_minimal_impl.rpt
```

### 6. Generate Bitstream
Bitstream generated automatically in `implement-minimal`:
```
build/vivado/riscv_processor_minimal/riscv_processor_minimal.runs/impl_1/riscv_processor_minimal.bit
```

## Programming the Board

### Using Vivado Hardware Manager
1. Open Vivado
2. Open Hardware Manager
3. Connect to Basys3 via USB
3. Program device with `riscv_processor_minimal.bit`

### Using Command Line
```bash
vivado -mode batch -source - <<EOF
open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {build/vivado/riscv_processor_minimal/riscv_processor_minimal.runs/impl_1/riscv_processor_minimal.bit} [current_hw_device]
program_hw_devices [current_hw_device]
close_hw
EOF
```

## Verification on Hardware

### LED Pattern Interpretation
The 16 LEDs show the lower 16 bits of the Program Counter:
- **Sequential execution**: LEDs increment by 4 (0x0, 0x4, 0x8, 0xC...)
- **Branch taken**: LEDs jump to branch target
- **Jump**: LEDs jump to JAL/JALR target

### Expected Behavior
| Instruction | PC Sequence | LED Pattern |
|-------------|-------------|-------------|
| Sequential | +4 each cycle | Binary count by 4 |
| BLT taken | Jump to target | Sudden change |
| BGE not taken | +4 | Continue counting |
| JAL | Jump to target | Sudden change |
| JALR | Jump to register | Sudden change |

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Bitstream not generated | Implementation failed | Check `impl_1/runme.log` |
| Timing violation | Clock too fast | Increase period or reduce logic depth |
| LEDs static | Processor stalled | Check reset polarity, clock |
| DRC errors | Pin conflicts | Verify XDC pin assignments |
| Memory not initialized | Hex file missing | Verify `instruction_memory.hex` in project |

## Resource Utilization (verified v1.2.0 post-route)

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| Slice LUTs | 540 | 20,800 | 2.60% |
| — distributed RAM | 128 | 9,600 | 1.33% |
| FFs | 227 | 41,600 | 0.55% |
| DSPs | 0 | 90 | 0% |
| BRAM | 0 | 50 | 0% |
| BUFG | 2 | 32 | 6.25% |
| I/O | 18 | 106 | 16.98% |

Memories infer as distributed RAM (single-cycle async read); the RV32M
multiplier maps to LUTs/CARRY4, not DSP. See `build/reports/utilization_minimal_impl.rpt`.

## Related Documents
- [JTAG Debug Build](jtag-debug.md)
- [Timing Analysis](timing.md)
- [Power Analysis](power.md)
- [Bitstream Generation](bitstream.md)