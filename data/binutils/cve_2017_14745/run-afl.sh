#!/bin/bash

SEED_DIR="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/seed/"

AFL_CMD="timeout 12h $VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-fuzz"
AFL_OPTS_COMMON="-t 2000ms -m none -s m -z -u n -a 180 -q a"
AFL_INPUT_DIR="./in"
AFL_PROG="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/sparrow-out/bug/slice_dfg.txt"
AFL_OUTPUT_BASE="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/dafl"
INSTRUMENTED_PROG="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/runtime/objdump.instrumented"
OUTPUT_TMP="/tmp/out.tmp"
EXPLOIT="$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/exploit"

count=1

for file in "$SEED_DIR"*; do
    input_dir=$(mktemp -d)
    cov_dir=$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/temp/output_$count

    mkdir -p $cov_dir
    
    cp "$file" "$input_dir"

    file_name=$(basename "$file")
    file_list=("seed1" "seed2" "seed3" "seed4" "seed5" "seed6" "seed7" "seed8" "seed9" "seed10" "seed12" "seed13" "seed14" "seed15" "seed16" "seed17" "seed18" "seed19" "seed20" "seed21" "seed22" "seed23" "seed24" "seed25" "seed26" "seed27" "seed28" "seed29" "seed30" "seed31" "seed32" "seed33" "seed34" "seed35" "seed36" "seed37" "seed38" "seed39" "seed40" "seed41" "seed42" "seed43" "seed44" "seed45" "seed46" "seed47" "seed48" "seed49" "seed50" "exploit")
    #file_list=("seed35" "seed47" "seed25" "seed15" "seed22" "seed16" "seed20" "seed26" "seed27" "seed39" "seed13" "seed11" "seed28" "seed12" "seed1" "seed19" "seed46" "seed33" "seed17" "seed50" "seed32" "seed42" "seed10" "seed7" "seed21" "seed40" "seed14" "seed49" "seed23" "seed38" "seed9" "seed37" "seed36" "seed29" "seed43" "seed2" "seed31" "seed44" "seed18" "seed45" "seed41" "seed24" "seed4" "seed8" "seed30" "seed3" "seed34" "seed48" "seed6" "seed5" "exploit")

    if [[ " ${file_list[@]} " =~ " ${file_name} " ]]; then
        AFL_OPTS="$AFL_OPTS_COMMON -C"
    else
        AFL_OPTS="$AFL_OPTS_COMMON"
    fi
    
    output_dir="${AFL_OUTPUT_BASE}_seed_$count"
    export AFL_NO_UI=1
    export PACFIX_TARGET_LINE=6635
    export PACFIX_COV_EXE=$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/runtime/objdump.coverage
    export PACFIX_COV_DIR=$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/temp/output_$count
    export PACFIX_VAL_EXE=$VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/runtime/objdump.valuation

    $AFL_CMD $AFL_OPTS -i "$input_dir" -p "$AFL_PROG" -o "$output_dir" -b "$EXPLOIT" -- "$INSTRUMENTED_PROG" -D @@ &
    # $AFL_CMD $AFL_OPTS -C -i "$input_dir" -p "$AFL_PROG" -o "$output_dir" -b "$EXPLOIT" -- "$INSTRUMENTED_PROG" -D @@ &
    count=$((count + 1))
done

wait

echo "Run Completed."
