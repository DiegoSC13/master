# corregir_indices_par.py

import pickle
import argparse

def restore_indexes_par(par_file, pkl_file, output_file):
    # Leer los nuevos índices del archivo .pkl
    with open(pkl_file, 'rb') as f:
        nuevos_indices = pickle.load(f)
        print("Índices originales cargados:", nuevos_indices)

    # Leer el archivo .par
    with open(par_file, 'r') as f:
        lineas = f.readlines()

    # Separar el encabezado de los datos
    encabezado = []
    datos = []
    for linea in lineas:
        if linea.strip() == '' or linea.startswith('C'):
            encabezado.append(linea)
        else:
            datos.append(linea)

    if len(nuevos_indices) != len(datos):
        print(f"Cantidad de partículas en el .par: {len(datos)}")
        print(f"Cantidad de índices en el .pkl: {len(nuevos_indices)}")
        raise ValueError("El número de índices en el .pkl no coincide con el número de partículas en el .par")

    # Corregir los índices en los datos
    datos_corregidos = []
    for nuevo_idx, linea in zip(nuevos_indices, datos):
        partes = linea.strip().split()
        partes[0] = str(nuevo_idx)
        nueva_linea = '{:>8} {:>7} {:>7} {:>8} {:>10} {:>10} {:>7} {:>8} {:>8} {:>8} {:>7} {:>7} {:>8} {:>8} {:>10} {:>7} {:>7}'.format(*partes)
        datos_corregidos.append(nueva_linea + '\n')

    # Guardar el nuevo archivo .par
    with open(output_file, 'w') as f:
        f.writelines(encabezado[0])
        f.writelines(datos_corregidos)
        f.writelines(encabezado[1])
        f.writelines(encabezado[2])

    print(f"Archivo corregido guardado en {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Corregir los índices de un archivo .par usando un archivo .pkl.")
    parser.add_argument('--par_file', type=str, required=True, help='Ruta del archivo .par de entrada')
    parser.add_argument('--pkl_file', type=str, required=True, help='Ruta del archivo .pkl con los nuevos índices')
    parser.add_argument('--output_file', type=str, required=True, help='Ruta del archivo .par de salida')

    args = parser.parse_args()

    restore_indexes_par(args.par_file, args.pkl_file, args.output_file)
