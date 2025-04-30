#!/bin/bash

set -e
set -o pipefail

source /nfs/bartesaghilab2/ds672/anaconda3/etc/profile.d/conda.sh
conda activate cryodrgn

#Ruta base y ruta de trabajo
DS_DIR="/nfs/bartesaghilab2/ds672"
WORK_DIR="${DS_DIR}/empiar10076"

#Rutas a entradas de cryoDRGN
PARTICLES_DIR="${WORK_DIR}/downsampled_data/particles.128.mrcs"
CTF_DIR="${WORK_DIR}/inputs/initial_hidden_variables/all_particles/ctf_iter0_i.pkl"
POSES_DIR="${WORK_DIR}/inputs/par_processed/poses_pyem_converted.pkl"
INDEXES_DIR="${WORK_DIR}/inputs/initial_hidden_variables/filtered_particles/indexes.pkl"

#Parámetros de cryoDRGN
ENC_DIM=256
ENC_LAYERS=3
DEC_DIM=256
DEC_LAYERS=3
ZDIM=8
DOWNSAMPLING=128
N_EPOCHS=1 #De la iteración 0, la cantidad de épocas por iteración se controla con ALPHA

#Parámetros de loop 
NUM_ITER=2
ALPHA=1 #Para controlar cantidad de épocas de cryoDRGN por iteración

#Fecha y hora
DATE="$(date +%Y_%m_%d_%H_%M_%S)" 

#Parámetros de analysis_diego.py
APIX=3.275
NUM_CLUSTERS=5

for ((i=0; i<NUM_ITER; i++)); do
  echo ">>> Iteración $i"

  cd "${WORK_DIR}/experiments" || exit 1

  OUTPUT_DIR="${DATE}_z${ZDIM}_ds${DOWNSAMPLING}_iter${i}"
  mkdir $OUTPUT_DIR

  LOGFILE_DIR="$WORK_DIR/experiments/${OUTPUT_DIR}/log_$OUTPUT_DIR.log"
  
  echo "[INFO] Entrenando con zdim=${ZDIM} - Log: $LOGFILE_DIR"

  if [ "$i" -gt 0 ]; then
    echo "Esta no es la primera iteración, hago algo diferente"
    
    #Calculo nuevo número de épocas
    N_EPOCHS=$((N_EPOCHS+ALPHA*i))
    
    #Defino variable con nuevas poses
    NEW_POSES_DIR="$OUTPUT_PKL_DIR"

    #Entreno cryoDRGN
    cryodrgn train_vae "$PARTICLES_DIR" \
      --ctf "$CTF_DIR" \
      --poses "$NEW_POSES_DIR" \
      --zdim "$ZDIM" -n "$N_EPOCHS" \
      --enc-dim "$ENC_DIM" --enc-layers "$ENC_LAYERS" \
      --dec-dim "$DEC_DIM" --dec-layers "$DEC_LAYERS" \
      --ind "$INDEXES_DIR" \
      --load "$OLD_OUTPUT_DIR/weights.$N_ANALYSIS.pkl" \
      --uninvert-data \
      -o "$OUTPUT_DIR" \

      #Calculo número de época de análisis
      ((N_ANALYSIS=N_EPOCHS-ALPHA))
      #> "$LOGFILE_DIR" 2>&1
    cd /nfs/bartesaghilab2/ds672/master/cryodrgn/commands || exit 1
    echo "[INFO] Analizando resultados de entrenamiento con zdim=${ZDIM} - Log: $LOGFILE_DIR \n"
    python analyze_diego.py "$WORK_DIR/experiments/$OUTPUT_DIR" "$N_ANALYSIS" \
      --flip \
      --Apix $APIX  \
      --ksample $NUM_CLUSTERS \
      #> "$LOGFILE_DIR" 2>&1

    #Guardo el outdir de esta iteración para cargar los últimos pesos en la que viene
    OLD_OUTPUT_DIR="$OUTPUT_DIR"

    echo "[INFO] Terminó zdim=${ZDIM} a $(date)\n"

  else
    echo "Esta es la primera iteración"

    #Calculo algunos parámetros
    #echo "Alpha: ${ALPHA}"
    #echo "i: ${i}"
    N_EPOCHS=$((N_EPOCHS+ALPHA*i))
    #echo "Número de épocas: ${N_EPOCHS}"
    N_ANALYSIS=$((N_EPOCHS-ALPHA))
    
    #echo ""
    #echo "Número de análisis: ${N_ANALYSIS}"
    OLD_OUTPUT_DIR="$OUTPUT_DIR"

    #Corro cryoDRGN
    cryodrgn train_vae "$PARTICLES_DIR" \
      --ctf "$CTF_DIR" \
      --poses "$POSES_DIR" \
      --zdim "$ZDIM" -n "$N_EPOCHS" \
      --enc-dim "$ENC_DIM" --enc-layers "$ENC_LAYERS" \
      --dec-dim "$DEC_DIM" --dec-layers "$DEC_LAYERS" \
      --ind "$INDEXES_DIR" \
      --uninvert-data \
      -o "$OUTPUT_DIR" \
      #> "$LOGFILE_DIR" 2>&1
    
    # Me muevo a directorio de analysis_diego.py y corro
    cd /nfs/bartesaghilab2/ds672/master/cryodrgn/commands || exit 1
    echo "[INFO] Analizando resultados de entrenamiento con zdim=${ZDIM} - Log: $LOGFILE_DIR \n"
    python analyze_diego.py "$WORK_DIR/experiments/$OUTPUT_DIR" 0 \
      --flip \
      --Apix "$APIX"  \
      --ksample "$NUM_CLUSTERS" \
      #> "$LOGFILE_DIR" 2>&1
    echo "[INFO] Terminó zdim=${ZDIM} a $(date)\n"
  fi

  # Ruta base
  PYP_DIR="/nfs/bartesaghilab2/ds672/nextpyp"
  SIF_DIR="${PYP_DIR}/pyp.sif"
  INPUT_FILE_DIR="/nfs/bartesaghilab2/ds672/master/pipelines/empiar10076.txt"

  REFINE3D_INPUT=$(cat <<EOF
/nfs/bartesaghilab2/ds672/empiar10076/empiar_data/L17Combine_weight_local.mrc
/nfs/bartesaghilab2/ds672/empiar10076/empiar_data/Frealign9Parameter_0_r1.par
/nfs/bartesaghilab2/ds672/cryosparc/CS-empiar-10076-may-2024/J5/J5_003_volume_map.mrc
no
no
/nfs/bartesaghilab2/ds672/nextpyp/empiar10076/dont_care.mrc
${DS_DIR}/nextpyp/empiar10076/parfile_iter${i}.par
${DS_DIR}/nextpyp/empiar10076/changes_parfile_iter${i}.par
C1
0
0
1
1.31
300
2.7
0.07
1586
0
100
300
8
0
0
0
8
0
20
0
0
0
0
0
0
500
50
1
no
yes
yes
yes
yes
yes
yes
no
no
no
yes
yes
no
yes
no
EOF
)

  # Ejecutar dentro del contenedor
  echo "[INFO] Ejecuto refine3d..."
  singularity exec -B /hpc -B /nfs "$SIF_DIR" bash -c "
    cd /opt/pyp/external/frealignx && \
    echo \"$REFINE3D_INPUT\" | ./refine3d
  "

  # Rutas de archivos
  INPUT_PAR_DIR="${DS_DIR}/nextpyp/empiar10076/parfile_iter${i}.par" #salida de refine3d / entrada de crop_par.py
  CROPPED_PAR_DIR="${DS_DIR}/nextpyp/empiar10076/cropped_file_iter${i}.par" #salida de crop_par.py / entrada de par2star.py
  INPUT_STAR_DIR="${DS_DIR}/nextpyp/empiar10076/pyem_file_iter${i}.star" #salida de par2star.py / entrada de modify_star.py
  OUTPUT_STAR_DIR="${DS_DIR}/nextpyp/empiar10076/poses_4parse_iter${i}.star" #salida de modify_star.py / entrada de cryodrgn parse_pose_star
  OUTPUT_PKL_DIR="${DS_DIR}/empiar10076/poses_4cryodrgn_iter${i}.pkl" #salida de cryodrgn parse_pose_star. Poses para nueva iteración
  C=53 #Cantidad de filas a croppear en crop_par.py
  # Ejecutar los scripts Python
  echo "[INFO] Ejecuto crop_par.py..."
  cd "${DS_DIR}/master/pipelines"
  python crop_par.py "$INPUT_PAR_DIR" "$CROPPED_PAR_DIR" "$C"

  echo "[INFO] Ejecuto par2star.py..."
  cd "${DS_DIR}/pyem/pyem/cli"
  python par2star.py "$CROPPED_PAR_DIR" "$INPUT_STAR_DIR"

  echo "[INFO] Ejecuto modify_star.py..."
  cd "${DS_DIR}/master/pipelines"
  python modify_star.py "$INPUT_STAR_DIR" "$OUTPUT_STAR_DIR"

  echo "[INFO] Ejecuto cryodrgn parse_pose_star..."
  cryodrgn parse_pose_star "$OUTPUT_STAR_DIR" \
    --Apix 1.31 \
    -D 320 \
    -o "$OUTPUT_PKL_DIR"

  echo "[INFO] Tratamiento de poses de iter ${i} completado."

  done

echo "[INFO] Todos los entrenamientos completados."
