#!/bin/ksh --login

module load hpss

day=`date -u "+%d" -d "-1 day"`
month=`date -u "+%m" -d "-1 day"`
year=`date -u "+%Y" -d "-1 day"`

. ${GLOBAL_VAR_DEFNS_FP}

cd ${COMOUT_BASEDIR}
set -A XX `ls -d ${RUN}.$year$month$day/* | sort -r`
runcount=${#XX[*]}
if [[ $runcount -gt 0 ]];then

  hsi mkdir $ARCHIVEDIR/$year
  hsi mkdir $ARCHIVEDIR/$year/$month
  hsi mkdir $ARCHIVEDIR/$year/$month/$day

  for onerun in ${XX[*]};do

    echo "Archive files from ${onerun}"
    hour=${onerun##*/}

    if [[ -e ${COMOUT_BASEDIR}/${onerun}/nclprd/full/files.zip ]];then
      echo "Graphics..."
      mkdir -p $COMOUT_BASEDIR/stage/$year$month$day$hour/nclprd
      cp -rsv ${COMOUT_BASEDIR}/${onerun}/nclprd/* $COMOUT_BASEDIR/stage/$year$month$day$hour/nclprd
    fi

    if [[ -d ${CYCLE_BASEDIR}/$year$month$day$hour/anal_gsi ]];then
      echo "GSI Diag ..."
      mkdir -p $COMOUT_BASEDIR/stage/$year$month$day$hour/anal_gsi
      cp -rsv ${CYCLE_BASEDIR}/$year$month$day$hour/anal_gsi/* $COMOUT_BASEDIR/stage/$year$month$day$hour/anal_gsi
    fi

    for memID in {1..9}; do
      ensmem=mem${memID}
    
      set -A YY `ls -d ${COMOUT_BASEDIR}/${onerun}/${ensmem}/*bg*tm*`
      postcount=${#YY[*]}
      echo $postcount
      if [[ $postcount -gt 0 ]];then
        echo "GRIB-2 for ${ensmem} ..."
        mkdir -p $COMOUT_BASEDIR/stage/$year$month$day$hour/${ensmem}/postprd
        cp -rsv ${COMOUT_BASEDIR}/${onerun}/${ensmem}/*bg*tm* $COMOUT_BASEDIR/stage/$year$month$day$hour/${ensmem}/postprd 
      fi

      if [[ -e ${CYCLE_BASEDIR}/$year$month$day$hour/${ensmem}/INPUT/gfs_data.tile7.halo0.nc ]]; then
         echo "INPUT  for ${ensmem} ..."
         mkdir -p $COMOUT_BASEDIR/stage/$year$month$day$hour/${ensmem}/input
         cp -rsv ${CYCLE_BASEDIR}/$year$month$day$hour/${ensmem}/INPUT $COMOUT_BASEDIR/stage/$year$month$day$hour/${ensmem}/input
         cp -rsv ${CYCLE_BASEDIR}/$year$month$day$hour/${ensmem}/input.nml $COMOUT_BASEDIR/stage/$year$month$day$hour/${ensmem}/input 
         cp -rsv ${CYCLE_BASEDIR}/$year$month$day$hour/${ensmem}/model_configure $COMOUT_BASEDIR/stage/$year$month$day$hour/${ensmem}/input 
      fi

    done

    if [[ -e ${COMOUT_BASEDIR}/stage/$year$month$day$hour ]];then
      cd ${COMOUT_BASEDIR}/stage
      htar -chvf $ARCHIVEDIR/$year/$month/$day/$year$month$day$hour.tar $year$month$day$hour
      rm -rf $year$month$day$hour
    fi

  done
fi

rmdir $COMOUT_BASEDIR/stage

dateval=`date`
echo "Completed archive at "$dateval
exit 0

