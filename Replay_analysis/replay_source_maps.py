#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Sep 10 14:39:32 2026

@author: Anastasia Dimakou 
The script:
1. Loads a 4D NIfTI source-reconstruction map.
2. Averages activity around stimulus onset.
3. Takes the absolute activation magnitude.
4. Masks the image to cortical regions.
5. Retains the strongest 10% of cortical voxels.
6. Displays the resulting map in orthographic views.
"""


from nilearn import image, plotting, datasets
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.cm import ScalarMappable
from matplotlib.colors import Normalize

# --------------------------------------------------
# Load motor reconstruction
# --------------------------------------------------
vis_for = "/home/uranus/Scrivania/source_reconstruction/Replay_inter1.nii.gz"
vis_back =  "/home/uranus/Scrivania/source_reconstruction/Replay_avergae_visual_back.nii.gz"
motor_for=  "/home/uranus/Scrivania/source_reconstruction/Replay_motor_for_inter5.nii.gz"
img = image.load_img(
    vis_for
)

data = img.get_fdata()

print("Shape:", data.shape)



# --------------------------------------------------
# Extract onset (0 ms)
# t=100 corresponds to 0 ms
# --------------------------------------------------

onset_map = np.mean(data[:, :, :, 100:110], axis=3)
# absolute activation
onset_map = np.abs(onset_map)



# --------------------------------------------------
# Cortical mask (remove cerebellum + subcortical)
# --------------------------------------------------

atlas = datasets.fetch_atlas_harvard_oxford(
    'cort-maxprob-thr25-2mm'
)

atlas_img = image.resample_to_img(
    atlas.maps,
    img,
    interpolation='nearest'
)

atlas_data = atlas_img.get_fdata()

# cortex only
cortex_mask = atlas_data > 0


# remove non-cortex
onset_map[~cortex_mask] = 0



# --------------------------------------------------
# Keep strongest 10% cortical voxels
# --------------------------------------------------

percentile = 90

threshold = np.percentile(
    onset_map[onset_map > 0],
    percentile
)

print("Threshold:", threshold)


strong_map = np.zeros_like(onset_map)

strong_map[
    onset_map >= threshold
] = onset_map[
    onset_map >= threshold
]

print(
    "Strong cortical voxels:",
    np.sum(strong_map > 0)
)



# --------------------------------------------------
# Create image
# --------------------------------------------------

strong_img = image.new_img_like(
    img,
    strong_map
)




fig = plt.figure(figsize=(8, 6))

display = plotting.plot_stat_map(
    strong_img,
    threshold=0,
    display_mode="ortho",
    cmap="Oranges",
    colorbar=False,   # Disable Nilearn's colorbar
    title="Motor Forward",
    figure=fig
)

# Create a horizontal colorbar
norm = Normalize(vmin=strong_map.min(), vmax=strong_map.max())
sm = ScalarMappable(norm=norm, cmap="Oranges")
sm.set_array([])

cax = fig.add_axes([0.25, 0.08, 0.5, 0.03])  # [left, bottom, width, height]
cbar = plt.colorbar(sm, cax=cax, orientation="horizontal")
cbar.set_label("Forward")

plt.show()
plt.show()
