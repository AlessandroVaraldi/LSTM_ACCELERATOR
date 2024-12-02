library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.custom_types.all;
use work.components_f32.all;

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
        c_old       : in  dataflow;
        c_new       : out dataflow;
        h_new       : out dataflow
    );
end entity;
    
architecture Behavioral of LSTM_unit_f32 is
    
    signal f_en, i_en, z_en, o_en: std_logic;

    signal f_reg, i_reg, z_reg, o_reg: std_logic_vector(2**n downto 0);
    signal f_df, i_df, z_df, o_df: dataflow;
    
    signal cf_df, iz_df: dataflow;
    signal cf_reg, iz_reg: std_logic_vector(2**n downto 0);
    
    signal thc_reg: std_logic_vector(2**n-1 downto 0);
    
    signal sum, sum_reg, mul: dataflow;
    
    type rom_type is array (0 to 7) of std_logic_vector(63 downto 0);
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
   
   signal abs_input: std_logic_vector (2**n-1 downto 0);
   signal address: std_logic_vector (2 downto 0);
   signal lut_out: std_logic_vector (63 downto 0);
   
   signal m, q: std_logic_vector (2**n-1 downto 0);
  
   signal tanh_c: dataflow; 
   
   signal rst_regs, rst_mul: std_logic;
    
   type state_type is (RESET, PIPELINE);
   signal state, next_state: state_type;
   
   signal st0, st1, st2, st3, st4, st5: std_logic;
   
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
   
   signal nor_sum, int_sum, reg_sum: dataflow;
    
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
            cf_reg <= (others => '0');
            iz_reg <= (others => '0');
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
    
    st0 <= f_df.flag and c_old.flag;
    
    u0: mul_f32
		port map (
            reset   =>  rst,
            clock   =>  clk,
            clken   =>  clken,
            start   =>  st0,
            data1   =>  f_df,
            data2   =>  c_old,
            d_out   =>  cf_df
		);
		
    st1 <= i_df.flag and z_df.flag;
		
    u1: mul_f32
		port map (
            reset   =>  rst,
            clock   =>  clk,
            clken   =>  clken,
            start   =>  st1,
            data1   =>  i_df,
            data2   =>  z_df,
            d_out   =>  iz_df
		);
		
	st2 <= cf_df.flag and iz_df.flag;
		
	u2: sum_f32
		port map (
            reset   =>  rst,
            clock   =>  clk,
            clken   =>  clken,
            start   =>  st2,
            data1   =>  cf_df,
            data2   =>  iz_df,
            d_out   =>  sum
		);
		
	c_new <= sum;
	
	nor_sum.data (31) <= '0';
    nor_sum.data (30 downto 23) <= std_logic_vector(unsigned(sum.data (30 downto 23)) + p);
    nor_sum.data (22 downto 0) <= sum.data (22 downto 0);
    nor_sum.flag <= sum.flag;
    nor_sum.gate <= sum.gate;
    
    u3: cnv_f2i
        port map (
            reset   => rst,
            clock   => clk,
            clken   => '1',
            data1   => nor_sum.data,
            d_out   => int_sum.data
        );
        
    process (clk)
    begin
        if rst = '1' then
            int_sum.flag <= '0';
            int_sum.gate <= (others => '0');
        elsif rising_edge(clk) then
            int_sum.flag <= nor_sum.flag;
            int_sum.gate <= nor_sum.gate;
        end if;
   end process;
    
    address <= int_sum.data (p+2 downto p); 

    process (clk, rst)
    begin
        if rst = '1' then
            lut_out <= (others => '0');
            reg_sum.data <= (others => '0');
            reg_sum.gate <= (others => '0');
            reg_sum.flag <= '0';
        elsif rising_edge(clk) then
            lut_out <= rom (to_integer(unsigned(address)));
            reg_sum <= sum;
        end if;
    end process;
    
    m <= lut_out (2**(n+1)-1 downto 2**n);
    q <= lut_out (2**n-1 downto 0);
	
	--abs_input <=  sum.data when sum.data(2**n-1) = '0' else (std_logic_vector(unsigned(not(sum.data)) + 1));                   
    --address <= abs_input (p+1 downto p-1);
    --lut_out <= rom (to_integer(unsigned(address)));
    --m <= lut_out (2**(n+1)-1 downto 2**n);
    --q <= lut_out (2**n-1 downto 0);
    
    st3 <= sum_reg.flag;
    
    u4: mac_f32
        port map (
            reset       => rst,
            clock       => clk,
            clken       => '1',
            start       => st3,
            data1       => reg_sum,
            data2.data  => m,
            data2.flag  => '1',
            data2.gate  => "000",
            data3.data  => q,
            data3.flag  => '1',
            data3.gate  => "000",
            d_out       => tanh_c
        );
		
	-- o might need a shift register
	
	st4 <= tanh_c.flag and o_df.flag;
		
	u5: mul_f32
		port map (
            reset   =>  rst_mul,
            clock   =>  clk,
            clken   =>  clken,
            start   =>  st4, 
            data1   =>  tanh_c,
            data2   =>  o_df,
            d_out   =>  mul
		);
    
    h_new <= mul;
    
end Behavioral;