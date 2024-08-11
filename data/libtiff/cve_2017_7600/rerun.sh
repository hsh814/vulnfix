#!/bin/bash
pushd pacfix/libtiff
  cp tif_dirwrite.c.i.c tif_dirwrite.c
popd
rm -rf runtime
mkdir -p runtime/afl-in
mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -debug -cycle 60 -timeout 300 ./config
