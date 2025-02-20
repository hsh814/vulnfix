#!/bin/bash

SEED_DIR="/home/yuntong/vulnfix/data/binutils/cve_2017_14745/seed/"

AFL_CMD="timeout 12h /home/yuntong/vulnfix/thirdparty/AFLRun/afl-fuzz"
AFL_OPTS_COMMON="-t 2000ms -m none"
AFL_INPUT_DIR="./in"
AFL_PROG="/home/yuntong/vulnfix/data/binutils/cve_2017_14745/sparrow-out/bug/slice_dfg.txt"
AFL_OUTPUT_BASE="/home/yuntong/vulnfix/data/binutils/cve_2017_14745/aflrun"
INSTRUMENTED_PROG="/home/yuntong/vulnfix/data/binutils/cve_2017_14745/objdump.aflrun"
OUTPUT_TMP="/tmp/out.tmp"
EXPLOIT="/home/yuntong/vulnfix/data/binutils/cve_2017_14745/exploit"

export AFL_NO_UI=1
export PACFIX_TARGET_LINE=6635
export PACFIX_COV_EXE=/home/yuntong/vulnfix/data/binutils/cve_2017_14745/runtime/objdump.coverage
export PACFIX_COV_DIR=/home/yuntong/vulnfix/data/binutils/cve_2017_14745/temp/output2
export PACFIX_VAL_EXE=/home/yuntong/vulnfix/data/binutils/cve_2017_14745/runtime/objdump.valuation
mkdir -p $PACFIX_COV_DIR

input_dir=$SEED_DIR
output_dir=/home/yuntong/vulnfix/data/binutils/cve_2017_14745/aflrun_out2
rm -rf $output_dir
$AFL_CMD $AFL_OPTS_COMMON -i "$input_dir" -o "$output_dir" -- "$INSTRUMENTED_PROG" -D @@

echo "Run Completed."
