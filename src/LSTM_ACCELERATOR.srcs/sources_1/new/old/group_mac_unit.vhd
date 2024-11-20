----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/13/2024 09:14:10 AM
-- Design Name: 
-- Module Name: group_mac_unit - Behavioral
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

entity group_mac_unit is
    generic(
        inputs: positive := 5; 
        cells: positive := 3;
        n: positive := 5;
        p: positive := 24;
        c: positive := 1
    );
    port 
    (
        clk         : in  std_logic;
        rst         : in  std_logic;
        start       : in  std_logic;
        data_x      : in  input_array;
        ready       : out std_logic
    );
end group_mac_unit;

architecture Behavioral of group_mac_unit is

    function log2ceil(n : integer) return integer is
        variable result : integer := 0;
        variable temp : integer := n - 1;  -- Per arrotondare verso l'alto
    begin
        while temp > 0 loop
            temp := temp / 2;
            result := result + 1;
        end loop;
        return result;
    end function;

    function divide_and_ceil(dividend : integer; divisor : integer) return integer is
        variable result : integer;
    begin
        if divisor = 0 then
            -- Gestione del caso divisore uguale a zero
            result := 0;
        elsif dividend mod divisor = 0 then
            -- Se la divisione è esatta, restituisce solo il quoziente
            result := dividend / divisor;
        else
            -- Altrimenti arrotonda per eccesso
            result := (dividend / divisor) + 1;
        end if;
        return result;
    end function;

    constant xdim: integer := inputs + cells;
    constant ydim: integer := cells * 4;
    constant area: integer := (inputs + cells) * cells * 4;
    
    constant xad_dim: integer := 10;
    constant had_dim: integer := log2ceil(cells);
    constant bad_dim: integer := log2ceil(ydim);
    constant wad_dim: integer := log2ceil(xdim);

    constant input_groups: integer := divide_and_ceil(xdim, 8);
    
    type input_group is array (0 to 2**c-1) of std_logic_vector(2**n-1 downto 0);
    type group_group is array (0 to input_groups-1) of input_group;
    
    signal i_uns: unsigned (wad_dim-1 downto 0);

    signal mux_input: group_group;
    signal mac_input: input_group;
    
    signal group_sel: unsigned (input_groups-1 downto 0);

    component shift_register is
        generic (
            l : integer := 8; -- Lunghezza dell'indirizzo (log2 della profondità del registro)
            n : integer := 3  -- Dimensione della word (larghezza del dato)
        );
        port (
            clk     : in  std_logic;
            rst     : in  std_logic;
            enable  : in  std_logic; -- Segnale di enable per lo shift
            data_in : in  std_logic_vector(2**n-1 downto 0); -- Dato da inserire nella prima posizione
            addr    : in  std_logic_vector(l-1 downto 0); -- Indirizzo di lettura
            data_out: out std_logic_vector(2**n-1 downto 0)  -- Dato corrispondente all'indirizzo
        );
    end component;
    
    signal x_en, sh_en, in_en: std_logic_vector (inputs-1 downto 0);
    signal x_ad: std_logic_vector (xad_dim-1 downto 0);
    signal shift_out: input_array;
    
    signal cnt: integer;
    signal cnt_en, cnt_rs: std_logic;
    
    signal load_init: std_logic;

    
    signal gi: unsigned (1 downto 0);
    signal gi_rs, gi_en: std_logic;

    component mac_i32 is
        generic (n: integer; p: integer);
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
    
    type state_type is (RESET, IDLE, LOAD, POSTLOAD, PIPELINE);
    signal state, next_state: state_type;

begin

    process (clk, rst)
    begin
        if rst = '1' then
            state <= RESET;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;
    
    process (state, start)
    begin
        case state is
            when RESET =>
            when IDLE =>
            when LOAD =>
            when PIPELINE =>
            when OTHERS =>
            
        end case;
      
    end process;
    
    init_count: process (clk, cnt_en, cnt_rs, gi_rs, gi_en)
    begin
        if rising_edge(clk) then
        
            if cnt_rs = '1' then 
                cnt <= 0;
            elsif cnt_en = '1' then 
                cnt <= cnt + 1;
            end if;
            
            if gi_rs = '1' then 
                gi <= (others => '0');
            elsif gi_en = '1' then
                gi <= gi + 1;
            end if;
            
            if load_init = '1' then 
                in_en <= (others => '1');
            else 
                in_en <= (others => '0');
            end if;
            
        end if;
    end process;

    shiftreg_gen: 
    for i in 0 to inputs-1 generate
    m_i: shift_register
        generic map (l => xad_dim, n => n)
        port map (
            clk         => clk,
            rst         => rst,
            enable      => sh_en(i),
            addr        => x_ad,
            data_in     => data_x(i),
            data_out    => shift_out(i)
        );
    end generate;

    signal_gen:
    for i in 0 to xdim-1 generate
    i_uns <= to_unsigned(i, wad_dim);
    mux_input(to_integer(i_uns(wad_dim-1 downto 0)))(to_integer(i_uns(1 downto 0))) <= shift_out(i);
    end generate;

    -- mux per selezionare il gruppo di input
    -- ho input_groups gruppi di input e devo selezionarli uno alla volta
    -- quindi mi serve un multiplexer che in output restituisca il gruppo di input selezionato
    
    mac_input <= mux_input(to_integer(group_sel));

    mac_gen:
    for i in 0 to 2**c-1 generate
    u_i: mac_i32
        generic map (n => n, p => p)
        port map (
            clock   => clk,
            reset   => rst,
            start   => mac_st,
            clken   => clken,
            data1   => mac_input(i),
            data2   => data_w,
            data3   => bias,
            d_out   => mac
        );
    end generate;
