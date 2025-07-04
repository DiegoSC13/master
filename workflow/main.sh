#!/bin/bash

set -e
set -o pipefail

source "$(dirname "$0")/config_10076.sh"
conda activate cryodrgn

# Fecha y hora
DATE="$(date +%Y_%m_%d_%H_%M_%S)"

#### Asignación de variables antes de iterar ####
#Estas variables no van en config.sh porque van
#cambiando en cada iteración. config.sh tiene valores fijos.

### Entradas ejemplo1000 
# OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/example_1000/poses_1000.pkl" #Change me
# OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/master/workflow/experiments/empiar10076_example1000"
# OLD_N_ANALYSIS=1 #Change me
# OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/example_1000/init_maps"
# KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/master/delete_me/example_1000/centers.txt"
# COMPLETE_PAR_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/example_1000/Frealign9Parameter_0_r1_92x_1000.par"

CLUSTER_METHOD="$1"

if [ "$CLUSTER_METHOD" == "KMEANS" ]; then
  CLUSTER_PATH="kmeans${NUM_CLUSTERS}"
elif [ "$CLUSTER_METHOD" == "HDBSCAN" ]; then
  CLUSTER_PATH="hdbscan"
else
  echo "[ERROR] Método de clustering no reconocido: $CLUSTER_METHOD"
  exit 1
fi

echo "Cluster Method: $CLUSTER_METHOD"

### Entradas EMPIAR-10076
OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/refine3d_exps/par_92x/exp4/output_refine3d_exp4_cropped_modified2pkl.pkl" #Change me
OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_07_z8_ds320_par_92x_exp4"
OLD_N_ANALYSIS=49 #Change me
OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/master/workflow/experiments/empiar10076/init_maps"
KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/empiar10076/experiments/2025_06_07_z8_ds320_par_92x_exp4/analysis_diego.49/${CLUSTER_PATH}_umap/centers.txt"
COMPLETE_PAR_DIR="${DS_DIR}/master/delete_me/refine3d_exps/par_92x/Frealign9Parameter_0_r1_92x.par"

for ((i=1; i<NUM_ITER; i++)); do
  echo "[INFO] >>> Iteración $i"
  OUTPUT_DIR="/nfs/bartesaghilab2/ds672/master/workflow/experiments/empiar10076/${DATE}_z${ZDIM}_ds${DOWNSAMPLING}_iter${i}"
  #OUTPUT_DIR="/nfs/bartesaghilab2/ds672/master/workflow/experiments/empiar10076_example1000/${DATE}_z${ZDIM}_ds${DOWNSAMPLING}_iter${i}"
  #OUTPUT_DIR="/nfs/bartesaghilab2/ds672/master/workflow/experiments/empiar10180/${DATE}_z${ZDIM}_ds${DOWNSAMPLING}_iter${i}"
  
  POSES_DIR="$OUTPUT_PKL_DIR"

  source "$(dirname "$0")/cryodrgn.sh" "$i" "$POSES_DIR" "$OUTPUT_DIR" "$OLD_OUTPUT_DIR" "$OLD_N_ANALYSIS" 
  bash "$(dirname "$0")/analysis.sh" "$i" "$OUTPUT_DIR" "$N_ANALYSIS"
  source "$(dirname "$0")/clusters_processing.sh" "$i" "$OUTPUT_DIR" "$N_ANALYSIS" "$CLUSTER_PATH" "$COMPLETE_PAR_DIR" "$OLD_OUTPUT_DIR" "$OLD_N_ANALYSIS"
  source "$(dirname "$0")/frealign.sh" "$i" "$OUTPUT_DIR" "$N_ANALYSIS" "$OLD_POSES" "$CLUSTER_PATH"
  source "$(dirname "$0")/poses_processing.sh" "$i" "$OUTPUT_DIR" "$N_ANALYSIS" "$CLUSTER_PATH"
done

echo "[INFO] Todos los entrenamientos completados."
