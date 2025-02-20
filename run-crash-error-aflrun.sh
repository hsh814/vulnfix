#!/bin/bash

# Define array of script paths
scripts=(
    "/home/yuntong/vulnfix/data/binutils/cve_2017_6965/run-aflrun-single.sh"
    "/home/yuntong/vulnfix/data/binutils/cve_2017_14745/run-aflrun-single.sh"
    "/home/yuntong/vulnfix/data/coreutils/gnubug_25003/run-aflrun-single.sh"
    "/home/yuntong/vulnfix/data/coreutils/gnubug_25023/run-aflrun-single.sh"
    "/home/yuntong/vulnfix/data/jasper/cve_2016_9557/run-aflrun-single.sh"
    "/home/yuntong/vulnfix/data/libtiff/cve_2016_9532/run-aflrun-single.sh"
    "/home/yuntong/vulnfix/data/libtiff/cve_2016_10094/run-aflrun-single.sh"
    "/home/yuntong/vulnfix/data/libtiff/cve_2017_7599/run-aflrun-single.sh"
    "/home/yuntong/vulnfix/data/libtiff/cve_2017_7601/run-aflrun-single.sh"
    "/home/yuntong/vulnfix/data/libxml2/cve_2016_1839/run-aflrun-single.sh"
    "/home/yuntong/vulnfix/data/zziplib/cve_2017_5974/run-aflrun-single.sh"
)

# Function to run script in its directory
run_in_directory() {
    local script_path="$1"
    local dir_path=$(dirname "$script_path")
    local script_name=$(basename "$script_path")
    (cd "$dir_path" && bash "$script_name") &
}

# Iterate through the array and run each script
for script in "${scripts[@]}"; do
    run_in_directory "$script"
done

# Wait for all background processes to finish
wait

echo "All scripts have completed."