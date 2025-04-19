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
ALPHA=1 #Para controlar cantidad de épocas de cryoDRGN

DATE="$(date +%Y_%m_%d_%H_%M_%S)" #La hora por ahora no me importa
# Valores del espacio latente (puedes ajustar estos)
ZDIM=8
DOWNSAMPLING=128

APIX=3.275
NUM_CLUSTERS=5

NUM_ITER=2

for ((i=0; i<NUM_ITER; i++)); do
  echo ">>> Iteración $i"

  OUTDIR="${DATE}_z${ZDIM}_ds${DOWNSAMPLING}_iter${i}"
  LOGFILE="log_${OUTDIR}.log"
  
  echo "[INFO] Entrenando con zdim=${ZDIM} - Log: $LOGFILE"

  cd /nfs/bartesaghilab2/ds672/empiar10076/experiments || exit 1

  if [ "$i" -gt 0 ]; then
    echo "Esta no es la primera iteración, hago algo diferente"
    
    #Calculo nuevo número de épocas
    N_EPOCHS=((N_EPOCHS+ALPHA*i))
    
    #Defino variable con nuevas poses
    NEW_POSES="$OUTPUT_PKL"

    #Entreno cryoDRGN
    cryodrgn train_vae "$PARTICLES" \
      --ctf "$CTF" \
      --poses "$NEW_POSES" \
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
    echo "Alpha: ${ALPHA}"
    echo "i: ${i}"
    N_EPOCHS=$((N_EPOCHS+ALPHA*i))
    echo "Número de épocas: ${N_EPOCHS}"
    N_ANALYSIS=$((N_EPOCHS-ALPHA))
    
    echo ""
    echo "Número de análisis: ${N_ANALYSIS}"
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
      --Apix "$APIX"  \
      --ksample "$NUM_CLUSTERS" \
      > "$LOGFILE" 2>&1
    echo "[INFO] Terminó zdim=${ZDIM} a $(date)\n"
  fi

  # Ruta base
  PYP_DIR="/nfs/bartesaghilab2/ds672/nextpyp"
  SIF="${PYP_DIR}/pyp.sif"
  INPUT_FILE="/nfs/bartesaghilab2/ds672/master/pipelines/empiar10076.txt"

  singularity exec -B /hpc -B /nfs "$SIF" bash -c "
    cd /opt/pyp/external/frealignx && \
    ./refine3d < $INPUT_FILE
  "

  source /nfs/bartesaghilab2/ds672/anaconda3/etc/profile.d/conda.sh
  conda activate cryodrgn

  # Rutas de archivos
  DS_DIR="/nfs/bartesaghilab2/ds672"
  INPUT_PAR="${DS_DIR}/nextpyp/empiar10076/output_parameter_file_N.par"
  CROPPED_PAR="${DS_DIR}/nextpyp/empiar10076/output_parameter_file_N_cropped.par"
  INPUT_STAR="${DS_DIR}/nextpyp/empiar10076/output_parameter_file_N_cropped_pyem.star"
  OUTPUT_STAR="${DS_DIR}/nextpyp/empiar10076/output_parameter_file_N_cropped_pyem_4parse.star"
  OUTPUT_PKL="${DS_DIR}/empiar10076/output_parameter_file_N_cropped_pyem_4cryodrgn.pkl"
  C=53
  # Ejecutar los scripts Python
  cd "${DS_DIR}/master/pipelines"
  python crop_par.py "$INPUT_PAR" "$CROPPED_PAR" "$C"
  cd "${DS_DIR}/pyem/pyem/cli"
  python par2star.py "$CROPPED_PAR" "$INPUT_STAR"
  cd "${DS_DIR}/master/pipelines"
  python modify_star.py "$INPUT_STAR" "$OUTPUT_STAR"
  cryodrgn parse_pose_star "$OUTPUT_STAR" \
    --Apix 1.31 \
    -D 320 \
    -o "$OUTPUT_PKL"

  echo "[INFO] Tratamiento de poses completado."

  done

echo "[INFO] Todos los entrenamientos completados."
