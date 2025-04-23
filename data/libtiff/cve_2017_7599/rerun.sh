#!/bin/bash
pushd pacfix/libtiff
  cp tif_dirwrite.c.i.c tif_dirwrite.c
popd
# rm -rfruntime
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

$VULNFIX_HOME/pacfix/main.exe -synth_only -debug -cycle 60 -timeout 300 ./config
