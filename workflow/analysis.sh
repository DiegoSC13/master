#!/bin/bash

echo ""
echo "############################### ANALYSIS ###############################" 

i=$1
OUTPUT_DIR=$2
N_ANALYSIS=$3
CONFIG_NAME=$4

SCRIPT_DIR="$(dirname "$0")"
CONFIG_PATH="${SCRIPT_DIR}/${CONFIG_NAME}"

source "$CONFIG_PATH"

cd "${DS_DIR}/master/cryodrgn/commands" || exit 1
echo "[INFO] Analizando resultados de entrenamiento con zdim=${ZDIM}, Apix=${APIX} y k=${NUM_CLUSTERS} - Log: $LOGFILE_DIR"
python analyze_diego.py "$OUTPUT_DIR" "$N_ANALYSIS" \
  --skip-vol \
  --Apix $APIX  \
  --ksample $NUM_CLUSTERS \
  --min-clusters $((NUM_CLUSTERS-1)) \
  #> "$LOGFILE_DIR" 2>&1

#Guardo el outdir de esta iteración para cargar los últimos pesos en la que viene
#OLD_OUTPUT_DIR="$OUTPUT_DIR"

