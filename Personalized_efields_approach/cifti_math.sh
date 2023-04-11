#!/bin/bash
#SBATCH --partition=low-moby
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=1G
#SBATCH --time=4:00:00
#SBATCH --export=ALL
#SBATCH --job-name cifti_seed_connectivity
#SBATCH --output=/projects/ttan/UBC-TMS/analysis/new_connectivity/smooth_4mm/logs/individual_cifti_seed_connectivity_rsfMRI_02_%j.txt
#SBATCH --array=1-34


module load connectome-workbench/1.3.2/
study="UBC-TMS"
sublist=/projects/ttan/${study}/analysis_LsgACC/PALM/sublist_MADRS_34_subs.txt
index() {
   head -n $SLURM_ARRAY_TASK_ID $sublist \
   | tail -n 1
}

#Input directory for L-sgACC connectivity maps
in_dir=/projects/ttan/${study}/analysis_LsgACC/LsgACC_connectivity/ses-02
#Output directory
output_dir=/projects/ttan/${study}/analysis_LsgACC/LsgACC_RDLPFC_conn_maps/ses-02/
in_roi=/projects/ttan/UBC-TMS/ROIs/R_DLPFC_glasser_combined_ROI.dscalar.nii

# Extract LsgACC to RDLPFC connectivity

wb_command -cifti-math 'x-y' ${output_dir}/`index`_ses-02_func_connectivity_L_sgACC_RDLPFC_glasser.dscalar.nii -var x ${in_dir}/`index`_ses-02_func_connectivity_L_sgACC_glasser.dscalar.nii -var y ${in_roi} 

