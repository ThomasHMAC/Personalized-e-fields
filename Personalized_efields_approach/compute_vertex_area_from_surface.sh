#!/bin/bash
### Compute the adjacency(neighbourhood) information between vertices from the surfaces
module load connectome-workbench/1.4.1
base_dir='/external/UBC-TMS/ciftify'
outdir='/projects/ttan/UBC-TMS/analysis_LsgACC/PALM/va_files'
sublist='/projects/ttan/UBC-TMS/analysis_LsgACC/PALM/sublist_MADRS_34_subs.txt'
mkdir -p ${outdir}
while read subid;
do
for id in L R;
do
wb_command -surface-vertex-areas ${base_dir}/${subid}/MNINonLinear/fsaverage_LR32k/${subid}.${id}.midthickness.32k_fs_LR.surf.gii \
                                 ${outdir}/${subid}.${id}.midthick_va.shape.gii
echo ${subid} done
done
done < ${sublist}
