# restaurar_indices_star.py

import re
import pickle
import argparse

def arange2indexes(archivo_star, archivo_pkl, salida_star):
    # Cargar los índices originales
    with open(archivo_pkl, 'rb') as f:
        indices_originales = pickle.load(f)

    with open(archivo_star, 'r') as f:
        lineas = f.readlines()

    nuevas_lineas = []
    idx = 0

    for linea in lineas:
        if re.match(r"^\s*\d+@.*", linea):
            partes = linea.strip().split()
            _, nombre_archivo = partes[0].split("@", 1)
            nuevo_indice = indices_originales[idx]
            nueva_linea = f"{nuevo_indice}@{nombre_archivo} {' '.join(partes[1:])}\n"
            nuevas_lineas.append(nueva_linea)
            idx += 1
        else:
            nuevas_lineas.append(linea)

    with open(salida_star, 'w') as f:
        f.writelines(nuevas_lineas)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Restaurar los índices originales en un archivo .star usando un .pkl de índices.")
    parser.add_argument('--input_star', type=str, required=True, help='Ruta del archivo .star modificado')
    parser.add_argument('--pkl_file', type=str, required=True, help='Ruta del archivo .pkl con índices originales')
    parser.add_argument('--output_star', type=str, required=True, help='Ruta del archivo .star de salida restaurado')

    args = parser.parse_args()

    arange2indexes(args.input_star, args.pkl_file, args.output_star)
