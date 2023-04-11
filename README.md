# Personalized-e-fields
Perform overlap calculation between functional connectiviy, e-fields, and surface vertex area maps in fs_LR32k space.

## Requirements:
1. Functional connectivity maps in CIFTI space
2. E-field maps in CIFTI space

## Pipelines:

SimNIBS - perform reconstruction of a tetrahedral head mesh from T1-weight image

https://github.com/simnibs/simnibs

simNIBS to Cifti Space - perform surface mapping from SimNIBS native surface outputs to HCP fs_LR32kspace

https://github.com/TIGRLab/nextflow-simnibs

### Computation of the overlap overlap between connectivity and e-field maps.

```Personalized_efields_approach/sum_connectivity_efields.py``` - calculate the overlap between connectivity, efields, and surface area maps

```
Usage:
   meants_dotproduct [options] <func> <seed> <L_va> <R_va>
Arguments:
    <func>          functional connectivity at ROIs (cifti; dscalar)
    <efield>        efield data (cifti;dscalar)
    <L_va>          surface area each vertex is responsible for in left hemisphere (gifti;va.shape.gii)
    <R_va>          surface area each vertex is responsible for in righ hemisphere (gifti;va.shape.gii)

Options:
    --outputcsv PATH     Specify the output filename
    --debug              Debug logging
    -h, --help           Prints this message
```   
   
### Computation of target negative connectivity via ROI approach

```ROI_target_connectivity_approach/sum_target_connectivity.py``` - calculate the connectiviy proximate to the target and surface area maps 
```
Usage:
   meants_dotproduct [options] <func> <seed> <L_va> <R_va>
Arguments:
    <func>          functional connectivity at ROIs (cifti; dscalar)
    <L_va>          surface area each vertex is responsible for in left hemisphere (gifti;va.shape.gii)
    <R_va>          surface area each vertex is responsible for in righ hemisphere (gifti;va.shape.gii)
Options:
    --outputcsv PATH     Specify the output filename
    --debug              Debug logging
    -h, --help           Prints this message
```
