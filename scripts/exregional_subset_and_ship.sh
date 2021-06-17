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
scrfunc_fp=$( $READLINK -f "${BASH_SOURCE[0]}" )
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

This is the ex-script for the task that uses wgrib2 to subset the grib2
files, rename them, and upload to the S3 Bucket.
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
valid_args=( \
"input_dir" \
"output_dir" \
"fhr" \
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

check_upload() {

  local file_path file_size stat

  stat=$1
  file_path=$2

  file_size=$(stat --printf=%s $post_path)
  if [ "$stat" -ne 0 ] ; then
    echo File $file_path was NOT uploaded to the bucket successfully.
    exit $stat
  else
    echo $file_path was uploaded to the bucket with file size $file_size.
  fi

}


yyyymmdd=${CDATE:0:8}
hh=${CDATE:8:2}

# Define the output grid
#----------------------------------------------------------------------
gridspecs="lambert:262.5:38.5:38.5 237.280:1799:3000 21.138:1059:3000"

# Set the needed variables
#----------------------------------------------------------------------
bucket=noaa-rrfs-pds
s3_post_grib_pfx="s3://${bucket}/rrfs.${yyyymmdd}/${hh}/mem0${MEMBER}"

fhr3=$(printf "%03d" $fhr)
fhr2=$(printf "%02d" $fhr)

s3_file=rrfs.t${hh}z.mem${MEMBER}.na${fhr3}
s3_reduce_file=rrfs.t${hh}z.mem${MEMBER}1.testbed.conusf${fhr3}.grib2

post_file=PRSLEV.GrbF${fhr2}
post_path=${input_dir}/${post_file}

post_tmp_file=PRSLEV.GrbF${fhr2}.tmp

# This file contains the set of grib variables to include in the subset
#----------------------------------------------------------------------
fields_file=/contrib/rpanda/parm/testbed.txt



#----------------------------------------------------------------------
#----------------------------------------------------------------------


# Copy the post file to S3 file as-is
#----------------------------------------------------------------------
source /contrib/.aws/bdp.key

post_stat=$(echo aws s3 cp ${post_path} ${s3_post_grib_pfx}/${s3_file})

# Check the contents of the grib file
#----------------------------------------------------------------------
wgrib2 -v $post_path  > tmp.txt
if [ "$?" -ne 0 ]; then
  echo "$post_path did not validate; skipping upload to S3"
  wait # Let the post file finish upload before exiting
  check_upload $post_stat $post_path
  exit 1
fi

# Subset the large file on a new grid first, then a subset of variables
#----------------------------------------------------------------------

# Writes to a temporary file: post_tmp_file
wgrib2 $post_path -set_bitmap 1 -set_grib_type c3 -new_grid_winds grid \
    -new_grid $gridspecs $post_tmp_file > /dev/null


# Input is tmp file, output to the final file: post_tmp_file
wgrib2 ${post_tmp_file} | \
  grep -F -f ${fields_file} | \
  wgrib2 -i -grib ${s3_reduce_file} ${post_tmp_file}

post_reduce_stat=$(echo aws s3 cp ${s3_reduce_file} ${s3_post_grib_pfx}/${s3_reduce_file})
wait

# Report on upload status
#----------------------------------------------------------------------
check_upload $post_stat $post_path
check_upload $post_reduce_stat $s3_reduce_file

#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "
========================================================================
Post-processing for forecast hour $fhr completed successfully.

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

