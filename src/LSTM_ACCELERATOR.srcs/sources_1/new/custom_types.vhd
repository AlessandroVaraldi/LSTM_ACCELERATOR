----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.09.2024 15:38:50
-- Design Name: 
-- Module Name: custom_types - Behavioral
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


package custom_types is

    --constant precision: integer := 5;
    --constant binarypoint: integer := 24; 
    
    constant precision: integer := 5;

    type weight_array is record
        w_x: std_logic_vector (2**precision-1 downto 0);
        b_x: std_logic_vector (2**precision-1 downto 0);
        w_h: std_logic_vector (2**precision-1 downto 0);
        b_h: std_logic_vector (2**precision-1 downto 0);
    end record;
    
    type dataflow is record
        data: std_logic_vector (2**precision-1 downto 0);
        flag: std_logic;
        gate: std_logic_vector (2 downto 0);
        
        -- input    : 000
        -- output   : 001
        -- state    : 010
        -- f gate   : 100
        -- i gate   : 101
        -- z gate   : 110
        -- o gate   : 111
    end record;
    
    type input_array is array (0 to 4) of std_logic_vector (2**precision-1 downto 0);
    
 end custom_types;