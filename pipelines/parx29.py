import argparse

def convertir_a_frealignx(input_path, output_path):
    """
    Convierte un archivo .par del formato Frealign92 al formato FrealignX,
    respetando el formato exacto de columnas fijas.
    """
    with open(input_path, 'r') as f:
        lines = f.readlines()

    with open(output_path, 'w') as f:
        for line in lines:
            if not line.strip():
                continue  # Saltar líneas vacías

            if line.lstrip().startswith("C"):
                # Escribir encabezado original de FrealignX
                f.write(
                    "C           PSI   THETA     PHI       SHX       SHY     MAG  FILM      "
                    "DF1      DF2  ANGAST     OCC     -LogP      SIGMA   SCORE  CHANGE\n"
                )
                continue

            parts = line.strip().split()

            if len(parts) < 17:
                raise ValueError(f"Línea con menos de 17 columnas: {line}")
            elif len(parts) > 17:
                parts = parts[:17]

            (
                C, PSI, THETA, PHI, SHX, SHY, MAG, INCLUDE,
                DF1, DF2, ANGAST, PSHIFT, OCC, LogP, SIGMA, SCORE, CHANGE
            ) = parts

            neg_LogP = -float(LogP)

            line_out = (
                f"{int(C):7d}{float(PSI):8.2f}{float(THETA):8.2f}{float(PHI):8.2f}"
                f"{float(SHX):10.2f}{float(SHY):10.2f}{int(MAG):8d}{int(INCLUDE):6d}"
                f"{float(DF1):9.1f}{float(DF2):9.1f}{float(ANGAST):8.2f}{float(OCC):8.2f}"
                f"{neg_LogP:10.0f}{float(SIGMA):11.4f}{float(SCORE):8.2f}{float(CHANGE):8.2f}\n"
            )

            f.write(line_out)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convertir archivo .par de Frealign92 a FrealignX.")
    parser.add_argument("input", help="Archivo de entrada .par (Frealign92)")
    parser.add_argument("output", help="Archivo de salida .par (FrealignX)")
    args = parser.parse_args()

    convertir_a_frealignx(args.input, args.output)
