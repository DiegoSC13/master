import os
import argparse
import mrcfile
import numpy as np

def load_paths_from_txt(txt_path):
    base_dir = os.path.dirname(os.path.abspath(txt_path))
    with open(txt_path, 'r') as f:
        relative_paths = [line.strip() for line in f if line.strip()]
    full_paths = [os.path.join(base_dir, rel_path) for rel_path in relative_paths]
    print(f'{full_paths=}')
    return full_paths

def concatenate_mrcs(input_files, output_path):
    stack = []
    reference_shape = None

    for filepath in input_files:
        print(f"📥 Leyendo: {filepath}")
        with mrcfile.open(filepath, permissive=True) as mrc:
            data = mrc.data

            if data.ndim < 3:
                raise ValueError(f"{filepath} no parece ser un archivo .mrcs válido (dimensiones: {data.shape})")

            if reference_shape is None:
                reference_shape = data.shape[1:]
            elif data.shape[1:] != reference_shape:
                raise ValueError(f"Dimensiones incompatibles en {filepath}: {data.shape[1:]} vs {reference_shape}")

            stack.append(data)

    concatenated_stack = np.concatenate(stack, axis=0)

    with mrcfile.new(output_path, overwrite=True) as mrc:
        mrc.set_data(concatenated_stack.astype(np.float32))

    print(f"✅ Stack combinado guardado en: {output_path} ({concatenated_stack.shape[0]} entradas)")

def main():
    parser = argparse.ArgumentParser(description="Concatenar varios archivos .mrcs listados en un .txt")
    parser.add_argument("--list_txt", required=True, help="Ruta al archivo .txt con paths relativos a .mrcs")
    parser.add_argument("--output_path", required=True, help="Ruta del archivo de salida .mrcs")
    args = parser.parse_args()

    input_files = load_paths_from_txt(args.list_txt)
    concatenate_mrcs(input_files, args.output_path)

if __name__ == "__main__":
    main()
