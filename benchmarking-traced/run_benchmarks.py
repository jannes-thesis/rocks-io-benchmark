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
    workloads: List[str]
    thread_configurations: List[List[int]]


def get_bench_params(name):
    with open('benchmarks.json') as f:
        benchmarks_json = json.load(f)
    b = benchmarks_json[name]
    return BenchmarkParameters(b['rocks_bin_dir'],
            b['workloads'], b['thread_configurations'])


def format_output(last_three_lines):
    runtime = last_three_lines[0].split()[-2]
    header = last_three_lines[1].replace('\t', ',').rstrip()
    header += ',runtime'
    data = last_three_lines[2].replace('\t', ',').rstrip()
    data += f',{runtime}'
    return header + '\n' + data + '\n'


def execute_config(config, workloads, rocks_bin_dir):
    config_dir = f'results-{now}/run_comp{str(config[0])}-flush{str(config[1])}'
    os.makedirs(config_dir)
    if os.path.exists('benchmark-data'):
        shutil.rmtree('benchmark-data')
    os.mkdir('benchmark-data')
    for workload in workloads:
        # delete data after first time loading, so 2. load starts from nothing
        if workload == 'fillseq_disable_wal':
            shutil.rmtree('benchmark-data')
            os.mkdir('benchmark-data')
        # r(['sudo', 'bash', 'clear_buffer.sh'])
        r(['sudo', 'drop_caches.sh'])
        sleep(1)
        total_output = ''
        with Popen(['bash', runscript,
                    str(config[0]), str(config[1]), workload, config_dir, rocks_bin_dir],
                   text=True, stdout=subprocess.PIPE) as proc:
            # while running continously obtain stdout and buffer it
            while proc.poll() is None:
                out, err = proc.communicate()
                total_output += out
                print(out)
            last_three_lines = total_output.split('\n')[-4:-1]
            with open(f'{config_dir}/result-{workload}.txt', 'w') as f:
                f.write(format_output(last_three_lines))


if __name__ == '__main__':

    bench_name = sys.argv[1]
    b_params = get_bench_params(bench_name)
    now = datetime.today().strftime('%Y-%m-%d-%H:%M:%S')

    for config in b_params.thread_configurations:
        execute_config(config, b_params.workloads, b_params.rocks_bin_dir)

    if os.path.exists('benchmark-data'):
        shutil.rmtree('benchmark-data')

    print('benchmark done')
