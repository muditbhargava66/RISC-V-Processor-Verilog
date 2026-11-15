# RISC-V Processor Quartus Timing Constraints
# For Intel/Altera FPGA deployment (core-only top: riscv_processor)
# The core clock here is the board clock fed directly to the core (no divider
# in the Quartus flow). Constrained at 50 MHz to match the core's timing budget.

# Create clock constraint (50 MHz / 20 ns)
create_clock -name sys_clk -period 20.000 [get_ports clk]

# Set input delays
set_input_delay -clock sys_clk -min 1.000 [get_ports reset]
set_input_delay -clock sys_clk -max 3.000 [get_ports reset]

# Set output delays
set_output_delay -clock sys_clk -min 1.000 [get_ports pc_debug*]
set_output_delay -clock sys_clk -max 5.000 [get_ports pc_debug*]

# Clock uncertainty
set_clock_uncertainty -setup 0.200 [get_clocks sys_clk]
set_clock_uncertainty -hold 0.100 [get_clocks sys_clk]

# Reset is asynchronous to the core clock; debug LEDs are async status outputs
set_false_path -from [get_ports reset]
set_false_path -to [get_ports pc_debug*]