library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity brom is
    port (
        clk : in STD_LOGIC;
        addr : in UNSIGNED(4 downto 0);
        data : out STD_LOGIC_VECTOR(31 downto 0)
    );
end brom;

architecture Behavioral of brom is
    type rom_type is array (0 to 32) of STD_LOGIC_VECTOR(31 downto 0);
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
        X"003F271F",
        X"FF49D5A7",
        X"FF7FAFBC",
        X"0094180C",
        X"0096E178",
        X"FFA76976",
        X"0126B768",
        X"01EA3414",
        X"018E7BCE",
        X"00000000",
        X"00000000",
        X"00000000",
        X"00000000",
        X"00000000",
        X"00000000",
        X"00000000",
        X"00000000"
        X"00000000"
    );
begin
    process(clk)
    begin
        if rising_edge(clk) then
            data <= rom(to_integer(addr));
        end if;
    end process;
end Behavioral;
