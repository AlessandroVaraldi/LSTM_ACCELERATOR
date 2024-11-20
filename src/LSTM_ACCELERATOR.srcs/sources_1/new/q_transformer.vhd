library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity q_transformer is
    generic (n: integer; p: integer);
	port
	(
		reset   : in  std_logic;
		clock   : in  std_logic;
		clken	: in  std_logic;	
		q     	: in  std_logic_vector (2**n-1 downto 0);			
		q_tp    : out std_logic_vector (2**n-1 downto 0);
		q_tn    : out std_logic_vector (2**n-1 downto 0);
		q_sp    : out std_logic_vector (2**n-1 downto 0);
		q_sn    : out std_logic_vector (2**n-1 downto 0)
	);
end q_transformer;

architecture Behavioral of q_transformer is

    signal HALF_p, half_n: std_logic_vector (2**n-1 downto 0);
    
begin
    
    half_p <= (others => '0') when p = 0 else (2**n-1 downto p => '0') & '1' & (p-2 downto 0 => '0');
    half_n <= (others => '0') when p = 0 else (2**n-1 downto p => '0') & '1' & (p-2 downto 1 => '0') & '1';

    process (reset,clock)
    begin
        if reset = '1' then
            q_tp <= (others => '0');
            q_tn <= (others => '0');
            q_sp <= (others => '0');
            q_sn <= (others => '0');
        elsif rising_edge (clock) and clken = '1' then
            q_tp <= q;
            q_tn <= std_logic_vector(unsigned(not(q)) + 1);
            q_sp <= std_logic_vector(signed(q(2**n-1) & q(2**n-1 downto 1)) + signed(half_p));
            q_sn <= std_logic_vector(signed(not(q(2**n-1) & q(2**n-1 downto 1))) + signed(half_n));
        end if;
    end process; 

end Behavioral;