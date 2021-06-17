#!/bin/env bash

# Remove config.sh in case it's a link
rm -rf config.sh

# Generate 9 individual member experiment directories following the same numbering as in HWT.
mem=1
for suite in FV3_GFS_v15_thompson_mynn rrfs_gfsv16 nssl_mp_no_nsst ; do 
   for ICS in gfs gefs01 gefs02; do 
    config_file=config.sh.$ICS
    member=$(printf "%02d" $mem)
    sed s/__MEMBER__/$member/g $config_file > config.sh
    sed -i s/__CCPPSUITE__/$suite/g config.sh

    ./generate_FV3LAM_wflow.sh || exit 1
    wait
    ((mem+=1))
  done
done


