"""Parse image poses from a cryoSPARC .cs metafile"""

import argparse
import os
import pickle
import logging
import numpy as np
import torch
from cryodrgn import lie_tools
import random
import h5py

logger = logging.getLogger(__name__)


def add_args(parser):
    parser.add_argument("input", help="Cryosparc .cs file")
    parser.add_argument(
        "--abinit",
        action="store_true",
        help="Flag if results are from ab-initio reconstruction",
    )
    parser.add_argument(
        "--hetrefine",
        action="store_true",
        help="Flag if results are from a heterogeneous refinements (default: homogeneous refinement)",
    )
    parser.add_argument(
        "-D", type=int, required=True, help="Box size of reconstruction (pixels)"
    )
    # parser.add_argument(
    #     "-o", metavar="PKL", type=os.path.abspath, required=True, help="Output pose.pkl"
    # )
    return parser

#EDIT Diego
def modified_pose(dim_a, dim_b, num_pixels):
    matrix = []
    for _ in range(dim_a):
        row = [random.randint(-num_pixels, num_pixels) for _ in range(dim_b)]
        matrix.append(row)
    return np.array(matrix)

def main(args):
    assert args.input.endswith(".cs"), "Input format must be .cs file"
    # assert args.o.endswith(".pkl"), "Output format must be .pkl"

    data = np.load(args.input)
    # view the first row
    for i in range(len(data.dtype)):
        print(i, data.dtype.names[i], data[0][i])

    if args.abinit:
        RKEY = "alignments_class_0/pose"
        TKEY = "alignments_class_0/shift"
    else:
        RKEY = "alignments3D/pose"
        TKEY = "alignments3D/shift"

    # parse rotations
    logger.info(f"Extracting rotations from {RKEY}")
    rot = np.array([x[RKEY] for x in data])
    print('rot:')
    print(rot)

    # parse translations
    logger.info(f"Extracting translations from {TKEY}")
    trans = np.array([x[TKEY] for x in data])
    print('trans: ')
    print(trans)
    dim_rows = trans.shape[0]
    dim_columns = trans.shape[1]
    variation = 20
    variations_vector_trans = modified_pose(dim_rows, dim_columns, variation)
    #np.save('uniform_' + str(variation) + '_pixels_variation_modified_cs.npy', variations_vector_trans)
    trans = trans + variations_vector_trans

    # with h5py.File(args.input, "r+") as f:
    #     f['/alignments3D/shift'][:] = trans
    for i in range(len(data)):
        data[i][TKEY] = trans[i]

    new_cs_filename = args.input.replace('.cs', '_' + str(variation) + '_pixels_variation')
    new_cs_full_filename = new_cs_filename + '.npy'
    np.save(new_cs_filename, data)
    os.rename(new_cs_full_filename, new_cs_full_filename.replace(".npy", ".cs"))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    main(add_args(parser).parse_args())