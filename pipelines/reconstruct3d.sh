#!/bin/bash

# Verifica que se haya pasado un argumento
if [ -z "$1" ]; then
  echo "[ERROR] Debes proporcionar un archivo de entrada .txt como argumento."
  echo "Uso: $0 ruta/al/archivo.txt"
  exit 1
fi

# Ruta base
PYP_DIR="/nfs/bartesaghilab2/ds672/nextpyp"
SIF_DIR="${PYP_DIR}/pyp.sif"
INPUT_FILE="$1"  # archivo pasado como argumento

# Ejecutar dentro del contenedor
echo "[INFO] Ejecutando reconstruct3d_stats con archivo de entrada: $INPUT_FILE"
singularity exec -B /hpc -B /nfs "$SIF_DIR" bash -c "
  cd /opt/pyp/external/frealignx && \
  ./reconstruct3d_stats < \"$INPUT_FILE\"
"