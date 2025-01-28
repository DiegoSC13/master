'Funcion que convierte de .cs a .pkl. No modifica los valores de las poses'
'Cae en desuso me parece, parse_pose ya esta haciendo esto...'

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
    return parser

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
    rot = np.array([x[RKEY] for x in data])

    # parse translations
    logger.info(f"Extracting translations from {TKEY}")
    trans = np.array([x[TKEY] for x in data])

    filename = args.input.split('/')[-1]
    filename, extention = os.path.splitext(filename)
    with open('pkl_files/' + filename + '.pkl', "wb") as f:
        pickle.dump((rot, trans), f)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    main(add_args(parser).parse_args())
