#!/bin/bash

cd rocksdb-6.7.3
DEBUG_LEVEL=0 make db_bench
cd ..
mv rocksdb-6.7.3/db_bench db_bench_original
