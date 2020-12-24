from subprocess import run as r
from subprocess import Popen
from time import sleep
from datetime import datetime
from dataclasses import dataclass
from typing import *
import subprocess
import os
import shutil
import sys
import json

runscript = 'run_benchmark_with_systemtap.sh'

@dataclass(frozen=True)
class BenchmarkParameters:
    rocks_bin_dir: str
    workload: str
    flush_threads: List[int]


def get_bench_params(name):
    with open('benchmarks.json') as f:
        benchmarks_json = json.load(f)
    b = benchmarks_json[name]
    return BenchmarkParameters(b['rocks_bin_dir'],
            b['workload'], b['flush_threads'])


def execute_config(n_flush_threads, workload, rocks_bin_dir, output_dir):
    r(['sudo', 'clear_page_cache'])
    sleep(1)
    output_prefix = str(os.path.join(output_dir, f't={n_flush_threads}'))
    if os.path.exists('benchmark-data'):
        shutil.rmtree('benchmark-data')
    os.mkdir('benchmark-data')
    total_output = ''
    with Popen(['bash', runscript, str(n_flush_threads), workload, output_prefix, rocks_bin_dir],
               text=True, stdout=subprocess.PIPE) as proc:
        # while running continously obtain stdout and buffer it
        while proc.poll() is None:
            out, err = proc.communicate()
            total_output += out
            print(out)


if __name__ == '__main__':

    bench_name = sys.argv[1]
    b_params = get_bench_params(bench_name)
    now = datetime.today().strftime('%Y-%m-%d-%H:%M')
    output_dir = f'run-{bench_name}-{now}'
    os.mkdir(output_dir)

    for n in b_params.flush_threads:
        execute_config(n, b_params.workload, b_params.rocks_bin_dir, output_dir)

    if os.path.exists('benchmark-data'):
        shutil.rmtree('benchmark-data')

    print('benchmark done')
