def convert_star_to_par(star_path, par_path, mag_value=38168):
    import pandas as pd
    import re

    with open(star_path, 'r') as f:
        lines = f.readlines()

    # Buscar inicio de datos y encabezado
    header_lines = []
    data_start = 0
    for i, line in enumerate(lines):
        if line.startswith('_rln'):
            header_lines.append(line.strip())
        elif re.match(r'^\s*[\d\.\-]', line):  # empieza con número, datos reales
            data_start = i
            break

    # Crear mapeo nombre -> índice
    col_map = {}
    for line in header_lines:
        match = re.match(r'(_rln\w+)\s+#(\d+)', line)
        if match:
            name, idx = match.groups()
            col_map[int(idx) - 1] = name

    # Leer los datos como matriz (sin encabezados)
    data = pd.read_csv(star_path, delim_whitespace=True, skiprows=data_start, header=None)

    # Verificar que haya al menos 25 columnas
    if data.shape[1] < 25:
        raise ValueError("El archivo .star tiene menos de 25 columnas. ¿Estás seguro de que está completo?")

    # Asignar columnas necesarias (usando los índices conocidos)
    PSI    = data[19]   # _rlnAnglePsi #20
    PHI    = data[21]   # _rlnAngleRot #22
    THETA  = data[22]   # _rlnAngleTilt #23
    SHX    = -data[23]  # _rlnOriginX #24 (invertido)
    SHY    = -data[24]  # _rlnOriginY #25 (invertido)
    DF1    = data[5] / 10.0  # _rlnDefocusU #6
    DF2    = data[6] / 10.0  # _rlnDefocusV #7
    ANGAST = data[7]    # _rlnDefocusAngle #8
    PSHIFT = data[11]   # _rlnPhaseShift #12

    # Crear DataFrame final
    par_df = pd.DataFrame({
        'C': range(1, len(data)+1),
        'PSI': PSI,
        'THETA': THETA,
        'PHI': PHI,
        'SHX': SHX,
        'SHY': SHY,
        'MAG': mag_value,
        'INCLUDE': 1,
        'DF1': DF1,
        'DF2': DF2,
        'ANGAST': ANGAST,
        'PSHIFT': PSHIFT,
        'OCC': 100.00,
        'LogP': 0,
        'SIGMA': 100.00,
        'SCORE': 0.0,
        'CHANGE': 0.0
    })

    # Escribir archivo .par
    with open(par_path, 'w') as f:
        f.write("C           PSI   THETA     PHI       SHX       SHY     MAG  INCLUDE   DF1      DF2  "
                "ANGAST  PSHIFT     OCC      LogP      SIGMA   SCORE  CHANGE\n")
        for row in par_df.itertuples(index=False):
            f.write("{:>7} {:7.2f} {:7.2f} {:7.2f} {:9.2f} {:9.2f} {:7d} {:5d} {:8.1f} {:8.1f} {:7.2f} {:7.2f} {:7.2f} {:9d} {:10.4f} {:7.2f} {:7.2f}\n".format(*row))

    print(f"Archivo .par generado: {par_path}")
