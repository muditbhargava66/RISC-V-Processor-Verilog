# RISC-V Processor Constraints File
# For Xilinx 7-series FPGA (Artix-7)

# Clock constraint
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

# Input/Output constraints
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# Debug output constraints (LEDs)
set_property PACKAGE_PIN U16 [get_ports {pc_debug[0]}]
set_property PACKAGE_PIN E19 [get_ports {pc_debug[1]}]
set_property PACKAGE_PIN U19 [get_ports {pc_debug[2]}]
set_property PACKAGE_PIN V19 [get_ports {pc_debug[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pc_debug[*]}]

# Timing constraints
set_input_delay -clock clk -min 1.000 [get_ports reset]
set_input_delay -clock clk -max 3.000 [get_ports reset]

# False paths for debug signals
set_false_path -from [get_ports reset] -to [get_ports {pc_debug[*]}]
set_false_path -from [get_ports reset] -to [get_ports {instruction_debug[*]}]
set_false_path -from [get_ports reset] -to [get_ports {alu_result_debug[*]}]