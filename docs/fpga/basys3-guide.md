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
| `src/alu.sv` | ALU with M-extension |
| `src/control_unit.sv` | Instruction decode |
| `src/register_file.sv` | 32x32 register file |
| `src/program_counter.sv` | PC with branch/jump |
| `src/immediate_generator.sv` | Immediate extraction |
| `src/instruction_memory.sv` | I-MEM (1KB) |
| `src/data_memory.sv` | D-MEM (1KB) |
| `src/control_unit.sv` | Control logic |
| `src/riscv_processor.sv` | Core processor |
| `src/riscv_processor_minimal.sv` | Minimal wrapper |

### Pin Constraints (XDC)

```tcl
# Clock: 50 MHz (20ns period) - derived from 100 MHz with clock divider
# or use 100 MHz directly with tighter timing
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} [get_ports clk]

# Reset button (active high)
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

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
set_property PACKAGE_PIN P3  [get_ports {pc_debug[11]}]
set_property PACKAGE_PIN N3  [get_ports {pc_debug[13]}]
set_property PACKAGE_PIN P1  [get_ports {pc_debug[14]}]
set_property PACKAGE_PIN L1  [get_ports {pc_debug[15]}]

set_property IOSTANDARD LVCMOS33 [get_ports {pc_debug[*]}]

# Timing constraints
set_input_delay -clock sys_clk_pin -min 0.500 [get_ports reset]
set_input_delay -clock sys_clk_pin -max 2.000 [get_ports reset]

set_output_delay -clock sys_clk_pin -min 0.500 [get_ports {pc_debug[*]}]
set_output_delay -clock sys_clk_pin -max 3.000 [get_ports {pc_debug[*]}]

set_false_path -to [get_ports {pc_debug[*]}]

set_clock_uncertainty -setup 0.100 [get_clocks sys_clk_pin]
set_clock_uncertainty -hold 0.050 [get_clocks sys_clk_pin]

set_max_delay -from [get_clocks sys_clk_pin] -to [get_clocks sys_clk_pin] 19.500

# I/O voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
```

## Clock Strategy

The design uses a **single clock domain** at 50 MHz:

- **Basys3 oscillator**: 100 MHz
- **Design clock**: 50 MHz (derived from 100 MHz via MMCM or direct use with 20ns period)
- **Rationale**: Single-cycle design needs longer period for critical path

### Option 1: Use 100 MHz with 20ns constraint
```tcl
create_clock -period 10.000 -name sys_clk_pin [get_ports clk]
set_max_delay -from [get_clocks sys_clk_pin] -to [get_clocks sys_clk_pin] 9.500
```

### Option 2: Use 50 MHz (recommended)
```tcl
create_clock -period 20.000 -name sys_clk_pin [get_ports clk]
set_max_delay -from [get_clocks sys_clk_pin] -to [get_clocks sys_clk_pin] 19.500
```

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
build/vivado/riscv_processor_minimal/riscv_processor_minimal.bit
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
set_property PROGRAM.FILE {build/vivado/riscv_processor_minimal/riscv_processor_minimal.bit} [current_hw_device]
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

## Resource Utilization (Typical)

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUTs | ~4,100 | 20,800 | 19.7% |
| FFs | ~8,400 | 41,600 | 20.2% |
| DSPs | 2 | 90 | 2.2% |
| BRAM | 0 | 50 | 0% |
| I/O | 18 | 88 | 20.5% |

## Related Documents
- [JTAG Debug Build](jtag-debug.md)
- [Timing Analysis](timing.md)
- [Power Analysis](power.md)
- [Bitstream Generation](bitstream.md)