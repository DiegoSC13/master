#!/bin/bash

echo ""
echo "############################### FREALIGN ###############################" 

i=$1
OUTPUT_DIR=$2
N_ANALYSIS=$3
OLD_POSES=$4
CLUSTER_PATH=$5
CONFIG_NAME=$6
HIGH_RES_LIMIT=$7

SCRIPT_DIR="$(dirname "$0")"
CONFIG_PATH="${SCRIPT_DIR}/${CONFIG_NAME}"

source "$CONFIG_PATH"

CLUSTER_IDS=$(python3 -c "
import pickle
import numpy as np
labels = pickle.load(open('${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/new_labels.pkl', 'rb'))
print(' '.join(str(i) for i in np.unique(labels) if i != -1))
")

#Defino directorio de salida de .par's de refine3d
cd "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/"
mkdir refine3d_output
mkdir reconstruct3d_output

#Itero en los clusters
#for ((j=0; j<NUM_CLUSTERS; j++)); do
for j in $CLUSTER_IDS; do

  #j_padded para expresarlo en dos dígitos
  printf -v j_padded "%02d" "$j"

  echo "Procesando cluster $j"
  #Cambio los índices de los .par para que refine todas las partículas del .mrc
  cd "${DS_DIR}/master/pipelines"
  python indexes2arange_par.py \
  --input_par "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/parfiles_per_label/Cluster${j}_iter${i}.par" \
  --output_par "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/parfiles_per_label/Cluster${j}_iter${i}2arange.par"
  
  #Armo entrada de primer reconstruct3d, con poses de la iteración anterior
  #Vuelvo a reconstruir porque cambiaron los clusters. Reconstruyo con los cluster
  #de esta iteración. Si los cluster cambian poco deberían ser muy parecidas
  RECONSTRUCT3D_INITIAL_INPUT=$(cat <<EOF
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/mrc_cluster/particles_class_${j_padded}.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/parfiles_per_label/Cluster${j}_iter${i}2arange.par
no
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_oldposes_1_iter${i}_cluster${j}.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_oldposes_2_iter${i}_cluster${j}.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/res_oldposes_iter${i}_cluster${j}.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_oldposes_iter${i}_cluster${j}.txt
C1
0
0
1.31
300
2.7
0.07
1586
0
100
0
0
5
1
1
1
yes
yes
no
no
no
yes
no
no
no
no
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_oldposes_iter${i}_cluster${j}_1.dat
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_oldposes_iter${i}_cluster${j}_2.dat
EOF
)
echo "i: $i, j: $j, i-1: $((i-1))"
  #Armo entrada a refine3d
  REFINE3D_INPUT=$(cat <<EOF
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/mrc_cluster/particles_class_${j_padded}.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/parfiles_per_label/Cluster${j}_iter${i}2arange.par
${OLD_MAPS_DIR}/res_iter$((i-1))_cluster${j}.mrc
${OLD_MAPS_DIR}/stats_iter$((i-1))_cluster${j}.txt
yes
${WORK_DIR}/dont_care.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output/parfile_iter${i}_cluster${j}.par
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output/changes_parfile_iter${i}_cluster${j}.par
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
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/mrc_cluster/particles_class_${j_padded}.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output/parfile_iter${i}_cluster${j}.par
no
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_1_iter${i}_cluster${j}.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_2_iter${i}_cluster${j}.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/res_iter${i}_cluster${j}.mrc
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_iter${i}_cluster${j}.txt
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
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_iter${i}_cluster${j}_1.dat
${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output/stats_iter${i}_cluster${j}_2.dat
EOF
)

# Ejecuto refine3d dentro del contenedor
#    echo \"$RECONSTRUCT3D_INITIAL_INPUT\" | ./reconstruct3d_stats
  echo "[INFO] Ejecuto refine3d..."
  singularity exec -B /hpc -B /nfs "$SIF_DIR" bash -c "
    cd /opt/pyp/external/frealignx && \
    echo \"$REFINE3D_INPUT\" | ./refine3d
    echo \"$RECONSTRUCT3D_REFINED_INPUT\" | ./reconstruct3d_stats
"
  #     echo \"$RECONSTRUCT3D_REFINED_INPUT\" | ./reconstruct3d_stats
  
  echo "[INFO] Ejecuto rename_pars.py..."
  cd "${DS_DIR}/master/pipelines"
  python rename_pars.py "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output"

  INPUT_PAR_DIR="${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output/parfile_iter${i}_cluster${j_padded}.par" #salida de refine3d / entrada de crop_par.py
  CROPPED_PAR_DIR="${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output/parfile_iter${i}_cluster${j_padded}_cropped.par" #salida de crop_par.py / entrada de star2par.py
  C=53 #Cantidad de filas a croppear en crop_par.py

  echo "[INFO] Ejecuto crop_par.py..."
  python crop_par.py "$INPUT_PAR_DIR" "$CROPPED_PAR_DIR" "$C"

  echo "[INFO] Ejecuto arange2indexes_par.py..."
  python arange2indexes_par.py \
  --par_file "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output/parfile_iter${i}_cluster${j_padded}_cropped.par" \
  --pkl_file "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/particles_per_label/particles_class_${j_padded}.pkl" \
  --output_file "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output/parfile_iter${i}_cluster${j_padded}_cropped_index_restored.par"
done

#OLD_POSES="${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output"
OLD_MAPS_DIR="${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/reconstruct3d_output"
KMEANS_CENTERS="${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/centers.txt"
cd "${DS_DIR}/master/workflow"

