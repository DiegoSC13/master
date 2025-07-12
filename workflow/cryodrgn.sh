#!/bin/bash

echo ""
echo "############################### CRYODRGN ###############################" 

i=$1
POSES_DIR=$2
OUTPUT_DIR=$3
OLD_OUTPUT_DIR=$4
OLD_N_ANALYSIS=$5
CONFIG_NAME=$6

SCRIPT_DIR="$(dirname "$0")"
CONFIG_PATH="${SCRIPT_DIR}/${CONFIG_NAME}"

source "$CONFIG_PATH"

cd "${DS_DIR}/master/pipelines"
python clear_memory.py

#Calculo nuevo número de épocas
N_EPOCHS=$((N_EPOCHS+ALPHA*i))
echo "Número de épocas de iteración ${i}: ${N_EPOCHS}"

#Entreno cryoDRGN
#Volver a poner --ind "$INDEXES_DIR" \
# if [ "$i" -eq 1 ]; then
cryodrgn train_vae "$PARTICLES_DIR" \
  --ctf "$CTF_DIR" \
  --poses "$POSES_DIR" \
  --zdim "$ZDIM" -n "$N_EPOCHS" \
  --enc-dim "$ENC_DIM" --enc-layers "$ENC_LAYERS" \
  --dec-dim "$DEC_DIM" --dec-layers "$DEC_LAYERS" \
  --ind "$INDEXES_DIR" \
  --load "$OLD_OUTPUT_DIR/weights.$OLD_N_ANALYSIS.pkl" \
  --uninvert-data \
  -o "$OUTPUT_DIR" 
    #> "$LOGFILE_DIR" 2>&1
# else
#   cryodrgn train_vae "$FILTERED_PARTICLES_DIR" \
#     --ctf "$FILTERED_CTF_DIR" \
#     --poses "$POSES_DIR" \
#     --zdim "$ZDIM" -n "$N_EPOCHS" \
#     --enc-dim "$ENC_DIM" --enc-layers "$ENC_LAYERS" \
#     --dec-dim "$DEC_DIM" --dec-layers "$DEC_LAYERS" \
#     --load "$OLD_OUTPUT_DIR/weights.$OLD_N_ANALYSIS.pkl" \
#     --uninvert-data \
#     -o "$OUTPUT_DIR" 
# fi

N_ANALYSIS=$((N_EPOCHS-1))
cd "${DS_DIR}/master/workflow"
