#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <output_suffix>"
    exit 1
fi
SUFFIX="$1"
TARGET_DIR="/home/yuntong/vulnfix/data/binutils/cve_2017_15025"
SEED_DIR="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/seed/"

AFL_CMD="timeout 24h /home/yuntong/vulnfix/thirdparty/AFLRun/afl-fuzz"
AFL_OPTS_COMMON="-C -t 2000ms -m none"
AFL_PROG="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/sparrow-out/bug/slice_dfg.txt"
AFL_OUTPUT_BASE="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/aflrun"
INSTRUMENTED_PROG="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/nm-new.aflrun"
OUTPUT_TMP="/tmp/out.tmp"
EXPLOIT="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/exploit"

export AFL_NO_UI=1
export PACFIX_TARGET_LINE=2441
export PACFIX_COV_EXE=/home/yuntong/vulnfix/data/binutils/cve_2017_15025/runtime/nm-new.coverage
export PACFIX_COV_DIR="${TARGET_DIR}/temp/output-${SUFFIX}"
export PACFIX_VAL_EXE=/home/yuntong/vulnfix/data/binutils/cve_2017_15025/runtime/nm-new.valuation

mkdir -p $PACFIX_COV_DIR

input_dir=$SEED_DIR
output_dir="${TARGET_DIR}/aflrun_out/out-${SUFFIX}"

rm -rf $output_dir

$AFL_CMD $AFL_OPTS_COMMON -i "$input_dir" -o "$output_dir" -- "$INSTRUMENTED_PROG" -A -a -l -S -s --special-syms --synthetic --with-symbol-versions @@


echo "Run Completed."
