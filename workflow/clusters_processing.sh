#!/bin/bash

source "$(dirname "$0")/config_10076.sh"

echo ""
echo "############################### CLUSTERS PROCESSING ###############################" 
i=$1
OUTPUT_DIR=$2
N_ANALYSIS=$3
CLUSTER_PATH=$4
COMPLETE_PAR_DIR=$5
OLD_OUTPUT_DIR=$6
OLD_N_ANALYSIS=$7

cd "$DS_DIR/master/pipelines" || exit 1 
python align_clusters.py \
    --X "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/umap.pkl" \
    --labels_prev "${OLD_OUTPUT_DIR}/analysis_diego.${OLD_N_ANALYSIS}/${CLUSTER_PATH}_umap/labels.pkl" \
    --labels_curr "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/labels.pkl" \
    --output "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/new_labels.pkl"

python generate_pars_per_cluster.py \
    --labels_pkl_path "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/new_labels.pkl" \
    --particles_per_label_folder "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/particles_per_label" \
    --output_folder "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/parfiles_per_label" \
    --parfile_path "${COMPLETE_PAR_DIR}" \
    --iter ${i} \
    --metadata_row_num 1
# python labels_processing.py ${WORK_DIR}/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/labels.pkl ${WORK_DIR}/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/particles_per_label ${WORK_DIR}/experiments/${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/parfiles_per_label ${WORK_DIR}/old_inputs/Parameters.star ${i} 13

#Corro mrc_from_pkl.py para generar los mrc de entrada a refine3d
cd "$DS_DIR/master/pipelines" || exit 1
python mrc_from_pkl.py \
    --pkls_folder "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/particles_per_label" \
    --mrc_filepath "${DS_DIR}/empiar10076/empiar_data/L17Combine_weight_local.mrc" \
    --output_folder "${OUTPUT_DIR}/analysis_diego.${N_ANALYSIS}/${CLUSTER_PATH}_umap/mrc_cluster"

cd "${DS_DIR}/master/workflow"
OLD_OUTPUT_DIR="$OUTPUT_DIR"
OLD_N_ANALYSIS="$N_ANALYSIS"