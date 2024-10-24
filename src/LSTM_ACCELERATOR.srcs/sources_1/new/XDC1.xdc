create_clock -name clock -period 20.000 [get_ports clk]
set_clock_uncertainty 0.1 [get_clocks clock]
set_input_delay -clock [get_clocks clock] 0.5 [all_inputs]
set_output_delay -clock [get_clocks clock] 0.5 [all_outputs]


#create_clock -name clk -period 10.000 [get_ports clk]
#set_clock_uncertainty 0.05 [get_clocks clk]
#set_input_delay -clock [get_clocks clk] 0.5 [all_inputs]
#set_output_delay -clock [get_clocks clk] 0.5 [all_outputs]