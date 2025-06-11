  for ((i=0; i<NUM_ITER; i++)); do
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