#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <output_suffix>"
    exit 1
fi
set -x
SUFFIX="$1"
SEED_DIR="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/seed/"
SEED_DIR="${SEED_DIR_OVERRIDE:-$SEED_DIR}"
TARGET_DIR="/home/yuntong/vulnfix/data/binutils/cve_2017_6965"
cd $TARGET_DIR/afl-runtime

TIMEOUT="24h"
TIMEOUT="${TIMEOUT_OVERRIDE:-$TIMEOUT}"
export AFL_PATH=/home/yuntong/vulnfix/thirdparty/AFL

AFL_CMD="timeout $TIMEOUT $AFL_PATH/afl-fuzz"
AFL_OPTS_COMMON="-t 2000+ -m none -C"
AFL_OPTS_COMMON="${AFL_OPTS_COMMON_OVERRIDE:-$AFL_OPTS_COMMON}"
AFL_INPUT_DIR="./in"
AFL_PROG="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/sparrow-out/bug/slice_dfg.txt"
AFL_OUTPUT_BASE="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/aflrun"
TARGET_BIN="readelf"
INSTRUMENTED_PROG="${TARGET_DIR}/afl-runtime/${TARGET_BIN}"
OUTPUT_TMP="/tmp/out.tmp"
EXPLOIT="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/exploit"

export AFL_NO_UI=1
export PACFIX_TARGET_LINE=11640
export PACFIX_COV_EXE=/home/yuntong/vulnfix/data/binutils/cve_2017_6965/runtime/readelf.coverage
export PACFIX_COV_DIR="${TARGET_DIR}/temp/output-${SUFFIX}"
export PACFIX_VAL_EXE=/home/yuntong/vulnfix/data/binutils/cve_2017_6965/runtime/readelf.valuation


input_dir=$TARGET_DIR/afl-runtime/in

OUTPUT_DIR_BASE="${TARGET_DIR}/afl-runtime/out"
mkdir -p $OUTPUT_DIR_BASE
# output_dir_cbi="$OUTPUT_DIR_BASE/cbi-${SUFFIX}"
# constraint_file=$OUTPUT_DIR_BASE/etc/constraint-${SUFFIX}
# out_file_cbi=$OUTPUT_DIR_BASE/etc/outfile-${SUFFIX}
# AFL_CMD_CBI="$AFL_PATH/cd-bytes-identifier"
# AFL_CBI_OPTS="-m none -g -i $EXPLOIT -c $constraint_file -k $output_dir_cbi -o $out_file_cbi "

# $AFL_CMD_CBI $AFL_CBI_OPTS -- "$INSTRUMENTED_PROG" -w @@


output_dir="$OUTPUT_DIR_BASE/${SUFFIX}"
output_dir="${OUTPUT_DIR_OVERRIDE:-$output_dir}"

rm -rf $output_dir

$AFL_CMD $AFL_OPTS_COMMON -i "$input_dir" -o "$output_dir" -- "$INSTRUMENTED_PROG" -w @@

echo "Run Completed."
