#!/bin/bash
pushd pacfix/zzip
  cp memdisk.c.i.c memdisk.c
popd
# rm -rfruntime runtime-dafl
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/root/pacfix/main.exe -synth_only -epsilon $1 -atomic -debug -cycle 60 -timeout 200 ./config 
# > runtime/pacfix.log 2>&1

