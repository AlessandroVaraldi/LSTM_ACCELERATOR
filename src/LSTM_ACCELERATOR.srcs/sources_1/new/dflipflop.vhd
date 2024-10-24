----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.06.2024 11:42:09
-- Design Name: 
-- Module Name: dflipflop - Behavioral
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

entity dflipflop is
    port 
    ( 
        clk : in  std_logic;
        rst : in  std_logic;
        d   : in  std_logic;
        q   : out std_logic
     );
end dflipflop;

architecture Behavioral of dflipflop is

    begin
        process(clk, rst)
        begin
            if rst = '1' then
                q <= '0';
            elsif rising_edge(clk) then
                q <= d;
            end if;
        end process;
        
end Behavioral;
