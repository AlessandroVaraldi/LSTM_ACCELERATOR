----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.06.2024 11:42:09
-- Design Name: 
-- Module Name: dff_chain - Behavioral
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

entity dff_chain is
    generic (
		N : integer := 8
   );
   port (
		clock : in std_logic;
		reset : in std_logic;
		start : in std_logic;
		q : out std_logic_vector(N-1 downto 0)
	);
end dff_chain;

architecture Behavioral of dff_chain is

    component dflipflop is
        port 
        (
           clk : in  std_logic;
           rst : in  std_logic;
           d   : in  std_logic;
           q   : out std_logic
         );
    end component;
    
    signal q_internal : std_logic_vector(N downto 0) := (others => '0');

begin

	q_internal(0) <= start;
    
	gen_ff: for i in 0 to N-1 generate
	
	dff: dflipflop
		port map (
			clk => clock,
			rst => reset,
			d => q_internal(i),
			q => q_internal(i+1)
		);
	end generate gen_ff;

	q <= q_internal(N downto 1) when reset = '0' else (others => '0');

end Behavioral;
