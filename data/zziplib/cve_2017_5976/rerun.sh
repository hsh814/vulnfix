#!/bin/bash
pushd pacfix/zzip
  cp memdisk.c.i.c memdisk.c
popd
# rm -rfruntime runtime-dafl
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

$VULNFIX_HOME/pacfix/main.exe -synth_only -debug -cycle 60 -timeout 200 ./config 
# > runtime/pacfix.log 2>&1

