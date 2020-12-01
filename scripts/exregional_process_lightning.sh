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

This is the ex-script for the task that runs radar reflectivity preprocess
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
  LD_LIBRARY_PATH="${UFS_WTHR_MDL_DIR}/FV3/ccpp/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  ;;
#
"JET")
  ulimit -s unlimited
  ulimit -a
  APRUN="srun"
  LD_LIBRARY_PATH="${UFS_WTHR_MDL_DIR}/FV3/ccpp/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
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

YYJJJHH=`date +"%y%j%H" -d "${START_DATE}"`
PREYYJJJHH=`date +"%y%j%H" -d "${START_DATE} 1 hours ago"`

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
rectory for lightning  process ..."


# Create directory.

cd ${WORKDIR}

fixdir=$FIXgsi/

print_info_msg "$VERBOSE" "fixdir is $fixdir"

#
#-----------------------------------------------------------------------
#
# link or copy background files
#
#-----------------------------------------------------------------------

cp_vrfy ${fixdir}/fv3_grid_spec          fv3sar_grid_spec.nc
cp_vrfy ${fixdir}/geo_em.d01.nc          geo_em.d01.nc


#
# Link to the NLDN data
#
#-----------------------------------------------------------------------
filenum=0
LIGHTNING_FILE=${LIGHTNING_ROOT}/vaisala/netcdf
if [ -r "${LIGHTNING_FILE}/${YYJJJHH}050005r" ]; then
  ((filenum += 1 ))
  ln -sf ${LIGHTNING_FILE}/${YYJJJHH}050005r ./NLDN_lightning_${filenum}
else
   echo " ${LIGHTNING_FILE}/${YYJJJHH}050005r does not exist"
fi
if [ -r "${LIGHTNING_FILE}/${YYJJJHH}000005r" ]; then
  ((filenum += 1 ))
  ln -sf ${LIGHTNING_FILE}/${YYJJJHH}000005r ./NLDN_lightning_${filenum}
else
   echo " ${LIGHTNING_FILE}/${YYJJJHH}000005r does not exist"
fi
if [ -r "${LIGHTNING_FILE}/${PREYYJJJHH}550005r" ]; then
  ((filenum += 1 ))
  ln -sf ${LIGHTNING_FILE}/${PREYYJJJHH}550005r ./NLDN_lightning_${filenum}
else
   echo " ${LIGHTNING_FILE}/${PREYYJJJHH}550005r does not exist"
fi
if [ -r "${LIGHTNING_FILE}/${PREYYJJJHH}500005r" ]; then
  ((filenum += 1 ))
  ls ${LIGHTNING_FILE}/${PREYYJJJHH}500005r
  ln -sf ${LIGHTNING_FILE}/${PREYYJJJHH}500005r ./NLDN_lightning_${filenum}
else
   echo " ${LIGHTNING_FILE}/${PREYYJJJHH}500005r does not exist"
fi
if [ ! 0 ] ; then
if [ -r "${LIGHTNING_FILE}/${PREYYJJJHH}450005r" ]; then
  ((filenum += 1 ))
  ln -sf ${LIGHTNING_FILE}/${PREYYJJJHH}450005r ./NLDN_lightning_${filenum}
else
   echo " ${LIGHTNING_FILE}/${PREYYJJJHH}450005r does not exist"
fi
if [ -r "${LIGHTNING_FILE}/${PREYYJJJHH}400005r" ]; then
  ((filenum += 1 ))
  ln -sf ${LIGHTNING_FILE}/${PREYYJJJHH}400005r ./NLDN_lightning_${filenum}
else
   echo " ${LIGHTNING_FILE}/${PREYYJJJHH}400005r does not exist"
fi
if [ -r "${LIGHTNING_FILE}/${PREYYJJJHH}350005r" ]; then
  ((filenum += 1 ))
  ln -sf ${LIGHTNING_FILE}/${PREYYJJJHH}350005r ./NLDN_lightning_${filenum}
else
   echo " ${LIGHTNING_FILE}/${PREYYJJJHH}350005r does not exist"
fi
fi

echo "found GLD360 files: ${filenum}"



#-----------------------------------------------------------------------
#
#   copy bufr table
#
#-----------------------------------------------------------------------
BUFR_TABLE=${fixdir}/prepobs_prep_RAP.bufrtable

# Fixed fields
cp_vrfy $BUFR_TABLE prepobs_prep.bufrtable

#-----------------------------------------------------------------------
#
# Build namelist and run executable
#
#-----------------------------------------------------------------------

cat << EOF > mosaic.namelist
 &setup
  analysis_time = ${YYYYMMDDHH},
  NLDN_filenum  = ${filenum},
  IfAlaska    = false,
  bkversion=1,
 /

EOF

#
#-----------------------------------------------------------------------
#
# Copy the executable to the run directory.
#
#-----------------------------------------------------------------------
#
EXEC="${EXECDIR}/process_Lightning_nc.exe"

if [ -f $EXEC ]; then
  print_info_msg "$VERBOSE" "
Copying the lightning process  executable to the run directory..."
  cp_vrfy ${EXEC} ${WORKDIR}/process_Lightning_nc.exe
else
  print_err_msg_exit "\
The executable specified in EXEC does not exist:
  EXEC = \"$EXEC\"
Build lightning process and rerun."
fi
#
#
#-----------------------------------------------------------------------
#
# Run the process
#
#-----------------------------------------------------------------------
#
$APRUN ./process_Lightning_nc.exe < mosaic.namelist > stdout 2>&1 || print_err_msg_exit "\
Call to executable to run radar refl process returned with nonzero exit code."
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
RADAR REFL PROCESS completed successfully!!!

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

