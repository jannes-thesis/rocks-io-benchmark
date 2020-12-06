n=$1
result_dirs=($(ls -l | grep "result" | tail -n $n | awk '{print $9}'))
repeated_dir="${result_dirs[0]}-repeated"
mkdir $repeated_dir
for ((i = 0 ; i < $n; i++)); do
    mv ${result_dirs[i]} "${repeated_dir}/$((i + 1))"
done
