#!/bin/bash


# Script downloads the GFS or GEFS files from NOAA's ftp server.
# This script is modified from Rajendra Panda's HWT Exerpimental scritps.

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
# Get the full path to the file in which this script/function is located.
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )

print_info_msg "
========================================================================
Entering script:  \"${scrfunc_fn}\"
In directory:     \"${scrfunc_dir}\"

This is the ex-script for the task that copies/fetches to a local directory.
either from disk or HPSS) the external model files from which initial or.
boundary condition files for the FV3 will be generated.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  Then.
# process the arguments provided to this script/function (which should.
# consist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
valid_args=( \
"extrn_mdl_cdate" \
)
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

set -x

get_files() {

  files=("$@")
  for file in ${files[@]} ; do
    wget $file || exit 1
    wait
  done

}

hh=${extrn_mdl_cdate:8:2}
yyyymmdd=${extrn_mdl_cdate:0:8}
case ${EXTRN_MDL_NAME_ICS} in 

  "FV3GFS")
    urla="https://ftp.ncep.noaa.gov/data/nccf/com/gfs/prod/gfs.${yyyymmdd}/${hh}/atmos"
    urla="https://noaa-gfs-bdp-pds.s3.amazonaws.com/gfs.${yyyymmdd}/${hh}/atmos"
    urlb=$urla
    filea="gfs.t${hh}z.pgrb2.0p25.f0"
    fileb="gfs.t${hh}z.pgrb2b.0p25.f0"
    combined_file=${filea}FHR_tmp
    ;;
  "GEFS")
    urla="https://ftp.ncep.noaa.gov/data/nccf/com/gens/prod/gefs.${yyyymmdd}/${hh}/atmos/pgrb2ap5"
    urlb="https://ftp.ncep.noaa.gov/data/nccf/com/gens/prod/gefs.${yyyymmdd}/${hh}/atmos/pgrb2bp5"
    urla="https://noaa-gefs-pds.s3.amazonaws.com/gefs.${yyyymmdd}/${hh}/atmos/pgrb2ap5"
    urlb="https://noaa-gefs-pds.s3.amazonaws.com/gefs.${yyyymmdd}/${hh}/atmos/pgrb2bp5"
    filea="gep${GEFS_MEMBER}.t${hh}z.pgrb2a.0p50.f0"
    fileb="gep${GEFS_MEMBER}.t${hh}z.pgrb2b.0p50.f0"
    combined_file="gep${GEFS_MEMBER}.t${hh}z.pgrb2.0p50.f0FHR"
    ;;

esac

last_hour=$(( FCST_LEN_HRS + EXTRN_MDL_LBCS_OFFSET_HRS ))
last_hour=$(printf "%02d" $last_hour) 
first_hour=$(( EXTRN_MDL_LBCS_OFFSET_HRS + LBC_SPEC_INTVL_HRS ))
first_hour=$(printf "%02d" $first_hour) 

extrn_mdl_fns=()
bcs_fhrs=($(seq -w $first_hour $LBC_SPEC_INTVL_HRS $last_hour ))

for fhr in ${bcs_fhrs[@]} ; do

  outfile=${combined_file/FHR/$fhr}
  get_files ${urla}/${filea}${fhr} ${urlb}/${fileb}${fhr}
  cat ${filea}${fhr} ${fileb}${fhr} > ${outfile}

  rm -rf ${filea}${fhr} ${fileb}${fhr}

  if [ ${EXTRN_MDL_NAME_ICS} = "FV3GFS" ] ; then

    # Use wgrib2 to remove duplicate entries from the GFS files
    wgrib2 ${combined_file/FHR/$fhr} -submsg 1 | \
      ${USHDIR}/grib2_unique.pl | \
      wgrib2 -i ${combined_file/FHR/$fhr} -GRIB ${outfile/_tmp/}
    rm -rf ${outfile}
  fi

  extrn_mdl_fns+=("${outfile/_tmp/}")
done

var_defs="extrn_mdl_var_defns.sh"
echo EXTRN_MDL_CDATE=$extrn_mdl_cdate > $var_defs
echo EXTRN_MDL_FNS=\( ${extrn_mdl_fns[@]} \) >> $var_defs
echo EXTRN_MDL_LBC_SPEC_FHRS=\( ${bcs_fhrs[@]} \) >> $var_defs

