#!/bin/bash

set -e
set -o pipefail

source /nfs/bartesaghilab2/ds672/anaconda3/etc/profile.d/conda.sh
conda activate cryodrgn

DATASET=$1
DIM=$2
NUM_CLUSTERS=$3
N_ANALYSIS=$4

DS_DIR="/nfs/bartesaghilab2/ds672"
WORK_DIR="${DS_DIR}/empiar${DATASET}"
#OUTPUT_DIR="${WORK_DIR}/experiments/2025_06_19_z8_ds${DS}"

# Ruta base
PYP_DIR="/nfs/bartesaghilab2/ds672/nextpyp"
SIF_DIR="${PYP_DIR}/pyp.sif"
cd "${PYP_DIR}"

CLUSTER_PATH="kmeans${NUM_CLUSTERS}"

# CLUSTER_IDS=$(python3 -c "
# import pickle
# import numpy as np
# labels = pickle.load(open('${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/new_labels.pkl', 'rb'))
# print(' '.join(str(i) for i in np.unique(labels) if i != -1))
# ")

if [ "$DATASET" == "10076" ]; then
  PIXEL_SIZE=1.31
  AMPLITUDE_CONTRAST=0.07
  MOLECULAR_MASS=1586
  WEIGHTING_FACTOR=5
  INVERT_CONTRAST="no"
  ADJUST_SCORES="yes"
  OUTER_RADIUS=100
  COMPLETE_PAR_DIR="${DS_DIR}/master/delete_me/refine3d_exps/par_92x/exp4/output_refine3d_exp4_cropped_index_filtered.par"
  MRC_FILTERED_PATH="${WORK_DIR}/inputs/initial_hidden_variables/filtered_particles/filtered_L17Combine_weight_local.mrc"
#   if [ "$DIM" == "128" ]; then
#     #OUTPUT_DIR="${WORK_DIR}/experiments/2025_06_05_z8_ds${DIM}_par_92x_exp4"
#   elif [ "$DIM" == "320" ]; then
#     OUTPUT_DIR="${WORK_DIR}/experiments/2025_06_07_z8_ds${DIM}_par_92x_exp4"
#   fi
elif [ "$DATASET" == "10180" ]; then
  PIXEL_SIZE=1.699
  AMPLITUDE_CONTRAST=0.1
  MOLECULAR_MASS=3000
  WEIGHTING_FACTOR=10
  INVERT_CONTRAST="yes"
  ADJUST_SCORES="no"
  OUTER_RADIUS=150
  if [ "$DIM" == "128" ]; then
    OUTPUT_DIR="${WORK_DIR}/experiments/2025_06_26_z8_ds${DIM}"
    COMPLETE_PAR_DIR="${DS_DIR}/master/delete_me/empiar10180/consensus_data_MT_filtered.par"
    MRC_FILTERED_PATH="${WORK_DIR}/downsampled_data/particles.orig.imod_stack_filtered.mrcs"
  elif [ "$DIM" == "256" ]; then
    OUTPUT_DIR="${WORK_DIR}/experiments/2025_02_26_z8_ds${DIM}"
    COMPLETE_PAR_DIR="${DS_DIR}/master/delete_me/empiar10180/consensus_data_MT.par"
    MRC_FILTERED_PATH="${WORK_DIR}/downsampled_data/particles.orig.imod_stack.mrcs"
  elif [ "$DIM" == "320" ]; then
    OUTPUT_DIR="${WORK_DIR}/experiments/2025_06_19_z8_ds${DIM}"
    COMPLETE_PAR_DIR="${DS_DIR}/master/delete_me/empiar10180/consensus_data_MT_filtered.par"
    MRC_FILTERED_PATH="${WORK_DIR}/downsampled_data/particles.orig.imod_stack_filtered.mrcs"
  fi
else
  echo "[ERROR] Método de clustering no reconocido: $CLUSTER_METHOD"
  exit 1
fi

NUM_ITERS=5
OUTPUT_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/ref_rec_iterative"
HIGH_RES_LIMIT=7
for i in $(seq 0 $NUM_ITERS); do
  #j=$((i+1))
  #echo "i=$i, j=$j"
  REFINE3D_INPUT=$(cat <<EOF
/nfs/bartesaghilab2/ds672/master/workflow/experiments/empiar10076/2025_07_08_16_17_30_z8_ds128_iter1/analysis_diego.44/kmeans6_umap/mrc_cluster/particles_class_00.mrc
/nfs/bartesaghilab2/ds672/master/workflow/experiments/empiar10076/2025_07_08_16_17_30_z8_ds128_iter1/analysis_diego.44/kmeans6_umap/parfiles_per_label/Cluster0_iter12arange.par
${OUTPUT_DIR}/res_cluster0_ref${i}.mrc
${OUTPUT_DIR}/stats_cluster0_ref${i}.txt
yes
${WORK_DIR}/dont_care.mrc
${OUTPUT_DIR}/parfile_cluster0_ref${i}.par
${OUTPUT_DIR}/changes_parfile_cluster0_ref${i}.par
C1
0
0
1
${PIXEL_SIZE}
300
2.7
${AMPLITUDE_CONTRAST}
${MOLECULAR_MASS}
30
150
30
$((HIGH_RES_LIMIT-i))
0
0
140
8
7.5
20
15
15
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
yes
no
yes
${INVERT_CONTRAST}
no
yes
no
EOF
)

  #Armo entrada de reconstruct3d con las poses de esta iteración
  #No se usa en la iteración, es para evaluación de resultados
  RECONSTRUCT3D_REFINED_INPUT=$(cat <<EOF
/nfs/bartesaghilab2/ds672/master/workflow/experiments/empiar10076/2025_07_08_16_17_30_z8_ds128_iter1/analysis_diego.44/kmeans6_umap/mrc_cluster/particles_class_00.mrc
${OUTPUT_DIR}/parfile_cluster0_ref${i}.par
no
${OUTPUT_DIR}/stats_1_cluster0_ref$((i+1)).mrc
${OUTPUT_DIR}/stats_2_cluster0_ref$((i+1)).mrc
${OUTPUT_DIR}/res_cluster0_ref$((i+1)).mrc
${OUTPUT_DIR}/stats_cluster0_ref$((i+1)).txt
C1
0
0
${PIXEL_SIZE}
300
2.7
${AMPLITUDE_CONTRAST}
${MOLECULAR_MASS}
0
100
0
0
${WEIGHTING_FACTOR}
1
1
1
yes
yes
${INVERT_CONTRAST}
no
no
yes
no
no
no
no
${OUTPUT_DIR}/stats_cluster0_1_ref$((i+1)).dat
${OUTPUT_DIR}/stats_cluster0_2_ref$((i+1)).dat
EOF
)

# Ejecuto refine3d dentro del contenedor
  echo "[INFO] Ejecuto refine3d..."
  singularity exec -B /hpc -B /nfs "$SIF_DIR" bash -c "
    cd /opt/pyp/external/frealignx && \
    echo \"$REFINE3D_INPUT\" | ./refine3d
    echo \"$RECONSTRUCT3D_REFINED_INPUT\" | ./reconstruct3d_stats
"
done