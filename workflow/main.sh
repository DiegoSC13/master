#!/bin/bash

set -e
set -o pipefail

# source "$(dirname "$0")/config_10076.sh"
source /nfs/bartesaghilab2/ds672/anaconda3/etc/profile.d/conda.sh
conda activate cryodrgn

# Fecha y hora
DATE="$(date +%Y_%m_%d_%H_%M_%S)"

#### Asignación de variables antes de iterar ####
#Estas variables no van en config.sh porque van
#cambiando en cada iteración. config.sh tiene valores fijos.

CONFIG_NAME="$1"
CLUSTER_METHOD="$2"
export DATASET="$3"
export DIM="$4"
export NUM_CLUSTERS="$5"
export DIM_UMAP="$6"

echo "Dataset: $DATASET"
echo "Dim: $DIM"
echo "Cantidad de clusters: $NUM_CLUSTERS"

SCRIPT_DIR="$(dirname "$0")"
CONFIG_PATH="${SCRIPT_DIR}/${CONFIG_NAME}"
source "$CONFIG_PATH"

if [ "$CLUSTER_METHOD" == "KMEANS" ]; then
  if [ "$DIM_UMAP" == "3" ]; then
    CLUSTER_PATH="kmeans${NUM_CLUSTERS}_3d"
  elif [ "$DIM_UMAP" == "2" ]; then
    CLUSTER_PATH="kmeans${NUM_CLUSTERS}"
  fi
elif [ "$CLUSTER_METHOD" == "HDBSCAN" ]; then
  if [ "$DIM_UMAP" == "3" ]; then
    CLUSTER_PATH="hdbscan_3d"
  elif [ "$DIM_UMAP" == "2" ]; then
    CLUSTER_PATH="hdbscan"
  fi
  
else
  echo "[ERROR] Método de clustering no reconocido: $CLUSTER_METHOD"
  exit 1
fi

echo "Cluster Method: $CLUSTER_METHOD"
echo "UMAPs Dimension: $DIM_UMAP"
echo "Cluster Path: $CLUSTER_PATH"

#source /nfs/bartesaghilab2/ds672/master/delete_me/vars.txt

#OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/master/workflow/base_conditions/filtered_Nrefs/empiar${DATASET}_${CLUSTER_PATH}_ds${DIM}"

if [ "$DATASET" == "10076" ]; then
  if [ "$DIM" == "128" ]; then
    OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/refine3d_exps/par_92x/exp4/output_refine3d_exp4_cropped_modified2pkl.pkl" #Change me
    OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_05_z8_ds128_par_92x_exp4"
    OLD_N_ANALYSIS=39 #Change me
    OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_05_z8_ds128_par_92x_exp4/analysis_diego.39/${CLUSTER_PATH}_umap/reconstruct3d_output" 
    KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_05_z8_ds128_par_92x_exp4/analysis_diego.39/${CLUSTER_PATH}_umap/centers.txt"
    COMPLETE_PAR_DIR="${DS_DIR}/master/delete_me/refine3d_exps/par_92x/exp4/output_refine3d_exp4_cropped_index_filtered.par"
  elif [ "$DIM" == "320" ]; then
    OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/refine3d_exps/par_92x/exp4/output_refine3d_exp4_cropped_modified2pkl.pkl" #Change me
    OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_07_z8_ds320_par_92x_exp4"
    OLD_N_ANALYSIS=39 #Change me
    OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_07_z8_ds320_par_92x_exp4/analysis_diego.39/${CLUSTER_PATH}_umap/reconstruct3d_output" 
    KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_07_z8_ds320_par_92x_exp4/analysis_diego.39/${CLUSTER_PATH}_umap/centers.txt"
    COMPLETE_PAR_DIR="${DS_DIR}/master/delete_me/refine3d_exps/par_92x/exp4/output_refine3d_exp4_cropped_index_filtered.par"
  fi
elif [ "$DATASET" == "10180" ]; then
  if [ "$DIM" == "128" ]; then
    OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/empiar10180/inputs/poses.pkl" #Change me
    OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/empiar10180/experiments/2025_06_26_z8_ds128"
    OLD_N_ANALYSIS=39 #Change me
    OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/master/workflow/base_conditions/filtered_Nrefs/empiar${DATASET}_${CLUSTER_PATH}_ds${DIM}/reconstruct3d_output" 
    KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/master/workflow/base_conditions/filtered_Nrefs/empiar${DATASET}_${CLUSTER_PATH}_ds${DIM}/cryodrgn/centers.txt"
    COMPLETE_PAR_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/empiar10180/consensus_data_MT_filtered_2arange.par"
  elif [ "$DIM" == "256" ]; then #En este entrenamiento NO filtro partículas
    OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/empiar10180/inputs/poses.pkl" #Change me
    OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/empiar10180/experiments/2025_02_26_z8_ds256"
    OLD_N_ANALYSIS=39 #Change me
    OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/master/workflow/base_conditions/filtered_Nrefs/empiar10180_${CLUSTER_PATH}_ds${DIM}/reconstruct3d_output" 
    #KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/master/workflow/base_conditions/filtered_Nrefs/empiar10180_${CLUSTER_PATH}_ds${DIM}/cryodrgn/centers.txt"
    COMPLETE_PAR_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/empiar10180/consensus_data_MT.par" #Sin filtrar
  elif [ "$DIM" == "320" ]; then
    OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/empiar10180/inputs/poses.pkl" #Change me
    OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/empiar10180/experiments/2025_06_19_z8_ds320"
    OLD_N_ANALYSIS=39 #Change me
    OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/master/workflow/base_conditions/filtered_Nrefs/empiar10180_${CLUSTER_PATH}_ds${DIM}/reconstruct3d_output" 
    KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/master/workflow/base_conditions/filtered_Nrefs/empiar10180_${CLUSTER_PATH}_ds${DIM}/cryodrgn/centers.txt"
    COMPLETE_PAR_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/empiar10180/consensus_data_MT_filtered_2arange.par"
  fi
else
  echo "Dataset no reconocido: $DATASET"
  exit 1
fi

# Resolución máxima, voy bajándola en cada iteración
#HIGH_RES_LIMIT=9
HIGH_RES_LIMIT_LIST=(6 5 4 3 3 3 2 2 2)
for ((i=1; i<NUM_ITER; i++)); do
  echo "[INFO] >>> Iteración $i"
  HIGH_RES_LIMIT=${HIGH_RES_LIMIT_LIST[$((i-1))]}
  OUTPUT_DIR="/nfs/bartesaghilab2/ds672/master/workflow/experiments/empiar${DATASET}/${DATE}_z${ZDIM}_ds${DOWNSAMPLING}_${CLUSTER_PATH}_iter${i}"
  #OUTPUT_DIR="/nfs/bartesaghilab2/ds672/master/workflow/experiments/empiar10076_example1000/${DATE}_z${ZDIM}_ds${DOWNSAMPLING}_iter${i}"
  #OUTPUT_DIR="/nfs/bartesaghilab2/ds672/master/workflow/experiments/empiar10180/${DATE}_z${ZDIM}_ds${DOWNSAMPLING}_iter${i}"
  
  POSES_DIR="$OUTPUT_PKL_DIR"

  source "$(dirname "$0")/cryodrgn.sh" "$i" "$POSES_DIR" "$OUTPUT_DIR" "$OLD_OUTPUT_DIR" "$OLD_N_ANALYSIS" "$CONFIG_NAME"
  bash "$(dirname "$0")/analysis.sh" "$i" "$OUTPUT_DIR" "$N_ANALYSIS" "$CONFIG_NAME"
  source "$(dirname "$0")/clusters_processing.sh" "$i" "$OUTPUT_DIR" "$N_ANALYSIS" "$CLUSTER_PATH" "$COMPLETE_PAR_DIR" "$OLD_OUTPUT_DIR" "$OLD_N_ANALYSIS" "$CONFIG_NAME"
  if [ "$CLUSTER_METHOD" == "KMEANS" ]; then
    source "$(dirname "$0")/frealign_kmeans.sh" "$i" "$OUTPUT_DIR" "$N_ANALYSIS" "$OLD_POSES" "$CLUSTER_PATH" "$CONFIG_NAME" "$HIGH_RES_LIMIT"
  elif [ "$CLUSTER_METHOD" == "HDBSCAN" ]; then
    source "$(dirname "$0")/frealign_hdbscan.sh" "$i" "$OUTPUT_DIR" "$N_ANALYSIS" "$OLD_POSES" "$CLUSTER_PATH" "$CONFIG_NAME" "$HIGH_RES_LIMIT"
  fi
 # source "$(dirname "$0")/frealign_kmeans.sh" "$i" "$OUTPUT_DIR" "$N_ANALYSIS" "$OLD_POSES" "$CLUSTER_PATH" "$CONFIG_NAME" "$HIGH_RES_LIMIT"
  source "$(dirname "$0")/poses_processing.sh" "$i" "$OUTPUT_DIR" "$N_ANALYSIS" "$CLUSTER_PATH" "$CONFIG_NAME" 
done

echo "[INFO] Todos los entrenamientos completados."

######################################
#Definiciones viejas que no me animo a borrar

### Entradas EMPIAR-10076 - Ejemplo de 1000 partículas 
# OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/example_1000/poses_1000.pkl" #Change me
# OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/master/workflow/experiments/empiar10076_example1000"
# OLD_N_ANALYSIS=1 #Change me
# OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/example_1000/init_maps"
# KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/master/delete_me/example_1000/centers.txt"
# COMPLETE_PAR_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/example_1000/Frealign9Parameter_0_r1_92x_1000_filtered.par"

### Entradas EMPIAR-10076 - Downsampled 128x128
# OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/refine3d_exps/par_92x/exp4/output_refine3d_exp4_cropped_modified2pkl.pkl" #Change me
# OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_05_z8_ds128_par_92x_exp4"
# OLD_N_ANALYSIS=39 #Change me
# OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_05_z8_ds128_par_92x_exp4/analysis_diego.39/${CLUSTER_PATH}_umap/reconstruct3d_output" 
# KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_05_z8_ds128_par_92x_exp4/analysis_diego.39/${CLUSTER_PATH}_umap/centers.txt"
# COMPLETE_PAR_DIR="${DS_DIR}/master/delete_me/refine3d_exps/par_92x/exp4/output_refine3d_exp4_cropped_index_filtered.par"

### Entradas EMPIAR-10076 - Resolución original
# OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/refine3d_exps/par_92x/exp4/output_refine3d_exp4_cropped_modified2pkl.pkl" #Change me
# OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_07_z8_ds320_par_92x_exp4"
# OLD_N_ANALYSIS=39 #Change me
# OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_07_z8_ds320_par_92x_exp4/analysis_diego.39/${CLUSTER_PATH}_umap/reconstruct3d_output" 
# KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_07_z8_ds320_par_92x_exp4/analysis_diego.39/${CLUSTER_PATH}_umap/centers.txt"
# COMPLETE_PAR_DIR="${DS_DIR}/master/delete_me/refine3d_exps/par_92x/exp4/output_refine3d_exp4_cropped_index_filtered.par"

# OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/refine3d_exps/par_92x/exp4/output_refine3d_exp4_cropped_modified2pkl.pkl" #Change me
# OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_07_z8_ds320_par_92x_exp4"
# OLD_N_ANALYSIS=49 #Change me
# OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/master/workflow/experiments/empiar10076/init_maps" #No los usa por ahora
# KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_07_z8_ds320_par_92x_exp4/analysis_diego.49/${CLUSTER_PATH}_umap/centers.txt"
# COMPLETE_PAR_DIR="${DS_DIR}/master/delete_me/refine3d_exps/par_92x/Frealign9Parameter_0_r1_92x.par"

### Entradas EMPIAR-10180 - Downsampled 128x128
# OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/empiar10180/inputs/poses.pkl" #Change me
# OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/empiar10180/experiments/2025_06_26_z8_ds128"
# OLD_N_ANALYSIS=39 #Change me
# OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/master/workflow/base_conditions/filtered_Nrefs/empiar${DATASET}_${CLUSTER_PATH}_ds${DIM}/reconstruct3d_output" 
# KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/master/workflow/base_conditions/filtered_Nrefs/empiar${DATASET}_${CLUSTER_PATH}_ds${DIM}/cryodrgn/centers.txt"
# COMPLETE_PAR_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/empiar10180/consensus_data_MT_filtered_2arange.par"

### Entradas EMPIAR-10180 - Resolución original
# OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/empiar10180/inputs/poses.pkl" #Change me
# OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/empiar10180/experiments/2025_06_19_z8_ds320"
# OLD_N_ANALYSIS=39 #Change me
# OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/master/workflow/base_conditions/filtered_Nrefs/empiar10180_${CLUSTER_PATH}_ds${DIM}/reconstruct3d_output" 
# KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/master/workflow/base_conditions/filtered_Nrefs/empiar10180_${CLUSTER_PATH}_ds${DIM}/cryodrgn/centers.txt"
# COMPLETE_PAR_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/empiar10180/consensus_data_MT_filtered_2arange.par"