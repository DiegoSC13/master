# Pipeline Overview

The main entry point of the pipeline is the script main.sh.

This script orchestrates the entire iterative workflow of the project, coordinating model training, latent space analysis, clustering, 3D refinement, and pose updates across multiple iterations.

Execution syntax:

```bash
main.sh CONFIG_NAME CLUSTER_METHOD DATASET DIM NUM_CLUSTERS DIM_UMAP
```
Main scripts paratemers (`main.sh`)

`CONFIG_NAME`
Name of the configuration file (e.g. `config_10076.sh`).

This file defines fixed experimental parameters, such as:
- Latent space dimensionality 
- Downsampling factor
- Number of iterations 
- CryoDRGN training parameters
- Analysis parameters


`CLUSTER_METHOD`
Clustering algorithm applied to the latent space.

Supported values:
- `KMEANS`  : centroid-based clustering with a fixed number of clusters
- `HDBSCAN`: density-based clustering with an adaptive number of clusters

This choice determines:
- The clustering strategy
- The downstream refinement script
- The directory structure used to store results


`DATASET`
EMPIAR dataset identifier.

Currently supported:
- `10076`
- `10180`

This parameter controls dataset-specific paths, input poses, .par files, and filtering strategies, which are defined explicitly inside main.sh.

`DIM`
Image dimension used for training and reconstruction.

Typical values include:
- `128`
- `256`
- `320`

This parameter determines:
- The resolution of input particle images
- Which preprocessed datasets and pose files are used


`NUM_CLUSTERS`
Number of clusters used only when CLUSTER_METHOD = KMEANS.

For HDBSCAN, this parameter is ignored, as the number of clusters is inferred automatically from data density.


`DIM_UMAP`
Dimensionality of the UMAP embedding used for latent space analysis.

Supported values:
- `2`  : 2D embedding
- `3`  : 3D embedding


Auxiliary scripts called by `main.sh`

`cryodrgn.sh`
Trains a CryoDRGN model using the current set of poses and particle images.

`analysis.sh`
Performs latent space analysis, including UMAP projection and clustering.

`clusters_processing.sh`
Processes clustering results and generates particle subsets for refinement.

`frealign_kmeans.sh`
Performs cluster-wise 3D refinement using Frealign when K-Means clustering is selected.

`frealign_hdbscan.sh`
Performs cluster-wise 3D refinement using Frealign when HDBSCAN clustering is selected.

`poses_processing.sh`
Generates updated pose estimates to be reused in the next iteration.


### Iterative workflow

The pipeline runs over multiple iterations. At each iteration:
- A new output directory is created using a timestamp
- A progressively lower maximum resolution limit is applied during refinement
- Results from the previous iteration are reused
- Updated poses are generated and fed into the next iteration

This iterative strategy enables progressive improvement of structural consistency,
while explicitly modeling conformational heterogeneity.


### Author
Diego Silvera
Master’s Thesis
Heterogeneous Cryo-EM Reconstruction using Deep Generative Models
