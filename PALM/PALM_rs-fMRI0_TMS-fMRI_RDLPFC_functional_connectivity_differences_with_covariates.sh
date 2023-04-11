#!/bin/bash
#SBATCH --partition=low-moby
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=2G
#SBATCH --time=30:00:00
#SBATCH --export=ALL
#SBATCH --job-name PALM
#SBATCH --output=/projects/ttan/UBC-TMS/analysis_LsgACC/PALM/PALM_conmat_MDD_RDLPFC_TMS-fMRI_rsfMRI0_diff_with_covariates_28_subs_%j.txt
#SBATCH --array=1

module load matlab/R2017b
module load palm/alpha111
module load connectome-workbench/1.4.1

#Assign DIR to the root directory for PALM analysis
DIR="/projects/ttan/UBC-TMS/analysis_LsgACC/PALM"

#users should input the directory of sublistids

#sublistids is in the format of "subid_site_number", eg: sub-CMHWM003
sublistids="${DIR}/sublist_MADRS_28_subs.txt"

#assign full path for filename files, which is a list of path to GLM output in surface space
filename="$(find $DIR/filelists/RDLPFC/TMS-fMRI_rs-fMRI0/filelist*.txt -type f | head -n $SLURM_ARRAY_TASK_ID | tail -n 1)"
truncname="$(echo $(basename `echo "$filename"`) | sed 's/filelist/PALM_conmat_MDD_RDLPFC_TMS-rsfMRI_baseline_rsfMRI_diff_with_covariates/;s/.txt//')"
outdir="${DIR}/Results/$truncname"
desmat="$DIR/con_design/design_mat_active_baseline_with_covariates_noMT_28_subs.csv"
conmat="$DIR/con_design/con_mat_active_baseline_with_covariates_noMT.csv"
#outdier is the place where users want to save results in
echo output directory is $outdir
head -10 $filename
head -10 $desmat
head -10 $conmat
mkdir -p $outdir
cd $outdir

#assign path to where the midthickness and vertex files are located
HCP_DATA=/external/UBC-TMS
infile=allsubs_merged.dscalar.nii
fname=merge_split
#extracting the first element of sublistids file
exampleSubid=$(head -n 1 ${sublistids})
#first Instance of sublistids file, change these path to approriate path
surfL=${HCP_DATA}/ciftify/${exampleSubid}/MNINonLinear/fsaverage_LR32k/${exampleSubid}.L.midthickness.32k_fs_LR.surf.gii
surfR=${HCP_DATA}/ciftify/${exampleSubid}/MNINonLinear/fsaverage_LR32k/${exampleSubid}.R.midthickness.32k_fs_LR.surf.gii

#stage 1 merge files (do a while loop reading a text file with a lsit of cifti files
mergefiles() {
    args=""
    while read ff
    do
	  args="${args} -cifti $ff"
    done < ${filename} #users need to specify the full path for filename file
    echo $args
    # allsubs_merged.dscalar.nii is the file that PALM will use
    wb_command -cifti-merge ${infile} ${args}
}

#stage 2 separate cifti into gifti
cifti2gifti() {
    wb_command -cifti-separate $infile COLUMN -volume-all ${fname}_sub.nii -metric CORTEX_LEFT ${fname}_L.func.gii -metric CORTEX_RIGHT ${fname}_R.func.gii
    wb_command -gifti-convert BASE64_BINARY ${fname}_L.func.gii ${fname}_L.func.gii
    wb_command -gifti-convert BASE64_BINARY ${fname}_R.func.gii ${fname}_R.func.gii
}

#stage 3 Calculate mean surface
meansurface() {
    MERGELIST=""
    while read subids; do
	  dir='/projects/ttan/UBC-TMS/analysis_LsgACC/PALM/va_files'
	  MERGELIST="${MERGELIST} -metric $dir/${subids}.L.midthick_va.shape.gii";
    done < ${sublistids}

    #wb_command will automatically save results in the current dir, which is outdir
    wb_command -metric-merge L_midthick_va.func.gii ${MERGELIST}
    wb_command -metric-reduce L_midthick_va.func.gii MEAN L_area.func.gii

    MERGELIST=""
    while read subids; do
	  dir='/projects/ttan/UBC-TMS/analysis_LsgACC/PALM/va_files'
	  MERGELIST="${MERGELIST} -metric $dir/${subids}.R.midthick_va.shape.gii";
    done < ${sublistids}

    wb_command -metric-merge R_midthick_va.func.gii ${MERGELIST}
    wb_command -metric-reduce R_midthick_va.func.gii MEAN R_area.func.gii
}

#stage 4: RUN PALM
runpalm() {
    palm -i ${fname}_L.func.gii -d $desmat -t $conmat -o results_L_cort -T -tfce2D -s $surfL L_area.func.gii -logp -n 1000 -ise -precision "double"
    palm -i ${fname}_R.func.gii  -d $desmat -t $conmat -o results_R_cort -T -tfce2D -s $surfR R_area.func.gii -logp -n 1000 -ise -precision "double"
    palm -i ${fname}_sub.nii  -d $desmat -t $conmat -o results_sub -T -logp -n 1000 -ise -precision "double"

    # C1 = positive slope; C2 = negative slope; C3 = positive sex; C4 = negative sex; C5 = positive age; C6 = negative age; C7 = positive preMADRS; C8 = negative preMADRS; C9 = positive prepostMADRS; C10 = negative prepostMADRS;
    # C11 = positive active FD, C12 = negative active FD;

    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c1.dscalar.nii -volume-all results_sub_tfce_tstat_fwep_c1.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c1.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c1.gii
    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c2.dscalar.nii -volume-all results_sub_tfce_tstat_fwep_c2.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c2.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c2.gii
    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c3.dscalar.nii -volume-all results_sub_tfce_tstat_fwep_c3.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c3.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c3.gii
    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c4.dscalar.nii -volume-all results_sub_tfce_tstat_fwep_c4.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c4.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c4.gii
    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c5.dscalar.nii -volume-all results_sub_tfce_tstat_fwep_c5.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c5.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c5.gii
    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c6.dscalar.nii -volume-all results_sub_tfce_tstat_fwep_c6.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c6.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c6.gii
    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c7.dscalar.nii -volume-all results_sub_tfce_tstat_fwep_c7.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c7.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c7.gii
    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c8.dscalar.nii -volume-all results_sub_tfce_tstat_fwep_c8.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c8.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c8.gii
    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c9.dscalar.nii -volume-all results_sub_tfce_tstat_fwep_c9.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c9.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c9.gii
    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c10.dscalar.nii -volume-all results_sub_tfce_tstat_fwep_c10.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c10.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c10.gii
    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c11.dscalar.nii -volume-all results_sub_tfce_tstat_fwep_c11.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c11.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c11.gii
    wb_command -cifti-create-dense-from-template ${infile} results_cort_tfce_tstat_fwep_c12.dscalar.nii -volume-all results_sub_tfce_tstat_fwep_c12.nii -metric CORTEX_LEFT results_L_cort_tfce_tstat_fwep_c12.gii -metric CORTEX_RIGHT results_R_cort_tfce_tstat_fwep_c12.gii

    wb_command -cifti-math '(x-y)' ${fname}_tstat_fwep_c12.dscalar.nii -var x results_cort_tfce_tstat_fwep_c1.dscalar.nii -var y results_cort_tfce_tstat_fwep_c2.dscalar.nii
    wb_command -cifti-math '(x-y)' ${fname}_tstat_fwep_c34.dscalar.nii -var x results_cort_tfce_tstat_fwep_c3.dscalar.nii -var y results_cort_tfce_tstat_fwep_c4.dscalar.nii
    wb_command -cifti-math '(x-y)' ${fname}_tstat_fwep_c56.dscalar.nii -var x results_cort_tfce_tstat_fwep_c5.dscalar.nii -var y results_cort_tfce_tstat_fwep_c6.dscalar.nii
    wb_command -cifti-math '(x-y)' ${fname}_tstat_fwep_c78.dscalar.nii -var x results_cort_tfce_tstat_fwep_c7.dscalar.nii -var y results_cort_tfce_tstat_fwep_c8.dscalar.nii
    wb_command -cifti-math '(x-y)' ${fname}_tstat_fwep_c910.dscalar.nii -var x results_cort_tfce_tstat_fwep_c9.dscalar.nii -var y results_cort_tfce_tstat_fwep_c10.dscalar.nii
    wb_command -cifti-math '(x-y)' ${fname}_tstat_fwep_c1112.dscalar.nii -var x results_cort_tfce_tstat_fwep_c11.dscalar.nii -var y results_cort_tfce_tstat_fwep_c12.dscalar.nii
}
#back to the previous directory

mergefiles &&
    cifti2gifti &&
    meansurface &&
    runpalm
