import numpy as np
import struct

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


# Load numpy array from file
wx = np.load('./Data/Weights/lstm_weight_ih_l0.npy')
bx = np.load('./Data/Weights/lstm_bias_ih_l0.npy')
wh = np.load('./Data/Weights/lstm_weight_hh_l0.npy')
bh = np.load("./Data/Weights/lstm_bias_hh_l0.npy")

# Create VHDL for ROM
with open('wrom.vhd', 'w') as f:
    f.write('library IEEE;\n')
    f.write('use IEEE.STD_LOGIC_1164.ALL;\n')
    f.write('use IEEE.NUMERIC_STD.ALL;\n')
    f.write('entity wrom is\n')
    f.write('    port (\n')
    f.write('        clk : in STD_LOGIC;\n')
    f.write('        addr : in UNSIGNED(7 downto 0);\n')
    f.write('        data : out STD_LOGIC_VECTOR(31 downto 0)\n')
    f.write('    );\n')
    f.write('end wrom;\n')
    f.write('\n')
    f.write('architecture Behavioral of wrom is\n')
    f.write('    type rom_type is array (0 to 255) of STD_LOGIC_VECTOR(31 downto 0);\n')
    f.write('    signal rom : rom_type := (\n')
    i = 0
    for yi in range(wx.shape[0]):
        for xi_a in range(wx.shape[1]):
            i = i + 1
            f.write(f'        {int_to_hex_complement(round(wx[yi,xi_a]*2**24))},\n')
        for xi_b in range(wh.shape[1]):
            i = i + 1
            f.write(f'        {int_to_hex_complement(round(wh[yi,xi_b]*2**24))},\n')
    for j in range(255-i):
        f.write(f'        {int_to_hex_complement(0)},\n')
    f.write(f'        {int_to_hex_complement(0)}\n')  
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
    
