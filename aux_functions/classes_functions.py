import numpy as np
import pickle
import os
import shutil
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

def select_rows_star(input_path, output_path, indexes):
    '''
    Función que crea archivos .star a partir del .star original y una lista con los índices de las partículas a utilizar
    Input: Path al .star original, Path para guardar el .star de salida e índices de partículas a utilizar
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
    metadata  = lines[:13] #13 lineas de metadata antes de ir particula por particula
    # Extraer solo las líneas con los índices especificados
    selected_lines = [line for i, line in enumerate(lines) if i in indexes] 
    #selected_lines_ = [x + const_ for x in selected_lines]
    final_lines = metadata + selected_lines
    with open(output_path, 'w') as f: #Si ya había otro archivo con el mismo nombre lo sobreescribe
        f.writelines(final_lines)
    return