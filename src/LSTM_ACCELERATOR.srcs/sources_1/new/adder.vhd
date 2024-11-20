----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/15/2024 12:07:16 PM
-- Design Name: 
-- Module Name: sum_i32 - Behavioral
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

entity adder is
    generic (n: integer; p: integer);
    port
	(
		reset   : in  std_logic;
		clock   : in  std_logic;
		clken	: in  std_logic;	
		data1	: in  dataflow;		
		data2	: in  dataflow;	
		d_out	: out dataflow;	
		flags  	: out std_logic_vector (4 downto 0)
	);
end adder;

architecture Behavioral of adder is

begin

    process (reset,clock,clken)
    begin
        if reset = '1' then
            d_out.data <= (others => '0');
            d_out.flag <= '0';
        elsif rising_edge (clock) and clken = '1' then
            if data1.flag = '1' and data2.flag = '1' then
                d_out.data <= std_logic_vector(signed(data1.data) + signed(data2.data));
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
