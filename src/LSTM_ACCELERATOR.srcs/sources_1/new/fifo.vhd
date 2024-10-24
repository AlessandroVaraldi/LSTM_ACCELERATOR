library ieee;
use ieee.std_logic_1164.all;

use work.custom_types.all;

entity fifo_dataflow is
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
end fifo_dataflow;

architecture Behavioral of fifo_dataflow is
  type fifo_array is array (0 to DEPTH-1) of dataflow;
  signal fifo_mem : fifo_array;
  signal rd_ptr, wr_ptr : integer range 0 to DEPTH-1 := 0; -- Puntatori di lettura e scrittura
  signal fifo_count : integer range 0 to DEPTH := 0; -- Contatore degli elementi nella FIFO

begin

  -- Scrittura nella FIFO
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        wr_ptr <= 0;
        fifo_count <= 0;
      elsif wr_en = '1' and full = '0' then
        fifo_mem(wr_ptr) <= data_in;
        wr_ptr <= (wr_ptr + 1) mod DEPTH;
        --fifo_count <= fifo_count + 1;
      end if;
    end if;
  end process;

  -- Lettura dalla FIFO
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rd_ptr <= 0;
      elsif rd_en = '1' and empty = '0' then
        data_out <= fifo_mem(rd_ptr);
        rd_ptr <= (rd_ptr + 1) mod DEPTH;
        --fifo_count <= fifo_count - 1;
      end if;
    end if;
  end process;

  -- Indicatore FIFO piena e vuota
  --full <= '1' when fifo_count = DEPTH else '0';
  --empty <= '1' when fifo_count = 0 else '0';
  full <= '0';
  empty <= '0';

end Behavioral;

