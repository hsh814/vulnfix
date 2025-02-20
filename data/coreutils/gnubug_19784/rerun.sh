#!/bin/bash
pushd pacfix/src
  cp make-prime-list.c.i.c make-prime-list.c
popd
# rm -rfruntime runtime-moo
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -synth_only -debug -epsilon 0.0 -cycle 60 -lvfile ./live_variables  -timeout 300 ./config
