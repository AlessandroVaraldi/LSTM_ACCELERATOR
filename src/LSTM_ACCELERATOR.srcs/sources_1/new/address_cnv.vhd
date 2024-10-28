----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/28/2024 11:31:15 AM
-- Design Name: 
-- Module Name: address_cnv - Behavioral
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

entity address_cnv is
    port
    (
        clk:        in  std_logic;
        rst:        in  std_logic;
        data_i:     in  dataflow;
        data_o:     out dataflow
    );
end address_cnv;

architecture Behavioral of address_cnv is

    signal data_inv: dataflow;

begin

    data_inv.data <= std_logic_vector(unsigned(not(data_i.data)) + 1);
    data_inv.gate <= data_i.gate;
    data_inv.flag <= data_i.flag;

    process (clk, rst)
    begin
        if rst = '1' then
            data_o.data <= (others => '0');
            data_o.gate <= (others => '0');
            data_o.flag <= '0';
        elsif rising_edge(clk) then
            if data_i.flag = '1' then
                if unsigned(data_i.data) > 0 or unsigned(data_i.data) = 0 then
                    data_o <= data_i;
                else
                    data_o <= data_inv;
                end if;
            else    
                data_o.flag <= '0';
            end if;
        end if;
    end process;

end Behavioral;
