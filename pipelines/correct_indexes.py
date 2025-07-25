import argparse

def corregir_indices_par(input_file, output_file):
    with open(input_file, 'r') as f_in, open(output_file, 'w') as f_out:
        for i, line in enumerate(f_in):
            # Saltar líneas vacías o comentarios
            if not line.strip() or line.strip().startswith('C'):
                f_out.write(line)
                continue

            parts = line.strip().split()
            if len(parts) < 2:
                f_out.write(line)
                continue

            # Reemplazar el índice por el contador i + 1
            parts[0] = str(i)

            # Reconstruir la línea con formato simple (ajustar si se desea más precisión)
            new_line = " ".join(f"{float(p):7.2f}" if '.' in p else f"{int(p):7d}" for p in parts)
            f_out.write(new_line + "\n")

    print(f"Archivo corregido escrito en: {output_file}")

def main():
    parser = argparse.ArgumentParser(description="Corrige los índices de un archivo .par corrupto.")
    parser.add_argument("input_file", help="Ruta al archivo .par de entrada")
    parser.add_argument("output_file", help="Ruta al archivo .par corregido de salida")

    args = parser.parse_args()
    corregir_indices_par(args.input_file, args.output_file)

if __name__ == "__main__":
    main()
