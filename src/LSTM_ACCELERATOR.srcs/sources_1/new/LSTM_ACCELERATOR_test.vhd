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
use IEEE.STD_LOGIC_TEXTIO.ALL;  -- Pacchetto per scrivere STD_LOGIC
use STD.TEXTIO.ALL;             -- Pacchetto generale per l'input/output di testo

use work.custom_types.all;

use work.lzc_wire.all;
use work.lzc_lib.all;
use work.fp_wire.all;
use work.fp_lib.all;

entity LSTM_ACCELERATOR_test is
--  Port ( );
end LSTM_ACCELERATOR_test;

architecture Behavioral of LSTM_ACCELERATOR_test is

    signal debug_signal : integer := 0;

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
            inputs: positive := inputs; 
            cells: positive := cells;
            n: positive := precision;
            p: positive := point
        );
        port 
        (
            clk         : in  std_logic;
            rst         : in  std_logic;
            start       : in  std_logic;
            data_x      : in  input_array;
            ready       : out std_logic;
            outp        : out std_logic_vector (2**n-1 downto 0)
        );
    end component;
    
    signal x_ad: unsigned(7 downto 0) := (others => '0');
    signal data: std_logic_vector(159 downto 0);
    signal outp: std_logic_vector (2**precision-1 downto 0);
    
    component xrom is
        port (
            clk : in STD_LOGIC;
            addr : in UNSIGNED(7 downto 0);
            data : out STD_LOGIC_VECTOR(159 downto 0)
        );
    end component;
    
    component mac_f32 is
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
    end component;

begin

--    u1: mac_f32
--        port map (
--            reset       => rst,
--            clock       => clk,
--            clken       => '1',
--            start       => start,
--            data1       => x,
--            data2       => y,
--            data3       => z
--        );
        
    -- ## DEBUG ##
--    process(output)
--        variable line_out : line;
--    begin
--        write(line_out, string'("Debug: debug_signal = "));
--        write(line_out, debug_signal);  -- Stampa il valore di debug_signal
--        writeline(output, line_out);    -- Stampa la linea nella console
--        wait;  -- Per bloccare la simulazione
--    end process;

    data_x(0) <= data (2**precision - 1 + 24 - point + 128 downto 24 - point + 128);
    data_x(1) <= data (2**precision - 1 + 24 - point + 96 downto 24 - point + 96);
    data_x(2) <= data (2**precision - 1 + 24 - point + 64 downto 24 - point + 64);
    data_x(3) <= data (2**precision - 1 + 24 - point + 32 downto 24 - point + 32);
    data_x(4) <= data (2**precision - 1 + 24 - point downto 24 - point);
    
    m0: xrom
        port map (
            clk     => clk,
            addr    => x_ad,
            data    => data
        );
        
    u0: LSTM_ACCELERATOR
        generic map (
            inputs  => inputs,
            cells   => cells,
            n       => precision,
            p       => point
        )
        port map (
            clk     => clk,
            rst     => rst,
            start   => start,
            data_x  => data_x,
            outp    => outp,
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
        start <= '0';
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
