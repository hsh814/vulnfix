#!/bin/bash
pushd pacfix/libtiff
  cp tif_dirwrite.c.i.c tif_dirwrite.c
popd
# rm -rfruntime
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/root/pacfix/main.exe -synth_only -epsilon $1 -atomic -debug -cycle 60 -timeout 300 ./config
