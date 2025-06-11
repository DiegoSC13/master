#!/bin/bash

# Activación del entorno
source /nfs/bartesaghilab2/ds672/anaconda3/etc/profile.d/conda.sh
conda activate cryodrgn

# Fecha y hora
DATE="$(date +%Y_%m_%d_%H_%M_%S)"

# Paths base
DS_DIR="/nfs/bartesaghilab2/ds672"
WORK_DIR="${DS_DIR}/empiar10076"

# CryoDRGN inputs
#PARTICLES_DIR="${WORK_DIR}/empiar_data/L17Combine_weight_local.mrc"
PARTICLES_DIR="${DS_DIR}/master/delete_me/example_1000/particles_example_1000.mrc"
CTF_DIR="${DS_DIR}/master/delete_me/example_1000/ctf_1000.pkl"
POSES_DIR="${DS_DIR}/master/delete_me/example_1000/poses_1000.pkl"
INDEXES_DIR="${DS_DIR}/master/delete_me/example_1000/particles_example_1000.pkl"
#BASE_TRAIN=""

# CryoDRGN parameters
ENC_DIM=256
ENC_LAYERS=3
DEC_DIM=256 
DEC_LAYERS=3 
ZDIM=8
DOWNSAMPLING=128
N_EPOCHS=1
ALPHA=1
NUM_ITER=2

# Analysis parameters
APIX=1.31
NUM_CLUSTERS=2
PIXEL_SIZE=3.275
IMAGE_SIZE=128

# Frealign paths
PYP_DIR="${DS_DIR}/nextpyp"
SIF_DIR="${PYP_DIR}/pyp.sif"
FREALIGNX_DIR="/opt/pyp/ext/frealignx"
