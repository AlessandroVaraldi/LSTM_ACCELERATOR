library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.lzc_wire.all;
use work.fp_wire.all;
use work.fp_func.all;

entity sum_f32 is
	port
	(
		reset   : in  std_logic;
		clock   : in  std_logic;
		clken	: in  std_logic;
		modop   : in  std_logic;	
		data1	: in  std_logic_vector (31 downto 0);		
		data2	: in  std_logic_vector (31 downto 0);	
		d_out	: out std_logic_vector (31 downto 0);	
		flags  	: out std_logic_vector(4 downto 0);
		ready  	: out std_logic
	);
end sum_f32;

architecture rtl of sum_f32 is

component fp_unit is
	port(
		reset     : in  std_logic;
		clock     : in  std_logic;
		fp_unit_i : in  fp_unit_in_type;
		fp_unit_o : out fp_unit_out_type
	);
end component;

constant fp_operation_zero : fp_operation_type := (
   fmadd    => '0',
   fmsub    => '0',
   fnmadd   => '0',
   fnmsub   => '0',
   fadd     => '0',
   fsub     => '0',
   fmul     => '0',
   fdiv     => '0',
   fsqrt    => '0',
   fsgnj    => '0',
   fcmp     => '0',
   fmax     => '0',
   fclass   => '0',
   fmv_i2f  => '0',
   fmv_f2i  => '0',
   fcvt_i2f => '0',
   fcvt_f2i => '0',
   fcvt_op  => (others => '0')
);

constant fp_exe_in_zero : fp_exe_in_type := (
   data1  => (others => '0'),
   data2  => (others => '0'),
   data3  => (others => '0'),
   op     => fp_operation_zero,
   fmt    => (others => '0'),
   rm     => (others => '0'),
   enable => '0'
);

constant fp_unit_in_zero : fp_unit_in_type := (
	fp_exe_i => fp_exe_in_zero
);

signal datain: fp_unit_in_type := fp_unit_in_zero;
signal output: fp_unit_out_type;
signal rst: std_logic;

begin
	
	datain.fp_exe_i.data1 <= data1;
	datain.fp_exe_i.data2 <= data2;
	
	datain.fp_exe_i.op.fadd  <= '1' when modop = '0' else '0';
	datain.fp_exe_i.op.fmul  <= '1' when modop = '1' else '0';
	
	datain.fp_exe_i.enable <= clken;
	
	rst <= not reset;
	
	u0:fp_unit
		port map (
		reset     => rst,
		clock     => clock,
		fp_unit_i => datain,
		fp_unit_o => output
	);
	
	d_out <= output.fp_exe_o.result;
	flags <= output.fp_exe_o.flags;
	ready <= output.fp_exe_o.ready;
	
end rtl;
	


	