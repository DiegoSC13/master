#!/bin/bash

source /nfs/bartesaghilab2/ds672/anaconda3/etc/profile.d/conda.sh
conda activate cryodrgn

DATASET=$1
DIM=$2
NUM_CLUSTERS=$3
N_ANALYSIS=$4

DS_DIR="/nfs/bartesaghilab2/ds672"
WORK_DIR="${DS_DIR}/empiar${DATASET}"
#OUTPUT_DIR="${WORK_DIR}/experiments/2025_06_19_z8_ds${DS}"

CLUSTER_PATH="hdbscan" #${NUM_CLUSTERS}"
### EMPIAR-10076
# COMPLETE_PAR_DIR="${DS_DIR}/master/delete_me/refine3d_exps/par_92x/exp4/output_refine3d_exp4_cropped_index_filtered.par"
# MRC_FILTERED_PATH="${WORK_DIR}/inputs/initial_hidden_variables/filtered_particles/filtered_L17Combine_weight_local.mrc"
### EMPIAR-10180
#COMPLETE_PAR_DIR="${DS_DIR}/master/delete_me/empiar10180/consensus_data_MT_filtered.par"
#MRC_FILTERED_PATH="${WORK_DIR}/downsampled_data/particles.orig.imod_stack_filtered.mrcs"

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
  if [ "$DIM" == "128" ]; then
    OUTPUT_DIR="${WORK_DIR}/experiments/2025_06_05_z8_ds${DIM}_par_92x_exp4"
  elif [ "$DIM" == "320" ]; then
    OUTPUT_DIR="${WORK_DIR}/experiments/2025_06_07_z8_ds${DIM}_par_92x_exp4"
  fi
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

python generate_pars_per_cluster.py \
    --labels_pkl_path "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/new_labels.pkl" \
    --particles_per_label_folder "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/particles_per_label" \
    --output_folder "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/parfiles_per_label" \
    --parfile_path "${COMPLETE_PAR_DIR}" \
    --iter 0 \
    --metadata_row_num 1
# python labels_processing.py ${WORK_DIR}/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/labels.pkl ${WORK_DIR}/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/particles_per_label ${WORK_DIR}/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/parfiles_per_label ${WORK_DIR}/old_inputs/Parameters.star ${i} 13

#Corro mrc_from_pkl.py para generar los mrc de entrada a refine3d
cd "$DS_DIR/master/pipelines" || exit 1
python mrc_from_pkl.py \
    --pkls_folder "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/particles_per_label" \
    --mrc_filepath "${MRC_FILTERED_PATH}" \
    --output_folder "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/mrc_cluster"

CLUSTER_IDS=$(python3 -c "
import pickle
import numpy as np
labels = pickle.load(open('${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/new_labels.pkl', 'rb'))
print(' '.join(str(i) for i in np.unique(labels) if i != -1))
")

#Defino directorio de salida de .par's de refine3d
cd "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/"
# mkdir refine3d_output
mkdir reconstruct3d_output


#Itero en los clusters
#for ((j=0; j<NUM_CLUSTERS; j++)); do
for j in $CLUSTER_IDS; do
  echo "Procesando cluster $j"
  #Cambio los índices de los .par para que refine todas las partículas del .mrc
  cd "${DS_DIR}/master/pipelines"
  python indexes2arange_par.py \
  --input_par "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/parfiles_per_label/Cluster${j}_iter0.par" \
  --output_par "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/parfiles_per_label/Cluster${j}_iter02arange.par"

  # Verifica que se haya pasado un argumento
  # if [ "$#" -ne 1 ]; then
  #   echo "[ERROR] Debes proporcionar un directorio de entrada que contenga los archivos .txt necesarios."
  #   echo "Uso: $0 ruta/al/directorio"
  #   exit 1
  # fi

  #INPUT_DIR="$1"
  # REFINE_INPUT="${INPUT_DIR}/refine3d_input.txt"
  # RECONSTRUCT_INPUT="${INPUT_DIR}/reconstruct3d_stats_input.txt"

  # # Verifica que el directorio exista
  # if [ ! -d "$INPUT_DIR" ]; then
  #   echo "[ERROR] El directorio '$INPUT_DIR' no existe."
  #   exit 1
  # fi

  # # Verifica que los archivos existan
  # if [ ! -f "$REFINE_INPUT" ]; then
  #   echo "[ERROR] El archivo '$REFINE_INPUT' no existe."
  #   exit 1
  # fi

  # if [ ! -f "$RECONSTRUCT_INPUT" ]; then
  #   echo "[ERROR] El archivo '$RECONSTRUCT_INPUT' no existe."
  #   exit 1
  # fi

  # Rutas
  WORK_DIR="/nfs/bartesaghilab2/ds672"
  MASTER_DIR="${WORK_DIR}/master"
  PYP_DIR="${WORK_DIR}/nextpyp"
  SIF_DIR="${PYP_DIR}/pyp.sif"
  #INPUT_FILE="$1"  # archivo pasado como argumento

  printf -v j_padded "%02d" "$j"

  # # Ejecutar reconstruct3d
  RECONSTRUCT3D_INITIAL_INPUT=$(cat <<EOF
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/mrc_cluster/particles_class_${j_padded}.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/parfiles_per_label/Cluster${j}_iter02arange.par
no
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_1_iter0_cluster${j}.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_2_iter0_cluster${j}.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/res_iter0_cluster${j}.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_iter0_cluster${j}.txt
C1
0
0
${PIXEL_SIZE}
300
2.7
${AMPLITUDE_CONTRAST}
${MOLECULAR_MASS}
0
${OUTER_RADIUS}
0
0
${WEIGHTING_FACTOR}
1
1
1
yes
${ADJUST_SCORES}
${INVERT_CONTRAST}
no
no
yes
no
no
no
no
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_iter0_cluster${j}_1.dat
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_iter0_cluster${j}_2.dat
EOF
  )

  echo "[INFO] Ejecuto reconstruct3d..."
  singularity exec -B /hpc -B /nfs "$SIF_DIR" bash -c "
    cd /opt/pyp/external/frealignx && \
    echo \"$RECONSTRUCT3D_INITIAL_INPUT\" | ./reconstruct3d_stats
  "
done

# echo "[INFO] Ejecutando refine3d con archivo de entrada: $REFINE_INPUT"
# singularity exec -B /hpc -B /nfs "$SIF_DIR" bash -c "
#   cd /opt/pyp/external/frealignx && \
#   ./refine3d < \"$REFINE_INPUT\"
# "

# INPUT_CROP_DIR="${INPUT_DIR}/output_refine3d.par"
# CROPPED_PAR_DIR="${INPUT_DIR}/output_refine3d_cropped.par"
# C=53
# INPUT_RECONSTRUCT3D_DIR="${INPUT_DIR}/output_refine3d_cropped4rec3d.par"

# cd "$MASTER_DIR/pipelines" || exit 1
# python crop_par.py "$INPUT_CROP_DIR" "$CROPPED_PAR_DIR" "$C"
# python par4reconstruct3d.py "$CROPPED_PAR_DIR" "$INPUT_RECONSTRUCT3D_DIR" \
#   --mag 38168 \
#   --ang 5.28 \
#   --occ 100.00

# # Ejecutar reconstruct3d_stats
# echo "[INFO] Ejecutando reconstruct3d_stats con archivo de entrada: $RECONSTRUCT_INPUT"
# singularity exec -B /hpc -B /nfs "$SIF_DIR" bash -c "
#  cd /opt/pyp/external/frealignx && \
#  ./reconstruct3d_stats < \"$RECONSTRUCT_INPUT\"
# "