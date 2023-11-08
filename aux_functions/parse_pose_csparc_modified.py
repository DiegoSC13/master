"""Parse image poses from a cryoSPARC .cs metafile
    Esta es la funcion de cryoDRGN para generar un poses.pkl, la salida de esta funcion tiene transformaciones en las poses"""

import argparse
import os
import pickle
import logging
import numpy as np
import torch
from cryodrgn import lie_tools
import random

logger = logging.getLogger(__name__)


def add_args(parser):
    parser.add_argument("input", help="Cryosparc .cs file")
    parser.add_argument(
        "-Vr", type=int, default=0, help="""Variation in rotation with range Vr, poses will be modify by an 
                                            additive random value between [-Vr,Vr], uniform distribution"""
    )
    parser.add_argument(
        "-Vt", type=int, default=0, help="""Variation in translation with range Vt, poses will be modify by an 
                                            additive random value between [-Vt,Vt], uniform distribution"""
    )
    parser.add_argument(
        "-D", type=int, default=320, help="Box size of reconstruction (pixels)"
    )
    parser.add_argument(
        "-drgn", type=bool, default=True, help="Apply pose transformation for cryoDRGN"
    )
    return parser

def modified_pose(dim_a, dim_b, num_pixels):
    matrix = []
    for _ in range(dim_a):
        row = [random.randint(-num_pixels, num_pixels) for _ in range(dim_b)]
        matrix.append(row)
    return np.array(matrix)

def main(args):
    assert args.input.endswith(".cs"), "Input format must be .cs file"

    data = np.load(args.input)
    # view the first row
    for i in range(len(data.dtype)):
        print(i, data.dtype.names[i], data[0][i])

    RKEY = "alignments3D/pose"
    TKEY = "alignments3D/shift"

    # parse rotations
    logger.info(f"Extracting rotations from {RKEY}")
    rot_orig = np.array([x[RKEY] for x in data])

    # parse translations
    logger.info(f"Extracting translations from {TKEY}")
    trans_orig = np.array([x[TKEY] for x in data])

    logger.info(f"Writing {args.input.split('.')[0]}.pkl")
    with open(args.input.split('.')[0] + '.pkl', "wb") as f:
        pickle.dump((rot_orig, trans_orig), f)

    if args.Vr != 0 or args.Vt != 0:
        dim_rows = trans_orig.shape[0]
        dim_columns_r = rot_orig.shape[1] #3
        dim_columns_t = trans_orig.shape[1] #2

        variations_vector_rot = modified_pose(dim_rows, dim_columns_r, args.Vr)
        variations_vector_trans = modified_pose(dim_rows, dim_columns_t, args.Vt)
        if args.Vr != 0:
            np.save(args.input.split('.')[0] + '_' + str(args.Vr) + 'rot.npy', variations_vector_rot)
        if args.Vt != 0:
            np.save(args.input.split('.')[0] + '_' + str(args.Vt) + 'trans.npy', variations_vector_trans)
        
        rot = rot_orig + variations_vector_rot
        trans = trans_orig + variations_vector_trans

        logger.info(f"Writing {args.input.split('.')[0]}_pm.pkl")
        with open(args.input.split('.')[0] + '_' + str(args.Vr) + 'rot_' + str(args.Vt) + 'trans.pkl', "wb") as f:
            pickle.dump((rot, trans), f)
    
    else:
        rot = rot_orig
        trans = trans_orig

    if args.drgn == True:
        #Converting Euler Angles in rotation matrix for cryoDRGN
        rot = torch.tensor(rot_orig)
        rot = lie_tools.expmap(rot)
        rot = rot.cpu().numpy()
        logger.info("Transposing rotation matrix")
        rot = np.array([x.T for x in rot])
        logger.info(rot.shape)

        # convert translations from pixels to fraction
        trans /= args.D

        # write output
        logger.info(f"Writing {args.input.split('.')[0]}_drgn")
        with open(args.input.split('.')[0] + '_' + str(args.Vr) + 'rot_' + str(args.Vt) + 'trans_drgn.pkl', "wb") as f:
            pickle.dump((rot, trans), f)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    main(add_args(parser).parse_args())
