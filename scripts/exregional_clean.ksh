#!/bin/ksh --login

currentime=`date`

. ${GLOBAL_VAR_DEFNS_FP}

# Delete run directories
deletetime=`date +%Y%m%d%H -d "${currentime} 72 hours ago"`
echo "Deleting directories before ${deletetime}..."
cd ${EXPTDIR}
set -A XX `ls -d 20* | sort -r`
for onetime in ${XX[*]};do
  if [[ ${onetime} -le ${deletetime} ]]; then
    rm -rf ${EXPTDIR}/${onetime}
    echo "Deleted ${EXPTDIR}/${onetime}"
  fi
done

# Delete netCDF files
deletetime=`date +%Y%m%d%H -d "${currentime} 24 hours ago"`
echo "Deleting netCDF files before ${deletetime}..."
cd ${EXPTDIR}
set -A XX `ls -d 20* | sort -r`
for onetime in ${XX[*]};do
  if [[ ${onetime} -le ${deletetime} ]]; then
    rm -f ${EXPTDIR}/${onetime}/phy*nc
    rm -f ${EXPTDIR}/${onetime}/dyn*nc
    rm -rf ${EXPTDIR}/${onetime}/RESTART
    rm -rf ${EXPTDIR}/${onetime}/INPUT
    echo "Deleted netCDF files in ${EXPTDIR}/${onetime}"
  fi
done

# Delete old log files
deletetime=`date +%Y%m%d%H -d "${currentime} 48 hours ago"`
echo "Deleting log files before ${deletetime}..."
cd ${LOGDIR}
pwd
set -A XX `ls -d *20*.lo*`
for file in ${XX[*]}; do
  filetime=`echo $file | rev | cut -d '_' -f1 | rev | cut -d '.' -f1`
  if [[ ${filetime} -le ${deletetime} ]]; then
    echo "Deleted log file : ${LOGDIR}/${file}"
    rm -f ${LOGDIR}/${file}
  fi
done

exit 0
