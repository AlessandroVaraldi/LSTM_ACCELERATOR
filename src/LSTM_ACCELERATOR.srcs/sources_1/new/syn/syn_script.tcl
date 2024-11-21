# rm -rf work/
# mkdir work
# source /eda/scripts/init_design_vision
# dc_shell-xg-t
# source syn_script.tcl

analyze -format vhdl -library work ../custom_types.vhd
analyze -format vhdl -library work ../components_i32.vhd

analyze -format vhdl -library work ../addr_generator.vhd
analyze -format vhdl -library work ../dflipflop.vhd
analyze -format vhdl -library work ../dff_chain.vhd
analyze -format vhdl -library work ../wrom.vhd
analyze -format vhdl -library work ../brom.vhd

analyze -format vhdl -library work ../mac.vhd
analyze -format vhdl -library work ../mac_unit.vhd

analyze -format vhdl -library work ../pwl_i32.vhd
analyze -format vhdl -library work ../m_transformer.vhd
analyze -format vhdl -library work ../q_transformer.vhd
analyze -format vhdl -library work ../pwl_lut.vhd

analyze -format vhdl -library work ../multiplier.vhd
analyze -format vhdl -library work ../adder.vhd
analyze -format vhdl -library work ../LSTM_unit.vhd

analyze -format vhdl -library work ../h_RAM.vhd
analyze -format vhdl -library work ../shift_register.vhd

analyze -format vhdl -library work ../LSTM_ACCELERATOR.vhd
analyze -format sverilog -library work ../LSTM_ACCELERATOR_top.sv

set power_preserve_rtl_hier_names true

elaborate LSTM_ACCELERATOR_top -library work

#check_design

create_clock -name CLK -period 10 clk

set_dont_touch_network CLK

set_clock_uncertainty 0.5 [get_clocks CLK]

set_input_delay 1.0 -max -clock CLK [remove_from_collection [all_inputs] clk]

set_output_delay 1.0 -max -clock CLK [all_outputs]

redirect -append output_compile.log {
    compile
}

#compile_ultra -gate_clock

report_timing
report_area
report_power

write -format ddc -hierarchy -output "design_optimized.ddc"