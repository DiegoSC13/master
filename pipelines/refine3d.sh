#!/bin/bash

set -e
set -o pipefail

# Ruta base
PYP_DIR="/nfs/bartesaghilab2/ds672/nextpyp"
SIF="${PYP_DIR}/pyp.sif"
INPUT_FILE="/nfs/bartesaghilab2/ds672/master/pipelines/empiar10076.txt"

singularity exec -B /hpc -B /nfs "$SIF" bash -c "
  cd /opt/pyp/external/frealignx && \
  ./refine3d < $INPUT_FILE
"
