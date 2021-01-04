#!/bin/bash
if [ $# -ne 5 ]; then
  echo "./run_benchmark.sh [num_flush_threads]
  [workload_name] [output_prefix] [rocks_bin_dir] [data_dir]"
  exit 0
fi

# configuration for benchmark wrapper script
export NUM_COMPACTION_THREADS=4
export NUM_FLUSH_THREADS=$1
workload=$2
output_prefix=$3
rocks_bin_dir=$4
data_dir=$5
# configuration for db_bench tool
export DB_DIR=${data_dir}/benchmark-data/db
export WAL_DIR=${data_dir}/benchmark-data/wal
export TEMP=${data_dir}/benchmark-data/tmp
export OUTPUT_DIR=${data_dir}/benchmark-data/output

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
# random read-modify-writes 
# no sync after every write
if [ $workload = "readrandomwriterandom" ]; then
    export DB_BENCH_NO_SYNC=yep
    export NUM_KEYS=4000000
fi

start_millis=`date +%s%3N`
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
flush_tids=$(bash get_child_tids.sh db_bench high)
echo "flush tids are ${flush_tids}"

set -m
sudo nohup staprun topsysm2.ko "targets_arg=$flush_tids" -o "${output_prefix}-syscalls.txt" > /dev/null 2> /dev/null < /dev/null &
staprun_pid=$!
echo "staprun pid for workers: ${staprun_pid}"
pidstat_lite $bench_pid $flush_tids > "${output_prefix}-pidstats.txt" &
pidstat_pid=$!
echo "pidstat pid: ${pidstat_pid}"

wait $pid 
end_millis=`date +%s%3N`
let runtime=$end_millis-$start_millis
echo $runtime > "${output_prefix}-runtime_ms.txt"

sudo kill -INT $staprun_pid
tail --pid=$staprun_pid -f /dev/null
# make sure staprun result file is written to disk
sync