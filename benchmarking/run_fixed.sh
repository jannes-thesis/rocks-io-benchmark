#!/bin/bash
# required: db_bench executable in same directory
if [ $# -ne 4 ]; then
  echo "./run_fixed.sh [num_flush_threads] [workload_name] [num_keys] [data_dir]"
  exit 0
fi
workload_name=$2
data_dir=$4

# configuration for db_bench tool
export NUM_FLUSH_THREADS=$1
export NUM_KEYS=$3
export NUM_COMPACTION_THREADS=4
export DB_DIR=${data_dir}/benchmark-data/db
export WAL_DIR=${data_dir}/benchmark-data/wal
export TEMP=${data_dir}/benchmark-data/tmp
export OUTPUT_DIR=${data_dir}/benchmark-data/output

./benchmark-mod.sh $workload_name