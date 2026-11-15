# RISC-V Processor JTAG Debug Constraints File
# Minimal external I/O - most debugging via JTAG/ILA
# For Xilinx 7-series FPGA (Basys3 board)
#
# Clocking matches the minimal wrapper: 100 MHz board clock divided to a 50 MHz
# generated core clock. ILA/VIO debug cores are created by build_vivado.tcl.

# Board clock: 100 MHz oscillator
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin [get_ports clk]

# Generated 50 MHz core clock from the toggle-flop + BUFG divider in the wrapper
create_generated_clock -name clk_core -source [get_ports clk] -divide_by 2 [get_pins u_clkbuf/O]

# Reset button (asynchronous, active high) - synchronized in the wrapper
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]
set_false_path -from [get_ports reset]

# Status LEDs - 8 LEDs showing PC lower bits
set_property PACKAGE_PIN U16 [get_ports {status_leds[0]}]
set_property PACKAGE_PIN E19 [get_ports {status_leds[1]}]
set_property PACKAGE_PIN U19 [get_ports {status_leds[2]}]
set_property PACKAGE_PIN V19 [get_ports {status_leds[3]}]
set_property PACKAGE_PIN W18 [get_ports {status_leds[4]}]
set_property PACKAGE_PIN U15 [get_ports {status_leds[5]}]
set_property PACKAGE_PIN U14 [get_ports {status_leds[6]}]
set_property PACKAGE_PIN V14 [get_ports {status_leds[7]}]

# Status indicators - 2 additional LEDs
set_property PACKAGE_PIN V13 [get_ports processor_active]
set_property PACKAGE_PIN V3 [get_ports error_flag]

set_property IOSTANDARD LVCMOS33 [get_ports {status_leds[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports processor_active]
set_property IOSTANDARD LVCMOS33 [get_ports error_flag]

# Status outputs are asynchronous LEDs - no timing requirement
set_false_path -to [get_ports {status_leds[*]}]
set_false_path -to [get_ports processor_active]
set_false_path -to [get_ports error_flag]

# Clock uncertainty on the core clock
set_clock_uncertainty -setup 0.100 [get_clocks clk_core]
set_clock_uncertainty -hold 0.050 [get_clocks clk_core]

# I/O voltage configuration for bitstream generation
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# NOTE: dbg_hub / ILA clock properties are applied automatically by Vivado when
# the debug cores are inserted. They must NOT be set here in the XDC, because no
# debug core exists at constraint time (the previous get_debug_cores dbg_hub
# queries matched nothing and produced errors).