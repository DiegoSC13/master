import argparse

def convertir_formato(input_path, output_path):
    """
    Convierte un archivo .par del formato FrealignX al formato Frealign92
    respetando el formato exacto de columnas fijas.
    """
    with open(input_path, 'r') as f:
        lines = f.readlines()

    with open(output_path, 'w') as f:
        for line in lines:
            if not line.strip():
                continue  # Saltar líneas vacías

            if line.lstrip().startswith("C"):
                # Escribir encabezado deseado con espacios exactos
                f.write(
                    "C           PSI   THETA     PHI       SHX       SHY     MAG  INCLUDE   "
                    "DF1      DF2  ANGAST  PSHIFT     OCC      LogP      SIGMA   SCORE  CHANGE\n"
                )
                continue

            parts = line.strip().split()

            if len(parts) < 16:
                raise ValueError(f"Línea con menos de 16 columnas: {line}")
            elif len(parts) > 16:
                parts = parts[:16]

            (
                C, PSI, THETA, PHI, SHX, SHY, MAG, FILM,
                DF1, DF2, ANGAST, OCC, neg_LogP, SIGMA, SCORE, CHANGE
            ) = parts

            INCLUDE = 1
            PSHIFT = 0.00
            LogP = -float(neg_LogP)

            # Formato exacto por campo, alineado
            line_out = (
                f"{int(C):7d}{float(PSI):8.2f}{float(THETA):8.2f}{float(PHI):8.2f}"
                f"{float(SHX):10.2f}{float(SHY):10.2f}{int(MAG):8d}{INCLUDE:6d}"
                f"{float(DF1):9.1f}{float(DF2):9.1f}{float(ANGAST):8.2f}{PSHIFT:8.2f}"
                f"{float(OCC):8.2f}{LogP:9.0f}{float(SIGMA):10.4f}{float(SCORE):9.2f}{float(CHANGE):8.2f}\n"
            )

            f.write(line_out)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convertir archivo .par de FrealignX a Frealign92.")
    parser.add_argument("input", help="Archivo de entrada .par (FrealignX)")
    parser.add_argument("output", help="Archivo de salida .par (Frealign92)")
    args = parser.parse_args()

    convertir_formato(args.input, args.output)
