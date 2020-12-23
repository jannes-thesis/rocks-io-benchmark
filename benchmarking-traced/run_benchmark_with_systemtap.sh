#!/bin/bash
if [ $# -ne 5 ]; then
  echo "./run_benchmark.sh [num_compaction_threads] [num_flush_threads]
  [workload_name] [result_dir] [rocks_bin_dir]"
  exit 0
fi

# results written here
stats_dir=$4
if [ ! -d $stats_dir ]; then
  mkdir $stats_dir
fi

# configuration for benchmark wrapper script
export NUM_COMPACTION_THREADS=$1
export NUM_FLUSH_THREADS=$2
workload=$3
rocks_bin_dir=$5
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
./benchmark-mod.sh $workload $rocks_bin_dir &

# get wrapper script pid and wait a bit for it to start db_bench
pid=$!
sleep 2

# should only show the actual parent process
bench_pid=`pidof db_bench`
echo "actual pid is ${bench_pid}"

# get tids of the compaction and flush thread pools
# write statistics in order: whole process, compaction threads, flush threads
flush_tids=`bash get_child_tids.sh db_bench high`
echo "flush tids are ${flush_tids}"
# tids_arr=(${flush_tids//,/ })
# first_tid=${flush_tids[0]}

# start collecting statistics
set -m
sudo nohup staprun topsysm2.ko "targets_arg=$flush_tids" -o "$stats_dir/metrics-$workload.txt" > /dev/null 2> /dev/null < /dev/null &
staprun_pid=$!
pidstat_lite $bench_pid $flush_tids > "$stats_dir/pidstats-$workload.txt" &
pidstat_pid=$!

# wait for benchmark wrapper script to finish
wait $pid 
sudo kill -INT $staprun_pid
tail --pid=$staprun_pid -f /dev/null
# make sure staprun result file is written to disk
sync
