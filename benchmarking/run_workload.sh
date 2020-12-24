#!/bin/bash
if [ $# -ne 4 ]; then
  echo "./run_benchmark.sh [num_flush_threads]
  [workload_name] [result_dir] [rocks_bin_dir]"
  exit 0
fi

# results written here
stats_dir=$3
if [ ! -d $stats_dir ]; then
  mkdir $stats_dir
fi

# configuration for benchmark wrapper script
export NUM_FLUSH_THREADS=$1
workload=$2
rocks_bin_dir=$4
current_dir=$(pwd)
# configuration for db_bench tool
export DB_DIR=${current_dir}/benchmark-data/db
export WAL_DIR=${current_dir}/benchmark-data/wal
export TEMP=${current_dir}/benchmark-data/tmp
export OUTPUT_DIR=${current_dir}/benchmark-data/output

# 80mil keys a w. 400 byte vals -> 3.2GB

# 1. load keys with random order 2. then do compaction
# auto compaction is disabled
# single-threaded
if [ $workload = "bulkload" ]; then
    # export NUM_KEYS=8000000
    export NUM_KEYS=40000000
fi
# load keys sequentially
# single-threaded
if [ $workload = "fillseq_disable_wal" ]; then
    # export NUM_KEYS=8000000
    export NUM_KEYS=40000000
fi
# read random keys while updating
# no sync after every write
if [ $workload = "readwhilewriting" ]; then
    # one extra thread for writing will be used
    export NUM_THREADS=16
    # export NUM_KEYS=8000000
    export NUM_KEYS=40000000
    export DB_BENCH_NO_SYNC=yep
fi
# random read-modify-writes 
# no sync after every write
if [ $workload = "updaterandom" ]; then
    export NUM_THREADS=16
    # export NUM_KEYS=800000
    export NUM_KEYS=4000000
    export DB_BENCH_NO_SYNC=yep
fi
# overwrite random keys
# no sync after every write
if [ $workload = "overwrite" ]; then
    export NUM_THREADS=8
    # export NUM_KEYS=8000
    export NUM_KEYS=40000
    export DB_BENCH_NO_SYNC=yep
fi
if [ $workload = "readrandom" ]; then
    export NUM_THREADS=8
    export NUM_KEYS=800000
fi


# run actual benchmark
./benchmark-mod.sh $workload $rocks_bin_dir