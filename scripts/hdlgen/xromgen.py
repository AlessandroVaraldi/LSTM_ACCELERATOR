import numpy as np
import struct

def i2hex(num):
    # Applica il complemento a 2 su un numero a 32 bit
    if num < 0:
        # Se il numero è negativo, calcola il complemento a 2
        num = (1 << 32) + num
    else:
        # Per i numeri positivi non c'è bisogno di modifiche
        num = num & 0xFFFFFFFF  # Assicura che rimanga a 32 bit

    # Converte il risultato in esadecimale con 8 caratteri
    return f'X"{num:08X}"'

def i2hex_raw(num):
    # Applica il complemento a 2 su un numero a 32 bit
    if num < 0:
        # Se il numero è negativo, calcola il complemento a 2
        num = (1 << 32) + num
    else:
        # Per i numeri positivi non c'è bisogno di modifiche
        num = num & 0xFFFFFFFF  # Assicura che rimanga a 32 bit

    # Converte il risultato in esadecimale con 8 caratteri
    return f'{num:08X}'


# Load numpy array from file
data = np.load('./Data/xtest.npy')

# Create VHDL for ROM
with open('xrom.vhd', 'w') as f:
    f.write('library IEEE;\n')
    f.write('use IEEE.STD_LOGIC_1164.ALL;\n')
    f.write('use IEEE.NUMERIC_STD.ALL;\n')
    f.write('entity xrom is\n')
    f.write('    port (\n')
    f.write('        clk : in STD_LOGIC;\n')
    f.write('        addr : in UNSIGNED(7 downto 0);\n')
    f.write('        data : out STD_LOGIC_VECTOR(127 downto 0)\n')
    f.write('    );\n')
    f.write('end xrom;\n')
    f.write('\n')
    f.write('architecture Behavioral of xrom is\n')
    f.write('    type rom_type is array (0 to 255) of STD_LOGIC_VECTOR(127 downto 0);\n')
    f.write('    signal rom : rom_type := (\n')
    for i in range(255):
        f.write('        X"' +i2hex_raw(round(data[i,0,0]*2**24))+i2hex_raw(round(data[i,0,1]*2**24))+i2hex_raw(round(data[i,0,2]*2**24))+i2hex_raw(round(data[i,0,3]*2**24))+i2hex_raw(round(data[i,0,4]*2**24))+ '",\n')
    f.write('        X"' +i2hex_raw(round(data[255,0,0]*2**24))+i2hex_raw(round(data[255,0,1]*2**24))+i2hex_raw(round(data[255,0,2]*2**24))+i2hex_raw(round(data[255,0,3]*2**24))+i2hex_raw(round(data[255,0,4]*2**24))+ '"\n')
    f.write('    );\n')
    f.write('begin\n')
    f.write('    process(clk)\n')
    f.write('    begin\n')
    f.write('        if rising_edge(clk) then\n')
    f.write('            data <= rom(to_integer(addr));\n')
    f.write('        end if;\n')
    f.write('    end process;\n')
    f.write('end Behavioral;\n')
    f.close()
    
