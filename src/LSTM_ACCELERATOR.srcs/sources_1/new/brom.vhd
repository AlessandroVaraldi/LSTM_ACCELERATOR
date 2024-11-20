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
        X"00A45293",
        X"007C27C0",
        X"009BFDB0",
        X"002218CC",
        X"FFA886A4",
        X"FEFBB2E0",
        X"FFE5C27F",
        X"FFBD22AD",
        X"0019F896",
        X"00FC3886",
        X"0107A688",
        X"0196EC7A",
        X"00E45DA1",
        X"007A69E4",
        X"FFF24876",
        X"003F271F"
    );
begin
    process(clk)
    begin
        if rising_edge(clk) then
            temp <= rom(to_integer(addr));
        end if;
    end process;
    data <= temp (2**n - 1 + 24 - p downto 24 - p);
end Behavioral;
