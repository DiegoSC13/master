import os
import re
import argparse
import pickle

def combinar_pars_con_indices_originales(directorio_pars, archivo_pkl, archivo_salida):
    # Filtrar archivos que terminan en "_cropped_index_restored.par"
    archivos_par = sorted([
        os.path.join(directorio_pars, f)
        for f in os.listdir(directorio_pars)
        if f.endswith("_cropped_index_restored.par")
    ])

    if not archivos_par:
        raise FileNotFoundError(f"No se encontraron archivos *_cropped_index_restored.par en {directorio_pars}")

    # Cargar los índices desde el archivo .pkl
    with open(archivo_pkl, 'rb') as f:
        particulas = pickle.load(f)

    # Cargar todos los archivos .par, separando encabezado y partículas
    datos_por_archivo = []
    for path in archivos_par:
        with open(path, 'r') as f:
            lineas = f.readlines()

        header = []
        datos = []
        for linea in lineas:
            if linea.strip() == '' or linea.strip().startswith('C'):
                header.append(linea)
            else:
                datos.append(linea)
        datos_por_archivo.append((header, datos))

    # Usamos el header del primer archivo
    header_final = datos_por_archivo[0][0]

    # Mover segunda y tercera línea del header al final
    if len(header_final) >= 3:
        segunda = header_final.pop(1)
        tercera = header_final.pop(1)  # el nuevo índice 1 es la tercera original
        lineas_extra = [segunda, tercera]
    else:
        lineas_extra = []

    nuevas_lineas = []

    # Contadores para acceder a las partículas por orden
    contadores = [0] * len(archivos_par)

    for archivo_idx in particulas:
        _, datos = datos_por_archivo[archivo_idx]
        idx = contadores[archivo_idx]
        if idx >= len(datos):
            raise IndexError(f"No hay suficientes partículas en el archivo {archivos_par[archivo_idx]} para el índice {idx}")
        nuevas_lineas.append(datos[idx])
        contadores[archivo_idx] += 1

    # Escribir el archivo combinado
    with open(archivo_salida, 'w') as f:
        f.writelines(header_final)
        f.writelines(nuevas_lineas)
        f.writelines(lineas_extra)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Combina archivos .par clásicos usando índices de un archivo .pkl.")
    parser.add_argument('--input_dir', type=str, required=True, help='Directorio que contiene los archivos .par')
    parser.add_argument('--labels_pkl', type=str, required=True, help='Ruta al archivo .pkl con los índices por archivo')
    parser.add_argument('--output_par', type=str, required=True, help='Ruta del archivo .par de salida combinado')

    args = parser.parse_args()

    combinar_pars_con_indices_originales(args.input_dir, args.labels_pkl, args.output_par)
