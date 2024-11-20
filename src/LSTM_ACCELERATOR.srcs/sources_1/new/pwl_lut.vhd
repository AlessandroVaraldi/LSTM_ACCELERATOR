----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/11/2024 02:53:02 PM
-- Design Name: 
-- Module Name: pwl_lut - Behavioral
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

entity pwl_lut is
    generic (n: integer; p: integer);
    port
    (
        clk:        in  std_logic;
        rst:        in  std_logic;
        input:      in  dataflow;
        output:     out dataflow
    );
end pwl_lut;

architecture Behavioral of pwl_lut is

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
    
    signal tansig, posneg: std_logic;
    signal tansig_v, posneg_v: std_logic_vector (2 downto 0);

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
   
   signal input_reg1, input_reg2: dataflow;
   
   component pwl_i32 is
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
   end component;
   
--   signal abs_input: std_logic_vector (2**n-1 downto 0);
--   signal address: std_logic_vector (2 downto 0);
--   signal lut_out: std_logic_vector (63 downto 0);
   
   signal m, q: std_logic_vector (2**n-1 downto 0);
   
   signal m_sel, q_sel: std_logic_vector (2**n-1 downto 0);
   
   type state_type is (RESET, PIPELINE);
   signal state, next_state: state_type;
   
   signal q_tp, q_tn, q_sp, q_sn: std_logic_vector (2**n-1 downto 0);
   
   signal m_t, m_s: std_logic_vector (2**n-1 downto 0);
   
   signal tanh_x: dataflow;
      
begin
    
    process (clk, rst)
    begin
        if rst = '1' then
            state <= RESET;
        elsif rising_edge(clk) then
            state <= next_state;
            input_reg1 <= input;
            input_reg2 <= input_reg1;
        end if;
    end process;
    
    process (state, input.flag)
    begin
        case state is
        
            when RESET =>
            
                next_state <= PIPELINE;
                
            when PIPELINE =>
                
        end case;
    end process;
    
    tansig <= '1' when input.gate = "100" or input.gate = "101" or input.gate = "111" else '0';
    
    f1: dff_chain 
        generic map (n => 3)
        port map (
            clock   => clk,
            reset   => rst,
            start   => tansig,
            q       => tansig_v
        );
        
    posneg <= '1' when input.data(2**n-1) = '1' else '0';
        
    f2: dff_chain 
        generic map (n => 3)
        port map (
            clock   => clk,
            reset   => rst,
            start   => posneg,
            q       => posneg_v
        );
        
    -- input non deve essere dimezzato se tanh
        
    u0: pwl_i32
        generic map (n => n, p => p)
        port map (
            rst     => rst,
            clk     => clk,
            input   => input.data,
            st      => tansig,
            m       => m,
            q       => q
        );
        
--    abs_input <=  input_reg.data when input_reg.data(2**n-1) = '0' else (std_logic_vector(unsigned(not(input_reg.data)) + 1));                   
--    address <= abs_input (p+2 downto p);
--    lut_out <= rom (to_integer(unsigned(address)));
    
--    m <= lut_out (2**(n+1)-1 downto 2**n);
--    q <= lut_out (2**n-1 downto 0);
    
    u1: m_transformer
        generic map (n => n, p => p)
        port map (
            reset       => rst,
            clock       => clk,
            clken       => '1',
            m           => m,
            m_t         => m_t,
            m_s         => m_s
        );
        
    u2: q_transformer
        generic map (n => n, p => p)
        port map (
            reset       => rst,
            clock       => clk,
            clken       => '1',
            q           => q,
            q_tp        => q_tp,
            q_sp        => q_sp,
            q_tn        => q_tn,
            q_sn        => q_sn
        );  

    m_sel <= m_t when tansig_v(1) = '0' else
             m_s;   
             
    q_sel <= q_tp when posneg_v(1) = '0' and tansig_v(1) = '0' else
             q_sp when posneg_v(1) = '0' and tansig_v(1) = '1' else
             q_tn when posneg_v(1) = '1' and tansig_v(1) = '0' else
             q_sn;   
            
    u3: mac
        generic map (n => n, p => p)
        port map (
            reset       => rst,
            clock       => clk,
            clken       => '1',
            start       => input_reg2.flag,
            data1       => input_reg2,
            data2.data  => m_sel,
            data2.flag  => '1',
            data2.gate  => "000",
            data3.data  => q_sel,
            data3.flag  => '1',
            data3.gate  => "000",
            d_out       => tanh_x
        );
	
    output.data <= tanh_x.data;
    output.gate <= tanh_x.gate;
    output.flag <= tanh_x.flag;
		
end Behavioral;
