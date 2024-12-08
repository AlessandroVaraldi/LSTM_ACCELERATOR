library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity m_transformer is
    generic (n: integer; p: integer);
	port
	(
		reset   : in  std_logic;
		clock   : in  std_logic;
		clken	: in  std_logic;	
		m     	: in  std_logic_vector (2**n-1 downto 0);			
		m_t     : out std_logic_vector (2**n-1 downto 0);
		m_s     : out std_logic_vector (2**n-1 downto 0)
	);
end m_transformer;

architecture Behavioral of m_transformer is
    
begin

    process (reset,clock)
    begin
        if reset = '1' then
            m_t <= (others => '0');
            m_s <= (others => '0');
        elsif rising_edge (clock) and clken = '1' then
            m_t <= m;
            m_s <= m(2**n-1) & m(2**n-1) & m (2**n-1 downto 2);
        end if;
    end process; 

end Behavioral;