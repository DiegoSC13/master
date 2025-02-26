import argparse
import os
import pickle
import logging
import numpy as np
import torch
from cryodrgn import lie_tools
import time
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
    print(f'{pkl_file=}')
    with open(pkl_file, 'wb') as file:
        pickle.dump({'rot': rot, 'trans': trans, 'corr': corr, 'idx': idx}, file)
    
    # Borrar el archivo .cs después de leerlo
    if remove_cs == True:
        os.remove(cs_file)
        print(f"Archivo {cs_file} eliminado y datos guardados en {pkl_file}.")
    
    return

def read_rtci_pkl(pkl_path):
    """
    Lee un archivo .pkl y devuelve el contenido de cada array. rtci: Rot, Trans, Corr, Idx
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

def poses_for_cryodrgn(rott, transs, output_path = None, D = 320):
    rot_iteration_n_np = np.array(rott)
    tran_iteration_n_np = np.array(transs)

    #Converting Euler Angles in rotation matrix for cryoDRGN
    rot = torch.tensor(rot_iteration_n_np)
    rot = lie_tools.expmap(rot)
    rot = rot.cpu().numpy()
    logger.info("Transposing rotation matrix")
    rot = np.array([x.T for x in rot])
    logger.info(rot.shape)

    # convert translations from pixels to fraction
    trans = tran_iteration_n_np/D

    if output_path != None:
        with open(output_path, "wb") as f:
            pickle.dump((rot, trans), f)

    return rot, trans

def poses_processing(poses_dir, labels_dir, output_dir):
    '''
    Bloque de procesamiento de poses completo. Recibe K vectores de poses y los junta siguiendo el orden de los índices
    de cada partícula

    Inputs:
    poses_dir: Nombre del directorio con las poses
    labels_dir: Nombre del directorio con los .pkl's. Es el particles_per_label_folder de labels_processing
    output_txt: Log con toda la información relevante del llamado a la función

    Ejemplo de uso:
    python poses_functions.py ../../empiar10076/inputs/pipeline_february/refinements_by_classes/ ../../empiar10076/experiments/2025_02_10_z8_ds128_iter0/analyze.49/kmeans5_umap/particles_per_label/ ../../empiar10076/experiments/2025_02_10_z8_ds128_iter0/analyze.49/kmeans5_umap/processed_poses    
    '''
    start = time.time()
    os.makedirs(output_dir, exist_ok=True)
    output_txt = os.path.join(output_dir, 'poses_processing.txt')
    
    files = sorted(os.listdir(poses_dir))
    print(files)

    # Defino listas para guardar K vectores en cada una
    rots, trans, idxs, corrs = [], [], [], []
    # Escribo info relevante en logfile
    with open(output_txt, "w") as log_file:
        log_file.write(f"Processing poses from: {poses_dir}\n")
        log_file.write(f"Processed labels used: {labels_dir}\n\n")
        log_file.write("Pose files found:\n")
        log_file.writelines([f"{file}\n" for file in files])
        log_file.write("\n")
    end = time.time()
    print(f'Tiempo de ejecución de primeras líneas: {end-start:.3f} segundos \n')
    
    start = time.time()
    for file in files:
        if file.endswith('.cs'):
            # Extraigo info relevante del .cs
            rot, tran, corr, idx = extract_info_from_cs(os.path.join(poses_dir, file))
            # Agrego esta información a listas que van a tener K elementos
            rots.append(rot), trans.append(tran), idxs.append(idx), corrs.append(corr)
            # Armo output_dir
            cs_dir = os.path.join(poses_dir, file)
            # Guardo información relevante del .cs en un .pkl con el mismo nombre
            process_and_save_data(cs_dir, os.path.dirname(cs_dir) + '.pkl')
    end = time.time()
    print(f'Tiempo de ejecución de for que lee y procesa .cs y guarda .pkl: {end - start:.3f} segundos')
    #labels_dir es el particles_per_label_folder de labels_processing
    labels_files = sorted(os.listdir(labels_dir))
    # classes es una lista con K elementos, cada uno tiene los índices de una clase
    # Básicamente lee y guarda el contenido de cada .pkl
    classes = []
    with open(output_txt, "a") as log_file:
        log_file.write("Label files found:\n")
        log_file.writelines([f"{file}\n" for file in labels_files])
        log_file.write("\n")
    start = time.time()
    for file in labels_files:
        file_path = os.path.join(labels_dir, file)
        with open(file_path, 'rb') as file_:
            class_per_label = pickle.load(file_)
            classes.append(class_per_label)
    end = time.time()
    print(f'Tiempo de ejecución de for que carga .pkls: {end-start:.3f} segundos')
    #Bloque que construye un solo vector de rotaciones y traslaciones a partir de los K vectores
    rotations_dict = {}
    translations_dict = {}
    start = time.time()
    for i, indexes in enumerate(classes):
        for j, idx in enumerate(indexes):
            rotations_dict[idx] = rots[i][j]
            translations_dict[idx] = trans[i][j]
    
    sorted_indexes = sorted(rotations_dict.keys())
    sorted_rots = [rotations_dict[idx] for idx in sorted_indexes]
    sorted_trans = [translations_dict[idx] for idx in sorted_indexes]
    end = time.time()
    print(f'Tiempo de ejecución de fors anidados: {end-start:.3f} segundos')
    output_pkl_pre_cryodrgn = os.path.join(output_dir, 'poses_without_cryodrgn_processing.pkl')
    with open(output_pkl_pre_cryodrgn, "wb") as f:
        pickle.dump((sorted_rots, sorted_trans), f)
    
    output_pkl = os.path.join(output_dir, 'poses_processed.pkl')
    
    #Preprocesamiento de poses de cryoDRGN. Las poses para cryoDRGN se guarda dentro de esta función
    #Salida final
    poses_for_cryodrgn(sorted_rots, sorted_trans, output_pkl)
    
    with open(output_txt, "a") as log_file:
        log_file.write(f"Generated poses pickle: {output_pkl}\n")

    return
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Procesa archivos de poses y genera un log de información.")
    parser.add_argument("poses_dir", help="Directorio que contiene los archivos de poses (.cs)")
    parser.add_argument("labels_dir", help="Directorio que contiene los archivos de etiquetas (.pkl)")
    parser.add_argument("output_txt", help="Ruta del archivo de salida .txt con la información del procesamiento")
    
    args = parser.parse_args()
    poses_processing(args.poses_dir, args.labels_dir, args.output_txt)