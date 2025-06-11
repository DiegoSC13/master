if [ "$i" -gt 0 ]; then
    echo "Esta no es la primera iteración, hago algo diferente"
    #Calculo número de época de análisis
    N_ANALYSIS=$((N_EPOCHS-1))
      
    cd "${DS_DIR}/master/cryodrgn/commands" || exit 1
    echo "[INFO] Analizando resultados de entrenamiento con zdim=${ZDIM}, Apix=${APIX} y k=${NUM_CLUSTERS} - Log: $LOGFILE_DIR"
    python analyze_diego.py "$WORK_DIR/experiments/$OUTPUT_DIR" "$N_ANALYSIS" \
      --flip \
      --Apix $APIX  \
      --ksample $NUM_CLUSTERS \
      #> "$LOGFILE_DIR" 2>&1

    #Guardo el outdir de esta iteración para cargar los últimos pesos en la que viene
    OLD_OUTPUT_DIR="$OUTPUT_DIR"

