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

entity pwl_i32 is
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
end pwl_i32;

architecture Behavioral of pwl_i32 is

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
    
    signal abs_input: std_logic_vector (2**n-1 downto 0);
    
    signal address: std_logic_vector (2 downto 0);

    type rom_type is array (0 to 7) of STD_LOGIC_VECTOR(63 downto 0);
    signal rom : rom_type := (
        X"00EC9A9F00000000",
        X"0099550D0029A2C9",
        X"00497FEC007977E9",
        X"001E256E00BA7FA6",
        X"000B907C00DFA98A",
        X"0004524F00F1C4FC",
        X"0001995B00F9EFD7",
        X"000096EB00FD7861"
    );
    
    signal lut_out: std_logic_vector (63 downto 0);

begin

    rom <= (
        X"00EC9A9F00000000",
        X"0099550D0029A2C9",
        X"00497FEC007977E9",
        X"001E256E00BA7FA6",
        X"000B907C00DFA98A",
        X"0004524F00F1C4FC",
        X"0001995B00F9EFD7",
        X"000096EB00FD7861"
    );

    abs_input <=  input when input(2**n-1) = '0' else (std_logic_vector(unsigned(not(input)) + 1)); 
    address <= abs_input (p+2 downto p) when st = '1' else abs_input (p+1 downto p-1);  

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
