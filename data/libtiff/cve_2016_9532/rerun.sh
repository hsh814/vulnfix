#!/bin/bash
pushd pacfix/tools
  cp tiffcrop.c.i.c tiffcrop.c
popd

rm -rf runtime
mkdir -p runtime/afl-in
mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -debug -cycle 60 -timeout 300 ./config
