import numpy as np
import matplotlib.pyplot as plt
import struct

def float_to_fixed_8_24(value):
    """
    Converte un valore float in formato fixed-point 8.24 con rappresentazione esadecimale.
    """
    # Calcola il valore scalato in fixed-point 8.24 (moltiplicando per 2^24)
    scaled_value = int(round(value * (1 << 24)))
    
    # Se il valore è negativo, converte a complemento a due per rappresentazione hex
    if scaled_value < 0:
        scaled_value = (1 << 32) + scaled_value

    # Ritorna la rappresentazione esadecimale a 8 cifre
    return f"0x{scaled_value:08X}"

def float_to_hex(value):
    """
    Converte un numero floating-point in rappresentazione esadecimale IEEE 754 single-precision.
    """
    # Usa struct.pack per ottenere il valore binario e lo converte in esadecimale
    return f"0x{struct.unpack('<I', struct.pack('<f', value))[0]:08X}"

def approx_tanh(n):
    """
    Approssima la funzione tanh con n intervalli lineari.
    
    Parameters:
    - n (int): Numero di intervalli lineari per l'approssimazione.
    
    Returns:
    - coeffs (list of tuples): Lista dei coefficienti (m, q) per le rette approssimanti.
    - intervals (list of tuples): Lista degli intervalli per ciascuna retta.
    """
    # Imposta il range dell'approssimazione (ad esempio [0, 4] copre la maggior parte del dominio tanh)
    x_min, x_max = 0, 4
    
    # Suddivide l'intervallo in n sezioni
    x_points = np.linspace(x_min, x_max, n + 1)
    coeffs = []
    intervals = []
    
    for i in range(n):
        # Estremi dell'intervallo
        x1, x2 = x_points[i], x_points[i + 1]
        
        # Valori di tanh nei punti x1 e x2
        y1, y2 = np.tanh(x1), np.tanh(x2)
        
        # Calcolo dei coefficienti della retta: y = m*x + q
        m = (y2 - y1) / (x2 - x1)  # coefficiente angolare
        q = y1 - m * x1            # intercetta
        
        # Converte m e q in formato fixed-point 8.24 e floating-point hex
        m_fixed = float_to_fixed_8_24(m)
        q_fixed = float_to_fixed_8_24(q)
        m_hex = float_to_hex(m)
        q_hex = float_to_hex(q)
        
        # Salva i coefficienti e gli estremi dell'intervallo
        coeffs.append(((m, m_fixed, m_hex), (q, q_fixed, q_hex)))
        intervals.append((x1, x2))
    
    return coeffs, intervals

# Esempio di utilizzo
n = 8  # Numero di intervalli
coeffs, intervals = approx_tanh(n)

# Stampa dei coefficienti in formato decimale, fixed-point 8.24 e floating-point hex
print("Coefficienti delle rette approssimanti (decimale, fixed-point 8.24, e hex floating-point) e relativi intervalli:")
for i in range(n):
    print(f"Intervallo {i+1}: {intervals[i]}")
    print(f"  Coefficiente angolare (m):")
    print(f"    Decimale = {coeffs[i][0][0]}, Fixed-point 8.24 = {coeffs[i][0][1]}, Hex float = {coeffs[i][0][2]}")
    print(f"  Intercetta (q):")
    print(f"    Decimale = {coeffs[i][1][0]}, Fixed-point 8.24 = {coeffs[i][1][1]}, Hex float = {coeffs[i][1][2]}")

# Plot della funzione tanh e dell'approssimazione lineare
x_vals = np.linspace(0, 4, 400)
y_tanh = np.tanh(x_vals)

plt.figure(figsize=(10, 6))
plt.plot(x_vals, y_tanh, label="tanh(x)", color="blue", linewidth=2)

# Aggiungi le approssimazioni lineari
for i in range(n):
    x1, x2 = intervals[i]
    m, q = coeffs[i][0][0], coeffs[i][1][0]  # Coefficienti decimali per il plot
    x_approx = np.linspace(x1, x2, 50)
    y_approx = m * x_approx + q
    plt.plot(x_approx, y_approx, label=f"Intervallo {i+1}", linestyle="--")

plt.xlabel("x")
plt.ylabel("y")
plt.title(f"Approssimazione della funzione tanh con {n} intervalli lineari")
plt.legend()
plt.grid(True)
plt.show()
