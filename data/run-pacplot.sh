#!/bin/bash

epsilons=(
  "0.01"
  "0.05"
  "0.1"
  "0.2"
  "0.5"
  "0.8"
)

fuzzers=(
  "evocatio"
  "afl"
  "dafl"
)
export PYTHONIOENCODING=UTF-8
cd /home/yuntong/vulnfix/data
filename="/home/yuntong/vulnfix/data/subjects.txt"
mkdir -p experiment-results/log

while read -r subject; do
  for epsilon in "${epsilons[@]}"; do
    for fuzzer in "${fuzzers[@]}"; do
      (
        echo "pacplot $subject $fuzzer $epsilon started at $(date)"
        new_subject="${subject//\//_}"
        python3 /home/yuntong/vulnfix/data/pacplot.py $fuzzer --single-subject=$subject --single-epsilon=$epsilon --skip-plot > experiment-results/log/${new_subject}_${fuzzer}_${epsilon}.log 2>&1
        echo "pacplot $subject $fuzzer $epsilon finished at $(date)"
      ) &
    done
  done
done < $filename

wait
echo "All job finished"
