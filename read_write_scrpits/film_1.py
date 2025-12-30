import argparse

def reemplazar_film_por_uno(input_path, output_path):
    """
    Sustituye la columna FILM por 1 en un archivo .par, sin alterar el resto del contenido.
    Se asume que FILM es la 8ª columna en el archivo original.
    """
    with open(input_path, 'r') as f_in:
        lines = f_in.readlines()

    with open(output_path, 'w') as f_out:
        for line in lines:
            if not line.strip():
                continue  # Saltar líneas vacías

            if line.lstrip().startswith("C"):
                f_out.write(line)
                continue

            parts = line.strip().split()

            if len(parts) < 8:
                raise ValueError(f"Línea inválida, menos de 8 columnas: {line}")

            parts[7] = '1'  # FILM está en la posición 7 (índice base 0)

            # Volver a escribir línea con formato alineado
            C, PSI, THETA, PHI, SHX, SHY, MAG, FILM, DF1, DF2, ANGAST, OCC, neg_LogP, SIGMA, SCORE, CHANGE = parts

            nueva_linea = (
                f"{int(C):7d}{float(PSI):8.2f}{float(THETA):8.2f}{float(PHI):8.2f}"
                f"{float(SHX):10.2f}{float(SHY):10.2f}{int(MAG):8d}{int(FILM):6d}"
                f"{float(DF1):9.1f}{float(DF2):9.1f}{float(ANGAST):8.2f}{float(OCC):8.2f}"
                f"{float(neg_LogP):10.0f}{float(SIGMA):11.4f}{float(SCORE):8.2f}{float(CHANGE):8.2f}\n"
            )

            f_out.write(nueva_linea)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Sustituir columna FILM por 1 en archivo .par.")
    parser.add_argument("input", help="Archivo de entrada .par")
    parser.add_argument("output", help="Archivo de salida con FILM=1")
    args = parser.parse_args()

    reemplazar_film_por_uno(args.input, args.output)
