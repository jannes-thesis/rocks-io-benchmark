#!/bin/bash
mkdir test-run
./db_bench --benchmarks="fillseq" --db=test-run --num=1000000 \
    --max_background_flushes=2
rm -rf test-run
