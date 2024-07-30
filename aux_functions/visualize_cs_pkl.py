"""Functions to visualize information from  cryoSPARC output (.cs file) 
   and .pkl files"""

import os
import pickle
import logging
import numpy as np
import torch
from cryodrgn import lie_tools
import random

def read_pkl(pkl_path):
    '''
    Guardo el contenido del archivo .pkl en la variable de salida
    '''
    with open(pkl_path, 'rb') as file:
        data = pickle.load(file)
    return data

