library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity shift_register is
    generic (
        l : integer := 3; -- Lunghezza dell'indirizzo (log2 della profondità del registro)
        n : integer := 3  -- Dimensione della word (larghezza del dato)
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        enable  : in  std_logic; -- Segnale di enable per lo shift
        data_in : in  std_logic_vector(2**n-1 downto 0); -- Dato da inserire nella prima posizione
        addr    : in  std_logic_vector(l-1 downto 0); -- Indirizzo di lettura
        data_out: out std_logic_vector(2**n-1 downto 0)  -- Dato corrispondente all'indirizzo
    );
end shift_register;

architecture Behavioral of shift_register is
    -- Definisco la memoria come un array di 2^l celle, ognuna di dimensione n
    type reg_array is array (2**l-1 downto 0) of std_logic_vector(2**n-1 downto 0);
    signal shift_reg : reg_array := (others => (others => '0')); -- Inizializzo lo shift register a 0
begin
    process (clk, rst)
    begin
        if rst = '1' then
            -- Reset: pulisco tutto il contenuto del registro
            shift_reg <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if enable = '1' then
                -- Shift dei dati: tutti i dati avanzano di una posizione
                for i in 0 to 2**l-2 loop
                    shift_reg(i) <= shift_reg(i+1);
                end loop;
                -- Inserisco il nuovo dato nella prima posizione
                shift_reg(2**l-1) <= data_in;
            end if;
        end if;
    end process;

    -- Uscita del dato corrispondente all'indirizzo di lettura
    data_out <= shift_reg(to_integer(unsigned(addr)));
end Behavioral;
