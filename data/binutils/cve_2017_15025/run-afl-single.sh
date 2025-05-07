#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <output_suffix>"
    exit 1
fi
SUFFIX="$1"
TARGET_DIR="/home/yuntong/vulnfix/data/binutils/cve_2017_15025"
SEED_DIR="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/seed/"
SEED_DIR="${SEED_DIR_OVERRIDE:-$SEED_DIR}"

TIMEOUT="24h"
TIMEOUT="${TIMEOUT_OVERRIDE:-$TIMEOUT}"
export AFL_PATH=/home/yuntong/vulnfix/thirdparty/AFL

AFL_CMD="timeout $TIMEOUT $AFL_PATH/afl-fuzz"
AFL_OPTS_COMMON="-t 2000+ -m none -C"
AFL_OPTS_COMMON="${AFL_OPTS_COMMON_OVERRIDE:-$AFL_OPTS_COMMON}"
AFL_PROG="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/sparrow-out/bug/slice_dfg.txt"
AFL_OUTPUT_BASE="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/aflrun"
TARGET_BIN="nm-new"
INSTRUMENTED_PROG="${TARGET_DIR}/afl-runtime/${TARGET_BIN}"
OUTPUT_TMP="/tmp/out.tmp"
EXPLOIT="/home/yuntong/vulnfix/data/binutils/cve_2017_15025/exploit"

export AFL_NO_UI=1
export PACFIX_TARGET_LINE=2441
export PACFIX_COV_EXE=/home/yuntong/vulnfix/data/binutils/cve_2017_15025/runtime/nm-new.coverage
export PACFIX_COV_DIR="${TARGET_DIR}/temp/output-${SUFFIX}"
export PACFIX_VAL_EXE=/home/yuntong/vulnfix/data/binutils/cve_2017_15025/runtime/nm-new.valuation

mkdir -p $PACFIX_COV_DIR

input_dir="${TARGET_DIR}/afl-runtime/in"
mkdir -p ${TARGET_DIR}/afl-runtime/out
output_dir="${TARGET_DIR}/afl-runtime/out/${SUFFIX}"
output_dir="${OUTPUT_DIR_OVERRIDE:-$output_dir}"

rm -rf $output_dir

$AFL_CMD $AFL_OPTS_COMMON -i "$input_dir" -o "$output_dir" -- "$INSTRUMENTED_PROG" -A -a -l -S -s --special-syms --synthetic --with-symbol-versions @@


echo "Run Completed."
