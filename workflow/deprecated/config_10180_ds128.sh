#!/bin/bash

# Activación del entorno
source /nfs/bartesaghilab2/ds672/anaconda3/etc/profile.d/conda.sh
conda activate cryodrgn

# Paths base
DS_DIR="/nfs/bartesaghilab2/ds672"
WORK_DIR="${DS_DIR}/empiar10180"

# CryoDRGN inputs
PARTICLES_DIR="${WORK_DIR}/downsampled_data/particles.128.mrcs"
#FILTERED_PARTICLES_DIR="${WORK_DIR}/inputs/initial_hidden_variables/filtered_particles/filtered_particles.128.mrcs"
CTF_DIR="${WORK_DIR}/inputs/ctf.pkl"
#FILTERED_CTF_DIR="${WORK_DIR}/inputs/initial_hidden_variables/filtered_particles/ctf_iter0_i_filtered.pkl"
INDEXES_DIR="${WORK_DIR}/inputs/filtered.ind.pkl"
# PARTICLES_DIR="${DS_DIR}/master/delete_me/example_1000/particles_example_1000.mrc"
# CTF_DIR="${DS_DIR}/master/delete_me/example_1000/ctf_1000.pkl"
# POSES_DIR="${DS_DIR}/master/delete_me/example_1000/poses_1000.pkl"
#INDEXES_DIR="${DS_DIR}/master/delete_me/example_1000/particles_example_1000.pkl"

#BASE_TRAIN=""

# CryoDRGN parameters
ENC_DIM=256
ENC_LAYERS=3
DEC_DIM=256
DEC_LAYERS=3 
ZDIM=8
DOWNSAMPLING=128
N_EPOCHS=40
#Iteration parameters
ALPHA=5
NUM_ITER=10

# Analysis parameters
APIX=4,2475
NUM_CLUSTERS=6
PIXEL_SIZE=1.699 #parse_pose_star
IMAGE_SIZE=320

# Frealign paths
PYP_DIR="${DS_DIR}/nextpyp"
SIF_DIR="${PYP_DIR}/pyp.sif"
FREALIGNX_DIR="/opt/pyp/ext/frealignx"
