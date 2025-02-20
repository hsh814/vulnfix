#!/bin/bash

subjects=(
    "binutils/cve_2017_6965"
    "binutils/cve_2017_14745"
    "binutils/cve_2017_15025"
    "coreutils/gnubug_19784"
    "coreutils/gnubug_25003"
    "coreutils/gnubug_25023"
    "coreutils/gnubug_26545"
    "jasper/cve_2016_8691"
    "jasper/cve_2016_9557"
    "libjpeg/cve_2012_2806"
    "libjpeg/cve_2017_15232"
    "libming/cve_2016_9264"
    "libtiff/bugzilla_2633"
    "libtiff/cve_2016_5321"
    "libtiff/cve_2016_9532"
    "libtiff/cve_2016_10094"
    "libtiff/cve_2017_7595"
    "libtiff/cve_2017_7599"
    "libtiff/cve_2017_7600"
    "libtiff/cve_2017_7601"
    "libxml2/cve_2012_5134"
    "libxml2/cve_2016_1838"
    "libxml2/cve_2016_1839"
    "libxml2/cve_2017_5969"
    "zziplib/cve_2017_5974"
    "zziplib/cve_2017_5975"
    "zziplib/cve_2017_5976"
)
# subjects=("binutils/cve_2017_6965")
for subject in "${subjects[@]}"; do
  (
    python3 get_results.py $subject
    # python3 analyze.py $subject cludafl-reset-instant
    # python3 analyze.py $subject cludafl-energy-reset
    # python3 analyze.py $subject cludafl-reset-min
  )
done

echo "All subjects have completed."
