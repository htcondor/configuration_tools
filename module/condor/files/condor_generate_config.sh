#!/bin/sh

local_dir=$1
cat $local_dir/condor_config.local
for file in `ls $local_dir/feature_configs`; do
   cat $local_dir/feature_configs/$file
done
