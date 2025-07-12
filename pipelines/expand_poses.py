#!/usr/bin/env python3

import pickle
import numpy as np
import argparse

def expand_and_reindex_poses(poses_pkl, indices_pkl, N, output_pkl=None):
    """
    Reindexa y expande poses (traslación y rotación) a un tamaño N. Guarda el resultado como tensores.

    Parámetros:
    - poses_pkl: ruta al .pkl con [rotations (M, 3, 3), translations (M, 2)] (tensores).
    - indices_pkl: ruta al .pkl con M índices enteros únicos en [0, N).
    - N: número total de partículas en la salida.
    - output_pkl: si se especifica, guarda el nuevo archivo .pkl con tensores.

    Devuelve:
    - poses_out: tuple (rotations_tensor, translations_tensor) con formas (N, 3, 3) y (N, 2).
    """

    # Cargar poses originales
    with open(poses_pkl, 'rb') as f:
        poses = pickle.load(f)

    translations = np.asarray(poses[1])  # (M, 2)
    rotations = np.asarray(poses[0])     # (M, 3, 3)

    M = translations.shape[0]
    if rotations.shape != (M, 3, 3):
        raise ValueError(f"Se esperaba (M, 3, 3) en rotaciones, se obtuvo {rotations.shape}.")

    # Cargar índices
    with open(indices_pkl, 'rb') as f:
        indices = np.asarray(pickle.load(f), dtype=int)

    if indices.shape[0] != M:
        raise ValueError(f"{indices.shape[0]} índices para {M} poses.")

    if np.any(indices >= N):
        raise ValueError(f"Índices mayores o iguales a N={N} detectados.")

    # Inicializar tensores de salida
    new_translations = np.zeros((N, 2), dtype=translations.dtype)
    new_rotations = np.zeros((N, 3, 3), dtype=rotations.dtype)

    # Reubicar
    new_translations[indices] = translations
    new_rotations[indices] = rotations

    poses_out = (new_rotations, new_translations)

    # Guardar
    if output_pkl is not None:
        with open(output_pkl, 'wb') as f:
            pickle.dump(poses_out, f, protocol=pickle.HIGHEST_PROTOCOL)
        print(f"Guardado: {output_pkl} con traslaciones {new_translations.shape} y rotaciones {new_rotations.shape}")

    return poses_out

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Reindexa y expande poses a tamaño N.")
    parser.add_argument("poses_pkl", help="Archivo .pkl con las poses originales")
    parser.add_argument("indices_pkl", help="Archivo .pkl con los índices seleccionados")
    parser.add_argument("N", type=int, help="Número total de partículas en la salida")
    parser.add_argument("output_pkl", help="Ruta del archivo .pkl de salida")

    args = parser.parse_args()

    expand_and_reindex_poses(args.poses_pkl, args.indices_pkl, args.N, args.output_pkl)
