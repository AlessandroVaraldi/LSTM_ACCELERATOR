library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.custom_types.all;
use work.components_i32.all;

entity LSTM_unit_f32 is
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
        h_new       : out dataflow
    );
end entity;
    
architecture Behavioral of LSTM_unit_f32 is
    
    signal f_en, i_en, z_en, o_en, c_en: std_logic;

    signal c_reg, f_reg, i_reg, z_reg, o_reg: std_logic_vector(2**n downto 0);
    signal c_df, f_df, i_df, z_df, o_df: dataflow;
    
    signal cf_df, iz_df: dataflow;
    signal cf_reg, iz_reg: std_logic_vector(2**n downto 0);
    
    signal thc_reg: std_logic_vector(2**n-1 downto 0);
    
    signal sum, sum_reg, mul: dataflow;
    
    type rom_type is array (0 to 7) of std_logic_vector(63 downto 0);
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
   
   signal abs_input: std_logic_vector (2**n-1 downto 0);
   signal address: std_logic_vector (2 downto 0);
   signal lut_out: std_logic_vector (63 downto 0);
   
   signal m, q: std_logic_vector (2**n-1 downto 0);
   
   component mac is
       generic (n: integer; p: integer);
       port
       (
           reset    : in  std_logic;
           clock    : in  std_logic;
           clken    : in  std_logic;
           start    : in  std_logic;
           data1    : in  dataflow;				
           data2	: in  dataflow;		
           data3	: in  dataflow;		
           d_out	: out dataflow;	
           flags  	: out std_logic_vector(4 downto 0)
       );
   end component;
   
   signal tanh_c: dataflow; 
   
   signal rst_regs, rst_mul: std_logic;
   
   component mul_f32 is
       port
       (
           reset    : in  std_logic;
           clock    : in  std_logic;
           clken	: in  std_logic;	
           data1	: in  std_logic_vector (31 downto 0);		
           data2	: in  std_logic_vector (31 downto 0);	
           d_out	: out std_logic_vector (31 downto 0);	
           flags  	: out std_logic_vector(4 downto 0);
           ready  	: out std_logic
        );
   end component;
   
   component sum_f32 is
       port
       (
           reset    : in  std_logic;
           clock    : in  std_logic;
           clken	: in  std_logic;	
           data1	: in  std_logic_vector (31 downto 0);		
           data2	: in  std_logic_vector (31 downto 0);	
           d_out	: out std_logic_vector (31 downto 0);	
           flags  	: out std_logic_vector(4 downto 0);
           ready  	: out std_logic
        );
   end component;
    
   type state_type is (RESET, PIPELINE);
   signal state, next_state: state_type;
    
begin

    -- ricevo i dati in questa sequenza: i0, f0, z0, o0, i1, f1, z1, o1
    -- devo calcolare c = z * i + c * f, h = c * o
    
    process (clk, rst)
    begin
        if rst = '1' then
            state <= RESET;
            
            f_reg <= (others => '0');
            i_reg <= (others => '0');
            z_reg <= (others => '0');
            o_reg <= (others => '0');
            c_reg <= (others => '0');
            cf_reg <= (others => '0');
            iz_reg <= (others => '0');
            c_reg <= (others => '0');
            thc_reg <= (others => '0');
            rst_mul <= '0';
            
        elsif rising_edge(clk) and clken = '1' then
            state <= next_state;
            
            if f_en = '1' then
                f_reg (2**n-1 downto 0) <= data.data;
                f_reg (2**n) <= data.flag;
            end if;
            
            if i_en = '1' then
                i_reg (2**n-1 downto 0) <= data.data;
                i_reg (2**n) <= data.flag;
            end if;
            
            if z_en = '1' then
                z_reg (2**n-1 downto 0) <= data.data;
                z_reg (2**n) <= data.flag;
            end if;
            
            if o_en = '1' then
                o_reg (2**n-1 downto 0) <= data.data;
                o_reg (2**n) <= data.flag;
            end if;
            
            if c_en = '1' then
                c_reg (2**n-1 downto 0) <= data.data;
                c_reg (2**n) <= data.flag;         
            end if;
            
            if rst_regs = '1' then
                f_reg <= (others => '0');
                i_reg <= (others => '0');
                z_reg <= (others => '0');
                o_reg <= (others => '0');
                rst_mul <= '1';
            else
                rst_mul <= '0';
            end if;
              
        end if;
    end process;
    
    process (state, start, data.flag, mul.flag)
    begin
        f_en <= '0';
        i_en <= '0';
        z_en <= '0';
        o_en <= '0';
        c_en <= '0';
        rst_regs <= '0';
        case state is
            when RESET =>

                next_state <= PIPELINE;
                
            when PIPELINE =>
            
                if data.flag = '1' then
                    case data.gate is
                        when "100" =>
                            f_en <= '1';
                        when "101" =>
                            i_en <= '1';  
                        when "110" =>
                            z_en <= '1';                        
                        when "111" =>
                            o_en <= '1';
                        when "010" =>
                            c_en <= '1';
                        when others=>
                    end case;
                end if;
                
                sum_reg <= sum;
                
                if mul.flag = '1' then
                    rst_regs <= '1';
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
    
    u0: mul_f32
        generic map (n => n, p => p)
		port map (
            reset   =>  rst,
            clock   =>  clk,
            clken   =>  clken,
            data1   =>  f_df,
            data2   =>  c_df,
            d_out   =>  cf_df
		);
		
    u1: mul_f32
        generic map (n => n, p => p)
		port map (
            reset   =>  rst,
            clock   =>  clk,
            clken   =>  clken,
            data1   =>  i_df,
            data2   =>  z_df,
            d_out   =>  iz_df
		);
		
	u2: sum_f32
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
	
	abs_input <=  sum.data when sum.data(2**n-1) = '0' else (std_logic_vector(unsigned(not(sum.data)) + 1));                   
    address <= abs_input (p+1 downto p-1);
    lut_out <= rom (to_integer(unsigned(address)));
    m <= lut_out (2**(n+1)-1 downto 2**n);
    q <= lut_out (2**n-1 downto 0);
    
    u3: mac_f32
        generic map (n => n, p => p)
        port map (
            reset       => rst,
            clock       => clk,
            clken       => '1',
            start       => sum_reg.flag,
            data1       => sum_reg,
            data2.data  => m,
            data2.flag  => '1',
            data2.gate  => "000",
            data3.data  => q,
            data3.flag  => '1',
            data3.gate  => "000",
            d_out       => tanh_c
        );
		
	-- o might need a shift register
		
	u4: mul_f32
        generic map (n => n, p => p)
		port map (
            reset   =>  rst_mul,
            clock   =>  clk,
            clken   =>  clken,
            data1   =>  tanh_c,
            data2   =>  o_df,
            d_out   =>  mul
		);
    
    h_new <= mul;
    
end Behavioral;