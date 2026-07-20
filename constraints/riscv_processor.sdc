# RISC-V Processor Quartus Timing Constraints
# For Intel/Altera FPGA deployment

# Create clock constraint
create_clock -name sys_clk -period 10.000 [get_ports clk]

# Set input delays
set_input_delay -clock sys_clk -min 1.000 [get_ports reset]
set_input_delay -clock sys_clk -max 3.000 [get_ports reset]

# Set output delays
set_output_delay -clock sys_clk -min 1.000 [get_ports pc_debug*]
set_output_delay -clock sys_clk -max 5.000 [get_ports pc_debug*]

# Clock uncertainty
set_clock_uncertainty -setup 0.200 [get_clocks sys_clk]
set_clock_uncertainty -hold 0.100 [get_clocks sys_clk]

# False paths for debug signals
set_false_path -from [get_ports reset] -to [get_ports pc_debug*]

# Timing exceptions for cross-clock domain paths (if any)
# set_false_path -from [get_clocks clk_a] -to [get_clocks clk_b]

# Maximum delay constraints for critical paths
# set_max_delay -from [get_registers *] -to [get_registers *] 8.000