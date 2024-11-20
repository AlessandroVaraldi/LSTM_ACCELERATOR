library ieee;
use ieee.std_logic_1164.all;
use numeric_std.all;

entity mac_unit is
    generic(
        inputs: positive := 5; 
        cells: positive := 3;
        n: positive := 5;
        p: positive := 24;
        c: positive := 1
    );
    port 
    (
        clk         : in  std_logic;
        rst         : in  std_logic;
        start       : in  std_logic;
        data_x      : in  input_array;
        ready       : out std_logic
    );
end mac_unit;

architecture Behavioral of LSTM_ACCELERATOR is

    function log2ceil(n : integer) return integer is
        variable result : integer := 0;
        variable temp : integer := n - 1;  -- Per arrotondare verso l'alto
    begin
        while temp > 0 loop
            temp := temp / 2;
            result := result + 1;
        end loop;
        return result;
    end function;

    function divide_and_ceil(dividend : integer; divisor : integer) return integer is
        variable result : integer;
    begin
        if divisor = 0 then
            -- Gestione del caso divisore uguale a zero
            result := 0;
        elsif dividend mod divisor = 0 then
            -- Se la divisione è esatta, restituisce solo il quoziente
            result := dividend / divisor;
        else
            -- Altrimenti arrotonda per eccesso
            result := (dividend / divisor) + 1;
        end if;
    return result;

    constant xdim: integer := inputs + cells;
    constant ydim: integer := cells * 4;
    constant area: integer := (inputs + cells) * cells * 4;

    constant input_groups: integer := divide_and_ceil(xdim, 8);

    type group is array (0 to 2**c-1) of std_logic_vector(2**n-1 downto 0);
    type groups is array (0 to input_groups-1) of group;

    signal placeholder: groups;
    signal mac_input: group;

    component shift_register is
        generic (
            l : integer := 8; -- Lunghezza dell'indirizzo (log2 della profondità del registro)
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
    end component;

    component mac_i32 is
        generic (n: integer; p: integer);
        port
        (
            reset   : in  std_logic;
            clock   : in  std_logic;
            clken	: in  std_logic;
            start   : in  std_logic;
            data1	: in  dataflow;				
            data2	: in  dataflow;		
            data3	: in  dataflow;		
            d_out	: out dataflow;	
            flags  	: out std_logic_vector(4 downto 0)
        );
    end component;

begin

    shiftreg_gen: 
    for i in 0 to inputs-1 generate
    m_i: shift_register
        generic map (l => xad_dim, n => n)
        port map (
            clk         => clk,
            rst         => rst,
            enable      => sh_en(i),
            addr        => x_ad,
            data_in     => data_x(i),
            data_out    => shift_out(i)
        );
    end generate;

    signal_gen:
    for i in 0 to xdim-1 generate
    i_uns <= to_unsigned(i, y'length);
    placeholder(i_uns(y'length downto 0))(i_uns(1 downto 0)) <= shift_out(i);
    end generate;

    -- mux per selezionare il gruppo di input
    -- ho input_groups gruppi di input e devo selezionarli uno alla volta
    -- quindi mi serve un multiplexer che in output restituisca il gruppo di input selezionato

    mac_gen:
    for i in 0 to 2**c-1 generate
    u_i: mac_i32
        generic map (n => n, p => p)
        port map (
            clock   => clk,
            reset   => rst,
            start   => mac_st,
            clken   => clken,
            data1   => mac_input(i),
            data2   => data_w,
            data3   => bias,
            d_out   => mac
        );
    end generate;