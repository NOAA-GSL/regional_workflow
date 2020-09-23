#!/bin/ksh --login

module load hpss

day=`date -u "+%d" -d "-1 day"`
month=`date -u "+%m" -d "-1 day"`
year=`date -u "+%Y" -d "-1 day"`

. ${GLOBAL_VAR_DEFNS_FP}

cd ${EXPTDIR}
set -A XX `ls -d $year$month$day* | sort -r`
runcount=${#XX[*]}
if [[ $runcount -gt 0 ]];then

  hsi mkdir $ARCHIVEDIR/$year
  hsi mkdir $ARCHIVEDIR/$year/$month
  hsi mkdir $ARCHIVEDIR/$year/$month/$day

  for onerun in ${XX[*]};do

    echo "Archive files from ${onerun}"
    hour=`echo $onerun | cut -c 9-10`

    if [[ -e ${EXPTDIR}/${onerun}/nclprd/full/files.zip ]];then
      echo "Graphics..."
      mkdir -p $EXPTDIR/stage/$year$month$day$hour/nclprd
      cp -rv ${EXPTDIR}/${onerun}/nclprd/* $EXPTDIR/stage/$year$month$day$hour/nclprd 
    fi

    set -A YY `ls -d ${EXPTDIR}/${onerun}/postprd/*bg*tm*`
    postcount=${#YY[*]}
    echo $postcount
    if [[ $postcount -gt 0 ]];then
      echo "GRIB-2..."
      mkdir -p $EXPTDIR/stage/$year$month$day$hour/postprd
      cp -rv ${EXPTDIR}/${onerun}/postprd/*bg*tm* $EXPTDIR/stage/$year$month$day$hour/postprd 
    fi

    if [[ -e ${EXPTDIR}/stage/$year$month$day$hour ]];then
      cd ${EXPTDIR}/stage
      tar -zcvf $year$month$day$hour.tar.gz $year$month$day$hour
      rm -rf $year$month$day$hour
      hsi put $year$month$day$hour.tar.gz : $ARCHIVEDIR/$year/$month/$day/$year$month$day$hour.tar.gz
      rm -rf $year$month$day$hour.tar.gz
    fi

  done
fi

rmdir $EXPTDIR/stage

dateval=`date`
echo "Completed archive at "$dateval
exit 0

