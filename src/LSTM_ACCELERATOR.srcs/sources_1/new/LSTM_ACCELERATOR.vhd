----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/10/2024 02:06:50 PM
-- Design Name: 
-- Module Name: LSTM2 - Behavioral
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

entity LSTM_ACCELERATOR is
    generic(inputs: positive := 5; cells: positive := 3);
    port 
    (
        clk         : in  std_logic;
        rst         : in  std_logic;
        start       : in  std_logic;
        data_x      : in  input_array;
        ready       : out std_logic
    );
end LSTM_ACCELERATOR;

architecture Behavioral of LSTM_ACCELERATOR is

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
    
    constant n: integer := 5;
    constant p: integer := 24;
    
    constant xdim: integer := inputs + cells;
    constant ydim: integer := cells * 4;
    constant area: integer := (inputs + cells) * cells * 4;
    
    constant xad_dim: integer := 10;
    constant had_dim: integer := log2ceil(cells);
    constant bad_dim: integer := log2ceil(ydim);
    constant wad_dim: integer := log2ceil(xdim);
    
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

    component mac_unit is
        generic (n: integer; p: integer);
        port
        (
            clk         : in  std_logic;
            rst         : in  std_logic;
            clken       : in  std_logic;
            start       : in  std_logic;
            stop        : in  std_logic;
            data_x      : in  dataflow;
            data_w      : in  dataflow;
            data_b      : in  dataflow;
            newline     : in std_logic;
            endline     : in  std_logic; 
            data_o      : out dataflow;
            ready       : out std_logic
        );
    end component;
    
    signal mac_start, mac_stop, mac_ready, newline, endline: std_logic;
    signal x_df, w_df, b_df, mac_o: dataflow;
    
    component addr_generator is
        generic
        (
            cells       : integer;
            inputs      : integer;
            x_ad_dim    : integer;
            h_ad_dim    : integer;
            w_ad_dim    : integer;
            b_ad_dim    : integer
        );  
        port
        (
            clk         : in  std_logic;
            rst         : in  std_logic;
            en          : in  std_logic;
            h_ad        : out std_logic_vector (h_ad_dim-1 downto 0);
            x_ad        : out std_logic_vector (x_ad_dim-1 downto 0);
            x_se        : out integer;
            sel         : out std_logic;
            w_ad        : out std_logic_vector ((w_ad_dim+b_ad_dim)-1 downto 0);
            b_ad        : out std_logic_vector (b_ad_dim-1 downto 0);
            newline     : out std_logic;
            endline     : out std_logic;
            ready       : out std_logic
        );  
    end component;
    
    signal adg_en, adg_rd, sel: std_logic := '1';
    
    component wrom is
        generic (n: integer; m: integer);
        port (
            clk : in STD_LOGIC;
            addr : in UNSIGNED((m+n)-1 downto 0);
            data : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    signal w_ad: std_logic_vector ((wad_dim+bad_dim)-1 downto 0);
    signal w_out: std_logic_vector(31 downto 0);
    
    component brom is
        generic (n: integer);
        port (
            clk : in STD_LOGIC;
            addr : in UNSIGNED(n-1 downto 0);
            data : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    signal b_ad: std_logic_vector (bad_dim-1 downto 0);
    signal b_out: std_logic_vector(31 downto 0);
    
    component h_ram is
        generic (
            n           : integer
        );
        port (
            clk         : in  std_logic;
            we          : in  std_logic;
            wr_addr     : in  std_logic_vector(n-1 downto 0);
            rd_addr     : in  std_logic_vector(n-1 downto 0);
            din         : in  std_logic_vector (31 downto 0);
            dout        : out std_logic_vector (31 downto 0)
        );
    end component;
    
    signal h_we: std_logic;
    signal h_wad, h_rad: std_logic_vector (1 downto 0);
    signal h_in, h_out: std_logic_vector(31 downto 0);
    
    component dff_chain is
        generic (
           N : integer := 8
        );
        port (
           clock : in std_logic;
           reset : in std_logic;
           start : in std_logic;
           q : out std_logic_vector(N-1 downto 0)
        );
    end component;
    
    signal cnt: integer;
    signal cnt_en, cnt_rs: std_logic;
    
    signal load_init: std_logic;
    
    signal x_se : integer range 0 to inputs-1 := 0;
    
    signal gi: unsigned (1 downto 0);
    signal gi_rs, gi_en: std_logic;
    
    signal act_in: dataflow;
    
    component Activation_unit is
        generic (n: integer; p: integer);
        port 
        (
            clk         : in  std_logic;
            rst         : in  std_logic;
            clken       : in  std_logic;
            start       : in  std_logic;
            act_in      : in  dataflow;
            rd_en       : out std_logic;
            address     : out std_logic_vector (7 downto 0);
            reading     : in  dataflow;
            act_out     : out dataflow
        );  
    end component;
    
    signal act_start, act_rd: std_logic;
    signal act_ad: std_logic_vector (7 downto 0);
    signal act_reading, act_out: dataflow;
    
    component LSTM_unit is
        generic (n: integer; p: integer);
        port
        (
            clk         : in  std_logic;
            rst         : in  std_logic;
            clken       : in  std_logic;
            start       : in  std_logic;
            stop        : in  std_logic;
            data        : in  dataflow;
            c_new       : out dataflow;
            c_add       : out dataflow;
            rd_en       : out std_logic;
            tanh_c      : in  dataflow;
            h_new       : out dataflow
        );
    end component;
    
    signal LU_start: std_logic;
    signal LU_in, c_new, h_new, tanh_c: dataflow;
    signal LU_rd: std_logic;
    signal LU_ad: std_logic_vector (7 downto 0);
    signal c_add, LU_reading: dataflow;
    
    component lut is
        port (
            clka    : in  STD_LOGIC;
            ena     : in  STD_LOGIC;
            addra   : in  STD_LOGIC_VECTOR (7 downto 0);
            douta   : out STD_LOGIC_VECTOR (31 downto 0);
            clkb    : in  STD_LOGIC;
            enb     : in  STD_LOGIC;
            addrb   : in  STD_LOGIC_VECTOR (7 downto 0);
            doutb   : out STD_LOGIC_VECTOR (31 downto 0)
        );
    end component;

    signal step: std_logic;
    
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
    
    process (state, start, cnt, sel, x_se, h_rad, endline)
    begin
    
        load_init <= '0';
        cnt_rs <= '0';
        cnt_en <= '0';
        
        mac_start <= '0';
        mac_stop <= '0';

        x_df.data <= (others => '0');
        x_df.flag <= '0';
        
        w_df.data <= (others => '0');
        w_df.flag <= '0';
        
        b_df.data <= (others => '0');
        b_df.flag <= '0';
        
        gi_rs <= '0';
        gi_en <= '0';
        
        act_in.data <= (others => '0');
        act_in.flag <= '0';
        act_in.gate <= (others => '0');
        
        act_start <= '0';
        
        case state is
            when RESET =>
                
                cnt_rs <= '1';
                gi_rs <= '1';
                next_state <= IDLE;
                
            when IDLE =>
            
                if start = '1' then
                    next_state <= LOAD;
                else
                    next_state <= IDLE;
                end if;
                
            when LOAD =>
                load_init <= '1';
            
                if cnt = xad_dim-1 then
                    cnt_rs <= '1';
                    next_state <= POSTLOAD;
                else
                    cnt_en <= '1';
                    next_state <= LOAD;
                end if;
                
            when POSTLOAD =>
                
                mac_start <= '1';
                next_state <= PIPELINE;
                
            when PIPELINE =>
                
                if sel = '0' then x_df.data <= shift_out(x_se);
                else x_df.data <= h_out;
                end if;
                x_df.flag <= '1';
                
                w_df.data <= w_out;
                w_df.flag <= '1';
                
                b_df.data <= b_out;
                b_df.flag <= '1';
                
                if endline = '1' then
                    gi_en <= '1';
                    act_in <= mac_o;
                    act_start <= '1';
                end if;
                
                next_state <= PIPELINE;
                
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
    
    process(clk)
    begin
        if rising_edge(clk) then
            if step = '1' then
                step <= '0';
                act_reading.flag <= '1';
            elsif act_rd = '1' then
                step <= '1';
                act_reading.flag <= '0';
            else
                step <= '0';
                act_reading.flag <= '0';
            end if;
        end if;
    end process;
    
    x_df.gate <= std_logic_vector('1' & gi);
            
    -- arrivo a ad=cells*4 e cambio input, bias, e do segnale di newline
    -- arrivo a y=inputs (ad=cells*4*inputs) e passo a previous output, cambio bias, e do segnale di newline
    -- arrivo a y=inputs+cells e ho finito un ciclo (ad=cells*4*(inputs+cells))
    -- passo a x successivo e ripeto
    
    adg_en <= mac_ready or mac_start;
        
    u0: addr_generator
        generic map (
            cells       => cells,
            inputs      => inputs,
            x_ad_dim    => xad_dim,
            h_ad_dim    => had_dim,
            w_ad_dim    => wad_dim,
            b_ad_dim    => bad_dim
        )
        port map (
            clk         => clk,
            rst         => rst,
            en          => adg_en,
            h_ad        => h_rad,
            x_ad        => x_ad,
            x_se        => x_se,
            sel         => sel,
            w_ad        => w_ad,
            b_ad        => b_ad,
            newline     => newline,
            endline     => endline,
            ready       => adg_rd
        );
    
    f0: dff_chain 
        generic map (n => inputs)
        port map (
            clock   => clk,
            reset   => rst,
            start   => adg_rd,
            q       => x_en
        );
        
    sh_en <= in_en or x_en;    
    
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
    
    m0: wrom
        generic map (n => wad_dim, m => bad_dim)
        port map (
            clk         => clk,
            addr        => unsigned(w_ad),
            data        => w_out
        );
        
    m1: brom
        generic map (n => bad_dim)
        port map (
            clk        => clk,
            addr       => unsigned(b_ad),
            data       => b_out
        );
        
    u1: mac_unit
        generic map (n => 5, p => p)
        port map (
            clk         => clk,
            rst         => rst,
            clken       => '1',
            start       => mac_start,
            stop        => mac_stop,
            data_x      => x_df,
            data_w      => w_df,
            data_b      => b_df,
            newline     => newline,
            endline     => endline,
            data_o      => mac_o,
            ready       => mac_ready
        );
          
    u2: activation_unit
        generic map (n => n, p => p)
        port map (
            clk     => clk,
            rst     => rst,
            clken   => '1',
            start   => act_start,
            act_in  => act_in,
            rd_en   => act_rd,
            address => act_ad,
            reading => act_reading,
            act_out => act_out
        );
        
    LU_in <= act_out;
    LU_start <= act_out.flag;
        
    u3: LSTM_unit
        generic map (n => n, p => p)
        port map (
            clk     => clk,
            rst     => rst,
            clken   => '1',
            start   => LU_start,
            stop    => '0',
            data    => LU_in,
            c_new   => c_new,
            c_add   => c_add,
            rd_en   => LU_rd,
            tanh_c  => lu_reading,
            h_new   => h_new
        );
        
    LU_ad <= c_add.data (p+1 downto p-6);
        
    m2: lut
        port map (
            clka        => clk,
            addra       => act_ad,
            ena         => act_rd,
            douta       => act_reading.data,
            clkb        => clk,
            addrb       => LU_ad,
            enb         => LU_rd,
            doutb       => lu_reading.data
        );
                  
    m3: h_ram
        generic map (n => had_dim)
        port map (
            clk         => clk,
            we          => h_we,
            wr_addr     => h_wad,
            rd_addr     => h_rad,
            din         => h_in,
            dout        => h_out
        );
        
    ready <= adg_rd or load_init;
            
end Behavioral;
