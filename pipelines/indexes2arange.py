# renumerar_star.py

import re
import argparse

def indexes2arange(archivo_par, salida_par):
    with open(archivo_par, 'r') as f:
        lineas = f.readlines()

    nuevas_lineas = []
    contador = 1

    for linea in lineas:
        # Coincide con las líneas de datos que tienen formato tipo "12@archivo.mrcs"
        if re.match(r"^\s*\d+@.*", linea):
            partes = linea.strip().split()
            imagen, *resto = partes
            # Extrae solo la parte después del "@"
            _, nombre_archivo = imagen.split("@", 1)
            nuevo_imagen = f"{contador}@{nombre_archivo}"
            nuevas_lineas.append(f"{nuevo_imagen} {' '.join(resto)}\n")
            contador += 1
        else:
            nuevas_lineas.append(linea)

    with open(salida_par, 'w') as f:
        f.writelines(nuevas_lineas)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Renumerar índices de imagen en un archivo .par")
    parser.add_argument('--input_par', type=str, required=True, help='Ruta del archivo .par de entrada')
    parser.add_argument('--output_par', type=str, required=True, help='Ruta del archivo .par de salida')

    args = parser.parse_args()

    indexes2arange(args.input_par, args.output_par)
