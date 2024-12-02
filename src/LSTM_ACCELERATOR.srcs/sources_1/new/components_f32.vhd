----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/19/2024 10:08:48 AM
-- Design Name: 
-- Module Name: components_i32 - Behavioral
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

use work.custom_types.all;

package components_f32 is

    component mac_f32 is
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
   
    component mul_f32 is
        port
        (
            reset   : in  std_logic;
            clock   : in  std_logic;
            clken	: in  std_logic;
		    start   : in  std_logic;	
            data1	: in  dataflow;		
            data2	: in  dataflow;	
            d_out	: out dataflow;	
            flags  	: out std_logic_vector(4 downto 0)
        );
    end component;
    
    component sum_f32 is
        port
        (
            reset   : in  std_logic;
            clock   : in  std_logic;
            clken	: in  std_logic;	
	       	start   : in  std_logic;
            data1	: in  dataflow;		
            data2	: in  dataflow;	
            d_out	: out dataflow;	
            flags  	: out std_logic_vector(4 downto 0)
        ); 
    end component;
    
end components_f32;

