#!/bin/bash

echo ""
echo "############################### POSES PROCESSING ###############################" 

i=$1
OUTPUT_DIR=$2
N_ANALYSIS=$3
CLUSTER_PATH=$4
CONFIG_NAME=$5

SCRIPT_DIR="$(dirname "$0")"
CONFIG_PATH="${SCRIPT_DIR}/${CONFIG_NAME}"

source "$CONFIG_PATH"

echo "[INFO] Ejecuto combine_pars.py..."
cd "${DS_DIR}/master/pipelines"
# python combine_pars.py \
#   --input_dir "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output" \
#   --labels_pkl "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/new_labels.pkl" \
#   --output_par "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output/parfile_iter${i}_complete.par"

python combine_pars_updated.py \
  --input_dir "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output" \
  --labels_pkl "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/new_labels.pkl" \
  --output_par "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output/parfile_iter${i}_complete.par" \
  --backup_par "${COMPLETE_PAR_DIR}"


# COMPLETE_PAR_DIR="${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output/parfile_iter${i}_complete.par"

#Creo carpeta para salidas
mkdir "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/poses_files"
COMPLETE_PAR_DIR="${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/refine3d_output/parfile_iter${i}_complete.par"
INPUT_STAR_DIR="${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/poses_files/pyem_file_iter${i}.star" #salida de par2star.py / entrada de modify_star.py
OUTPUT_STAR_DIR="${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/poses_files/poses_4parse_iter${i}.star" #salida de modify_star.py / entrada de cryodrgn parse_pose_star
OUTPUT_SHORT_PKL_DIR="${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/poses_files/poses_4cryodrgn_iter${i}.pkl" #salida de cryodrgn parse_pose_star. Poses para nueva iteración #EDIT: Agrego 0s para no romper iteración cuando hay índices de filtrado
OUTPUT_PKL_DIR="${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/poses_files/poses_4cryodrgn_expanded_iter${i}.pkl" #salida de cryodrgn parse_pose_star. Poses para nueva iteración

#C=53 #Cantidad de filas a croppear en crop_par.py
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
  -o "$OUTPUT_SHORT_PKL_DIR"

if [ "$DATASET" == "10076" ]; then
  N=131899
elif [ "$DATASET" == "10180" ]; then
  N=327490
else
  echo "[ERROR] Dataset no reconocido: $DATASET"
  exit 1
fi

echo "[INFO] Ejecuto expand_poses.py..."
python expand_poses.py "$OUTPUT_SHORT_PKL_DIR" "$INDEXES_DIR" "$N" "$OUTPUT_PKL_DIR" 

cd "${DS_DIR}/master/workflow"

echo "[INFO] Tratamiento de poses de iter ${i} completado."