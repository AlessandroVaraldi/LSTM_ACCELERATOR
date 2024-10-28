library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.custom_types.all;

entity LSTM_unit is
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
end entity;
    
architecture Behavioral of LSTM_unit is

    component mul_i32 is
        generic (n: integer; p: integer);
        port
        (
            reset   : in  std_logic;
            clock   : in  std_logic;
            clken	: in  std_logic;
            data1	: in  dataflow;		
            data2	: in  dataflow;	
            d_out	: out dataflow;	
            flags  	: out std_logic_vector (4 downto 0)
        );
    end component;
    
    component sum_i32 is
        generic (n: integer; p: integer);
        port
        (
            reset   : in  std_logic;
            clock   : in  std_logic;
            clken	: in  std_logic;
            data1	: in  dataflow;		
            data2	: in  dataflow;	
            d_out	: out dataflow;	
            flags  	: out std_logic_vector (4 downto 0)
        );
    end component;
    
    component address_cnv is
        port
        (
            clk:        in  std_logic;
            rst:        in  std_logic;
            data_i:     in  dataflow;
            data_o:     out dataflow
        );
    end component;
    
    signal cnv: dataflow;

    signal c_reg, f_reg, i_reg, z_reg, o_reg: std_logic_vector(2**n downto 0);
    signal c_df, f_df, i_df, z_df, o_df: dataflow;
    
    signal cf_df, iz_df: dataflow;
    signal cf_reg, iz_reg: std_logic_vector(2**n downto 0);
    
    signal thc_reg: std_logic_vector(2**n-1 downto 0);
    
    signal sum: dataflow;
    
    type state_type is (RESET, IDLE, PIPELINE);
    signal state, next_state: state_type;
    
begin

    -- ricevo i dati in questa sequenza: i0, f0, z0, o0, i1, f1, z1, o1
    -- devo calcolare c = z * i + c * f, h = c * o
    
    process (clk, rst)
    begin
        if rst = '1' then
            state <= RESET;
        elsif rising_edge(clk) and clken = '1' then
            state <= next_state;
        end if;
    end process;
    
    process (state, start, stop)
    begin
        case state is
            when RESET =>
                f_reg <= (others => '0');
                i_reg <= (others => '0');
                z_reg <= (others => '0');
                o_reg <= (others => '0');
                c_reg <= (others => '0');
                cf_reg <= (others => '0');
                iz_reg <= (others => '0');
                c_reg <= (others => '0');
                thc_reg <= (others => '0');
                next_state <= IDLE;
            when IDLE =>
            
                if start = '1' and data.flag = '1' then
                
                    case data.gate is
                        when "100" =>
                            f_reg (2**n-1 downto 0) <= data.data;
                            f_reg (2**n) <= data.flag;
                        when "101" =>
                            i_reg (2**n-1 downto 0) <= data.data;
                            i_reg (2**n) <= data.flag;
                        when "110" =>
                            z_reg (2**n-1 downto 0) <= data.data;
                            z_reg (2**n) <= data.flag;
                        when "111" =>
                            o_reg (2**n-1 downto 0) <= data.data;
                            o_reg (2**n) <= data.flag;
                        when "010" =>
                            c_reg (2**n-1 downto 0) <= data.data;
                            c_reg (2**n) <= data.flag;
                        when others=>
                    end case;
                    next_state <= PIPELINE;
                
                else
                    
                    next_state <= IDLE;
                    
                end if;
                
            when PIPELINE =>
            
                if data.flag = '1' then
                    case data.gate is
                        when "100" =>
                            f_reg (2**n-1 downto 0) <= data.data;
                            f_reg (2**n) <= data.flag;
                        when "101" =>
                            i_reg (2**n-1 downto 0) <= data.data;
                            i_reg (2**n) <= data.flag;
                        when "110" =>
                            z_reg (2**n-1 downto 0) <= data.data;
                            z_reg (2**n) <= data.flag;
                        when "111" =>
                            o_reg (2**n-1 downto 0) <= data.data;
                            o_reg (2**n) <= data.flag;
                        when "010" =>
                            c_reg (2**n-1 downto 0) <= data.data;
                            c_reg (2**n) <= data.flag;
                        when others=>
                    end case;
                end if;
                
                if cf_df.flag = '1' then
                    cf_reg (2**n-1 downto 0) <= cf_df.data;
                end if;
                
                if iz_df.flag = '1' then
                    iz_reg (2**n-1 downto 0) <= iz_df.data;
                end if;
                
                if sum.flag = '1' then
                    c_reg (2**n-1 downto 0) <= sum.data;
                end if;
                
                if tanh_c.flag = '1' then
                    thc_reg <= tanh_c.data;
                end if;
                
            when OTHERS =>
        end case;
    end process;
        
    f_df.data <= f_reg (2**n-1 downto 0);
    f_df.flag <= f_reg (2**n);
    f_df.gate <= "100";
    
    i_df.data <= i_reg (2**n-1 downto 0);
    i_df.flag <= i_reg (2**n);
    i_df.gate <= "101";
    
    z_df.data <= z_reg (2**n-1 downto 0);
    z_df.flag <= z_reg (2**n);
    z_df.gate <= "110";
    
    o_df.data <= o_reg (2**n-1 downto 0);
    o_df.flag <= o_reg (2**n);
    o_df.gate <= "111";
    
    c_df.data <= c_reg (2**n-1 downto 0);
    c_df.flag <= '1';
    c_df.gate <= "010";
    
    u0: mul_i32
        generic map (n => n, p => p)
		port map (
            reset   =>  rst,
            clock   =>  clk,
            clken   =>  clken,
            data1   =>  c_df,
            data2   =>  f_df,
            d_out   =>  cf_df
		);
		
    u1: mul_i32
        generic map (n => n, p => p)
		port map (
            reset   =>  rst,
            clock   =>  clk,
            clken   =>  clken,
            data1   =>  i_df,
            data2   =>  z_df,
            d_out   =>  iz_df
		);
		
	u2: sum_i32
        generic map (n => n, p => p)
		port map (
            reset   =>  rst,
            clock   =>  clk,
            clken   =>  clken,
            data1   =>  cf_df,
            data2   =>  iz_df,
            d_out   =>  sum
		);
		
	c_new <= sum;	
	
	cn: address_cnv
        port map (
            clk     => clk,
            rst     => rst,
            data_i  => sum,
            data_o  => cnv
        );
        
    c_add <= cnv;
	rd_en <= cnv.flag;
		
	-- o might need a shift register
		
	u3: mul_i32
        generic map (n => n, p => p)
		port map (
            reset   =>  rst,
            clock   =>  clk,
            clken   =>  clken,
            data1   =>  tanh_c,
            data2   =>  o_df,
            d_out   =>  h_new
		);
    
end Behavioral;