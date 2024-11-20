import numpy as np
import struct

address_length = 8
ceil_value = 4

def int_to_hex_complement(num):
    # Applica il complemento a 2 su un numero a 32 bit
    if num < 0:
        # Se il numero è negativo, calcola il complemento a 2
        num = (1 << 32) + num
    else:
        # Per i numeri positivi non c'è bisogno di modifiche
        num = num & 0xFFFFFFFF  # Assicura che rimanga a 32 bit

    # Converte il risultato in esadecimale con 8 caratteri
    return f'X"{num:08X}"'

def tanh_gen():
    x = np.linspace(0, ceil_value-(ceil_value/(2**address_length)), 2**address_length)
    y = np.tanh(x+ceil_value/(2**(address_length+1)))
    return y

# Load numpy array from file
tanh_values = tanh_gen()

# Create VHDL for ROM
with open('lut.vhd', 'w') as f:
    f.write('library IEEE;\n')
    f.write('use IEEE.STD_LOGIC_1164.ALL;\n')
    f.write('use IEEE.NUMERIC_STD.ALL;\n')
    f.write('entity lut is\n')
    f.write('    port (\n')
    f.write('        clk : in STD_LOGIC;\n')
    f.write('        addr : in UNSIGNED('+ str(address_length-1) + ' downto 0);\n')
    f.write('        en : in STD_LOGIC;\n')
    f.write('        data : out STD_LOGIC_VECTOR(31 downto 0)\n')
    f.write('    );\n')
    f.write('end lut;\n')
    f.write('\n')
    f.write('architecture Behavioral of lut is\n')
    f.write('    type rom_type is array (0 to ' + str(2**address_length-1) + ') of STD_LOGIC_VECTOR(31 downto 0);\n')
    f.write('    signal rom : rom_type := (\n')
    i = 0
    for value in tanh_values:
        f.write(f'        {int_to_hex_complement(int(value * 2**24))}')
        if i < 2**address_length-1:
            f.write(',')
        f.write('\n')
        i += 1
    f.write('    );\n')
    f.write('begin\n')
    f.write('    process(clk)\n')
    f.write('    begin\n')
    f.write('        if rising_edge(clk) then\n')
    f.write('            if en = \'1\' then\n')
    f.write('               data <= rom(to_integer(addr));\n')
    f.write('            end if;\n')
    f.write('        end if;\n')
    f.write('    end process;\n')
    f.write('end Behavioral;\n')
    f.close()
    
