#!/bin/bash

source /nfs/bartesaghilab2/ds672/anaconda3/etc/profile.d/conda.sh
conda activate cryodrgn

# Verifica que se haya pasado un argumento
if [ "$#" -ne 1 ]; then
  echo "[ERROR] Debes proporcionar un directorio de entrada que contenga los archivos .txt necesarios."
  echo "Uso: $0 ruta/al/directorio"
  exit 1
fi

INPUT_DIR="$1"
REFINE_INPUT="${INPUT_DIR}/refine3d_input.txt"
RECONSTRUCT_INPUT="${INPUT_DIR}/reconstruct3d_stats_input.txt"

# Verifica que el directorio exista
if [ ! -d "$INPUT_DIR" ]; then
  echo "[ERROR] El directorio '$INPUT_DIR' no existe."
  exit 1
fi

# Verifica que los archivos existan
if [ ! -f "$REFINE_INPUT" ]; then
  echo "[ERROR] El archivo '$REFINE_INPUT' no existe."
  exit 1
fi

if [ ! -f "$RECONSTRUCT_INPUT" ]; then
  echo "[ERROR] El archivo '$RECONSTRUCT_INPUT' no existe."
  exit 1
fi

# Rutas
WORK_DIR="/nfs/bartesaghilab2/ds672"
MASTER_DIR="${WORK_DIR}/master"
PYP_DIR="${WORK_DIR}/nextpyp"
SIF_DIR="${PYP_DIR}/pyp.sif"
INPUT_FILE="$1"  # archivo pasado como argumento

# # Ejecutar refine3d
echo "[INFO] Ejecutando refine3d con archivo de entrada: $REFINE_INPUT"
singularity exec -B /hpc -B /nfs "$SIF_DIR" bash -c "
  cd /opt/pyp/external/frealignx && \
  ./refine3d < \"$REFINE_INPUT\"
"

INPUT_CROP_DIR="${INPUT_DIR}/output_refine3d.par"
CROPPED_PAR_DIR="${INPUT_DIR}/output_refine3d_cropped.par"
C=53
INPUT_RECONSTRUCT3D_DIR="${INPUT_DIR}/output_refine3d_cropped4rec3d.par"

cd "$MASTER_DIR/pipelines" || exit 1
python crop_par.py "$INPUT_CROP_DIR" "$CROPPED_PAR_DIR" "$C"
python par4reconstruct3d.py "$CROPPED_PAR_DIR" "$INPUT_RECONSTRUCT3D_DIR" \
  --mag 38168 \
  --ang 5.28 \
  --occ 100.00

# Ejecutar reconstruct3d_stats
echo "[INFO] Ejecutando reconstruct3d_stats con archivo de entrada: $RECONSTRUCT_INPUT"
singularity exec -B /hpc -B /nfs "$SIF_DIR" bash -c "
 cd /opt/pyp/external/frealignx && \
 ./reconstruct3d_stats < \"$RECONSTRUCT_INPUT\"
"