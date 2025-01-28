import mrcfile
import os

#SIN PROBAR, ELIMINAR SI OTRA COSA FUNCIONA

def split_mrcs(input_file, output_folder):
    # Abrir el archivo .mrcs
    with mrcfile.open(input_file, permissive=True) as mrc:
        data = mrc.data  # Cargar las partículas como un array
        num_particles = data.shape[0]  # Número de partículas en el stack

        print(f"El archivo contiene {num_particles} partículas.")

        # Crear el directorio de salida si no existe
        os.makedirs(output_folder, exist_ok=True)

        # Guardar cada partícula en un archivo separado
        for i in range(num_particles):
            output_file = os.path.join(output_folder, f"particle_{i+1:04d}.mrc")
            with mrcfile.new(output_file, overwrite=True) as output_mrc:
                output_mrc.set_data(data[i])
            
            print(f"Partícula {i+1} guardada en {output_file}")