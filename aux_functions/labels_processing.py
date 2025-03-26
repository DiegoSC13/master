import numpy as np
import pickle
import os
import shutil
import argparse
from collections import defaultdict

def labels_per_classes(labels_path, output_path):
    '''
    Recibe salida labels.pkl de cryoDRGN y separa índices de partículas por clases
    Input: Path de labels.pkl, path donde crea carpeta particles_per_classes
    Output: K archivos particles_class_X en output_path
    Ejemplo de uso: labels_per_classes('./labels.pkl','./particles_per_classes')
    '''
    with open(labels_path, 'rb') as file:
        labels = pickle.load(file)
    N = len(labels)
    indexes = np.arange(1, N+1, 1, dtype=int)

    particle_per_class = defaultdict(list)

    for index, label in zip(indexes, labels):
        particle_per_class[label].append(index)  

    for class_, list_ in particle_per_class.items():
        globals()[f"particles_class_{class_}"] = list_

    particles_per_classes = [particle_per_class[k] for k in sorted(particle_per_class.keys())]

    sum_len_classes = sum(len(clase) for clase in particles_per_classes)
    # print(sum_len_classes)
    assert sum_len_classes == N, f'La suma de partículas por clase es distinta a {N}'

    if os.path.exists(output_path):
        shutil.rmtree(output_path)
    # Creamos el directorio
    os.makedirs(output_path)
    for class_, list_ in particle_per_class.items():
        with open(output_path + f"/particles_class_{class_}.pkl", "wb") as file:
            pickle.dump(list_, file)
    return

def select_rows_star(input_path, output_path, indexes, metadata_row_num=13):
    '''
    Función que crea archivos .star a partir del .star original y una lista con los índices de las partículas a utilizar
    Input: Path al .star original, Path para guardar el .star de salida, índices de partículas a utilizar y número de filas de la metadata
    Output: Archivo .star solo con las partículas a utilizar
    Ejemplo de uso:
    with open('./particles_per_classes/particles_class_4.pkl', 'rb') as file:
        particles_0 = pickle.load(file)
    particles_0 = [x + 12 for x in particles_0] #Desplazamiento por líneas de metadata
    select_rows_star('Parameters.star', 'Cluster4_Parameters.star', particles_0)
    OJO: Si cambia la cantidad de líneas que ocupa la metadata, cambia la función
    '''
    with open(input_path, 'r') as f:
        lines = f.readlines()
    metadata  = lines[:metadata_row_num] #13 lineas de metadata (EMPIAR-10076) antes de ir particula por particula
    # Extraer solo las líneas con los índices especificados
    selected_lines = [line for i, line in enumerate(lines) if i in indexes] 
    #selected_lines_ = [x + const_ for x in selected_lines]
    final_lines = metadata + selected_lines
    with open(output_path, 'w') as f: #Si ya había otro archivo con el mismo nombre lo sobreescribe
        f.writelines(final_lines)
    return

def labels_processing(labels_pkl_path, particles_per_label_folder, output_folder, starfile_path, iter, metadata_row_num=13):
    '''
    Entrada:
    Path al archivo pkl, Path a guardar pkl's con índices por clase, path a guardar .star por clase,
    path a .star original, número de iteración
    
    Salida:
    Directorio con archivos .star por clase. 
    Esos .star son entrada de Refinement por clase en CryoSPARC
    
    Ejemplo de uso:
    labels_pkl_path = '../labels_output_2025_02_05_z8_ds128_iter2.pkl'
    particles_per_labels_folder = '../processed_labels_output_2025_02_05_z8_ds128_iter2'
    output_folder = '../testing_labels_processing'
    starfile_path = '../files/labels/iter0/Parameters.star'
    iter = 0

    labels_processing(labels_pkl_path, particles_per_labels_folder, output_folder, starfile_path, iter)
    '''
    
    labels_per_classes(labels_pkl_path,particles_per_label_folder) #Change depending on iteration
    # Reemplazar output_folder si ya existe
    if os.path.exists(output_folder):
        shutil.rmtree(output_folder)
    os.makedirs(output_folder)

    # Crear el archivo de log en output_folder
    log_file_path = os.path.join(output_folder, "labels_processing.txt")
    with open(log_file_path, "w") as log_file:
        log_file.write(f"Path to pkl file with labels (output of CryoDRGN): {labels_pkl_path}\n")
        log_file.write(f"Path to particles per label: {labels_pkl_path}\n")
        log_file.write(f"Path to .star files per label: {output_folder}\n")
        log_file.write(f"Path to original .star file: {starfile_path}\n")
        log_file.write(f"Iteration number: {iter}\n")
    cont = 0
    files = os.listdir(particles_per_label_folder) 
    files = sorted(files)
    for file in files:
        print(file)
        file_path = os.path.join(particles_per_label_folder, file)  # Corrección del path
        with open(file_path, 'rb') as label_file:
            particles = pickle.load(label_file)
            particles = [x + metadata_row_num - 1  for x in particles] #Antes metadata_row_num=13 siempre y acá había un 12
        output_starfile = os.path.join(output_folder, f'Cluster{cont}_iter{iter}_.star')
        select_rows_star(starfile_path, output_starfile, particles, metadata_row_num)
        cont += 1
    return

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Procesa archivos de etiquetas y genera archivos .star.")
    parser.add_argument("labels_pkl_path", help="Path al .pkl con labels (salida de CryoDRGN)")
    parser.add_argument("particles_per_label_folder", help="Path a guardar pkl's con índices por clase")
    parser.add_argument("output_folder", help="Ruta de la carpeta donde se guardarán los resultados.")
    parser.add_argument("starfile_path", help="Ruta del archivo .star base.")
    parser.add_argument("iter", type=int, help="Número de iteración.")
    group = parser.add_argument_group("Extra arguments")
    group.add_argument(
        "metadata_row_num",
        type=int,
        default=13,
        help="Cantidad de líneas de metadata antes de las partículas",
    )
    args = parser.parse_args()

    labels_processing(args.labels_pkl_path, 
                      args.particles_per_label_folder, 
                      args.output_folder, 
                      args.starfile_path, 
                      args.iter,
                      args.metadata_row_num)