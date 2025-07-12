#!/bin/bash

# Activación del entorno
source /nfs/bartesaghilab2/ds672/anaconda3/etc/profile.d/conda.sh
conda activate cryodrgn

# Paths base
DS_DIR="/nfs/bartesaghilab2/ds672"
WORK_DIR="${DS_DIR}/empiar10180"

# CryoDRGN inputs
PARTICLES_DIR="${WORK_DIR}/data/particles.orig.imod_stack.mrcs"
CTF_DIR="${WORK_DIR}/inputs/ctf.pkl"
INDEXES_DIR="${WORK_DIR}/inputs/filtered.ind.pkl"
# PARTICLES_DIR="${DS_DIR}/master/delete_me/example_1000/particles_example_1000.mrc"
# CTF_DIR="${DS_DIR}/master/delete_me/example_1000/ctf_1000.pkl"
# POSES_DIR="${DS_DIR}/master/delete_me/example_1000/poses_1000.pkl"
#INDEXES_DIR="${DS_DIR}/master/delete_me/example_1000/particles_example_1000.pkl"

#BASE_TRAIN=""

# CryoDRGN parameters
ENC_DIM=1024
ENC_LAYERS=3
DEC_DIM=1024
DEC_LAYERS=3 
ZDIM=8
DOWNSAMPLING=320
N_EPOCHS=40
#Iteration parameters
ALPHA=5
NUM_ITER=5

# Analysis parameters
APIX=1.699
#NUM_CLUSTERS=5
PIXEL_SIZE=1.699
IMAGE_SIZE=320

# Frealign paths
PYP_DIR="${DS_DIR}/nextpyp"
SIF_DIR="${PYP_DIR}/pyp.sif"
FREALIGNX_DIR="/opt/pyp/ext/frealignx"
