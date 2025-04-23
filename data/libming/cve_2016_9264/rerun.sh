#!/bin/bash
pushd pacfix/util
  cp listmp3.c.i.c listmp3.c
popd
# rm -rfruntime
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

$VULNFIX_HOME/pacfix/main.exe -synth_only -debug -epsilon 0.0 -cycle 60 -timeout 300 -seed -nouniq ./config
