# --------------------------------------------------------
# FCN
# Copyright (c) 2016
# Licensed under The MIT License [see LICENSE for details]
# Written by Yu Xiang
# --------------------------------------------------------

import numpy as np
cimport numpy as np

assert sizeof(int) == sizeof(np.int32_t)

cdef extern from "gpu_build_voxel.hpp":
    void _build_voxels(int grid_size, float step_d, float step_h, float step_w,
                   float min_d, float min_h, float min_w,
                   int filter_h, int filter_w, int num_classes,
                   int height, int width, np.int32_t* grid_indexes, np.int32_t* labels,
                   np.float32_t* pmatrix, np.int32_t* top_locations, np.int32_t* top_labels, int device_id)

    void _compute_pixel_labels(int grid_size, int num_classes, int height, int width,
                   np.int32_t* grid_indexes, np.float32_t* cls_prob_3d, np.int32_t* top_labels, int device_id);

def gpu_build_voxel(np.int32_t grid_size, np.float step_d, np.float step_h, np.float step_w,
            np.float min_d, np.float min_h, np.float min_w,
            np.int32_t filter_h, np.int32_t filter_w, np.int32_t num_classes,
            np.ndarray[np.int32_t, ndim=2] grid_indexes, np.ndarray[np.int32_t, ndim=2] labels,
            np.ndarray[np.float32_t, ndim=2] pmatrix, np.int32_t device_id=0):

    cdef int height = labels.shape[0]
    cdef int width = labels.shape[1]

    cdef np.ndarray[np.int32_t, ndim=4] \
        top_locations = np.zeros((grid_size, grid_size, grid_size, filter_h * filter_w), dtype=np.int32)

    cdef np.ndarray[np.int32_t, ndim=4] \
        top_labels = np.zeros((grid_size, grid_size, grid_size, num_classes), dtype=np.int32)

    _build_voxels(grid_size, step_d, step_h, step_w, min_d, min_h, min_w, filter_h, filter_w, num_classes, height, width, \
                  &grid_indexes[0, 0], &labels[0, 0], &pmatrix[0, 0], &top_locations[0, 0, 0, 0], &top_labels[0, 0, 0, 0], device_id)

    return top_locations, top_labels

# compute pixel labels from 3D probablities on voxels
def gpu_compute_labels(np.ndarray[np.int32_t, ndim=2] grid_indexes, np.ndarray[np.float32_t, ndim=4] cls_prob_3d, np.int32_t device_id=0):

    cdef int height = grid_indexes.shape[0]
    cdef int width = grid_indexes.shape[1]
    cdef int grid_size = cls_prob_3d.shape[0]
    cdef int num_classes = cls_prob_3d.shape[3]

    cdef np.ndarray[np.int32_t, ndim=2] \
        top_labels = np.zeros((height, width), dtype=np.int32)

    _compute_pixel_labels(grid_size, num_classes, height, width, \
                  &grid_indexes[0, 0], &cls_prob_3d[0, 0, 0, 0], &top_labels[0, 0], device_id)

    return top_labels