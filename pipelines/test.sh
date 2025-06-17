#!/bin/bash

# Si no se pasa un argumento, crea un archivo por defecto
if [ -z "$1" ]; then
  echo "[INFO] No se proporcionó un archivo de entrada. Generando 'default_input.txt'..."
  INPUT_FILE="default_input.txt"
  
  # Aquí generas el contenido del archivo (puedes personalizar esto)
  echo "Este es un archivo de entrada generado automáticamente." > "$INPUT_FILE"
else
  INPUT_FILE="$1"
fi

echo "[INFO] Usando archivo de entrada: $INPUT_FILE"

# Aquí continúa el resto de tu script usando $INPUT_FILE