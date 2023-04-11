#!/usr/bin/env python
import pandas as pd
#import simnibs.msh.transformations as transformations
import os
import csv
import numpy as np
from string import Template
import subprocess


# List of participants
with open('/projects/ttan/UBC-TMS/analysis/RDLPFC_20mm_sphere/rerun_sublist.txt') as file:
    subids = file.readlines()
subs = [x.strip() for x in subids]

# MNI coordinates for TMS target region
MNI_coords_template = "/projects/ttan/UBC-TMS/analysis/RDLPFC_20mm_sphere/MNI_coordinates.txt"

# Loop through each subject and generating the number and location of vertex closest to target region
for sub_id in subs:	
    R_surf_template = Template("/projects/ttan/UBC-TMS/in_progress/ciftify/${ID}/MNINonLinear/fsaverage_LR32k/${ID}.R.pial.32k_fs_LR.surf.gii")
    #
    vertex_out_template = Template("/projects/ttan/UBC-TMS/analysis/RDLPFC_20mm_sphere/${ID}_closest_vertex_num.csv")
    R_surf = R_surf_template.substitute(ID=sub_id)
    vertex_out = vertex_out_template.substitute(ID=sub_id)
    wb_command = ["wb_command", "-surface-closest-vertex",
                R_surf,
                MNI_coords_template,
                vertex_out]
    subprocess.call(wb_command)

    dummy_file = '/projects/ttan/UBC-TMS/analysis/RDLPFC_20mm_sphere/ROIs/{}_vertex_hemi.csv'.format(sub_id)
    with open(vertex_out, 'r') as read_obj, open(dummy_file,'w', newline=None) as write_obj:
        write_obj.write("vertex,hemi")
        for line in read_obj:
            line = line.rstrip() + ",R"
            print(line)
            write_obj.write('\n' + line)
    subprocess.call(["rm", vertex_out])
