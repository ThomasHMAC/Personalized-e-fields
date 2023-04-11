#!/usr/bin/env python

# from ciftify.utils import run, get_stdout, TempDir
"""
Produces a csv file sum dot product from a functional connectivity file <func>,
efield file <efield>, and vertex area file <va>
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
DETAILS:
The default output filename is <dotproduct>_<sum>.csv inside the same directory
as the <func> file. This can be changed by specifying the full path after
the '--outputcsv' option.
Written by Thomas Tan, March 30, 2022 - An adapted version of Erin's Ciftify package
"""
#!/usr/bin/env python
import os
import sys
import argparse
import subprocess
import logging
import numpy as np
import ciftify.utils
import ciftify.niio
import nibabel as nib
from nilearn.surface import load_surf_data
from datetime import datetime

np.set_printoptions(threshold=sys.maxsize)

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

formatter = logging.Formatter("%(asctime)s:%(name)s:%(message)s")
log_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), datetime.now().strftime('dotproduct-%d-%m-%Y.log'))
file_handler = logging.FileHandler(log_path)
file_handler.setLevel(logging.INFO)
file_handler.setFormatter(formatter)

stream_handler = logging.StreamHandler()
stream_handler.setFormatter(formatter)
logger.addHandler(file_handler)
logger.addHandler(stream_handler)


def load_cifti(filename):
    with ciftify.utils.TempDir() as tempdir:
        L_data_surf = os.path.join(tempdir, "Ldata.func.gii")
        R_data_surf = os.path.join(tempdir, "Rdata.func.gii")
        ciftify.utils.run(
            [
                "wb_command",
                "-cifti-separate",
                filename,
                "COLUMN",
                "-metric",
                "CORTEX_LEFT",
                L_data_surf,
                "-metric",
                "CORTEX_RIGHT",
                R_data_surf,
            ]
        )
        # print(os.path.abspath(L_data_surf))
        Ldata = ciftify.niio.load_gii_data(L_data_surf)
        Rdata = ciftify.niio.load_gii_data(R_data_surf)
        cifti_data = np.vstack((Ldata, Rdata))
        return cifti_data


def main():
    parser = argparse.ArgumentParser(description="Run sum dotproduct")
    parser.add_argument(
        "conn_map",
        type=str,
        help="Functional Connectivity map at ROIs in cifti format",
    )
    parser.add_argument("efield_map", type=str, help="Efield map in cifti format")
    parser.add_argument(
        "L_va_map", type=str, help="Vertex area map in Left Hemisphere in gifti format"
    )
    parser.add_argument(
        "R_va_map", type=str, help="Vertex area map in Right Hemisphere in gifti format"
    )
    parser.add_argument("--outputcsv", help="Path to the output filename")
    args = parser.parse_args()
    cifti_conn = args.conn_map
    cifti_efield = args.efield_map
    outputcsv = args.outputcsv
    head, tail = os.path.split(cifti_conn)
    sub_id = tail.split("_")[0]
    L_va = args.L_va_map
    R_va = args.R_va_map
    conn_map = load_cifti(cifti_conn)
    size_conn_map = conn_map.shape
    pos_neg_indices = np.where(conn_map != 0)[0]
    pos_indices = np.where(conn_map > 0)[0]
    neg_indices = np.where(conn_map < 0)[0]
    neg_size = neg_indices.shape[0]
    pos_neg_size = pos_neg_indices.shape[0]
    pos_size = pos_indices.shape[0]
    logger.info(
        f"Subject {sub_id} numbers of negative vertex: {neg_size} \npositive vertex: {pos_size}\nall vertex: {pos_neg_size}"
    )
    # = np.where(conn_map != 0)[0] the 0 at the end indicate the which index the element of array is not 0
    Lva = ciftify.niio.load_gii_data(L_va)
    Rva = ciftify.niio.load_gii_data(R_va)
    va_map = np.vstack((Lva, Rva))
    efield_map = load_cifti(cifti_efield)
    logger.info(f"{efield_map.shape}")
    if conn_map.shape != va_map.shape or conn_map.shape != efield_map.shape:
        logger.info("The number of vertices do not mathch")
        sys.exit()
    else:
        logger.info("Number of vertices match")
    conn_neg_dat = conn_map[neg_indices]
    va_neg_dat = va_map[neg_indices]
    efield_neg_dat = efield_map[neg_indices]

    # vertex area weighted
    area_weighted_neg = va_neg_dat / va_neg_dat.sum()
    # computation of connectivity by efield by vertex area
    byproduct_neg = conn_neg_dat * efield_neg_dat * area_weighted_neg
    sum_byproduct_neg = byproduct_neg.sum()
    out_data_neg = np.zeros((1, 1))
    out_data_neg[0, :] = sum_byproduct_neg
    logger.info(
        f"Subject {sub_id} sum value of dotproduct with all negative vertices: {out_data_neg}"
    )
    if not outputcsv:
        outputdir = os.path.dirname(cifti_conn)
        outputcsv = os.path.join(outputdir, sub_id + "_" + "dotproduct_sum.csv")
        np.savetxt(outputcsv, np.c_[out_data_neg], delimiter=",")
    if outputcsv:
        np.savetxt(outputcsv, np.c_[out_data_neg], delimiter=",")


if __name__ == "__main__":
    main()
