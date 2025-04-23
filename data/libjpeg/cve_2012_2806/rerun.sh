#!/bin/bash
pushd pacfix
  cp jdmarker.c.i.c jdmarker.c
popd
# rm -rfruntime
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

$VULNFIX_HOME/pacfix/main.exe -synth_only -debug -seed -nouniq -epsilon 0.0 -lvfile ./live_variables -cycle 60 -timeout 300 ./config
