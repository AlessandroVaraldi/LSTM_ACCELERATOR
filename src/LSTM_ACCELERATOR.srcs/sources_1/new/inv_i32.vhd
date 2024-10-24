library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.custom_types.all;

entity inv_i32 is
	port
	(
		reset   : in  std_logic;
		clock   : in  std_logic;
		clken	: in  std_logic;	
		data1	: in  dataflow;			
		d_out	: out dataflow;	
		flags  	: out std_logic_vector(4 downto 0)
	);
end inv_i32;

architecture Behavioral of inv_i32 is

begin

    process (reset,clock)
    begin
        if reset = '1' then
            d_out.data <= (others => '0');
            d_out.flag <= '0';
        elsif rising_edge (clock) and clken = '1' then
            if data1.flag = '1' then
                d_out.data <= std_logic_vector(unsigned(not(data1.data)) + 1);
                d_out.flag <= '1';
                d_out.gate <= data1.gate;
            else
                d_out.data <= (others => '0');
                d_out.flag <= '0';
                d_out.gate <= (others => '0');
            end if;
        end if;
    end process; 

end Behavioral;