import os
import pickle
import argparse

def combinar_pars_con_indices_originales(directorio_pars, archivo_pkl, archivo_salida, archivo_backup_par):
    print(f"\n[INFO] Cargando etiquetas desde: {archivo_pkl}")
    with open(archivo_pkl, 'rb') as f:
        particulas = pickle.load(f)

    etiquetas_validas = sorted(set(p for p in particulas if p != -1))
    print(f"[INFO] Etiquetas detectadas (excluyendo -1): {etiquetas_validas}")

    archivos_par = sorted([
        os.path.join(directorio_pars, f)
        for f in os.listdir(directorio_pars)
        if f.endswith("_cropped_index_restored.par")
    ])
    print(f"[INFO] Archivos .par encontrados: {len(archivos_par)}")
    if len(archivos_par) < len(etiquetas_validas):
        raise ValueError("Hay menos archivos .par que etiquetas distintas en el .pkl")

    datos_por_etiqueta = {}
    for etiqueta, path in zip(etiquetas_validas, archivos_par):
        print(f"[INFO] Asociando etiqueta {etiqueta} con archivo: {os.path.basename(path)}")
        with open(path, 'r') as f:
            lineas = f.readlines()

        header = []
        datos = []
        for linea in lineas:
            if linea.strip() == '' or linea.strip().startswith('C'):
                header.append(linea)
            else:
                datos.append(linea)
        datos_por_etiqueta[etiqueta] = (header, datos)

    header_final = next(iter(datos_por_etiqueta.values()))[0]
    if len(header_final) >= 3:
        segunda = header_final.pop(1)
        tercera = header_final.pop(1)
        lineas_extra = [segunda, tercera]
    else:
        lineas_extra = []

    with open(archivo_backup_par, 'r') as f:
        lineas_backup = f.readlines()
    datos_backup = [l for l in lineas_backup if l.strip() and not l.strip().startswith('C')]
    print(f"[INFO] Partículas disponibles en el backup: {len(datos_backup)}")

    contadores = {etiqueta: 0 for etiqueta in etiquetas_validas}
    nuevas_lineas = []

    for i, etiqueta in enumerate(particulas):
        #print(f"[DEBUG] Partícula {i} → Etiqueta: {etiqueta}")
        if etiqueta == -1:
            if i >= len(datos_backup):
                raise IndexError(f"Índice {i} excede el backup")
            #print("[INFO] → Tomando del backup")
            nuevas_lineas.append(datos_backup[i])
        else:
            if etiqueta not in datos_por_etiqueta:
                raise ValueError(f"No hay archivo .par cargado para etiqueta {etiqueta}")
            _, datos = datos_por_etiqueta[etiqueta]
            idx_local = contadores[etiqueta]
            if idx_local >= len(datos):
                raise IndexError(f"No hay suficientes partículas en el archivo de la etiqueta {etiqueta}")
            #print(f"[INFO] → Tomando partícula {idx_local} del archivo de etiqueta {etiqueta}")
            nuevas_lineas.append(datos[idx_local])
            contadores[etiqueta] += 1

    print(f"\n[INFO] Total de partículas escritas: {len(nuevas_lineas)}")
    print(f"[INFO] Escribiendo archivo final: {archivo_salida}")
    with open(archivo_salida, 'w') as f:
        f.writelines(header_final)
        f.writelines(nuevas_lineas)
        f.writelines(lineas_extra)
    print("[INFO] ¡Archivo combinado generado con éxito!")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Combinar archivos .par según índices originales.')
    parser.add_argument('--input_dir', required=True, help='Directorio con los archivos .par por etiqueta')
    parser.add_argument('--labels_pkl', required=True, help='Archivo .pkl con los índices por partícula')
    parser.add_argument('--output_par', required=True, help='Archivo de salida combinado')
    parser.add_argument('--backup_par', required=True, help='Archivo .par de backup (referencia)')

    args = parser.parse_args()

    combinar_pars_con_indices_originales(
        directorio_pars=args.input_dir,
        archivo_pkl=args.labels_pkl,
        archivo_salida=args.output_par,
        archivo_backup_par=args.backup_par
    )
