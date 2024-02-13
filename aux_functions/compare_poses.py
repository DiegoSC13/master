"""Functions to extract information from  cryoSPARC output (.cs file) 
   and preprocess it for cryoDRGN"""

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
        "-N", type=int, required=True, help="Number of particles"
    )
    # parser.add_argument(
    #     "-Vt", type=int, default=0, help="""Variation in translation with range Vt, poses will be modify by an 
    #                                         additive random value between [-Vt,Vt], uniform distribution"""
    # )
    # parser.add_argument(
    #     "-D", type=int, default=320, help="Box size of reconstruction (pixels)"
    # )
    # parser.add_argument(
    #     "-drgn", type=bool, default=True, help="Apply pose transformation for cryoDRGN"
    # )
    return parser

def extract_info_from_cs(cs_file):
    ''''
    INPUT: .cs file from cryoSPARC
    OUTPUT: Rotation arrays, translation arrays, cross_correlation arrays and indexes arrays
    COMMENT: Extraigo la información relevante para el procesamiento de las poses. Necesito rotaciones y 
    traslaciones para cryoDRGN, la correlación y los índices son para comparar los K vectores de poses de 
    cada partícula y evaluar cuál es el mejor.
    '''
    data = np.load(cs_file)
    # view the first row
    for i in range(len(data.dtype)):
        print(i, data.dtype.names[i], data[0][i])

    RKEY = "alignments3D/pose"
    TKEY = "alignments3D/shift"
    CORRKEY = "alignments3D/cross_cor"
    IDXKEY = "blob/idx"

    # parse rotations
    logger.info(f"Extracting rotations from {RKEY}")
    rot = np.array([x[RKEY] for x in data])

    # parse translations
    logger.info(f"Extracting translations from {TKEY}")
    trans = np.array([x[TKEY] for x in data])

    # parse cross_correlations
    logger.info(f"Extracting cross_correlations from {CORRKEY}")
    corr = np.array([x[CORRKEY] for x in data])

    # parse cross_correlations
    logger.info(f"Extracting indexs from {IDXKEY}")
    idx = np.array([x[IDXKEY] for x in data])

    return rot, trans, corr, idx

def relation_idx_corr(N, idxs, corrs):
    ''''
    INPUT: Num of particles, 
    OUTPUT:
    COMMENT:
    '''

    sublist = [(idx_tot, corr_tot) for idx_tot, corr_tot in zip(idxs, corrs)]

    # Inicializar la lista final con listas vacías
    final_list = [[] for _ in range(N)]

    # Recorrer las sublistas
    for positions, values in sublist:
        # Asignar los valores a las posiciones correspondientes en la lista final
        for i, value in zip(positions, values):
            final_list[i].append(value)

    return final_list

def max_per_list(lists):
    ''''
    INPUT: Num of particles, 
    OUTPUT:
    COMMENT:
    '''
    # Usa la función map con max para obtener el máximo en cada lista
    maxs = list(map(max, lists))
    return maxs

def empty_or_filled_lists(lista_de_listas):
    ''''
    INPUT: Num of particles, 
    OUTPUT:
    COMMENT:
    '''
    empty_positions = []
    filled_positions = []

    for i, sublista in enumerate(lista_de_listas):
        if not sublista:
            empty_positions.append(i)
        else:
            filled_positions.append(i)

    return empty_positions, filled_positions

def main(args):
    #assert args.input.endswith(".cs"), "Input format must be .cs file"
    files = os.listdir(args.input)
    rots = []
    trans = []
    idxs = []
    corrs = []
    for file in files:
        rot, tran, corr, idx = extract_info_from_cs(os.path.join(args.input, file))
        #sublist = [idx, corr]
        #sublist = list(zip(idx, corr))
        rots.append(rot)
        trans.append(tran)
        idxs.append(idx)
        corrs.append(corr)


    sublist = [(idx_tot, corr_tot) for idx_tot, corr_tot in zip(idxs, corrs)]
    final_list = relation_idx_corr(args.N, sublist)
    print(len(idxs))
    empty_lists_idx, filled_lists_idx = empty_or_filled_lists(final_list)

    #Save particles idx for cryoDRGN training
    with open('filtered_particles_' + args.input + '.pkl', "wb") as f:
        pickle.dump(filled_lists_idx, f)

    if empty_lists_idx:
        print("Listas vacías encontradas en las posiciones:", empty_lists_idx)
    else:
        print("No se encontraron listas vacías.")
    print(final_list[3])
    # output_list = max_per_list(final_list)
    # print(output_list[0:3])



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    main(add_args(parser).parse_args())