#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <output_suffix>"
    exit 1
fi
SUFFIX="$1"
SEED_DIR="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/seed/"
TARGET_DIR="/home/yuntong/vulnfix/data/binutils/cve_2017_6965"

AFL_CMD="timeout 24h /home/yuntong/vulnfix/thirdparty/CLUDAFL/afl-fuzz"
AFL_OPTS_COMMON="-t 2000+ -m none -d -s mab"
AFL_OPTS_COMMON="${AFL_OPTS_COMMON_OVERRIDE:-$AFL_OPTS_COMMON}"
AFL_INPUT_DIR="./in"
AFL_PROG="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/sparrow-out/bug/slice_dfg.txt"
AFL_OUTPUT_BASE="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/aflrun"
TARGET_BIN="readelf"
INSTRUMENTED_PROG="${TARGET_DIR}/cludafl-runtime/${TARGET_BIN}"
OUTPUT_TMP="/tmp/out.tmp"
EXPLOIT="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/exploit"

export AFL_NO_UI=1
export PACFIX_TARGET_LINE=11640
export PACFIX_COV_EXE=/home/yuntong/vulnfix/data/binutils/cve_2017_6965/runtime/readelf.coverage
export PACFIX_COV_DIR="${TARGET_DIR}/temp/output-${SUFFIX}"
export PACFIX_VAL_EXE=/home/yuntong/vulnfix/data/binutils/cve_2017_6965/runtime/readelf.valuation

mkdir -p $PACFIX_COV_DIR
input_dir=$SEED_DIR
output_dir="${TARGET_DIR}/cludafl_out/out-${SUFFIX}"

rm -rf $output_dir

$AFL_CMD $AFL_OPTS_COMMON -p $AFL_PROG -i "$input_dir" -o "$output_dir" -- "$INSTRUMENTED_PROG" -w @@

echo "Run Completed."
