"""
Visualize latent space and generate volumes
"""

import argparse
import os
import os.path
import shutil
from datetime import datetime as dt
import logging
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
import cryodrgn
from cryodrgn import analysis, utils, config
import pickle

logger = logging.getLogger(__name__)


def add_args(parser):
    parser.add_argument(
        "workdir", type=os.path.abspath, help="Directory with cryoDRGN results"
    )
    parser.add_argument(
        "epoch",
        type=int,
        help="Epoch number N to analyze (0-based indexing, corresponding to z.N.pkl, weights.N.pkl)",
    )
    parser.add_argument("--device", type=int, help="Optionally specify CUDA device")
    parser.add_argument(
        "-o",
        "--outdir",
        help="Output directory for analysis results (default: [workdir]/analyze.[epoch])",
    )
    parser.add_argument(
        "--skip-vol", action="store_true", help="Skip generation of volumes"
    )
    parser.add_argument("--skip-umap", action="store_true", help="Skip running UMAP")

    group = parser.add_argument_group("Extra arguments for volume generation")
    group.add_argument(
        "--Apix",
        type=float,
        default=1,
        help="Pixel size to add to .mrc header (default: %(default)s A/pix)",
    )
    group.add_argument(
        "--flip", action="store_true", help="Flip handedness of output volumes"
    )
    group.add_argument(
        "--invert", action="store_true", help="Invert contrast of output volumes"
    )
    group.add_argument(
        "-d",
        "--downsample",
        type=int,
        help="Downsample volumes to this box size (pixels)",
    )
    group.add_argument(
        "--pc",
        type=int,
        default=2,
        help="Number of principal component traversals to generate (default: %(default)s)",
    )
    group.add_argument(
        "--ksample",
        type=int,
        default=20,
        help="Number of kmeans samples to generate (default: %(default)s)",
    )
    group.add_argument(
        "--indexes",
        type=os.path.abspath,
        help="Path to list of indexes for the volume generation",
    )
    group.add_argument(
        "--umaps",
        type=os.path.abspath,
        help="Path to umap.pkl file",
    )
    group.add_argument(
        "--vol-start-index",
        type=int,
        default=0,
        help="Default value of start index for volume generation (default: %(default)s)",
    )

    return parser


def analyze_z1(z, outdir, vg):
    """Plotting and volume generation for 1D z"""
    assert z.shape[1] == 1
    z = z.reshape(-1)
    N = len(z)

    plt.figure(1)
    plt.scatter(np.arange(N), z, alpha=0.1, s=2)
    plt.xlabel("particle")
    plt.ylabel("z")
    plt.savefig(f"{outdir}/z.png")

    plt.figure(2)
    sns.distplot(z)
    plt.xlabel("z")
    plt.savefig(f"{outdir}/z_hist.png")

    ztraj = np.percentile(z, np.linspace(5, 95, 10))
    vg.gen_volumes(outdir, ztraj)


def analyze_zN(z, outdir, vg, umap_dir=None, num_pcs=2, num_ksamples=20, indexes_list=None):
    zdim = z.shape[1]

    # UMAP -- slow step
    umap_emb = None
    if zdim > 2 and umap_dir == None:
        logger.info("Running UMAP...")
        umap_emb = analysis.run_umap(z)
        utils.save_pkl(umap_emb, f"{outdir}/umap.pkl")
    elif umap_dir != None:
        umap_emb = pickle.load(umap_dir) #Tengo que pasarle la dir de umap.pkl

    #Genero volúmenes según los índices que le pida
    if not os.path.exists(f"{outdir}/volumes_per_indexes"):
        os.mkdir(f"{outdir}/volumes_per_indexes")
    print('indexes_list: ', indexes_list)
    np.savetxt(f"{outdir}/volumes_per_indexes/centers.txt", z[indexes_list])
    np.savetxt(f"{outdir}/volumes_per_indexes/centers_ind.txt", indexes_list, fmt="%d")
    if indexes_list:
        logger.info("Generating reconstructions per indexes...")
        vg.gen_volumes(f"{outdir}/volumes_per_indexes", z[indexes_list])

def leer_archivo_y_generar_lista(nombre_archivo):
    try:
        with open(nombre_archivo, 'r') as archivo:
            # Lee todas las líneas del archivo
            lineas = archivo.readlines()

            # Convierte cada línea a un entero y agrégalo a la lista
            lista_enteros = [int(linea.strip()) for linea in lineas]

        return lista_enteros

    except FileNotFoundError:
        print(f"El archivo '{nombre_archivo}' no fue encontrado.")
        return None
    except Exception as e:
        print(f"Ocurrió un error: {e}")
        return None

class VolumeGenerator:
    """Helper class to call analysis.gen_volumes"""

    def __init__(self, weights, config, vol_args={}, skip_vol=False):
        self.weights = weights
        self.config = config
        self.vol_args = vol_args
        self.skip_vol = skip_vol

    def gen_volumes(self, outdir, z_values):
        if self.skip_vol:
            return
        if not os.path.exists(outdir):
            os.makedirs(outdir)
        zfile = f"{outdir}/z_values.txt"
        np.savetxt(zfile, z_values)
        analysis.gen_volumes(self.weights, self.config, zfile, outdir, **self.vol_args)


def main(args):
    t1 = dt.now()
    E = args.epoch
    workdir = args.workdir
    zfile = f"{workdir}/z.{E}.pkl"
    weights = f"{workdir}/weights.{E}.pkl"
    cfg = (
        f"{workdir}/config.yaml"
        if os.path.exists(f"{workdir}/config.yaml")
        else f"{workdir}/config.pkl"
    )
    outdir = f"{workdir}/analyze.{E}"
    if E == -1:
        zfile = f"{workdir}/z.pkl"
        weights = f"{workdir}/weights.pkl"
        outdir = f"{workdir}/analyze"

    if args.outdir:
        outdir = args.outdir
    logger.info(f"Saving results to {outdir}")
    if not os.path.exists(outdir):
        os.mkdir(outdir)

    if args.umap:
        umap_dir = args.umap
    else:
        umap_dir = None


    # Ejemplo de uso
    #nombre_archivo = '/nfs/bartesaghilab2/ds672/empiar10076/2023_11_06_output_tutorial_downsampling_256_z_8_20pixels_translation/analyze.49/kmeans5/centers_ind.txt'  # Reemplaza 'archivo.txt' con el nombre de tu archivo
    file_name = args.indexes
    index_list = leer_archivo_y_generar_lista(file_name)

    if index_list is not None:
        print(f"Lista de enteros generada: {index_list}")

    z = utils.load_pkl(zfile)
    zdim = z.shape[1]

    vol_args = dict(
        Apix=args.Apix,
        downsample=args.downsample,
        flip=args.flip,
        device=args.device,
        invert=args.invert,
        vol_start_index=args.vol_start_index,
    )
    vg = VolumeGenerator(weights, cfg, vol_args, skip_vol=args.skip_vol)

    if zdim == 1:
        analyze_z1(z, outdir, vg)
    else:
        analyze_zN(
            z,
            outdir,
            vg,
            umap_dir=umap_dir,
            num_pcs=args.pc,
            num_ksamples=args.ksample,
            indexes_list=index_list
        )

    logger.info(f"Finished in {dt.now()-t1}")


if __name__ == "__main__":
    matplotlib.use("Agg")  # non-interactive backend
    parser = argparse.ArgumentParser(description=__doc__)
    add_args(parser)
    main(parser.parse_args())
