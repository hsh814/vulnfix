#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <output_suffix>"
    exit 1
fi
SUFFIX="$1"

SEED_DIR="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/seed/"

TARGET_DIR="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745"
AFL_CMD="timeout 24h $VULNFIX_HOME/vulnfix/thirdparty/AFLRun/afl-fuzz"
AFL_OPTS_COMMON="-C -t 2000ms -m none"
AFL_INPUT_DIR="./in"
AFL_PROG="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/sparrow-out/bug/slice_dfg.txt"
AFL_OUTPUT_BASE="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/aflrun"
INSTRUMENTED_PROG="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/objdump.aflrun"
OUTPUT_TMP="/tmp/out.tmp"
EXPLOIT="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/exploit"

export AFL_NO_UI=1
export PACFIX_TARGET_LINE=6635
export PACFIX_COV_EXE=$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/runtime/objdump.coverage
export PACFIX_COV_DIR="${TARGET_DIR}/temp/output-${SUFFIX}"
export PACFIX_VAL_EXE=$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/runtime/objdump.valuation
mkdir -p $PACFIX_COV_DIR

input_dir=$SEED_DIR
output_dir="${TARGET_DIR}/aflrun_out/out-${SUFFIX}"
rm -rf $output_dir
$AFL_CMD $AFL_OPTS_COMMON -i "$input_dir" -o "$output_dir" -- "$INSTRUMENTED_PROG" -D @@

echo "Run Completed."
