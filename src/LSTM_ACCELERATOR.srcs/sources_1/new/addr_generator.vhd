----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/14/2024 11:13:39 AM
-- Design Name: 
-- Module Name: addr_generator - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity addr_generator is
    generic
    (
        cells       : integer;
        inputs      : integer;
        x_ad_dim    : integer;
        h_ad_dim    : integer;
        w_ad_dim    : integer;
        b_ad_dim    : integer
    );  
    port
    (
        clk         : in  std_logic;
        rst         : in  std_logic;
        en          : in  std_logic;
        o_en        : in  std_logic;
        h_ad        : out std_logic_vector (h_ad_dim-1 downto 0);
        x_ad        : out std_logic_vector (x_ad_dim-1 downto 0);
        x_se        : out integer;
        sel         : out std_logic;
        w_ad        : out std_logic_vector ((w_ad_dim+b_ad_dim)-1 downto 0);
        b_ad        : out std_logic_vector (b_ad_dim-1 downto 0);
        hw_ad       : out std_logic_vector (h_ad_dim-1 downto 0);
        newline     : out std_logic;
        endline     : out std_logic;
        ready       : out std_logic
    );  
end addr_generator;

architecture Behavioral of addr_generator is

    constant xdim: integer := cells + inputs;
    constant ydim: integer := 4 * cells;

    signal wi, wj, xj, hi, hwi, xi: integer;
    signal x_rs: std_logic;
    
    signal nl, el: std_logic;

begin

    process(clk, rst)
    begin
        if rst = '1' then
            ready <= '0';
            x_rs <= '1';
            --xi <= 0;
            --hi <= 0;
            xj <= 0;
            wi <= 0;
            wj <= 0;
            hwi <= 0;
            el <= '0';
        else
            if rising_edge(clk) then
                if en = '1' then
                    el <= '1';
                    if wj = ydim-1 and wi = xdim-1 then -- se matrice è finita
                        wj <= 0; -- riporto contatore verticale a 0
                        wi <= 0; -- riporto contatore orizzontale a 0
                        --xi <= 0; -- resetto selettore input
                        --hi <= 0; -- resetto contatore precedenti output
                        if xj = x_ad_dim-1 then -- se sequenza input è finita
                            xj <= 0;  -- riporto contatore sequenza a 0
                            ready <= '1'; -- comunico di caricare nuovo input
                        else -- se sequenza input non è finita
                            xj <= xj + 1; -- avanzo contatore sequenza
                            ready <= '0'; -- comunico di avanzare al prossimo input
                        end if;
                    else -- se matrice non è finita
                        ready <= '0';
                        if wi = xdim-1 then -- se riga è finita
                            --xi <= 0; -- resetto selettore input
                            --hi <= 0; -- resetto contatore precedenti output
                            wi <= 0; -- resetto contatore orizzontale
                            wj <= wj + 1; -- avanzo contatore verticale
                        elsif wi < inputs then -- se siamo nella sezione input
                            wi <= wi + 1; -- avanzo contatore orizzontale
                            --xi <= xi + 1; -- avanzo selettore input
                        else -- se siamo nella sezione precedenti output
                            wi <= wi + 1; -- avanzo contatore orizzontale
                            --hi <= hi + 1; -- avanzo contatore precedenti output
                        end if;
                    end if;
                else 
                    el <= '0';
                end if;
                
                if o_en = '1' then
                    if hwi = 3 then
                        hwi <= 0;
                    else
                        hwi <= hwi + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    x_ad <= std_logic_vector(to_unsigned(xj, x_ad_dim));
    w_ad <= std_logic_vector(to_unsigned(wj * xdim + wi, w_ad_dim+b_ad_dim));
    b_ad <= std_logic_vector(to_unsigned(wj, b_ad_dim));
    
    xi <= wi - 1;
    x_se <= xi when xi > 0 else 0;
    hi <= wi - 5;
    h_ad <= std_logic_vector(to_unsigned(hi, h_ad_dim)) when hi > 0 else (others => '0');
    sel <= '0' when xi > -1 and xi < inputs else '1';
    
    hw_ad <= std_logic_vector(to_unsigned(hwi, h_ad_dim));
    
    newline <= '1' when xi = 0 and el = '1' else '0';
    endline <= '1' when xi = -1 and el = '1'  else '0';

end Behavioral;