#!/bin/sh --login
 
# Set the queueing options 
#SBATCH --nodes=60 --ntasks-per-node=4   ## refer to the run_fcst task section in the workflow xml
#SBATCH -t 6:40:00
#SBATCH -A nrtrr
# #SBATCH -qos debug
#SBATCH -J fv3_fcst
#SBATCH --partition=sjet  ## check which jet partition was used from the run_fcst log file in the cycle that needs to be repeated
 
set -x
#-------------------------------------------
# point to the source code for executable and
# for loading the same modules used in the run that needs to be repeated
#-------------------------------------------
SRCDIR=/WHERE-YOUR-ufs-srweather-app-CODE-IS/dev4-ufs-srweather-app
module purge
module use $SRCDIR/regional_workflow/modulefiles/tasks/jet
module load run_fcst
 
FV3_EXE=$SRCDIR/exec/fv3_gfs.x

#-------------------------------------------
# the workdir is a hard copy of the cycle that needs to be repeated, for example, /lfs4/BMC/nrtrr/NCO_dirs/stmp/tmpnwprd/RRFS_dev4/2021010612
# remove the IC/LBC source (HRRRX/, RAPX/), forecast files (dynf*.nc, phyf*.nc), log files (logf*), post and restart files (if applicable) 
# must keep all the fix files and INPUT/ 
#-------------------------------------------
workdir=/WHERE-YOUR-TEST-DIR-IS/2021010612
cd $workdir
rm -f phyf*.nc dynf*.nc logf* 
rm -f fv3_gfs.x
cp ${FV3_EXE} fv3_gfs.x
 
#-------------------------------------------
# submit the job
#-------------------------------------------
srun ./fv3_gfs.x   
 
exit

