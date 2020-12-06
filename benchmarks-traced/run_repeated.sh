#!/bin/bash
for i in {1..5}
do
    python3 run_benchmarks.py $1
done
bash combine_results.sh 5
