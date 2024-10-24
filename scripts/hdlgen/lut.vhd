library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity lut is
    port (
        clk : in STD_LOGIC;
        addr : in UNSIGNED(7 downto 0);
        en : in STD_LOGIC;
        data : out STD_LOGIC_VECTOR(31 downto 0)
    );
end lut;

architecture Behavioral of lut is
    type rom_type is array (0 to 255) of STD_LOGIC_VECTOR(31 downto 0);
    signal rom : rom_type := (
        X"0001FFFD",
        X"0005FFB8",
        X"0009FEB2",
        X"000DFC6E",
        X"0011F86B",
        X"0015F22D",
        X"0019E935",
        X"001DDD09",
        X"0021CD2E",
        X"0025B92D",
        X"0029A08F",
        X"002D82E0",
        X"00315FAF",
        X"0035368D",
        X"0039070E",
        X"003CD0C9",
        X"00409359",
        X"00444E59",
        X"0048016C",
        X"004BAC35",
        X"004F4E5C",
        X"0052E78E",
        X"00567779",
        X"0059FDD1",
        X"005D7A4D",
        X"0060ECAA",
        X"006454A6",
        X"0067B205",
        X"006B048E",
        X"006E4C0D",
        X"00718853",
        X"0074B932",
        X"0077DE83",
        X"007AF822",
        X"007E05EE",
        X"008107CA",
        X"0083FD9F",
        X"0086E758",
        X"0089C4E2",
        X"008C9631",
        X"008F5B3A",
        X"009213F7",
        X"0094C063",
        X"0097607F",
        X"0099F44D",
        X"009C7BD2",
        X"009EF717",
        X"00A16627",
        X"00A3C90F",
        X"00A61FDF",
        X"00A86AAA",
        X"00AAA985",
        X"00ACDC86",
        X"00AF03C5",
        X"00B11F5D",
        X"00B32F6C",
        X"00B5340D",
        X"00B72D61",
        X"00B91B89",
        X"00BAFEA6",
        X"00BCD6DC",
        X"00BEA450",
        X"00C06727",
        X"00C21F86",
        X"00C3CD95",
        X"00C5717D",
        X"00C70B64",
        X"00C89B75",
        X"00CA21D8",
        X"00CB9EB7",
        X"00CD123D",
        X"00CE7C94",
        X"00CFDDE5",
        X"00D1365D",
        X"00D28625",
        X"00D3CD68",
        X"00D50C51",
        X"00D6430A",
        X"00D771BE",
        X"00D89896",
        X"00D9B7BD",
        X"00DACF5C",
        X"00DBDF9C",
        X"00DCE8A7",
        X"00DDEAA4",
        X"00DEE5BC",
        X"00DFDA17",
        X"00E0C7DC",
        X"00E1AF31",
        X"00E2903D",
        X"00E36B26",
        X"00E44010",
        X"00E50F20",
        X"00E5D87B",
        X"00E69C44",
        X"00E75A9D",
        X"00E813AA",
        X"00E8C78B",
        X"00E97663",
        X"00EA2050",
        X"00EAC574",
        X"00EB65EE",
        X"00EC01DC",
        X"00EC995D",
        X"00ED2C8D",
        X"00EDBB8A",
        X"00EE4670",
        X"00EECD5B",
        X"00EF5065",
        X"00EFCFAA",
        X"00F04B42",
        X"00F0C348",
        X"00F137D5",
        X"00F1A8FF",
        X"00F216DF",
        X"00F2818D",
        X"00F2E91D",
        X"00F34DA7",
        X"00F3AF40",
        X"00F40DFD",
        X"00F469F2",
        X"00F4C332",
        X"00F519D3",
        X"00F56DE5",
        X"00F5BF7C",
        X"00F60EAA",
        X"00F65B81",
        X"00F6A610",
        X"00F6EE69",
        X"00F7349D",
        X"00F778BA",
        X"00F7BAD0",
        X"00F7FAEF",
        X"00F83924",
        X"00F8757D",
        X"00F8B009",
        X"00F8E8D5",
        X"00F91FEE",
        X"00F95560",
        X"00F98938",
        X"00F9BB82",
        X"00F9EC4A",
        X"00FA1B9A",
        X"00FA497E",
        X"00FA7601",
        X"00FAA12C",
        X"00FACB0A",
        X"00FAF3A6",
        X"00FB1B07",
        X"00FB4139",
        X"00FB6643",
        X"00FB8A2E",
        X"00FBAD03",
        X"00FBCECB",
        X"00FBEF8D",
        X"00FC0F50",
        X"00FC2E1E",
        X"00FC4BFC",
        X"00FC68F3",
        X"00FC8508",
        X"00FCA043",
        X"00FCBAAB",
        X"00FCD445",
        X"00FCED18",
        X"00FD052A",
        X"00FD1C80",
        X"00FD3321",
        X"00FD4911",
        X"00FD5E57",
        X"00FD72F6",
        X"00FD86F5",
        X"00FD9A58",
        X"00FDAD23",
        X"00FDBF5C",
        X"00FDD106",
        X"00FDE227",
        X"00FDF2C1",
        X"00FE02DA",
        X"00FE1275",
        X"00FE2196",
        X"00FE3041",
        X"00FE3E79",
        X"00FE4C42",
        X"00FE599F",
        X"00FE6693",
        X"00FE7322",
        X"00FE7F4F",
        X"00FE8B1C",
        X"00FE968D",
        X"00FEA1A4",
        X"00FEAC65",
        X"00FEB6D1",
        X"00FEC0EB",
        X"00FECAB6",
        X"00FED435",
        X"00FEDD69",
        X"00FEE655",
        X"00FEEEFB",
        X"00FEF75D",
        X"00FEFF7D",
        X"00FF075D",
        X"00FF0F00",
        X"00FF1667",
        X"00FF1D94",
        X"00FF2488",
        X"00FF2B46",
        X"00FF31CF",
        X"00FF3824",
        X"00FF3E48",
        X"00FF443C",
        X"00FF4A00",
        X"00FF4F98",
        X"00FF5504",
        X"00FF5A45",
        X"00FF5F5C",
        X"00FF644C",
        X"00FF6915",
        X"00FF6DB8",
        X"00FF7237",
        X"00FF7693",
        X"00FF7ACC",
        X"00FF7EE4",
        X"00FF82DC",
        X"00FF86B5",
        X"00FF8A6F",
        X"00FF8E0C",
        X"00FF918D",
        X"00FF94F2",
        X"00FF983D",
        X"00FF9B6D",
        X"00FF9E85",
        X"00FFA184",
        X"00FFA46C",
        X"00FFA73D",
        X"00FFA9F7",
        X"00FFAC9C",
        X"00FFAF2D",
        X"00FFB1A9",
        X"00FFB412",
        X"00FFB667",
        X"00FFB8AB",
        X"00FFBADC",
        X"00FFBCFD",
        X"00FFBF0C",
        X"00FFC10B",
        X"00FFC2FB",
        X"00FFC4DB",
        X"00FFC6AD",
        X"00FFC870",
        X"00FFCA26",
        X"00FFCBCE",
        X"00FFCD69",
        X"00FFCEF7",
        X"00FFD079",
        X"00FFD1EF",
        X"00FFD35A"
    );
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
               data <= rom(to_integer(addr));
            end if;
        end if;
    end process;
end Behavioral;
