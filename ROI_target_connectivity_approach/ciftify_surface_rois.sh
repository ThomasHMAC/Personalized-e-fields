#!/bin/bash
#SBATCH --partition=low-moby
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=2G
#SBATCH --time=20:00:00
#SBATCH --export=ALL
#SBATCH --job-name="surface_rois"
#SBATCH --output=/projects/ttan/UBC-TMS/analysis/RDLPFC_20mm_sphere/surface_rois_20_mm_%j.txt
#SBATCH --array=1

module load ciftify

study="UBC-TMS"
sublist=/projects/ttan/${study}/analysis/RDLPFC_20mm_sphere/rerun_sublist.txt

index() {
   head -n $SLURM_ARRAY_TASK_ID $sublist \
   | tail -n 1
}

in_csv=/projects/ttan/${study}/analysis/RDLPFC_20mm_sphere/ROIs
surf_L=/projects/ttan/UBC-TMS/in_progress/ciftify/`index`/MNINonLinear/fsaverage_LR32k/`index`.L.pial.32k_fs_LR.surf.gii
surf_R=/projects/ttan/UBC-TMS/in_progress/ciftify/`index`/MNINonLinear/fsaverage_LR32k/`index`.R.pial.32k_fs_LR.surf.gii

#surf_L=/external/UBC-TMS/ciftify/`index`/MNINonLinear/fsaverage_LR32k/`index`.L.pial.32k_fs_LR.surf.gii
#surf_R=/external/UBC-TMS/ciftify/`index`/MNINonLinear/fsaverage_LR32k/`index`.R.pial.32k_fs_LR.surf.gii
outdir=/projects/ttan/${study}/analysis/RDLPFC_20mm_sphere/

ciftify_surface_rois --verbose ${in_csv}/`index`_vertex_hemi.csv 20 ${surf_L} ${surf_R} ${outdir}/`index`_R_DLPFC_ROI_20mm_sphere_v1.dscalar.nii
