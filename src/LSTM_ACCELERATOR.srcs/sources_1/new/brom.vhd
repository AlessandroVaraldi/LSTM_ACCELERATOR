library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity brom is
    generic (n: integer; p: integer; len: integer);
    port (
        clk : in STD_LOGIC;
        addr : in UNSIGNED(len-1 downto 0);
        data : out STD_LOGIC_VECTOR(2**n-1 downto 0)
    );
end brom;

architecture Behavioral of brom is
    type rom_type is array (0 to 15) of STD_LOGIC_VECTOR(31 downto 0);
    signal temp : std_logic_vector (31 downto 0);
    signal rom : rom_type := (
        X"3F245293",
        X"3EF84F80",
        X"3F1BFDB0",
        X"3E086330",
        X"BEAEF2B8",
        X"BF822690",
        X"BDD1EC08",
        X"BE85BAA6",
        X"3DCFC4B0",
        X"3F7C3886",
        X"3F83D344",
        X"3FCB763D",
        X"3F645DA1",
        X"3EF4D3C8",
        X"BD5B78A0",
        X"3E7C9C7C"
    );
begin

    rom <= (
        X"3F245293",
        X"3EF84F80",
        X"3F1BFDB0",
        X"3E086330",
        X"BEAEF2B8",
        X"BF822690",
        X"BDD1EC08",
        X"BE85BAA6",
        X"3DCFC4B0",
        X"3F7C3886",
        X"3F83D344",
        X"3FCB763D",
        X"3F645DA1",
        X"3EF4D3C8",
        X"BD5B78A0",
        X"3E7C9C7C"
    );
    
    process(clk)
    begin
        if rising_edge(clk) then
            temp <= rom(to_integer(addr));
        end if;
    end process;
    data <= temp (2**n - 1 + 24 - p downto 24 - p);
end Behavioral;
