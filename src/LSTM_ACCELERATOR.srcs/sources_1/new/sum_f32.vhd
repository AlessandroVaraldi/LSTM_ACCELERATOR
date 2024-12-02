library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.lzc_wire.all;
use work.fp_wire.all;
use work.fp_func.all;

use work.custom_types.all;

entity sum_f32 is
	port
	(
		reset   : in  std_logic;
		clock   : in  std_logic;
		clken	: in  std_logic;
		start   : in  std_logic;
		data1	: in  dataflow;		
		data2	: in  dataflow;	
		d_out	: out dataflow;	
		flags  	: out std_logic_vector(4 downto 0)
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

    component dff_chain is
        generic (
           N : integer := 8
        );
        port (
           clock : in std_logic;
           reset : in std_logic;
           start : in std_logic;
           q : out std_logic_vector(N-1 downto 0)
        );
    end component;
    
    signal start_v: std_logic_vector (1 downto 0);
    signal g_tmp1: std_logic_vector (2 downto 0);

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
	
	datain.fp_exe_i.data1 <= data1.data;
	datain.fp_exe_i.data2 <= data2.data;
	
	datain.fp_exe_i.op.fadd  <= '1';
	
	datain.fp_exe_i.enable <= clken;
	
	rst <= not reset;
	
	u0:fp_unit
		port map (
		reset     => rst,
		clock     => clock,
		fp_unit_i => datain,
		fp_unit_o => output
	);
	
	u1: dff_chain
	    generic map (n=>2)
	    port map (
	       reset   => reset,
	       clock   => clock,
	       start   => start,
	       q       => start_v
	    );
	    
	gate_propagation: process (clock, reset)
	begin
	   if reset = '1' then
	       g_tmp1 <= (others => '0');
	       d_out.gate <= (others => '0');
	   elsif rising_edge(clock) then
	       g_tmp1 <= data1.gate;
	       d_out.gate <= g_tmp1;
	   end if;
	end process;
	
	d_out.data <= output.fp_exe_o.result;
	d_out.flag <= output.fp_exe_o.ready and start_v (1);
	flags <= output.fp_exe_o.flags;
	
end rtl;