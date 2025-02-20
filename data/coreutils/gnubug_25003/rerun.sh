#!/bin/bash
pushd pacfix
  cp split.c.i.c  src/split.c
popd
# rm -rfruntime runtime-moo
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -synth_only -debug -lvfile ./live_variables -cycle 60 -timeout 300 ./config 
