import json


def process_systemtap_output(lines):
    syscall_map = {}
    for line in lines[2:-1]:
        syscall, time, count = line.split()
        syscall_map[syscall] = (float(time), float(
            count), float(time) / float(count))
    return syscall_map


def convert_result(line):
    fields = line.split(',')
    p50_latency = fields[9]
    if p50_latency == '':
        p50_latency = -1
    runtime = fields[-1].strip()
    return float(runtime), float(p50_latency)


def convert_pidstat_line(line):
    fields = line.split()
    return int(fields[0]), int(fields[1])


def convert_pidstat(lines):
    """
    return aggregated bytes read/written
    """
    worker_lines = lines[2:]
    lines_fields = [convert_pidstat_line(line) for line in worker_lines]
    agg_read = sum([fields[0] for fields in lines_fields])
    agg_write = sum([fields[1] for fields in lines_fields])
    return agg_read, agg_write


def process_result_files(result_dir, configurations, workloads):
    results = []
    for config in configurations:
        config_dir = f'{result_dir}/run_comp{str(config[0])}-flush{str(config[1])}'
        for workload in workloads:
            print(f'{config}-{workload}')
            systemtap_file = f'{config_dir}/metrics-{workload}.txt'
            pidstats_file = f'{config_dir}/pidstats-{workload}.txt'
            result_file = f'{config_dir}/result-{workload}.txt'
            num_comp = config[0]
            num_flush = config[1]
            benchmark_run = {'workload': workload, 'thread_config': {
                'num_comp': num_comp, 'num_flush': num_flush}}
            with open(result_file) as f:
                lines = f.readlines()
                runtime, latency = convert_result(lines[-1])
                benchmark_run['runtime_s'] = runtime
                benchmark_run['avg_latency_ms'] = latency
            with open(systemtap_file) as f:
                lines = f.readlines()
                stats = process_systemtap_output(lines)
                stats_maps = [{'name': key, 'total_time_ms': stats[key][0], 'nr_calls': stats[key][1],
                               'avg_call_time_ms': stats[key][2]} for key in stats.keys()]
                benchmark_run['syscall_metrics'] = stats_maps
            with open(pidstats_file) as f:
                lines = f.readlines()
                bytes_read, bytes_written = convert_pidstat(lines)
                benchmark_run['io_throughput'] = {
                    'read_bytes': bytes_read, 'write_bytes': bytes_written}
            results.append(benchmark_run)
    return results


if __name__ == '__main__':
    import sys
    workloads = ['fillseq_disable_wal', 'bulkload']
    thread_configurations = [[1, 1], [1, 2], [1, 4], [
        1, 8], [1, 12], [1, 16], [1, 24], [1, 32], [1, 64]]
    result_base = sys.argv[1]
    n = int(sys.argv[2])
    runs_list = []
    for i in range(1, n + 1):
        result_dir = result_base + f'/{i}'
        results = process_result_files(
            result_dir, thread_configurations, workloads)
        runs_list.extend(results)
    with open(f'{result_base}/result-all.json', 'w') as f:
        json.dump(runs_list, f, indent=4)
