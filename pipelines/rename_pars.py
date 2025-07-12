#!/usr/bin/env python3

import os
import re
import sys

def renombrar_parfiles_dos_digitos(directorio):
    """
    Renombra archivos .par en el directorio especificado cambiando 'clusterX' por 'clusterXX' con dos dígitos.
    """
    for nombre_archivo in os.listdir(directorio):
        if nombre_archivo.endswith(".par") and nombre_archivo.startswith("parfile_"):
            match = re.search(r'cluster(\d+)', nombre_archivo)
            if match:
                num_cluster = int(match.group(1))
                num_cluster_str = f"{num_cluster:02d}"
                nuevo_nombre = re.sub(r'cluster\d+', f'cluster{num_cluster_str}', nombre_archivo)

                ruta_vieja = os.path.join(directorio, nombre_archivo)
                ruta_nueva = os.path.join(directorio, nuevo_nombre)

                os.rename(ruta_vieja, ruta_nueva)
                print(f"Renombrado: {nombre_archivo} → {nuevo_nombre}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python renombrar_parfiles.py /ruta/al/directorio")
        sys.exit(1)

    directorio = sys.argv[1]

    if not os.path.isdir(directorio):
        print(f"Error: '{directorio}' no es un directorio válido.")
        sys.exit(1)

    renombrar_parfiles_dos_digitos(directorio)
