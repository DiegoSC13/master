#!/bin/bash

set -e
set -o pipefail

source /nfs/bartesaghilab2/ds672/anaconda3/etc/profile.d/conda.sh
conda activate cryodrgn

#Fecha y hora
DATE="$(date +%Y_%m_%d_%H_%M_%S)" 

#Ruta base y ruta de trabajo
DS_DIR="/nfs/bartesaghilab2/ds672"
WORK_DIR="${DS_DIR}/empiar10076"

#Rutas a entradas de cryoDRGN
PARTICLES_DIR="${WORK_DIR}/empiar_data/L17Combine_weight_local.mrc"
CTF_DIR="${WORK_DIR}/inputs/initial_hidden_variables/all_particles/ctf_iter0_i.pkl"
POSES_DIR="${WORK_DIR}/inputs/par_processed/poses_pyem_converted.pkl"
INDEXES_DIR="${WORK_DIR}/inputs/initial_hidden_variables/filtered_particles/indexes.pkl"

#Parámetros de cryoDRGN
ENC_DIM=1024
ENC_LAYERS=3
DEC_DIM=1024
DEC_LAYERS=3
ZDIM=8
DOWNSAMPLING=320
N_EPOCHS=50 #De la iteración 0, la cantidad de épocas por iteración se controla con ALPHA

#Parámetros de loop 
NUM_ITER=2
ALPHA=10 #Para controlar cantidad de épocas de cryoDRGN por iteración

#Parámetros de analysis_diego.py
APIX=1.31
NUM_CLUSTERS=5

#Rutas para correr refine3d y reconstruct3d_stats
PYP_DIR="${DS_DIR}/nextpyp"
SIF_DIR="${PYP_DIR}/pyp.sif"
#INPUT_FILE_DIR="/nfs/bartesaghilab2/ds672/master/pipelines/empiar10076.txt"

#Datos de las imágenes originales
PIXEL_SIZE=1.31 #En angstroms
IMAGE_SIZE=320 #En píxeles

for ((i=0; i<NUM_ITER; i++)); do
  echo ">>> Iteración $i"

  cd "${WORK_DIR}/experiments" || exit 1

  #Genero directorio de trabajo
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
      #> "$LOGFILE_DIR" 2>&1

      #Calculo número de época de análisis
      N_ANALYSIS=$((N_EPOCHS-1))
      
    cd "${DS_DIR}/master/cryodrgn/commands" || exit 1
    echo "[INFO] Analizando resultados de entrenamiento con zdim=${ZDIM} - Log: $LOGFILE_DIR"
    python analyze_diego.py "$WORK_DIR/experiments/$OUTPUT_DIR" "$N_ANALYSIS" \
      --flip \
      --Apix $APIX  \
      --ksample $NUM_CLUSTERS \
      #> "$LOGFILE_DIR" 2>&1

    #Guardo el outdir de esta iteración para cargar los últimos pesos en la que viene
    OLD_OUTPUT_DIR="$OUTPUT_DIR"

    echo "[INFO] Terminó zdim=${ZDIM} a $(date)"

  else
    echo "Esta es la primera iteración"
    if [ -z "$1" ]; then
      echo "[INFO] No se proporcionó un archivo de entrada. Se entrena"
      INPUT_FILE="default_input.txt"
      
      # Aquí generas el contenido del archivo (puedes personalizar esto)
      echo "Este es un archivo de entrada generado automáticamente." > "$INPUT_FILE"
      #Calculo algunos parámetros
      #echo "Alpha: ${ALPHA}"
      #echo "i: ${i}"
      N_EPOCHS=$((N_EPOCHS+ALPHA)) #En la primera iteración siempre tengo i=0
      #echo "Número de épocas: ${N_EPOCHS}"
      N_ANALYSIS=$((N_EPOCHS-1)) #Así me quedo con la última
      
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
      cd "${DS_DIR}/master/cryodrgn/commands" || exit 1
      echo "[INFO] Analizando resultados de entrenamiento con zdim=${ZDIM} - Log: $LOGFILE_DIR"
      python analyze_diego.py "$WORK_DIR/experiments/$OUTPUT_DIR" "$N_ANALYSIS" \
        --flip \
        --Apix "$APIX"  \
        --ksample "$NUM_CLUSTERS" \
        #> "$LOGFILE_DIR" 2>&1
      echo "[INFO] Terminó zdim=${ZDIM} a $(date)"
    
    else
      INPUT_FILE="$1"
      OUTPUT_DIR=$(basename "$INPUT_FILE")
      echo "Última parte del path: $OUTPUT_DIR"
      #N_EPOCHS=$((N_EPOCHS+ALPHA)) #En la primera iteración siempre tengo i=0
      #echo "Número de épocas: ${N_EPOCHS}"
      N_ANALYSIS=$((N_EPOCHS-1)) #Así me quedo con la última
      
      #echo ""
      #echo "Número de análisis: ${N_ANALYSIS}"
      OLD_OUTPUT_DIR="$OUTPUT_DIR"
    fi
  fi

  #Análisis de labels
  # cd "$WORK_DIR/experiments/${OUTPUT_DIR}" || exit 1
  # mkdir mrc_iter${i}
  # cd "$WORK_DIR/master/pipelines" || exit 1
  # python mrc_per_classes 
  cd "$DS_DIR/master/pipelines" || exit 1 
  python generate_pars_per_cluster.py \
  --labels_pkl_path "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/labels.pkl" \
  --particles_per_label_folder "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/particles_per_label" \
  --output_folder "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/starfiles_per_label" \
  --parfile_path "${DS_DIR}/master/delete_me/refine3d_exps/par_92x/Frealign9Parameter_0_r1_92x.par" \
  --iter ${i} \
  --metadata_row_num 1
  # python labels_processing.py ${WORK_DIR}/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/labels.pkl ${WORK_DIR}/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/particles_per_label ${WORK_DIR}/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/starfiles_per_label ${WORK_DIR}/old_inputs/Parameters.star ${i} 13

  #Corro mrc_from_pkl.py para generar los mrc de entrada a refine3d
  cd "$DS_DIR/master/pipelines" || exit 1
  python mrc_from_pkl.py \
  --pkls_folder "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/particles_per_label" \
  --mrc_filepath "${DS_DIR}/empiar10076/empiar_data/L17Combine_weight_local.mrc" \
  --output_folder "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/mrc_cluster"

  #Defino directorio de salida de .par's de refine3d
  cd "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/"
  mkdir refine3d_output
  mkdir reconstruct3d_output

  #Itero en los clusters
  for ((j=0; j<NUM_CLUSTERS; j++)); do
    #Cambio los índices de los .star para que refine todas las partículas del .mrc
    cd "${DS_DIR}/master/pipelines"
    python indexes2arange_par.py \
    --input_par "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/starfiles_per_label/Cluster${j}_iter${i}.par" \
    --output_par "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/starfiles_per_label/Cluster${j}_iter${i}2arange.par"

    #Armo entrada a refine3d
    REFINE3D_INPUT=$(cat <<EOF
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/mrc_cluster/particles_class_${j}.mrc
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/starfiles_per_label/Cluster${j}_iter${i}2arange.par
${DS_DIR}/master/delete_me/reconstruct3d_exps/par_92x_refined/exp4_redo/output_res.mrc
/nfs/bartesaghilab2/ds672/master/delete_me/reconstruct3d_exps/par_92x_refined/exp4_redo/output_reconstruction3d_stats.txt
yes
/nfs/bartesaghilab2/ds672/nextpyp/empiar10076/dont_care.mrc
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/refine3d_output/parfile_iter${i}_cluster${j}.par
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/refine3d_output/changes_parfile_iter${i}_cluster${j}.par
C1
0
0
1
1.31
300
2.7
0.07
1586
30
150
30
8
0
0
140
8
7.5
20
15
15
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
yes
no
yes
no
no
yes
no
EOF
)

    #Armo entrada de reconstruct3d_stats
    RECONSTRUCT3D_REFINED_INPUT=$(cat <<EOF
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/mrc_cluster/particles_class_${j}.mrc
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/refine3d_output/parfile_iter${i}_cluster${j}.par
${DS_DIR}/master/delete_me/reconstruct3d_exps/par_92x_refined/exp4_redo/output_res.mrc
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/reconstruct3d_output/output_reconstruction3d_stats_1_iter${i}_cluster${j}.mrc
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/reconstruct3d_output/output_reconstruction3d_stats_2_iter${i}_cluster${j}.mrc
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/reconstruct3d_output/output_res_iter${i}_cluster${j}.mrc
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/reconstruct3d_output/output_reconstruction3d_stats_iter${i}_cluster${j}.txt
C1
0
0
1.31
300
2.7
0.07
1586
0
100
0
0
5
1
1
1
yes
yes
no
no
no
yes
no
no
no
no
${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/reconstruct3d_output/output_reconstruction3d_stats_iter${i}_cluster${j}.dat
/nfs/bartesaghilab2/ds672/master/delete_me/reconstruct3d_exps/par_92x_refined/exp4_redo/output_reconstruction3d_stats.dat
EOF
)

  # Ejecuto refine3d dentro del contenedor
    echo "[INFO] Ejecuto refine3d..."
    singularity exec -B /hpc -B /nfs "$SIF_DIR" bash -c "
      cd /opt/pyp/external/frealignx && \
      echo \"$RECONSTRUCT3D_INITIAL_INPUT\" | ./reconstruct3d_stats
      echo \"$REFINE3D_INPUT\" | ./refine3d
      echo \"$RECONSTRUCT3D_REFINED_INPUT\" | ./reconstruct3d_stats
  "
    INPUT_PAR_DIR="${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/refine3d_output/parfile_iter${i}_cluster${j}.par" #salida de refine3d / entrada de crop_par.py
    CROPPED_PAR_DIR="${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/refine3d_output/parfile_iter${i}_cluster${j}_cropped.par" #salida de crop_par.py / entrada de par2star.py
    C=53 #Cantidad de filas a croppear en crop_par.py

    echo "[INFO] Ejecuto crop_par.py..."
    cd "${DS_DIR}/master/pipelines"
    python crop_par.py "$INPUT_PAR_DIR" "$CROPPED_PAR_DIR" "$C"

    echo "[INFO] Ejecuto arange2indexes_par.py..."
    python arange2indexes_par.py \
    --par_file "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/refine3d_output/parfile_iter${i}_cluster${j}_cropped.par" \
    --pkl_file "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/particles_per_label/particles_class_${j}.pkl" \
    --output_file "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/refine3d_output/parfile_iter${i}_cluster${j}_cropped_index_restored.par"

  done

# Rutas de archivos
  # INPUT_PAR_DIR="${DS_DIR}/nextpyp/empiar10076/parfile_iter${i}_cluster${j}.par" #salida de refine3d / entrada de crop_par.py
  # CROPPED_PAR_DIR="${DS_DIR}/nextpyp/empiar10076/cropped_file_iter${i}_cluster${j}.par" #salida de crop_par.py / entrada de par2star.py
  
  echo "[INFO] Ejecuto combine_pars.py..."
  python combine_pars.py \
    --input_dir "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/refine3d_output" \
    --labels_pkl "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/labels.pkl" \
    --output_par "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/refine3d_output/parfile_iter${i}_complete.par"

  #Creo carpeta para salidas
  mkdir "${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/poses_files"
  COMPLETE_PAR_DIR="${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/refine3d_output/parfile_iter${i}_complete.par"
  INPUT_STAR_DIR="${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/poses_files/pyem_file_iter${i}.star" #salida de par2star.py / entrada de modify_star.py
  OUTPUT_STAR_DIR="${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/poses_files/poses_4parse_iter${i}.star" #salida de modify_star.py / entrada de cryodrgn parse_pose_star
  OUTPUT_PKL_DIR="${DS_DIR}/empiar10076/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/kmeans5_umap/poses_files/poses_4cryodrgn_iter${i}.pkl" #salida de cryodrgn parse_pose_star. Poses para nueva iteración
  C=53 #Cantidad de filas a croppear en crop_par.py
  # # Ejecutar los scripts Python
  # echo "[INFO] Ejecuto crop_par.py..."
  # cd "${DS_DIR}/master/pipelines"
  # python crop_par.py "$INPUT_PAR_DIR" "$CROPPED_PAR_DIR" "$C"

  echo "[INFO] Ejecuto par2star.py..."
  cd "${DS_DIR}/pyem/pyem/cli"
  python par2star.py "$COMPLETE_PAR_DIR" "$INPUT_STAR_DIR"

  echo "[INFO] Ejecuto modify_star.py..."
  cd "${DS_DIR}/master/pipelines"
  python modify_star.py "$INPUT_STAR_DIR" "$OUTPUT_STAR_DIR"

  echo "[INFO] Ejecuto cryodrgn parse_pose_star..."
  cryodrgn parse_pose_star "$OUTPUT_STAR_DIR" \
    --Apix "$PIXEL_SIZE" \
    -D "$IMAGE_SIZE" \
    -o "$OUTPUT_PKL_DIR"

  echo "[INFO] Tratamiento de poses de iter ${i} completado."

  done

echo "[INFO] Todos los entrenamientos completados."
