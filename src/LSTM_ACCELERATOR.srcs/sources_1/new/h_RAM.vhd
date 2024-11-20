library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity h_RAM is
    generic (
        n           : integer;
        len         : integer
    );
    port (
        clk         : in  std_logic;
        we          : in  std_logic;
        wr_addr     : in  std_logic_vector(len-1 downto 0);
        rd_addr     : in  std_logic_vector(len-1 downto 0);
        din         : in  std_logic_vector (2**n-1 downto 0);
        dout        : out std_logic_vector (2**n-1 downto 0)
    );
end entity h_RAM;

architecture Behavioral of h_RAM is
    type ram_type is array (0 to 2**len-1) of std_logic_vector (2**n-1 downto 0);
    signal ram : ram_type := (others => (others => '0'));
    signal addr_reg : std_logic_vector(1 downto 0);
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                -- Write the 4-word array to the selected row
                ram(to_integer(unsigned(wr_addr))) <= din;
            end if;
        end if;
    end process;

    -- Read operation (outputs the 4-word array from the selected row)
    dout <= ram(to_integer(unsigned(rd_addr)));

end architecture Behavioral;

