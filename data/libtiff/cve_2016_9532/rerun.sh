#!/bin/bash
pushd pacfix/tools
  cp tiffcrop.c.i.c tiffcrop.c
popd

# rm -rfruntime
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

$VULNFIX_HOME/pacfix/main.exe -synth_only -debug -nouniq -cycle 60 -timeout 300 ./config
