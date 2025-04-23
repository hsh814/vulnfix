#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <output_suffix>"
    exit 1
fi
SUFFIX="$1"
TARGET_DIR="$VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_9532"
SEED_DIR="${TARGET_DIR}/seed/"
TARGET_BIN="tiffcrop"

AFL_CMD="timeout 24h $VULNFIX_HOME/vulnfix/thirdparty/AFLRun/afl-fuzz"
AFL_OPTS_COMMON="-C -t 2000ms -m none"
AFL_INPUT_DIR="./in"
AFL_PROG="${TARGET_DIR}/sparrow-out/bug/slice_dfg.txt"
AFL_OUTPUT_BASE="${TARGET_DIR}/dafl"
INSTRUMENTED_PROG="${TARGET_DIR}/${TARGET_BIN}.aflrun"
OUTPUT_TMP="/tmp/out.tmp"
EXPLOIT="${TARGET_DIR}/exploit"

export AFL_NO_UI=1
export PACFIX_TARGET_LINE=2978
export PACFIX_COV_EXE=${TARGET_DIR}/runtime/${TARGET_BIN}.coverage
export PACFIX_COV_DIR="${TARGET_DIR}/temp/output-${SUFFIX}"
export PACFIX_VAL_EXE=${TARGET_DIR}/runtime/${TARGET_BIN}.valuation
mkdir -p $PACFIX_COV_DIR

input_dir=$SEED_DIR
output_dir="${TARGET_DIR}/aflrun_out/out-${SUFFIX}"
rm -rf $output_dir
$AFL_CMD $AFL_OPTS_COMMON -i "$input_dir" -o "$output_dir" -- "$INSTRUMENTED_PROG" @@ ${OUTPUT_TMP}

echo "Run Completed."
