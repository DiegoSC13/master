#!/bin/bash

source "$(dirname "$0")/config_10076.sh"

echo ""
echo "############################### CRYODRGN ###############################" 


i=$1
POSES_DIR=$2
OUTPUT_DIR=$3
OLD_OUTPUT_DIR=$4
OLD_N_ANALYSIS=$5
#cond_param=$

#Calculo nuevo número de épocas
N_EPOCHS=$((N_EPOCHS+ALPHA*i))
echo "Número de épocas de iteración ${i}: ${N_EPOCHS}"

#Entreno cryoDRGN
#Volver a poner --ind "$INDEXES_DIR" \
cryodrgn train_vae "$PARTICLES_DIR" \
  --ctf "$CTF_DIR" \
  --poses "$POSES_DIR" \
  --zdim "$ZDIM" -n "$N_EPOCHS" \
  --enc-dim "$ENC_DIM" --enc-layers "$ENC_LAYERS" \
  --dec-dim "$DEC_DIM" --dec-layers "$DEC_LAYERS" \
  --load "$OLD_OUTPUT_DIR/weights.$OLD_N_ANALYSIS.pkl" \
  --ind "$INDEXES_DIR" \
  --uninvert-data \
  -o "$OUTPUT_DIR" \
  #> "$LOGFILE_DIR" 2>&1

N_ANALYSIS=$((N_EPOCHS-1))
