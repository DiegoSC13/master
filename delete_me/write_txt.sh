#!/bin/bash

# Definición de variables
OUTPUT_PKL_DIR="/nfs/bartesaghilab2/ds672/empiar10180/inputs/poses.pkl" #Change me
OLD_OUTPUT_DIR="/nfs/bartesaghilab2/ds672/empiar10180/experiments/2025_06_19_z8_ds320"
OLD_N_ANALYSIS=39 #Change me
OLD_MAPS_DIR="/nfs/bartesaghilab2/ds672/master/workflow/base_conditions/filtered_Nrefs/empiar10180_\${CLUSTER_PATH}_ds\${DIM}/reconstruct3d_output"
KMEANS_CENTERS="/nfs/bartesaghilab2/ds672/master/workflow/base_conditions/filtered_Nrefs/empiar10180_\${CLUSTER_PATH}_ds\${DIM}/cryodrgn/centers.txt"
COMPLETE_PAR_DIR="/nfs/bartesaghilab2/ds672/master/delete_me/empiar10180/consensus_data_MT_filtered_2arange.par"

# Archivo de salida (puede cambiarse si querés otro nombre)
VARS_FILE="/nfs/bartesaghilab2/ds672/master/delete_me/empiar10076_ds320_k15.txt"

# Escribir (o sobrescribir) el archivo
cat <<EOF > "$VARS_FILE"
OUTPUT_PKL_DIR="$OUTPUT_PKL_DIR" 
OLD_OUTPUT_DIR="$OLD_OUTPUT_DIR"
OLD_N_ANALYSIS=$OLD_N_ANALYSIS 
OLD_MAPS_DIR="$OLD_MAPS_DIR"
KMEANS_CENTERS="$KMEANS_CENTERS"
COMPLETE_PAR_DIR="$COMPLETE_PAR_DIR"
EOF

echo "Archivo '$VARS_FILE' escrito correctamente."
