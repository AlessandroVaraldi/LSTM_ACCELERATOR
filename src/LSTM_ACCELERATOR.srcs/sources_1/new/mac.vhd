----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/15/2024 12:07:16 PM
-- Design Name: 
-- Module Name: mac_i32 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.custom_types.all;

entity mac is
    generic (n: integer; p: integer);
	port
	(
		reset   : in  std_logic;
		clock   : in  std_logic;
		clken	: in  std_logic;
		start   : in  std_logic;
		data1	: in  dataflow;				
		data2	: in  dataflow;		
		data3	: in  dataflow;		
		d_out	: out dataflow;	
		flags  	: out std_logic_vector(4 downto 0)
	);
end mac;

architecture Behavioral of mac is

    signal mac: std_logic_vector (2**n-1 downto 0) := (others => '0');

begin

    process (reset, clock)
    begin
        if reset = '1' then
            mac <= (others => '0');
            d_out.flag <= '0';
        else
            if rising_edge (clock) and clken = '1' then
                if start = '1' and data1.flag = '1' and data2.flag = '1' and data3.flag = '1' then
                    d_out.flag <= '1';
                    mac <= std_logic_vector("*"(signed(data1.data),signed(data2.data))((2**n-1) + p downto p) + signed(data3.data));
                else
                    d_out.flag <= '0';
                    mac <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    
    d_out.data <= mac;
    d_out.gate <= data1.gate;

end Behavioral;
