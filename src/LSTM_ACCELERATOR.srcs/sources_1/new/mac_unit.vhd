library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.custom_types.all;

entity mac_unit is
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
        newline     : in  std_logic;
        endline     : in  std_logic; 
        data_o      : out dataflow;
        ready       : out std_logic
    );  
end mac_unit;

architecture Behavioral of mac_unit is

    component mac_i32 is
        generic (n: integer; p: integer);
        port
        (
            reset   : in  std_logic;
            clear   : in  std_logic;
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
    
    signal bias, mac, reg: dataflow;
    signal mac_rs, mac_st: std_logic;
    
    signal reg_en, reg_rs: std_logic;
    
    type state_type is (RESET, IDLE, START_STATE, PIPELINE);
    signal state, next_state: state_type;

begin
        
    process (clk, rst)
    begin
        if rst = '1' then
            state <= RESET;
        elsif rising_edge(clk) and clken = '1' then
            state <= next_state;
        end if;
    end process;
    
    process (state, start, stop, newline, endline)
    begin
        reg_rs <= '0';
        mac_rs <= '0';
        case state is
            when RESET =>
            
                mac_rs <= '1';
                reg_rs <= '1';
                next_state <= IDLE;
                
            when IDLE =>
            
                if start = '1' then
                
                    next_state <= PIPELINE;
                
                else
                    
                    next_state <= IDLE;
                    
                end if;
                
            when PIPELINE =>
                
                if stop = '1' then
                 
                    next_state <= IDLE;
                    
                else 
            
                    next_state <= PIPELINE;
                    
                end if;
                
            when OTHERS =>
            
        end case;
      
    end process;
    
    mac_reg: process(clk)
    begin   
        if rising_edge(clk) then
            if reg_rs = '1' then
                reg.flag <= '0';
                reg.data <= (others => '0');
                reg.gate <= (others => '0');
            elsif reg_en = '1' then
                reg <= mac;
            end if;
        end if;
    end process;
    
    process (clk)
    begin
        if rising_edge(clk) then
            if start = '1' or mac.flag = '1' then
                mac_st <= '1';
            else 
                mac_st <= '0';
            end if;
        end if;
    end process;

    bias <= data_b when newline = '1' else reg;
    
    u0: mac_i32
        generic map (n => n, p => p)
        port map (
            clock   => clk,
            reset   => rst,
            clear   => mac_rs,
            start   => mac_st,
            clken   => clken,
            data1   => data_x,
            data2   => data_w,
            data3   => bias,
            d_out   => mac
        );
        
    reg_en <= mac.flag;
        
    data_o <= reg;
    ready <= mac.flag;
    
end Behavioral;