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
{ save_shell_opts; set -u -x; } > /dev/null 2>&1
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

This is the ex-script for the task that runs a analysis with FV3 for the
specified cycle.
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
valid_args=( "CYCLE_DIR" "ANALWORKDIR" "FG_ROOT")
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
"THEIA")
#

  if [ "${USE_CCPP}" = "TRUE" ]; then
  
# Need to change to the experiment directory to correctly load necessary 
# modules for CCPP-version of FV3LAM in lines below
    cd_vrfy ${EXPTDIR}
  
    set +x
    source ./module-setup.sh
    module use $( pwd -P )
    module load modules.fv3
    module load contrib wrap-mpi
    module list
    set -x
  
  else
  
    . /apps/lmod/lmod/init/sh
    module purge
    module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/soft/modulefiles
    module load intel/16.1.150 impi/5.1.1.109 netcdf/4.3.0 
    module load contrib wrap-mpi 
    module list
  
  fi

  ulimit -s unlimited
  ulimit -a
  np=${SLURM_NTASKS}
  APRUN="mpirun -np ${np}"
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
  NCKS=ncks
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
# Extract the valid time of the restart files
#
#-----------------------------------------------------------------------
#
ANAL_HH=${ANAL_DATE:8:2}
ANAL_YYYYMMDD=${ANAL_DATE:0:8}
#
#-----------------------------------------------------------------------
#
# go to working directory.
# define fix and background path
#
#-----------------------------------------------------------------------

cd_vrfy ${ANALWORKDIR}

fixgriddir=$FIX_GSI/${PREDEF_GRID_NAME}

print_info_msg "$VERBOSE" "FIX_GSI is $FIX_GSI"
print_info_msg "$VERBOSE" "fixgriddir is $fixgriddir"

#
#-----------------------------------------------------------------------
#
# link observation files
# copy observation files to working directory 
#
#-----------------------------------------------------------------------

obs_files_source[0]=${OBSPATH}/${ANAL_DATE}.rap.t${ANAL_HH}z.prepbufr.tm00
obs_files_target[0]=prepbufr

obs_files_source[1]=${OBSPATH}/${ANAL_DATE}.rap.t${HH}z.satwnd.tm00.bufr_d
obs_files_target[1]=satwndbufr

#obs_files_source[2]=${OBSPATH}/${ANAL_DATE}.rap.t${HH}z.nexrad.tm00.bufr_d
#obs_files_target[2]=l2rwbufr

obs_number=${#obs_files_source[@]}
for (( i=0; i<${obs_number}; i++ ));
do
  obs_file=${obs_files_source[$i]}
  obs_file_t=${obs_files_target[$i]}
  if [ -r "${obs_file}" ]; then
    ln -s "${obs_file}" "${obs_file_t}"
  else
    print_info_msg "$VERBOSE" "Warning: ${obs_file} does not exist!"
  fi
done

#-----------------------------------------------------------------------
#
# Create links to fix files in the FIXgsi directory.
# Set fixed files
#   berror   = forecast model background error statistics
#   specoef  = CRTM spectral coefficients
#   trncoef  = CRTM transmittance coefficients
#   emiscoef = CRTM coefficients for IR sea surface emissivity model
#   aerocoef = CRTM coefficients for aerosol effects
#   cldcoef  = CRTM coefficients for cloud effects
#   satinfo  = text file with information about assimilation of brightness temperatures
#   satangl  = angle dependent bias correction file (fixed in time)
#   pcpinfo  = text file with information about assimilation of prepcipitation rates
#   ozinfo   = text file with information about assimilation of ozone data
#   errtable = text file with obs error for conventional data (regional only)
#   convinfo = text file with information about assimilation of conventional data
#   bufrtable= text file ONLY needed for single obs test (oneobstest=.true.)
#   bftab_sst= bufr table for sst ONLY needed for sst retrieval (retrieval=.true.)
#
#-----------------------------------------------------------------------

anavinfo=${FIX_GSI}/anavinfo_fv3lam_hrrr
BERROR=${FIX_GSI}/rap_berror_stats_global_RAP_tune
SATINFO=${FIX_GSI}/global_satinfo.txt
#CONVINFO=${fixgriddir}/nam_regional_convinfo_RAP.txt
CONVINFO=${fixgriddir}/HRRRENS_regional_convinfo.3km.txt
OZINFO=${FIX_GSI}/global_ozinfo.txt
PCPINFO=${FIX_GSI}/global_pcpinfo.txt
#OBERROR=${FIX_GSI}/nam_errtable.r3dv
OBERROR=${FIX_GSI}/HRRRENS_errtable.r3dv
ATMS_BEAMWIDTH=${FIX_GSI}/atms_beamwidth.txt

# Fixed fields
cp_vrfy "${anavinfo}" "anavinfo"
cp_vrfy "${BERROR}"   "berror_stats"
cp_vrfy $SATINFO  satinfo
cp_vrfy $CONVINFO convinfo
cp      $OZINFO   ozinfo
cp      $PCPINFO  pcpinfo
cp_vrfy $OBERROR  errtable
cp_vrfy $ATMS_BEAMWIDTH atms_beamwidth.txt

cp_vrfy ${FIX_GSI}/hybens_info_rrfs hybens_info

# Get aircraft reject list and surface uselist
cp_vrfy ${AIRCRAFT_REJECT}/current_bad_aircraft.txt current_bad_aircraft

sfcuselists=gsd_sfcobs_uselist.txt
sfcuselists_path=${SFCOBS_USELIST}
cp_vrfy ${sfcuselists_path}/${sfcuselists} gsd_sfcobs_uselist.txt
cp_vrfy ${FIX_GSI}/gsd_sfcobs_provider.txt gsd_sfcobs_provider.txt


#-----------------------------------------------------------------------
#
# CRTM Spectral and Transmittance coefficients
#
#-----------------------------------------------------------------------
CRTMFIX=${FIX_CRTM}
emiscoef_IRwater=${CRTMFIX}/Nalli.IRwater.EmisCoeff.bin
emiscoef_IRice=${CRTMFIX}/NPOESS.IRice.EmisCoeff.bin
emiscoef_IRland=${CRTMFIX}/NPOESS.IRland.EmisCoeff.bin
emiscoef_IRsnow=${CRTMFIX}/NPOESS.IRsnow.EmisCoeff.bin
emiscoef_VISice=${CRTMFIX}/NPOESS.VISice.EmisCoeff.bin
emiscoef_VISland=${CRTMFIX}/NPOESS.VISland.EmisCoeff.bin
emiscoef_VISsnow=${CRTMFIX}/NPOESS.VISsnow.EmisCoeff.bin
emiscoef_VISwater=${CRTMFIX}/NPOESS.VISwater.EmisCoeff.bin
emiscoef_MWwater=${CRTMFIX}/FASTEM6.MWwater.EmisCoeff.bin
aercoef=${CRTMFIX}/AerosolCoeff.bin
cldcoef=${CRTMFIX}/CloudCoeff.bin

ln -s ${emiscoef_IRwater} Nalli.IRwater.EmisCoeff.bin
ln -s $emiscoef_IRice ./NPOESS.IRice.EmisCoeff.bin
ln -s $emiscoef_IRsnow ./NPOESS.IRsnow.EmisCoeff.bin
ln -s $emiscoef_IRland ./NPOESS.IRland.EmisCoeff.bin
ln -s $emiscoef_VISice ./NPOESS.VISice.EmisCoeff.bin
ln -s $emiscoef_VISland ./NPOESS.VISland.EmisCoeff.bin
ln -s $emiscoef_VISsnow ./NPOESS.VISsnow.EmisCoeff.bin
ln -s $emiscoef_VISwater ./NPOESS.VISwater.EmisCoeff.bin
ln -s $emiscoef_MWwater ./FASTEM6.MWwater.EmisCoeff.bin
ln -s $aercoef  ./AerosolCoeff.bin
ln -s $cldcoef  ./CloudCoeff.bin


# Copy CRTM coefficient files based on entries in satinfo file
for file in `awk '{if($1!~"!"){print $1}}' ./satinfo | sort | uniq` ;do
   ln -s ${CRTMFIX}/${file}.SpcCoeff.bin ./
   ln -s ${CRTMFIX}/${file}.TauCoeff.bin ./
done

#
#-----------------------------------------------------------------------
#
# Copy the GSI executable to the run directory.
#
#-----------------------------------------------------------------------
#
GSI_EXEC="${EXECDIR}/gsi.x"
 
if [ -f $GSI_EXEC ]; then
  print_info_msg "$VERBOSE" "
Copying the GSI executable to the run directory..."
  cp_vrfy ${GSI_EXEC} ${ANALWORKDIR}/gsi.x
else
  print_err_msg_exit "\
The GSI executable specified in GSI_EXEC does not exist:
  GSI_EXEC = \"$GSI_EXEC\"
Build GSI and rerun."
fi

#-----------------------------------------------------------------------
#
# set default values for namelist
#
#-----------------------------------------------------------------------

cloudanalysistype=0
ifsatbufr=.false.
ifsoilnudge=.false.
beta1_inv=1.0
ifhyb=.false.
grid_ratio=1

#
#-----------------------------------------------------------------------
# Loop over the ensemble members and run GSI without minimization to get the diag files
#-----------------------------------------------------------------------
#
ensmem=1
while [[ $ensmem -le ${NUM_ENS_MEMBERS} ]];do
rm -f pe0*

if [ ${BKTYPE} -eq 1 ]; then  # cold start, use background from INPUT
  bkpath=${CYCLE_DIR}/mem${ensmem}/INPUT
else
  bkpath=${FG_ROOT}/${YYYYMMDDHH}/mem${ensmem}/RESTART  # cycling, use background from RESTART
fi

print_info_msg "$VERBOSE" "default bkpath is $bkpath"

#
#-----------------------------------------------------------------------
# Use member1 as the reference state to ensure the use of the same set of observations
#-----------------------------------------------------------------------
#

if [ $ensmem == 1 ]; then
  lread_obs_save=.true.
  lread_obs_skip=.false.
else
  lread_obs_save=.false.
  lread_obs_skip=.true.
fi

#
#-----------------------------------------------------------------------
#
# link or copy background and grib configuration files
#
#  Using ncks to add phis (terrain) into cold start input background. 
#           it is better to change GSI to use the terrain from fix file.
#  Adding radar_tten array to fv3_tracer. Should remove this after add this array in
#           radar_tten converting code.
#-----------------------------------------------------------------------

cp_vrfy ${fixgriddir}/fv3_akbk                     fv3_akbk
cp_vrfy ${fixgriddir}/fv3_grid_spec                fv3_grid_spec

if [ ${BKTYPE} -eq 1 ]; then  # cold start uses background from INPUT
  cp_vrfy ${bkpath}/gfs_data.tile7.halo0.nc        gfs_data.tile7.halo0.nc_b
  ${NCKS} -A -v  phis ${fixgriddir}/phis.nc        gfs_data.tile7.halo0.nc_b

  cp_vrfy ${bkpath}/sfc_data.tile7.halo0.nc        fv3_sfcdata
  cp_vrfy gfs_data.tile7.halo0.nc_b                fv3_dynvars
  ln_vrfy -s fv3_dynvars                           fv3_tracer

  fv3lam_bg_type=1
# update times in coupler.res to current cycle time
 cp_vrfy ${fixgriddir}/fv3_coupler.res          coupler.res
 sed -i "s/yyyy/${YYYY}/" coupler.res
 sed -i "s/mm/${MM}/"     coupler.res
 sed -i "s/dd/${DD}/"     coupler.res
 sed -i "s/hh/${HH}/"     coupler.res
else                          # cycle uses background from restart
#   let us figure out which backgound is available
  
  restart_prefix=${ANAL_YYYYMMDD}.${ANAL_HH}0000.
  checkfile=${bkpath}/${restart_prefix}fv_core.res.tile1.nc
  if [ -r "${checkfile}" ]; then
    print_info_msg "$VERBOSE" "Found ${checkfile}; Use it as background for analysis "
    cp_vrfy  ${bkpath}/${restart_prefix}fv_core.res.tile1.nc             fv3_dynvars
    cp_vrfy  ${bkpath}/${restart_prefix}fv_tracer.res.tile1.nc           fv3_tracer
    cp_vrfy  ${bkpath}/${restart_prefix}sfc_data.nc                      fv3_sfcdata
    cp_vrfy  ${bkpath}/${restart_prefix}coupler.res                      coupler.res
  else
    print_err_msg_exit "$VERBOSE" "Error: cannot find background: ${checkfile}"
  fi
  fv3lam_bg_type=0
fi

#
# Build namelist and run GSI
#
#-----------------------------------------------------------------------
# Link the AMV bufr file
ifsatbufr=.false.

# Build the GSI namelist on-the-fly
. ${fixgriddir}/gsiparm.anl.sh
cat << EOF > gsiparm.anl
$gsi_namelist
EOF

#
#-----------------------------------------------------------------------
#
# Run the GSI. 
#
#-----------------------------------------------------------------------
#
$APRUN ./gsi.x < gsiparm.anl > stdout 2>&1 || print_err_msg_exit "\
Call to executable to run GSI returned with nonzero exit code."
#
ls -l * > list_run_directory_mem000${ensmem}
#
mv stdout stdout_mem000${ensmem}
mv gsiparm.anl gsiparm.anl_mem000${ensmem}
rm -f pe*.obs_setup

#-----------------------------------------------------------------------
# Loop over first and last outer loops to generate innovation
# diagnostic files for indicated observation types (groups)
#
# NOTE:  Since we set miter=2 in GSI namelist SETUP, outer
#        loop 03 will contain innovations with respect to 
#        the analysis.  Creation of o-a innovation files
#        is triggered by write_diag(3)=.true.  The setting
#        write_diag(1)=.true. turns on creation of o-g
#        innovation files.
#-----------------------------------------------------------------------
#

netcdf_diag=${netcdf_diag:-".false."}
binary_diag=${binary_diag:-".true."}

loops="01"
for loop in $loops; do

case $loop in
  01) string=ges;;
  03) string=anl;;
   *) string=$loop;;
esac

#  Collect diagnostic files for obs types (groups) below
if [ $binary_diag = ".true." ]; then
   listall=`ls pe* | cut -f2 -d"." | awk '{print substr($0, 0, length($0)-3)}' | sort | uniq `
   for type in $listall; do
      count=`ls pe*.${type}_${loop} | wc -l`
      if [[ $count -gt 0 ]]; then
         `cat pe*.${type}_${loop} > diag_${type}_${string}.mem000${ensmem}`
      fi
   done
fi

done

rm -f fv3_dynvars fv3_tracer fv3_sfcdata

# next member
   (( ensmem += 1 ))

done

# Delete/Unlink unneeded files
rm -f obs*
rm -f pe*
find *.bin -maxdepth 1 -exec unlink '{}' \;

#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
ANALYSIS GSI completed successfully!!!

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

