import argparse

def comparar_byte_a_byte(path1, path2):
    with open(path1, 'rb') as f1, open(path2, 'rb') as f2:
        return f1.read() == f2.read()

def comparar_linea_por_linea(path1, path2):
    with open(path1, 'r') as f1, open(path2, 'r') as f2:
        for linea1, linea2 in zip(f1, f2):
            if linea1 != linea2:
                return False
        # Verificar que ambos archivos hayan terminado
        return f1.readline() == '' and f2.readline() == ''

def main():
    parser = argparse.ArgumentParser(
        description='Compara dos archivos .par y verifica si son iguales.'
    )
    parser.add_argument('file1', help='Primer archivo .par')
    parser.add_argument('file2', help='Segundo archivo .par')

    args = parser.parse_args()

    resultado_bytes = comparar_byte_a_byte(args.file1, args.file2)
    resultado_lineas = comparar_linea_por_linea(args.file1, args.file2)

    print(f"Comparación byte a byte: {'IGUALES' if resultado_bytes else 'DIFERENTES'}")
    print(f"Comparación línea por línea: {'IGUALES' if resultado_lineas else 'DIFERENTES'}")

if __name__ == '__main__':
    main()
