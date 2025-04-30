#!/bin/bash

set -e
set -o pipefail

# Ruta base
PYP_DIR="/nfs/bartesaghilab2/ds672/nextpyp"
SIF_DIR="${PYP_DIR}/pyp.sif"
INPUT_FILE="/nfs/bartesaghilab2/ds672/master/pipelines/empiar10076.txt"

# singularity exec -B /hpc -B /nfs "$SIF" bash -c "
#   cd /opt/pyp/external/frealignx && \
#   ./refine3d < $INPUT_FILE
# "

NUM_CLUSTERS=1
DS_DIR="/nfs/bartesaghilab2/ds672"
OUTPUT_DIR="2025_04_28_16_59_04_z8_ds128_iter0"
N_ANALYSIS=0
i=0

# #Análisis de labels
# cd "$WORK_DIR/experiments/${OUTPUT_DIR}" || exit 1
# mkdir mrc_iter${i}
# cd "$WORK_DIR/master/aux_functions" || exit 1
# python mrc_per_classes 
# cd "$WORK_DIR/master/cryodrgn/commands" || exit 1
# python labels_processing.py ../../empiar10076/experiments/2025_02_10_z8_ds128_iter0/analyze.49/kmeans5_umap/labels.pkl ../../empiar10076/experiments/2025_02_10_z8_ds128_iter0/analyze.49/kmeans5_umap/particles_per_label ../../empiar10076/experiments/2025_02_10_z8_ds128_iter0/analyze.49/kmeans5_umap/starfiles_per_label ../../empiar10076/old_inputs/Parameters.star 0

#Itero en los clusters
for ((j=0; j<NUM_CLUSTERS; j++)); do
  # cd "${DS_DIR}/master/pipelines"
  # python indexes2arange.py \
  # --input_star "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/starfiles_per_label/Cluster${j}_iter${i}_10particles.star" \
  # --output_star "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/starfiles_per_label/Cluster${j}_iter${i}_10particles_modified.star"

  REFINE3D_INPUT=$(cat <<EOF
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/mrc_cluster/particles_class_${j}_10particles.mrc
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/starfiles_per_label/Cluster${j}_iter${i}_10particles_modified.star
${DS_DIR}/cryosparc/CS-empiar-10076-may-2024/J5/J5_003_volume_map.mrc
no
no
/nfs/bartesaghilab2/ds672/nextpyp/empiar10076/dont_care.mrc
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/refine3d_output/parfile_iter${i}_cluster${j}_10particles.par
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/refine3d_output/changes_parfile_iter${i}_cluster${j}_10particles.par
C1
0
0
1
1.31
300
2.7
0.07
1586
0
100
300
8
0
0
0
8
0
20
0
0
0
0
0
0
500
50
1
no
yes
yes
yes
yes
yes
yes
no
no
no
yes
yes
no
yes
no
EOF
)

# Ejecuto refine3d dentro del contenedor
  echo "[INFO] Ejecuto refine3d..."
  singularity exec -B /hpc -B /nfs "$SIF_DIR" bash -c "
    cd /opt/pyp/external/frealignx && \
    echo \"$REFINE3D_INPUT\" | ./refine3d
"
done
# source /nfs/bartesaghilab2/ds672/anaconda3/etc/profile.d/conda.sh
# conda activate cryodrgn

# # Rutas de archivos
# DS_DIR="/nfs/bartesaghilab2/ds672"
# INPUT_PAR="${DS_DIR}/nextpyp/empiar10076/output_parameter_file_N.par"
# CROPPED_PAR="${DS_DIR}/nextpyp/empiar10076/output_parameter_file_N_cropped.par"
# INPUT_STAR="${DS_DIR}/nextpyp/empiar10076/output_parameter_file_N_cropped_pyem.star"
# OUTPUT_STAR="${DS_DIR}/nextpyp/empiar10076/output_parameter_file_N_cropped_pyem_4parse.star"
# C=53
# # Ejecutar los scripts Python
# cd "${DS_DIR}/master/pipelines"
# python crop_par.py "$INPUT_PAR" "$CROPPED_PAR" "$C"
# cd "${DS_DIR}/pyem/pyem/cli"
# python par2star.py "$CROPPED_PAR" "$INPUT_STAR"
# cd "${DS_DIR}/master/pipelines"
# python modify_star.py "$INPUT_STAR" "$OUTPUT_STAR"
# cryodrgn parse_pose_star "$OUTPUT_STAR" \
#   --Apix 1.31 \
#   -D 320 \
#   -o "${DS_DIR}/empiar10076/output_parameter_file_N_cropped_pyem_4cryodrgn.pkl"

# echo "[INFO] Tratamiento de poses completado."