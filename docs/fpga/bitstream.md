# Bitstream Generation Guide

## Overview

Bitstream generation creates the configuration file for programming the FPGA.

## Generation Flow

### Via Make
```bash
make implement-minimal
# Bitstream: build/vivado/riscv_processor_minimal/riscv_processor_minimal.bit
```

### Manual Steps
```tcl
open_run impl_1
write_bitstream -force riscv_processor_minimal.bit
```

## Bitstream Options

### Key Options
```tcl
# Compression (reduces size ~30-50%)
write_bitstream -force -compress riscv_processor_minimal.bit

# Encryption (requires key)
write_bitstream -force -encrypt -keyfile key.nky riscv_processor_minimal.bit

# CRC verification
write_bitstream -force -crc enable riscv_processor_minimal.bit

# Startup clock
write_bitstream -force -startup_clk cclk riscv_processor_minimal.bit
```

### Recommended Options
```tcl
write_bitstream -force -compress -crc enable theAI assistant to continue statements are not allowed in Tcl
```
```tcl
write_bitstream -force -compress -crc enable riscv_processor_minimal.bit
```

## Bitstream Configuration

### Startup Options
| Option | Description | Default |
|--------|-------------|---------|
| `-startup_clk cclk` | Use CCLK for startup | JTAG clock |
| `-disable_auto_crc` | Disable CRC check | CRC enabled |
| `-compress` | Compress bitstream | Uncompressed |
| `-encrypt` | AES encryption | Disabled |

### Configuration Memory
| Parameter | Value |
|-----------|-------|
| Device | XC7A35T |
| Package | CPG236 |
| Bitstream Size | ~2.5 MB (compressed ~1.3 MB) |
| Configuration Time | ~100 ms @ 50 MHz CCLK |

## Programming Methods

### 1. JTAG (Vivado Hardware Manager)
```bash
# Via Make
make implement-minimal

# Manual
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

### 2. Quad SPI Flash (Permanent)
```tcl
# Generate MCS file
write_cfgmem -force -format mcs -interface spix4 -size 16 \
  -loadbit "up 0 build/vivado/riscv_processor_minimal/riscv_processor_minimal.bit" \
  riscv_processor_minimal.mcs

# Program flash
open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
program_hw_devices -cfgmem -force \
  -cfgmem_part {mt25ql128-spi-x1_x2_x4} \
  -file riscv_processor_minimal.mcs \
  [current_hw_device]
```

### 3. USB-JTAG Cable (Digilent)
```bash
# Using djtgcfg (Digilent)
djtgcfg prog -d Basys3 -i 0 -f build/vivado/riscv_processor_minimal/riscv_processor_minimal.bit
```

## Bitstream Verification

### CRC Check
```bash
# Vivado reports CRC in bitstream generation log
grep "CRC" build/vivado/riscv_processor_minimal/riscv_processor_minimal.runs/impl_1/runme.log
```

### Readback Verification
```tcl
open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
verify_hw_devices [current_hw_device]
```

## Bitstream Security

### Encryption
```tcl
# Generate encryption key
write_bitstream -force -encrypt -keyfile design.nky riscv_processor_minimal.bit

# Program encrypted bitstream
write_cfgmem -force -format mcs -interface spix4 \
  -encrypt -keyfile design.nky \
  -loadbit "up 0 riscv_processor_minimal.bit" \
  riscv_processor_minimal.mcs
```

### Readback Protection
```tcl
# Disable readback
set_property BITSTREAM.CONFIG.READBACK_DISABLE 1 [current_design]

# Disable JTAG after configuration
set_property BITSTREAM.CONFIG.DISABLE_JTAG 1 [current_design]
```

## Multi-Boot Support

### Golden + Update Images
```tcl
# Golden image (fallback)
write_cfgmem -force -format mcs -interface spix4 \
  -loadbit "up 0 golden.bit" \
  -loadbit "up 1 update.bit" \
  golden_update.mcs

# MultiBoot address (0x200000 for 2MB offset)
set_property BITSTREAM.CONFIG.NEXT_CONFIG_ADDR 0x200000 [current_design]
```

## Verification Checklist

- [ ] Bitstream generates without errors
- [ ] CRC check passes
- [ ] Bitstream size within device capacity
- [ ] JTAG programming succeeds
- [ ] Hardware boots and runs test program
- [ ] LEDs show expected PC sequence
- [ ] Reset button works correctly
- [ ] Multiple power cycles successful

## Related Documents
- [Basys3 Build Guide](basys3-guide.md)
- [Timing Analysis](timing.md)
- [Power Analysis](power.md)
- [JTAG Debug Build](jtag-debug.md)