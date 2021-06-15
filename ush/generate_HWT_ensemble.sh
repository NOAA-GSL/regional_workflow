#!/bin/env bash

# Remove config.sh in case it's a link
rm -rf config.sh

# Generate the GEFS01
cp config.sh.gefs01 config.sh
./generate_FV3LAM_wflow.sh

# Generate the GEFS02
cp config.sh.gefs02 config.sh
./generate_FV3LAM_wflow.sh

# Generate the GFS
cp config.sh.gfs config.sh
./generate_FV3LAM_wflow.sh

