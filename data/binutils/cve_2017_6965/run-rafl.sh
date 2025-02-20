#!/bin/bash

SEED_DIR="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/seed2/"

AFL_CMD="timeout 12h /home/yuntong/vulnfix/thirdparty/AFLRun/afl-fuzz"
AFL_OPTS_COMMON="-t 2000ms -m none"
AFL_INPUT_DIR="./in"
AFL_PROG="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/sparrow-out/bug/slice_dfg.txt"
AFL_OUTPUT_BASE="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/raflrun"
INSTRUMENTED_PROG="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/readelf.aflrun"
OUTPUT_TMP="/tmp/out.tmp"
EXPLOIT="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/exploit"

count=1

for file in "$SEED_DIR"*; do
    input_dir=$(mktemp -d)
    cov_dir=/home/yuntong/vulnfix/data/binutils/cve_2017_6965/temp/output_$count

    mkdir -p $cov_dir
    
    cp "$file" "$input_dir"

    file_name=$(basename "$file")
    file_list=("exploit")
    #file_list=("seed35" "seed47" "seed25" "seed15" "seed22" "seed16" "seed20" "seed26" "seed27" "seed39" "seed13" "seed11" "seed28" "seed12" "seed1" "seed19" "seed46" "seed33" "seed17" "seed50" "seed32" "seed42" "seed10" "seed7" "seed21" "seed40" "seed14" "seed49" "seed23" "seed38" "seed9" "seed37" "seed36" "seed29" "seed43" "seed2" "seed31" "seed44" "seed18" "seed45" "seed41" "seed24" "seed4" "seed8" "seed30" "seed3" "seed34" "seed48" "seed6" "seed5" "exploit")

    if [[ " ${file_list[@]} " =~ " ${file_name} " ]]; then
        AFL_OPTS="$AFL_OPTS_COMMON -C"
    else
        AFL_OPTS="$AFL_OPTS_COMMON"
    fi
    
    output_dir="${AFL_OUTPUT_BASE}_seed_$count"
    export AFL_NO_UI=1
    export PACFIX_TARGET_LINE=11640
    export PACFIX_COV_EXE=/home/yuntong/vulnfix/data/binutils/cve_2017_6965/runtime/readelf.coverage
    export PACFIX_COV_DIR=/home/yuntong/vulnfix/data/binutils/cve_2017_6965/temp/output_$count
    export PACFIX_VAL_EXE=/home/yuntong/vulnfix/data/binutils/cve_2017_6965/runtime/readelf.valuation

    $AFL_CMD $AFL_OPTS -i "$input_dir" -o "$output_dir" -- "$INSTRUMENTED_PROG" -w @@ &
    # $AFL_CMD $AFL_OPTS -C -i "$input_dir" -p "$AFL_PROG" -o "$output_dir" -b "$EXPLOIT" -- "$INSTRUMENTED_PROG" -D @@ &
    count=$((count + 1))
done

wait

echo "Run Completed."
