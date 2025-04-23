#!/bin/bash

TARGET_DIR="$VULNFIX_HOME/vulnfix/data/libxml2/cve_2017_5969"
SEED_DIR="${TARGET_DIR}/seed/"
TARGET_BIN="xmllint"

AFL_CMD="timeout 12h $VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-fuzz"
AFL_OPTS_COMMON="-t 2000ms -m none -s m -z -u n -a 180 -q a"
AFL_INPUT_DIR="./in"
AFL_PROG="${TARGET_DIR}/sparrow-out/bug/slice_dfg.txt"
AFL_OUTPUT_BASE="${TARGET_DIR}/dafl"
INSTRUMENTED_PROG="${TARGET_DIR}/runtime/${TARGET_BIN}.instrumented"
OUTPUT_TMP="/tmp/out.tmp"
EXPLOIT="${TARGET_DIR}/exploit"

count=1

for file in "$SEED_DIR"*; do
    input_dir=$(mktemp -d)
    cov_dir=${TARGET_DIR}/temp/output_$count

    mkdir -p $cov_dir
    
    cp "$file" "$input_dir"

    file_name=$(basename "$file")
    file_list=("exploit")
    #file_list=("exploit" "seed7" "seed11" "seed45" "seed31" "seed4" "seed47" "seed39" "seed8" "seed33" "seed26" "seed10" "seed14" "seed1" "seed13")
    #file_list=("exploit" "seed4" "seed20" "seed42" "seed25" "seed30" "seed8" "seed48" "seed6" "seed29" "seed39" "seed35" "seed37" "seed19" "seed32" "seed10" "seed21" "seed26" "seed1")
    #file_list=("exploit" "seed27" "seed17" "seed11" "seed13" "seed29" "seed33" "seed47" "seed22" "seed14" "seed5" "seed12" "seed45" "seed41" "seed9" "seed38" "seed39" "seed21")

    if [[ " ${file_list[@]} " =~ " ${file_name} " ]]; then
        AFL_OPTS="$AFL_OPTS_COMMON -C"
    else
        AFL_OPTS="$AFL_OPTS_COMMON"
    fi
    
    output_dir="${AFL_OUTPUT_BASE}_seed_$count"
    export AFL_NO_UI=1
    export PACFIX_TARGET_LINE=1181
    export PACFIX_COV_EXE=${TARGET_DIR}/runtime/${TARGET_BIN}.coverage
    export PACFIX_COV_DIR=${TARGET_DIR}/temp/output_$count
    export PACFIX_VAL_EXE=${TARGET_DIR}/runtime/${TARGET_BIN}.valuation

    $AFL_CMD $AFL_OPTS -i "$input_dir" -p "$AFL_PROG" -o "$output_dir" -b "$EXPLOIT" -- "$INSTRUMENTED_PROG" --recover @@ &
    # $AFL_CMD $AFL_OPTS -C -i "$input_dir" -p "$AFL_PROG" -o "$output_dir" -b "$EXPLOIT" -- "$INSTRUMENTED_PROG" -D @@ &
    count=$((count + 1))
done

wait

echo "Run Completed."
