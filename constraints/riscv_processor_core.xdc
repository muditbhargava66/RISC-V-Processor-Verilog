# Full-core characterization constraints (target: xc7a35tfgg484-1).
#
# This is the SAME xc7a35t die and -1 speed grade as the Basys3 target
# (xc7a35tcpg236-1), in a larger package (250 user I/O) so that all 241 I/O of
# the complete riscv_processor core (every debug port retained) can be placed.
# Logic resources, timing, and utilization percentages are directly comparable
# to the Basys3 minimal/jtag runs; only the package differs. This is a pin-less
# characterization build, not a board image (no bitstream is generated).

# Core clock at 50 MHz (20 ns), matching the deployed clk_core.
create_clock -period 20.000 -name clk_core -waveform {0.000 10.000} [get_ports clk]

# Asynchronous reset input is not a timed data path.
set_false_path -from [get_ports reset]

# Default I/O standard so power/timing estimates are realistic. Pin locations
# are auto-assigned by the placer; implementation runs to route_design only.
set_property IOSTANDARD LVCMOS33 [get_ports *]