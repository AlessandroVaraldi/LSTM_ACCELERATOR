library ieee;
use ieee.std_logic_1164.all;
use numeric_std.all;

entity pwl_activation_unit is
    port (
        clk: in std_logic;
        rst: in std_logic;
        start: in std_logic;
        x: in std_logic_vector(31 downto 0);
        y: out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of pwl_activation_unit is
    
    type rom_type is array (0 to 7) of STD_LOGIC_VECTOR(63 downto 0);
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

   signal x_reg, data_reg : std_logic_vector(31 downto 0) := (others => '0');

begin   

    process(clk, rst)
    begin
        if rst = '1' then
            x_reg <= (others => '0');
        elsif rising_edge(clk) then
            if start = '1' then
                x_reg <= x;
                data_reg <= rom(to_integer(unsigned(x_reg(25 downto 23))));
            end if;
            if data_reg.flag = '1' then
                y <= x_reg * data_reg(63 downto 32) + data_reg(31 downto 0);
            end if;
        end if;
    end process;


