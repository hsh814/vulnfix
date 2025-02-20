#!/bin/bash
pushd pacfix/src
  cp pr.c.i.c  pr.c
popd
# rm -rfruntime runtime-moo
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -synth_only -debug -epsilon 0.0 -cycle 60 -nouniq  -timeout 300 ./config 
