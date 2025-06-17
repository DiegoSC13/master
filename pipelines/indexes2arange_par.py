# renumerar_par.py

import argparse
import re

def indexes2arange_par(input_par, output_par):
    with open(input_par, 'r') as f:
        lineas = f.readlines()

    nuevas_lineas = []
    contador = 1
    data_pattern = re.compile(r"^\s*\d+\s+[-\d\.]")

    for linea in lineas:
        if data_pattern.match(linea):
            # Sobrescribe el índice manteniendo el formato de columnas
            nuevo_indice = f"{contador:7d}"  # Mismo ancho que el índice original
            linea_modificada = nuevo_indice + linea[7:]
            nuevas_lineas.append(linea_modificada)
            contador += 1
        else:
            # Encabezado u otra línea: la dejamos igual
            nuevas_lineas.append(linea)

    with open(output_par, 'w') as f:
        f.writelines(nuevas_lineas)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Renumerar índices de imagen en un archivo .par manteniendo el formato.")
    parser.add_argument('--input_par', type=str, required=True, help='Ruta del archivo .par de entrada')
    parser.add_argument('--output_par', type=str, required=True, help='Ruta del archivo .par de salida')

    args = parser.parse_args()
    indexes2arange_par(args.input_par, args.output_par)
