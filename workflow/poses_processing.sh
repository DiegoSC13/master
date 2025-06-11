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