#!/bin/bash
pushd pacfix/libtiff
  cp tif_jpeg.c.i.c tif_jpeg.c
popd
# rm -rfruntime
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -synth_only -debug -seed -nouniq -epsilon 0.0 -cycle 60 -timeout 300 ./config
