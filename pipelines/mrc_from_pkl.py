# generar_mrc.py

import os
import pickle
import numpy as np
import mrcfile
import argparse

def generar_mrc_desde_pkls(directorio_pkls, archivo_mrc_entrada, directorio_salida):
    # Cargar el stack original
    with mrcfile.open(archivo_mrc_entrada, permissive=True) as mrc:
        data = mrc.data  # numpy array: shape (N, Y, X)
        print("Shape del stack original:", data.shape)

    # Asegurar que el directorio de salida exista
    os.makedirs(directorio_salida, exist_ok=True)

    # Procesar cada archivo .pkl
    for nombre_pkl in os.listdir(directorio_pkls):
        if nombre_pkl.endswith('.pkl'):
            ruta_pkl = os.path.join(directorio_pkls, nombre_pkl)
            with open(ruta_pkl, 'rb') as f:
                indices = pickle.load(f)
                
            # Ajustar los índices de 1-based a 0-based
            indices = [i - 1 for i in indices]

            # Extraer las partículas correspondientes
            subset = data[indices]

            # Generar nombre del archivo .mrc de salida
            nombre_mrc = os.path.splitext(nombre_pkl)[0] + '.mrc'
            ruta_mrc_salida = os.path.join(directorio_salida, nombre_mrc)

            # Guardar el nuevo stack
            with mrcfile.new(ruta_mrc_salida, overwrite=True) as mrc_out:
                mrc_out.set_data(subset.astype(np.float32))

            print(f"Archivo guardado: {ruta_mrc_salida} con {len(indices)} partículas")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generar archivos .mrc a partir de archivos .pkl")
    parser.add_argument('--pkls_folder', type=str, required=True, help='Directorio que contiene los archivos .pkl')
    parser.add_argument('--mrc_filepath', type=str, required=True, help='Ruta del archivo .mrc original')
    parser.add_argument('--output_folder', type=str, required=True, help='Directorio donde se guardarán los nuevos .mrc')

    args = parser.parse_args()

    generar_mrc_desde_pkls(args.pkls_folder, args.mrc_filepath, args.output_folder)
