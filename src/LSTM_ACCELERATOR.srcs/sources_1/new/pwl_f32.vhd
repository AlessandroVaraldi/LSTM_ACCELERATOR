----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/19/2024 02:19:10 PM
-- Design Name: 
-- Module Name: pwl_i32 - Behavioral
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
use work.components_i32.all;

entity pwl_f32 is
    generic (n: integer; p: integer);
    port
    (
        clk:        in  std_logic;
        rst:        in  std_logic;
        input:      in  std_logic_vector (2**n-1 downto 0);
        st:         in  std_logic;
        m:          out std_logic_vector (2**n-1 downto 0);
        q:          out std_logic_vector (2**n-1 downto 0)
    );
end pwl_f32;

architecture Behavioral of pwl_f32 is

    component cnv_f2i is
        port
        (
            reset   : in  std_logic;
            clock   : in  std_logic;
            clken	: in  std_logic;	
            data1	: in  std_logic_vector (31 downto 0);	
            d_out	: out std_logic_vector (31 downto 0);	
            flags  	: out std_logic_vector (4 downto 0);
            ready  	: out std_logic
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
            flags  	: out std_logic_vector (4 downto 0)
        );
    end component;

    signal nor_input, int_input: std_logic_vector (2**n-1 downto 0);
    
    signal address: std_logic_vector (2 downto 0);

    type rom_type is array (0 to 7) of STD_LOGIC_VECTOR(63 downto 0);
    signal rom : rom_type := (
        X"3F6C9A9F00000000",
        X"3F19550D3E268B24",
        X"3E92FFD83EF2EFD3",
        X"3DF12B733F3A7FA6",
        X"3D3907C83F5FA98A",
        X"3C8A49D63F71C4FC",
        X"3BCCADA93F79EFD7",
        X"3B16EAA53B16EAA5"
    );
    
    signal lut_out: std_logic_vector (2**(n+1)-1 downto 0);

begin

    nor_input (31) <= '0';
    nor_input (30 downto 23) <= std_logic_vector(unsigned(input (30 downto 23)) + p);
    nor_input (22 downto 0) <= input (22 downto 0);
    
    u0: cnv_f2i
        port map (
            reset   => rst,
            clock   => clk,
            clken   => '1',
            data1   => nor_input,
            d_out   => int_input
        );
        
    address <= int_input (p+2 downto p) when st = '1' else int_input (p+1 downto p-1);  

    process (clk, rst)
    begin
        if rst = '1' then
            lut_out <= (others => '0');
        elsif rising_edge(clk) then
            lut_out <= rom (to_integer(unsigned(address)));
        end if;
    end process;

    m <= lut_out (2**(n+1)-1 downto 2**n);
    q <= lut_out (2**n-1 downto 0);

end Behavioral;
