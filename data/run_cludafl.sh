#!/bin/bash
set -x
subjects=(
    # "binutils/cve_2017_6965"
    # "binutils/cve_2017_14745"
    # "binutils/cve_2017_15025"
    # "coreutils/gnubug_19784"
    # "coreutils/gnubug_25003"
    # "coreutils/gnubug_25023"
    # "coreutils/gnubug_26545"
    # "jasper/cve_2016_8691"
    # "jasper/cve_2016_9557"
    # "libjpeg/cve_2012_2806"
    # "libjpeg/cve_2017_15232"
    # "libming/cve_2016_9264"
    # "libtiff/bugzilla_2633"
    # "libtiff/cve_2016_5321"
    # "libtiff/cve_2016_9532"
    # "libtiff/cve_2016_10094"
    # "libtiff/cve_2017_7595"
    # "libtiff/cve_2017_7599"
    # "libtiff/cve_2017_7600"
    # "libtiff/cve_2017_7601"
    # "libxml2/cve_2012_5134"
    # "libxml2/cve_2016_1838"
    # "libxml2/cve_2016_1839"
    # "libxml2/cve_2017_5969"
    # "zziplib/cve_2017_5974"
    # "zziplib/cve_2017_5975"
    # "zziplib/cve_2017_5976"
)
export CLUDAFL="/home/yuntong/vulnfix/thirdparty/CLUDAFL"
# subjects=("libjpeg/cve_2017_15232" "libxml2/cve_2016_1839" "libtiff/cve_2016_9532")

# array=("cludafl-reset-8" "cludafl-reset-9" "cludafl-reset-10")
array=("cludafl-llm-6" "cludafl-llm-7" "cludafl-llm-8" "cludafl-llm-9" "cludafl-llm-10")
#  "cludafl-reset-2" "cludafl-reset-3" "cludafl-reset-4" "cludafl-reset-5" "cludafl-reset-6" "cludafl-reset-7" "cludafl-reset-8" "cludafl-reset-9" "cludafl-reset-10"
for subject in "${subjects[@]}"; do
  (
    echo "Running AFLRun run-aflrun-single.sh for $subject"
    # i="cludafl-reset-min"
    for i in "${array[@]}"; do
    (
      export AFL_OPTS_COMMON_OVERRIDE="-t 2000+ -m none -d -s mab -l"
      echo "Starting fuzzer $i for $subject"
      pushd $subject
        mkdir -p cludafl_out
        ./run-cludafl-single.sh "$i"
      popd
      echo "Fuzzer $i for $subject has completed."
    ) &
    done
    wait
    echo "All fuzzers for $subject have completed."
  ) &
done

wait

echo "All subjects have completed."
