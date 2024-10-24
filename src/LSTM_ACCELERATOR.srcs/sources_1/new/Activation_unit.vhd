library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.custom_types.all;

entity Activation_unit is
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
end Activation_unit;

architecture Behavioral of Activation_unit is

    component fifo_dataflow is
        generic (
           DEPTH : integer := 16 -- Profondità della FIFO
        );
        port (
           clk      : in  std_logic;
           rst      : in  std_logic;
           wr_en    : in  std_logic; -- Segnale di abilitazione per la scrittura
           rd_en    : in  std_logic; -- Segnale di abilitazione per la lettura
           data_in  : in  dataflow; -- Dati in ingresso (32 bit)
           data_out : out dataflow; -- Dati in uscita (32 bit)
           full     : buffer std_logic; -- Indicatore di FIFO piena
           empty    : buffer std_logic  -- Indicatore di FIFO vuota
        );
    end component;
    
    signal fifo_out: dataflow;
    signal fifo_full, fifo_empty: std_logic;

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
    
    component mul2_i32 is 
        generic (n: integer; p: integer);
        port
        (
            reset   : in  std_logic;
            clock   : in  std_logic;
            clken	: in  std_logic;	
            data1	: in  dataflow;				
            d_out	: out dataflow;	
            flags  	: out std_logic_vector(4 downto 0)
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
    
    component inv_i32 is
        port
        (
            reset   : in  std_logic;
            clock   : in  std_logic;
            clken	: in  std_logic;	
            data1	: in  dataflow;			
            d_out	: out dataflow;	
            flags  	: out std_logic_vector(4 downto 0)
        );
    end component;
    
    signal read_reg: std_logic_vector (2**n+3 downto 0);
    signal read_df: dataflow;
    
    signal stage1, stage2, stage3: dataflow;
    signal times2, minus1, invert: dataflow;
    
    signal tansig, posneg: std_logic;
    signal tansig_v, posneg_v: std_logic_vector (7 downto 0);

    type state_type is (RESET, IDLE, PIPELINE);
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
    
    process (state, start, reading, fifo_out)
    begin
        case state is
            when RESET =>
            
                next_state <= IDLE;
                
            when IDLE =>
            
                if start = '1' and act_in.flag = '1' then
                    
                    next_state <= PIPELINE;
                
                else
                    
                    next_state <= IDLE;
                    
                end if;
                
            when PIPELINE =>

                if reading.flag = '1' then
                    read_reg (2**n-1 downto 0) <= reading.data;
                end if;
                
                if fifo_out.flag = '1' then
                    read_reg (2**n) <= fifo_out.flag;
                    read_reg (2**n+3 downto 2**n+1) <= fifo_out.gate;
                end if;

                next_state <= PIPELINE;
            when OTHERS =>
        end case;
    end process;
    
    -- TODO: overflow e underflow address
    process (rst, clk)
    begin
        if rst = '1' then
            rd_en <= '0';
            address <= (others => '0');
        elsif rising_edge(clk) then 
            if start = '1' and act_in.flag = '1' then
                address <= act_in.data (p+1 downto p-6);
                rd_en <= '1';
            else
                address <= (others => '0');
                rd_en <= '0';
            end if;
        end if;
    end process;
        
    m0: fifo_dataflow
        generic map (DEPTH => 16)
        port map (
            clk     => clk,
            rst     => rst,
            wr_en   => act_in.flag,
            rd_en   => reading.flag,
            data_in => act_in,
            data_out => fifo_out,
            full    => fifo_full,
            empty   => fifo_empty
        );
        
    read_df.data <= read_reg (2**n-1 downto 0);
    read_df.flag <= read_reg (2**n);
    read_df.gate <= read_reg (2**n+3 downto 2**n+1);
    
    tansig <= '1' when fifo_out.gate = "100" or fifo_out.gate = "101" or fifo_out.gate = "111" else '0';
    posneg <= '1' when fifo_out.data(31) = '1' else '0';
    
    f0: dff_chain 
        generic map (n => 8)
        port map (
            clock   => clk,
            reset   => rst,
            start   => tansig,
            q       => tansig_v
        );
        
    f1: dff_chain 
        generic map (n => 8)
        port map (
            clock   => clk,
            reset   => rst,
            start   => posneg,
            q       => posneg_v
        );
    
    -- attendo se sigm+ o tanh+
    -- inverto se sigm- p tanh-
    u0: inv_i32
        port map (
            reset   =>  rst,
            clock   =>  clk,
            clken   =>  clken,
            data1   =>  read_df,
            d_out   =>  invert
		);
		
	process (clk, rst)
	begin
	    if rst = '1' then
	        stage1.data <= (others => '0');
	        stage1.flag <= '0';
	    elsif rising_edge(clk) and clken = '1' then
	       if invert.flag = '1' then
	           stage1.flag <= '1';
	           if posneg_v(0) = '1' then
	               stage1 <= invert;
	           else
	               stage1 <= read_df;
	           end if;
	       end if;
	    end if;
	end process;
    
    
    -- attendo se tanh
    -- divido per 2 se sigm
    u1: mul2_i32
        generic map (n => n, p => p)
		port map (
            reset   =>  rst,
            clock   =>  clk,
            clken   =>  clken,
            data1   =>  stage1,
            d_out   =>  times2
		);
		
	process (clk, rst)
	begin
	    if rst = '1' then
	        stage2.data <= (others => '0');
	        stage2.flag <= '0';
	    elsif rising_edge(clk) and clken = '1' then
	       if times2.flag = '1' then
	           stage2.flag <= '1';
	           if tansig_v(2) = '1' then
	               stage2 <= times2;
	           else
	               stage2 <= stage1;
	           end if;
	       end if;
	    end if;
	end process;
    
    -- attendo se tanh
    -- aggiungo 1/2 se sigm
    u2: sum_i32
        generic map (n => n, p => p)
		port map (
            reset   =>  rst,
            clock   =>  clk,
            clken   =>  clken,
            data1   =>  stage2,
            data2.data   =>  x"00800000",
            data2.flag   =>  '1',
            data2.gate   =>  "000",
            d_out   =>  minus1
		);
		
    process (clk, rst)
	begin
	    if rst = '1' then
	        stage3.data <= (others => '0');
	        stage3.flag <= '0';
	    elsif rising_edge(clk) and clken = '1' then
	       if minus1.flag = '1' then
	           stage3.flag <= '1';
	           if tansig_v(4) = '1' then
	               stage3 <= minus1;
	           else
	               stage3 <= stage2;
	           end if;
	       end if;
	    end if;
	end process;

	act_out <= stage3;

end Behavioral;