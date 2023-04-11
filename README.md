# Personalized-e-fields
Perform overlap calculation between functional connectiviy, e-fields, and surface vertex area maps in fs_LR32k space.

## Requirements:
1. Functional connectivity maps in CIFTI space
2. E-field maps in CIFTI space

## Pipelines:

Simulation of personalized e-fields can be found in the link below

https://github.com/TIGRLab/nextflow-simnibs/blob/main/README.md

Computation of the overlap overlap between connectivity and e-field maps.

Personalized_efields_approach/sum_connectivity_efields.py

Computation of target negative connectivity via ROI approach

ROI_target_connectivity_approach/sum_target_connectivity.py

## Example Usage:
