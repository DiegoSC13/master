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
#Edit Diego
import pickle
from typing import Tuple, Optional
from sklearn.mixture import GaussianMixture
from sklearn.cluster import KMeans, DBSCAN


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
        "--vol-start-index",
        type=int,
        default=0,
        help="Default value of start index for volume generation (default: %(default)s)",
    )
    group.add_argument(
        "--cal_umap",
        type=bool,
        default=True,
        help="En caso de haber calculado UMAPs antes, le paso el path acá y no lo vuelvo a calcular (default: %(default)s)",
    )
    group.add_argument(
        "--init_centers",
        type=str,
        help="Ruta a un archivo .txt con índices (uno por línea) de centroides iniciales. Si no se pasa, se eligen aleatoriamente.",
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


def analyze_zN(z, outdir, vg, skip_umap=False, num_pcs=2, num_ksamples=20, init_centers=None):
    zdim = z.shape[1]
    K = num_ksamples
    N = len(z)

    #Genero directorios para guardar K-Means en z, PCA y UMAPs
    if not os.path.exists(f"{outdir}/kmeans{K}_z"):
        os.mkdir(f"{outdir}/kmeans{K}_z")
    if not os.path.exists(f"{outdir}/kmeans{K}_pca"):
        os.mkdir(f"{outdir}/kmeans{K}_pca")
    if not os.path.exists(f"{outdir}/kmeans{K}_umap"):
        os.mkdir(f"{outdir}/kmeans{K}_umap")
    if not os.path.exists(f"{outdir}/gmm{K}_umap"):
        os.mkdir(f"{outdir}/gmm{K}_umap")
    if not os.path.exists(f"{outdir}/dbscan_umap"):
        os.mkdir(f"{outdir}/dbscan_umap")
    if not os.path.exists(f"{outdir}/hdbscan_umap"):
        os.mkdir(f"{outdir}/hdbscan_umap")

    # kmeans clustering on z
    logger.info("K-means clustering on z...")
    #pc = np.array(pc).reshape(N, num_pcs)
    kmeans_labels_z, centers_z = analysis.cluster_kmeans(z, K)#, init_centers=init_centers)
    centers_z, centers_ind = analysis.get_nearest_point(z, centers_z)
    #if not os.path.exists(f"{outdir}/kmeans{K}"):
    #   os.mkdir(f"{outdir}/kmeans{K}")
    utils.save_pkl(kmeans_labels_z, f"{outdir}/kmeans{K}_z/labels.pkl")
    np.savetxt(f"{outdir}/kmeans{K}_z/centers.txt", centers_z)
    np.savetxt(f"{outdir}/kmeans{K}_z/centers_ind.txt", centers_ind, fmt="%d")
    logger.info("Generating center volumes for z-KMeans...")
    vg.gen_volumes(f"{outdir}/kmeans{K}_z", centers_z)

    # Principal component analysis
    logger.info("Performing PCA...")
    pc, pca = analysis.run_pca(z)

    logger.info("K-means clustering on PCA...")
    kmeans_labels_pca, centers_pca = analysis.cluster_kmeans(pc, K)
    centers_pca, centers_ind_pca = analysis.get_nearest_point(pc, centers_pca)
    #if not os.path.exists(f"{outdir}/kmeans{K}"):
    #   os.mkdir(f"{outdir}/kmeans{K}")
    utils.save_pkl(pc, f"{outdir}/pc.pkl")
    utils.save_pkl(kmeans_labels_pca, f"{outdir}/kmeans{K}_pca/labels.pkl")
    np.savetxt(f"{outdir}/kmeans{K}_pca/centers.txt", centers_pca)
    np.savetxt(f"{outdir}/kmeans{K}_pca/centers_ind.txt", centers_ind_pca, fmt="%d")
    logger.info("Generating center volumes for PCA-KMeans...")
    vg.gen_volumes(f"{outdir}/kmeans{K}_pca", centers_pca)

    # UMAP -- slow step
    umap_emb = None
    if zdim > 2 and not skip_umap:
        logger.info("Running UMAP...")
        umap_emb = analysis.run_umap(z)
        utils.save_pkl(umap_emb, f"{outdir}/umap.pkl")
    
    # kmeans clustering on UMAPs
    if umap_emb is None:
        logger.info(f"UMAP already calculated, uploading {outdir}/umap.pkl...")
        with open(f"{outdir}/umap.pkl", 'rb') as file:
            umap_emb = pickle.load(file)
    logger.info("K-means clustering on UMAPs...")
    kmeans_labels_umap, kmeans_centers_umap = analysis.cluster_kmeans2(umap_emb, K, init_centers=init_centers)
    kmeans_centers_umap, kmeans_centers_ind_umap = analysis.get_nearest_point(umap_emb, kmeans_centers_umap)

    utils.save_pkl(kmeans_labels_umap, f"{outdir}/kmeans{K}_umap/labels.pkl")
    #np.savetxt(f"{outdir}/kmeans{K}_umap/kmeans_labels.txt", kmeans_labels_umap)
    np.savetxt(f"{outdir}/kmeans{K}_umap/centers.txt", kmeans_centers_umap)
    np.savetxt(f"{outdir}/kmeans{K}_umap/centers_ind.txt", kmeans_centers_ind_umap, fmt="%d")
    logger.info("Generating center volumes for UMAP-KMeans...")
    vg.gen_volumes(f"{outdir}/kmeans{K}_umap", z[kmeans_centers_ind_umap])
    ############################################

    #GMM clustering on UMAPs
    gmm_labels_umap, gmm_centers_umap = analysis.cluster_gmm(umap_emb, K)
    gmm_centers_umap, gmm_centers_ind_umap = analysis.get_nearest_point(umap_emb, gmm_centers_umap)

    utils.save_pkl(gmm_labels_umap, f"{outdir}/gmm{K}_umap/labels.pkl")
    #np.savetxt(f"{outdir}/gmm{K}_umap/gmm_labels.txt", gmm_labels_umap)
    np.savetxt(f"{outdir}/gmm{K}_umap/centers.txt", gmm_centers_umap)
    np.savetxt(f"{outdir}/gmm{K}_umap/centers_ind.txt", gmm_centers_ind_umap, fmt="%d")
    logger.info("Generating volumes from GMM clustering...")
    vg.gen_volumes(f"{outdir}/gmm{K}_umap", z[gmm_centers_ind_umap])

    logger.info("Generating volumes from DBSCAN clustering...")
    labels_dbscan = analysis.aplicar_clustering('dbscan', umap_emb, eps=0.5, min_samples=50)
    #analysis.plot_clusters(umap_emb, labels_dbscan, title="DBSCAN sobre UMAP")
    utils.save_pkl(labels_dbscan, f"{outdir}/dbscan_umap/labels.pkl")

    logger.info("Generating volumes from HDBSCAN clustering...")
    labels_hdbscan = analysis.aplicar_clustering('hdbscan', umap_emb, min_cluster_size=50)
    #analysis.plot_clusters(umap_emb, labels_hdbscan, title="HDBSCAN sobre UMAP")
    utils.save_pkl(labels_hdbscan, f"{outdir}/hdbscan_umap/labels.pkl")

    # Make some plots
    logger.info("Generating plots...")

    def plt_pc_labels(x=0, y=1):
        plt.xlabel(f"PC{x+1} ({pca.explained_variance_ratio_[x]:.2f})")
        plt.ylabel(f"PC{y+1} ({pca.explained_variance_ratio_[y]:.2f})")

    def plt_pc_labels_jointplot(g, x=0, y=1):
        g.ax_joint.set_xlabel(f"PC{x+1} ({pca.explained_variance_ratio_[x]:.2f})")
        g.ax_joint.set_ylabel(f"PC{y+1} ({pca.explained_variance_ratio_[y]:.2f})")

    def plt_umap_labels():
        plt.xticks([])
        plt.yticks([])
        plt.xlabel("UMAP1")
        plt.ylabel("UMAP2")

    def plt_umap_labels_jointplot(g):
        g.ax_joint.set_xlabel("UMAP1")
        g.ax_joint.set_ylabel("UMAP2")

    def plt_gmm_labels():
        plt.xticks([])
        plt.yticks([])
        plt.xlabel("GMM1")
        plt.ylabel("GMM2")

    def plt_gmm_labels_jointplot(g):
        g.ax_joint.set_xlabel("GMM1")
        g.ax_joint.set_ylabel("GMM2")

    
    # PCA -- Style 1 -- Scatter
    plt.figure(figsize=(4, 4))
    plt.scatter(pc[:, 0], pc[:, 1], alpha=0.1, s=1, rasterized=True)
    plt_pc_labels()
    plt.tight_layout()
    plt.savefig(f"{outdir}/z_pca.png")

    # PCA -- Style 2 -- Scatter, with marginals
    g = sns.jointplot(x=pc[:, 0], y=pc[:, 1], alpha=0.1, s=1, rasterized=True, height=4)
    plt_pc_labels_jointplot(g)
    plt.tight_layout()
    plt.savefig(f"{outdir}/z_pca_marginals.png")

    # PCA -- Style 3 -- Hexbin
    g = sns.jointplot(x=pc[:, 0], y=pc[:, 1], height=4, kind="hex")
    plt_pc_labels_jointplot(g)
    plt.tight_layout()
    plt.savefig(f"{outdir}/z_pca_hexbin.png")

    if umap_emb is not None:
        # Style 1 -- Scatter
        plt.figure(figsize=(4, 4))
        plt.scatter(umap_emb[:, 0], umap_emb[:, 1], alpha=0.1, s=1, rasterized=True)
        plt_umap_labels()
        plt.tight_layout()
        plt.savefig(f"{outdir}/umap.png")

        # Style 2 -- Scatter with marginal distributions
        g = sns.jointplot(
            x=umap_emb[:, 0],
            y=umap_emb[:, 1],
            alpha=0.1,
            s=1,
            rasterized=True,
            height=4,
        )
        plt_umap_labels_jointplot(g)
        plt.tight_layout()
        plt.savefig(f"{outdir}/umap_marginals.png")

        # Style 3 -- Hexbin / heatmap
        g = sns.jointplot(x=umap_emb[:, 0], y=umap_emb[:, 1], kind="hex", height=4)
        plt_umap_labels_jointplot(g)
        plt.tight_layout()
        plt.savefig(f"{outdir}/umap_hexbin.png")

    # Plot kmeans sample points
    colors = analysis._get_chimerax_colors(K)
    analysis.scatter_annotate(
        pc[:, 0],
        pc[:, 1],
        centers_ind=centers_ind,
        annotate=True,
        colors=colors,
    )
    plt_pc_labels()
    plt.tight_layout()
    plt.savefig(f"{outdir}/kmeans{K}_pca/z_pca_centers.png")

    g = analysis.scatter_annotate_hex(
        pc[:, 0],
        pc[:, 1],
        centers_ind=centers_ind,
        annotate=True,
        colors=colors,
    )
    plt_pc_labels_jointplot(g)
    plt.tight_layout()
    plt.savefig(f"{outdir}/kmeans{K}_pca/z_pca_hex_centers.png")

    if umap_emb is not None:
        analysis.scatter_annotate(
            umap_emb[:, 0],
            umap_emb[:, 1],
            centers_ind=centers_ind,
            annotate=True,
            colors=colors,
        )
        plt_umap_labels()
        plt.tight_layout()
        plt.savefig(f"{outdir}/kmeans{K}_umap/umap_centers.png")

        g = analysis.scatter_annotate_hex(
            umap_emb[:, 0],
            umap_emb[:, 1],
            centers_ind=centers_ind,
            annotate=True,
            colors=colors,
        )
        plt_umap_labels_jointplot(g)
        plt.tight_layout()
        plt.savefig(f"{outdir}/kmeans{K}_umap/umap_hex_centers.png")


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
    #####
    init_centers = None
    if args.init_centers:
        # Leer cada línea como un vector de floats
        with open(args.init_centers, "r") as f:
            init_centers = np.array([
                list(map(float, line.strip().split()))
                for line in f if line.strip()
            ])

        # Validación opcional
        if init_centers.shape[1] != z.shape[1]:
            raise ValueError(f"Los centros tienen dimensión {init_centers.shape[1]}, pero z tiene dimensión {z.shape[1]}")

    #####
    E = args.epoch
    workdir = args.workdir
    zfile = f"{workdir}/z.{E}.pkl"
    weights = f"{workdir}/weights.{E}.pkl"
    cfg = (
        f"{workdir}/config.yaml"
        if os.path.exists(f"{workdir}/config.yaml")
        else f"{workdir}/config.pkl"
    )
    outdir = f"{workdir}/analysis_diego.{E}"
    if E == -1:
        zfile = f"{workdir}/z.pkl"
        weights = f"{workdir}/weights.pkl"
        outdir = f"{workdir}/analysis_diego"

    if args.outdir:
        outdir = args.outdir
    logger.info(f"Saving results to {outdir}")
    if not os.path.exists(outdir):
        os.mkdir(outdir)

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
    cal_umap = args.cal_umap
    if cal_umap == False:       
        skip_umap = True
    else:
        skip_umap = False
    if zdim == 1:
        analyze_z1(z, outdir, vg)
    else:
        analyze_zN(
            z,
            outdir,
            vg,
            skip_umap,
            num_pcs=args.pc,
            num_ksamples=args.ksample,
            init_centers=args.init_centers
        )

    # copy over template if file doesn't exist
    cfg = config.load(cfg)
    if cfg["model_args"]["encode_mode"] == "tilt":
        out_ipynb = f"{outdir}/cryoDRGN_ET_viz.ipynb"
        if not os.path.exists(out_ipynb):
            logger.info("Creating jupyter notebook...")
            ipynb = f"{cryodrgn._ROOT}/templates/cryoDRGN_ET_viz_template.ipynb"
            shutil.copyfile(ipynb, out_ipynb)
        else:
            logger.info(f"{out_ipynb} already exists. Skipping")
        logger.info(out_ipynb)
    else:
        out_ipynb = f"{outdir}/cryoDRGN_viz.ipynb"
        if not os.path.exists(out_ipynb):
            logger.info("Creating jupyter notebook...")
            ipynb = f"{cryodrgn._ROOT}/templates/cryoDRGN_viz_template.ipynb"
            shutil.copyfile(ipynb, out_ipynb)
        else:
            logger.info(f"{out_ipynb} already exists. Skipping")
        logger.info(out_ipynb)

        # copy over template if file doesn't exist
        out_ipynb = f"{outdir}/cryoDRGN_filtering.ipynb"
        if not os.path.exists(out_ipynb):
            logger.info("Creating jupyter notebook...")
            ipynb = f"{cryodrgn._ROOT}/templates/cryoDRGN_filtering_template.ipynb"
            shutil.copyfile(ipynb, out_ipynb)
        else:
            logger.info(f"{out_ipynb} already exists. Skipping")
        logger.info(out_ipynb)

    # copy over template if file doesn't exist
    out_ipynb = f"{outdir}/cryoDRGN_figures.ipynb"
    if not os.path.exists(out_ipynb):
        logger.info("Creating jupyter notebook...")
        ipynb = f"{cryodrgn._ROOT}/templates/cryoDRGN_figures_template.ipynb"
        shutil.copyfile(ipynb, out_ipynb)
    else:
        logger.info(f"{out_ipynb} already exists. Skipping")
    logger.info(out_ipynb)

    out_ipynb = f"{outdir}/cryoDRGN_figures_diego.ipynb"
    if not os.path.exists(out_ipynb):
        logger.info("Creating jupyter notebook...")
        ipynb = f"{cryodrgn._ROOT}/templates/cryoDRGN_diego_template.ipynb"
        shutil.copyfile(ipynb, out_ipynb)
    else:
        logger.info(f"{out_ipynb} already exists. Skipping")
    logger.info(out_ipynb)

    logger.info(f"Finished in {dt.now()-t1}")


if __name__ == "__main__":
    matplotlib.use("Agg")  # non-interactive backend
    parser = argparse.ArgumentParser(description=__doc__)
    add_args(parser)
    main(parser.parse_args())
