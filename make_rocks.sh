#!/bin/bash

sudo apt-get -y install gcc g++ libgflags-dev libzstd-dev libsnappy-dev
cd rocksdb-6.7.3
make release
cd ..
