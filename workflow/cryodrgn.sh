#!/bin/bash

set -e
set -o pipefail

source "$(dirname "$0")/config_10076.sh"

i=$1
cond_param=$2

if [ "$i" -gt 0 ]; then
    echo "Esta no es la primera iteración, hago algo diferente"
    
    #Calculo nuevo número de épocas
    N_EPOCHS=$((N_EPOCHS+ALPHA*i))
    echo "Número de épocas: ${N_EPOCHS}"
    #Defino variable con nuevas poses
    NEW_POSES_DIR="$OUTPUT_PKL_DIR"

    #DELETE ME
    NEW_POSES_DIR="$POSES_DIR"
    N_ANALYSIS=1
    OLD_OUTPUT_DIR="$OUTPUT_DIR"

    #Entreno cryoDRGN
    #Volver a poner --ind "$INDEXES_DIR" \
    cryodrgn train_vae "$PARTICLES_DIR" \
      --ctf "$CTF_DIR" \
      --poses "$NEW_POSES_DIR" \
      --zdim "$ZDIM" -n "$N_EPOCHS" \
      --enc-dim "$ENC_DIM" --enc-layers "$ENC_LAYERS" \
      --dec-dim "$DEC_DIM" --dec-layers "$DEC_LAYERS" \
      --load "$OLD_OUTPUT_DIR/weights.$N_ANALYSIS.pkl" \
      --uninvert-data \
      -o "$OUTPUT_DIR" \
      #> "$LOGFILE_DIR" 2>&1
else
    echo "Esta es la primera iteración"
    if [ -z "$BASE_TRAIN" ]; then
      echo "[INFO] No se proporcionó un archivo de entrada. Se entrena"

      N_EPOCHS=$((N_EPOCHS+ALPHA)) #En la primera iteración siempre tengo i=0
      echo "Número de épocas: ${N_EPOCHS}"
      N_ANALYSIS=$((N_EPOCHS-1)) #Así me quedo con la última
      
      #echo ""
      #echo "Número de análisis: ${N_ANALYSIS}"
      OLD_OUTPUT_DIR="$OUTPUT_DIR"

      #Corro cryoDRGN
      #Volver a poner #--ind "$INDEXES_DIR" \ cuando suelte el ejemplo de juguete
      cryodrgn train_vae "$PARTICLES_DIR" \
        --ctf "$CTF_DIR" \
        --poses "$POSES_DIR" \
        --zdim "$ZDIM" -n "$N_EPOCHS" \
        --enc-dim "$ENC_DIM" --enc-layers "$ENC_LAYERS" \
        --dec-dim "$DEC_DIM" --dec-layers "$DEC_LAYERS" \
        --uninvert-data \
        -o "$OUTPUT_DIR" \
        #> "$LOGFILE_DIR" 2>&1
      
    else
      INPUT_FILE="$BASE_TRAIN"
      OUTPUT_DIR=$(basename "$INPUT_FILE")
      echo "OUTPUT_DIR: $OUTPUT_DIR"
      #N_EPOCHS=$((N_EPOCHS+ALPHA)) #En la primera iteración siempre tengo i=0
      #echo "Número de épocas: ${N_EPOCHS}"
      N_ANALYSIS=$((N_EPOCHS-1)) #Así me quedo con la última
      
      #echo ""
      #echo "Número de análisis: ${N_ANALYSIS}"
      OLD_OUTPUT_DIR="$OUTPUT_DIR"
      fi
  fi