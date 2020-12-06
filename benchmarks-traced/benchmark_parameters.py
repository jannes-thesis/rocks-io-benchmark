# workloads = ('fillseq_disable_wal', 'bulkload',
#              'readwhilewriting', 'overwrite', 'updaterandom')
# workloads = ('fillseq_disable_wal', 'bulkload',
#              'overwrite', 'updaterandom')
workloads = ('fillseq_disable_wal', 'bulkload',
             'readwhilewriting', 'updaterandom')

# (num_compaction_threads, num_flush_threads)
# thread_configurations = ((1, 1), (2, 1), (4, 1), (8, 1), (12, 1), (16, 1))
# thread_configurations = [(8, 8)]
# thread_configurations = ((1, 1), (1, 2), (1, 4), (1, 8), (1, 12), (1, 16))
thread_configurations = ((1, 1), (1, 2), (1, 4), (1, 6),
                         (1, 8), (1, 10), (1, 12), (1, 14), (1, 16))
# thread_configurations = ((1, 1), (1, 2))


y_metrics = {'runtime_seconds', 'avg_latency_ms'}
# systemcall times are per avg per worker thread
x_metrics = {'num_compaction_threads', 'num_flush_threads',
             'write_ms', 'sync_file_range_ms', 'fdatasync_ms',
             'munmap_ms', 'fsync_ms', 'unlink_ms', 'pread_ms', 'futex_ms'}

target_syscalls = ['write', 'sync_file_range', 'fdatasync',
                   'munmap', 'fsync', 'unlink', 'pread', 'futex']

y_x_combinations = {(key1, key2) for key1 in y_metrics for key2 in x_metrics}
