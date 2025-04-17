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
N_EPOCHS=1

DATE="$(date +%Y_%m_%d_)" #%H%M%S)" #La hora por ahora no me importa
# Valores del espacio latente (puedes ajustar estos)
ZDIM_LIST=(8 20)
DOWNSAMPLING=128

# Bucle sobre los zdim
for ZDIM in "${ZDIM_LIST[@]}"; do
  OUTDIR="${DATE}_z${ZDIM}_ds${DOWNSAMPLING}_testing_bash_4"
  LOGFILE="log_${OUTDIR}.log"
  
  echo "[INFO] Entrenando con zdim=${ZDIM} - Log: $LOGFILE \n"

  cd /nfs/bartesaghilab2/ds672/empiar10076/experiments || exit 1

  cryodrgn train_vae "$PARTICLES" \
    --ctf "$CTF" \
    --poses "$POSES" \
    --zdim "$ZDIM" -n "$N_EPOCHS" \
    --enc-dim "$ENC_DIM" --enc-layers "$ENC_LAYERS" \
    --dec-dim "$DEC_DIM" --dec-layers "$DEC_LAYERS" \
    --ind "$INDEXES" \
    --uninvert-data \
    -o "$OUTDIR" \
    > "$LOGFILE" 2>&1

  cd /nfs/bartesaghilab2/ds672/master/cryodrgn/commands || exit 1
  echo "[INFO] Analizando resultados de entrenamiento con zdim=${ZDIM} - Log: $LOGFILE \n"
  python analyze_diego.py "../../../empiar10076/experiments/$OUTDIR" 0 \
    --flip \
    --Apix 3.275  \
    --ksample 8 \
    > "$LOGFILE" 2>&1
  echo "[INFO] Terminó zdim=${ZDIM} a $(date)\n"
done

echo "[INFO] Todos los entrenamientos completados."
