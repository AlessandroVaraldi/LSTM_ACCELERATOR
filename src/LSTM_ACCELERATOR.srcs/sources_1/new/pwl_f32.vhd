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
use work.components_f32.all;

entity pwl_f32 is
    generic (n: integer; p: integer);
    port
    (
        clk:        in  std_logic;
        rst:        in  std_logic;
        input:      in  dataflow;
        output:     out dataflow
        --sign:       in  std_logic;
        --gate:       in  std_logic;
        --m:          out std_logic_vector (2**n-1 downto 0);
        --q:          out std_logic_vector (2**n-1 downto 0)
    );
end pwl_f32;

architecture Behavioral of pwl_f32 is

    signal sign, gate: std_logic;
    
    component dff_chain is
        generic (
           N : integer := 8
        );
        port (
           clock : in std_logic;
           reset : in std_logic;
           start : in std_logic;
           q     : out std_logic_vector(N-1 downto 0)
        );
    end component;
    
    signal sign_v, gate_v: std_logic_vector (3 downto 0);

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

    signal nor_input, int_input, reg_input: dataflow;
    
    signal address: std_logic_vector (4 downto 0);
    signal m_address, q_address: std_logic_vector (4 downto 0);

    type m_rom_type is array (0 to 15) of STD_LOGIC_VECTOR(31 downto 0);
    signal m_rom : m_rom_type := (
        X"3F6C9A9F",
        X"3F19550D",
        X"3E92FFD8",
        X"3DF12B73",
        X"3D3907C8",
        X"3C8A49D6",
        X"3BCCADA9",
        X"3B16EAA5",
        X"3e6c9a9f",
        X"3e19550d",
        X"3d92ffd8",
        X"3cf12b73",
        X"3c3907c8",
        X"3b8a49d6",
        X"3accada9",
        X"3a16eaa5"
    );

    type q_rom_type is array (0 to 31) of STD_LOGIC_VECTOR(31 downto 0);
    signal q_rom : q_rom_type := (
        X"00000000",
        X"3E268B24",
        X"3EF2EFD3",
        X"3F3A7FA6",
        X"3F5FA98A",
        X"3F71C4FC",
        X"3F79EFD7",
        X"3B16EAA5",
        X"3f000000",
        X"3f14d164",
        X"3f3cbbf5",
        X"3f5d3fd3",
        X"3f6fd4c5",
        X"3f78e27e",
        X"3f7cf7eb",
        X"3f004b75",
        X"00000000",
        X"be268b24",
        X"bef2efd3",
        X"bf3a7fa6",
        X"bf5fa98a",
        X"bf71c4fc",
        X"bf79efd7",
        X"bb16eaa5",
        X"3f000000",
        X"3ed65d37",
        X"3e868817",
        X"3e0b00b4",
        X"3d8159d9",
        X"3ce3b03e",
        X"3c420528",
        X"3eff6915"
    );
    
    signal m, q: std_logic_vector (2**n-1 downto 0);

begin

    gate <= '0' when input.gate = "110" else '1';
    sign <= input.data(31);
    
    f0: dff_chain 
        generic map (n => 4)
        port map (
            clock   => clk,
            reset   => rst,
            start   => gate,
            q       => gate_v
        );
        
        
    f1: dff_chain 
        generic map (n => 4)
        port map (
            clock   => clk,
            reset   => rst,
            start   => sign,
            q       => sign_v
        );

    nor_input.data (31) <= '0';
    nor_input.data (30 downto 23) <= std_logic_vector(unsigned(input.data (30 downto 23)) + p);
    nor_input.data (22 downto 0) <= input.data (22 downto 0);
    nor_input.flag <= input.flag;
    nor_input.gate <= input.gate;
    
    u0: cnv_f2i
        port map (
            reset   => rst,
            clock   => clk,
            clken   => '1',
            data1   => nor_input.data,
            d_out   => int_input.data
        );
        
    process (clk)
    begin
        if rst = '1' then
            int_input.flag <= '0';
            int_input.gate <= (others => '0');
        elsif rising_edge(clk) then
            int_input.flag <= nor_input.flag;
            int_input.gate <= nor_input.gate;
        end if;
   end process;
    
    address <= "00" & int_input.data (p+2 downto p) when gate = '1' else "00" & int_input.data (p+1 downto p-1);
    m_address <=    std_logic_vector(unsigned(address) +  8) when gate = '1' else address;
    q_address <=    std_logic_vector(unsigned(address) +  8) when gate = '1' and sign = '0' else
                    std_logic_vector(unsigned(address) + 16) when gate = '0' and sign = '1' else
                    std_logic_vector(unsigned(address) + 24) when gate = '1' and sign = '1' else
                    address;   

    process (clk, rst)
    begin
        if rst = '1' then
            m <= (others => '0');
            q <= (others => '0');
            reg_input.data <= (others => '0');
            reg_input.gate <= (others => '0');
            reg_input.flag <= '0';
        elsif rising_edge(clk) then
            m <= m_rom (to_integer(unsigned(m_address)));
            q <= q_rom (to_integer(unsigned(q_address)));
            reg_input <= input;
        end if;
    end process;
    
    u1: mac_f32
        port map (
            clock   => clk,
            reset   => rst,
            start   => reg_input.flag,
            clken   => '1',
            data1   => reg_input,
            data2.data   => m,
            data2.gate   => "000",
            data2.flag   => '1',
            data3.data   => q,
            data3.gate   => "000",
            data3.flag   => '1',
            d_out   => output
        );

end Behavioral;
