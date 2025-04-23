#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <output_suffix>"
    exit 1
fi
SUFFIX="$1"
SEED_DIR="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_6965/seed/"
SEED_DIR="${SEED_DIR_OVERRIDE:-$SEED_DIR}"
TARGET_DIR="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_6965"

TIMEOUT="24h"
TIMEOUT="${TIMEOUT_OVERRIDE:-$TIMEOUT}"
AFL_CMD="timeout $TIMEOUT $VULNFIX_HOME/vulnfix/thirdparty/CLUDAFL/afl-fuzz"
AFL_OPTS_COMMON="-t 2000+ -m none -d -s mab"
AFL_OPTS_COMMON="${AFL_OPTS_COMMON_OVERRIDE:-$AFL_OPTS_COMMON}"
AFL_INPUT_DIR="./in"
AFL_PROG="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_6965/sparrow-out/bug/slice_dfg.txt"
AFL_OUTPUT_BASE="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_6965/aflrun"
TARGET_BIN="readelf"
INSTRUMENTED_PROG="${TARGET_DIR}/cludafl-runtime/${TARGET_BIN}"
OUTPUT_TMP="/tmp/out.tmp"
EXPLOIT="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_6965/exploit"

export AFL_NO_UI=1
export PACFIX_TARGET_LINE=11640
export PACFIX_COV_EXE=$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_6965/runtime/readelf.coverage
export PACFIX_COV_DIR="${TARGET_DIR}/temp/output-${SUFFIX}"
export PACFIX_VAL_EXE=$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_6965/runtime/readelf.valuation

mkdir -p $PACFIX_COV_DIR
input_dir=$SEED_DIR
output_dir="${TARGET_DIR}/cludafl_out/out-${SUFFIX}"
output_dir="${OUTPUT_DIR_OVERRIDE:-$output_dir}"

rm -rf $output_dir

$AFL_CMD $AFL_OPTS_COMMON -p $AFL_PROG -i "$input_dir" -o "$output_dir" -- "$INSTRUMENTED_PROG" -w @@

echo "Run Completed."
