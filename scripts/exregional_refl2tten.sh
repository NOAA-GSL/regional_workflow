#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions file and the bash utility functions.
#
#-----------------------------------------------------------------------
#
. ${GLOBAL_VAR_DEFNS_FP}
. $USHDIR/source_util_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u +x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located 
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# Print message indicating entry into script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"

This is the ex-script for the task that generates radar reflectivity tten
with FV3 for the specified cycle.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  
# Then process the arguments provided to this script/function (which 
# should consist of a set of name-value pairs of the form arg1="value1",
# etc).
#
#-----------------------------------------------------------------------
#
valid_args=( "CYCLE_DIR" "WORKDIR")
process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# For debugging purposes, print out values of arguments passed to this
# script.  Note that these will be printed out only if VERBOSE is set to
# TRUE.
#
#-----------------------------------------------------------------------
#
print_input_args valid_args
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
case $MACHINE in
#
"WCOSS_C" | "WCOSS")
#

  if [ "${USE_CCPP}" = "TRUE" ]; then
  
# Needed to change to the experiment directory because the module files
# for the CCPP-enabled version of FV3 have been copied to there.

    cd_vrfy ${CYCLE_DIR}
  
    set +x
    source ./module-setup.sh
    module use $( pwd -P )
    module load modules.fv3
    module list
    set -x
  
  else
  
    . /apps/lmod/lmod/init/sh
    module purge
    module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/soft/modulefiles
    module load intel/16.1.150 impi/5.1.1.109 netcdf/4.3.0 
    module list
  
  fi

  ulimit -s unlimited
  ulimit -a
  APRUN="mpirun -l -np ${PE_MEMBER01}"
  ;;
#
"HERA")
  ulimit -s unlimited
  ulimit -a
  APRUN="srun"
#  LD_LIBRARY_PATH="${UFS_WTHR_MDL_DIR}/FV3/ccpp/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  ;;
#
"JET")
  ulimit -s unlimited
  ulimit -a
  APRUN="srun"
#  LD_LIBRARY_PATH="${UFS_WTHR_MDL_DIR}/FV3/ccpp/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  ;;
#
"ODIN")
#
  module list

  ulimit -s unlimited
  ulimit -a
  APRUN="srun -n ${PE_MEMBER01}"
  ;;
#
esac
#
#-----------------------------------------------------------------------
#
# Extract from CDATE the starting year, month, day, and hour of the
# forecast.  These are needed below for various operations.
#
#-----------------------------------------------------------------------
#
set -x
START_DATE=`echo "${CDATE}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/'`
YYYYMMDDHH=`date +%Y%m%d%H -d "${START_DATE}"`
JJJ=`date +%j -d "${START_DATE}"`

YYYY=${YYYYMMDDHH:0:4}
MM=${YYYYMMDDHH:4:2}
DD=${YYYYMMDDHH:6:2}
HH=${YYYYMMDDHH:8:2}
YYYYMMDD=${YYYYMMDDHH:0:8}
#
#-----------------------------------------------------------------------
#
# Create links in the subdirectory of the current cycle's run di-
# rectory for radar reflectivity process.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "
Creating links in the subdirectory of the current cycle's run di-
rectory for radar reflectivity process ..."


# Create directory.

workdir=${WORKDIR}
cd_vrfy ${workdir}

fixdir=$FIXgsi/$PREDEF_GRID_NAME
print_info_msg "$VERBOSE" "fixdir is $fixdir"
pwd

#
#-----------------------------------------------------------------------
#
# link or copy background files
#
#-----------------------------------------------------------------------

cp_vrfy ${fixdir}/fv3_akbk                               fv3_akbk
cp_vrfy ${fixdir}/fv3_grid_spec                          fv3_grid_spec

bkpath=${CYCLE_DIR}/INPUT
if [ -w ${bkpath}/gfs_data.tile7.halo0.nc ]; then  # Use background from INPUT
  ln_vrfy -s ${bkpath}/sfc_data.tile7.halo0.nc      fv3_sfcdata
  ln_vrfy -s ${bkpath}/gfs_data.tile7.halo0.nc      fv3_dynvars
  ln_vrfy -s ${bkpath}/gfs_data.tile7.halo0.nc      fv3_tracer
else
  ln_vrfy -s ${bkpath}/fv_core.res.tile1.nc         fv3_dynvars
  ln_vrfy -s ${bkpath}/fv_tracer.res.tile1.nc       fv3_tracer
  ln_vrfy -s ${bkpath}/sfc_data.nc                  fv3_sfcdata
fi

#
#-----------------------------------------------------------------------
#
# link observation files
# copy observation files to working directory 
#
#-----------------------------------------------------------------------

# Link to the radar binary data
PROCESS_RADARREF_PATH=${CYCLE_DIR}/PROCESS_RADARREF
#subhtimes="15 30 45 60"
#count=1
#for subhtime in ${subhtimes}; do
#  if [ -r "${PROCESS_RADARREF_PATH}/RefInGSI3D.dat" ]; then
#    ${LN} -s ${PROCESS_RADARREF_PATH}/RefInGSI3D.dat ./RefInGSI3D.dat_0${count}
#  else
#    ${ECHO} "Warning ${PROCESS_RADARREF_PATH}/${subhtime}/RefInGSI3D.dat does not exist!"
#  fi
#  count=$((count + 1))
#done
ln -s ${PROCESS_RADARREF_PATH}/RefInGSI3D.dat ./RefInGSI3D.dat_01

#-----------------------------------------------------------------------
#
# Create links to fix files in the FIXgsi directory.
# Set fixed files
#   BUFR_TABLE= bufr table for sst ONLY needed for sst retrieval (retrieval=.true.)
#
#-----------------------------------------------------------------------
BUFR_TABLE=${fixdir}/prepobs_prep_RAP.bufrtable

# Fixed fields
cp_vrfy $BUFR_TABLE prepobs_prep.bufrtable

#-----------------------------------------------------------------------
#
# Build namelist and run GSI
#
#-----------------------------------------------------------------------

#
#-----------------------------------------------------------------------
#
# Copy the GSI executable to the run directory.
#
#-----------------------------------------------------------------------
#
EXEC="${EXECDIR}/ref2ttenfv3sar.exe"

if [ -f $EXEC ]; then
  print_info_msg "$VERBOSE" "
Copying the radar refl tten  executable to the run directory..."
  cp_vrfy ${EXEC} ${workdir}/ref2ttenfv3sar.exe
else
  print_err_msg_exit "\
The GSI executable specified in EXEC does not exist:
  EXEC = \"$EXEC\"
Build radar refl tten and rerun."
fi
#
#-----------------------------------------------------------------------
#
# Set and export variables.
#
#-----------------------------------------------------------------------
#
#
#-----------------------------------------------------------------------
#
# Run the GSI.  Note that we have to launch the forecast from
# the current cycle's run directory because the GSI executable will look
# for input files in the current directory.
#
#-----------------------------------------------------------------------
#
$APRUN ./ref2ttenfv3sar.exe > stdout 2>&1 || print_err_msg_exit "\
Call to executable to run radar refl tten returned with nonzero exit code."

#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
RADAR REFL TTEN PROCESS completed successfully!!!

Exiting script:  \"${scrfunc_fn}\"
In directory:    \"${scrfunc_dir}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

