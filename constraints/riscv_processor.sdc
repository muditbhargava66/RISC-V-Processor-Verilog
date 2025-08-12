# RISC-V Processor SDC Constraints
# For Intel Quartus Prime (Synopsys Design Constraints format)

# Create clock constraint
create_clock -name clk -period 10.000 [get_ports clk]

# Set input delays
set_input_delay -clock clk -min 1.000 [get_ports reset]
set_input_delay -clock clk -max 3.000 [get_ports reset]

# Set output delays for debug signals
set_output_delay -clock clk -min 1.000 [get_ports pc_debug[*]]
set_output_delay -clock clk -max 5.000 [get_ports pc_debug[*]]
set_output_delay -clock clk -min 1.000 [get_ports instruction_debug[*]]
set_output_delay -clock clk -max 5.000 [get_ports instruction_debug[*]]
set_output_delay -clock clk -min 1.000 [get_ports alu_result_debug[*]]
set_output_delay -clock clk -max 5.000 [get_ports alu_result_debug[*]]

# Set false paths for reset
set_false_path -from [get_ports reset] -to [get_registers *]

# Set multicycle paths for memory operations (if needed)
# set_multicycle_path -setup -end 2 -from [get_registers *] -to [get_registers *data_memory*]

# Clock uncertainty
set_clock_uncertainty -setup 0.200 [get_clocks clk]
set_clock_uncertainty -hold 0.100 [get_clocks clk]

# Maximum delay constraints
set_max_delay -from [get_ports reset] -to [get_registers *] 15.000