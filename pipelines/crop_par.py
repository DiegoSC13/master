import sys

def crop_par(archivo_entrada, archivo_salida, n_filas_a_eliminar):
    """
    Lee un archivo .par, elimina las primeras n_filas_a_eliminar filas y guarda el resultado en un nuevo archivo.

    :param archivo_entrada: Ruta al archivo .par original
    :param archivo_salida: Ruta al nuevo archivo .par recortado
    :param n_filas_a_eliminar: Número de filas al principio del archivo que se deben eliminar
    """
    with open(archivo_entrada, 'r') as f_in:
        lineas = f_in.readlines()

    lineas_filtradas = []
    num_eliminadas = 0
    for linea in lineas:
        if linea.strip().startswith('D'):  # mantener comentarios
            lineas_filtradas.append(linea)
        elif num_eliminadas < n_filas_a_eliminar:
            num_eliminadas += 1
        else:
            lineas_filtradas.append(linea)

    with open(archivo_salida, 'w') as f_out:
        f_out.writelines(lineas_filtradas)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Uso: python crop_par.py <archivo_entrada> <archivo_salida> <n_filas_a_eliminar>")
        sys.exit(1)

    archivo_entrada = sys.argv[1]
    archivo_salida = sys.argv[2]
    try:
        n_filas_a_eliminar = int(sys.argv[3])
    except ValueError:
        print("El número de filas a eliminar debe ser un entero.")
        sys.exit(1)

    crop_par(archivo_entrada, archivo_salida, n_filas_a_eliminar)
