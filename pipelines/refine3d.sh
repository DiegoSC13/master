#!/bin/bash

set -e
set -o pipefail

# Ruta base
PYP_DIR="/nfs/bartesaghilab2/ds672/nextpyp"
SIF="${PYP_DIR}/pyp.sif"
INPUT_FILE="/nfs/bartesaghilab2/ds672/master/pipelines/empiar10076.txt"

singularity exec -B /hpc -B /nfs "$SIF" bash -c "
  cd /opt/pyp/external/frealignx && \
  ./refine3d < $INPUT_FILE
"

source /nfs/bartesaghilab2/ds672/anaconda3/etc/profile.d/conda.sh
conda activate cryodrgn

# Rutas de archivos
DS_DIR="/nfs/bartesaghilab2/ds672"
INPUT_PAR="${DS_DIR}/nextpyp/empiar10076/output_parameter_file_N.par"
CROPPED_PAR="${DS_DIR}/nextpyp/empiar10076/output_parameter_file_N_cropped.par"
INPUT_STAR="${DS_DIR}/nextpyp/empiar10076/output_parameter_file_N_cropped_pyem.star"
OUTPUT_STAR="${DS_DIR}/nextpyp/empiar10076/output_parameter_file_N_cropped_pyem_4parse.star"
C=53
# Ejecutar los scripts Python
cd "${DS_DIR}/master/pipelines"
python crop_par.py "$INPUT_PAR" "$CROPPED_PAR" "$C"
cd "${DS_DIR}/pyem/pyem/cli"
python par2star.py "$CROPPED_PAR" "$INPUT_STAR"
cd "${DS_DIR}/master/pipelines"
python modify_star.py "$INPUT_STAR" "$OUTPUT_STAR"
cryodrgn parse_pose_star "$OUTPUT_STAR" \
  --Apix 1.31 \
  -D 320 \
  -o "${DS_DIR}/empiar10076/output_parameter_file_N_cropped_pyem_4cryodrgn.pkl"

echo "[INFO] Tratamiento de poses completado."