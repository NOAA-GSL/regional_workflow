#!/bin/bash -l

source /lustre/harrop/FFAIR/ufs-srweather-app/env/build_aws_intel.env
source /lustre/harrop/FFAIR/ufs-srweather-app/env/wflow_aws.env
module use /contrib/apps/modules
module load rocoto

for i in `seq 1 9`; do
    rocotorun -w /lustre/harrop/FFAIR/RRFS_mem0${i}/FV3LAM_wflow.xml -d /lustre/harrop/FFAIR/RRFS_mem0${i}/FV3LAM_wflow.db -v 10
done
