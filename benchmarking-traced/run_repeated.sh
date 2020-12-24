#!/bin/bash
for i in {1..3}
do
    python run_bench_traced.py $1
done
bash combine_results.sh 3
