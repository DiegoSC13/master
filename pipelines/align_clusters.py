#!/usr/bin/env python3

import numpy as np
from scipy.spatial.distance import cdist
from scipy.optimize import linear_sum_assignment
import argparse
import pickle

def load_pkl(path):
    with open(path, 'rb') as f:
        return pickle.load(f)

def remap_cluster_labels(X, labels_prev, labels_curr):
    """
    Renombra etiquetas de clustering actual para que coincidan con etiquetas anteriores,
    basándose en cercanía de centroides. No modifica los grupos ni las asignaciones.
    """
    mask_prev = labels_prev != -1
    mask_curr = labels_curr != -1

    prev_ids = np.unique(labels_prev[mask_prev])
    curr_ids = np.unique(labels_curr[mask_curr])
    
    if len(prev_ids) == 0 or len(curr_ids) == 0:
        return labels_curr  # No hay nada que emparejar
    
    prev_centroids = np.array([X[labels_prev == i].mean(axis=0) for i in prev_ids])
    curr_centroids = np.array([X[labels_curr == i].mean(axis=0) for i in curr_ids])
    
    distance_matrix = cdist(curr_centroids, prev_centroids)
    row_ind, col_ind = linear_sum_assignment(distance_matrix)
    
    id_map = {}
    used_prev_ids = set()
    for i, j in zip(row_ind, col_ind):
        id_map[curr_ids[i]] = prev_ids[j]
        used_prev_ids.add(prev_ids[j])
    
    unused_id = max(prev_ids.max(), curr_ids.max(), -1) + 1
    for cid in curr_ids:
        if cid not in id_map:
            id_map[cid] = unused_id
            unused_id += 1
    
    labels_curr_remap = np.array([
        id_map[label] if label != -1 else -1
        for label in labels_curr
    ])
    
    return labels_curr_remap

def main():
    parser = argparse.ArgumentParser(description="Remap cluster labels from .pkl files for consistency across iterations.")
    parser.add_argument('--X', required=True, help='Path to .pkl file with UMAP coordinates (numpy array)')
    parser.add_argument('--labels_prev', required=True, help='Path to .pkl file with previous labels')
    parser.add_argument('--labels_curr', required=True, help='Path to .pkl file with current labels')
    parser.add_argument('--output', default='labels_curr_remap.pkl', help='Output path for remapped labels (.pkl)')
    
    args = parser.parse_args()

    X = load_pkl(args.X)
    labels_prev = load_pkl(args.labels_prev)
    labels_curr = load_pkl(args.labels_curr)

    labels_remap = remap_cluster_labels(X, labels_prev, labels_curr)

    with open(args.output, 'wb') as f:
        pickle.dump(labels_remap, f)

    print(f"Etiquetas remapeadas guardadas en: {args.output}")

if __name__ == '__main__':
    main()
