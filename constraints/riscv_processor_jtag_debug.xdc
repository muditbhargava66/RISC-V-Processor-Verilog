# RISC-V Processor JTAG Debug Constraints File
# Minimal external I/O - most debugging via JTAG/ILA
# For Xilinx 7-series FPGA (Basys3 board)

# Clock constraint - 50MHz for reliable timing
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} [get_ports clk]

# Reset button
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

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

# Timing constraints
set_input_delay -clock sys_clk_pin -min 0.500 [get_ports reset]
set_input_delay -clock sys_clk_pin -max 2.000 [get_ports reset]

# Output delay constraints for status signals
set_output_delay -clock sys_clk_pin -min 0.500 [get_ports {status_leds[*]}]
set_output_delay -clock sys_clk_pin -max 3.000 [get_ports {status_leds[*]}]
set_output_delay -clock sys_clk_pin -min 0.500 [get_ports processor_active]
set_output_delay -clock sys_clk_pin -max 3.000 [get_ports processor_active]
set_output_delay -clock sys_clk_pin -min 0.500 [get_ports error_flag]
set_output_delay -clock sys_clk_pin -max 3.000 [get_ports error_flag]

# Set false paths for status outputs to relax timing
set_false_path -to [get_ports {status_leds[*]}]
set_false_path -to [get_ports processor_active]
set_false_path -to [get_ports error_flag]

# Clock uncertainty
set_clock_uncertainty -setup 0.100 [get_clocks sys_clk_pin]
set_clock_uncertainty -hold 0.050 [get_clocks sys_clk_pin]

# Set maximum delay for internal paths
set_max_delay -from [get_clocks sys_clk_pin] -to [get_clocks sys_clk_pin] 19.500

# I/O voltage configuration for bitstream generation
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# Debug constraints for ILA
# These signals are marked with mark_debug attribute and will be captured by ILA
# No external pins required - all via JTAG

# ILA clock constraint - use system clock for debug
set_property C_CLK_INPUT_FREQ_HZ 50000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]

# Optional: Constrain debug nets to improve timing
# set_false_path -from [get_pins -hierarchical *debug*]
# set_false_path -to [get_pins -hierarchical *debug*]