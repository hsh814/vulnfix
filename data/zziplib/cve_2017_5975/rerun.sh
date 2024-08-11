#!/bin/bash
pushd pacfix/zzip
  cp memdisk.c.i.c memdisk.c
popd
rm -rf runtime runtime-dafl
mkdir -p runtime/afl-in
mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -nouniq -seed -epsilon 0.0 -debug -cycle 600 -timeout 1800 ./config 
# > runtime/pacfix.log 2>&1

