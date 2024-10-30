----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/14/2024 02:02:20 PM
-- Design Name: 
-- Module Name: LSTM2_test - Behavioral
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

entity LSTM_ACCELERATOR_test is
--  Port ( );
end LSTM_ACCELERATOR_test;

architecture Behavioral of LSTM_ACCELERATOR_test is

    function mul_by_075(input : integer) return integer is
        variable temp : integer;
    begin
        -- Calcola input * 0.75 usando lo shift
        temp := input - (input / 4);  -- Equivalente a input * 0.75 approssimato per difetto
        return temp;
    end function;
    
    constant point: integer := mul_by_075(2**precision);

    -- Clock period definition
    constant clk_period : time := 10 ns;

    signal clk, rst, start, ready: std_logic := '0';
    signal data_x: input_array;

    component LSTM_ACCELERATOR is
        generic(
            inputs: positive := 5; 
            cells: positive := 3;
            n: positive := 5;
            p: positive := 24
        );
        port 
        (
            clk         : in  std_logic;
            rst         : in  std_logic;
            start       : in  std_logic;
            data_x      : in  input_array;
            ready       : out std_logic
        );
    end component;
    
    signal x_ad: unsigned(7 downto 0) := (others => '0');
    signal data: std_logic_vector(159 downto 0);
    
    component xrom is
        port (
            clk : in STD_LOGIC;
            addr : in UNSIGNED(7 downto 0);
            data : out STD_LOGIC_VECTOR(159 downto 0)
        );
    end component;

begin

    data_x(0) <= data(159 downto 159 - (2**precision) + 1);
    data_x(1) <= data(127 downto 127 - (2**precision) + 1);
    data_x(2) <= data(95 downto 95 - (2**precision) + 1);
    data_x(3) <= data(63 downto 63 - (2**precision) + 1);
    data_x(4) <= data(31 downto 31 - (2**precision) + 1);
    
    m0: xrom
        port map (
            clk     => clk,
            addr    => x_ad,
            data    => data
        );
        
    u0: LSTM_ACCELERATOR
        generic map (
            inputs  => 5,
            cells   => 1,
            n       => precision,
            p       => point
        )
        port map (
            clk     => clk,
            rst     => rst,
            start   => start,
            data_x  => data_x,
            ready   => ready
        );
        
    clk_process : process
    begin
        clk <= '1';
        wait for clk_period / 2;
        clk <= '0';
        wait for clk_period / 2;
    end process;
    
    -- Stimulus process
    stimulus: process
    begin
        rst <= '1';
        wait for clk_period * 2;
        rst <= '0';
        wait for clk_period;
        
        start <= '1';
        wait for clk_period;
        start <= '0';
        
        wait;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) and ready = '1' then
            x_ad <= x_ad + 1;
        end if;
    end process;

end Behavioral;
