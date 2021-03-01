MACHINE="LINUX"
ACCOUNT="an_account"
WORKFLOW_MANAGER="rocoto"
SCHED="slurm"

EXPT_BASEDIR="/lustre"
EXPT_SUBDIR="test_community"

RUN_CMD_UTILS="srun --mpi=pmi2"
RUN_CMD_FCST="srun --mpi=pmi2"
RUN_CMD_POST="srun --mpi=pmi2"

NCORES_PER_NODE="36"
PPN_RUN_FCST="18"
LAYOUT_X="4"
LAYOUT_Y="4"
WRTCMP_write_groups="1"
WRTCMP_write_tasks_per_group="2"

PARTITION_DEFAULT=
QUEUE_DEFAULT=
PARTITION_HPSS=
QUEUE_HPSS=
PARTITION_FCST=
QUEUE_FCST=

LMOD_PATH="/apps/lmod/lmod/init/sh"
BUILD_ENV_FN="build_aws_intel.env"

VERBOSE="TRUE"

RUN_ENVIR="community"
PREEXISTING_DIR_METHOD="rename"

PREDEF_GRID_NAME="RRFS_CONUS_25km"
QUILTING="TRUE"

CCPP_PHYS_SUITE="FV3_GFS_v15p2"
FCST_LEN_HRS="48"
LBC_SPEC_INTVL_HRS="6"

DATE_FIRST_CYCL="20190615"
DATE_LAST_CYCL="20190615"
CYCL_HRS=( "00" )

EXTRN_MDL_NAME_ICS="FV3GFS"
EXTRN_MDL_NAME_LBCS="FV3GFS"

FV3GFS_FILE_FMT_ICS="grib2"
FV3GFS_FILE_FMT_LBCS="grib2"

WTIME_RUN_FCST="01:00:00"

# The following are specifically for AWS using Parallel Works
FIXgsm=${FIXgsm:-"/contrib/NCEPDEV/global/glopara/fix/fix_am"}
TOPO_DIR=${TOPO_DIR:-"/contrib/NCEPDEV/global/glopara/fix/fix_orog"}
SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"/contrib/NCEPDEV/global/glopara/fix/fix_sfc_climo"}
FIXLAM_NCO_BASEDIR=${FIXLAM_NCO_BASEDIR:-"/contrib/NCEPDEV/global/glopara/fix/FV3LAM_pregen"}

#
# Uncomment the following line in order to use user-staged external model 
# files with locations and names as specified by EXTRN_MDL_SOURCE_BASEDIR_ICS/
# LBCS and EXTRN_MDL_FILES_ICS/LBCS.
#
USE_USER_STAGED_EXTRN_FILES="TRUE"
#
# The following is specifically for AWS via Parallel Works.  It will have to be
# modified if on another platform, using other dates, other external models, etc.
#
EXTRN_MDL_SOURCE_BASEDIR_ICS="/lustre/model_data/FV3GFS"
EXTRN_MDL_FILES_ICS=( "gfs.pgrb2.0p25.f000" )
EXTRN_MDL_SOURCE_BASEDIR_LBCS="/lustre/model_data/FV3GFS"
EXTRN_MDL_FILES_LBCS=( "gfs.pgrb2.0p25.f006" "gfs.pgrb2.0p25.f012" "gfs.pgrb2.0p25.f018" "gfs.pgrb2.0p25.f024" \
                       "gfs.pgrb2.0p25.f030" "gfs.pgrb2.0p25.f036" "gfs.pgrb2.0p25.f042" "gfs.pgrb2.0p25.f048" )
