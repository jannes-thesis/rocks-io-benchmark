#!/bin/bash
# required: db_bench executable in same directory
if [ $# -ne 4 ]; then
  echo "./run_adaptive.sh [algo_params_string] [workload_name] [num_keys] [data_dir]"
  exit 0
fi
workload_name=$2
data_dir=$4

export ALGO_PARAMS=$1
# configuration for db_bench tool
export NUM_KEYS=$3
# somehow the num flush thread value also influences the job 
# submission rate to the flush pool, regardless of actual pool size
# therefore it needs to be set higher while ignoring this value 
# when instantiating the flush pool which is always started with pool size 1
export NUM_FLUSH_THREADS=8
export NUM_COMPACTION_THREADS=4
export DB_DIR=${data_dir}/benchmark-data/db
export WAL_DIR=${data_dir}/benchmark-data/wal
export TEMP=${data_dir}/benchmark-data/tmp
export OUTPUT_DIR=${data_dir}/benchmark-data/output

./benchmark-mod.sh $workload_name