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

package components_i32 is

    component mac is
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

   component m_transformer is
       generic (n: integer; p: integer);
	   port
	   (
		  reset   : in  std_logic;
		  clock   : in  std_logic;
		  clken	  : in  std_logic;	
		  m       : in  std_logic_vector (2**n-1 downto 0);			
		  m_t     : out std_logic_vector (2**n-1 downto 0);
		  m_s     : out std_logic_vector (2**n-1 downto 0)
	   );
   end component;
   
   component q_transformer is
       generic (n: integer; p: integer);
       port
       (
           reset   : in  std_logic;
           clock   : in  std_logic;
           clken   : in  std_logic;	
           q       : in  std_logic_vector (2**n-1 downto 0);			
           q_tp    : out std_logic_vector (2**n-1 downto 0);
           q_tn    : out std_logic_vector (2**n-1 downto 0);
           q_sp    : out std_logic_vector (2**n-1 downto 0);
           q_sn    : out std_logic_vector (2**n-1 downto 0)
       );
   end component;
   
    component multiplier is
        generic (n: integer; p: integer);
        port
        (
            reset   : in  std_logic;
            clock   : in  std_logic;
            clken	: in  std_logic;
            data1	: in  dataflow;		
            data2	: in  dataflow;	
            d_out	: out dataflow;	
            flags  	: out std_logic_vector (4 downto 0)
        );
    end component;
    
    component adder is
        generic (n: integer; p: integer);
        port
        (
            reset   : in  std_logic;
            clock   : in  std_logic;
            clken	: in  std_logic;
            data1	: in  dataflow;		
            data2	: in  dataflow;	
            d_out	: out dataflow;	
            flags  	: out std_logic_vector (4 downto 0)
        );
    end component;
    
end components_i32;

