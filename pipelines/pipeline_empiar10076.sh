#!/bin/bash

set -e
set -o pipefail

source /nfs/bartesaghilab2/ds672/anaconda3/etc/profile.d/conda.sh
conda activate cryodrgn

# Parámetros generales
PARTICLES=../downsampled_data/particles.128.mrcs
CTF=../inputs/initial_hidden_variables/all_particles/ctf_iter0_i.pkl
POSES=../inputs/par_processed/poses_pyem_converted.pkl
INDEXES=../inputs/initial_hidden_variables/filtered_particles/indexes.pkl

ENC_DIM=256
ENC_LAYERS=3
DEC_DIM=256
DEC_LAYERS=3

N_EPOCHS=3
ALPHA=1 #Para controlar cantidad de épocas de cryoDRGN

DATE="$(date +%Y_%m_%d_%H_%M_%S)" #La hora por ahora no me importa
# Valores del espacio latente (puedes ajustar estos)
ZDIM=8
DOWNSAMPLING=128

NUM_ITER=3

for ((i=0; i<NUM_ITER; i++)); do
  echo ">>> Iteración $i"

  OUTDIR="${DATE}_z${ZDIM}_ds${DOWNSAMPLING}_iter${i}"
  LOGFILE="log_${OUTDIR}.log"
  
  echo "[INFO] Entrenando con zdim=${ZDIM} - Log: $LOGFILE \n"

  cd /nfs/bartesaghilab2/ds672/empiar10076/experiments || exit 1

  if [ "$i" -gt 0 ]; then
    echo "Esta no es la primera iteración, hago algo diferente"
    
    #Calculo nuevo número de épocas
    ((N_EPOCHS+=ALPHA*i))
    
    #Entreno cryoDRGN
    cryodrgn train_vae "$PARTICLES" \
      --ctf "$CTF" \
      --poses "$POSES" \
      --zdim "$ZDIM" -n "$N_EPOCHS" \
      --enc-dim "$ENC_DIM" --enc-layers "$ENC_LAYERS" \
      --dec-dim "$DEC_DIM" --dec-layers "$DEC_LAYERS" \
      --ind "$INDEXES" \
      --load "$OLD_OUTDIR/weights.$N_ANALYSIS.pkl" \
      --uninvert-data \
      -o "$OUTDIR" \

      #Calculo número de época de análisis
      ((N_ANALYSIS=N_EPOCHS-ALPHA))
      #> "$LOGFILE" 2>&1
    cd /nfs/bartesaghilab2/ds672/master/cryodrgn/commands || exit 1
    echo "[INFO] Analizando resultados de entrenamiento con zdim=${ZDIM} - Log: $LOGFILE \n"
    python analyze_diego.py "../../../empiar10076/experiments/$OUTDIR" "$N_ANALYSIS" \
      --flip \
      --Apix 3.275  \
      --ksample 5 \
      #> "$LOGFILE" 2>&1

    #Guardo el outdir de esta iteración para cargar los últimos pesos en la que viene
    OLD_OUTDIR="$OUTDIR"

    echo "[INFO] Terminó zdim=${ZDIM} a $(date)\n"

  else
    echo "Esta es la primera iteración"

    #Calculo algunos parámetros
    ((N_EPOCHS+=ALPHA*i))
    ((N_ANALYSIS=N_EPOCHS-ALPHA))
    OLD_OUTDIR="$OUTDIR"
    #Corro cryoDRGN
    cryodrgn train_vae "$PARTICLES" \
      --ctf "$CTF" \
      --poses "$POSES" \
      --zdim "$ZDIM" -n "$N_EPOCHS" \
      --enc-dim "$ENC_DIM" --enc-layers "$ENC_LAYERS" \
      --dec-dim "$DEC_DIM" --dec-layers "$DEC_LAYERS" \
      --ind "$INDEXES" \
      --uninvert-data \
      -o "$OUTDIR" \
      #> "$LOGFILE" 2>&1
    
    # Me muevo a directorio de analysis_diego.py y corro
    cd /nfs/bartesaghilab2/ds672/master/cryodrgn/commands || exit 1
    echo "[INFO] Analizando resultados de entrenamiento con zdim=${ZDIM} - Log: $LOGFILE \n"
    python analyze_diego.py "../../../empiar10076/experiments/$OUTDIR" 0 \
      --flip \
      --Apix 3.275  \
      --ksample 8 \
      > "$LOGFILE" 2>&1
    echo "[INFO] Terminó zdim=${ZDIM} a $(date)\n"
  fi
done

echo "[INFO] Todos los entrenamientos completados."
