import pandas as pd
import argparse

def convert_par_file(input_path, output_path, default_df1=None, default_df2=None,
                     default_score=None, default_mag=None, default_ang=None, default_occ=None):
    """
    Convierte un archivo .par al formato Frealign clásico compatible con reconstruct3d_stats.
    """
    with open(input_path, 'r') as f:
        lines = [line.strip() for line in f if not line.startswith('C') and line.strip()]

    data = pd.DataFrame([
        list(map(float, line.split()))
        for line in lines
    ])

    data.columns = [
        'C', 'PSI', 'THETA', 'PHI', 'SHX', 'SHY',
        'MAG', 'INCLUDE', 'DF1', 'DF2', 'ANGAST',
        'PSHIFT', 'OCC', 'LogP', 'SIGMA', 'SCORE', 'CHANGE'
    ]

    # if default_df1 is not None:
    #     data['DF1'] = data['DF1'].replace(0.0, default_df1)
    # if default_df2 is not None:
    #     data['DF2'] = data['DF2'].replace(0.0, default_df2)
    # if default_score is not None:
    #     data['SCORE'] = data['SCORE'].replace(0.0, default_score)
    if default_mag is not None:
        data['MAG'] = data['MAG'].replace(0.0, default_mag)
    if default_occ is not None:
        data['OCC'] = data['OCC'].replace(0.0, default_occ)
    if default_mag is not None:
        data['ANGAST'] = data['ANGAST'].replace(0.0, default_ang)

    data['FILM'] = 1
    data['-LogP'] = -data['LogP']

    # Convertir columnas a enteros donde corresponde
    data['C'] = data['C'].astype(int)
    data['MAG'] = data['MAG'].astype(int)
    data['FILM'] = data['FILM'].astype(int)

    columns_out = [
        'C', 'PSI', 'THETA', 'PHI', 'SHX', 'SHY',
        'MAG', 'FILM', 'DF1', 'DF2', 'ANGAST',
        'OCC', '-LogP', 'SIGMA', 'SCORE', 'CHANGE'
    ]
    data_out = data[columns_out]

    with open(output_path, 'w') as f:
        header = (
            "C           PSI   THETA     PHI       SHX       SHY     MAG  FILM"
            "      DF1      DF2  ANGAST     OCC     -LogP      SIGMA   SCORE  CHANGE\n"
        )
        f.write(header)
        for row in data_out.itertuples(index=False):
            f.write("{:7d}{:9.2f}{:8.2f}{:8.2f}{:10.2f}{:10.2f}{:7d}{:7d}{:10.1f}{:10.1f}"
                    "{:9.2f}{:9.2f}{:10.1f}{:10.4f}{:8.2f}{:7.2f}\n".format(*row))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convierte un archivo .par al formato Frealign clásico.")
    parser.add_argument("input_path", help="Ruta al archivo .par original (mal formado)")
    parser.add_argument("output_path", help="Ruta de salida del archivo .par corregido")
    # parser.add_argument("--df1", type=float, default=None, help="Valor por defecto para DF1 si es 0.0")
    # parser.add_argument("--df2", type=float, default=None, help="Valor por defecto para DF2 si es 0.0")
    # parser.add_argument("--score", type=float, default=None, help="Valor por defecto para SCORE si es 0.0")
    parser.add_argument("--mag", type=int, default=None, help="Valor por defecto para MAG si es 0")
    parser.add_argument("--ang", type=float, default=None, help="Valor por defecto para ANGAST si es 0.0")
    parser.add_argument("--occ", type=float, default=None, help="Valor por defecto para OCC si es 0")

    args = parser.parse_args()

    convert_par_file(
        input_path=args.input_path,
        output_path=args.output_path,
        # default_df1=args.df1,
        # default_df2=args.df2,
        # default_score=args.score,
        default_mag=args.mag,
        default_ang=args.ang,
        default_occ=args.occ
    )
    print(f"Archivo convertido guardado en: {args.output_path}")
