import os
import glob
import argparse
import mrcfile
import numpy as np

def load_mrcs_from_directory(input_dir, recursive=False):
    input_files = sorted(glob.glob(os.path.join(input_dir, "**", "*.mrc"), recursive=True))
    if not input_files:
        raise FileNotFoundError(f"No se encontraron archivos .mrc en {input_dir} (ni subdirectorios)")

    stack = []
    reference_shape = None

    for filepath in input_files:
        with mrcfile.open(filepath, permissive=True) as mrc:
            data = mrc.data

            if reference_shape is None:
                reference_shape = data.shape
            elif data.shape != reference_shape:
                raise ValueError(f"El archivo {filepath} tiene dimensiones {data.shape}, que no coinciden con {reference_shape}")
            
            stack.append(data)

    stack_array = np.stack(stack, axis=0)
    return stack_array


def main():
    parser = argparse.ArgumentParser(description="Apilar archivos .mrc en un solo archivo .mrcs")
    parser.add_argument("--input_dir", required=True, help="Directorio con archivos .mrc")
    parser.add_argument("--output_path", required=True, help="Ruta del archivo de salida .mrcs (incluyendo el nombre)")
    parser.add_argument("--recursive", action="store_true", help="Si se incluye, busca archivos .mrc recursivamente en subdirectorios")
    args = parser.parse_args()

    print(f"📂 Leyendo archivos desde: {args.input_dir}")
    print(f"💾 Guardando stack en: {args.output_path}")

    stack = load_mrcs_from_directory(args.input_dir)

    with mrcfile.new(args.output_path, overwrite=True) as mrc:
        mrc.set_data(stack.astype(np.float32))
    
    print("✅ Stack creado exitosamente.")

if __name__ == "__main__":
    main()
