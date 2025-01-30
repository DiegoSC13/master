import argparse
import os
import pickle
import logging
import numpy as np
import torch
from cryodrgn import lie_tools
import random

logger = logging.getLogger(__name__)

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
    # for i in range(len(data.dtype)):
    #     print(i, data.dtype.names[i], data[0][i])

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

    # parse indexes
    logger.info(f"Extracting indexs from {IDXKEY}")
    idx = np.array([x[IDXKEY] for x in data])

    return rot, trans, corr, idx

def process_and_save_data(cs_file, pkl_file, remove_cs = False):
    """
    Lee un archivo .cs, procesa los datos y los guarda en un archivo .pkl.
    
    Args:
        cs_file (str): Nombre del archivo .cs a leer.
        pkl_file (str): Nombre del archivo .pkl donde se guardará la información.
    """
    # Simulación de lectura de datos desde el archivo .cs
    data = np.load(cs_file)
    # view the first row
    # for i in range(len(data.dtype)):
    #     print(i, data.dtype.names[i], data[0][i])

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

    # parse indexes
    logger.info(f"Extracting indexs from {IDXKEY}")
    idx = np.array([x[IDXKEY] for x in data])
    
    # Guardar los datos en un archivo .pkl
    with open(pkl_file, 'wb') as file:
        pickle.dump({'rot': rot, 'trans': trans, 'corr': corr, 'idx': idx}, file)
    
    # Borrar el archivo .cs después de leerlo
    if remove_cs == True:
        os.remove(cs_file)
        print(f"Archivo {cs_file} eliminado y datos guardados en {pkl_file}.")
    
    return

def read_pkl(pkl_path):
    """
    Lee un archivo .pkl y devuelve el contenido de cada array.
    Input: pkl_file (str): Path del archivo .pkl a leer.
    Output: Arreglo de rotaciones, traslaciones, correlaciones cruzadas de poses e índices
    Ejemplo de uso: rot, trans, corr, idx = read_pkl(cs_dir.split('.')[0] + '.pkl') #cs_dir tiene el directorio .cs, por eso se cambia la extensión a pkl
    """
    with open(pkl_path, 'rb') as file:
        data = pickle.load(file)
    
    # Acceso a los arrays
    rot = data['rot']
    trans = data['trans']
    corr = data['corr']
    idx = data['idx']

    return rot, trans, corr, idx

