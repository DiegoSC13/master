#!/bin/bash

set -e
set -o pipefail

source "$(dirname "$0")/config_10076.sh"

i=0
echo "[INFO] >>> Primera iteración $i"
bash "$(dirname "$0")/cryodrgn.sh" "$i" "$BASE_TRAIN"

for ((i=1; i<NUM_ITER; i++)); do
  echo "[INFO] >>> Iteración $i"
  bash "$(dirname "$0")/cryodrgn.sh" "$i"
  # bash "$(dirname "$0")/analysis.sh" "$i"
  # bash "$(dirname "$0")/clusters_processing.sh" "$i"
  # bash "$(dirname "$0")/frealign.sh" "$i"
  # bash "$(dirname "$0")/poses_processing.sh" "$i"
done

echo "[INFO] Todos los entrenamientos completados."
