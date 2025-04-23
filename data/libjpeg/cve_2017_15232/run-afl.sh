#!/bin/bash

TARGET_DIR="$VULNFIX_HOME/vulnfix/data/libjpeg/cve_2017_15232"
SEED_DIR="${TARGET_DIR}/seed/"
TARGET_BIN="djpeg"

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
    file_list=("exploit" "seed2")
    #file_list=("exploit" "seed7" "seed43" "seed47" "seed41" "seed33" "seed15" "seed28" "seed45" "seed3" "seed8" "seed31" "seed17" "seed12" "seed26" "seed20" "seed39" "seed10" "seed13" "seed9" "seed14" "seed6" "seed38" "seed4" "seed21")

    if [[ " ${file_list[@]} " =~ " ${file_name} " ]]; then
        AFL_OPTS="$AFL_OPTS_COMMON -C"
    else
        AFL_OPTS="$AFL_OPTS_COMMON"
    fi
    
    output_dir="${AFL_OUTPUT_BASE}_seed_$count"
    export AFL_NO_UI=1
    export PACFIX_TARGET_LINE=2243
    export PACFIX_COV_EXE=${TARGET_DIR}/runtime/${TARGET_BIN}.coverage
    export PACFIX_COV_DIR=${TARGET_DIR}/temp/output_$count
    export PACFIX_VAL_EXE=${TARGET_DIR}/runtime/${TARGET_BIN}.valuation

    $AFL_CMD $AFL_OPTS -i "$input_dir" -p "$AFL_PROG" -o "$output_dir" -b "$EXPLOIT" -- "$INSTRUMENTED_PROG" -crop 1x1+16+16 -onepass -dither ordered -dct float -colors 8 -targa -grayscale -outfile "$OUTPUT_TMP"  @@ &
    # $AFL_CMD $AFL_OPTS -C -i "$input_dir" -p "$AFL_PROG" -o "$output_dir" -b "$EXPLOIT" -- "$INSTRUMENTED_PROG" -D @@ &
    count=$((count + 1))
done

wait

echo "Run Completed."
