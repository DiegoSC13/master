import sys

def modify_star(archivo_entrada, archivo_salida):
    """
    Modifica un archivo .star comentando el bloque data_optics y la línea '_rlnImageName'.
    - Comenta el bloque 'data_optics'
    - Comenta '_rlnImageName'
    """
    with open(archivo_entrada, 'r') as f:
        lineas = f.readlines()

    nueva_lista = []
    en_optics = False
    en_particles = False
    header_modificado = False

    for linea in lineas:
        linea_strip = linea.strip()

        if linea_strip.startswith("data_optics"):
            en_optics = True
            nueva_lista.append("#" + linea)
            continue

        if en_optics:
            if linea_strip == "data_particles":
                en_optics = False
                en_particles = True
                nueva_lista.append(linea)
                continue
            else:
                nueva_lista.append("#" + linea)
                continue

        if en_particles and not header_modificado:
            if linea_strip.startswith("_rlnImageName"):
                nueva_lista.append("#" + linea)
            else:
                nueva_lista.append(linea)
        else:
            nueva_lista.append(linea)

    with open(archivo_salida, 'w') as f:
        f.writelines(nueva_lista)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: python modify_star.py <archivo_entrada> <archivo_salida>")
        sys.exit(1)

    archivo_entrada = sys.argv[1]
    archivo_salida = sys.argv[2]

    modify_star(archivo_entrada, archivo_salida)
